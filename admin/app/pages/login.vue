<script setup lang="ts">
definePageMeta({ layout: "default", middleware: [] });

const { signIn, signInWithGoogle } = useFirebaseAuth();
const { post } = useApi();
const authStore = useAuthStore();
const router = useRouter();

const email = ref("");
const password = ref("");
const error = ref("");
const loading = ref(false);

interface AuthTokenResult {
  claims: Record<string, unknown>;
}

interface AuthUser {
  uid: string;
  email?: string | null;
  displayName?: string | null;
  getIdToken: (forceRefresh?: boolean) => Promise<string>;
  getIdTokenResult: (forceRefresh?: boolean) => Promise<AuthTokenResult>;
}

const isAuthUser = (value: unknown): value is AuthUser => {
  if (!value || typeof value !== "object") return false;
  const candidate = value as { uid?: unknown; getIdTokenResult?: unknown };
  return (
    typeof candidate.uid === "string" &&
    typeof candidate.getIdTokenResult === "function"
  );
};

const getErrorMessage = (err: unknown, fallback: string) => {
  if (err && typeof err === "object" && "message" in err) {
    const message = (err as { message?: unknown }).message;
    if (typeof message === "string") return message;
  }
  return fallback;
};

const handleGoogleLogin = async () => {
  loading.value = true;
  error.value = "";
  try {
    const user = await signInWithGoogle();
    if (!isAuthUser(user)) throw new Error("Unexpected auth response.");
    await finalizeLogin(user);
  } catch (err) {
    error.value = getErrorMessage(err, "Google sign in failed.");
  } finally {
    loading.value = false;
  }
};

const handleLogin = async () => {
  if (!email.value || !password.value) return;
  loading.value = true;
  error.value = "";

  try {
    const user = await signIn(email.value, password.value);
    if (!isAuthUser(user)) throw new Error("Unexpected auth response.");
    await finalizeLogin(user);
  } catch (err) {
    error.value = getErrorMessage(
      err,
      "Sign in failed. Check your credentials.",
    );
  } finally {
    loading.value = false;
  }
};

const finalizeLogin = async (user: AuthUser) => {
  const tokenResult = await user.getIdTokenResult(true);
  const roleClaim = tokenResult.claims["role"];
  const role = typeof roleClaim === "string" ? roleClaim : "user";

  const allowedRoles = ["moderator", "admin", "superadmin"];
  if (!allowedRoles.includes(role)) {
    error.value = "Access denied: insufficient role.";
    await useFirebaseAuth().signOut();
    return;
  }

  const token = await user.getIdToken();
  const profile = await post<{ user?: { name?: string } }>(
    "/auth/sync",
    undefined,
    token,
  );
  authStore.setUser({
    uid: user.uid,
    email: user.email ?? "",
    name: profile?.user?.name ?? user.displayName ?? user.email ?? "",
    role,
  });

  router.push("/");
};
</script>

<template>
  <div class="min-h-screen bg-gray-950 flex items-center justify-center p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-sm p-8">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">CodeSapiens</h1>
        <p class="text-gray-500 text-sm mt-1">Admin Panel</p>
      </div>

      <div class="flex flex-col gap-4">
        <button
          :disabled="loading"
          class="w-full flex items-center justify-center gap-3 py-2.5 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-60"
          @click="handleGoogleLogin"
        >
          <Icon name="logos:google-icon" size="18" />
          Continue with Google
        </button>

        <div class="relative my-2">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-gray-200"></div>
          </div>
          <div class="relative flex justify-center text-xs uppercase">
            <span class="bg-white px-2 text-gray-500">Or use email</span>
          </div>
        </div>

        <form class="flex flex-col gap-4" @submit.prevent="handleLogin">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1"
              >Email</label
            >
            <input
              v-model="email"
              type="email"
              autocomplete="email"
              required
              class="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1"
              >Password</label
            >
            <input
              v-model="password"
              type="password"
              autocomplete="current-password"
              required
              class="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
            />
          </div>

          <p v-if="error" class="text-red-600 text-sm">{{ error }}</p>

          <button
            type="submit"
            :disabled="loading"
            class="w-full py-2.5 bg-yellow-400 text-gray-900 font-semibold rounded-lg hover:bg-yellow-500 transition-colors disabled:opacity-60 disabled:cursor-not-allowed mt-1"
          >
            {{ loading ? "Signing in…" : "Sign in" }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
