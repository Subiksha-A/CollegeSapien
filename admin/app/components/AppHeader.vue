<script setup lang="ts">
const authStore = useAuthStore();
const { signOut } = useFirebaseAuth();
const router = useRouter();

const handleSignOut = async () => {
  await signOut();
  router.push("/login");
};
</script>

<template>
  <header
    class="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-6"
  >
    <div class="text-sm text-gray-500">
      Welcome back,
      <span class="font-semibold text-gray-900">{{
        authStore.user?.name
      }}</span>
    </div>

    <div class="flex items-center gap-3">
      <RoleBadge :role="authStore.user?.role ?? 'user'" />
      <button
        class="text-sm text-gray-500 hover:text-gray-900 transition-colors flex items-center gap-1.5"
        @click="handleSignOut"
      >
        <Icon name="i-heroicons-arrow-right-on-rectangle" class="w-4 h-4" />
        Sign out
      </button>
    </div>
  </header>
</template>
