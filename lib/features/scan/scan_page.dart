import 'package:firebase_database/firebase_database.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartfresh/service/firestore%20provider.dart';

import '../../core/theme/color_palette.dart';
import '../../shared/widgets/app_button.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  // ── QR-only, normal speed — fastest possible detection ──────────────────
  late final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode], // QR only — no false positives
  );

  late final AnimationController _beamCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  bool _hasPermission = false;
  bool _permanentlyDenied = false;
  bool _hasScanned = false;
  bool _torchOn = false;

  final bool _isMobile = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_isMobile) _requestCameraPermission();
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    _scanner.dispose();
    super.dispose();
  }

  // ── Camera Permission ─────────────────────────────────────────────────────

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
      _permanentlyDenied = status.isPermanentlyDenied;
    });
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

  ({String name, DateTime expired, String uid, bool valid}) _parseQr(
      String raw) {
    debugPrint('🔍 Raw QR value: "$raw"');

    try {
      final parts = raw.split('|');

      // Must have exactly 4 parts AND start with "SF"
      if (parts.length == 4 && parts[0] == 'SF') {
        return _parseParts(parts[1], parts[2], parts[3]);
      }
    } catch (e) {
      debugPrint('❌ QR parse exception: $e');
    }

    debugPrint('⚠️ Not a SmartFresh QR code: "$raw"');
    return (
      name: raw.length > 40 ? '${raw.substring(0, 40)}…' : raw,
      expired: DateTime.now().add(const Duration(days: 1)),
      uid: 'UNKNOWN',
      valid: false,
    );
  }

  ({String name, DateTime expired, String uid, bool valid}) _parseParts(
      String rawName, String rawDate, String rawUid) {
    final name = rawName.trim();
    final uid = rawUid.trim();
    final seg = rawDate.trim().split('/');

    debugPrint('📅 Date segments: $seg (count: ${seg.length})');
    debugPrint('🔑 UID: "$uid"  |  Name: "$name"');

    if (seg.length != 6) return _invalid(rawName, rawDate, rawUid);

    final dd = int.tryParse(seg[0]);
    final mm = int.tryParse(seg[1]);
    final yyyy = int.tryParse(seg[2]);
    final hh = int.tryParse(seg[3]);
    final min = int.tryParse(seg[4]);
    final ss = int.tryParse(seg[5]);

    if (dd == null ||
        mm == null ||
        yyyy == null ||
        hh == null ||
        min == null ||
        ss == null) {
      return _invalid(rawName, rawDate, rawUid);
    }

    if (name.isEmpty || uid.isEmpty) {
      return _invalid(rawName, rawDate, rawUid);
    }

    final expiry = DateTime(yyyy, mm, dd, hh, min, ss);
    debugPrint('✅ Parsed → name="$name" expiry=$expiry uid="$uid"');

    return (name: name, expired: expiry, uid: uid, valid: true);
  }

  ({String name, DateTime expired, String uid, bool valid}) _invalid(
      String n, String d, String u) {
    return (
      name: n,
      expired: DateTime.now().add(const Duration(days: 1)),
      uid: u.isEmpty ? 'UNKNOWN' : u,
      valid: false,
    );
  }

  // ── Realtime Database duplicate check ─────────────────────────────────────
  //
  // Checks all 4 zone paths for the given UID.
  // Returns the zone name if found, null if not found.

  Future<String?> _findExistingZone(String uid) async {
    final zones = ['zone1', 'zone2', 'zone3', 'pirimi'];
    for (final zone in zones) {
      final path = FridgePaths.collectionForZone(zone);
      final snapshot = await FirebaseDatabase.instance
          .ref('$path/$uid')
          .get();
      if (snapshot.exists) return zone;
    }
    return null;
  }

  // ── On QR Detected ────────────────────────────────────────────────────────

  Future<void> _onDetected(String rawValue) async {
    if (_hasScanned) return;
    setState(() => _hasScanned = true);

    HapticFeedback.mediumImpact();
    await _scanner.stop();

    final parsed = _parseQr(rawValue);

    // Only check Realtime Database if the QR is a valid SmartFresh code
    String? existingZone;
    if (parsed.valid && parsed.uid != 'UNKNOWN') {
      existingZone = await _findExistingZone(parsed.uid);
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _QrResultSheet(
        name: parsed.name,
        expired: parsed.expired,
        uid: parsed.uid,
        isValidFormat: parsed.valid,
        existingZone: existingZone, // null = new product
        onAdd: (zoneName) => saveProductToZone(
          name: parsed.name,
          expired: parsed.expired,
          uid: parsed.uid,
          zoneName: zoneName,
        ),
      ),
    );

    if (mounted) {
      setState(() => _hasScanned = false);
      await _scanner.start();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isMobile) return _unsupportedView();
    if (!_hasPermission) return _permissionView();
    return _scannerView();
  }

  Widget _unsupportedView() => Scaffold(
        appBar: AppBar(title: Text('scan'.tr())),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded,
                  size: 72, color: ColorPalette.secondary),
              const SizedBox(height: 16),
              Text('cameraNotSupported'.tr(),
                  style: const TextStyle(color: ColorPalette.secondary)),
            ],
          ),
        ),
      );

  Widget _permissionView() => Scaffold(
        appBar: AppBar(title: Text('scan'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: ColorPalette.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 52, color: ColorPalette.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'cameraPermissionRequired'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'cameraPermissionDesc'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: ColorPalette.secondary, fontSize: 13),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: _permanentlyDenied
                      ? 'openSettings'.tr()
                      : 'grantPermission'.tr(),
                  icon: _permanentlyDenied
                      ? Icons.settings_rounded
                      : Icons.camera_alt_rounded,
                  onPressed: _permanentlyDenied
                      ? openAppSettings
                      : _requestCameraPermission,
                ),
                if (!_permanentlyDenied) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _requestCameraPermission,
                    child: Text('retry'.tr()),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _scannerView() => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Camera feed ──
            Positioned.fill(
              child: MobileScanner(
                controller: _scanner,
                onDetect: (capture) {
                  for (final b in capture.barcodes) {
                    if (b.rawValue != null && !_hasScanned) {
                      _onDetected(b.rawValue!);
                    }
                  }
                },
              ),
            ),

            // ── Dark overlay with scan cutout ──
            Positioned.fill(child: _ScanOverlay()),

            // ── Top bar ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      'scanBarcode'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        _scanner.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      icon: Icon(
                        _torchOn
                            ? Icons.flashlight_off_rounded
                            : Icons.flashlight_on_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Scan frame with animated beam ──
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(260, 260),
                      painter: _CornerPainter(color: ColorPalette.primary),
                    ),
                    AnimatedBuilder(
                      animation: _beamCtrl,
                      builder: (_, __) => Positioned(
                        top: _beamCtrl.value * 248,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              ColorPalette.primary,
                              Colors.transparent,
                            ]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom instructions ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Column(
                children: [
                  Text(
                    'pointCamera'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54)
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SmartFresh QR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black54)
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => _scanner.switchCamera(),
                    icon: const Icon(Icons.flip_camera_ios_rounded,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Scan Overlay ──────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ignore: deprecated_member_use
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final center = Offset(size.width / 2, size.height / 2);
    final cutout = Rect.fromCenter(center: center, width: 260, height: 260);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Corner Bracket Painter ────────────────────────────────────────────────────

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
      debugPrint('❌ Firestore save error: $e');
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
                  onTap: () => setState(() => _selectedZone = 'zone1'),
                ),
                const SizedBox(width: 12),
                _ZoneChip(
                  label: 'Zone 2',
                  color: ColorPalette.primary,
                  selected: _selectedZone == 'zone2',
                  onTap: () => setState(() => _selectedZone = 'zone2'),
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