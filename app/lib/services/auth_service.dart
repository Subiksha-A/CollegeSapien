import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/api_models.dart';
import 'api_service.dart';
// import 'app_capability_service.dart'; // mod: moved to web admin panel

// Web OAuth client ID from google-services.json (client_type: 3).
// Required for Google Sign-In on Android to return an idToken.
const _googleWebClientId =
    '186941997391-uhmgsim9eq2pfttpk9ihk6so83q5na0l.apps.googleusercontent.com';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  Future<AuthSyncResult> syncProfile() async {
    final timezoneOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final json = await ApiService.instance
            .post('/auth/sync?timezoneOffsetMinutes=$timezoneOffsetMinutes')
        as Map<String, dynamic>;
    final result = AuthSyncResult.fromJson(json);
    _profile = result.user;
    return result;
  }

  Future<AuthSyncResult> signInWithEmailPassword(
      String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
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
    await credential.user?.getIdToken(true);
    await ApiService.instance.post('/auth/signup', {'name': name.trim()});
    await credential.user?.sendEmailVerification();
  }

  Future<AuthSyncResult> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        await _auth.signInWithPopup(GoogleAuthProvider());
        await _auth.currentUser?.getIdToken(true);
        return syncProfile();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          throw ApiException(499, 'Google sign-in was cancelled');
        }
        throw ApiException(
          500,
          'Google sign-in failed: ${e.message ?? e.code}',
        );
      } catch (e) {
        throw ApiException(500, 'Google sign-in failed: ${e.toString()}');
      }
    }

    final GoogleSignInAccount googleUser;
    try {
      await _googleSignIn.initialize(
        serverClientId: _googleWebClientId,
      );
      googleUser = await _googleSignIn.authenticate();
    } catch (e) {
      throw ApiException(500, 'Google sign-in failed: ${e.toString()}');
    }

    final googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw ApiException(500,
          'Google sign-in failed: could not obtain credentials. Ensure your SHA-1 fingerprint is registered in Firebase Console.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    return syncProfile();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> deleteAccount() async {
    await ApiService.instance.delete('/auth/me');
    await _auth.signOut();
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
    _profile = null;
    // AppCapabilityService.instance.invalidate(); // mod: moved to web admin panel
    try {
      await ApiService.instance
          .post('/auth/logout')
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Local sign-out should still complete if the API is unreachable.
    }
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
    await _auth.signOut();
  }
}
