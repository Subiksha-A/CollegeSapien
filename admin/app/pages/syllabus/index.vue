<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface CollegeOption {
  id: string;
  name: string;
  code: string;
}

interface CurriculumSubject {
  semester: string;
  subject_name: string;
  [key: string]: unknown;
}

interface CurriculumRecord {
  id: string;
  collegeCode: string;
  courseCode: string;
  regulation: string;
  college: string;
  course: string;
  status: "pending" | "approved";
  fileName?: string | null;
  subjects: CurriculumSubject[];
}

interface UploadRowError {
  fileName?: string;
  error: string;
}

const { get, post, patch } = useApi();

const colleges = ref<CollegeOption[]>([]);
const snack = ref("");
const uploadErrors = ref<UploadRowError[]>([]);
const uploading = ref(false);
const isDragOver = ref(false);

const pending = ref<CurriculumRecord[]>([]);
const approved = ref<CurriculumRecord[]>([]);
const loadingPending = ref(true);
const loadingApproved = ref(true);

const selectedPending = ref<Set<string>>(new Set());
const batchInFlight = ref(false);
const singleInFlight = ref<Set<string>>(new Set());

const activeTab = ref<"pending" | "approved">("pending");
const detailItem = ref<CurriculumRecord | null>(null);
const savingEdit = ref(false);

const filterCollegeCode = ref("");
const filterCourseCode = ref("");
const filterRegulation = ref("");

const buildQuery = (params: Record<string, string>) => {
  const entries = Object.entries(params).filter(([, v]) => v);
  if (entries.length === 0) return "";
  return `?${entries.map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join("&")}`;
};

const fetchPending = async () => {
  loadingPending.value = true;
  try {
    pending.value = await get<CurriculumRecord[]>(
      `/curriculum/pending${buildQuery({
        collegeCode: filterCollegeCode.value,
        courseCode: filterCourseCode.value,
        regulation: filterRegulation.value,
      })}`,
    );
  } catch (err) {
    console.error("Failed to load pending curricula", err);
  }
  loadingPending.value = false;
};

const fetchApproved = async () => {
  loadingApproved.value = true;
  try {
    approved.value = await get<CurriculumRecord[]>(
      `/curriculum/admin${buildQuery({
        collegeCode: filterCollegeCode.value,
        courseCode: filterCourseCode.value,
        regulation: filterRegulation.value,
      })}`,
    );
  } catch (err) {
    console.error("Failed to load approved curricula", err);
  }
  loadingApproved.value = false;
};

onMounted(async () => {
  try {
    colleges.value = await get<CollegeOption[]>("/colleges");
  } catch (err) {
    console.error("Failed to load colleges", err);
  }
  await Promise.all([fetchPending(), fetchApproved()]);
});

watch([filterCollegeCode, filterCourseCode, filterRegulation], () => {
  fetchPending();
  fetchApproved();
});

const readFileAsText = (file: File): Promise<string> =>
  new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(reader.error);
    reader.readAsText(file);
  });

const handleFiles = async (fileList: FileList | null) => {
  if (!fileList || fileList.length === 0) return;
  uploading.value = true;
  uploadErrors.value = [];

  const items: { fileName: string; data: unknown }[] = [];
  for (const file of Array.from(fileList)) {
    try {
      const text = await readFileAsText(file);
      const data = JSON.parse(text);
      if (
        !data?.college_code ||
        !data?.course_code ||
        !data?.regulation ||
        !Array.isArray(data?.subjects)
      ) {
        uploadErrors.value.push({
          fileName: file.name,
          error:
            "Missing college_code, course_code, regulation, or subjects[]",
        });
        continue;
      }
      items.push({ fileName: file.name, data });
    } catch {
      uploadErrors.value.push({
        fileName: file.name,
        error: "Invalid JSON",
      });
    }
  }

  if (items.length > 0) {
    try {
      const res = await post<{
        results: Array<
          | {
              fileName?: string;
              id: string;
              collegeCode: string;
              courseCode: string;
              regulation: string;
              subjectCount: number;
            }
          | { fileName?: string; error: unknown }
        >;
      }>("/curriculum/pending", { items });

      const failures = res.results.filter(
        (r): r is { fileName?: string; error: unknown } => "error" in r,
      );
      if (failures.length > 0) {
        uploadErrors.value.push(
          ...failures.map((f) => ({
            fileName: f.fileName,
            error: JSON.stringify(f.error),
          })),
        );
      }
      snack.value = `${res.results.length - failures.length} file(s) uploaded for review.`;
      await fetchPending();
    } catch (err) {
      console.error("Upload failed", err);
      uploadErrors.value.push({ error: "Upload request failed." });
    }
  }

  uploading.value = false;
};

const onDrop = (e: DragEvent) => {
  isDragOver.value = false;
  handleFiles(e.dataTransfer?.files ?? null);
};

const onFileInput = (e: Event) => {
  const target = e.target as HTMLInputElement;
  handleFiles(target.files);
  target.value = "";
};

const toggleSelected = (id: string) => {
  if (selectedPending.value.has(id)) selectedPending.value.delete(id);
  else selectedPending.value.add(id);
};

