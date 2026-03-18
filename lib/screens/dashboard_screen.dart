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
import 'qr_sheet_screen.dart';
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF152540) : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Select a box to add item', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('or scan a box QR code', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 12),
        // Scan QR button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryColor.withAlpha(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Scan Box QR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or pick a box', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
              ),
              Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.boxes.length,
            itemBuilder: (c, i) {
              final box = provider.boxes[i];
              final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.inventory_2_rounded, color: color, size: 20),
                ),
                title: Text(box.name?.toString() ?? 'Unnamed Box', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(box.location?.toString() ?? 'Unknown', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                trailing: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white24 : Colors.black26),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final recentBoxes = provider.recentBoxes;
        final totalItems = provider.totalItems;
        final totalBoxes = provider.boxes.length;
        final isEmpty = totalBoxes == 0;

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
                        TextSpan(text: 'VISE', style: TextStyle(color: AppTheme.primaryColor)),
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

                    // ── Empty State ──
                    if (isEmpty) ...[
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Let\'s organize your stuff!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 20),
                      _EmptyStateBanner(
                        onCreateBox: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateBoxScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Hero Banner with Stats (when has boxes) ──
                    if (!isEmpty) ...[
                      _HeroBanner(
                        greeting: _getGreeting(),
                        totalBoxes: totalBoxes,
                        totalItems: totalItems,
                        onAnalytics: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
                        onCreateBox: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Quick Actions ──
                    const _SectionTitle('Quick Actions'),
                    const SizedBox(height: 14),
                    _QuickActionsGrid(provider: provider),
                    const SizedBox(height: 24),

                    // ── Recent Boxes ──
                    if (recentBoxes.isNotEmpty) ...[
                      _SectionTitleRow(
                        title: 'Recent Boxes',
                        trailing: 'See All',
                        onTrailing: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoxesScreen())),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: recentBoxes.length > 6 ? 6 : recentBoxes.length,
                          itemBuilder: (_, i) => _RecentBoxCard(box: recentBoxes[i]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Tools ──
                    const _SectionTitle('Tools'),
                    const SizedBox(height: 14),
                    _ToolsList(),
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

// ── Hero Banner (has data) ────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String greeting;
  final int totalBoxes;
  final int totalItems;
  final VoidCallback onAnalytics;
  final VoidCallback onCreateBox;

  const _HeroBanner({
    required this.greeting,
    required this.totalBoxes,
    required this.totalItems,
    required this.onAnalytics,
    required this.onCreateBox,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          BoxShadow(color: AppTheme.primaryColor.withAlpha(80), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(12)),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(8)),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(6)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your Inventory',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onAnalytics,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Stats row
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.inventory_2_rounded,
                      value: '$totalBoxes',
                      label: totalBoxes == 1 ? 'Box' : 'Boxes',
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.category_rounded,
                      value: '$totalItems',
                      label: totalItems == 1 ? 'Item' : 'Items',
                    ),
                    const Spacer(),
                    // Add box button
                    GestureDetector(
                      onTap: onCreateBox,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: AppTheme.primaryDark, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'New Box',
                              style: TextStyle(color: AppTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 15),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.0),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Empty State Banner ────────────────────────────────────────────────────────

class _EmptyStateBanner extends StatelessWidget {
  final VoidCallback onCreateBox;

  const _EmptyStateBanner({required this.onCreateBox});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2D4A), const Color(0xFF152540)]
              : [AppTheme.primaryColor.withAlpha(10), AppTheme.accentColor.withAlpha(8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : AppTheme.primaryColor.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start by creating your first box',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a box for each storage container,\nthen add items inside.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black45,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onCreateBox,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Your First Box', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid (2x2) ──────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final InventoryProvider provider;
  const _QuickActionsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hasBoxes = provider.boxes.isNotEmpty;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_box_rounded,
                label: 'Create Box',
                subtitle: 'New container',
                color: AppTheme.primaryColor,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBoxScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_rounded,
                label: 'Add Item',
                subtitle: hasBoxes ? 'To a box' : 'Create a box first',
                color: AppTheme.accentColor,
                onTap: hasBoxes ? () => _showAddItemListDialog(context, provider) : null,
                disabled: !hasBoxes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                subtitle: 'Find a box',
                color: const Color(0xFF7C4DFF),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.qr_code_2_rounded,
                label: 'All QRs',
                subtitle: 'View & print',
                color: Colors.teal,
                onTap: hasBoxes ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrSheetScreen())) : null,
                disabled: !hasBoxes,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = disabled ? Colors.grey.shade400 : color;

    return Opacity(
      opacity: disabled ? 0.7 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF152540) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: effectiveColor.withAlpha(isDark ? 30 : 25)),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(color: effectiveColor.withAlpha(isDark ? 8 : 15), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: effectiveColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white24 : Colors.black26),
              ],
            ),
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
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF152540) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(isDark ? 40 : 35)),
          boxShadow: [
            BoxShadow(color: color.withAlpha(isDark ? 15 : 20), blurRadius: 14, offset: const Offset(0, 5)),
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
              child: Icon(Icons.inventory_2_rounded, color: color, size: 20),
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

// ── Tools List (horizontal scrollable) ────────────────────────────────────────

class _ToolsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tools = [
      _ToolItem(icon: Icons.local_shipping_rounded, label: 'Travel', desc: 'Packing lists', color: const Color(0xFF2196F3),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelScreen()))),
      _ToolItem(icon: Icons.shopping_cart_rounded, label: 'Shopping', desc: 'Shopping lists', color: AppTheme.warningColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen()))),
      _ToolItem(icon: Icons.task_alt_rounded, label: 'Planner', desc: 'Task planning', color: AppTheme.successColor,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen()))),
      _ToolItem(icon: Icons.history_rounded, label: 'Activity', desc: 'Recent actions', color: const Color(0xFF9C27B0),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ToolCard(tool: tools[i], isDark: isDark),
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  const _ToolItem({required this.icon, required this.label, required this.desc, required this.color, required this.onTap});
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  final bool isDark;
  const _ToolCard({required this.tool, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152540) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tool.color.withAlpha(isDark ? 25 : 20)),
            boxShadow: [
              BoxShadow(color: tool.color.withAlpha(isDark ? 8 : 12), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: tool.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tool.icon, color: tool.color, size: 18),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? Colors.white24 : Colors.black26),
                ],
              ),
              const SizedBox(height: 10),
              Text(tool.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(
                tool.desc,
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
              ),
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
