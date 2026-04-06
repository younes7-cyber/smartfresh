import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/navigation/page_transitions.dart';
import 'core/state/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/email_verification_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/navigation/main_navigation.dart';
import 'features/notifications/notifications_page.dart';
import 'features/scan/scan_page.dart';
import 'features/settings/barcode_generator_page.dart';
import 'features/settings/settings_page.dart';
import 'features/splash/splash_screen.dart';
import 'features/zones/zones_page.dart';

class SmartFreshApp extends ConsumerWidget {
  const SmartFreshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SmartFresh',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final textDirection = locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
        return Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
      onGenerateRoute: (settings) {
        Widget page = const SplashScreen();
        switch (settings.name) {
          case AppRoutes.splash:
            page = const SplashScreen();
            break;
          case AppRoutes.login:
            page = const LoginPage();
            break;
          case AppRoutes.signup:
            page = const SignupPage();
            break;
          case AppRoutes.forgotPassword:
            page = const ForgotPasswordPage();
            break;
          case AppRoutes.verifyEmail:
            page = const EmailVerificationPage();
            break;
          case AppRoutes.main:
            page = const MainNavigation();
            break;
          case AppRoutes.dashboard:
            page = const DashboardPage();
            break;
          case AppRoutes.notifications:
            page = const NotificationsPage();
            break;
          case AppRoutes.scan:
            page = const ScanPage();
            break;
          case AppRoutes.zones:
            page = const ZonesPage();
            break;
          case AppRoutes.settings:
            page = const SettingsPage();
            break;
          case AppRoutes.barcodeGenerator:
            page = const BarcodeGeneratorPage();
            break;
        }

        return buildSlideFadeRoute(page, settings: settings);
      },
      initialRoute: AppRoutes.splash,
    );
  }
}
