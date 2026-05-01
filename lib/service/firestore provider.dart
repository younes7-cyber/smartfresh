// ignore_for_file: file_names

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/product_model.dart';
import 'fcm_token.dart';

final _db = FirebaseDatabase.instance.ref();

// Database URL

// ── Fridge paths ──────────────────────────────────────────────────────────────

class FridgePaths {
  static const _col = 'frigo';

  // Fixed hardware fridge ID — used for ALL reads AND writes
  static const _fixedId = 'TBNp1Y68mMV9nODEw6Kj';
  static const fridgeDoc = '$_col/$_fixedId';

  // Sub-collection paths (now just nested paths in the database)
  static const zone1 = '$fridgeDoc/zone1';
  static const zone2 = '$fridgeDoc/zone2';
  static const zone3 = '$fridgeDoc/zone3';
  static const pirimi = '$fridgeDoc/pirimi';

  /// Returns the collection path for a given zone name string
  static String collectionForZone(String zoneName) => '$fridgeDoc/$zoneName';
}

// ── Zone StreamProviders — real-time via .onValue ────────────────────────────

final zone1Provider = StreamProvider<List<ProductModel>>((ref) {
  return _db.child(FridgePaths.zone1).onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];
    final data = snapshot.value as Map?;
    if (data == null) return [];
    return data.entries
        .map((e) => ProductModel.fromRealtimeDb(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
              ProductZone.zone1,
            ))
        .toList();
  });
});

final zone2Provider = StreamProvider<List<ProductModel>>((ref) {
  return _db.child(FridgePaths.zone2).onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];
    final data = snapshot.value as Map?;
    if (data == null) return [];
    return data.entries
        .map((e) => ProductModel.fromRealtimeDb(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
              ProductZone.zone2,
            ))
        .toList();
  });
});

final zone3Provider = StreamProvider<List<ProductModel>>((ref) {
  return _db.child(FridgePaths.zone3).onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];
    final data = snapshot.value as Map?;
    if (data == null) return [];
    return data.entries
        .map((e) => ProductModel.fromRealtimeDb(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
              ProductZone.zone3,
            ))
        .toList();
  });
});

final pirimiProvider = StreamProvider<List<ProductModel>>((ref) {
  return _db.child(FridgePaths.pirimi).onValue.map((event) {
    final snapshot = event.snapshot;
    if (!snapshot.exists) return [];
    final data = snapshot.value as Map?;
    if (data == null) return [];
    return data.entries
        .map((e) => ProductModel.fromRealtimeDb(
              Map<String, dynamic>.from(e.value as Map),
              e.key,
              ProductZone.expired,
            ))
        .toList();
  });
});

// ── Dashboard count StreamProviders ──────────────────────────────────────────

/// Total = zone1 + zone2 + zone3 (real-time combined stream)
final totalProductsProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>.broadcast();

  final refs = [
    _db.child(FridgePaths.zone1).onValue,
    _db.child(FridgePaths.zone2).onValue,
    _db.child(FridgePaths.zone3).onValue,
  ];

  final snapshots = <DataSnapshot?>[null, null, null];

  void emitTotal() {
    int total = 0;
    for (final snap in snapshots) {
      if (snap != null && snap.exists) {
        final data = snap.value as Map?;
        total += data?.length ?? 0;
      }
    }
    controller.add(total);
  }

  for (var i = 0; i < refs.length; i++) {
    refs[i].listen((event) {
      snapshots[i] = event.snapshot;
      emitTotal();
    });
  }

  return controller.stream;
});

/// Fresh = zone1 + zone2
final freshProductsProvider = StreamProvider<int>((ref) {
  final controller = StreamController<int>.broadcast();

  final refs = [
    _db.child(FridgePaths.zone1).onValue,
    _db.child(FridgePaths.zone2).onValue,
  ];

  final snapshots = <DataSnapshot?>[null, null];

  void emitFresh() {
    int total = 0;
    for (final snap in snapshots) {
      if (snap != null && snap.exists) {
        final data = snap.value as Map?;
        total += data?.length ?? 0;
      }
    }
    controller.add(total);
  }

  for (var i = 0; i < refs.length; i++) {
    refs[i].listen((event) {
      snapshots[i] = event.snapshot;
      emitFresh();
    });
  }

  return controller.stream;
});

/// Expiring soon = zone3
final expiringSoonCountProvider = StreamProvider<int>((ref) {
  return _db.child(FridgePaths.zone3).onValue.map((event) {
    if (!event.snapshot.exists) return 0;
    final data = event.snapshot.value as Map?;
    return data?.length ?? 0;
  });
});

