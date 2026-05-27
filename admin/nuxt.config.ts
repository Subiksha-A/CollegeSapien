export default defineNuxtConfig({
  compatibilityDate: "2024-10-24",
  ssr: false,
  srcDir: "app",
  modules: [
    "@vueuse/nuxt",
    "@nuxt/icon",
    "@unocss/nuxt",
    "@nuxt/eslint",
    "@pinia/nuxt",
    "pinia-plugin-persistedstate/nuxt",
  ],
  devtools: { enabled: true },
  css: ["./app/app.css"],
  unocss: { nuxtLayers: true },
  imports: { dirs: ["./stores"] },
  runtimeConfig: {
    public: {
      apiBaseUrl: "",
      firebaseApiKey: "",
      firebaseAuthDomain: "",
      firebaseProjectId: "",
      firebaseAppId: "",
      appCheckDebugToken: "",
    },
  },
});
