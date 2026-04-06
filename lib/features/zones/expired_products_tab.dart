import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/constants.dart';
import '../../core/state/app_providers.dart';
import '../../shared/models/product_model.dart';
import '../../shared/widgets/product_card.dart';

class ExpiredProductsTab extends ConsumerStatefulWidget {
  const ExpiredProductsTab({super.key});

  @override
  ConsumerState<ExpiredProductsTab> createState() => _ExpiredProductsTabState();
}

class _ExpiredProductsTabState extends ConsumerState<ExpiredProductsTab> {
  final _pinController = TextEditingController();
  bool _dialogLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = ref.watch(productsProvider).where((item) => item.status == ProductStatus.expired).toList();

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: expired.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => ProductCard(product: expired[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _showBoxDialog,
            child: Text('openExpiredBox'.tr()),
          ),
        ),
      ],
    );
  }

  Future<void> _showBoxDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('enterPin'.tr()),
          content: PinCodeTextField(
            appContext: dialogContext,
            length: 4,
            controller: _pinController,
            pinTheme: PinTheme(shape: PinCodeFieldShape.box, borderRadius: BorderRadius.circular(12), fieldHeight: 52, fieldWidth: 52),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('cancel'.tr())),
            ElevatedButton(
              onPressed: _dialogLoading
                  ? null
                  : () {
                      if (_pinController.text == AppPins.expiredBox) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('boxOpened'.tr())));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('incorrectCode'.tr())));
                      }
                    },
              child: Text('yes'.tr()),
            ),
          ],
        );
      },
    );
  }
}
