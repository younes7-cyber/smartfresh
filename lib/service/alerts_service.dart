import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/notification_model.dart';

final _db = FirebaseDatabase.instance.ref();

class AlertsService {
  static const _alertsPath = 'frigo/TBNp1Y68mMV9nODEw6Kj/alerts';

  /// Fetch all alerts from Firebase in real-time (sorted by newest first)
  static Stream<List<AppNotificationModel>> getAlertsStream() {
    return _db.child(_alertsPath).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];
      
      final data = snapshot.value as Map?;
      if (data == null) return [];

      final alerts = data.entries
          .map((e) {
            try {
              final alertData = Map<String, dynamic>.from(e.value as Map);
              return AppNotificationModel.fromFirebase(
                id: e.key,
                data: alertData,
              );
            } catch (e) {
              return null;
            }
          })
          .whereType<AppNotificationModel>()
          .toList();

      // Sort by newest first (descending order by createdAt)
      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    });
  }

  /// Mark a specific alert as read
  static Future<void> markAsRead(String alertId) async {
    await _db.child('$_alertsPath/$alertId/isRead').set(true);
  }

  /// Delete a specific alert
  static Future<void> deleteAlert(String alertId) async {
    await _db.child('$_alertsPath/$alertId').remove();
  }

  /// Mark all alerts as read
  static Future<void> markAllAsRead() async {
    final snapshot = await _db.child(_alertsPath).get();
    if (!snapshot.exists) return;

    final data = snapshot.value as Map?;
    if (data == null) return;

    for (final key in data.keys) {
      await _db.child('$_alertsPath/$key/isRead').set(true);
    }
  }
}

// Stream provider for real-time alerts
final alertsStreamProvider = StreamProvider<List<AppNotificationModel>>((ref) {
  return AlertsService.getAlertsStream();
});
