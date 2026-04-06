import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../shared/widgets/app_button.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _timer;
  int _cooldown = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldown == 0) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('verifyEmail'.tr())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_read_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text('checkInbox'.tr(), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('verificationSent'.tr(), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              AppButton(
                outlined: true,
                label: _cooldown > 0 ? '${'resendEmail'.tr()} ($_cooldown)' : 'resendEmail'.tr(),
                onPressed: _cooldown > 0
                    ? null
                    : () {
                        setState(() => _cooldown = 30);
                        _startTimer();
                      },
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'verifiedContinue'.tr(),
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.main),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
