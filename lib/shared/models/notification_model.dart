import 'package:flutter/material.dart';

enum NotificationType {
  expiringSoon,
  expired,
  expiredBoxFull,
  doorOpen,
  zoneEmpty,
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isRead = false,
    this.priority = 2,
    this.context,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isRead;
  final int priority; // 1: red, 2: yellow, 3: green
  final String? context;

  /// Factory constructor to create from Firebase database data
  factory AppNotificationModel.fromFirebase({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return AppNotificationModel(
      id: id,
      type: NotificationType.values.first, // Default type
      title: data['name'] ?? 'Alert',
      description: data['context'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      isRead: data['isRead'] ?? false,
      priority: data['priority'] ?? 2,
      context: data['context'],
    );
  }

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      description: description,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      priority: priority,
      context: context,
    );
  }

  /// Get color based on priority: 1=red, 2=yellow, 3=green
  Color get color {
    switch (priority) {
      case 1:
        return const Color(0xFFDC3545); // Red
      case 2:
        return const Color(0xFFFFC107); // Yellow
      case 3:
        return const Color(0xFF28A745); // Green
      default:
        return const Color(0xFF6C757D); // Gray
    }
  }

  String relativeTime(DateTime now) {
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays} days ago';
  }
}
