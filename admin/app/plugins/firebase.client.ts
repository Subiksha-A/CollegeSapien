import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged } from 'firebase/auth'
import { initializeAppCheck, CustomProvider } from 'firebase/app-check'

export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig()

  const firebaseConfig = {
    apiKey: config.public.firebaseApiKey as string,
    authDomain: config.public.firebaseAuthDomain as string,
    projectId: config.public.firebaseProjectId as string,
    appId: config.public.firebaseAppId as string,
  }

  const app = getApps().length ? getApps()[0]! : initializeApp(firebaseConfig)
  const auth = getAuth(app)

  // App Check: use debug token for the admin panel (internal tool).
  // Register the debug UUID in Firebase Console → App Check → Debug Tokens.
  const debugToken = config.public.appCheckDebugToken as string
  if (debugToken) {
    // @ts-expect-error: FIREBASE_APPCHECK_DEBUG_TOKEN is a special global the SDK reads
    self.FIREBASE_APPCHECK_DEBUG_TOKEN = debugToken
    initializeAppCheck(app, {
      provider: new CustomProvider({
        getToken: async () => ({
          token: debugToken,
          expireTimeMillis: Date.now() + 3600 * 1000,
        }),
      }),
      isTokenAutoRefreshEnabled: false,
    })
  }

  // Start auth listener immediately after Firebase is ready
  const authStore = useAuthStore()
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      const tokenResult = await user.getIdTokenResult(true)
      const role = (tokenResult.claims['role'] as string) ?? 'user'
      authStore.setUser({
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email ?? '',
        role,
      })
    } else {
      authStore.clearUser()
    }
    authStore.markInitialized()
  })

  return {
    provide: {
      firebaseApp: app,
      firebaseAuth: auth,
    },
  }
})
