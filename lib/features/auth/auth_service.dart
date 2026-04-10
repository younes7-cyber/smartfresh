import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result wrapper for auth operations
class AuthResult {
  const AuthResult.success([this.user]) : error = null;
  const AuthResult.failure(this.error) : user = null;

  final User? user;
  final String? error;

  bool get isSuccess => error == null;
}

/// Central Firebase Authentication + Firestore service
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ──────────────────────── Streams ────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ──────────────────────── Sign Up ────────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1️⃣ Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user!;

      // 2️⃣ Update display name in Auth profile
      await user.updateDisplayName(username.trim());

      // 3️⃣ Save user document in Firestore → collection "users"
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        });
      } catch (firestoreError) {
        // Firestore failure must not block auth — log and continue
        debugPrint('Firestore write error during signup: $firestoreError');
      }

      // 4️⃣ Send verification email
      // FIX Bug 1: small delay avoids Firebase throttling right after account creation,
      // and we catch this error independently so it never blocks the signup flow.
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        // too-many-requests or other non-critical errors: log only, do not fail
        debugPrint('sendEmailVerification error (non-blocking): ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('sendEmailVerification unexpected error: $e');
      }

      return AuthResult.success(user);

    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // ──────────────────────── Sign In ────────────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // ──────────────────────── Email Verification ────────────────────────

  Future<AuthResult> sendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// FIX Bug 2: After reload(), always re-fetch currentUser from FirebaseAuth.instance
  /// because the old User object reference is stale and still returns emailVerified=false.
  Future<bool> reloadAndCheckVerification() async {
    try {
      // Step 1: Force reload from Firebase servers
      await _auth.currentUser?.reload();

      // Step 2: CRITICAL — re-fetch the user AFTER reload to get the fresh state.
      // Do NOT use the old 'currentUser' reference captured before reload().
      final freshUser = _auth.currentUser;
      final verified = freshUser?.emailVerified ?? false;

      // Step 3: If verified, update Firestore document
      if (verified && freshUser != null) {
        try {
          await _firestore.collection('users').doc(freshUser.uid).update({
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Non-blocking — user is still verified even if Firestore update fails
          debugPrint('Firestore emailVerified update error: $e');
        }
      }

      return verified;
    } catch (e) {
      debugPrint('reloadAndCheckVerification error: $e');
      return false;
    }
  }

  // ──────────────────────── Fetch User Profile ─────────────────────────

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
      return null;
    }
  }

  // ──────────────────────── Password Reset ────────────────────────

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // ──────────────────────── Sign Out ────────────────────────

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ──────────────────────── Error Mapping ────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'auth.userNotFound';
      case 'wrong-password':
        return 'auth.wrongPassword';
      case 'invalid-credential':
        return 'auth.invalidCredential';
      case 'email-already-in-use':
        return 'auth.emailInUse';
      case 'weak-password':
        return 'auth.weakPassword';
      case 'invalid-email':
        return 'auth.invalidEmail';
      case 'user-disabled':
        return 'auth.userDisabled';
      case 'too-many-requests':
        return 'auth.tooManyRequests';
      case 'network-request-failed':
        return 'auth.networkError';
      case 'operation-not-allowed':
        return 'auth.operationNotAllowed';
      default:
        return e.message ?? 'auth.unknownError';
    }
  }
}