import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/state/app_providers.dart';
import '../../shared/widgets/app_button.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('SF')),
              title: const Text('SmartFresh User'),
              subtitle: const Text('user@smartfresh.app'),
              trailing: TextButton(onPressed: () {}, child: Text('editProfile'.tr())),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text('language'.tr()),
              subtitle: Text(locale.languageCode.toUpperCase()),
              onTap: () => _showLocalePicker(context, ref),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: Text('theme'.tr()),
              subtitle: Text(themeMode == ThemeMode.dark ? 'Dark' : 'Light'),
              value: themeMode == ThemeMode.dark,
              onChanged: (value) => ref.read(themeModeProvider.notifier).setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_rounded),
              title: Text('barcodeGenerator'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.barcodeGenerator),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('logout'.tr()),
                    content: Text('logoutConfirm'.tr()),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('no'.tr())),
                      ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('yes'.tr())),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocalePicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('العربية'), onTap: () async { await ref.read(localeProvider.notifier).setLocale(const Locale('ar')); await context.setLocale(const Locale('ar')); if (context.mounted) Navigator.pop(sheetContext); }),
            ListTile(title: const Text('Français'), onTap: () async { await ref.read(localeProvider.notifier).setLocale(const Locale('fr')); await context.setLocale(const Locale('fr')); if (context.mounted) Navigator.pop(sheetContext); }),
            ListTile(title: const Text('English'), onTap: () async { await ref.read(localeProvider.notifier).setLocale(const Locale('en')); await context.setLocale(const Locale('en')); if (context.mounted) Navigator.pop(sheetContext); }),
          ],
        ),
      ),
    );
  }
}
