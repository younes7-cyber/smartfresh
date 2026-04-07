import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/state/app_providers.dart';
import '../../shared/models/product_model.dart';
import '../../shared/widgets/app_button.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.all],
  );

  bool _hasPermission = false;
  bool _permissionPermanentlyDenied = false;
  bool _hasScanned = false;
  bool _isSupportedPlatform = true;
  late final AnimationController _beamController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void initState() {
    super.initState();
    _isSupportedPlatform = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    _requestPermission();
  }

  @override
  void dispose() {
    _beamController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      return;
    }
    setState(() {
      _hasPermission = false;
      _permissionPermanentlyDenied = status.isPermanentlyDenied;
    });
  }

  Future<void> _onBarcodeDetected(String rawValue) async {
    if (_hasScanned) return;
    _hasScanned = true;
    HapticFeedback.mediumImpact();
    await _scannerController.stop();

    final product = _parseBarcode(rawValue);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _BarcodeSheet(
        product: product,
        onAdd: (zone) {
          ref.read(productsProvider.notifier).addProduct(
                ProductModel(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: product.name,
                  uid: product.uid,
                  expiryDate: product.expiryDate,
                  zone: zone,
                  status: zone == ProductZone.zone3 ? ProductStatus.expiringSoon : ProductStatus.fresh,
                ),
              );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to ${zone.name}')));
          Navigator.of(context).pop();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );

    _hasScanned = false;
    await _scannerController.start();
  }

  ({String name, DateTime expiryDate, String uid}) _parseBarcode(String rawValue) {
    final parts = rawValue.split('|');
    if (parts.length == 3) {
      final dateParts = parts[1].split('/');
      if (dateParts.length == 6) {
        final expiry = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
          int.parse(dateParts[3]),
          int.parse(dateParts[4]),
          int.parse(dateParts[5]),
        );
        return (name: parts[0], expiryDate: expiry, uid: parts[2]);
      }
    }
    return (name: rawValue, expiryDate: DateTime.now().add(const Duration(days: 1)), uid: 'UNKNOWN');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupportedPlatform) {
      return Scaffold(
        appBar: AppBar(title: Text('scan'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography_rounded, size: 72),
                const SizedBox(height: 16),
                Text('cameraPermissionRequired'.tr(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(onPressed: () => openAppSettings(), child: Text('openSettings'.tr())),
              ],
            ),
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(title: Text('scan'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography_rounded, size: 72),
                const SizedBox(height: 16),
                Text('cameraPermissionRequired'.tr(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(
                  label: _permissionPermanentlyDenied ? 'openSettings'.tr() : 'grantPermission'.tr(),
                  onPressed: () => openAppSettings(),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _requestPermission, child: Text('retry'.tr())),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('scanBarcode'.tr())),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && !_hasScanned) {
                  _onBarcodeDetected(rawValue);
                }
              }
            },
          ),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                Text('scanBarcode'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('pointCamera'.tr(), style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => _scannerController.toggleTorch(),
                      icon: const Icon(Icons.flashlight_on, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => _scannerController.switchCamera(),
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeSheet extends StatefulWidget {
  const _BarcodeSheet({required this.product, required this.onAdd, required this.onClose});

  final ({String name, DateTime expiryDate, String uid}) product;
  final void Function(ProductZone zone) onAdd;
  final VoidCallback onClose;

  @override
  State<_BarcodeSheet> createState() => _BarcodeSheetState();
}

class _BarcodeSheetState extends State<_BarcodeSheet> {
  ProductZone? _selectedZone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode Detected', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Name: ${widget.product.name}'),
            Text('Expiry: ${DateFormat('dd/MM/yyyy').format(widget.product.expiryDate)}'),
            Text('UID: ${widget.product.uid}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  selected: _selectedZone == ProductZone.zone1,
                  label: Text('zone1'.tr()),
                  onSelected: (_) => setState(() => _selectedZone = ProductZone.zone1),
                ),
                ChoiceChip(
                  selected: _selectedZone == ProductZone.zone2,
                  label: Text('zone2'.tr()),
                  onSelected: (_) => setState(() => _selectedZone = ProductZone.zone2),
                ),
                ChoiceChip(
                  selected: _selectedZone == ProductZone.zone3,
                  label: Text('zone3'.tr()),
                  onSelected: (_) => setState(() => _selectedZone = ProductZone.zone3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    child: Text('cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedZone == null ? null : () => widget.onAdd(_selectedZone!),
                    child: Text('addToFridge'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
