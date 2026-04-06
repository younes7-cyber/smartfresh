import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartfresh/app.dart';
import 'package:smartfresh/core/state/app_providers.dart';

void main() {
  testWidgets('boots the SmartFresh splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance())],
          child: const SmartFreshApp(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('SmartFresh'), findsOneWidget);
  });
}
