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
  });

  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isRead;

  AppNotificationModel copyWith({bool? isRead}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      description: description,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Color get color {
    switch (type) {
      case NotificationType.expiringSoon:
        return const Color(0xFFFFC107);
      case NotificationType.expired:
      case NotificationType.expiredBoxFull:
        return const Color(0xFFDC3545);
      case NotificationType.doorOpen:
        return const Color(0xFF007BFF);
      case NotificationType.zoneEmpty:
        return const Color(0xFF6C757D);
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.expiringSoon:
        return Icons.hourglass_bottom_rounded;
      case NotificationType.expired:
        return Icons.warning_amber_rounded;
      case NotificationType.expiredBoxFull:
        return Icons.inventory_2_rounded;
      case NotificationType.doorOpen:
        return Icons.door_front_door_rounded;
      case NotificationType.zoneEmpty:
        return Icons.layers_clear_rounded;
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
