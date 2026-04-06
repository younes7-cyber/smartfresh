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

    final pages = const [
      DashboardPage(),
      NotificationsPage(),
      ScanPage(),
      ZonesPage(),
      SettingsPage(),
    ];

    if (isTablet) {
      return Scaffold(
        body: Row(
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: ref.read(navigationIndexProvider.notifier).setIndex,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded),
                if (unread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: CircleAvatar(radius: 8, child: Text('$unread', style: const TextStyle(fontSize: 10))),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          const NavigationDestination(icon: Icon(Icons.layers_rounded), label: 'Zones'),
          const NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
      floatingActionButton: index == 2
          ? FloatingActionButton(
              onPressed: () => ref.read(navigationIndexProvider.notifier).setIndex(2),
              child: const Icon(Icons.qr_code_scanner),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