const approveIds = async (ids: string[]) => {
  if (ids.length === 0) return;
  batchInFlight.value = true;
  try {
    const res = await post<{ approved: string[]; failed: unknown[] }>(
      "/curriculum/pending/approve",
      { ids },
    );
    pending.value = pending.value.filter((p) => !res.approved.includes(p.id));
    res.approved.forEach((id) => selectedPending.value.delete(id));
    snack.value = `${res.approved.length} curriculum(s) approved.`;
    await fetchApproved();
  } catch (err) {
    console.error("Approve failed", err);
  }
  batchInFlight.value = false;
};

const rejectIds = async (ids: string[]) => {
  if (ids.length === 0) return;
  batchInFlight.value = true;
  try {
    await post("/curriculum/pending/reject", { ids });
    pending.value = pending.value.filter((p) => !ids.includes(p.id));
    ids.forEach((id) => selectedPending.value.delete(id));
    snack.value = `${ids.length} curriculum(s) rejected.`;
  } catch (err) {
    console.error("Reject failed", err);
  }
  batchInFlight.value = false;
};

const approveOne = async (id: string) => {
  singleInFlight.value.add(id);
  await approveIds([id]);
  singleInFlight.value.delete(id);
  if (detailItem.value?.id === id) detailItem.value = null;
};

const rejectOne = async (id: string) => {
  singleInFlight.value.add(id);
  await rejectIds([id]);
  singleInFlight.value.delete(id);
  if (detailItem.value?.id === id) detailItem.value = null;
};

const availableRegulations = computed(() => {
  const regs = new Set<string>();
  [...pending.value, ...approved.value].forEach((c) => regs.add(c.regulation));
  return [...regs].sort();
});

