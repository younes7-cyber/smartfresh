
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/features/auth/auth_service.dart';

import '../../core/constants.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/color_palette.dart';

/// Provider that fetches the current user's Firestore profile
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return AuthService.instance.fetchUserProfile();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final profileAsync = ref.watch(userProfileProvider);
   final currentLocale = context.locale;
    ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User Profile Card ──
          profileAsync.when(
            loading: () => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: ColorPalette.primary,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: const Text('...'),
                subtitle: const Text('...'),
              ),
            ),
            error: (_, __) => _UserProfileCard(
              username: FirebaseAuth.instance.currentUser?.displayName ?? '—',
              email: FirebaseAuth.instance.currentUser?.email ?? '—',
            ),
            data: (profile) => _UserProfileCard(
              username: profile?['username'] as String? ??
                  FirebaseAuth.instance.currentUser?.displayName ??
                  '—',
              email: profile?['email'] as String? ??
                  FirebaseAuth.instance.currentUser?.email ??
                  '—',
            ),
          ),

          const SizedBox(height: 12),

          // ── Language ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text('language'.tr()),
         subtitle: Text(_languageLabel(currentLocale.languageCode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLocalePicker(context, ref),
            ),
          ),

          const SizedBox(height: 12),

          // ── Theme ──
          Card(
            child: SwitchListTile(
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.nightlight_round
                    : Icons.wb_sunny_rounded,
                color: ColorPalette.primary,
              ),
              title: Text('theme'.tr()),
              subtitle: Text(themeMode == ThemeMode.dark ? 'dark'.tr() : 'light'.tr()),
              value: themeMode == ThemeMode.dark,
              activeThumbColor: ColorPalette.primary,
              onChanged: (value) => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
            ),
          ),

          const SizedBox(height: 12),

          // ── Barcode Generator ──
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_rounded,
                  color: ColorPalette.primary),
              title: Text('barcodeGenerator'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.barcodeGenerator),
            ),
          ),

          const SizedBox(height: 12),

          // ── Logout ──
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: ColorPalette.danger),
              title: Text(
                'logout'.tr(),
                style: const TextStyle(color: ColorPalette.danger),
              ),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'ar':
        return '🇸🇦 العربية';
      case 'fr':
        return '🇫🇷 Français';
      case 'en':
        return '🇬🇧 English';
      default:
        return code.toUpperCase();
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('logoutConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('no'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('yes'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AuthService.instance.signOut();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }
Future<void> _showLocalePicker(BuildContext context, WidgetRef ref) async {
    // ✅ Capture l'instance d'EasyLocalization AVANT le dialogue asynchrone
    final easyLocalization = EasyLocalization.of(context);

    final chosenLang = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                   const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _LocaleTile(
              flag: '🇸🇦',
              label: 'العربية',
              code: 'ar',
              onTap: () => Navigator.pop(sheetContext, 'ar'),
            ),
            _LocaleTile(
              flag: '🇫🇷',
              label: 'Français',
              code: 'fr',
              onTap: () => Navigator.pop(sheetContext, 'fr'),
            ),
            _LocaleTile(
              flag: '🇬🇧',
              label: 'English',
              code: 'en',
              onTap: () => Navigator.pop(sheetContext, 'en'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );   if (chosenLang != null && context.mounted) {
      final locale = Locale(chosenLang);
      // ✅ Utilise l'instance sauvegardée (pas de recherche d'ancêtre dangereuse)
      await easyLocalization?.setLocale(locale);
      await ref.read(localeProvider.notifier).setLocale(locale);
    }
  }
}

// ─── Tuile simplifiée ────────────────────────────────────────────
class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.flag,
    required this.label,
    required this.code,
    required this.onTap,
  });

  final String flag;
  final String label;
  final String code;
  final VoidCallback onTap;                     // ← simple callback

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      onTap: onTap,
    );
  }
}

// ── User Profile Card ─────────────────────────────────────────────────────────

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.username, required this.email});
  final String username;
  final String email;

  String get _initials {
    if (username.isEmpty || username == '—') return 'SF';
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Username + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      color: ColorPalette.secondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Locale Tile ───────────────────────────────────────────────────────────────

