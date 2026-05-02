import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/features/auth/auth_providers.dart';
import 'package:smartfresh/features/auth/auth_service.dart';
import '../../core/constants.dart';
import '../../core/theme/color_palette.dart';

// ConsumerStatefulWidget so we can write to emailVerifiedFlagProvider
class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage>
    with SingleTickerProviderStateMixin {
  Timer? _cooldownTimer;
  int _cooldown = 60;
  bool _canResend = false;

  Timer? _pollTimer;

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  bool _resending = false;
  bool _checking = false;
  String? _resendError;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCooldown();
    _startPolling();
  }

  void _startCooldown() {
    if (mounted) {
      setState(() {
        _cooldown = 60;
        _canResend = false;
      });
    }
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        if (mounted) {
          setState(() {
            _cooldown = 0;
            _canResend = true;
          });
        }
      } else {
        if (mounted) {
          setState(() => _cooldown--);
        }
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      final verified = await _checkVerified();
      if (verified && mounted) _navigateToMain();
    });
  }

  /// Core verification check:
  /// 1. reload() from Firebase servers
  /// 2. re-read currentUser AFTER reload (avoids stale cache bug)
  /// 3. if verified → set local Riverpod flag so AuthGuard lets us through
  Future<bool> _checkVerified() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      // CRITICAL: re-fetch after reload, not before
      final freshUser = FirebaseAuth.instance.currentUser;
      final verified = freshUser?.emailVerified ?? false;

      if (verified) {
        // Update Firestore (non-blocking)
        AuthService.instance.reloadAndCheckVerification();
        // ✅ Set local flag so AuthGuard passes us through to /main
        ref.read(emailVerifiedFlagProvider.notifier).state = true;
      }

      return verified;
    } catch (_) {
      return false;
    }
  }

  void _navigateToMain() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    }
  }

  Future<void> _resend() async {
    if (mounted) {
      setState(() {
        _resending = true;
        _resendError = null;
      });
    }

    final result = await AuthService.instance.sendVerificationEmail();

    if (!mounted) return;
    setState(() => _resending = false);

    if (result.isSuccess) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('verificationResent'.tr()),
          backgroundColor: ColorPalette.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() => _resendError = result.error?.tr());
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _checking = true);

    final verified = await _checkVerified();

    if (!mounted) return;

    if (verified) {
      _navigateToMain();
    } else {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'notVerifiedYet'.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: ColorPalette.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    // Reset the local verified flag on sign out
    ref.read(emailVerifiedFlagProvider.notifier).state = false;
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _userEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003D80), Color(0xFF007BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white70),
                        tooltip: 'logout'.tr(),
                      ),
                      Text(
                        AppStrings.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_rounded,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'checkInbox'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'verificationSentTo'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _userEmail,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ColorPalette.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ColorPalette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'waitingVerification'.tr(),
                                      style: const TextStyle(
                                        color: ColorPalette.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _VerificationStep(
                                  number: 1, label: 'step1CheckEmail'.tr()),
                              const SizedBox(height: 10),
                              _VerificationStep(
                                  number: 2, label: 'step2ClickLink'.tr()),
                              const SizedBox(height: 10),
                              _VerificationStep(
                                  number: 3, label: 'step3AutoRedirect'.tr()),
                              const SizedBox(height: 24),
                              if (_resendError != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: ColorPalette.danger
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: ColorPalette.danger
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(_resendError!,
                                      style: const TextStyle(
                                          color: ColorPalette.danger,
                                          fontSize: 12),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(height: 12),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _canResend && !_resending ? _resend : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    side: BorderSide(
                                      color: _canResend
                                          ? ColorPalette.primary
                                          : ColorPalette.secondary
                                              .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  icon: _resending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Icon(Icons.send_rounded,
                                          size: 16,
                                          color: _canResend
                                              ? ColorPalette.primary
                                              : ColorPalette.secondary),
                                  label: Text(
                                    _canResend
                                        ? 'resendEmail'.tr()
                                        : '${'resendEmail'.tr()} ($_cooldown s)',
                                    style: TextStyle(
                                      color: _canResend
                                          ? ColorPalette.primary
                                          : ColorPalette.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _checking ? null : _manualCheck,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorPalette.primary,
                                    disabledBackgroundColor: ColorPalette.primary
                                        .withValues(alpha: 0.6),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  icon: _checking
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 18),
                                  label: Text(
                                    _checking
                                        ? 'checking'.tr()
                                        : 'iVerifiedContinue'.tr(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white70, size: 16),
                          label: Text('useAnotherAccount'.tr(),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({required this.number, required this.label});
  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: ColorPalette.primary, shape: BoxShape.circle),
          child: Center(
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13)),
        ),
      ],
    );
  }
}