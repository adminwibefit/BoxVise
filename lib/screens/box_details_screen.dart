import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nfc_service.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'add_item_screen.dart';
import 'qr_code_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class BoxDetailsScreen extends StatefulWidget {
  final BoxModel box;
  final String? heroTag;

  const BoxDetailsScreen({super.key, required this.box, this.heroTag});

  @override
  State<BoxDetailsScreen> createState() => _BoxDetailsScreenState();
}

class _BoxDetailsScreenState extends State<BoxDetailsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final filteredItems = box.items.where((i) {
          final q = _searchQuery.toLowerCase();
          final nameMatch = (i.name ?? '').toLowerCase().contains(q);
          final tagsMatch = (i.tags).any((t) => t.toLowerCase().contains(q));
          return nameMatch || tagsMatch;
        }).toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF080D1A) : const Color(0xFFF0F2F8),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF080D1A) : const Color(0xFFF0F2F8),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      provider.selectedItemIds.isNotEmpty ? Icons.close_rounded : Icons.arrow_back_rounded,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onPressed: () {
                    if (provider.selectedItemIds.isNotEmpty) {
                      provider.clearSelection();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: provider.selectedItemIds.isNotEmpty
                    ? Text('${provider.selectedItemIds.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))
                    : null,
                actions: provider.selectedItemIds.isNotEmpty
                    ? [
                        _NavBtn(icon: Icons.move_up_rounded, isDark: isDark,
                            onTap: () => _showMoveSelectionDialog(context, provider)),
                        _NavBtn(icon: Icons.delete_rounded, isDark: isDark,
                            iconColor: AppTheme.errorColor,
                            onTap: () => _showBulkItemDeleteConfirm(context, provider)),
                        const SizedBox(width: 8),
                      ]
                    : [
                        _NavBtn(icon: Icons.qr_code_rounded, isDark: isDark,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => QrCodeScreen(box: box)))),
                        _NavBtn(icon: Icons.ios_share_rounded, isDark: isDark,
                            onTap: () => _showShareSheet(context, provider)),
                        _NavBtn(icon: Icons.edit_rounded, isDark: isDark,
                            onTap: () => _showEditBoxDialog(context, provider)),
                        const SizedBox(width: 8),
                      ],
              ),

              // Box Identity Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: color.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: widget.heroTag ?? 'box_${box.id}',
                          child: Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.inventory_2_rounded, color: color, size: 26),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                box.name?.toString() ?? 'Unnamed Box',
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: color),
                                  const SizedBox(width: 3),
                                  Text(box.location?.toString() ?? 'Unknown',
                                      style: TextStyle(fontSize: 12,
                                          color: isDark ? Colors.white.withAlpha(140) : Colors.black45)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.label_rounded, size: 12, color: color),
                                  const SizedBox(width: 3),
                                  Text(box.category?.toString() ?? 'Other',
                                      style: TextStyle(fontSize: 12,
                                          color: isDark ? Colors.white.withAlpha(140) : Colors.black45)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          icon: Icons.widgets_rounded,
                          label: 'Items',
                          value: '${box.items.length}',
                          color: color,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatChip(
                          icon: Icons.tag_rounded,
                          label: 'Total Qty',
                          value: '${box.totalQuantity}',
                          color: AppTheme.accentColor,
                          isDark: isDark,
                        ),
                      ),
                      if ((box.capacity ?? 0) > 0) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.storage_rounded,
                            label: 'Used',
                            value: '${((box.items.length / box.capacity!) * 100).toInt()}%',
                            color: AppTheme.warningColor,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Items Section Header + Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${box.items.length} total',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white30 : Colors.black38),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20,
                              color: isDark ? Colors.white30 : Colors.black38),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF111827) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Items List
              filteredItems.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Icons.category_outlined,
                        title: _searchQuery.isNotEmpty ? 'No matches' : 'No items yet',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'Tap + Add Item to get started',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _ItemCard(
                            item: filteredItems[i],
                            box: box,
                            color: color,
                          ),
                          childCount: filteredItems.length,
                        ),
                      ),
                    ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => AddItemScreen(box: box))),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 6,
          ),
        );
      },
    );
  }

  // ── Share bottom sheet ────────────────────────────────────────────────────
  void _showShareSheet(BuildContext context, InventoryProvider provider) {
    final box = widget.box;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Actions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 14),
            _ActionRow(
              icon: Icons.shopping_cart_rounded,
              label: 'Add to Shop List',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                provider.addToShoppingList(box);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Box added to shop list')));
              },
            ),
            _ActionRow(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Share PDF Report',
              color: AppTheme.errorColor,
              onTap: () { Navigator.pop(context); _shareBoxPdf(); },
            ),
            _ActionRow(
              icon: Icons.text_snippet_rounded,
              label: 'Share as Text',
              color: AppTheme.accentColor,
              onTap: () { Navigator.pop(context); _shareBoxText(); },
            ),
            _ActionRow(
              icon: Icons.qr_code_2_rounded,
              label: 'Share QR Label',
              color: AppTheme.warningColor,
              onTap: () { Navigator.pop(context); provider.shareQrLabelPdf(box); },
            ),
            _ActionRow(
              icon: Icons.nfc_rounded,
              label: 'Write to NFC Tag',
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => NfcSheet(isWriting: true, dataToWrite: box.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Move selection ────────────────────────────────────────────────────────
  void _showMoveSelectionDialog(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Move items to…',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.boxes.length,
              itemBuilder: (c, i) {
                final b = provider.boxes[i];
                if (b.id == widget.box.id) return const SizedBox.shrink();
                return ListTile(
                  leading: Icon(Icons.inventory_2_rounded,
                      color: Color(b.colorValue ?? AppTheme.primaryColor.value)),
                  title: Text(b.name ?? 'Unnamed Box'),
                  onTap: () {
                    provider.moveSelectedItems(widget.box.id, b.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Items moved to ${b.name}')));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Bulk delete ───────────────────────────────────────────────────────────
  void _showBulkItemDeleteConfirm(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text(
            'Delete ${provider.selectedItemIds.length} items from this box?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteSelectedItems(widget.box);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Share PDF ─────────────────────────────────────────────────────────────
  Future<void> _shareBoxPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, text: 'Box: ${widget.box.name ?? "Unnamed"}'),
            pw.Text('Location: ${widget.box.location ?? "Unknown"}'),
            pw.Text('Category: ${widget.box.category ?? "Other"}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Item Name', 'Quantity', 'Tags'],
                ...widget.box.items.map(
                    (i) => [i.name ?? '', (i.quantity ?? 1).toString(), (i.tags).join(', ')]),
              ],
            ),
          ],
        ),
      ),
    );
    final output = await getTemporaryDirectory();
    final file =
        File('${output.path}/${widget.box.name ?? "inventory"}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)],
        text: 'Inventory for ${widget.box.name}');
  }

  // ── Share text ────────────────────────────────────────────────────────────
  void _shareBoxText() {
    final box = widget.box;
    final buf = StringBuffer();
    buf.writeln('Box: ${box.name ?? "Unnamed"}');
    buf.writeln('Location: ${box.location ?? "Unknown"}');
    buf.writeln('--- Items ---');
    for (final item in box.items) {
      buf.writeln('- ${item.name} (${item.quantity}x)');
    }
    Share.share(buf.toString(), subject: 'Inventory List');
  }

  // ── Edit box ──────────────────────────────────────────────────────────────
  void _showEditBoxDialog(BuildContext context, InventoryProvider provider) {
    final nameCtrl = TextEditingController(text: widget.box.name ?? '');
    final locationCtrl =
        TextEditingController(text: widget.box.location ?? '');
    String selectedCategory = widget.box.category ?? 'Other';
    final categories = [
      'Clothing', 'Tools', 'Documents', 'Kitchen', 'Electronics', 'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Box'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Box Name',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.contains(selectedCategory)
                    ? selectedCategory
                    : 'Other',
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCategory = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                provider.updateBox(
                  widget.box,
                  name: nameCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  category: selectedCategory,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavBtn(
      {required this.icon,
      required this.isDark,
      required this.onTap,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 17, color: iconColor ?? (isDark ? Colors.white : Colors.black87)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title:
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Item Card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final ItemModel item;
  final BoxModel box;
  final Color color;

  const _ItemCard(
      {required this.item, required this.box, required this.color});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected =
        context.watch<InventoryProvider>().selectedItemIds.contains(item.id);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withAlpha(40),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded,
            color: AppTheme.errorColor, size: 24),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Delete "${item.name ?? 'this item'}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        final name = item.name ?? 'Item';
        provider.deleteItem(box, item);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" deleted'),
          action:
              SnackBarAction(label: 'Undo', onPressed: provider.undoDeleteItem),
        ));
      },
      child: GestureDetector(
        onTap: () {
          if (provider.selectedItemIds.isNotEmpty) {
            provider.toggleItemSelection(item.id);
          } else {
            _showItemActions(context, provider, isDark);
          }
        },
        onLongPress: () => provider.toggleItemSelection(item.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withAlpha(30)
                : (isDark ? const Color(0xFF111827) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? color.withAlpha(120)
                  : (isDark
                      ? Colors.white.withAlpha(10)
                      : Colors.black.withAlpha(8)),
            ),
          ),
          child: Row(
            children: [
              // Icon / Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.imagePath != null &&
                        File(item.imagePath!).existsSync()
                    ? Image.file(File(item.imagePath!),
                        width: 48, height: 48, fit: BoxFit.cover)
                    : Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: color.withAlpha(22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.widgets_rounded,
                            color: color, size: 22),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name?.toString() ?? 'Unnamed Item',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white.withAlpha(115) : Colors.black45),
                      ),
                    ],
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        children: item.tags
                            .take(3)
                            .map((t) => Text('#$t',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600)))
                            .toList(),
                      ),
                    ],
                    if ((item.quantity ?? 0) <= 1) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppTheme.errorColor),
                          SizedBox(width: 3),
                          Text('Low Stock',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorColor)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Qty stepper + context menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Qty stepper
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QtyBtn(
                            icon: Icons.remove_rounded,
                            onTap: () =>
                                provider.decrementQuantity(box, item)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${item.quantity}',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: color)),
                        ),
                        _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: () =>
                                provider.incrementQuantity(box, item)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // More actions
                  GestureDetector(
                    onTap: () =>
                        _showItemActions(context, provider, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.more_horiz_rounded,
                          size: 16,
                          color:
                              isDark ? Colors.white54 : Colors.black38),
                    ),
                  ),
                ],
              ),

              // Selection check
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showItemActions(
      BuildContext context, InventoryProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.widgets_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(item.name ?? 'Item',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.edit_rounded,
              label: 'Edit Item',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddItemScreen(box: box, editItem: item)));
              },
            ),
            _ActionRow(
              icon: Icons.add_shopping_cart_rounded,
              label: 'Add to Shop List',
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.pop(context);
                provider.addToShoppingList(box, item);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.name} added to shop list')));
              },
            ),
            _ActionRow(
              icon: Icons.front_hand_rounded,
              label: 'Lend Item',
              color: AppTheme.warningColor,
              onTap: () {
                Navigator.pop(context);
                _showLendDialog(context, provider, item);
              },
            ),
            _ActionRow(
              icon: Icons.delete_rounded,
              label: 'Delete Item',
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Item'),
                    content: Text('Delete "${item.name}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          provider.deleteItem(box, item);
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

// ── Lend dialog ───────────────────────────────────────────────────────────────

void _showLendDialog(
    BuildContext context, InventoryProvider provider, ItemModel item) {
  final nameCtrl = TextEditingController();
  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Lend ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Borrower Name',
                hintText: 'Who is borrowing this?',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text(selectedDate == null
                  ? 'No Return Date Set'
                  : 'Return By: ${DateFormat('MMM dd, yyyy').format(selectedDate!)}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => selectedDate = date);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              provider.lendItem(
                itemId: item.id,
                itemName: item.name ?? 'Item',
                borrowerName: nameCtrl.text.trim(),
                returnDate: selectedDate,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Marked as lent to ${nameCtrl.text}')));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  );
}
