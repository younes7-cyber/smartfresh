import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/features/zones/firestore_delete_help.dart';

import '../../core/theme/color_palette.dart';
import '../../shared/models/product_model.dart';
import '../../shared/widgets/product_card.dart';

class FridgeZonesTab extends ConsumerStatefulWidget {
  const FridgeZonesTab({super.key});

  @override
  ConsumerState<FridgeZonesTab> createState() => _FridgeZonesTabState();
}

class _FridgeZonesTabState extends ConsumerState<FridgeZonesTab> {
  final _searchControllers = <ProductZone, TextEditingController>{
    ProductZone.zone1: TextEditingController(),
    ProductZone.zone2: TextEditingController(),
    ProductZone.zone3: TextEditingController(),
  };
  final _expanded = <ProductZone>{ProductZone.zone1};

  @override
  void dispose() {
    for (final c in _searchControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Zone metadata ─────────────────────────────────────────────────────────

  String _zoneTitle(ProductZone zone) {
    switch (zone) {
      case ProductZone.zone1:
        return 'zone1'.tr();
      case ProductZone.zone2:
        return 'zone2'.tr();
      case ProductZone.zone3:
        return 'zone3'.tr();
      default:
        return '';
    }
  }

  Color _zoneColor(ProductZone zone) {
    switch (zone) {
      case ProductZone.zone1:
        return ColorPalette.success;
      case ProductZone.zone2:
        return ColorPalette.primary;
      case ProductZone.zone3:
        return ColorPalette.warning;
      default:
        return ColorPalette.secondary;
    }
  }

  IconData _zoneIcon(ProductZone zone) {
    switch (zone) {
      case ProductZone.zone1:
        return Icons.looks_one_rounded;
      case ProductZone.zone2:
        return Icons.looks_two_rounded;
      case ProductZone.zone3:
        return Icons.looks_3_rounded;
      default:
        return Icons.layers_rounded;
    }
  }

  // ── Delete from Firestore ─────────────────────────────────────────────────

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteProduct'.tr()),
        content: Text('deleteProductConfirm'.tr(args: [product.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: ColorPalette.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await deleteProductFromZone(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('productDeleted'.tr(args: [product.name])),
            backgroundColor: ColorPalette.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('deleteError'.tr()),
            backgroundColor: ColorPalette.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch each zone stream separately for independent real-time updates
    final zone1Async = ref.watch(zone1Provider);
    final zone2Async = ref.watch(zone2Provider);
    final zone3Async = ref.watch(zone3Provider);

    final zoneData = {
      ProductZone.zone1: zone1Async,
      ProductZone.zone2: zone2Async,
      ProductZone.zone3: zone3Async,
    };

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final zone = [ProductZone.zone1, ProductZone.zone2, ProductZone.zone3][index];
        final asyncValue = zoneData[zone]!;
        final controller = _searchControllers[zone]!;
        final color = _zoneColor(zone);

        return asyncValue.when(
          loading: () => _ZoneShimmerCard(color: color, title: _zoneTitle(zone)),
          error: (e, _) => _ZoneErrorCard(
            color: color,
            title: _zoneTitle(zone),
            error: e.toString(),
          ),
          data: (products) {
            final query = controller.text.toLowerCase();
            final filtered = query.isEmpty
                ? products
                : products
                    .where((p) =>
                        p.name.toLowerCase().contains(query) ||
                        p.uid.toLowerCase().contains(query))
                    .toList();

            return _ZoneCard(
              zone: zone,
              title: _zoneTitle(zone),
              color: color,
              icon: _zoneIcon(zone),
              totalCount: products.length,
              filteredProducts: filtered,
              searchController: controller,
              isExpanded: _expanded.contains(zone),
              onExpansionChanged: (expanded) => setState(() {
                expanded ? _expanded.add(zone) : _expanded.remove(zone);
              }),
              onSearch: (_) => setState(() {}),
              onDelete: _deleteProduct,
            );
          },
        );
      },
    );
  }
}

// ── Zone Card ─────────────────────────────────────────────────────────────────

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.title,
    required this.color,
    required this.icon,
    required this.totalCount,
    required this.filteredProducts,
    required this.searchController,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onSearch,
    required this.onDelete,
  });

  final ProductZone zone;
  final String title;
  final Color color;
  final IconData icon;
  final int totalCount;
  final List<ProductModel> filteredProducts;
  final TextEditingController searchController;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final ValueChanged<String> onSearch;
  final Future<void> Function(ProductModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Zone header ──
          InkWell(
            onTap: () => onExpansionChanged(!isExpanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '$totalCount ${'products'.tr()}',
                          style: TextStyle(
                              color: ColorPalette.secondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Badge
                  if (totalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$totalCount',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child:
                        Icon(Icons.expand_more_rounded, color: color),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable content ──
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearch,
                          decoration: InputDecoration(
                            hintText: 'searchProducts'.tr(),
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),

                      // Product list
                      if (filteredProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: ColorPalette.secondary, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'noProductsFound'.tr(),
                                style: const TextStyle(
                                    color: ColorPalette.secondary),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredProducts.map(
                          (product) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 4, 12, 4),
                            child: ProductCard(
                              product: product,
                              trailing: IconButton(
                                onPressed: () => onDelete(product),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: ColorPalette.danger,
                                  size: 22,
                                ),
                                tooltip: 'delete'.tr(),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Loading shimmer card ──────────────────────────────────────────────────────

class _ZoneShimmerCard extends StatelessWidget {
  const _ZoneShimmerCard({required this.color, required this.title});
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ZoneErrorCard extends StatelessWidget {
  const _ZoneErrorCard(
      {required this.color, required this.title, required this.error});
  final Color color;
  final String title;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: ColorPalette.danger),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(error,
                      style: const TextStyle(
                          color: ColorPalette.danger, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}