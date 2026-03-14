import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Consumer<InventoryProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear List',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear List?'),
                    content: const Text('This will remove all manually added items.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          provider.clearShoppingList();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareShoppingList(context),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final lowStockItems = provider.lowStockItems;
          final manualItems = provider.manualShoppingList;
          
          if (lowStockItems.isEmpty && manualItems.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                icon: Icons.shopping_basket_outlined,
                title: 'Your list is empty',
                subtitle: 'Low stock items or manually added items will appear here.',
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have ${lowStockItems.length + manualItems.length} items to shop.',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (manualItems.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('MANUALLY ADDED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                      ),
                      ...manualItems.map((entry) {
                        final box = entry['box'];
                        final item = entry['item'];
                        return _buildItemTile(context, provider, box, item, isManual: true);
                      }),
                    ],
                    if (lowStockItems.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('LOW STOCK ALERTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                      ),
                      ...lowStockItems.map((entry) {
                        final box = entry['box'];
                        final item = entry['item'];
                        return _buildItemTile(context, provider, box, item, isManual: false);
                      }),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _shareShoppingList(context),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share Shopping List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, InventoryProvider provider, dynamic box, dynamic item, {required bool isManual}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isManual ? AppTheme.primaryColor.withAlpha(30) : Colors.orangeAccent.withAlpha(30)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isManual ? AppTheme.primaryColor : Colors.orangeAccent).withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            item != null ? Icons.category_rounded : Icons.inventory_2_rounded,
            color: isManual ? AppTheme.primaryColor : Colors.orangeAccent,
            size: 20
          ),
        ),
        title: Text(
          item != null ? item.name : (box.name ?? 'Unknown Box'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)
        ),
        subtitle: Text(
          item != null ? 'In: ${box.name} • ${box.location}' : 'Location: ${box.location}',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)
        ),
        trailing: isManual 
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: () => provider.removeFromShoppingList(box.id, item?.id),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item != null) Text('Qty: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.errorColor)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                  onPressed: () {
                    if (item != null) provider.incrementQuantity(box, item);
                  },
                ),
              ],
            ),
      ),
    );
  }

  void _shareShoppingList(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final lowStock = provider.lowStockItems;
    final manual = provider.manualShoppingList;
    
    if (lowStock.isEmpty && manual.isEmpty) return;

    String list = "📦 Boxvise Shopping List:\n\n";
    
    if (manual.isNotEmpty) {
      list += "[ Manual List ]\n";
      for (var i in manual) {
        final box = i['box'];
        final item = i['item'];
        list += "• ${item != null ? item.name : box.name} (Location: ${box.location})\n";
      }
      list += "\n";
    }

    if (lowStock.isNotEmpty) {
      list += "[ Low Stock Alerts ]\n";
      for (var i in lowStock) {
        list += "• ${i['item'].name} (Qty: ${i['item'].quantity} in ${i['box'].name})\n";
      }
    }
    
    Share.share(list);
  }
}
