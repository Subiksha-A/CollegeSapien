<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface College {
  id: string;
  name: string;
  code: string;
  city?: string;
  domains?: string[];
}

interface Department {
  id: string;
  name: string;
  code: string;
}

const { get, post, put, delete: apiDelete } = useApi();

const activeSubTab = ref<"colleges" | "departments">("colleges");

// --- College states ---
const colleges = ref<College[]>([]);
const loading = ref(true);
const selectedCollege = ref<College | null>(null);

// Form state (shared for create + edit)
const formMode = ref<"idle" | "create" | "edit">("idle");
const formName = ref("");
const formCode = ref("");
const formCity = ref("");
const formDomains = ref<string[]>([]);
const formDomainInput = ref("");
const formSaving = ref(false);
const formError = ref("");

// Delete confirm
const pendingDelete = ref<College | null>(null);
const deleteInFlight = ref(false);

// --- Department states ---
const departments = ref<Department[]>([]);
const loadingDepts = ref(true);
const selectedDept = ref<Department | null>(null);

const deptFormMode = ref<"idle" | "create" | "edit">("idle");
const deptFormName = ref("");
const deptFormCode = ref("");
const deptFormSaving = ref(false);
const deptFormError = ref("");

const pendingDeleteDept = ref<Department | null>(null);
const deleteDeptInFlight = ref(false);

const snack = ref("");

onMounted(async () => {
  try {
    colleges.value = await get<College[]>("/colleges");
  } catch (err) {
    console.error("Failed to load colleges", err);
  }
  loading.value = false;

  try {
    departments.value = await get<Department[]>("/colleges/departments");
  } catch (err) {
    console.error("Failed to load departments", err);
  }
  loadingDepts.value = false;
});

// --- College methods ---
const openCreate = () => {
  selectedCollege.value = null;
  formName.value = "";
  formCode.value = "";
  formCity.value = "";
  formDomains.value = [];
  formDomainInput.value = "";
  formError.value = "";
  formMode.value = "create";
};

const openEdit = (college: College) => {
  selectedCollege.value = college;
  formName.value = college.name;
  formCode.value = college.code;
  formCity.value = college.city ?? "";
  formDomains.value = [...(college.domains ?? [])];
  formDomainInput.value = "";
  formError.value = "";
  formMode.value = "edit";
};

const cancelForm = () => {
  formMode.value = "idle";
  selectedCollege.value = null;
};

const addDomain = () => {
  const d = formDomainInput.value.trim().toLowerCase();
  if (d && !formDomains.value.includes(d)) formDomains.value.push(d);
  formDomainInput.value = "";
};

const removeDomain = (d: string) => {
  formDomains.value = formDomains.value.filter((x) => x !== d);
};

const saveCollege = async () => {
  formError.value = "";
  if (!formName.value.trim() || !formCode.value.trim()) {
    formError.value = "Name and code are required.";
    return;
  }
  formSaving.value = true;
  const body: Record<string, unknown> = {
    name: formName.value.trim(),
    code: formCode.value.trim().toUpperCase(),
    ...(formCity.value.trim() ? { city: formCity.value.trim() } : {}),
    ...(formDomains.value.length ? { domains: formDomains.value } : {}),
  };
  try {
    if (formMode.value === "create") {
      const res = await post<{ id: string }>("/colleges", body);
      colleges.value.push({ id: res.id, ...body } as College);
      snack.value = "College created.";
    } else if (selectedCollege.value) {
      await put(`/colleges/${selectedCollege.value.id}`, body);
      const idx = colleges.value.findIndex(
        (c) => c.id === selectedCollege.value!.id,
      );
      if (idx !== -1)
        colleges.value[idx] = {
          id: selectedCollege.value.id,
          ...body,
        } as College;
      snack.value = "College updated.";
    }
    formMode.value = "idle";
    selectedCollege.value = null;
  } catch {
    formError.value = "Save failed. Check that you have superadmin access.";
  }
  formSaving.value = false;
};

