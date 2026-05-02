import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/color_palette.dart';
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

    final pages = const [
      DashboardPage(),
      NotificationsPage(),
      ScanPage(),
      ZonesPage(),
      SettingsPage(),
    ];

    if (isTablet) {
      return Scaffold(
        body:
        
         Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: ref.read(navigationIndexProvider.notifier).setIndex,
              labelType: NavigationRailLabelType.all,
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                NavigationRailDestination(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_rounded),
                      if (unread > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: CircleAvatar(radius: 8, child: Text('$unread', style: const TextStyle(fontSize: 10))),
                        ),
                    ],
                  ),
                  label: const Text('Notifications'),
                ),
                const NavigationRailDestination(icon: Icon(Icons.qr_code_scanner), label: Text('Scan')),
                const NavigationRailDestination(icon: Icon(Icons.layers_rounded), label: Text('Zones')),
                const NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages[index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
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
      color: Colors.white,
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
                label: 'Dashboard',
                isSelected: index == 0,
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(0),
              ),
              _NavItem(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                isSelected: index == 1,
                badge: unread > 0 ? '$unread' : null,
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
              ),
              SizedBox(width: 56), // FAB space
              _NavItem(
                icon: Icons.layers_rounded,
                label: 'Zones',
                isSelected: index == 3,
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: index == 4,
                onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(4),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _ModernFAB(
        onPressed: () => ref.read(navigationIndexProvider.notifier).setIndex(2),
        isActive: index == 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
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
                    color: isSelected ? ColorPalette.primary.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? ColorPalette.primary : ColorPalette.secondary,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorPalette.danger,
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
                color: isSelected ? ColorPalette.primary : ColorPalette.secondary,
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

  const _ModernFAB({
    required this.onPressed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: AlwaysStoppedAnimation(isActive ? 1.1 : 1.0),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: isActive ? ColorPalette.primary : Colors.white,
        elevation: isActive ? 8 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 28,
          color: isActive ? Colors.white : ColorPalette.secondary,
        ),
      ),
    );
  }
}
