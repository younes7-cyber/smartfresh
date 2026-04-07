import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int get _strength {
    final value = _passwordController.text;
    if (value.length >= 12) return 4;
    if (value.length >= 9) return 3;
    if (value.length >= 6) return 2;
    return value.isEmpty ? 0 : 1;
  }

  Future<void> _submit() async {
  /*  FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future<void>.delayed(AppDurations.long);
    if (!mounted) return;
    setState(() => _loading = false);*/
    Navigator.of(context).pushReplacementNamed(AppRoutes.verifyEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('signup'.tr())),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _usernameController,
                      label: 'username'.tr(),
                      validator: (value) {
                        if (value == null || value.trim().length < 3) return 'usernameMin'.tr();
                        if (value.contains(' ')) return 'usernameNoSpaces'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'email'.tr(),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'requiredField'.tr();
                        if (!value.contains('@')) return 'invalidEmail'.tr();
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'password'.tr(),
                      obscureText: !_showPassword,
                      validator: (value) {
                        if (value == null || value.length < 6) return 'passwordMin'.tr();
                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StrengthBar(strength: _strength),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'createAccount'.tr(),
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('alreadyHaveAccount'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.red, Colors.amber, Colors.green, const Color(0xFF007BFF)];
    return Row(
      children: List.generate(4, (index) {
        final active = index < strength;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            height: 8,
            decoration: BoxDecoration(
              color: active ? colors[index] : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
