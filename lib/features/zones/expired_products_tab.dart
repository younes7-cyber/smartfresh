import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/constants.dart';
import '../../core/theme/color_palette.dart';
import '../../shared/widgets/product_card.dart';
import '../../service/firestore provider.dart';

class ExpiredProductsTab extends ConsumerStatefulWidget {
  const ExpiredProductsTab({super.key});

  @override
  ConsumerState<ExpiredProductsTab> createState() => _ExpiredProductsTabState();
}

class _ExpiredProductsTabState extends ConsumerState<ExpiredProductsTab> {
  Future<void> _showBoxDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PinDialog(),
    );

    if (confirmed == true) {
      await setBoxOpened();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('boxOpened'.tr()),
          ]),
          backgroundColor: ColorPalette.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pirimiAsync = ref.watch(pirimiProvider);

    return Column(
      children: [
        Expanded(
          child: pirimiAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: ColorPalette.danger, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'loadError'.tr(),
                    style: const TextStyle(color: ColorPalette.danger),
                  ),
                  Text(e.toString(),
                      style: const TextStyle(
                          fontSize: 11, color: ColorPalette.secondary)),
                ],
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ColorPalette.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded,
                            color: ColorPalette.success, size: 44),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'noExpiredProducts'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.success,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'noExpiredProductsDesc'.tr(),
                        style: const TextStyle(
                            color: ColorPalette.secondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: ColorPalette.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: ColorPalette.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: ColorPalette.danger, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${products.length} ${'expiredProductsCount'.tr()}',
                          style: const TextStyle(
                            color: ColorPalette.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: ColorPalette.danger, size: 20),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.delete_outline_rounded,
                                          color: ColorPalette.danger),
                                      const SizedBox(width: 8),
                                      Text('deleteProduct'.tr()),
                                    ],
                                  ),
                                  content: Text(
                                    'confirmDeleteProduct'.tr(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('cancel'.tr()),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ColorPalette.danger,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: Text(
                                        'delete'.tr(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await deleteProductFromZone(product);
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Row(children: [
                                        const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text('productDeleted'.tr()),
                                      ]),
                                      backgroundColor:
                                          ColorPalette.danger,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showBoxDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                'openExpiredBox'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  late final TextEditingController _pinController;
  String _currentPin = '';
  bool _pinError = false;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

@override
void dispose() {
    // Suppression du Future.delayed, dispose immédiat
    _pinController.dispose();
    super.dispose();
}

  void _onValidate() {
    if (_currentPin.length < 4) return;

    if (_currentPin == AppPins.expiredBox) {
      Navigator.of(context).pop(true);
    } else {
      if (mounted) {
        setState(() {
          _pinError = true;
          _currentPin = '';
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorPalette.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_rounded,
                color: ColorPalette.danger, size: 20),
          ),
          const SizedBox(width: 10),
          Text('enterPin'.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'enterPinDesc'.tr(),
            style: const TextStyle(
                color: ColorPalette.secondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PinCodeTextField(
            appContext: context,
            length: 4,
            controller: _pinController,
            obscureText: true,
            obscuringCharacter: '●',
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 54,
              fieldWidth: 54,
              activeFillColor:
                  ColorPalette.primary.withValues(alpha: 0.08),
              inactiveFillColor: Colors.transparent,
              selectedFillColor:
                  ColorPalette.primary.withValues(alpha: 0.05),
              activeColor: ColorPalette.primary,
              inactiveColor:
                  ColorPalette.secondary.withValues(alpha: 0.4),
              selectedColor: ColorPalette.primary,
              errorBorderColor: ColorPalette.danger,
            ),
            enableActiveFill: true,
            keyboardType: TextInputType.number,
   // Dans le PinCodeTextField
onChanged: (value) {
    if (!mounted) return; // Protection supplémentaire
    setState(() {
        _currentPin = value;
        if (_pinError) _pinError = false;
    });
},
onCompleted: (_) {
    if (!mounted) return; // Ajout de la vérification
    _onValidate();
},
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _pinError
                ? Padding(
                    key: const ValueKey('pin_error'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: ColorPalette.danger, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'incorrectCode'.tr(),
                          style: const TextStyle(
                              color: ColorPalette.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no_error')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _currentPin.length == 4 ? _onValidate : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.danger,
            disabledBackgroundColor:
                ColorPalette.danger.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(
            'validate'.tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}