import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
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
    for (final controller in _searchControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zones = [ProductZone.zone1, ProductZone.zone2, ProductZone.zone3];
    final products = ref.watch(productsProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: zones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final zone = zones[index];
        final items = products.where((item) => item.zone == zone).toList();
        final controller = _searchControllers[zone]!;
        final query = controller.text.toLowerCase();
        final filtered = items.where((item) => item.name.toLowerCase().contains(query)).toList();

        return Card(
          child: ExpansionTile(
            initiallyExpanded: _expanded.contains(zone),
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expanded.add(zone);
                } else {
                  _expanded.remove(zone);
                }
              });
            },
            title: Text(zone == ProductZone.zone3 ? 'zone3'.tr() : zone == ProductZone.zone2 ? 'zone2'.tr() : 'zone1'.tr()),
            subtitle: Text('${filtered.length} items'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: 'searchProducts'.tr()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No products found'),
                )
              else
                ...filtered.map(
                  (item) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ProductCard(
                      product: item,
                      trailing: IconButton(
                        onPressed: () => ref.read(productsProvider.notifier).removeProduct(item.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
