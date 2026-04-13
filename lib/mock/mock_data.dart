import 'package:flutter/material.dart';

import '../shared/models/notification_model.dart';
import '../shared/models/product_model.dart';

class MonthlyStat {
  const MonthlyStat({required this.month, required this.fresh, required this.expiringSoon, required this.expired});

  final String month;
  final double fresh;
  final double expiringSoon;
  final double expired;
}

class MockData {
  static final products = <ProductModel>[
    ProductModel(
      id: '1',
      name: 'Milk 1L',
      uid: 'A3F9X2B8K7',
      expired: DateTime.now().add(const Duration(days: 2, hours: 14)),
      zone: ProductZone.zone3,
      status: ProductStatus.expiringSoon,
    ),
    ProductModel(
      id: '2',
      name: 'Yogurt Pack',
      uid: 'K7BX2M9QA4',
      expired: DateTime.now().add(const Duration(days: 8)),
      zone: ProductZone.zone1,
      status: ProductStatus.fresh,
    ),
    ProductModel(
      id: '3',
      name: 'Lettuce',
      uid: 'Z9P1L8C4V6',
      expired: DateTime.now().subtract(const Duration(days: 1)),
      zone: ProductZone.expired,
      status: ProductStatus.expired,
    ),
    ProductModel(
      id: '4',
      name: 'Cheese Slice',
      uid: 'T2R8N5D1Q7',
      expired: DateTime.now().add(const Duration(days: 4)),
      zone: ProductZone.zone2,
      status: ProductStatus.fresh,
    ),
    ProductModel(
      id: '5',
      name: 'Orange Juice',
      uid: 'M8H4P2X6W9',
      expired: DateTime.now().add(const Duration(days: 1)),
      zone: ProductZone.zone3,
      status: ProductStatus.expiringSoon,
    ),
  ];

  static final notifications = <AppNotificationModel>[
    AppNotificationModel(
      id: 'n1',
      type: NotificationType.expiringSoon,
      title: 'Milk expires soon',
      description: 'Milk 1L expires in 2 days.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    AppNotificationModel(
      id: 'n2',
      type: NotificationType.expired,
      title: 'Yogurt expired',
      description: 'Yogurt Pack has expired.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotificationModel(
      id: 'n3',
      type: NotificationType.expiredBoxFull,
      title: 'Expired box full',
      description: 'Expired products box is full (10/10).',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotificationModel(
      id: 'n4',
      type: NotificationType.doorOpen,
      title: 'Zone 1 door open',
      description: 'Zone 1 door has been open for 5 min.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    AppNotificationModel(
      id: 'n5',
      type: NotificationType.zoneEmpty,
      title: 'Zone 2 empty',
      description: 'Zone 2 is currently empty.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static const monthlyStats = <MonthlyStat>[
    MonthlyStat(month: 'Jan', fresh: 34, expiringSoon: 8, expired: 4),
    MonthlyStat(month: 'Feb', fresh: 36, expiringSoon: 10, expired: 5),
    MonthlyStat(month: 'Mar', fresh: 38, expiringSoon: 11, expired: 6),
    MonthlyStat(month: 'Apr', fresh: 40, expiringSoon: 12, expired: 6),
    MonthlyStat(month: 'May', fresh: 42, expiringSoon: 10, expired: 5),
    MonthlyStat(month: 'Jun', fresh: 45, expiringSoon: 9, expired: 4),
    MonthlyStat(month: 'Jul', fresh: 48, expiringSoon: 12, expired: 6),
    MonthlyStat(month: 'Aug', fresh: 49, expiringSoon: 13, expired: 6),
    MonthlyStat(month: 'Sep', fresh: 47, expiringSoon: 11, expired: 5),
    MonthlyStat(month: 'Oct', fresh: 46, expiringSoon: 10, expired: 5),
    MonthlyStat(month: 'Nov', fresh: 44, expiringSoon: 9, expired: 4),
    MonthlyStat(month: 'Dec', fresh: 48, expiringSoon: 12, expired: 6),
  ];

  static final zoneProducts = <ProductZone, List<ProductModel>>{
    ProductZone.zone1: [
      products[1],
      ProductModel(
        id: '6',
        name: 'Butter',
        uid: 'BTR12345ZX',
        expired: DateTime.now().add(const Duration(days: 12)),
        zone: ProductZone.zone1,
        status: ProductStatus.fresh,
        icon: Icons.bakery_dining_rounded,
      ),
    ],
    ProductZone.zone2: [
      products[3],
      ProductModel(
        id: '7',
        name: 'Egg Tray',
        uid: 'EGGTRAY998',
        expired: DateTime.now().add(const Duration(days: 5)),
        zone: ProductZone.zone2,
        status: ProductStatus.fresh,
        icon: Icons.egg_rounded,
      ),
    ],
    ProductZone.zone3: [
      products[0],
      products[4],
    ],
    ProductZone.expired: [products[2]],
  };
}
