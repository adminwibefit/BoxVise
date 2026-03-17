import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'create_box_screen.dart';
import 'box_details_screen.dart';
import 'stats_screen.dart';
import 'qr_scanner_screen.dart';
import 'search_screen.dart';
import 'activity_screen.dart';
import 'boxes_screen.dart';
import 'settings_screen.dart';
import 'add_item_screen.dart';
import 'qr_code_screen.dart';
import 'shopping_list_screen.dart';
import 'planner_screen.dart';
import 'travel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          SearchScreen(),
          BoxesScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryColor);
              }
              return TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : Colors.black54);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(size: 24, color: AppTheme.primaryColor);
              }
              return IconThemeData(size: 22, color: isDark ? Colors.white54 : Colors.black54);
            }),
          ),
          child: NavigationBar(
            height: 75,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0D1829) : Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_rounded),
                label: provider.translate('Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_rounded),
                label: provider.translate('Search'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.inventory_2_rounded),
                label: provider.translate('Boxes'),
              ),
            ],
          ),
        );
      },
    );
  }

}

// ── Top-level helpers ─────────────────────────────────────────────────────────

void _showGeneratedQRs(BuildContext context, InventoryProvider provider) {
  if (provider.boxes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No boxes available.')));
    return;
  }
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Generated Box QRs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.boxes.length,
            itemBuilder: (c, i) {
              final box = provider.boxes[i];
              return ListTile(
                leading: Icon(Icons.qr_code_2_rounded, color: Color(box.colorValue ?? AppTheme.primaryColor.value)),
                title: Text(box.name?.toString() ?? 'Unnamed Box'),
                subtitle: Text(box.uuid ?? 'No UUID'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => QrCodeScreen(box: box)));
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

void _showAddItemListDialog(BuildContext context, InventoryProvider provider) {
  if (provider.boxes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a box first.')));
    return;
  }
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Select a box to add item to', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.boxes.length,
            itemBuilder: (c, i) {
              final box = provider.boxes[i];
              return ListTile(
                leading: Icon(Icons.inventory_2_rounded, color: Color(box.colorValue ?? AppTheme.primaryColor.value)),
                title: Text(box.name?.toString() ?? 'Unnamed Box'),
                subtitle: Text(box.location?.toString() ?? 'Unknown'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddItemScreen(box: box)));
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final recentBoxes = provider.recentBoxes;
        final totalItems = provider.totalItems;
        final totalBoxes = provider.boxes.length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              floating: true,
              snap: true,
              toolbarHeight: 68,
              backgroundColor: isDark ? const Color(0xFF0D1829) : const Color(0xFFF5F6F8),
              surfaceTintColor: Colors.transparent,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/logo.png', width: 34, height: 34, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 9),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.8,
                        color: isDark ? Colors.white : const Color(0xFF0D1829),
                      ),
                      children: const [
                        TextSpan(text: 'BOX'),
                        TextSpan(
                          text: 'VISE',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                _AppBarBtn(
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
                ),
                const SizedBox(width: 8),
                _AppBarBtn(
                  icon: Icons.settings_rounded,
                  filled: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                const SizedBox(width: 16),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Hero Stats Banner ──
                    _HeroBanner(
                      totalBoxes: totalBoxes,
                      totalItems: totalItems,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                    ),
                    const SizedBox(height: 28),

                    // ── Quick Actions ──
                    const _SectionTitle('Quick Actions'),
                    const SizedBox(height: 14),
                    _QuickActionsRow(provider: provider),
                    const SizedBox(height: 28),

                    // ── Recent Boxes ──
                    if (recentBoxes.isNotEmpty) ...[
                      _SectionTitleRow(
                        title: 'Recent Boxes',
                        trailing: 'See All',
                        onTrailing: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoxesScreen())),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: recentBoxes.length > 6 ? 6 : recentBoxes.length,
                          itemBuilder: (_, i) => _RecentBoxCard(box: recentBoxes[i]),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Tools Grid ──
                    const _SectionTitle('Explore'),
                    const SizedBox(height: 14),
                    _ToolsGrid(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      },
    );
  }
}

// ── App Bar Button ────────────────────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _AppBarBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled
              ? AppTheme.primaryColor
              : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: filled
              ? [BoxShadow(color: AppTheme.primaryColor.withAlpha(70), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Icon(icon, size: 20, color: filled ? Colors.white : (isDark ? Colors.white70 : AppTheme.accentColor)),
      ),
    );
  }
}

// ── Hero Stats Banner ─────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final int totalBoxes;
  final int totalItems;
  final VoidCallback onTap;

  const _HeroBanner({required this.totalBoxes, required this.totalItems, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryColor.withAlpha(80), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Your Inventory',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatPill(label: 'Boxes', value: '$totalBoxes'),
                      const SizedBox(width: 12),
                      _StatPill(label: 'Items', value: '$totalItems'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'View full analytics',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Row ─────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final InventoryProvider provider;
  const _QuickActionsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.add_box_rounded, label: 'Create Box', color: AppTheme.accentColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen()))),
      _QuickAction(icon: Icons.add_circle_rounded, label: 'Add Item', color: AppTheme.primaryColor,
          onTap: () => _showAddItemListDialog(context, provider)),
      _QuickAction(icon: Icons.qr_code_scanner_rounded, label: 'Scan QR', color: AppTheme.accentColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()))),
      _QuickAction(icon: Icons.qr_code_2_rounded, label: 'Generate QR', color: AppTheme.primaryColor,
          onTap: () => _showGeneratedQRs(context, provider)),
    ];

    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: actions.indexOf(a) < actions.length - 1 ? 10 : 0),
          child: _QuickActionTile(action: a),
        ),
      )).toList(),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152540) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(10) : action.color.withAlpha(30),
            ),
            boxShadow: [
              BoxShadow(
                color: action.color.withAlpha(isDark ? 8 : 18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Box Card ───────────────────────────────────────────────────────────

class _RecentBoxCard extends StatelessWidget {
  final dynamic box;
  const _RecentBoxCard({required this.box});

  @override
  Widget build(BuildContext context) {
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.read<InventoryProvider>().accessBox(box);
        Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF152540) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(isDark ? 40 : 35)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 15 : 20),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.inventory_2_rounded, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  box.name?.toString() ?? 'Unnamed',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${box.items.length} items',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black38,
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

// ── Tools Grid ────────────────────────────────────────────────────────────────

class _ToolsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolItem(icon: Icons.local_shipping_rounded, label: 'Travel', color: const Color(0xFF2196F3),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelScreen()))),
      _ToolItem(icon: Icons.shopping_cart_rounded, label: 'Shopping', color: AppTheme.warningColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()))),
      _ToolItem(icon: Icons.task_alt_rounded, label: 'Planner', color: AppTheme.successColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen()))),
      _ToolItem(icon: Icons.history_rounded, label: 'Activity', color: const Color(0xFF9C27B0),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: tools.map((t) => _ToolTile(tool: t)).toList(),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolItem({required this.icon, required this.label, required this.color, required this.onTap});
}

class _ToolTile extends StatelessWidget {
  final _ToolItem tool;
  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152540) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withAlpha(10) : tool.color.withAlpha(25)),
            boxShadow: [
              BoxShadow(
                color: tool.color.withAlpha(isDark ? 10 : 20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: tool.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(tool.icon, color: tool.color, size: 22),
              ),
              const SizedBox(height: 9),
              Text(tool.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Helpers ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));
  }
}

class _SectionTitleRow extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;
  const _SectionTitleRow({required this.title, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailing,
            child: Text(trailing!, style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
