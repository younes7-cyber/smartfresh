import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future<void>.delayed(AppDurations.long);
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF007BFF), Color(0xFF0056B3)]),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Image.asset(
                        AppStrings.logoAsset,
                        width: 84,
                        height: 84,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 72),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.appName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('login'.tr(), style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 20),
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
                              Align(
                                alignment: Alignment.centerRight,
                                child: AppButton(
                                  textOnly: true,
                                  label: 'forgotPassword'.tr(),
                                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AppButton(
                                label: 'login'.tr(),
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup),
                                  child: Text('signupPrompt'.tr()),
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
            ],
          ),
        ),
      ),
    );
  }
}