const handleSaveEdit = async (payload: {
  id: string;
  status: "pending" | "approved";
  college: string;
  collegeCode: string;
  course: string;
  courseCode: string;
  regulation: string;
  subjects: CurriculumSubject[];
}) => {
  savingEdit.value = true;
  const path =
    payload.status === "pending"
      ? `/curriculum/pending/${payload.id}`
      : `/curriculum/admin/${payload.id}`;
  try {
    const updated = await patch<CurriculumRecord>(path, {
      college: payload.college,
      collegeCode: payload.collegeCode,
      course: payload.course,
      courseCode: payload.courseCode,
      regulation: payload.regulation,
      subjects: payload.subjects,
    });

    const list = payload.status === "pending" ? pending : approved;
    const idx = list.value.findIndex((c) => c.id === payload.id);
    if (idx !== -1) {
      if (updated.id !== payload.id) list.value.splice(idx, 1);
      else list.value[idx] = updated;
    }
    if (updated.id !== payload.id) list.value.push(updated);

    detailItem.value = updated;
    snack.value = "Curriculum updated.";
  } catch (err) {
    console.error("Failed to save curriculum edit", err);
    snack.value = "Failed to save changes.";
  }
  savingEdit.value = false;
};
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-xl font-bold text-gray-900">Syllabus Management</h1>
      <p class="text-sm text-gray-500 mt-0.5">
        Upload curriculum JSON files, review, and publish to the app.
      </p>
    </div>

    <div
      v-if="snack"
      class="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2 flex justify-between"
    >
      {{ snack }}
      <button @click="snack = ''">
        <Icon name="i-heroicons-x-mark" class="w-4 h-4" />
      </button>
    </div>

    <!-- Upload zone -->
    <div
      class="mb-6 bg-white rounded-xl border-2 border-dashed p-8 text-center transition-colors"
      :class="isDragOver ? 'border-yellow-400 bg-yellow-50' : 'border-gray-200'"
      @dragover.prevent="isDragOver = true"
      @dragleave.prevent="isDragOver = false"
      @drop.prevent="onDrop"
    >
      <Icon
        name="i-heroicons-arrow-up-tray"
        class="w-8 h-8 mx-auto text-gray-400 mb-2"
      />
      <p class="text-sm text-gray-600 mb-3">
        Drag &amp; drop one or more curriculum JSON files here, or
      </p>
      <label
        class="inline-flex items-center gap-2 px-4 py-2 bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors text-sm cursor-pointer"
      >
        <Icon name="i-heroicons-folder-open" class="w-4 h-4" />
        Browse files
        <input
          type="file"
          accept="application/json"
          multiple
          class="hidden"
          @change="onFileInput"
        />
      </label>
      <p v-if="uploading" class="text-xs text-gray-400 mt-3">Uploading…</p>
    </div>

    <div
      v-if="uploadErrors.length > 0"
      class="mb-6 bg-red-50 border border-red-200 rounded-lg p-4 text-sm text-red-700"
    >
      <div class="font-medium mb-1">Some files failed to parse:</div>
      <ul class="list-disc list-inside space-y-0.5">
        <li v-for="(e, idx) in uploadErrors" :key="idx">
          {{ e.fileName ?? "Unknown file" }}: {{ e.error }}
        </li>
      </ul>
    </div>

    <!-- Filters -->
    <div class="mb-4 flex flex-wrap gap-3">
      <select
        v-model="filterCollegeCode"
        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
      >
        <option value="">All colleges</option>
        <option v-for="c in colleges" :key="c.id" :value="c.code">
          {{ c.name }}
        </option>
      </select>
      <select
        v-model="filterCourseCode"
        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
      >
        <option value="">All departments</option>
        <option v-for="d in departments" :key="d.code" :value="d.code">
          {{ d.name }}
        </option>
      </select>
      <select
        v-model="filterRegulation"
        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
      >
        <option value="">All regulations</option>
        <option v-for="r in availableRegulations" :key="r" :value="r">
          {{ r }}
        </option>
      </select>
    </div>

    <!-- Tabs -->
    <div class="flex gap-1 mb-4 border-b border-gray-200">
      <button
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeTab === 'pending'
            ? 'border-yellow-400 text-gray-900'
            : 'border-transparent text-gray-400 hover:text-gray-600'
        "
        @click="activeTab = 'pending'"
      >
        Pending review ({{ pending.length }})
      </button>
      <button
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeTab === 'approved'
            ? 'border-yellow-400 text-gray-900'
            : 'border-transparent text-gray-400 hover:text-gray-600'
        "
        @click="activeTab = 'approved'"
      >
        Approved ({{ approved.length }})
      </button>
    </div>

    <!-- Pending table -->
    <div v-if="activeTab === 'pending'">
      <div v-if="selectedPending.size > 0" class="mb-3 flex items-center gap-2">
        <span class="text-sm text-gray-600"
          >{{ selectedPending.size }} selected</span
        >
        <button
          :disabled="batchInFlight"
          class="px-3 py-1.5 text-xs font-medium bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 transition-colors"
          @click="approveIds([...selectedPending])"
        >
          Approve selected
        </button>
        <button
          :disabled="batchInFlight"
          class="px-3 py-1.5 text-xs font-medium border border-red-300 text-red-600 rounded-lg hover:bg-red-50 disabled:opacity-60 transition-colors"
          @click="rejectIds([...selectedPending])"
        >
          Reject selected
        </button>
      </div>

      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div v-if="loadingPending" class="p-4 text-sm text-gray-400">
          Loading…
        </div>
        <div
          v-else-if="pending.length === 0"
          class="p-8 text-center text-gray-500 text-sm"
        >
          No pending uploads.
        </div>
        <table v-else class="w-full text-sm">
          <thead>
            <tr class="text-left text-gray-400 border-b border-gray-100">
              <th class="py-2 px-4 font-medium w-8"></th>
              <th class="py-2 px-4 font-medium">File</th>
              <th class="py-2 px-4 font-medium">College</th>
              <th class="py-2 px-4 font-medium">Course</th>
              <th class="py-2 px-4 font-medium">Regulation</th>
              <th class="py-2 px-4 font-medium">Subjects</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in pending"
              :key="row.id"
              class="border-b border-gray-50 hover:bg-gray-50 cursor-pointer"
              @click="detailItem = row"
            >
              <td class="py-2 px-4" @click.stop>
                <input
                  type="checkbox"
                  :checked="selectedPending.has(row.id)"
                  @change="toggleSelected(row.id)"
                />
              </td>
              <td class="py-2 px-4 text-gray-500">
                {{ row.fileName ?? "—" }}
              </td>
              <td class="py-2 px-4 text-gray-900">{{ row.college }}</td>
              <td class="py-2 px-4 text-gray-900">{{ row.course }}</td>
              <td class="py-2 px-4 text-gray-500">{{ row.regulation }}</td>
              <td class="py-2 px-4 text-gray-500">
                {{ row.subjects.length }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Approved table -->
    <div v-else>
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div v-if="loadingApproved" class="p-4 text-sm text-gray-400">
          Loading…
        </div>
        <div
          v-else-if="approved.length === 0"
          class="p-8 text-center text-gray-500 text-sm"
        >
          No approved curricula yet.
        </div>
        <table v-else class="w-full text-sm">
          <thead>
            <tr class="text-left text-gray-400 border-b border-gray-100">
              <th class="py-2 px-4 font-medium">College</th>
              <th class="py-2 px-4 font-medium">Course</th>
              <th class="py-2 px-4 font-medium">Regulation</th>
              <th class="py-2 px-4 font-medium">Subjects</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in approved"
              :key="row.id"
              class="border-b border-gray-50 hover:bg-gray-50 cursor-pointer"
              @click="detailItem = row"
            >
              <td class="py-2 px-4 text-gray-900">{{ row.college }}</td>
              <td class="py-2 px-4 text-gray-900">{{ row.course }}</td>
              <td class="py-2 px-4 text-gray-500">{{ row.regulation }}</td>
              <td class="py-2 px-4 text-gray-500">
                {{ row.subjects.length }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <SyllabusCurriculumDetail
      v-if="detailItem"
      :curriculum="detailItem"
      :action-in-flight="singleInFlight.has(detailItem.id)"
      :saving-edit="savingEdit"
      @close="detailItem = null"
      @approve="approveOne"
      @reject="rejectOne"
      @save="handleSaveEdit"
    />
  </div>
</template>
