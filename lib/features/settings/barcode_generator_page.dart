import 'dart:math';
import 'dart:ui' as ui;
import 'package:barcode_widget/barcode_widget.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/color_palette.dart';
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
  bool _generated = false;
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
    if (_expiryDateTime == null) return '';
    return DateFormat('dd/MM/yyyy/HH/mm/ss').format(_expiryDateTime!);
  }

  String get _displayExpiry {
    if (_expiryDateTime == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(_expiryDateTime!);
  }

  String get _qrData =>
      'SF|${_nameController.text.trim()}|$_formattedExpiry|${_uidController.text}';

  Future<void> _pickExpiryDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    if (mounted) {
      setState(() {
        _expiryDateTime = DateTime(
            date.year, date.month, date.day, time.hour, time.minute, 0);
        _expiryController.text =
            DateFormat('dd/MM/yyyy HH:mm:ss').format(_expiryDateTime!);
      });
    }
  }

  void _generate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_expiryDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('requiredField'.tr()),
          backgroundColor: ColorPalette.danger,
        ),
      );
      return;
    }
    if (mounted) setState(() => _generated = true);
  }

  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
        return status.isGranted;
      }
      return true;
    }
    return true;
  }

  Future<void> _saveTicketToGallery() async {
    if (!_generated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('generateFirst'.tr()),
          backgroundColor: ColorPalette.warning,
        ),
      );
      return;
    }

    final hasPermission = await _requestGalleryPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('permissionDenied'.tr()),
          backgroundColor: ColorPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'openSettings'.tr(),
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _ticketKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await Gal.putImageBytes(
        pngBytes,
        name: 'SmartFresh_${_uidController.text}_ticket',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('ticketSaved'.tr()),
            ],
          ),
          backgroundColor: ColorPalette.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on GalException catch (e) {
      if (!mounted) return;
      final msg = e.type == GalExceptionType.accessDenied
          ? 'permissionDenied'.tr()
          : 'ticketSaveError'.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: ColorPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ticketSaveError'.tr()),
          backgroundColor: ColorPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('barcodeGenerator'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'productName'.tr(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'requiredField'.tr() : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _expiryController,
                label: 'expiryDate'.tr(),
                readOnly: true,
                suffixIcon: IconButton(
                  onPressed: _pickExpiryDateTime,
                  icon: const Icon(Icons.event_rounded),
                ),
                onTap: _pickExpiryDateTime,
                validator: (_) =>
                    _expiryDateTime == null ? 'requiredField'.tr() : null,
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
                  Tooltip(
                    message: 'regenerate'.tr(),
                    child: IconButton(
                      onPressed: () => setState(() {
                        _uidController.text = _generateUid();
                        _generated = false;
                      }),
                      icon: const Icon(Icons.refresh_rounded,
                          color: ColorPalette.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'generate'.tr(),
                icon: Icons.qr_code_2_rounded,
                onPressed: _generate,
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _generated
                    ? RepaintBoundary(
                        key: _ticketKey,
                        child: _TicketCard(
                          name: _nameController.text.trim(),
                          displayExpiry: _displayExpiry,
                          uid: _uidController.text,
                          qrData: _qrData,
                          isDark: isDark,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (_generated) ...[
                const SizedBox(height: 16),
                AppButton(
                  loading: _saving,
                  icon: Icons.save_alt_rounded,
                  label: 'saveToGallery'.tr(),
                  onPressed: _saving ? null : _saveTicketToGallery,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ticket Card Widget (textes traduits) ─────────────────────────────────────
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.name,
    required this.displayExpiry,
    required this.uid,
    required this.qrData,
    required this.isDark,
  });

  final String name;
  final String displayExpiry;
  final String uid;
  final String qrData;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white60 : ColorPalette.secondary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: ColorPalette.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.inventory_2_rounded,
                      label: 'productName'.tr(),
                      value: name,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.event_rounded,
                      label: 'expiryDate'.tr(),
                      value: displayExpiry,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'UID',
                      value: uid,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      isMonospace: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorPalette.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(
                    errorCorrectLevel: BarcodeQRCorrectionLevel.medium,
                  ),
                  data: qrData,
                  width: 110,
                  height: 110,
                  drawText: false,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  errorBuilder: (context, error) => Center(
                    child: Text('QR error: $error',
                        style: const TextStyle(color: ColorPalette.danger)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
    required this.subtitleColor,
    this.isMonospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textColor;
  final Color subtitleColor;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ColorPalette.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: subtitleColor)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}