import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Firestore path constants ──────────────────────────────────────────────────
class FridgePaths {
  static const fridgeDoc = 'frigo/TBNp1Y68mMV9nODEw6Kj';
  static const zone1 = '$fridgeDoc/zone1';
  static const zone2 = '$fridgeDoc/zone2';
  static const zone3 = '$fridgeDoc/zone3';
  static const pirimi = '$fridgeDoc/pirimi'; // expired box
}

enum ProductZone { zone1, zone2, zone3, expired }

enum ProductStatus { fresh, expiringSoon, expired }

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.uid,
    required this.expired,
    required this.zone,
    required this.status,
    this.createdAt,
    this.icon = Icons.inventory_2_rounded,
  });

  final String id;        // Firestore document ID
  final String name;
  final String uid;       // the 20-char alphanumeric UID encoded in the barcode
  final DateTime expired;
  final ProductZone zone;
  final ProductStatus status;
  final DateTime? createdAt;
  final IconData icon;

  // ── Computed status from expiry date ─────────────────────────────────────

  /// Returns a status computed from the current time:
  /// - expired    → already past expiry
  /// - expiringSoon → expires within 7 days
  /// - fresh      → more than 7 days remaining
  static ProductStatus computeStatus(DateTime expired) {
    final now = DateTime.now();
    final diff = expired.difference(now);
    if (diff.isNegative) return ProductStatus.expired;
    if (diff.inDays <= 7) return ProductStatus.expiringSoon;
    return ProductStatus.fresh;
  }

  // ── Firestore → ProductModel ──────────────────────────────────────────────

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    ProductZone zone,
  ) {
    final data = doc.data() ?? {};

    // expired can be stored as Timestamp or as a formatted String
    DateTime expired;
    final rawExpiry = data['expired'] ?? data['expiry'] ?? data['date'];
    if (rawExpiry is Timestamp) {
      expired = rawExpiry.toDate();
    } else if (rawExpiry is String && rawExpiry.isNotEmpty) {
      // Supports the barcode format: "dd/MM/yyyy/HH/mm/ss"
      // and the standard ISO format
      try {
        final parts = rawExpiry.split('/');
        if (parts.length >= 3) {
          expired = DateTime(
            int.parse(parts[2].length > 4 ? parts[2].substring(0, 4) : parts[2]), // year
            int.parse(parts[1]),   // month
            int.parse(parts[0]),   // day
            parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0, // hour
            parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0, // minute
            parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0, // second
          );
        } else {
          expired = DateTime.tryParse(rawExpiry) ?? DateTime.now();
        }
      } catch (_) {
        expired = DateTime.now();
      }
    } else {
      expired = DateTime.now();
    }

    // createdAt
    DateTime? createdAt;
    final rawCreated = data['createdAt'] ?? data['addedAt'];
    if (rawCreated is Timestamp) createdAt = rawCreated.toDate();

    return ProductModel(
      id: doc.id,
      name: (data['name'] ?? data['nom'] ?? 'Unknown').toString(),
      uid: (data['uid'] ?? data['UID'] ?? doc.id).toString(),
      expired: expired,
      zone: zone,
      status: computeStatus(expired),
      createdAt: createdAt,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  ProductModel copyWith({
    String? id,
    String? name,
    String? uid,
    DateTime? expired,
    ProductZone? zone,
    ProductStatus? status,
    DateTime? createdAt,
    IconData? icon,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      expired: expired ?? this.expired,
      zone: zone ?? this.zone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }

  String get zoneLabel {
    switch (zone) {
      case ProductZone.zone1:
        return 'Zone 1';
      case ProductZone.zone2:
        return 'Zone 2';
      case ProductZone.zone3:
        return 'Zone 3 (Expiring)';
      case ProductZone.expired:
        return 'Périmi';
    }
  }
}