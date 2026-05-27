import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  GoogleAuthProvider,
  signInWithPopup,
} from "firebase/auth";

export const useFirebaseAuth = () => {
  const { $firebaseAuth } = useNuxtApp();
  const authStore = useAuthStore();

  const signIn = async (email: string, password: string) => {
    const credential = await signInWithEmailAndPassword(
      $firebaseAuth,
      email,
      password,
    );
    return credential.user;
  };

  const signInWithGoogle = async () => {
    const provider = new GoogleAuthProvider();
    const credential = await signInWithPopup($firebaseAuth, provider);
    return credential.user;
  };

  const signOut = async () => {
    await firebaseSignOut($firebaseAuth);
    authStore.clearUser();
  };

  const getToken = async (): Promise<string | null> => {
    const user = $firebaseAuth.currentUser;
    if (!user) return null;
    return user.getIdToken();
  };

  return { signIn, signInWithGoogle, signOut, getToken };
};
