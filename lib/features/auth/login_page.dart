import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/features/auth/auth_service.dart';

import '../../core/constants.dart';
import '../../core/theme/color_palette.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  String? _authError;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward(from: 0);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _authError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      _shake();
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.instance.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      final user = result.user!;

      if (!user.emailVerified) {
        // User authenticated but email not verified → go to verification page
        Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail);
      } else {
        // Fully verified → go to main
        Navigator.of(context).pushReplacementNamed(AppRoutes.main);
      }
    } else {
      setState(() => _authError = result.error?.tr());
      _shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Header Background ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.38,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF003D80), Color(0xFF007BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        AppStrings.logoAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.ac_unit_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'welcomeBack'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form Card ──
          Positioned.fill(
            top: size.height * 0.30,
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final dx = _shakeAnim.value == 0
                          ? 0.0
                          : (8 *
                              (0.5 -
                                  (_shakeAnim.value * 10 % 1.0 - 0.5).abs()));
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Card(
                      elevation: 12,
                      shadowColor: Colors.black.withValues(alpha: 0.18),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'login'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'loginSubtitle'.tr(),
                                style: TextStyle(
                                  color: ColorPalette.secondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Error Banner ──
                              if (_authError != null) ...[
                                _ErrorBanner(message: _authError!),
                                const SizedBox(height: 16),
                              ],

                              // ── Email ──
                              AppTextField(
                                controller: _emailController,
                                label: 'email'.tr(),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'requiredField'.tr();
                                  }
                                  if (!v.contains('@')) {
                                    return 'invalidEmail'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Password ──
                              AppTextField(
                                controller: _passwordController,
                                label: 'password'.tr(),
                                obscureText: !_showPassword,
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'passwordMin'.tr();
                                  }
                                  return null;
                                },
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => _showPassword = !_showPassword),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                              ),

                              // ── Forgot Password ──
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.forgotPassword),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4),
                                  ),
                                  child: Text(
                                    'forgotPassword'.tr(),
                                    style: const TextStyle(
                                      color: ColorPalette.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ── Login Button ──
                              _GradientButton(
                                label: 'login'.tr(),
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                              const SizedBox(height: 20),

                              // ── Divider ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'or'.tr(),
                                      style: TextStyle(
                                          color: ColorPalette.secondary,
                                          fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ── Sign Up Link ──
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.signup),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'noAccount'.tr(),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : ColorPalette.secondary,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: ' ${'signup'.tr()}',
                                          style: const TextStyle(
                                            color: ColorPalette.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onPressed == null
                ? [Colors.grey.shade400, Colors.grey.shade400]
                : [const Color(0xFF007BFF), const Color(0xFF0056B3)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: ColorPalette.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ColorPalette.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: ColorPalette.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ColorPalette.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}