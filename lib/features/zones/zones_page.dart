import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/color_palette.dart';
import 'expired_products_tab.dart';
import 'fridge_zones_tab.dart';

class ZonesPage extends StatelessWidget {
  const ZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('zones'.tr()),
          bottom: TabBar(
            indicatorColor: ColorPalette.primary,
            labelColor: ColorPalette.primary,
            unselectedLabelColor: ColorPalette.secondary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.kitchen_rounded),
                text: 'fridgeZones'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.warning_amber_rounded),
                text: 'expiredProducts'.tr(),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FridgeZonesTab(),
            ExpiredProductsTab(),
          ],
        ),
      ),
    );
  }
}