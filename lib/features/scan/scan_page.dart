import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/color_palette.dart';
import '../../service/firestore provider.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late MobileScannerController _scanner;
  late final AnimationController _beamCtrl;
  bool _isScannerReady = false;

  // ═══ Anti‑répétition ═══
  bool _isSheetOpen = false;
  bool _cooldown = false;

  final bool _isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(navigationIndexProvider, (prev, next) {
        if (next == 2) {
          _activateScanner();
        } else {
          _deactivateScanner();
        }
      });
      if (ref.read(navigationIndexProvider) == 2) {
        _activateScanner();
      }
    });
  }

  // ── Activation / Désactivation ──────────────────────────────────────────
  Future<void> _activateScanner() async {
    if (!_isMobile) return;
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        await _scanner.start();
        setState(() => _isScannerReady = true);
      }
    } else if (status.isDenied || status.isLimited) {
      _requestCameraPermission();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _deactivateScanner() {
    if (_isMobile) {
      _scanner.stop();
      if (mounted) setState(() => _isScannerReady = false);
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      await _scanner.start();
      setState(() => _isScannerReady = true);
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('cameraPermissionRequired'.tr()),
        content: Text('cameraPermissionDesc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('openSettings'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _beamCtrl.dispose();
    _scanner.stop();
    _scanner.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(navigationIndexProvider) == 2) {
      _activateScanner();
    } else if (state == AppLifecycleState.paused) {
      _deactivateScanner();
    }
  }

  // ── QR Detection avec blocage ─────────────────────────────────────────
  void _onDetected(BarcodeCapture capture) {
    // Bloque si un sheet est déjà affiché ou en période de cooldown
    if (_isSheetOpen || _cooldown) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final raw = barcode.rawValue ?? '';
    final parts = raw.split('|');
    if (parts.length != 4 || parts[0] != 'SF') {
      _showResultSheet(
        name: raw,
        expired: DateTime.now(),
        uid: 'UNKNOWN',
        isValidFormat: false,
      );
      return;
    }

    final name = parts[1];
    final expiryParts = parts[2].split('/');
    DateTime expired = DateTime.now();
    try {
      if (expiryParts.length >= 6) {
        expired = DateTime(
          int.parse(expiryParts[2]),
          int.parse(expiryParts[1]),
          int.parse(expiryParts[0]),
          int.parse(expiryParts[3]),
          int.parse(expiryParts[4]),
          int.parse(expiryParts[5]),
        );
      }
    } catch (_) {}

    final uid = parts[3];
    _showResultSheet(
      name: name,
      expired: expired,
      uid: uid,
      isValidFormat: true,
    );
  }

  Future<void> _showResultSheet({
    required String name,
    required DateTime expired,
    required String uid,
    bool isValidFormat = true,
  }) async {
    _isSheetOpen = true;  // ← bloque les nouvelles détections
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _QrResultSheet(
        name: name,
        expired: expired,
        uid: uid,
        isValidFormat: isValidFormat,
        existingZone: null,
        onAdd: (zoneName) async {
          await saveProductToZone(
            name: name,
            expired: expired,
            uid: uid,
            zoneName: zoneName,
          );
        },
      ),
    );
    // Le bottom sheet est fermé
    _isSheetOpen = false;
    // Active un cooldown de 2 secondes
    _cooldown = true;
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cooldown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('scanPage'.tr()),
        centerTitle: true,
      ),
      body: _isMobile
          ? Stack(
              children: [
                MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetected,
                ),
                if (!_isScannerReady)
                  const Center(child: CircularProgressIndicator()),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                if (_isScannerReady)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Text(
                      'pointCamera'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Text('cameraNotSupported'.tr()),
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Reprendre ici TOUS les widgets du bottom sheet (_QrResultSheet, _InfoTile, _ZoneChip)
//  qui sont déjà dans les réponses précédentes. Ils restent inchangés.
// ════════════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════════════
//  Bottom sheet et ses sous‑widgets (inchangés, avec traduction)
//  (Assurez-vous d'avoir copié les classes _QrResultSheet, _InfoTile, _ZoneChip
//   depuis la réponse précédente, elles sont inchangées)
// ════════════════════════════════════════════════════════════════════════════

// ── QR Result Bottom Sheet (identique à la version précédente) ─────────
// ... (copiez ici la classe _QrResultSheet et ses sous-classes déjà fournies)

// ── QR Result Bottom Sheet ────────────────────────────────────────────────────
// (Modifié pour utiliser les traductions)

class _QrResultSheet extends StatefulWidget {
  const _QrResultSheet({
    required this.name,
    required this.expired,
    required this.uid,
    required this.isValidFormat,
    required this.existingZone,
    required this.onAdd,
  });

  final String name;
  final DateTime expired;
  final String uid;
  final bool isValidFormat;
  final String? existingZone;
  final Future<void> Function(String zoneName) onAdd;

  @override
  State<_QrResultSheet> createState() => _QrResultSheetState();
}

class _QrResultSheetState extends State<_QrResultSheet> {
  String? _selectedZone;
  bool _saving = false;
  bool _saved = false;

  String get _expiryFormatted {
    final d = widget.expired;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  }

  String _zoneDisplayName(String zone) {
    switch (zone) {
      case 'zone1':
        return 'zone1'.tr();
      case 'zone2':
        return 'zone2'.tr();
      case 'zone3':
        return 'zone3'.tr();
      case 'pirimi':
        return 'pirimi'.tr();
      default:
        return zone;
    }
  }

  Future<void> _save() async {
    if (_selectedZone == null || _saving) return;

    if (!widget.isValidFormat || widget.uid == 'UNKNOWN') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('invalidBarcodeFormat'.tr()),
          backgroundColor: ColorPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.onAdd(_selectedZone!);

      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('addedToZone'.tr(args: [
              _selectedZone == 'zone1' ? 'zone1'.tr() : 'zone2'.tr()
            ])),
          ]),
          backgroundColor: ColorPalette.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('saveError'.tr()),
          backgroundColor: ColorPalette.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDuplicate = widget.existingZone != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDuplicate
                        ? ColorPalette.warning.withValues(alpha: 0.12)
                        : widget.isValidFormat
                            ? ColorPalette.success.withValues(alpha: 0.12)
                            : ColorPalette.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDuplicate
                        ? Icons.warning_amber_rounded
                        : widget.isValidFormat
                            ? Icons.qr_code_scanner_rounded
                            : Icons.error_outline_rounded,
                    color: isDuplicate
                        ? ColorPalette.warning
                        : widget.isValidFormat
                            ? ColorPalette.success
                            : ColorPalette.danger,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDuplicate
                            ? 'productAlreadyExists'.tr()
                            : 'barcodeDetected'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        isDuplicate
                            ? 'alreadyInZone'
                                .tr(args: [_zoneDisplayName(widget.existingZone!)])
                            : widget.isValidFormat
                                ? 'validFormat'.tr()
                                : 'unknownFormat'.tr(),
                        style: TextStyle(
                          color: isDuplicate
                              ? ColorPalette.warning
                              : widget.isValidFormat
                                  ? ColorPalette.success
                                  : ColorPalette.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (isDuplicate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorPalette.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: ColorPalette.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'productDuplicateDesc'
                            .tr(args: [_zoneDisplayName(widget.existingZone!)]),
                        style: TextStyle(
                          color: ColorPalette.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.inventory_2_rounded,
              label: 'productName'.tr(),
              value: widget.name,
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.event_rounded,
              label: 'expired'.tr(),
              value: _expiryFormatted,
              valueColor: widget.expired.isBefore(DateTime.now())
                  ? ColorPalette.danger
                  : null,
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.fingerprint_rounded,
              label: 'UID',
              value: widget.uid,
              isMonospace: true,
              valueColor:
                  widget.uid == 'UNKNOWN' ? ColorPalette.danger : null,
            ),
            const SizedBox(height: 20),
            Text(
              'selectZone'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ZoneChip(
                  label: 'zone1'.tr(),
                  color: ColorPalette.success,
                  selected: _selectedZone == 'zone1',
                  onTap: () => setState(() => _selectedZone = 'zone1'),
                ),
                const SizedBox(width: 12),
                _ZoneChip(
                  label: 'zone2'.tr(),
                  color: ColorPalette.primary,
                  selected: _selectedZone == 'zone2',
                  onTap: () => setState(() => _selectedZone = 'zone2'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: (_saving ||
                            _selectedZone == null ||
                            !widget.isValidFormat)
                        ? null
                        : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_selectedZone == null ||
                                  !widget.isValidFormat)
                              ? [
                                  Colors.grey.shade400,
                                  Colors.grey.shade400,
                                ]
                              : [
                                  const Color(0xFF007BFF),
                                  const Color(0xFF0056B3),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            (_selectedZone != null && widget.isValidFormat)
                                ? [
                                    BoxShadow(
                                      color: ColorPalette.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                      ),
                      child: Center(
                        child: _saved
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 24)
                            : _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'addToFridge'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                      ),
                    ),
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

// ── Helper Widgets (inchangés sauf les textes) ────────────────────────────────
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isMonospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ColorPalette.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: ColorPalette.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: ColorPalette.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color:
                      valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontFamily: isMonospace ? 'monospace' : null,
                  letterSpacing: isMonospace ? 0.5 : null,
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

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}