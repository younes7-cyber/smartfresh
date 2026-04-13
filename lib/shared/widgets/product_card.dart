import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/color_palette.dart';
import '../models/product_model.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, this.trailing});

  final ProductModel product;
  final Widget? trailing;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Tick every second for live countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateRemaining());
    });
  }

  void _updateRemaining() {
    _remaining = widget.product.expired.difference(DateTime.now());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.product.status) {
      case ProductStatus.fresh:
        return ColorPalette.success;
      case ProductStatus.expiringSoon:
        return ColorPalette.warning;
      case ProductStatus.expired:
        return ColorPalette.danger;
    }
  }

  String get _countdownLabel {
    if (_remaining.isNegative) {
      final abs = _remaining.abs();
      final days = abs.inDays;
      final hours = abs.inHours.remainder(24);
      final mins = abs.inMinutes.remainder(60);
      if (days > 0) return 'Expired ${days}d ${hours}h ago';
      if (hours > 0) return 'Expired ${hours}h ${mins}m ago';
      return 'Expired ${mins}m ago';
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final mins = _remaining.inMinutes.remainder(60);
    final secs = _remaining.inSeconds.remainder(60);

    if (days > 0) {
      return 'Expires in ${days}d ${hours}h ${mins}m';
    }
    if (hours > 0) {
      return 'Expires in ${hours}h ${mins}m ${secs}s';
    }
    return 'Expires in ${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: _statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Status icon ──
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.product.icon, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'UID: ${widget.product.uid}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorPalette.secondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // ── Real-time countdown ──
                Row(
                  children: [
                    Icon(
                      _remaining.isNegative
                          ? Icons.error_outline_rounded
                          : Icons.timer_outlined,
                      size: 13,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _countdownLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Trailing (delete button, etc.) ──
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}