<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface College {
  id: string;
  name: string;
  code: string;
  city?: string;
  domains?: string[];
}

const { get, post, put, delete: apiDelete } = useApi();

const colleges = ref<College[]>([]);
const loading = ref(true);
const selectedCollege = ref<College | null>(null);
const snack = ref("");

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

onMounted(async () => {
  colleges.value = await get<College[]>("/colleges");
  loading.value = false;
});

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
  } catch (e: unknown) {
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
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-bold text-gray-900">Colleges</h1>
      <button
        class="inline-flex items-center gap-2 px-4 py-2 bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors text-sm"
        @click="openCreate"
      >
        <Icon name="i-heroicons-plus" class="w-4 h-4" />
        Add College
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

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <!-- College list -->
      <div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div
          class="px-4 py-3 border-b border-gray-100 text-sm font-medium text-gray-700"
        >
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
        <div
          v-if="!loading && colleges.length === 0"
          class="p-4 text-sm text-gray-400"
        >
          No colleges found.
        </div>
      </div>

      <!-- Detail / form panel -->
      <div
        class="md:col-span-2 bg-white rounded-xl border border-gray-200 overflow-hidden"
      >
        <!-- Idle state -->
        <div
          v-if="formMode === 'idle'"
          class="p-8 text-center text-gray-400 text-sm"
        >
          Select a college to edit, or click
          <strong class="text-gray-600">Add College</strong>.
        </div>

        <!-- Create / Edit form -->
        <template v-else>
          <div
            class="px-6 py-4 border-b border-gray-100 text-sm font-medium text-gray-700"
          >
            {{
              formMode === "create"
                ? "New College"
                : `Edit - ${selectedCollege?.name}`
            }}
          </div>

          <div class="flex flex-col p-6 space-y-4">
            <div
              v-if="formError"
              class="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg p-3"
            >
              {{ formError }}
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1"
                >Name *</label
              >
              <input
                v-model="formName"
                type="text"
                placeholder="e.g. SSN College of Engineering"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1"
                >Code *</label
              >
              <input
                v-model="formCode"
                type="text"
                placeholder="e.g. SSN"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1"
                >City</label
              >
              <input
                v-model="formCity"
                type="text"
                placeholder="e.g. Chennai"
                class="w-[90%] px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1"
                >Email Domains</label
              >
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
                <span
                  v-if="formDomains.length === 0"
                  class="text-xs text-gray-400"
                  >No domains added</span
                >
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
                {{
                  formSaving
                    ? "Saving…"
                    : formMode === "create"
                      ? "Create"
                      : "Save Changes"
                }}
              </button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <!-- Delete confirm modal -->
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
  </div>
</template>
