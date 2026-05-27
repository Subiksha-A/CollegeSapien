<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface Resource {
  id: string;
  name: string;
  category: string;
  uploaderName?: string;
  uploadedBy?: string;
  collegeId?: string;
  createdAt?: string;
}

const { get, patch, delete: apiDelete } = useApi();

const resources = ref<Resource[]>([]);
const loading = ref(true);
const categoryFilter = ref("all");
const pendingReject = ref<Resource | null>(null);
const rejectReason = ref("");
const actionInFlight = ref<Set<string>>(new Set());
const snack = ref("");

const fetchPending = async () => {
  loading.value = true;
  const query =
    categoryFilter.value !== "all" ? `?category=${categoryFilter.value}` : "";
  resources.value = await get<Resource[]>(`/admin/resources/pending${query}`);
  loading.value = false;
};

onMounted(fetchPending);
watch(categoryFilter, fetchPending);

const approve = async (id: string) => {
  actionInFlight.value.add(id);
  try {
    await patch(`/admin/resources/${id}/approve`);
    resources.value = resources.value.filter((r) => r.id !== id);
    snack.value = "Resource approved.";
  } catch (err) {
    console.error("Failed to approve resource", err);
  }
  actionInFlight.value.delete(id);
};

const reject = async () => {
  if (!pendingReject.value) return;
  const id = pendingReject.value.id;
  actionInFlight.value.add(id);
  try {
    await patch(
      `/admin/resources/${id}/reject`,
      rejectReason.value ? { reason: rejectReason.value } : {},
    );
    resources.value = resources.value.filter((r) => r.id !== id);
    snack.value = "Resource rejected and archived.";
  } catch (err) {
    console.error("Failed to reject resource", err);
  }
  pendingReject.value = null;
  rejectReason.value = "";
  actionInFlight.value.delete(id);
};

const archive = async (id: string) => {
  actionInFlight.value.add(id);
  try {
    await apiDelete(`/admin/resources/${id}`);
    resources.value = resources.value.filter((r) => r.id !== id);
    snack.value = "Resource archived.";
  } catch (err) {
    console.error("Failed to archive resource", err);
  }
  actionInFlight.value.delete(id);
};
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-bold text-gray-900">Moderation Queue</h1>
      <select
        v-model="categoryFilter"
        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
      >
        <option value="all">All categories</option>
        <option value="Notes">Notes</option>
        <option value="QP">Question Papers</option>
      </select>
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

    <div v-if="loading" class="text-gray-400 text-sm p-4">Loading…</div>

    <div
      v-else-if="resources.length === 0"
      class="bg-white rounded-xl border border-gray-200 p-8 text-center text-gray-500 text-sm"
    >
      No pending resources. 🎉
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="resource in resources"
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
            class="text-xs bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded-full shrink-0"
            >Pending</span
          >
        </div>

        <div class="flex gap-2 flex-wrap">
          <button
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 transition-colors"
            @click="approve(resource.id)"
          >
            Approve
          </button>
          <button
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium border border-red-300 text-red-600 rounded-lg hover:bg-red-50 disabled:opacity-60 transition-colors"
            @click="
              pendingReject = resource;
              rejectReason = '';
            "
          >
            Reject
          </button>
          <button
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 disabled:opacity-60 transition-colors"
            @click="archive(resource.id)"
          >
            Archive
          </button>
        </div>
      </div>
    </div>

    <!-- Reject modal -->
    <div
      v-if="pendingReject"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h3 class="text-base font-semibold text-gray-900 mb-2">
          Reject resource
        </h3>
        <p class="text-sm text-gray-500 mb-3">{{ pendingReject.name }}</p>
        <textarea
          v-model="rejectReason"
          placeholder="Reason (optional)"
          rows="3"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm resize-none focus:outline-none mb-4"
        />
        <div class="flex justify-end gap-2">
          <button
            class="px-4 py-2 text-sm border border-gray-300 rounded-lg"
            @click="pendingReject = null"
          >
            Cancel
          </button>
          <button
            class="px-4 py-2 text-sm bg-red-600 text-white font-medium rounded-lg hover:bg-red-700"
            @click="reject"
          >
            Reject & Archive
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
