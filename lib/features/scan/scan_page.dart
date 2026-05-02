import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/color_palette.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}
class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  // ── QR Scanner Controller — initialized in initState ──────────────────────
  late MobileScannerController _scanner;

  late final AnimationController _beamCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();


  final bool _isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    // Initialize scanner controller but don't start yet
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
    );
    
    if (_isMobile) _requestCameraPermission();
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    // Ensure scanner is stopped and disposed
    _scanner.stop();
    _scanner.dispose();
    super.dispose();
  }

  // ── Camera Permission ─────────────────────────────────────────────────────

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    
    if (status.isGranted) {
      // Permission granted - start camera
      await _scanner.start();
      if (mounted) {
        setState(() {});
      }
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied
      if (mounted) {
        setState(() {});
      }
    } else {
      // Permission temporarily denied
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ── QR Parser ─────────────────────────────────────────────────────────────
  //
  // Expected format: "SF|{name}|{dd/MM/yyyy/HH/mm/ss}|{uid}"
  //   parts[0] = "SF"  ← SmartFresh prefix (rejects foreign QR codes)
  //   parts[1] = name
  //   parts[2] = date  (dd/MM/yyyy/HH/mm/ss)
  //   parts[3] = uid   (20-char alphanumeric)
  //
  // Example: "SF|yayout|21/05/2025/23/22/11|FCV45T3QAWSWDEDEDEDE"

  void _onDetected(BarcodeCapture capture) {
    // Placeholder for QR detection logic
  }

  // ── Realtime Database duplicate check ─────────────────────────────────────
  //
  // Checks all 4 zone paths for the given UID.
  // Returns the zone name if found, null if not found.


  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('scanPage'.tr()),
        centerTitle: true,
      ),
      body: _isMobile
          ? MobileScanner(
              controller: _scanner,
              onDetect: _onDetected,
            )
          : Center(
              child: Text('cameraNotSupported'.tr()),
            ),
    );
  }
}
// ── Scan Overlay ──────────────────────────────────────────────────────────────



// ── Corner Bracket Painter ────────────────────────────────────────────────────

// ignore: unused_element
class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;

    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(
        Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, len), paint);
    canvas.drawLine(
        Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(
        Offset(size.width - len, size.height),
        Offset(size.width, size.height),
        paint);
    canvas.drawLine(
        Offset(size.width, size.height - len),
        Offset(size.width, size.height),
        paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── QR Result Bottom Sheet ────────────────────────────────────────────────────

class _QrResultSheet extends StatefulWidget {
  const _QrResultSheet({
    required this.name,
    required this.expired,
    required this.uid,
    required this.isValidFormat,
    required this.existingZone, // null = new, 'zone1'/'zone2'/etc = duplicate
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
        return 'Zone 1';
      case 'zone2':
        return 'Zone 2';
      case 'zone3':
        return 'Zone 3';
      case 'pirimi':
        return 'Périmés';
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
              _selectedZone == 'zone1' ? 'Zone 1' : 'Zone 2'
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
            // ── Drag handle ──
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

            // ── Header ──
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
                            ? 'Produit déjà enregistré'
                            : 'barcodeDetected'.tr(),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        isDuplicate
                            ? 'Déjà dans ${_zoneDisplayName(widget.existingZone!)}'
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

            // ── Duplicate warning banner ──
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
                        'Ce produit existe déjà dans ${_zoneDisplayName(widget.existingZone!)}. '
                        'Vous pouvez quand même l\'ajouter dans une autre zone.',
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

            // ── Product details ──
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

            // ── Zone selector (zone1 and zone2 only) ──
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
                  label: 'Zone 1',
                  color: ColorPalette.success,
                  selected: _selectedZone == 'zone1',
                  onTap: () {
                    if (mounted) {
                      setState(() => _selectedZone = 'zone1');
                    }
                  },
                ),
                const SizedBox(width: 12),
                _ZoneChip(
                  label: 'Zone 2',
                  color: ColorPalette.primary,
                  selected: _selectedZone == 'zone2',
                  onTap: () {
                    if (mounted) {
                      setState(() => _selectedZone = 'zone2');
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Action buttons ──
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

// ── Helper Widgets ────────────────────────────────────────────────────────────

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
                  color: valueColor ??
                      Theme.of(context).colorScheme.onSurface,
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