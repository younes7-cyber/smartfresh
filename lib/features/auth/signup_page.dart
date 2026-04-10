import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smartfresh/features/auth/auth_service.dart';

import '../../core/constants.dart';
import '../../core/theme/color_palette.dart';
import '../../shared/widgets/app_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  int get _strength {
    final v = _passwordController.text;
    if (v.isEmpty) return 0;
    if (v.length >= 12) return 4;
    if (v.length >= 9) return 3;
    if (v.length >= 6) return 2;
    return 1;
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1:
        return 'pwWeak'.tr();
      case 2:
        return 'pwFair'.tr();
      case 3:
        return 'pwGood'.tr();
      case 4:
        return 'pwStrong'.tr();
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1:
        return ColorPalette.danger;
      case 2:
        return ColorPalette.warning;
      case 3:
        return ColorPalette.success;
      case 4:
        return ColorPalette.primary;
      default:
        return Colors.transparent;
    }
  }

  void _shake() => _shakeController.forward(from: 0);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _authError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      _shake();
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.instance.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      // Navigate to verification page; user is signed in but not verified
      Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail);
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
          // ── Header ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.28,
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
                child: Stack(
                  children: [
                    // Back button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              AppStrings.logoAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.ac_unit_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'createAccount'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ──
          Positioned.fill(
            top: size.height * 0.22,
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
                              // ── Step indicator ──
                              _StepIndicator(currentStep: 1),
                              const SizedBox(height: 20),

                              // ── Error Banner ──
                              if (_authError != null) ...[
                                _ErrorBanner(message: _authError!),
                                const SizedBox(height: 16),
                              ],

                              // ── Username ──
                              AppTextField(
                                controller: _usernameController,
                                label: 'username'.tr(),
                                validator: (v) {
                                  if (v == null || v.trim().length < 3)
                                    return 'usernameMin'.tr();
                                  if (v.contains(' '))
                                    return 'usernameNoSpaces'.tr();
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Email ──
                              AppTextField(
                                controller: _emailController,
                                label: 'email'.tr(),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'requiredField'.tr();
                                  if (!v.contains('@'))
                                    return 'invalidEmail'.tr();
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Password ──
                              AppTextField(
                                controller: _passwordController,
                                label: 'password'.tr(),
                                obscureText: !_showPassword,
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.length < 6)
                                    return 'passwordMin'.tr();
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
                              const SizedBox(height: 10),

                              // ── Strength Bar ──
                              _StrengthBar(
                                strength: _strength,
                                label: _strengthLabel,
                                color: _strengthColor,
                              ),
                              const SizedBox(height: 24),

                              // ── Submit ──
                              _GradientButton(
                                label: 'createAccount'.tr(),
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                              const SizedBox(height: 20),

                              // ── Login link ──
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'alreadyHaveAccount'.tr(),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : ColorPalette.secondary,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: ' ${'login'.tr()}',
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

// ── Strength Bar ──────────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.strength,
    required this.label,
    required this.color,
  });
  final int strength;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final active = index < strength;
            final colors = [
              ColorPalette.danger,
              ColorPalette.warning,
              ColorPalette.success,
              ColorPalette.primary,
            ];
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? colors[index]
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) {
        final isActive = i + 1 == currentStep;
        final isDone = i + 1 < currentStep;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 32 : 24,
              height: 8,
              decoration: BoxDecoration(
                color: isActive || isDone
                    ? ColorPalette.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            if (i < 1) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

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
                      strokeWidth: 2.5, color: Colors.white),
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
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}