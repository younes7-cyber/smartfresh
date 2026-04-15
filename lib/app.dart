import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/features/auth/auth_guard.dart';

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

      onGenerateRoute: (settings) {
        late final Widget page;

        switch (settings.name) {
          // ── Public ──
          case AppRoutes.splash:
            page = const SplashScreen();   // handles auto-login redirect
          case AppRoutes.login:
            page = const LoginPage();
          case AppRoutes.signup:
            page = const SignupPage();
          case AppRoutes.forgotPassword:
            page = const ForgotPasswordPage();

          // ── Auth required, verification handled by page ──
          case AppRoutes.verifyEmail:
            page = const AuthRequiredGuard(child: EmailVerificationPage());

          // ── Auth + email verified required ──
          case AppRoutes.main:
            page = const AuthGuard(child: MainNavigation());
          case AppRoutes.dashboard:
            page = const AuthGuard(child: DashboardPage());
          case AppRoutes.notifications:
            page = const AuthGuard(child: NotificationsPage());
          case AppRoutes.scan:
            page = const AuthGuard(child: ScanPage());
          case AppRoutes.zones:
            page = const AuthGuard(child: ZonesPage());
          case AppRoutes.settings:
            page = const AuthGuard(child: SettingsPage());
          case AppRoutes.barcodeGenerator:
            page = const AuthGuard(child: BarcodeGeneratorPage());

          default:
            page = const SplashScreen();
        }

        return buildSlideFadeRoute(page, settings: settings);
      },

      initialRoute: AppRoutes.splash,
    );
  }
}