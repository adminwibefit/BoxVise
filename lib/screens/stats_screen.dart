import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  int _touchedPieIndex = -1;
  int _activityDays = 7; // 7, 30, or 90

  // Build activity spots from real createdDate data
  List<FlSpot> _buildActivitySpots(InventoryProvider provider) {
    final now = DateTime.now();
    final counts = List<double>.filled(_activityDays, 0.0);
    for (final box in provider.boxes) {
      final diff = now.difference(box.createdDate).inDays;
      if (diff >= 0 && diff < _activityDays) counts[_activityDays - 1 - diff] += 1;
      for (final item in box.items) {
        final d = now.difference(item.createdDate).inDays;
        if (d >= 0 && d < _activityDays) counts[_activityDays - 1 - d] += 1;
      }
    }
    return counts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF152540) : Colors.white;
    final scaffold = isDark ? const Color(0xFF0D1829) : const Color(0xFFF5F6F8);

    final spots = _buildActivitySpots(provider);
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final hasActivity = spots.any((s) => s.y > 0);
    final dist = provider.categoryDistribution;
    final locHeatmap = provider.locationHeatmap;
    final lowStock = provider.lowStockItems;
    final expiring = provider.expiringItems;
    final topBoxes = provider.topBoxesByItems;
    final totalItems = provider.totalItems;

    return Scaffold(
      backgroundColor: scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: scaffold,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Insights',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Summary Cards ─────────────────────────────────────────
                _SummaryGrid(
                  boxes: provider.totalBoxes,
                  items: provider.totalItems,
                  value: provider.totalInventoryValue,
                  categories: provider.totalCategories,
                  isDark: isDark,
                  bg: bg,
                ),
                const SizedBox(height: 28),

                // ── Alerts ────────────────────────────────────────────────
                if (lowStock.isNotEmpty || expiring.isNotEmpty) ...[
                  _SectionHeader('Alerts',
                      badge: (lowStock.length + expiring.length).toString(),
                      badgeColor: AppTheme.errorColor),
                  const SizedBox(height: 14),
                  if (expiring.isNotEmpty)
                    _AlertBanner(
                      icon: Icons.timer_rounded,
                      color: AppTheme.warningColor,
                      title: '${expiring.length} item${expiring.length > 1 ? 's' : ''} expiring soon',
                      subtitle: expiring.map((e) => e['item'].name ?? '').take(2).join(', '),
                      isDark: isDark,
                    ),
                  if (expiring.isNotEmpty && lowStock.isNotEmpty) const SizedBox(height: 8),
                  if (lowStock.isNotEmpty)
                    _AlertBanner(
                      icon: Icons.inventory_rounded,
                      color: AppTheme.errorColor,
                      title: '${lowStock.length} low-stock item${lowStock.length > 1 ? 's' : ''}',
                      subtitle: lowStock.map((e) => e['item'].name ?? '').take(2).join(', '),
                      isDark: isDark,
                    ),
                  const SizedBox(height: 28),
                ],

                // ── Activity Chart ────────────────────────────────────────
                _SectionHeader('Activity'),
                const SizedBox(height: 14),
                Container(
                  decoration: _cardDecoration(isDark, bg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Added Over Time',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  'Boxes + Items combined',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
                                ),
                              ],
                            ),
                            _PeriodToggle(
                              selected: _activityDays,
                              onSelect: (d) => setState(() => _activityDays = d),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
                          child: hasActivity
                              ? LineChart(LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: maxY > 0 ? (maxY / 3).ceilToDouble() : 1,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(10),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: (_activityDays / 6).ceilToDouble(),
                                        reservedSize: 22,
                                        getTitlesWidget: (value, _) {
                                          final daysAgo = _activityDays - 1 - value.toInt();
                                          if (daysAgo == 0) return _axisLabel('Today');
                                          if (daysAgo % (_activityDays ~/ 4).clamp(1, 99) != 0 && daysAgo != _activityDays - 1) {
                                            return const SizedBox.shrink();
                                          }
                                          return _axisLabel('${daysAgo}d');
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: maxY > 0 ? (maxY / 3).ceilToDouble() : 1,
                                        getTitlesWidget: (v, _) => _axisLabel('${v.toInt()}'),
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      curveSmoothness: 0.4,
                                      color: AppTheme.primaryColor,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, _, __, ___) {
                                          if (spot.y == 0) return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0, strokeColor: Colors.transparent);
                                          return FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppTheme.primaryColor);
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [AppTheme.primaryColor.withAlpha(45), AppTheme.primaryColor.withAlpha(0)],
                                        ),
                                      ),
                                    ),
                                  ],
                                  minY: 0,
                                  maxY: (maxY + 1).ceilToDouble(),
                                ))
                              : _EmptyChart(isDark: isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Category Distribution ─────────────────────────────────
                if (dist.isNotEmpty) ...[
                  _SectionHeader('Category Breakdown'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(isDark, bg),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: PieChart(PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (event, res) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions || res == null || res.touchedSection == null) {
                                          _touchedPieIndex = -1;
                                          return;
                                        }
                                        _touchedPieIndex = res.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 44,
                                  sections: dist.entries.toList().asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final cat = entry.value;
                                    final isTouched = i == _touchedPieIndex;
                                    final color = _catColor(cat.key, i);
                                    return PieChartSectionData(
                                      color: color,
                                      value: cat.value.toDouble(),
                                      title: isTouched ? '${cat.value}' : '',
                                      radius: isTouched ? 62.0 : 52.0,
                                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                                      borderSide: isTouched ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                                    );
                                  }).toList(),
                                )),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: dist.entries.toList().asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final cat = entry.value;
                                    final color = _catColor(cat.key, i);
                                    final pct = totalItems == 0 ? 0 : ((cat.value / provider.totalBoxes) * 100).round();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(cat.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                                Text('${cat.value} box${cat.value > 1 ? 'es' : ''}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Top Boxes ─────────────────────────────────────────────
                if (topBoxes.isNotEmpty) ...[
                  _SectionHeader('Busiest Boxes'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(isDark, bg),
                    child: Column(
                      children: topBoxes.asMap().entries.map((entry) {
                        final i = entry.key;
                        final box = entry.value.key;
                        final count = entry.value.value;
                        final maxCount = topBoxes.first.value;
                        final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
                        final pct = maxCount == 0 ? 0.0 : count / maxCount;
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < topBoxes.length - 1 ? 16 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
                                    child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(box.name ?? 'Unnamed', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                                    child: Text('$count item${count != 1 ? 's' : ''}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 7,
                                  backgroundColor: color.withAlpha(isDark ? 25 : 20),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Location Heatmap ──────────────────────────────────────
                if (locHeatmap.isNotEmpty) ...[
                  _SectionHeader('By Location'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(isDark, bg),
                    child: Column(
                      children: () {
                        final sorted = locHeatmap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                        final maxVal = sorted.first.value;
                        return sorted.asMap().entries.map((entry) {
                          final i = entry.key;
                          final loc = entry.value;
                          final pct = maxVal == 0 ? 0.0 : loc.value / maxVal;
                          final colors = [AppTheme.primaryColor, AppTheme.accentColor, const Color(0xFF00BCD4), const Color(0xFF9C27B0)];
                          final color = colors[i % colors.length];
                          return Padding(
                            padding: EdgeInsets.only(bottom: i < sorted.length - 1 ? 16 : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: color),
                                      const SizedBox(width: 6),
                                      Text(loc.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                    ]),
                                    Text('${loc.value} box${loc.value > 1 ? 'es' : ''}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 7,
                                    backgroundColor: color.withAlpha(isDark ? 25 : 18),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      }(),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Empty State ───────────────────────────────────────────
                if (provider.totalBoxes == 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 64, color: AppTheme.primaryColor.withAlpha(80)),
                          const SizedBox(height: 16),
                          Text('No data yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : Colors.black38)),
                          const SizedBox(height: 6),
                          Text('Create some boxes to see insights', style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : Colors.black26)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _axisLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.withAlpha(150)));
  }

  BoxDecoration _cardDecoration(bool isDark, Color bg) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
      boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 20, offset: const Offset(0, 4))],
    );
  }

  Color _catColor(String cat, int index) {
    final palette = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      const Color(0xFF00BCD4),
      const Color(0xFF9C27B0),
      const Color(0xFF4CAF50),
      const Color(0xFFFF5722),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];
    switch (cat) {
      case 'Clothing':    return const Color(0xFFEC407A);
      case 'Tools':       return const Color(0xFF607D8B);
      case 'Electronics': return const Color(0xFF2196F3);
      case 'Kitchen':     return const Color(0xFFFF9800);
      case 'Documents':   return const Color(0xFF5C6BC0);
      case 'Books':       return const Color(0xFF8BC34A);
      case 'Sports':      return const Color(0xFF00BCD4);
      default:            return palette[index % palette.length];
    }
  }
}

// ── Summary Grid ──────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  final int boxes, items, categories;
  final double value;
  final bool isDark;
  final Color bg;

  const _SummaryGrid({
    required this.boxes, required this.items, required this.value,
    required this.categories, required this.isDark, required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _NumCard(label: 'Boxes', value: '$boxes', icon: Icons.inventory_2_rounded, color: AppTheme.primaryColor, isDark: isDark, bg: bg)),
          const SizedBox(width: 12),
          Expanded(child: _NumCard(label: 'Items', value: '$items', icon: Icons.category_rounded, color: AppTheme.accentColor, isDark: isDark, bg: bg)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _NumCard(label: 'Value', value: '₹${value.toStringAsFixed(0)}', icon: Icons.payments_rounded, color: AppTheme.successColor, isDark: isDark, bg: bg)),
          const SizedBox(width: 12),
          Expanded(child: _NumCard(label: 'Categories', value: '$categories', icon: Icons.label_rounded, color: const Color(0xFF9C27B0), isDark: isDark, bg: bg)),
        ]),
      ],
    );
  }
}

class _NumCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color bg;

  const _NumCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withAlpha(10) : color.withAlpha(20)),
        boxShadow: isDark ? null : [BoxShadow(color: color.withAlpha(18), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.0)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final Color? badgeColor;

  const _SectionHeader(this.title, {this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppTheme.primaryColor).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor ?? AppTheme.primaryColor)),
          ),
        ],
      ],
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool isDark;

  const _AlertBanner({required this.icon, required this.color, required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period Toggle ─────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _PeriodToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 30, 90].map((d) {
          final active = selected == d;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                d == 7 ? '7D' : d == 30 ? '30D' : '90D',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty Chart ───────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  final bool isDark;
  const _EmptyChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart_rounded, size: 40, color: isDark ? Colors.white.withAlpha(40) : Colors.black.withAlpha(30)),
          const SizedBox(height: 8),
          Text('No activity yet', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}
