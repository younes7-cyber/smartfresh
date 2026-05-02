import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/alerts_service.dart';
import '../../shared/widgets/notification_card.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        actions: [
          TextButton(
            onPressed: () async {
              await AlertsService.markAllAsRead();
            },
            child: Text('markAllAsRead'.tr()),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Text('noNotifications'.tr()),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return NotificationCard(
                notification: item,
                onDismiss: () async {
                  await AlertsService.deleteAlert(item.id);
                },
                onTap: () async {
                  // Mark as read when tapped
                  await AlertsService.markAsRead(item.id);
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('loadError'.tr()),
        ),
      ),
    );
  }
}
