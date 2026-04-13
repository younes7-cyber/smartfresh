import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/product_model.dart';

final _db = FirebaseFirestore.instance;

// ── Per-zone real-time StreamProviders ───────────────────────────────────────

/// Stream of zone1 products — updates instantly on Firestore changes
final zone1Provider = StreamProvider<List<ProductModel>>((ref) {
  return _db
      .collection(FridgePaths.zone1)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ProductModel.fromFirestore(doc, ProductZone.zone1))
          .toList());
});

/// Stream of zone2 products
final zone2Provider = StreamProvider<List<ProductModel>>((ref) {
  return _db
      .collection(FridgePaths.zone2)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ProductModel.fromFirestore(doc, ProductZone.zone2))
          .toList());
});

/// Stream of zone3 products (expiring soon zone)
final zone3Provider = StreamProvider<List<ProductModel>>((ref) {
  return _db
      .collection(FridgePaths.zone3)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ProductModel.fromFirestore(doc, ProductZone.zone3))
          .toList());
});

/// Stream of pirimi (expired box) products
final pirimiProvider = StreamProvider<List<ProductModel>>((ref) {
  return _db
      .collection(FridgePaths.pirimi)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => ProductModel.fromFirestore(doc, ProductZone.expired))
          .toList());
});

// ── Firestore delete helpers ──────────────────────────────────────────────────

/// Delete a product document from its zone sub-collection
Future<void> deleteProductFromZone(ProductModel product) async {
  final collectionPath = _zoneCollectionPath(product.zone);
  await _db.collection(collectionPath).doc(product.id).delete();
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