const confirmDelete = async () => {
  if (!pendingDelete.value) return;
  deleteInFlight.value = true;
  try {
    await apiDelete(`/colleges/${pendingDelete.value.id}`);
    colleges.value = colleges.value.filter(
      (c) => c.id !== pendingDelete.value!.id,
    );
    if (selectedCollege.value?.id === pendingDelete.value.id) {
      selectedCollege.value = null;
      formMode.value = "idle";
    }
    snack.value = "College deleted.";
  } catch {
    snack.value = "Delete failed.";
  }
  pendingDelete.value = null;
  deleteInFlight.value = false;
};

// --- Department methods ---
const openCreateDept = () => {
  selectedDept.value = null;
  deptFormName.value = "";
  deptFormCode.value = "";
  deptFormError.value = "";
  deptFormMode.value = "create";
};

const openEditDept = (dept: Department) => {
  selectedDept.value = dept;
  deptFormName.value = dept.name;
  deptFormCode.value = dept.code;
  deptFormError.value = "";
  deptFormMode.value = "edit";
};

const cancelDeptForm = () => {
  deptFormMode.value = "idle";
  selectedDept.value = null;
};

const saveDept = async () => {
  deptFormError.value = "";
  if (!deptFormName.value.trim() || !deptFormCode.value.trim()) {
    deptFormError.value = "Name and code are required.";
    return;
  }
  deptFormSaving.value = true;
  const body = {
    name: deptFormName.value.trim(),
    code: deptFormCode.value.trim().toUpperCase(),
  };
  try {
    if (deptFormMode.value === "create") {
      const res = await post<{ id: string }>("/colleges/departments", body);
      departments.value.push({ id: res.id, ...body });
      snack.value = "Department created.";
    } else if (selectedDept.value) {
      await put(`/colleges/departments/${selectedDept.value.id}`, body);
      const idx = departments.value.findIndex(
        (d) => d.id === selectedDept.value!.id,
      );
      if (idx !== -1)
        departments.value[idx] = {
          id: selectedDept.value.id,
          ...body,
        };
      snack.value = "Department updated.";
    }
    deptFormMode.value = "idle";
    selectedDept.value = null;
  } catch {
    deptFormError.value = "Save failed. Check that you have superadmin access.";
  }
  deptFormSaving.value = false;
};

