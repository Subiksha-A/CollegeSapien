<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface Stats {
  approvedNotes: number;
  approvedQPs: number;
  pendingModeration: number;
  syllabus: number;
}
interface Resource {
  id: string;
  name: string;
  category: string;
  uploaderName?: string;
  uploadedBy?: string;
  collegeId?: string;
  createdAt?: string;
  fileUrl?: string;
}

const { get, patch, delete: apiDelete } = useApi();

const stats = ref<Stats | null>(null);
const statsLoading = ref(true);
const statsError = ref("");

const tab = ref<"approved" | "archived">("approved");
const categoryFilter = ref("all");
const resourceList = ref<Resource[]>([]);
const resourcesLoading = ref(false);
const actionInFlight = ref<Set<string>>(new Set());
const snack = ref("");

const fetchResources = async () => {
  resourcesLoading.value = true;
  try {
    const endpoint =
      tab.value === "approved"
        ? "/admin/resources/approved"
        : "/admin/resources/archived";
    const query =
      categoryFilter.value !== "all" ? `?category=${categoryFilter.value}` : "";
    resourceList.value = await get<Resource[]>(`${endpoint}${query}`);
  } catch (err) {
    console.error("Failed to load resources", err);
    resourceList.value = [];
  }
  resourcesLoading.value = false;
};

const archive = async (id: string) => {
  actionInFlight.value.add(id);
  try {
    await apiDelete(`/admin/resources/${id}`);
    resourceList.value = resourceList.value.filter((r) => r.id !== id);
    snack.value = "Resource archived.";
  } catch (err) {
    console.error("Failed to archive resource", err);
  }
  actionInFlight.value.delete(id);
};

const unarchive = async (id: string) => {
  actionInFlight.value.add(id);
  try {
    await patch(`/admin/resources/${id}/unarchive`);
    resourceList.value = resourceList.value.filter((r) => r.id !== id);
    snack.value = "Resource restored to approved.";
  } catch (err) {
    console.error("Failed to unarchive resource", err);
  }
  actionInFlight.value.delete(id);
};

onMounted(async () => {
  try {
    stats.value = await get<Stats>("/admin/resources/stats");
  } catch (err) {
    console.error("Failed to load resource stats", err);
    statsError.value = "Failed to load stats.";
  }
  statsLoading.value = false;
  await fetchResources();
});

watch([tab, categoryFilter], fetchResources);
</script>

<template>
  <div>
    <h1 class="text-xl font-bold text-gray-900 mb-6">Resources</h1>

    <!-- Stats -->
    <div v-if="statsLoading" class="text-gray-400 text-sm mb-6">
      Loading stats…
    </div>
    <div
      v-else-if="statsError"
      class="text-amber-700 bg-amber-50 border border-amber-200 rounded-lg p-4 text-sm mb-6"
    >
      {{ statsError }}
    </div>
    <template v-else-if="stats">
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          label="Approved Notes"
          :value="stats.approvedNotes"
          icon="i-heroicons-document-text"
        />
        <StatCard
          label="Approved QPs"
          :value="stats.approvedQPs"
          icon="i-heroicons-academic-cap"
        />
        <StatCard
          label="Pending Moderation"
          :value="stats.pendingModeration"
          icon="i-heroicons-shield-check"
          to="/moderation"
        />
        <StatCard
          label="Syllabus Docs"
          :value="stats.syllabus"
          icon="i-heroicons-book-open"
        />
      </div>
    </template>

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

    <!-- Tab bar + filter -->
    <div class="flex items-center justify-between gap-4 flex-wrap w-full">
      <!-- Input field and Search button -->
      <div class="flex gap-2 flex-1 flex-wrap">
        <input
          class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
          placeholder="Search..."
        />
        <button
          class="px-4 py-2 transition-colors border-none rounded-lg bg-white text-gray-600 hover:bg-gray-50"
        >
          Search
        </button>
      </div>

      <div class="flex flex-row gap-4">
        <div
          class="flex rounded-lg bg-gray-100 p-1 gap-1 overflow-hidden text-sm"
        >
          <button
            class="px-4 py-2 transition-colors border-none rounded-lg"
            :class="
              tab === 'approved'
                ? 'bg-yellow-400 text-gray-900 font-medium'
                : 'bg-white text-gray-600 hover:bg-gray-50'
            "
            @click="tab = 'approved'"
          >
            Approved
          </button>
          <button
            class="px-4 py-2 transition-colors border-none rounded-lg"
            :class="
              tab === 'archived'
                ? 'bg-yellow-400 text-gray-900 font-medium'
                : 'bg-white text-gray-600 hover:bg-gray-50'
            "
            @click="tab = 'archived'"
          >
            Archived
          </button>
        </div>

        <select
          v-model="categoryFilter"
          class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
        >
          <option value="all">All categories</option>
          <option value="Notes">Notes</option>
          <option value="QP">Question Papers</option>
        </select>
      </div>
    </div>

    <!-- Resource list -->
    <div v-if="resourcesLoading" class="text-gray-400 text-sm p-4">
      Loading…
    </div>

    <div
      v-else-if="resourceList.length === 0"
      class="bg-white rounded-xl border border-gray-200 p-8 text-center text-gray-500 text-sm"
    >
      No {{ tab }} resources{{
        categoryFilter !== "all" ? ` in ${categoryFilter}` : ""
      }}.
    </div>

    <div v-else class="pt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="resource in resourceList"
        :key="resource.id"
        class="bg-white rounded-xl border border-gray-200 p-5"
      >
        <div class="flex items-start justify-between gap-2 mb-3">
          <div>
            <div class="font-semibold text-gray-900 text-sm">
              {{ resource.name }}
            </div>
            <div class="text-xs text-gray-500 mt-0.5">
              {{ resource.category }} · By
              {{ resource.uploaderName ?? resource.uploadedBy }}
            </div>
          </div>
          <span
            class="text-xs px-2 py-0.5 rounded-full shrink-0"
            :class="
              tab === 'approved'
                ? 'bg-green-100 text-green-800'
                : 'bg-gray-100 text-gray-600'
            "
            >{{ tab === "approved" ? "Approved" : "Archived" }}</span
          >
        </div>

        <div class="flex gap-2">
          <a
            v-if="resource.fileUrl"
            :href="resource.fileUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="px-3 py-1.5 text-xs font-medium border border-blue-300 text-blue-600 rounded-lg hover:bg-blue-50 transition-colors flex items-center gap-1"
          >
            <Icon
              name="i-heroicons-arrow-top-right-on-square"
              class="w-3.5 h-3.5"
            />
            Open File
          </a>
          <button
            v-if="tab === 'approved'"
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 disabled:opacity-60 transition-colors"
            @click="archive(resource.id)"
          >
            Archive
          </button>
          <button
            v-else
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 transition-colors"
            @click="unarchive(resource.id)"
          >
            Restore
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
