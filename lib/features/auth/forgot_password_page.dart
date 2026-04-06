import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('resetLinkSent'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('forgotPassword'.tr())),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: AppTextField(
                    controller: _emailController,
                    label: 'email'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'requiredField'.tr();
                      if (!value.contains('@')) return 'invalidEmail'.tr();
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(label: 'sendResetLink'.tr(), onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
