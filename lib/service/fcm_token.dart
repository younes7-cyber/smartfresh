import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as gauth;

// ── Background message handler — MUST be top-level ───────────────────────────
// Registered in main.dart via FirebaseMessaging.onBackgroundMessage(...)

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 [Background] FCM: "${message.notification?.title}"');
  // Firebase is already initialized by the system before this runs.
  // Heavy work (DB writes, etc.) can be done here safely.
}

// ── FCM Service ───────────────────────────────────────────────────────────────

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// High-importance Android channel — must match the channel_id sent by server
  static const _channel = AndroidNotificationChannel(
    'smartfresh_alerts',
    'SmartFresh Alerts',
    description: 'Fridge and product expiry alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ── Initialize (call once in main.dart after Firebase.initializeApp) ──────

  Future<void> initialize() async {
    // 1️⃣ Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
    );
    debugPrint('🔔 FCM permission status: ${settings.authorizationStatus}');

    // 2️⃣ Create the high-importance Android channel
    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // 3️⃣ Initialize flutter_local_notifications for foreground display
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // permission already requested above
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // 4️⃣ Make notifications appear even when app is in foreground (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5️⃣ Foreground message listener
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6️⃣ Background → foreground tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 7️⃣ Terminated state: check if app was opened by a notification
    final terminated = await _messaging.getInitialMessage();
    if (terminated != null) _onNotificationTap(terminated);

    // 8️⃣ Subscribe to 'alerts' topic
    await subscribeToAlerts();

    // 9️⃣ Log token for debugging
    if (!kIsWeb) {
      final token = await _messaging.getToken();
      debugPrint('📱 FCM Device Token: $token');
    }
  }

  // ── Topic subscription ────────────────────────────────────────────────────

  Future<void> subscribeToAlerts() async {
    try {
      await _messaging.subscribeToTopic('alerts');
      debugPrint('✅ Subscribed to topic: alerts');
    } catch (e) {
      debugPrint('❌ subscribeToTopic error: $e');
    }
  }

  Future<void> unsubscribeFromAlerts() async {
    try {
      await _messaging.unsubscribeFromTopic('alerts');
      debugPrint('✅ Unsubscribed from topic: alerts');
    } catch (e) {
      debugPrint('❌ unsubscribeFromTopic error: $e');
    }
  }

  Future<String?> getToken() => _messaging.getToken().catchError((e) {
        debugPrint('❌ getToken error: $e');
        return null;
      });

  // ── Foreground handler ────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 [Foreground] FCM: "${message.notification?.title}"');
    final notif = message.notification;
    if (notif == null) return;

    // Android requires an explicit local notification to show in foreground
    await _localNotifications.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(notif.body ?? ''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: "${message.notification?.title}"');
    
  }

  void _onLocalTap(NotificationResponse response) {
    debugPrint('👆 Local notification tapped, payload: ${response.payload}');
  }

  // ── Send FCM via HTTP v1 API (service account OAuth2) ────────────────────
  //
  // ⚠️ SECURITY NOTE: In production, NEVER call this from the Flutter client.
  //    Move this to a Firebase Cloud Function or your backend.
  //    Bundling the service account key in the app exposes your credentials.
  //    This implementation is for DEVELOPMENT / TESTING only.
  //
  // Message format (matches your server template):
  //   {
  //     notification: { title: name, body: "${context} | ${time}" },
  //     topic: 'alerts'
  //   }

  Future<void> sendAlertNotification({
    required String name,     // → notification title
    required String context,  // → first part of body (e.g. "Milk expires soon")
    required String time,     // → second part of body (e.g. "14:32")
  }) async {
    if (kIsWeb) {
      debugPrint('⚠️ sendAlertNotification: not supported on web');
      return;
    }

    try {
      final serviceAccount = await _loadServiceAccount();
      if (serviceAccount == null) return;

      final accessToken = await _getOAuthToken(serviceAccount);
      if (accessToken == null) return;

      final projectId = serviceAccount['project_id'] as String;

      // Exact message structure matching your template
      final payload = jsonEncode({
        'message': {
          'notification': {
            'title': name,
            'body': '$context | $time',
          },
          'topic': 'alerts',
          'android': {
            'notification': {
              'channel_id': 'smartfresh_alerts',
              'priority': 'HIGH',
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      });

      final httpClient = HttpClient();
      final request = await httpClient.postUrl(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
      );
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.write(payload);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        debugPrint('✅ FCM alert sent: "$name" | "$context | $time"');
      } else {
        debugPrint(
            '❌ FCM send failed [${response.statusCode}]: $body');
      }

      httpClient.close(force: false);
    } catch (e, st) {
      debugPrint('❌ sendAlertNotification error: $e\n$st');
    }
  }

  /// Send alert via FCM to all users subscribed to 'alerts' topic
  Future<void> sendAlertViaFcm({
    required String name,
    required String context,
  }) async {
    if (kIsWeb) {
      debugPrint('⚠️ sendAlertViaFcm: not supported on web');
      return;
    }

    try {
      final serviceAccount = await _loadServiceAccount();
      if (serviceAccount == null) return;

      final accessToken = await _getOAuthToken(serviceAccount);
      if (accessToken == null) return;

      final projectId = serviceAccount['project_id'] as String;

      final payload = jsonEncode({
        'message': {
          'notification': {
            'title': name,
            'body': context,
          },
          'topic': 'alerts',
          'android': {
            'notification': {
              'channel_id': 'smartfresh_alerts',
              'priority': 'HIGH',
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      });

      final httpClient = HttpClient();
      final request = await httpClient.postUrl(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
      );
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $accessToken')
        ..set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.write(payload);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        debugPrint('✅ FCM alert sent to topic "alerts": "$name" | "$context"');
      } else {
        debugPrint(
            '❌ FCM send failed [${response.statusCode}]: $body');
      }

      httpClient.close(force: false);
    } catch (e, st) {
      debugPrint('❌ sendAlertViaFcm error: $e\n$st');
    }
  }

  // ── Load service account JSON from assets ─────────────────────────────────

  Future<Map<String, dynamic>?> _loadServiceAccount() async {
    try {
      final raw = await rootBundle.loadString(
          'assets/smartfresh-69244-f8d65ec1b9dc.json');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to load service account JSON: $e');
      return null;
    }
  }

  // ── Get OAuth2 access token from service account ──────────────────────────

  Future<String?> _getOAuthToken(Map<String, dynamic> serviceAccount) async {
    try {
      final credentials =
          gauth.ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await gauth.clientViaServiceAccount(credentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('❌ OAuth2 token error: $e');
      return null;
    }
  }
}