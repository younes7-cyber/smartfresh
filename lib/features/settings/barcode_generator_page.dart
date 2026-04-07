import 'dart:math';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class BarcodeGeneratorPage extends StatefulWidget {
  const BarcodeGeneratorPage({super.key});

  @override
  State<BarcodeGeneratorPage> createState() => _BarcodeGeneratorPageState();
}

class _BarcodeGeneratorPageState extends State<BarcodeGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uidController = TextEditingController();
  final _expiryController = TextEditingController();
  final _ticketKey = GlobalKey();
  DateTime? _expiryDateTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _uidController.text = _generateUid();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uidController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  String _generateUid() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String get _formattedExpiry {
    final expiry = _expiryDateTime;
    if (expiry == null) return '';
    return DateFormat('dd/MM/yyyy/HH/mm/ss').format(expiry);
  }

  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return false;

    Permission permission;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      permission = androidInfo.version.sdkInt >= 33 ? Permission.photos : Permission.storage;
    } else {
      permission = Permission.photos;
    }

    final status = await permission.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _pickExpiryDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() {
      _expiryDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute, 0);
      _expiryController.text = DateFormat('dd/MM/yyyy HH:mm:ss').format(_expiryDateTime!);
    });
  }

  Future<void> _saveTicketToGallery() async {
    if (!(_formKey.currentState?.validate() ?? false) || _expiryDateTime == null) return;
    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Storage permission is required.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

     /* final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: 'SmartFresh_${_uidController.text}_ticket',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['isSuccess'] == true ? '✅ Ticket saved to gallery!' : '❌ Failed to save ticket.')),
      );*/
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Failed to save ticket.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barcodeData = _expiryDateTime == null ? '' : '${_nameController.text}|$_formattedExpiry|${_uidController.text}';

    return Scaffold(
      appBar: AppBar(title: Text('barcodeGenerator'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'productName'.tr(),
                validator: (value) {
                  if (value == null || value.trim().length < 2) return 'requiredField'.tr();
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'expiryDate'.tr(),
                  hintText: 'Select expiry date and time',
                  suffixIcon: IconButton(onPressed: _pickExpiryDateTime, icon: const Icon(Icons.event)),
                ),
                validator: (_) => _expiryDateTime == null ? 'requiredField'.tr() : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _uidController,
                      label: 'uid'.tr(),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => _uidController.text = _generateUid()),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                key: _ticketKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SmartFresh', style: Theme.of(context).textTheme.titleLarge),
                      const Divider(),
                      Text('Product: ${_nameController.text.isEmpty ? '-' : _nameController.text}'),
                      Text('Expiry: ${_expiryDateTime == null ? '-' : DateFormat('dd/MM/yyyy HH:mm:ss').format(_expiryDateTime!)}'),
                      Text('UID: ${_uidController.text}'),
                      const SizedBox(height: 16),
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: barcodeData.isEmpty ? 'SmartFresh' : barcodeData,
                        width: double.infinity,
                        height: 100,
                        drawText: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                loading: _saving,
                icon: Icons.save_alt_rounded,
                label: 'saveToGallery'.tr(),
                onPressed: _saving ? null : _saveTicketToGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
