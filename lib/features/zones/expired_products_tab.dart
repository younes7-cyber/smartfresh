import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:smartfresh/features/zones/firestore_delete_help.dart';

import '../../core/constants.dart';
import '../../core/theme/color_palette.dart';
import '../../shared/widgets/product_card.dart';

class ExpiredProductsTab extends ConsumerStatefulWidget {
  const ExpiredProductsTab({super.key});

  @override
  ConsumerState<ExpiredProductsTab> createState() => _ExpiredProductsTabState();
}

class _ExpiredProductsTabState extends ConsumerState<ExpiredProductsTab> {
  final _pinController = TextEditingController();
  bool _pinError = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // ── Open expired box dialog ───────────────────────────────────────────────

  Future<void> _showBoxDialog() async {
    _pinController.clear();
    setState(() => _pinError = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
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
                    appContext: dialogContext,
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
                      activeFillColor: ColorPalette.primary.withValues(alpha: 0.08),
                      inactiveFillColor: Colors.transparent,
                      selectedFillColor: ColorPalette.primary.withValues(alpha: 0.05),
                      activeColor: ColorPalette.primary,
                      inactiveColor: ColorPalette.secondary.withValues(alpha: 0.4),
                      selectedColor: ColorPalette.primary,
                      errorBorderColor: ColorPalette.danger,
                    ),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (_pinError) {
                        setDialogState(() => _pinError = false);
                      }
                    },
                    onCompleted: (pin) {
                      // Auto-confirm when all 4 digits entered
                      if (pin == AppPins.expiredBox) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.lock_open_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('boxOpened'.tr()),
                            ]),
                            backgroundColor: ColorPalette.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } else {
                        setDialogState(() => _pinError = true);
                        _pinController.clear();
                      }
                    },
                  ),
                  // Error message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _pinError
                        ? Padding(
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
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _pinController.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('cancel'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Real-time stream from frigo/.../pirimi
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
                  // ── Header count banner ──
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

                  // ── Product list ──
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          ProductCard(product: products[index]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── Open expired box button ──
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