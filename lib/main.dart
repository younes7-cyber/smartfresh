import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfresh/service/fcm_token.dart';

import 'app.dart';
import 'core/state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Register FCM background handler BEFORE Firebase.initializeApp
  // Must be top-level and annotated @pragma('vm:entry-point') in fcm_service.dart
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2️⃣ Initialize Firebase
  await Firebase.initializeApp();

  // 3️⃣ Initialize FCM — sets up permissions, channel, listeners, topic sub
  await FcmService.instance.initialize();

  // 4️⃣ EasyLocalization
  await EasyLocalization.ensureInitialized();

  // 5️⃣ SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SmartFreshApp(),
      ),
    ),
  );
}