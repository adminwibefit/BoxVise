import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class CreateBoxScreen extends StatefulWidget {
  const CreateBoxScreen({super.key});

  @override
  State<CreateBoxScreen> createState() => _CreateBoxScreenState();
}

class _CreateBoxScreenState extends State<CreateBoxScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController(text: '0');

  String _selectedCategory = 'Other';
  bool _isCreating = false;

  // QR
  String _qrMode = 'generate'; // 'generate' or 'custom'
  String? _customQrData;       // raw QR value from scan/upload
  bool _qrError = false;       // shows inline error when custom QR not captured

  final List<String> _categories = [
    'Clothing', 'Tools', 'Documents', 'Kitchen', 'Electronics', 'Books', 'Other'
  ];

  late int _randomColorIndex;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _randomColorIndex = Random().nextInt(AppTheme.boxColors.length);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Scan QR via camera ────────────────────────────────────────────────────
  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const _CustomQrScannerScreen(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() { _customQrData = result; _qrError = false; });
    }
  }

  // ── Pick QR from image ────────────────────────────────────────────────────
  Future<void> _uploadQr() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final controller = MobileScannerController();
    final capture = await controller.analyzeImage(picked.path);
    controller.dispose();

    if (!mounted) return;

    final raw = capture?.barcodes.firstOrNull?.rawValue;
    if (raw != null && raw.isNotEmpty) {
      setState(() { _customQrData = raw; _qrError = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR captured: ${raw.length > 30 ? '${raw.substring(0, 30)}…' : raw}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No QR code found in image'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppTheme.boxColors[_randomColorIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Box',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _slideAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Card
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            selectedColor.withAlpha(102),
                            selectedColor.withAlpha(38),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: selectedColor.withAlpha(77), width: 2),
                        boxShadow: [
                          BoxShadow(color: selectedColor.withAlpha(64), blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_rounded, size: 48, color: selectedColor),
                          const SizedBox(height: 8),
                          Text(
                            _nameController.text.isEmpty ? 'New Box' : _nameController.text,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Box Name
                  const Text('Box Name', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Festival Clothes',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a box name' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Location
                  const Text('Location (Hierarchy)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. House > Bedroom > Closet',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a location' : null,
                  ),
                  const SizedBox(height: 20),

                  // Capacity + Category row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Capacity (Max Items)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _capacityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0 = unlimited',
                                prefixIcon: Icon(Icons.speed_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _selectedCategory = v ?? 'Other'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── QR Code Section ─────────────────────────────────────
                  const Text('QR Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _qrMode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'generate', child: Text('Generate QR')),
                      DropdownMenuItem(value: 'custom',   child: Text('Custom QR')),
                    ],
                    onChanged: (v) => setState(() {
                      _qrMode = v ?? 'generate';
                      if (_qrMode == 'generate') _customQrData = null;
                    }),
                  ),

                  // Custom QR sub-section
                  if (_qrMode == 'custom') ...[
                    const SizedBox(height: 16),
                    // Captured indicator
                    if (_customQrData != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'QR: ${_customQrData!.length > 36 ? '${_customQrData!.substring(0, 36)}…' : _customQrData!}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _customQrData = null),
                              child: const Icon(Icons.close_rounded, size: 16, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    // Scan / Upload buttons
                    Row(
                      children: [
                        Expanded(
                          child: _qrOptionButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Scan QR',
                            color: AppTheme.primaryColor,
                            isDark: isDark,
                            hasError: _qrError,
                            onTap: _scanQr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _qrOptionButton(
                            icon: Icons.upload_rounded,
                            label: 'Upload QR',
                            color: AppTheme.accentColor,
                            isDark: isDark,
                            hasError: _qrError,
                            onTap: _uploadQr,
                          ),
                        ),
                      ],
                    ),
                    if (_qrError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            'Please scan or upload a QR code',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(height: 40),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createBox,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedColor,
                        disabledBackgroundColor: selectedColor.withAlpha(120),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, size: 24),
                                SizedBox(width: 8),
                                Text('Create Box', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qrOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: hasError ? Colors.red.withAlpha(10) : color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasError ? Colors.red.withAlpha(100) : color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _createBox() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate custom QR
    if (_qrMode == 'custom' && _customQrData == null) {
      setState(() => _qrError = true);
      return;
    }

    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    setState(() => _isCreating = true);

    try {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      await provider.addBox(
        name: name,
        location: location,
        category: _selectedCategory,
        colorValue: AppTheme.boxColors[_randomColorIndex].toARGB32(),
        capacity: int.tryParse(_capacityController.text) ?? 0,
        customQrData: _qrMode == 'custom' ? _customQrData : null,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Box "$name" created!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create box: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ── Inline custom QR scanner (accepts any QR value) ───────────────────────────
class _CustomQrScannerScreen extends StatefulWidget {
  const _CustomQrScannerScreen();

  @override
  State<_CustomQrScannerScreen> createState() => _CustomQrScannerScreenState();
}

class _CustomQrScannerScreenState extends State<_CustomQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    setState(() => _hasScanned = true);
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _btn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  _btn(Icons.flash_on_rounded, () => _controller.toggleTorch()),
                ],
              ),
            ),
          ),
          // Instruction
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(200), Colors.black],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan Custom QR Code',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Point at any QR code to use it\nas this box\'s identifier',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(50)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
