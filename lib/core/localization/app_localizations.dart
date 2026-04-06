import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.context);

  final BuildContext context;

  static AppLocalizations of(BuildContext context) => AppLocalizations(context);

  String t(String key) => key.tr();

  static bool isRtl(Locale locale) => locale.languageCode == 'ar';
}
