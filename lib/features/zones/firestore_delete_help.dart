import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/product_model.dart';

final _db = FirebaseDatabase.instance.ref();

// ── Action paths ──────────────────────────────────────────────────────────────

/// Set the ouvre_boite (open box) flag to true when PIN is entered correctly
Future<void> setBoxOpened() async {
  try {
    await _db
        .child('/action/jI3Xr4kfUsNpGGhMCnZF/ouvre_boite')
        .set(true);
  } catch (e) {
    rethrow;
  }
}

// ── Per-zone real-time StreamProviders ───────────────────────────────────────

/// Stream of zone1 products — updates instantly on Realtime Database changes
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

/// Stream of zone2 products
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

/// Stream of zone3 products (expiring soon zone)
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

/// Stream of pirimi (expired box) products
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

// ── Realtime Database delete helpers ───────────────────────────────────────────

/// Delete a product from its zone
Future<void> deleteProductFromZone(ProductModel product) async {
  final collectionPath = _zoneCollectionPath(product.zone);
  await _db.child('$collectionPath/${product.id}').remove();
}

String _zoneCollectionPath(ProductZone zone) {
  switch (zone) {
    case ProductZone.zone1:
      return FridgePaths.zone1;
    case ProductZone.zone2:
      return FridgePaths.zone2;
    case ProductZone.zone3:
      return FridgePaths.zone3;
    case ProductZone.expired:
      return FridgePaths.pirimi;
  }
}