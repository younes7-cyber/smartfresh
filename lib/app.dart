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
    final themeMode = ref.watch(themeModeProvider);

    // ✅ Utilisez context.locale (fourni par EasyLocalization) au lieu du provider
    final routeKey = ValueKey('${context.locale.languageCode}_${themeMode.name}');

    return MaterialApp(
      key: ValueKey(context.locale.languageCode), // 👈 clé supplémentaire pour forcer la reconstruction complète
      title: 'SmartFresh',
      debugShowCheckedModeBanner: false,
      locale: context.locale,                       // 👈 locale gérée par EasyLocalization
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      onGenerateRoute: (settings) {
                late final Widget page;

        switch (settings.name) {
          case AppRoutes.splash:
            page = SplashScreen(key: routeKey);
          case AppRoutes.login:
            page = LoginPage(key: routeKey);
          case AppRoutes.signup:
            page = SignupPage(key: routeKey);
          case AppRoutes.forgotPassword:
            page = ForgotPasswordPage(key: routeKey);

          // Auth required, verification handled by page
          case AppRoutes.verifyEmail:
            page = AuthRequiredGuard(key: routeKey, child: EmailVerificationPage());

          // Auth + email verified required
          case AppRoutes.main:
            page = AuthGuard(key: routeKey, child: MainNavigation());
          case AppRoutes.dashboard:
            page = AuthGuard(key: routeKey, child: DashboardPage());
          case AppRoutes.notifications:
            page = AuthGuard(key: routeKey, child: NotificationsPage());
          case AppRoutes.scan:
            page = AuthGuard(key: routeKey, child: ScanPage());
          case AppRoutes.zones:
            page = AuthGuard(key: routeKey, child: ZonesPage());
          case AppRoutes.settings:
            page = AuthGuard(key: routeKey, child: SettingsPage());
          case AppRoutes.barcodeGenerator:
            page = AuthGuard(key: routeKey, child: BarcodeGeneratorPage());

          default:
            page = SplashScreen(key: routeKey);
        }

        return buildSlideFadeRoute(page, settings: settings);
      },

      initialRoute: AppRoutes.splash,
    );
  }
}