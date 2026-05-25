import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/api_models.dart';
import 'api_service.dart';
// import 'app_capability_service.dart'; // mod: moved to web admin panel

// Web OAuth client ID from google-services.json (client_type: 3).
// Required for Google Sign-In on Android to return an idToken.
const _googleWebClientId =
    '967553114336-dn8lj07ei0f8mgol1esf5hp4d48dcqv3.apps.googleusercontent.com';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleWebClientId,
    scopes: ['email'],
  );

  User? get currentUser => _auth.currentUser;

  Future<AuthSyncResult> syncProfile() async {
    final json = await ApiService.instance.post('/auth/sync') as Map<String, dynamic>;
    return AuthSyncResult.fromJson(json);
  }

  Future<AuthSyncResult> signInWithEmailPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
    return syncProfile();
  }

  Future<void> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.sendEmailVerification();
  }

  Future<AuthSyncResult> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } catch (e) {
      throw ApiException(500, 'Google sign-in failed: ${e.toString()}');
    }

    if (googleUser == null) {
      throw ApiException(499, 'Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      throw ApiException(500, 'Google sign-in failed: could not obtain credentials. Ensure your SHA-1 fingerprint is registered in Firebase Console.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    await _auth.currentUser?.getIdToken(true);
    return syncProfile();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<UserProfile> onboard({
    required String name,
    required String collegeId,
    required String department,
    required int semester,
  }) async {
    final json = await ApiService.instance.post('/auth/onboard', {
      'name': name.trim(),
      'collegeId': collegeId,
      'department': department,
      'semester': semester,
    }) as Map<String, dynamic>;

    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    // AppCapabilityService.instance.invalidate(); // mod: moved to web admin panel
    try {
      await ApiService.instance.post('/auth/logout');
    } catch (_) {
      // Local sign-out should still complete if the API is unreachable.
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
