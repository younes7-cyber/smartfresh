import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/product_model.dart';

final _db = FirebaseFirestore.instance;

// ── Fridge paths ──────────────────────────────────────────────────────────────

class FridgePaths {
  static const _col = 'frigo';

  // Fixed hardware fridge ID — used for ALL reads AND writes
  static const _fixedId = 'TBNp1Y68mMV9nODEw6Kj';
  static const fridgeDoc = '$_col/$_fixedId';

  // Sub-collection paths
  static const zone1 = '$fridgeDoc/zone1';
  static const zone2 = '$fridgeDoc/zone2';
  static const zone3 = '$fridgeDoc/zone3';
  static const pirimi = '$fridgeDoc/pirimi';

  /// Returns the collection path for a given zone name string
  static String collectionForZone(String zoneName) => '$fridgeDoc/$zoneName';
}

// ── Zone StreamProviders — real-time via .snapshots() ────────────────────────

final zone1Provider = StreamProvider<List<ProductModel>>((ref) => _db
    .collection(FridgePaths.zone1)
    .snapshots()
    .map((s) => s.docs
        .map((d) => ProductModel.fromFirestore(d, ProductZone.zone1))
        .toList()));

final zone2Provider = StreamProvider<List<ProductModel>>((ref) => _db
    .collection(FridgePaths.zone2)
    .snapshots()
    .map((s) => s.docs
        .map((d) => ProductModel.fromFirestore(d, ProductZone.zone2))
        .toList()));

final zone3Provider = StreamProvider<List<ProductModel>>((ref) => _db
    .collection(FridgePaths.zone3)
    .snapshots()
    .map((s) => s.docs
        .map((d) => ProductModel.fromFirestore(d, ProductZone.zone3))
        .toList()));

final pirimiProvider = StreamProvider<List<ProductModel>>((ref) => _db
    .collection(FridgePaths.pirimi)
    .snapshots()
    .map((s) => s.docs
        .map((d) => ProductModel.fromFirestore(d, ProductZone.expired))
        .toList()));

// ── Dashboard count StreamProviders ──────────────────────────────────────────

/// Total = zone1 + zone2 + zone3 (real-time combined stream)
final totalProductsProvider = StreamProvider<int>((ref) {
  final List<QuerySnapshot?> latest = List.filled(3, null);
  final controller = StreamController<int>.broadcast();

  final streams = [
    _db.collection(FridgePaths.zone1).snapshots(),
    _db.collection(FridgePaths.zone2).snapshots(),
    _db.collection(FridgePaths.zone3).snapshots(),
  ];

  for (var i = 0; i < streams.length; i++) {
    streams[i].listen((snap) {
      latest[i] = snap;
      final total = latest.fold<int>(0, (sum, s) => sum + (s?.docs.length ?? 0));
      controller.add(total);
    });
  }

  ref.onDispose(controller.close);
  return controller.stream;
});

/// Fresh = zone1 + zone2
final freshProductsProvider = StreamProvider<int>((ref) {
  final List<QuerySnapshot?> latest = List.filled(2, null);
  final controller = StreamController<int>.broadcast();

  final streams = [
    _db.collection(FridgePaths.zone1).snapshots(),
    _db.collection(FridgePaths.zone2).snapshots(),
  ];

  for (var i = 0; i < streams.length; i++) {
    streams[i].listen((snap) {
      latest[i] = snap;
      final total = latest.fold<int>(0, (sum, s) => sum + (s?.docs.length ?? 0));
      controller.add(total);
    });
  }

  ref.onDispose(controller.close);
  return controller.stream;
});

/// Expiring soon = zone3
final expiringSoonCountProvider = StreamProvider<int>((ref) => _db
    .collection(FridgePaths.zone3)
    .snapshots()
    .map((s) => s.docs.length));

/// Expired = pirimi
final expiredCountProvider = StreamProvider<int>((ref) => _db
    .collection(FridgePaths.pirimi)
    .snapshots()
    .map((s) => s.docs.length));

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
final annualStatsProvider = StreamProvider<List<MonthlyZoneStats>>((ref) {
  final year = DateTime.now().year;
  const labels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final List<QuerySnapshot?> latest = List.filled(4, null);
  final controller = StreamController<List<MonthlyZoneStats>>.broadcast();

  final streams = [
    _db.collection(FridgePaths.zone1).snapshots(),
    _db.collection(FridgePaths.zone2).snapshots(),
    _db.collection(FridgePaths.zone3).snapshots(),
    _db.collection(FridgePaths.pirimi).snapshots(),
  ];

  void emit() {
    double count(QuerySnapshot? snap, int month) {
      if (snap == null) return 0;
      return snap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        final raw = data['createdAt'];
        if (raw is! Timestamp) return false;
        final dt = raw.toDate();
        return dt.year == year && dt.month == month;
      }).length.toDouble();
    }

    final stats = List.generate(12, (i) {
      final m = i + 1;
      return MonthlyZoneStats(
        month: labels[i],
        zone1: count(latest[0], m),
        zone2: count(latest[1], m),
        zone3: count(latest[2], m),
        pirimi: count(latest[3], m),
      );
    });

    controller.add(stats);
  }

  for (var i = 0; i < streams.length; i++) {
    streams[i].listen((snap) {
      latest[i] = snap;
      emit();
    });
  }

  ref.onDispose(controller.close);
  return controller.stream;
});

// ── Firestore delete ──────────────────────────────────────────────────────────

Future<void> deleteProductFromZone(ProductModel product) async {
  final path = switch (product.zone) {
    ProductZone.zone1 => FridgePaths.zone1,
    ProductZone.zone2 => FridgePaths.zone2,
    ProductZone.zone3 => FridgePaths.zone3,
    ProductZone.expired => FridgePaths.pirimi,
  };
  await _db.collection(path).doc(product.id).delete();
}

// ── Firestore write (scan) ────────────────────────────────────────────────────
//
// Path : frigo/TBNp1Y68mMV9nODEw6Kj/{zoneName}/{productUID}
// Doc ID = product UID (20-char alphanumeric from barcode)
//
// Using .doc(uid).set(...) creates the document with the UID as its ID
// directly — no rename needed, Firestore doesn't support renaming.

Future<void> saveProductToZone({
  required String name,
  required DateTime expired,
  required String uid,
  required String zoneName, // 'zone1' or 'zone2'
}) async {
  final collectionPath = FridgePaths.collectionForZone(zoneName);

  // .doc(uid) → document ID = product UID
  await _db.collection(collectionPath).doc(uid).set({
    'uid': uid,
    'name': name,
    'expired': Timestamp.fromDate(expired),
    'createdAt': FieldValue.serverTimestamp(),
  });
}