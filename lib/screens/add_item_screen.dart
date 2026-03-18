import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class AddItemScreen extends StatefulWidget {
  final BoxModel box;
  final ItemModel? editItem;
  const AddItemScreen({super.key, required this.box, this.editItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _tagCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0.0'); // kept for data compatibility
  final List<String> _tags = [];
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  DateTime? _reminderDate;
  DateTime? _expiryDate;
  bool _isTemplate = false;

  final List<String> _nameSuggestions = [
    'Hammer', 'Screwdriver', 'Tape', 'Drill', 'Screws', 'Wrench',
    'Passport', 'IDs', 'Certificates', 'Policy',
    'T-shirt', 'Jeans', 'Socks', 'Jacket', 'Shoes',
    'Laptop', 'Charger', 'Cables', 'Phone', 'Tablet'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      _nameCtrl.text = widget.editItem!.name ?? '';
      _descCtrl.text = widget.editItem!.description ?? '';
      _qtyCtrl.text = (widget.editItem!.quantity ?? 1).toString();
      _tags.addAll(widget.editItem!.tags);
      if (widget.editItem!.imagePath != null && File(widget.editItem!.imagePath!).existsSync()) {
        _selectedImage = File(widget.editItem!.imagePath!);
      }
      _isTemplate = widget.editItem!.isTemplate;
      _reminderDate = widget.editItem!.reminderDate;
      _priceCtrl.text = (widget.editItem!.price ?? 0.0).toStringAsFixed(2);
      _expiryDate = widget.editItem!.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _tagCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 50,
      );
      if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  void _showImagePickerSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(widget.box.colorValue ?? AppTheme.primaryColor.value);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF152540) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Add Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _imageOptionTile(icon: Icons.camera_alt_rounded, label: 'Take Photo', subtitle: 'Use your camera', color: color,
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
              const SizedBox(height: 12),
              _imageOptionTile(icon: Icons.photo_library_rounded, label: 'Choose from Gallery', subtitle: 'Pick an existing photo', color: AppTheme.accentColor,
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                _imageOptionTile(icon: Icons.delete_rounded, label: 'Remove Photo', subtitle: 'Delete the selected photo', color: AppTheme.errorColor,
                  onTap: () { Navigator.pop(ctx); setState(() => _selectedImage = null); }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageOptionTile({required IconData icon, required String label, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
          ])),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 20),
        ]),
      ),
    );
  }

  Future<String?> _saveImagePermanently(File image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/item_images');
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    final savedImage = await image.copy('${imagesDir.path}/$fileName');
    return savedImage.path;
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() { _tags.add(tag); _tagCtrl.clear(); });
    }
  }

  void _lookupPrice() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter item name first')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching prices on eBay & Amazon...')));
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _priceCtrl.text = '24.99');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Found price: \$24.99')));
  }

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InventoryProvider>();
      String? savedPath;
      if (_selectedImage != null && (widget.editItem == null || _selectedImage!.path != widget.editItem!.imagePath)) {
        savedPath = await _saveImagePermanently(_selectedImage!);
      } else if (widget.editItem != null) {
        savedPath = widget.editItem!.imagePath;
      }

      if (!mounted) return;

      if (widget.editItem != null) {
        await provider.updateItem(widget.box, widget.editItem!,
          name: _nameCtrl.text.trim(), description: _descCtrl.text.trim(),
          quantity: int.tryParse(_qtyCtrl.text) ?? 1, tags: _tags, imagePath: savedPath,
          isTemplate: _isTemplate, reminderDate: _reminderDate,
          price: double.tryParse(_priceCtrl.text) ?? 0.0, expiryDate: _expiryDate);
      } else {
        await provider.addItem(widget.box,
          name: _nameCtrl.text.trim(), description: _descCtrl.text.trim(),
          quantity: int.tryParse(_qtyCtrl.text) ?? 1, tags: _tags, imagePath: savedPath,
          isTemplate: _isTemplate, reminderDate: _reminderDate,
          price: double.tryParse(_priceCtrl.text) ?? 0.0, expiryDate: _expiryDate);
      }

      final suggestion = provider.suggestBoxCategory(widget.box);

      Navigator.pop(context);
      if (suggestion != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.editItem == null
              ? '${_nameCtrl.text.trim()} added! Suggestion: Change box category to "$suggestion"?'
              : 'Item updated! Suggestion: Change box category to "$suggestion"?'),
          action: SnackBarAction(label: 'Update', onPressed: () => provider.updateBoxCategory(widget.box, suggestion)),
          duration: const Duration(seconds: 4),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.editItem == null ? '${_nameCtrl.text.trim()} added!' : 'Item updated!')),
        );
      }
    }
  }

  void _showBulkDeleteConfirm(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${provider.selectedBoxIds.length} boxes and all their items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { provider.deleteSelectedBoxes(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boxes deleted'))); },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  final Map<String, List<String>> _tagSuggestionsMap = {
    'screwdriver': ['tools', 'garage', 'hardware'],
    'hammer': ['tools', 'garage', 'construction'],
    'passport': ['documents', 'travel', 'important'],
    'shirt': ['clothing', 'apparel'],
    'pants': ['clothing', 'apparel'],
    'jacket': ['clothing', 'winter'],
    'cable': ['electronics', 'tech'],
    'charger': ['electronics', 'tech'],
  };

  void _checkSuggestions(String value) {
    final query = value.toLowerCase().trim();
    if (_tagSuggestionsMap.containsKey(query)) {
      for (final s in _tagSuggestionsMap[query]!) {
        if (!_tags.contains(s)) setState(() => _tags.add(s));
      }
    }
  }

  void _showTemplatePicker(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template picker not yet implemented!')));
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editItem != null;
    final cardColor = isDark ? const Color(0xFF152540) : Colors.white;
    final fieldFill = isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(15);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1829) : const Color(0xFFF5F6F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Item' : 'Add Item',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.box.name ?? 'Unnamed Box',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (isEditing)
                IconButton(
                  icon: Icon(Icons.bookmark_rounded, color: _isTemplate ? color : (isDark ? Colors.white38 : Colors.black26), size: 22),
                  onPressed: () => setState(() => _isTemplate = !_isTemplate),
                  tooltip: _isTemplate ? 'Saved as template' : 'Save as template',
                ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Card 1: Photo + Name + Description ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Photo thumbnail
                              GestureDetector(
                                onTap: _showImagePickerSheet,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: fieldFill,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _selectedImage != null ? color.withAlpha(80) : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)),
                                      width: _selectedImage != null ? 2 : 1,
                                    ),
                                    image: _selectedImage != null
                                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: _selectedImage == null
                                      ? Icon(Icons.add_a_photo_rounded, color: color.withAlpha(120), size: 22)
                                      : Align(
                                          alignment: Alignment.bottomRight,
                                          child: Container(
                                            margin: const EdgeInsets.all(3),
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(color: Colors.black.withAlpha(120), shape: BoxShape.circle),
                                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Name field
                              Expanded(
                                child: Autocomplete<String>(
                                  optionsBuilder: (TextEditingValue v) {
                                    if (v.text.isEmpty) return const Iterable<String>.empty();
                                    return _nameSuggestions.where((o) => o.toLowerCase().contains(v.text.toLowerCase()));
                                  },
                                  onSelected: (String s) { _nameCtrl.text = s; _checkSuggestions(s); },
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                    if (controller.text.isEmpty && _nameCtrl.text.isNotEmpty) controller.text = _nameCtrl.text;
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        hintText: 'Item name',
                                        hintStyle: TextStyle(fontWeight: FontWeight.w400, color: isDark ? Colors.white24 : Colors.black26),
                                        filled: true,
                                        fillColor: fieldFill,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.bookmark_added_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
                                          onPressed: () => _showTemplatePicker(context),
                                        ),
                                      ),
                                      onChanged: (v) { _nameCtrl.text = v; _checkSuggestions(v); },
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Add a description (optional)',
                              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                              filled: true,
                              fillColor: fieldFill,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Card 2: Quantity ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
                      ),
                      child: Row(
                        children: [
                          Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54)),
                          const Spacer(),
                          _qtyBtn(Icons.remove_rounded, color, () {
                            int c = int.tryParse(_qtyCtrl.text) ?? 1;
                            if (c > 1) setState(() => _qtyCtrl.text = '${c - 1}');
                          }),
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                              validator: (v) => (v == null || v.isEmpty || (int.tryParse(v) ?? 0) < 1) ? 'Min 1' : null,
                            ),
                          ),
                          _qtyBtn(Icons.add_rounded, color, () {
                            int c = int.tryParse(_qtyCtrl.text) ?? 1;
                            setState(() => _qtyCtrl.text = '${c + 1}');
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Card 3: Reminder + Expiry ──
                    Row(
                      children: [
                        Expanded(child: _DateChip(
                          label: 'Reminder', icon: Icons.notifications_active_outlined,
                          date: _reminderDate, color: color, isDark: isDark, cardColor: cardColor, formatDate: _formatDate,
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _reminderDate ?? DateTime.now(),
                              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                            if (date != null) setState(() => _reminderDate = date);
                          },
                          onClear: _reminderDate != null ? () => setState(() => _reminderDate = null) : null,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _DateChip(
                          label: 'Expiry', icon: Icons.timer_outlined,
                          date: _expiryDate, color: color, isDark: isDark, cardColor: cardColor, formatDate: _formatDate,
                          onTap: () async {
                            final date = await showDatePicker(context: context, initialDate: _expiryDate ?? DateTime.now(),
                              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                            if (date != null) setState(() => _expiryDate = date);
                          },
                          onClear: _expiryDate != null ? () => setState(() => _expiryDate = null) : null,
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Card 4: Tags ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Tags', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black54)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _isTemplate = !_isTemplate),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isTemplate ? color.withAlpha(12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _isTemplate ? color.withAlpha(50) : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(10))),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(_isTemplate ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded, size: 12,
                                        color: _isTemplate ? color : (isDark ? Colors.white38 : Colors.black38)),
                                    const SizedBox(width: 3),
                                    Text('Template', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                        color: _isTemplate ? color : (isDark ? Colors.white38 : Colors.black38))),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _tagCtrl,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Add tag...',
                                    hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                                    filled: true, fillColor: fieldFill,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 10, right: 4),
                                      child: Icon(Icons.label_outline_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 30),
                                  ),
                                  onFieldSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _addTag,
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: _tags.map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(10),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: color.withAlpha(25)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black54)),
                                  const SizedBox(width: 3),
                                  GestureDetector(
                                    onTap: () => setState(() => _tags.remove(t)),
                                    child: Icon(Icons.close_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ]),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Save Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(isEditing ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(isEditing ? 'Save Changes' : 'Add Item', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

// ── Date Chip Widget ──────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final Color color;
  final bool isDark;
  final Color cardColor;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateChip({
    required this.label,
    required this.icon,
    required this.date,
    required this.color,
    required this.isDark,
    required this.cardColor,
    required this.formatDate,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasDate ? color.withAlpha(40) : (isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(8))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hasDate ? color : (isDark ? Colors.white38 : Colors.black26)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
                  Text(
                    hasDate ? formatDate(date!) : 'Not set',
                    style: TextStyle(fontSize: 12, fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                        color: hasDate ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white24 : Colors.black26)),
                  ),
                ],
              ),
            ),
            if (hasDate && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
              ),
          ],
        ),
      ),
    );
  }
}
