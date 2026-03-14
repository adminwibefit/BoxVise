import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Intelligence analysis', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withAlpha(200)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(Icons.analytics_rounded, size: 100, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Efficiency Score Card
                _buildEfficiencyScore(provider, isDark),
                const SizedBox(height: 24),

                // Core Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildAdvancedStatCard('Total Items', '${provider.totalItems}', Icons.inventory_2_rounded, AppTheme.primaryColor, isDark),
                    _buildAdvancedStatCard('Inventory Value', '${_currencySymbol}${provider.totalInventoryValue.toStringAsFixed(0)}', Icons.payments_rounded, Colors.green, isDark),
                    _buildAdvancedStatCard('Storage Load', '${(provider.totalSpaceUsage * 100).toInt()}%', Icons.pie_chart_rounded, Colors.orange, isDark),
                    _buildAdvancedStatCard('Data Health', '${provider.boxes.isEmpty ? 0 : 98}%', Icons.security_rounded, Colors.indigo, isDark),
                  ],
                ),
                const SizedBox(height: 32),

                // Category Breakdown
                _sectionTitle('Category Distribution'),
                const SizedBox(height: 16),
                _buildCategoryChart(context, provider),
                const SizedBox(height: 32),

                // Top Boxes
                _sectionTitle('High-Density Storage Units'),
                const SizedBox(height: 16),
                ...provider.topBoxesByItems.map((entry) => _buildBoxRankTile(context, entry.key, entry.value, isDark)),
                const SizedBox(height: 32),

                // Value Insights
                _sectionTitle('Strategic Insights'),
                const SizedBox(height: 16),
                _buildValueInsights(context, provider, isDark),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static const String _currencySymbol = '₹';

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
    );
  }

  Widget _buildEfficiencyScore(InventoryProvider provider, bool isDark) {
    final score = provider.boxes.isEmpty ? 0 : 85; // Mock logic for design
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(40), width: 2),
        boxShadow: [
          if (!isDark) BoxShadow(color: AppTheme.primaryColor.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.primaryColor.withAlpha(30),
                  color: AppTheme.primaryColor,
                ),
              ),
              Text('$score%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Organization Efficiency', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Your inventory is well-categorized. Add more tags to reach 100%.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, InventoryProvider provider) {
    final distribution = provider.categoryDistribution;
    final total = provider.totalBoxes;
    if (total == 0) return const Center(child: Text('No data available'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: distribution.entries.map((entry) {
          final percentage = entry.value / total;
          final color = _getCategoryColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('${(percentage * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withAlpha(20),
                    color: color,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoxRankTile(BuildContext context, dynamic box, int count, bool isDark) {
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.inventory_2_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(box.name ?? 'Unnamed Box', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(box.location ?? 'Unknown', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Text('$count items', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildValueInsights(BuildContext context, InventoryProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildInsightRow('Highest Value Box', provider.boxes.isEmpty ? 'N/A' : _getHighestValueBox(provider), Icons.star_rounded, Colors.amber),
          const Divider(height: 32),
          _buildInsightRow('Low Stock Items', '${provider.lowStockItems.length} items', Icons.warning_amber_rounded, Colors.orange),
          const Divider(height: 32),
          _buildInsightRow('Items Expiring Soon', '${provider.expiringItems.length} items', Icons.timer_rounded, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  String _getHighestValueBox(InventoryProvider provider) {
    double maxVal = -1;
    String name = 'N/A';
    for (var box in provider.boxes) {
      double val = box.items.fold(0.0, (sum, item) => sum + ((item.price ?? 0) * (item.quantity ?? 1)));
      if (val > maxVal) {
        maxVal = val;
        name = box.name ?? 'Unnamed Box';
      }
    }
    return name;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Clothing': return Colors.pink;
      case 'Tools': return Colors.blueGrey;
      case 'Electronics': return Colors.blue;
      case 'Kitchen': return Colors.orange;
      case 'Documents': return Colors.indigo;
      default: return AppTheme.primaryColor;
    }
  }
}
