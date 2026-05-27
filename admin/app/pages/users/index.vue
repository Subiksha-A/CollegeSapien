<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface User {
  id: string;
  uid?: string;
  name: string;
  email: string;
  role: string;
  collegeId?: string;
  collegeName?: string;
  isVerified?: boolean;
  createdAt?: string;
}

const { get } = useApi();

const users = ref<User[]>([]);
const loading = ref(true);
const search = ref("");
const roleFilter = ref("all");

onMounted(async () => {
  users.value = await get<User[]>("/admin/users");
  loading.value = false;
});

const filtered = computed(() =>
  users.value.filter((u) => {
    const q = search.value.toLowerCase();
    const matchSearch =
      !q ||
      u.name.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q);
    const matchRole = roleFilter.value === "all" || u.role === roleFilter.value;
    return matchSearch && matchRole;
  }),
);
</script>

<template>
  <div>
    <h1 class="text-xl font-bold text-gray-900 mb-6">Users</h1>

    <div class="bg-white rounded-xl border border-gray-200">
      <div class="p-4 border-b border-gray-100 flex gap-3 flex-wrap">
        <input
          v-model="search"
          placeholder="Search by name or email…"
          class="flex-1 min-w-48 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
        />
        <select
          v-model="roleFilter"
          class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
        >
          <option value="all">All roles</option>
          <option value="user">User</option>
          <option value="moderator">Moderator</option>
          <option value="admin">Admin</option>
          <option value="superadmin">Superadmin</option>
        </select>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-400 text-sm">
        Loading…
      </div>
      <div
        v-else-if="filtered.length === 0"
        class="p-8 text-center text-gray-400 text-sm"
      >
        No users found.
      </div>
      <table v-else class="w-full text-sm">
        <thead>
          <tr class="text-xs text-gray-500 border-b border-gray-100">
            <th class="px-4 py-3 text-left font-medium">Name</th>
            <th class="px-4 py-3 text-left font-medium">Email</th>
            <th class="px-4 py-3 text-left font-medium">Role</th>
            <th class="px-4 py-3 text-left font-medium">College</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="user in filtered"
            :key="user.id"
            class="border-b border-gray-50 hover:bg-gray-50 cursor-pointer"
            @click="navigateTo(`/users/${user.id}`)"
          >
            <td class="px-4 py-3 font-medium text-gray-900">{{ user.name }}</td>
            <td class="px-4 py-3 text-gray-600">{{ user.email }}</td>
            <td class="px-4 py-3"><RoleBadge :role="user.role" /></td>
            <td class="px-4 py-3 text-gray-500">
              {{ user.collegeName ?? user.collegeId ?? "—" }}
            </td>
          </tr>
        </tbody>
      </table>
      <div class="px-4 py-3 text-xs text-gray-400 border-t border-gray-100">
        {{ filtered.length }} of {{ users.length }} users
      </div>
    </div>
  </div>
</template>
