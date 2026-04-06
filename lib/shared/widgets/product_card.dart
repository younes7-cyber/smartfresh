import 'package:flutter/material.dart';

import '../../core/theme/color_palette.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.trailing});

  final ProductModel product;
  final Widget? trailing;

  Color get statusColor {
    switch (product.status) {
      case ProductStatus.fresh:
        return ColorPalette.success;
      case ProductStatus.expiringSoon:
        return ColorPalette.warning;
      case ProductStatus.expired:
        return ColorPalette.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = product.expiryDate.difference(DateTime.now());
    final expired = remaining.isNegative;
    final label = expired
        ? 'Expired ${remaining.inDays.abs()}d ago'
        : 'Expires in ${remaining.inDays}d ${remaining.inHours.remainder(24)}h';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Icon(product.icon, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('UID: ${product.uid}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: statusColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