const confirmDeleteDept = async () => {
  if (!pendingDeleteDept.value) return;
  deleteDeptInFlight.value = true;
  try {
    await apiDelete(`/colleges/departments/${pendingDeleteDept.value.id}`);
    departments.value = departments.value.filter(
      (d) => d.id !== pendingDeleteDept.value!.id,
    );
    if (selectedDept.value?.id === pendingDeleteDept.value.id) {
      selectedDept.value = null;
      deptFormMode.value = "idle";
    }
    snack.value = "Department deleted.";
  } catch {
    snack.value = "Delete failed.";
  }
  pendingDeleteDept.value = null;
  deleteDeptInFlight.value = false;
};
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-bold text-gray-900">Colleges & Departments</h1>
      <button
        v-if="activeSubTab === 'colleges'"
        class="inline-flex items-center gap-2 px-4 py-2 bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors text-sm"
        @click="openCreate"
      >
        <Icon name="i-heroicons-plus" class="w-4 h-4" />
        Add College
      </button>
      <button
        v-else
        class="inline-flex items-center gap-2 px-4 py-2 bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors text-sm"
        @click="openCreateDept"
      >
        <Icon name="i-heroicons-plus" class="w-4 h-4" />
        Add Department
      </button>
    </div>

    <!-- Sub-tabs -->
    <div class="flex gap-1 mb-6 border-b border-gray-200">
      <button
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeSubTab === 'colleges'
            ? 'border-yellow-400 text-gray-900'
            : 'border-transparent text-gray-400 hover:text-gray-600'
        "
        @click="activeSubTab = 'colleges'"
      >
        Colleges
      </button>
      <button
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeSubTab === 'departments'
            ? 'border-yellow-400 text-gray-900'
            : 'border-transparent text-gray-400 hover:text-gray-600'
        "
        @click="activeSubTab = 'departments'"
      >
        Departments
      </button>
    </div>

    <!-- Snack -->
    <div
      v-if="snack"
      class="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2 flex justify-between"
    >
      {{ snack }}
      <button @click="snack = ''">
        <Icon name="i-heroicons-x-mark" class="w-4 h-4" />
      </button>
    </div>

    <!-- Colleges Tab -->
    <div v-if="activeSubTab === 'colleges'" class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- College list -->
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div class="px-4 py-3 border-b border-gray-100 text-sm font-medium text-gray-700">
          All Colleges ({{ colleges.length }})
        </div>
        <div v-if="loading" class="p-4 text-sm text-gray-400">Loading…</div>
        <div
          v-for="college in colleges"
          :key="college.id"
          class="px-4 py-3 border-b border-gray-50 cursor-pointer hover:bg-gray-50 transition-colors group"
          :class="
            selectedCollege?.id === college.id
              ? 'bg-yellow-50 border-l-2 border-l-yellow-400'
              : ''
          "
          @click="openEdit(college)"
        >
          <div class="flex items-center justify-between gap-2">
            <div class="min-w-0">
              <div class="font-medium text-gray-900 text-sm truncate">
                {{ college.name }}
              </div>
              <div class="text-xs text-gray-500 mt-0.5">
                {{ college.code }} · {{ college.city ?? "No city" }}
              </div>
            </div>
            <button
              class="shrink-0 p-1 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
              title="Delete"
              @click.stop="pendingDelete = college"
            >
              <Icon name="i-heroicons-trash" class="w-4 h-4" />
            </button>
          </div>
        </div>
        <div v-if="!loading && colleges.length === 0" class="p-4 text-sm text-gray-400">
          No colleges found.
        </div>
      </div>

      <!-- Detail / form panel -->
      <div class="md:col-span-2 bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div v-if="formMode === 'idle'" class="p-8 text-center text-gray-400 text-sm">
          Select a college to edit, or click <strong class="text-gray-600">Add College</strong>.
        </div>
        <template v-else>
          <div class="px-6 py-4 border-b border-gray-100 text-sm font-medium text-gray-700">
            {{ formMode === "create" ? "New College" : `Edit - ${selectedCollege?.name}` }}
          </div>

          <div class="flex flex-col p-6 space-y-4">
            <div v-if="formError" class="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg p-3">
              {{ formError }}
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Name *</label>
              <input
                v-model="formName"
                type="text"
                placeholder="e.g. SSN College of Engineering"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Code *</label>
              <input
                v-model="formCode"
                type="text"
                placeholder="e.g. SSN"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">City</label>
              <input
                v-model="formCity"
                type="text"
                placeholder="e.g. Chennai"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Email Domains</label>
              <div class="flex gap-2 mb-2">
                <input
                  v-model="formDomainInput"
                  type="text"
                  placeholder="e.g. ssn.edu.in"
                  class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
                  @keydown.enter.prevent="addDomain"
                />
                <button
                  type="button"
                  class="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg text-sm hover:bg-gray-200 transition-colors"
                  @click="addDomain"
                >
                  Add
                </button>
              </div>
              <div class="flex flex-wrap gap-2">
                <span
                  v-for="d in formDomains"
                  :key="d"
                  class="inline-flex items-center gap-1 px-2 py-1 bg-yellow-100 text-yellow-900 rounded-md text-xs"
                >
                  {{ d }}
                  <button @click="removeDomain(d)">
                    <Icon name="i-heroicons-x-mark" class="w-3 h-3" />
                  </button>
                </span>
                <span v-if="formDomains.length === 0" class="text-xs text-gray-400">No domains added</span>
              </div>
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <button
                class="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                @click="cancelForm"
              >
                Cancel
              </button>
              <button
                :disabled="formSaving"
                class="px-4 py-2 text-sm bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 disabled:opacity-60 transition-colors"
                @click="saveCollege"
              >
                {{ formSaving ? "Saving…" : (formMode === "create" ? "Create" : "Save Changes") }}
              </button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Departments Tab -->
    <div v-else-if="activeSubTab === 'departments'" class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- Department list -->
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div class="px-4 py-3 border-b border-gray-100 text-sm font-medium text-gray-700">
          All Departments ({{ departments.length }})
        </div>
        <div v-if="loadingDepts" class="p-4 text-sm text-gray-400">Loading…</div>
        <div
          v-for="dept in departments"
          :key="dept.id"
          class="px-4 py-3 border-b border-gray-50 cursor-pointer hover:bg-gray-50 transition-colors group"
          :class="
            selectedDept?.id === dept.id
              ? 'bg-yellow-50 border-l-2 border-l-yellow-400'
              : ''
          "
          @click="openEditDept(dept)"
        >
          <div class="flex items-center justify-between gap-2">
            <div class="min-w-0">
              <div class="font-medium text-gray-900 text-sm truncate">
                {{ dept.name }}
              </div>
              <div class="text-xs text-gray-500 mt-0.5">
                {{ dept.code }}
              </div>
            </div>
            <button
              class="shrink-0 p-1 text-gray-400 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
              title="Delete"
              @click.stop="pendingDeleteDept = dept"
            >
              <Icon name="i-heroicons-trash" class="w-4 h-4" />
            </button>
          </div>
        </div>
        <div v-if="!loadingDepts && departments.length === 0" class="p-4 text-sm text-gray-400">
          No departments found.
        </div>
      </div>

      <!-- Detail / form panel -->
      <div class="md:col-span-2 bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div v-if="deptFormMode === 'idle'" class="p-8 text-center text-gray-400 text-sm">
          Select a department to edit, or click <strong class="text-gray-600">Add Department</strong>.
        </div>
        <template v-else>
          <div class="px-6 py-4 border-b border-gray-100 text-sm font-medium text-gray-700">
            {{ deptFormMode === 'create' ? 'New Department' : `Edit - ${selectedDept?.name}` }}
          </div>
          <div class="flex flex-col p-6 space-y-4">
            <div v-if="deptFormError" class="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg p-3">
              {{ deptFormError }}
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Name *</label>
              <input
                v-model="deptFormName"
                type="text"
                placeholder="e.g. Information Technology"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Code *</label>
              <input
                v-model="deptFormCode"
                type="text"
                placeholder="e.g. IT"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>
            <div class="flex justify-end gap-2 pt-2">
              <button
                class="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                @click="cancelDeptForm"
              >
                Cancel
              </button>
              <button
                :disabled="deptFormSaving"
                class="px-4 py-2 text-sm bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 disabled:opacity-60 transition-colors"
                @click="saveDept"
              >
                {{ deptFormSaving ? 'Saving…' : (deptFormMode === 'create' ? 'Create' : 'Save Changes') }}
              </button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Delete College confirm modal -->
    <div
      v-if="pendingDelete"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h3 class="text-base font-semibold text-gray-900 mb-2">
          Delete college?
        </h3>
        <p class="text-sm text-gray-500 mb-4">
          <strong>{{ pendingDelete.name }}</strong> will be soft-deleted. This
          cannot be undone from the admin panel.
        </p>
        <div class="flex justify-end gap-2">
          <button
            class="px-4 py-2 text-sm border border-gray-300 rounded-lg"
            @click="pendingDelete = null"
          >
            Cancel
          </button>
          <button
            :disabled="deleteInFlight"
            class="px-4 py-2 text-sm bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 disabled:opacity-60"
            @click="confirmDelete"
          >
            {{ deleteInFlight ? "Deleting…" : "Delete" }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Department Confirm Modal -->
    <div
      v-if="pendingDeleteDept"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h3 class="text-base font-semibold text-gray-900 mb-2">
          Delete department?
        </h3>
        <p class="text-sm text-gray-500 mb-4">
          <strong>{{ pendingDeleteDept.name }}</strong> will be soft-deleted. This
          cannot be undone from the admin panel.
        </p>
        <div class="flex justify-end gap-2">
          <button
            class="px-4 py-2 text-sm border border-gray-300 rounded-lg"
            @click="pendingDeleteDept = null"
          >
            Cancel
          </button>
          <button
            :disabled="deleteDeptInFlight"
            class="px-4 py-2 text-sm bg-red-600 text-white font-medium rounded-lg hover:bg-red-700 disabled:opacity-60"
            @click="confirmDeleteDept"
          >
            {{ deleteDeptInFlight ? "Deleting…" : "Delete" }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
