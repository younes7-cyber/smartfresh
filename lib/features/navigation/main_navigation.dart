import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import '../dashboard/dashboard_page.dart';
import '../notifications/notifications_page.dart';
import '../scan/scan_page.dart';
import '../settings/settings_page.dart';
import '../zones/zones_page.dart';

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    // ⚡ Clé de reconstruction pour forcer la mise à jour des traductions
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final pageKey = ValueKey('page_${locale.languageCode}_${themeMode.name}');

    // ✅ Plus de const, et la page ScanPage est détruite quand index != 2
    final pages = <Widget>[
      DashboardPage(key: pageKey),
      NotificationsPage(key: pageKey),
      // ScanPage n'est plus dans la liste permanente
      const SizedBox.shrink(),
      ZonesPage(key: pageKey),
      SettingsPage(key: pageKey),
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected:
                  ref.read(navigationIndexProvider.notifier).setIndex,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: primaryColor),
              unselectedIconTheme:
                  IconThemeData(color: onSurfaceColor.withValues(alpha: 0.6)),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_rounded),
                  label: Text('dashboard'.tr()),
                ),
                NavigationRailDestination(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_rounded),
                      if (unread > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            child: Text('$unread',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  label: Text('notifications'.tr()),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text('scan'.tr()),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.layers_rounded),
                  label: Text('zones'.tr()),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_rounded),
                  label: Text('settings'.tr()),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            // ✅ Affichage conditionnel : ScanPage détruite quand pas active
            Expanded(
              child: index == 2
                  ? ScanPage(key: pageKey)
                  : IndexedStack(index: index, children: pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: index == 2
          ? ScanPage(key: pageKey)
          : IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomAppBar(
          color: surfaceColor,
          elevation: 0,
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'dashboard'.tr(),
                isSelected: index == 0,
                onTap: () =>
                    ref.read(navigationIndexProvider.notifier).setIndex(0),
                primaryColor: primaryColor,
                onSurfaceColor: onSurfaceColor,
              ),
              _NavItem(
                icon: Icons.notifications_rounded,
                label: 'notifications'.tr(),
                isSelected: index == 1,
                badge: unread > 0 ? '$unread' : null,
                onTap: () =>
                    ref.read(navigationIndexProvider.notifier).setIndex(1),
                primaryColor: primaryColor,
                onSurfaceColor: onSurfaceColor,
              ),
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.layers_rounded,
                label: 'zones'.tr(),
                isSelected: index == 3,
                onTap: () =>
                    ref.read(navigationIndexProvider.notifier).setIndex(3),
                primaryColor: primaryColor,
                onSurfaceColor: onSurfaceColor,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'settings'.tr(),
                isSelected: index == 4,
                onTap: () =>
                    ref.read(navigationIndexProvider.notifier).setIndex(4),
                primaryColor: primaryColor,
                onSurfaceColor: onSurfaceColor,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _ModernFAB(
        onPressed: () =>
            ref.read(navigationIndexProvider.notifier).setIndex(2),
        isActive: index == 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
// ── NavItem / FAB restent identiques à la version précédente ─────────────
// (copiez-la depuis ma réponse antérieure)

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color onSurfaceColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.onSurfaceColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? primaryColor : onSurfaceColor,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primaryColor : onSurfaceColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const _ModernFAB({required this.onPressed, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return ScaleTransition(
      scale: AlwaysStoppedAnimation(isActive ? 1.1 : 1.0),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: isActive ? primaryColor : Colors.white,
        elevation: isActive ? 8 : 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 28,
          color: isActive ? Colors.white : primaryColor,
        ),
      ),
    );
  }
}