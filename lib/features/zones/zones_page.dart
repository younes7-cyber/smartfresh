import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
            tabs: [
              Tab(text: 'Fridge Zones'),
              Tab(text: 'expiredProducts'.tr()),
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
