import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/features/auth/auth_providers.dart';


import '../../core/constants.dart';

/// Protects routes that require a fully authenticated + email-verified user.
///
/// IMPORTANT — emailVerified caveat:
/// Firebase's authStateChanges() stream does NOT emit a new event when the
/// user verifies their email. The User object in the stream cache therefore
/// always shows emailVerified=false until the next sign-in.
///
/// To work around this we store a local "verified flag" in a Riverpod provider
/// that the verification page sets explicitly after a successful reload().
/// The guard reads BOTH the stream AND that local flag.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    // Local flag set by the verification page after reload() confirms verified
    final locallyVerified = ref.watch(emailVerifiedFlagProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
        return const SizedBox.shrink();
      },
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          });
          return const SizedBox.shrink();
        }

        // Accept if Firebase stream says verified OR local flag is set
        final isVerified = user.emailVerified || locallyVerified;

        if (!isVerified) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail);
          });
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}

/// Guard for the verify-email route only.
/// Redirects to /login if not authenticated.
/// Does NOT redirect to /main based on emailVerified from the stream
/// (because the stream is stale — navigation is handled by the page itself).
class AuthRequiredGuard extends ConsumerWidget {
  const AuthRequiredGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
        return const SizedBox.shrink();
      },
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          });
          return const SizedBox.shrink();
        }

        // ✅ Do NOT check user.emailVerified here.
        // The stream value is stale. The page handles its own navigation
        // via _manualCheck() and the polling timer.
        return child;
      },
    );
  }
}