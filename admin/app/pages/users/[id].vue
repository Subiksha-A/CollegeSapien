<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface UserDetail {
  id: string;
  name: string;
  email: string;
  role: string;
  collegeId?: string;
  collegeName?: string;
  department?: string;
  semester?: number;
  isVerified?: boolean;
  disabled?: boolean;
  createdAt?: string;
  bannedAt?: string;
}

const route = useRoute();
const { get, post, patch } = useApi();
const authStore = useAuthStore();

const user = ref<UserDetail | null>(null);
const loading = ref(true);
const error = ref("");
const showRoleModal = ref(false);
const showBanModal = ref(false);
const selectedRole = ref("");
const selectedCollegeId = ref("");
const actionLoading = ref(false);
const snack = ref("");

onMounted(async () => {
  try {
    user.value = await get<UserDetail>(`/admin/users/${route.params.id}`);
    selectedRole.value = user.value.role;
    selectedCollegeId.value = user.value.collegeId ?? "";
  } catch (e: unknown) {
    error.value =
      (e as { message?: string })?.message ?? "Failed to load user.";
  }
  loading.value = false;
});

const assignRole = async () => {
  if (!user.value) return;
  actionLoading.value = true;
  try {
    await post("/admin/assign-role", {
      uid: user.value.id,
      role: selectedRole.value,
      ...(selectedRole.value === "moderator" && selectedCollegeId.value
        ? { collegeId: selectedCollegeId.value }
        : {}),
    });
    user.value.role = selectedRole.value;
    snack.value = "Role updated.";
    showRoleModal.value = false;
  } catch (err) {
    console.error("Failed to assign role", err);
  }
  actionLoading.value = false;
};

const toggleBan = async () => {
  if (!user.value) return;
  actionLoading.value = true;
  const endpoint = user.value.disabled
    ? `/admin/users/${user.value.id}/unban`
    : `/admin/users/${user.value.id}/ban`;
  try {
    await patch(endpoint);
    user.value.disabled = !user.value.disabled;
    snack.value = user.value.disabled ? "User banned." : "User unbanned.";
    showBanModal.value = false;
  } catch (err) {
    console.error("Failed to toggle ban state", err);
  }
  actionLoading.value = false;
};
</script>

<template>
  <div>
    <div class="flex items-center gap-3 mb-6">
      <NuxtLink to="/users" class="text-gray-400 hover:text-gray-900">
        <Icon name="i-heroicons-arrow-left" class="w-5 h-5" />
      </NuxtLink>
      <h1 class="text-xl font-bold text-gray-900">User Profile</h1>
    </div>

    <div v-if="loading" class="text-gray-400 text-sm p-4">Loading…</div>
    <div v-else-if="error" class="text-red-600 text-sm p-4">{{ error }}</div>

    <template v-else-if="user">
      <div
        class="bg-white rounded-xl border border-gray-200 p-6 mb-4 flex items-start justify-between gap-4"
      >
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <h2 class="text-lg font-semibold text-gray-900">{{ user.name }}</h2>
            <RoleBadge :role="user.role" />
            <span
              v-if="user.disabled"
              class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700"
              >Banned</span
            >
          </div>
          <div class="text-sm text-gray-500">{{ user.email }}</div>
          <div class="text-sm text-gray-500">
            {{ user.collegeName ?? user.collegeId ?? "No college" }} ·
            {{ user.department ?? "No dept" }} · Sem {{ user.semester ?? "—" }}
          </div>
        </div>

        <div v-if="authStore.isSuperAdmin" class="flex gap-2 shrink-0">
          <button
            class="px-3 py-1.5 text-sm bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors"
            @click="showRoleModal = true"
          >
            Assign Role
          </button>
          <button
            class="px-3 py-1.5 text-sm font-medium rounded-lg transition-colors"
            :class="
              user.disabled
                ? 'bg-green-100 text-green-700 hover:bg-green-200'
                : 'bg-red-100 text-red-700 hover:bg-red-200'
            "
            @click="showBanModal = true"
          >
            {{ user.disabled ? "Unban" : "Ban" }}
          </button>
        </div>
      </div>

      <div
        v-if="snack"
        class="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2"
      >
        {{ snack }}
      </div>
    </template>

    <!-- Role modal -->
    <div
      v-if="showRoleModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h3 class="text-base font-semibold text-gray-900 mb-4">Assign Role</h3>
        <select
          v-model="selectedRole"
          class="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm mb-3 focus:outline-none"
        >
          <option value="user">User</option>
          <option value="ambassador">Ambassador</option>
          <option value="moderator">Moderator</option>
          <option value="admin">Admin</option>
          <option value="superadmin">Superadmin</option>
        </select>
        <input
          v-if="selectedRole === 'moderator'"
          v-model="selectedCollegeId"
          placeholder="College ID (required)"
          class="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm mb-3 focus:outline-none"
        />
        <div class="flex justify-end gap-2">
          <button
            class="px-4 py-2 text-sm border border-gray-300 rounded-lg"
            @click="showRoleModal = false"
          >
            Cancel
          </button>
          <button
            :disabled="actionLoading"
            class="px-4 py-2 text-sm bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 disabled:opacity-60"
            @click="assignRole"
          >
            {{ actionLoading ? "Saving…" : "Save" }}
          </button>
        </div>
      </div>
    </div>

    <ConfirmModal
      v-if="showBanModal"
      :title="user?.disabled ? 'Unban user?' : 'Ban user?'"
      :message="
        user?.disabled
          ? 'This will re-enable their account.'
          : 'This will disable their Firebase Auth account immediately.'
      "
      :confirm-label="user?.disabled ? 'Unban' : 'Ban'"
      :danger="!user?.disabled"
      @confirm="toggleBan"
      @cancel="showBanModal = false"
    />
  </div>
</template>