/// Expired = pirimi
final expiredCountProvider = StreamProvider<int>((ref) {
  return _db.child(FridgePaths.pirimi).onValue.map((event) {
    if (!event.snapshot.exists) return 0;
    final data = event.snapshot.value as Map?;
    return data?.length ?? 0;
  });
});

// ── Annual chart stats ────────────────────────────────────────────────────────

class MonthlyZoneStats {
  const MonthlyZoneStats({
    required this.month,
    required this.zone1,
    required this.zone2,
    required this.zone3,
    required this.pirimi,
  });
  final String month;
  final double zone1;
  final double zone2;
  final double zone3;
  final double pirimi;
}

/// Combines all 4 zone snapshots and buckets by createdAt month (current year).
final annualStatsProvider =
    StreamProvider<List<MonthlyZoneStats>>((ref) {
  final year = DateTime.now().year;
  const labels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final controller =
      StreamController<List<MonthlyZoneStats>>.broadcast();

  final refs = [
    _db.child(FridgePaths.zone1).onValue,
    _db.child(FridgePaths.zone2).onValue,
    _db.child(FridgePaths.zone3).onValue,
    _db.child(FridgePaths.pirimi).onValue,
  ];

  final snapshots = <DataSnapshot?>[null, null, null, null];

  void emit() {
    double count(DataSnapshot? snap, int month) {
      if (snap == null || !snap.exists) return 0;
      final data = snap.value as Map?;
      if (data == null) return 0;

      int count = 0;
      for (final entry in data.entries) {
        final productData = entry.value as Map?;
        if (productData != null) {
          final rawCreated = productData['createdAt'];
          if (rawCreated is int) {
            final dt = DateTime.fromMillisecondsSinceEpoch(rawCreated);
            if (dt.year == year && dt.month == month) count++;
          }
        }
      }
      return count.toDouble();
    }

    final stats = List.generate(12, (i) {
      final m = i + 1;
      return MonthlyZoneStats(
        month: labels[i],
        zone1: count(snapshots[0], m),
        zone2: count(snapshots[1], m),
        zone3: count(snapshots[2], m),
        pirimi: count(snapshots[3], m),
      );
    });

    controller.add(stats);
  }

  for (var i = 0; i < refs.length; i++) {
    refs[i].listen((event) {
      snapshots[i] = event.snapshot;
      emit();
    });
  }

  ref.onDispose(controller.close);
  return controller.stream;
});

// ── Realtime Database delete ───────────────────────────────────────────────────

Future<void> deleteProductFromZone(ProductModel product) async {
  final path = switch (product.zone) {
    ProductZone.zone1 => FridgePaths.zone1,
    ProductZone.zone2 => FridgePaths.zone2,
    ProductZone.zone3 => FridgePaths.zone3,
    ProductZone.expired => FridgePaths.pirimi,
  };
  await _db.child('$path/${product.id}').remove();
}

// ── Realtime Database write (scan) ─────────────────────────────────────────────
//
// Path : frigo/TBNp1Y68mMV9nODEw6Kj/{zoneName}/{productUID}
// In Realtime DB, the productUID becomes a key in the hierarchical structure
//
// Using .set(...) creates or overwrites the value at that path

Future<void> saveProductToZone({
  required String name,
  required DateTime expired,
  required String uid,
  required String zoneName, // 'zone1' or 'zone2'
}) async {
  final collectionPath = FridgePaths.collectionForZone(zoneName);
  final now = DateTime.now();
  final nowMillis = now.millisecondsSinceEpoch;

  // Save product
  await _db.child('$collectionPath/$uid').set({
    'uid': uid,
    'name': name,
    'expired': expired.millisecondsSinceEpoch,
    'createdAt': nowMillis,
  });

  // Create alert notification in database
  final alertPath = '${FridgePaths.fridgeDoc}/alerts';
  final context =
      'Expires ${expired.day}/${expired.month}/${expired.year} ${expired.hour}:${expired.minute.toString().padLeft(2, '0')}';
  
  await _db.child(alertPath).push().set({
    'name': name,
    'context': context,
    'createdAt': nowMillis,
    'isRead': false,
    'priority': 3,
  });

  // Send FCM notification to all users subscribed to 'alerts' topic
  await FcmService.instance.sendAlertViaFcm(
    name: name,
    context: context,
  );
}