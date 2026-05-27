export default defineNuxtRouteMiddleware(async (to) => {
  if (to.path === "/login") return;

  const authStore = useAuthStore();

  // Wait for Firebase onAuthStateChanged to fire before evaluating.
  // isInitialized is set to true after the first auth state callback.
  if (!authStore.isInitialized) {
    await until(() => authStore.isInitialized).toBe(true, { timeout: 5000 });
  }

  if (!authStore.isAuthenticated) {
    return navigateTo("/login");
  }

  if (!authStore.canModerate) {
    return navigateTo("/login");
  }
});
