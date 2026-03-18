import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../models/box_model.dart';

class QrSheetScreen extends StatefulWidget {
  const QrSheetScreen({super.key});

  @override
  State<QrSheetScreen> createState() => _QrSheetScreenState();
}

class _QrSheetScreenState extends State<QrSheetScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _saving = false;

  Future<void> _saveAsImage() async {
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/boxvise_qr_codes.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'BoxVise QR Codes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAsPdf(List<BoxModel> boxes) async {
    setState(() => _saving = true);
    try {
      final pdf = pw.Document();

      // Split into pages of 9 (3x3 grid)
      final pages = <List<BoxModel>>[];
      for (var i = 0; i < boxes.length; i += 9) {
        pages.add(boxes.sublist(i, i + 9 > boxes.length ? boxes.length : i + 9));
      }

      for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final pageBoxes = pages[pageIndex];
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(30),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('BoxVise QR Labels', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Page ${pageIndex + 1} of ${pages.length}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(
                    child: pw.GridView(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: pageBoxes.map((box) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                box.name ?? 'Unnamed',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                                maxLines: 1,
                              ),
                              pw.SizedBox(height: 6),
                              pw.BarcodeWidget(
                                barcode: pw.Barcode.qrCode(),
                                data: 'Boxvise:${box.uuid}',
                                width: 90,
                                height: 90,
                              ),
                              pw.SizedBox(height: 6),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey100,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                ),
                                child: pw.Text(
                                  (box.uuid ?? '').substring(0, 8).toUpperCase(),
                                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final boxes = provider.boxes;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1829) : const Color(0xFFF5F6F8),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF0D1829) : const Color(0xFFF5F6F8),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All QR Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  '${boxes.length} ${boxes.length == 1 ? 'box' : 'boxes'}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45),
                ),
              ],
            ),
          ),
          body: boxes.isEmpty
              ? _buildEmptyState(isDark)
              : Column(
                  children: [
                    // QR Grid Preview
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: RepaintBoundary(
                          key: _repaintKey,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Header inside the card
                                Row(
                                  children: [
                                    Icon(Icons.qr_code_2_rounded, size: 18, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    const Text('BoxVise QR Labels',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1829))),
                                    const Spacer(),
                                    Text('${boxes.length} codes',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // QR Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.78,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: boxes.length,
                                  itemBuilder: (_, i) => _QrTile(box: boxes[i]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Bottom action bar
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF152540) : Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DownloadBtn(
                              icon: Icons.image_rounded,
                              label: 'Save as Image',
                              color: AppTheme.primaryColor,
                              isDark: isDark,
                              loading: _saving,
                              onTap: _saving ? null : _saveAsImage,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DownloadBtn(
                              icon: Icons.picture_as_pdf_rounded,
                              label: 'Save as PDF',
                              color: AppTheme.accentColor,
                              isDark: isDark,
                              loading: _saving,
                              onTap: _saving ? null : () => _saveAsPdf(boxes),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_2_rounded, size: 48, color: AppTheme.primaryColor.withAlpha(100)),
          ),
          const SizedBox(height: 16),
          const Text('No QR codes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Create a box to generate QR labels', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}

// ── QR Tile ──────────────────────────────────────────────────────────────────

class _QrTile extends StatelessWidget {
  final BoxModel box;
  const _QrTile({required this.box});

  @override
  Widget build(BuildContext context) {
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            box.name ?? 'Unnamed',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: QrImageView(
              data: 'Boxvise:${box.uuid}',
              version: QrVersions.auto,
              padding: EdgeInsets.zero,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: const Color(0xFF0D1829)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0D1829)),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5FA),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (box.uuid ?? '').substring(0, 8).toUpperCase(),
              style: const TextStyle(fontSize: 7, color: Color(0xFF666666), fontFamily: 'monospace', letterSpacing: 0.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Download Button ──────────────────────────────────────────────────────────

class _DownloadBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool loading;
  final VoidCallback? onTap;

  const _DownloadBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
