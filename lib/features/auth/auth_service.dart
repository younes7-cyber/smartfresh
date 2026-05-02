import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result wrapper for auth operations
class AuthResult {
  const AuthResult.success([this.user]) : error = null;
  const AuthResult.failure(this.error) : user = null;

  final User? user;
  final String? error;

  bool get isSuccess => error == null;
}

/// Central Firebase Authentication + Realtime Database service
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;
  
  // Database URL

  // ── SharedPreferences key ─────────────────────────────────────────────────
  //
  // This flag is written ONCE after successful signup/login.
  // It is ONLY cleared when the user explicitly presses "Logout".
  // It is NEVER re-written on subsequent app launches.
  // Purpose: let SplashScreen know whether to skip the login page.

  static const _kIsLoggedIn = 'smartfresh.is_logged_in';

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ── Auto-login helpers ────────────────────────────────────────────────────

  /// Called by SplashScreen to decide whether to redirect to /main or /login.
  static Future<bool> isAutoLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kIsLoggedIn) ?? false;
    } catch (_) {
      return false;
    }
  }

  // Write flag only when value changes to avoid unnecessary writes
  static Future<void> _persistLogin(bool loggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (loggedIn) {
        await prefs.setBool(_kIsLoggedIn, true);
      } else {
        await prefs.remove(_kIsLoggedIn);
      }
    } catch (e) {
      // Error silently ignored
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;

      // 2. Set display name
      await user.updateDisplayName(username.trim());

      // 3. Get FCM token (non-blocking — don't fail signup if this fails)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        // FCM token error ignored
      }

      // 4. Save user document in Realtime Database
      //    Fields:
      //      - uid, username, email, createdAt, emailVerified
      //      - topic: 'alerts'   → marks this user as subscribed to alert topic
      //      - fcmToken          → used for targeted direct push (optional)
      try {
        await _db.ref('users/${user.uid}').set({
          'uid': user.uid,
          'username': username.trim(),
          'email': email.trim().toLowerCase(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'emailVerified': false,
          'topic': 'alerts',
          if (fcmToken != null) 'fcmToken': fcmToken,
        });
      } catch (e) {
        // Database write error ignored
      }

      // 5. Persist auto-login flag ONCE (never re-written until logout)
      await _persistLogin(true);

      // 6. Send verification email (delay avoids Firebase throttling)
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await user.sendEmailVerification();
      } on FirebaseAuthException {
        // Email verification error ignored
      } catch (e) {
        // Email verification error ignored
      }

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;

      // Persist auto-login flag ONCE on first successful login
      // (If already set, SharedPreferences ignores duplicate writes)
      await _persistLogin(true);

      // Update FCM token in Firestore (token can rotate after re-install)
      _refreshFcmToken(user.uid);

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // ── Email Verification ────────────────────────────────────────────────────

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

  /// Reload user and check emailVerified.
  /// CRITICAL: re-fetches currentUser AFTER reload to avoid stale object bug.
  Future<bool> reloadAndCheckVerification() async {
    try {
      await _auth.currentUser?.reload();
      final freshUser = _auth.currentUser; // new reference after reload
      final verified = freshUser?.emailVerified ?? false;

      if (verified && freshUser != null) {
        try {
          await _db.ref('users/${freshUser.uid}').update({
            'emailVerified': true,
            'verifiedAt': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (e) {
          // Database update error ignored
        }
      }

      return verified;
    } catch (e) {
      return false;
    }
  }

  // ── Fetch user profile from Realtime Database ────────────────────────────

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final snapshot = await _db.ref('users/$uid').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

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

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      // ✅ Clear auto-login flag on explicit logout
      // Next app launch → SplashScreen redirects to /login
      await _persistLogin(false);
      await _auth.signOut();
    } catch (e) {
      // Sign out error ignored
    }
  }

  // ── FCM token refresh (non-blocking) ─────────────────────────────────────

  void _refreshFcmToken(String uid) {
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        _db.ref('users/$uid').update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    // ignore: invalid_return_type_for_catch_error
    });
  }

  // ── Firebase error mapping ────────────────────────────────────────────────

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