import 'package:flutter/material.dart';

enum ProductZone { zone1, zone2, zone3, expired }

enum ProductStatus { fresh, expiringSoon, expired }

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.uid,
    required this.expiryDate,
    required this.zone,
    required this.status,
    this.createdAt,
    this.icon = Icons.inventory_2_rounded,
  });

  final String id;
  final String name;
  final String uid;
  final DateTime expiryDate;
  final ProductZone zone;
  final ProductStatus status;
  final DateTime? createdAt;
  final IconData icon;

  ProductModel copyWith({
    String? id,
    String? name,
    String? uid,
    DateTime? expiryDate,
    ProductZone? zone,
    ProductStatus? status,
    DateTime? createdAt,
    IconData? icon,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      expiryDate: expiryDate ?? this.expiryDate,
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
        return 'Zone 3';
      case ProductZone.expired:
        return 'Expired';
    }
  }
}
