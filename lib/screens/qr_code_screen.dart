import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/box_model.dart';
import '../theme/app_theme.dart';

class QrCodeScreen extends StatefulWidget {
  final BoxModel box;
  const QrCodeScreen({super.key, required this.box});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _saving = false;

  Future<void> _saveAndShare() async {
    setState(() => _saving = true);
    try {
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final boxName = (widget.box.name ?? 'box').replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
      final uuid = (widget.box.uuid ?? '').substring(0, 8);
      final file = File('${dir.path}/${boxName}_qr_$uuid.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: '${widget.box.name} - BoxVise QR');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uuid8 = (box.uuid ?? '').substring(0, 8).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Box Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
                child: Icon(Icons.inventory_2_rounded, color: color, size: 40),
              ),
              const SizedBox(height: 16),
              Text(box.name?.toString() ?? 'Unnamed Box', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 4),
                Text(box.location?.toString() ?? 'Unknown', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
              ]),
              const SizedBox(height: 28),

              // QR Code Card (capturable)
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: color.withAlpha(51), blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Box name inside the card
                      Text(
                        box.name?.toString() ?? 'Unnamed Box',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D1829)),
                      ),
                      const SizedBox(height: 14),
                      QrImageView(
                        data: 'Boxvise:${box.uuid}',
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF152540)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          uuid8,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF152540), letterSpacing: 1.5, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save / Print button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveAndShare,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_alt_rounded, size: 20),
                  label: Text(_saving ? 'Saving...' : 'Save & Print', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(38)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor.withAlpha(179), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Print this QR code and stick it on the physical box for quick scanning.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 14),

              // Items summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(13) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Box Contents', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black87)),
                  const SizedBox(height: 6),
                  Text('${box.items.length} items · ${box.totalQuantity} total quantity',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                  if (box.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: (box.items).where((i) => i != null).take(5).map((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                      child: Text(item.name?.toString() ?? '', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                    )).toList()),
                    if (box.items.length > 5) Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('+${box.items.length - 5} more', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
