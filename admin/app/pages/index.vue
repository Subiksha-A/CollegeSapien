<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

const { get } = useApi();

interface ApiUser {
  id: string;
  role: string;
}
interface ApiResource {
  id: string;
}
interface ApiReport {
  id: string;
}
interface Stats {
  approvedNotes: number;
  approvedQPs: number;
  pendingModeration: number;
  syllabus: number;
}

const loading = ref(true);
const totalUsers = ref(0);
const pendingModeration = ref(0);
const pendingReports = ref(0);
const resourceStats = ref<Stats | null>(null);
const statsError = ref("");

onMounted(async () => {
  const [users, pending, reports] = await Promise.allSettled([
    get<ApiUser[]>("/admin/users"),
    get<ApiResource[]>("/admin/resources/pending"),
    get<ApiReport[]>("/admin/reports"),
  ]);

  if (users.status === "fulfilled") totalUsers.value = users.value.length;
  if (pending.status === "fulfilled")
    pendingModeration.value = pending.value.length;
  if (reports.status === "fulfilled")
    pendingReports.value = reports.value.length;

  try {
    resourceStats.value = await get<Stats>("/admin/resources/stats");
  } catch (err) {
    statsError.value = "Failed to load resource stats.";
    console.error("Failed to load resource stats", err);
  }

  loading.value = false;
});
</script>

<template>
  <div>
    <h1 class="text-xl font-bold text-gray-900 mb-6">Dashboard</h1>

    <div
      v-if="statsError"
      class="mb-4 text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2"
    >
      {{ statsError }}
    </div>

    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
      <StatCard
        label="Total Users"
        :value="totalUsers"
        icon="i-heroicons-users"
        to="/users"
        :loading="loading"
      />
      <StatCard
        label="Pending Moderation"
        :value="pendingModeration"
        icon="i-heroicons-shield-check"
        to="/moderation"
        :loading="loading"
      />
      <StatCard
        label="Pending Reports"
        :value="pendingReports"
        icon="i-heroicons-flag"
        to="/reports"
        :loading="loading"
      />
      <StatCard
        label="Approved Notes"
        :value="resourceStats?.approvedNotes ?? '—'"
        icon="i-heroicons-document-text"
        to="/resources"
        :loading="loading"
      />
    </div>

    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <StatCard
        label="Approved QPs"
        :value="resourceStats?.approvedQPs ?? '—'"
        icon="i-heroicons-academic-cap"
        to="/resources"
        :loading="loading"
      />
      <StatCard
        label="Syllabus Docs"
        :value="resourceStats?.syllabus ?? '—'"
        icon="i-heroicons-book-open"
        :loading="loading"
      />
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <NuxtLink
        to="/moderation"
        class="bg-white rounded-xl border border-gray-200 p-5 flex items-center gap-3 hover:border-yellow-400 transition-colors group"
      >
        <Icon
          name="i-heroicons-shield-check"
          class="w-6 h-6 text-gray-400 group-hover:text-yellow-500"
        />
        <div>
          <div class="font-semibold text-gray-900 text-sm">
            Review Pending Resources
          </div>
          <div class="text-xs text-gray-500">
            Approve or reject uploaded notes &amp; QPs
          </div>
        </div>
        <Icon
          name="i-heroicons-arrow-right"
          class="w-4 h-4 text-gray-300 ml-auto group-hover:text-yellow-500"
        />
      </NuxtLink>

      <NuxtLink
        to="/reports"
        class="bg-white rounded-xl border border-gray-200 p-5 flex items-center gap-3 hover:border-yellow-400 transition-colors group"
      >
        <Icon
          name="i-heroicons-flag"
          class="w-6 h-6 text-gray-400 group-hover:text-yellow-500"
        />
        <div>
          <div class="font-semibold text-gray-900 text-sm">Resolve Reports</div>
          <div class="text-xs text-gray-500">
            Handle user-submitted abuse reports
          </div>
        </div>
        <Icon
          name="i-heroicons-arrow-right"
          class="w-4 h-4 text-gray-300 ml-auto group-hover:text-yellow-500"
        />
      </NuxtLink>
    </div>
  </div>
</template>
