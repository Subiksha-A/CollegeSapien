interface AdminUser {
  uid: string;
  email: string;
  name: string;
  role: string;
}

export const useAuthStore = defineStore("auth", {
  state: () => ({
    user: null as AdminUser | null,
    isInitialized: false,
  }),

  getters: {
    isAuthenticated: (state) => state.user !== null,
    isSuperAdmin: (state) => state.user?.role === "superadmin",
    isAdminOrAbove: (state) =>
      state.user?.role === "admin" || state.user?.role === "superadmin",
    canModerate: (state) =>
      ["moderator", "admin", "superadmin"].includes(state.user?.role ?? ""),
  },

  actions: {
    setUser(user: AdminUser) {
      this.user = user;
      this.isInitialized = true;
    },
    clearUser() {
      this.user = null;
      this.isInitialized = true;
    },
    markInitialized() {
      this.isInitialized = true;
    },
  },

  persist: {
    pick: ["user"],
  },
});
