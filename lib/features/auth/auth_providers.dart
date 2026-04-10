import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream provider that watches Firebase auth state changes.
/// NOTE: this stream does NOT update when emailVerified changes —
/// only on sign-in / sign-out events.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Local flag that the EmailVerificationPage sets to true after
/// a successful reload() + emailVerified check.
/// This is necessary because authStateChanges() never emits after
/// email verification, so AuthGuard would always see emailVerified=false.
final emailVerifiedFlagProvider = StateProvider<bool>((ref) => false);

/// Convenience: is the user fully authenticated + verified?
final isVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final localFlag = ref.watch(emailVerifiedFlagProvider);
  return (user != null && user.emailVerified) || localFlag;
});

/// Convenience: is the user signed in at all?
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});