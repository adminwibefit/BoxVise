import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/box_model.dart';
import '../models/item_model.dart';
import '../models/travel_model.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TRAVEL SCREEN  (tabs: Start / Active / History)
// ─────────────────────────────────────────────────────────────────────────────
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1829) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor:
                isDark ? const Color(0xFF0D1829) : const Color(0xFFF8FAFC),
            elevation: 0,
            title: const Text(
              'Travel',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(
                    text: 'Start',
                    icon: Icon(Icons.flight_takeoff_rounded, size: 20)),
                Tab(
                    text: 'Active',
                    icon: Icon(Icons.local_shipping_rounded, size: 20)),
                Tab(
                    text: 'History',
                    icon: Icon(Icons.history_rounded, size: 20)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStartTab(isDark),
            _buildActiveTab(provider, provider.activeTravel, isDark),
            _buildHistoryTab(provider, isDark),
          ],
        ),
      ),
    );
  }

  // ── START TAB ──────────────────────────────────────────────────────────────
  Widget _buildStartTab(bool isDark) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Travel Trip',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your trip details to get started',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 24),

            // ── Fields card ────────────────────────────────────────────────
            _fieldCard(isDark, [
              _formField(
                ctrl: _nameCtrl,
                hint: 'Trip Name',
                icon: Icons.drive_file_rename_outline_rounded,
                isDark: isDark,
                required: true,
              ),
              _divider(isDark),
              _formField(
                ctrl: _fromCtrl,
                hint: 'From',
                icon: Icons.my_location_rounded,
                isDark: isDark,
                required: true,
              ),
              _divider(isDark),
              _formField(
                ctrl: _toCtrl,
                hint: 'To',
                icon: Icons.location_on_rounded,
                isDark: isDark,
                required: true,
              ),
              _divider(isDark),
              _formField(
                ctrl: _notesCtrl,
                hint: 'Notes (optional)',
                icon: Icons.notes_rounded,
                isDark: isDark,
                required: false,
              ),
            ]),

            const SizedBox(height: 32),

            // ── Next button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripBagsScreen(
                        tripName: _nameCtrl.text.trim(),
                        from: _fromCtrl.text.trim(),
                        to: _toCtrl.text.trim(),
                        notes: _notesCtrl.text.trim().isEmpty
                            ? null
                            : _notesCtrl.text.trim(),
                        onTripStarted: () {
                          _nameCtrl.clear();
                          _fromCtrl.clear();
                          _toCtrl.clear();
                          _notesCtrl.clear();
                          _tabController.animateTo(1);
                        },
                      ),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152540) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 40,
                    offset: const Offset(0, 10))
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _formField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    required bool isDark,
    required bool required,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? '$hint is required' : null
          : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38, fontSize: 15),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        errorStyle: const TextStyle(height: 0.8, fontSize: 11),
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
      ),
      style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
      );

  // ── ACTIVE TAB ─────────────────────────────────────────────────────────────
  Widget _buildActiveTab(
      InventoryProvider provider, TravelModel? travel, bool isDark) {
    if (travel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 64, color: Colors.grey.withAlpha(80)),
            const SizedBox(height: 16),
            const Text('No active trip',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            const Text('Start one from the Start tab',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    final bg = isDark ? const Color(0xFF152540) : Colors.white;
    final verifiedCount =
        travel.itemStatuses.where((s) => s.status == TravelStatus.unloaded).length;
    final total = travel.itemStatuses.length;
    final allDone = verifiedCount == total && total > 0;
    final progress = total == 0 ? 0.0 : verifiedCount / total;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(travel.tripName,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: allDone
                                  ? Colors.green.withAlpha(20)
                                  : Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              allDone ? 'Ready' : 'In Progress',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: allDone ? Colors.green : Colors.orange),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle,
                              size: 6,
                              color: isDark
                                  ? Colors.white30
                                  : Colors.black26),
                          const SizedBox(width: 8),
                          Text(travel.fromLocation,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.white30
                                    : Colors.black26),
                          ),
                          Text(travel.toLocation,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Progress card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: allDone
                                        ? Colors.green
                                        : Colors.orange),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                allDone
                                    ? 'All Boxes Verified'
                                    : 'Verification',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (allDone
                                      ? Colors.green
                                      : AppTheme.primaryColor)
                                  .withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: allDone
                                      ? Colors.green
                                      : AppTheme.primaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(8)
                              : Colors.black.withAlpha(6),
                          color: allDone ? Colors.green : AppTheme.primaryColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$verifiedCount/$total',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: allDone
                              ? null
                              : () => _scanToUpdate(
                                  provider, travel, TravelStatus.unloaded),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allDone
                                ? Colors.green.withAlpha(15)
                                : AppTheme.primaryColor,
                            foregroundColor:
                                allDone ? Colors.green : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  allDone
                                      ? Icons.check_circle_rounded
                                      : Icons.qr_code_scanner_rounded,
                                  size: 20),
                              const SizedBox(width: 10),
                              Text(
                                allDone
                                    ? 'All Verified'
                                    : 'Scan QR to Verify',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Boxes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final item = travel.itemStatuses[i];
                final boxModel =
                    provider.boxes.cast<BoxModel?>().firstWhere((b) => b?.id == item.boxId, orElse: () => null);
                return _buildTravelBoxTile(
                    provider, travel.id, item, boxModel, isDark);
              },
              childCount: travel.itemStatuses.length,
            ),
          ),
        ),

        SliverPadding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allDone
                      ? Colors.green
                      : (isDark
                          ? Colors.white.withAlpha(8)
                          : Colors.black.withAlpha(6)),
                  foregroundColor: allDone
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black26),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed:
                    allDone ? () => _confirmEndTravel(provider, travel) : null,
                icon: Icon(
                    allDone
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    size: 20),
                label: Text(
                  allDone ? 'Finish & Archive Trip' : 'Verify All to Finish',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelBoxTile(InventoryProvider provider, String travelId,
      TravelItemStatus status, BoxModel? box, bool isDark) {
    final unloadedItems = status.itemStatuses
        .where((s) => s.status == TravelStatus.unloaded)
        .length;
    final totalItems = status.itemStatuses.length;

    TravelStatus visualStatus = status.status;
    if (totalItems > 0 && unloadedItems == totalItems) {
      visualStatus = TravelStatus.unloaded;
    }

    IconData statusIcon;
    Color statusColor;
    switch (visualStatus) {
      case TravelStatus.pending:
        statusIcon = Icons.circle_outlined;
        statusColor = Colors.grey;
        break;
      case TravelStatus.loaded:
        statusIcon = Icons.check_circle_rounded;
        statusColor = Colors.orange;
        break;
      case TravelStatus.unloaded:
        statusIcon = Icons.verified_rounded;
        statusColor = Colors.green;
        break;
      case TravelStatus.missing:
        statusIcon = Icons.error_rounded;
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withAlpha(50)),
      ),
      elevation: 0,
      color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () =>
              _showManualStatusChange(provider, travelId, status),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: statusColor.withAlpha(25), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
        ),
        title: Text(
          (box?.name != null && box!.name!.trim().isNotEmpty)
              ? box.name!.trim()
              : (status.boxName.trim().isNotEmpty
                  ? status.boxName.trim()
                  : 'Box ${status.boxId.length > 4 ? status.boxId.substring(status.boxId.length - 4) : status.boxId}'),
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black),
        ),
        subtitle: Text(
          'Status: ${visualStatus.name.toUpperCase()} • $totalItems Items',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor),
        ),
        trailing: const Icon(Icons.expand_more_rounded),
        children: [
          ...status.itemStatuses.map((itemDetail) {
            final itemStat = itemDetail.status;
            Color itemColor;
            IconData itemIcon;
            switch (itemStat) {
              case TravelStatus.pending:
                itemIcon = Icons.circle_outlined;
                itemColor = Colors.grey;
                break;
              case TravelStatus.loaded:
                itemIcon = Icons.check_circle_rounded;
                itemColor = Colors.orange;
                break;
              case TravelStatus.unloaded:
                itemIcon = Icons.verified_rounded;
                itemColor = Colors.green;
                break;
              case TravelStatus.missing:
                itemIcon = Icons.error_rounded;
                itemColor = Colors.red;
                break;
            }
            return ListTile(
              dense: true,
              leading: const SizedBox(width: 40),
              title: Text(itemDetail.name,
                  style: TextStyle(
                      decoration: itemStat == TravelStatus.unloaded
                          ? TextDecoration.lineThrough
                          : null)),
              trailing: PopupMenuButton<TravelStatus>(
                icon: Icon(itemIcon, color: itemColor, size: 20),
                onSelected: (val) => provider.updateTravelItemStatus(
                    travelId, status.boxId, itemDetail.id, val),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                      value: TravelStatus.pending, child: Text('Pending')),
                  PopupMenuItem(
                      value: TravelStatus.unloaded,
                      child: Text('Unloaded')),
                  PopupMenuItem(
                      value: TravelStatus.missing,
                      child: Text('Missing',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
              onTap: () {
                final next = itemStat == TravelStatus.pending
                    ? TravelStatus.unloaded
                    : TravelStatus.pending;
                provider.updateTravelItemStatus(
                    travelId, status.boxId, itemDetail.id, next);
              },
            );
          }),
          if (status.itemStatuses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No items in this box.',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  void _showManualStatusChange(InventoryProvider provider, String travelId,
      TravelItemStatus status) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Box Status',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: const Text('Mark as Pending'),
              onTap: () {
                provider.updateTravelStatus(
                    travelId, status.boxId, TravelStatus.pending);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.verified_rounded, color: Colors.green),
              title: const Text('Mark as Unloaded (Verified)'),
              onTap: () {
                provider.updateTravelStatus(
                    travelId, status.boxId, TravelStatus.unloaded);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.error_rounded, color: Colors.red),
              title: const Text('Mark as Missing'),
              onTap: () {
                provider.updateTravelStatus(
                    travelId, status.boxId, TravelStatus.missing);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── HISTORY TAB ────────────────────────────────────────────────────────────
  Widget _buildHistoryTab(InventoryProvider provider, bool isDark) {
    final history =
        provider.travelLogs.where((t) => t.isCompleted).toList();
    if (history.isEmpty) {
      return const Center(
        child: Text('No travel history',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final travel = history[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(travel.tripName),
            subtitle: Text(
                '${travel.fromLocation} → ${travel.toLocation}\n${travel.startTime.toString().split('.')[0]}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showSummary(travel),
          ),
        );
      },
    );
  }

  // ── Scan helpers ───────────────────────────────────────────────────────────
  void _scanToUpdate(InventoryProvider provider, TravelModel travel,
      TravelStatus status) async {
    final uuid = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const QrScannerScreen(returnMode: true)),
    );
    if (uuid != null && mounted) {
      final box = provider.findBoxByUuid(uuid);
      if (box != null) {
        if (travel.itemStatuses.any((s) => s.boxId == box.id)) {
          provider.updateTravelStatus(travel.id, box.id, status);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${box.name} marked as ${status.name}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('This box is not part of this travel trip')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Scanned box not found in inventory')));
      }
    }
  }

  // ── End trip dialogs ───────────────────────────────────────────────────────
  void _confirmEndTravel(InventoryProvider provider, TravelModel travel) {
    final unloadedCount = travel.itemStatuses
        .where((s) => s.status == TravelStatus.unloaded)
        .length;
    final totalCount = travel.itemStatuses.length;
    final missingCount = totalCount - unloadedCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
                missingCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: missingCount > 0 ? Colors.orange : Colors.green,
                size: 48),
            const SizedBox(height: 12),
            const Text('Complete Trip?', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trip Summary',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _summaryRow(
                'Boxes Unloaded', '$unloadedCount / $totalCount', Colors.green),
            if (missingCount > 0)
              _summaryRow(
                  'Boxes Missing/Loaded', '$missingCount', Colors.red),
            const Divider(height: 24),
            Text(
              missingCount > 0
                  ? 'Warning: $missingCount boxes are not marked as "Unloaded". Are you sure you want to finish the trip?'
                  : 'All boxes unloaded successfully.',
              style: TextStyle(
                  fontSize: 13,
                  color: missingCount > 0 ? Colors.red : Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Wait, Go Back'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        missingCount > 0 ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    provider.endTravel(travel.id);
                    Navigator.pop(ctx);
                    _showFinalResults(
                        context, travel, unloadedCount, missingCount);
                  },
                  child: const Text('Finish Trip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFinalResults(BuildContext context, TravelModel travel,
      int unloaded, int missing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Trip Completed',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded,
                color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
                'Congratulations! Your trip "${travel.tripName}" is finished.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Boxes'),
                        Text('${travel.itemStatuses.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Moved Successfully'),
                        Text('$unloaded',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green))
                      ]),
                  if (missing > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Unaccounted'),
                          Text('$missing',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red))
                        ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your trip has been recorded in the history tab.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Great!'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSummary(TravelModel travel) {
    final unloaded = travel.itemStatuses
        .where((s) => s.status == TravelStatus.unloaded)
        .length;
    final missing = travel.itemStatuses
        .where((s) => s.status == TravelStatus.missing)
        .length;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(travel.tripName,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${travel.fromLocation} → ${travel.toLocation}',
                style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _summaryRow('Boxes Planned', '${travel.itemStatuses.length}'),
            _summaryRow('Boxes Unloaded', '$unloaded', Colors.green),
            _summaryRow('Boxes Missing', '$missing', Colors.red),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIP BAGS SCREEN  (step 2 of creating a trip)
// ─────────────────────────────────────────────────────────────────────────────
class TripBagsScreen extends StatefulWidget {
  final String tripName;
  final String from;
  final String to;
  final String? notes;
  final VoidCallback onTripStarted;

  const TripBagsScreen({
    super.key,
    required this.tripName,
    required this.from,
    required this.to,
    this.notes,
    required this.onTripStarted,
  });

  @override
  State<TripBagsScreen> createState() => _TripBagsScreenState();
}

class _TripBagsScreenState extends State<TripBagsScreen> {
  final List<BoxModel> _bags = [];
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtered bags based on search ──────────────────────────────────────────
  List<BoxModel> get _filtered {
    if (_query.isEmpty) return _bags;
    return _bags.where((bag) {
      if ((bag.name ?? '').toLowerCase().contains(_query)) return true;
      return bag.items
          .any((item) => (item.name ?? '').toLowerCase().contains(_query));
    }).toList();
  }

  // ── Download QR PDF ────────────────────────────────────────────────────────
  Future<void> _downloadQrPdf() async {
    if (_bags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one bag first')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating QR PDF…'), duration: Duration(seconds: 2)),
    );

    try {
      final pdf = pw.Document();
      const cols = 3;
      const perPage = 12;

      for (int start = 0; start < _bags.length; start += perPage) {
        final pageBags = _bags.skip(start).take(perPage).toList();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Trip: ${widget.tripName} — Bag QR Codes',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${widget.from} → ${widget.to}  •  Generated ${DateTime.now().toLocal().toString().substring(0, 16)}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 16),
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: cols,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: List.generate(pageBags.length, (i) {
                      final bag = pageBags[i];
                      final qrData = bag.customQrData ?? 'Boxvise:${bag.uuid ?? bag.id}';
                      final shortId = bag.id.length > 10
                          ? bag.id.substring(bag.id.length - 10).toUpperCase()
                          : bag.id.toUpperCase();

                      return pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              bag.name ?? 'Unnamed Bag',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                            ),
                            pw.SizedBox(height: 6),
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: qrData,
                              width: 90,
                              height: 90,
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              shortId,
                              style: const pw.TextStyle(
                                  fontSize: 7, color: PdfColors.grey700),
                              textAlign: pw.TextAlign.center,
                            ),
                            if ((bag.location ?? '').isNotEmpty)
                              pw.Text(
                                bag.location!,
                                style: const pw.TextStyle(
                                    fontSize: 7, color: PdfColors.grey500),
                                textAlign: pw.TextAlign.center,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/Trip_${widget.tripName}_QR_Codes.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)],
          text: '${widget.tripName} — Bag QR Codes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF error: $e')));
      }
    }
  }

  // ── Add bag — push full Create Bag screen ──────────────────────────────────
  void _addBag() async {
    final bag = await Navigator.push<BoxModel>(
      context,
      MaterialPageRoute(builder: (_) => const _CreateBagScreen()),
    );
    if (bag != null) {
      setState(() => _bags.add(bag));
    }
  }

  // ── Add item to bag dialog ─────────────────────────────────────────────────
  void _addItem(BoxModel bag) {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF152540) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Item to ${bag.name}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Press enter to quickly add multiple items',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Item name (e.g. Plates)',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withAlpha(8)
                    : Colors.black.withAlpha(5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() {
                    bag.items.add(ItemModel(
                      id: 'TEMP_ITEM_${DateTime.now().millisecondsSinceEpoch}',
                      name: val.trim(),
                      quantity: 1,
                      tags: [],
                    ));
                  });
                  ctrl.clear();
                  // Re-open for fast multi-add
                  Navigator.pop(ctx);
                  _addItem(bag);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        setState(() {
                          bag.items.add(ItemModel(
                            id: 'TEMP_ITEM_${DateTime.now().millisecondsSinceEpoch}',
                            name: ctrl.text.trim(),
                            quantity: 1,
                            tags: [],
                          ));
                        });
                        Navigator.pop(ctx);
                        _addItem(bag);
                      }
                    },
                    child: const Text('Add Item',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Show bag QR ────────────────────────────────────────────────────────────
  void _showBagQr(BoxModel bag) {
    final qrData =
        bag.customQrData ?? 'Boxvise:${bag.uuid ?? bag.id}';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(bag.name ?? 'Bag QR', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                  data: qrData, version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 12),
            const Text(
              'Scan to track this bag during the trip',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'))
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1829) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0D1829) : const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tripName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              '${widget.from} → ${widget.to}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            onSelected: (val) {
              if (val == 'download_qr') _downloadQrPdf();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'download_qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Download QRs',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF152540) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(8)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search bags and items…',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18,
                              color:
                                  isDark ? Colors.white54 : Colors.black45),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 14),
                ),
              ),
            ),
          ),

          // ── Add Bag row ─────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _bags.isEmpty
                      ? 'No bags yet'
                      : '${_bags.length} bag${_bags.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45),
                ),
                TextButton.icon(
                  onPressed: _addBag,
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  label: const Text('Add Bag',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // ── Bags list ───────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.luggage_rounded,
                            size: 56,
                            color: Colors.grey.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'No results for "$_query"'
                              : 'Add bags to pack for your trip',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final bag = filtered[i];
                      return _buildBagTile(bag, isDark);
                    },
                  ),
          ),
        ],
      ),

      // ── Start Travel Mode button ────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _bags.isEmpty
                  ? null
                  : () {
                      provider.startTravel(
                        name: widget.tripName,
                        from: widget.from,
                        to: widget.to,
                        selectedBoxes: _bags,
                        notes: widget.notes,
                      );
                      widget.onTripStarted();
                      Navigator.pop(context);
                    },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight_takeoff_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Start Travel Mode',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBagTile(BoxModel bag, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(10)
                : Colors.black.withAlpha(8)),
      ),
      elevation: 0,
      color: isDark ? const Color(0xFF152540) : Colors.white,
      child: ExpansionTile(
        shape: const Border(),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.luggage_rounded,
              color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          bag.name ?? 'Unnamed Bag',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black),
        ),
        subtitle: Text(
          '${bag.items.length} item${bag.items.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.qr_code_2_rounded,
                  size: 22,
                  color: isDark ? Colors.white54 : Colors.black45),
              onPressed: () => _showBagQr(bag),
              tooltip: 'View QR',
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
              onPressed: () =>
                  setState(() => _bags.remove(bag)),
              tooltip: 'Remove bag',
            ),
          ],
        ),
        children: [
          // Items list
          ...bag.items.map((item) => ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.only(left: 72, right: 8),
                leading: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.grey, shape: BoxShape.circle),
                ),
                title: Text(item.name ?? '',
                    style: const TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey),
                  onPressed: () =>
                      setState(() => bag.items.remove(item)),
                ),
              )),

          // Add item button
          Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: TextButton.icon(
              onPressed: () => _addItem(bag),
              icon: const Icon(Icons.add_circle_outline_rounded,
                  size: 18, color: AppTheme.primaryColor),
              label: const Text('Add Item',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE BAG SCREEN  (mirrors CreateBoxScreen design, returns a BoxModel)
// ─────────────────────────────────────────────────────────────────────────────
class _CreateBagScreen extends StatefulWidget {
  const _CreateBagScreen();

  @override
  State<_CreateBagScreen> createState() => _CreateBagScreenState();
}

class _CreateBagScreenState extends State<_CreateBagScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '0');

  String _selectedCategory = 'Other';
  String _qrMode = 'generate';
  String? _customQrData;
  bool _qrError = false;

  late int _colorIndex;
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  final List<String> _categories = [
    'Clothing', 'Tools', 'Documents', 'Kitchen', 'Electronics', 'Books', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _colorIndex = Random().nextInt(AppTheme.boxColors.length);
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BagQrScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() { _customQrData = result; _qrError = false; });
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('QR captured: ${raw.length > 30 ? '${raw.substring(0, 30)}…' : raw}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No QR code found in image'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_qrMode == 'custom' && _customQrData == null) {
      setState(() => _qrError = true);
      return;
    }

    final id = 'TEMP_BAG_${DateTime.now().millisecondsSinceEpoch}';
    final bag = BoxModel(
      id: id,
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty ? 'In Transit' : _locationCtrl.text.trim(),
      colorValue: AppTheme.boxColors[_colorIndex].toARGB32(),
      category: _selectedCategory,
      capacity: int.tryParse(_capacityCtrl.text) ?? 0,
      customQrData: _qrMode == 'custom' ? _customQrData : null,
      createdDate: DateTime.now(),
      items: [],
    );
    Navigator.pop(context, bag);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppTheme.boxColors[_colorIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bag',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _anim,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(_anim),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Preview card ───────────────────────────────────────
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
                        border: Border.all(
                            color: selectedColor.withAlpha(77), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: selectedColor.withAlpha(64),
                              blurRadius: 30,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.luggage_rounded,
                              size: 48, color: selectedColor),
                          const SizedBox(height: 8),
                          Text(
                            _nameCtrl.text.isEmpty
                                ? 'New Bag'
                                : _nameCtrl.text,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Bag Name ───────────────────────────────────────────
                  const Text('Bag Name',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Kitchen Bag',
                      prefixIcon: Icon(Icons.luggage_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a bag name'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // ── Location ───────────────────────────────────────────
                  const Text('Location (Hierarchy)',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'e.g. House > Bedroom > Closet',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Capacity + Category ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Capacity (Max Items)',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _capacityCtrl,
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
                            const Text('Category',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.category_outlined),
                              ),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                      value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) => setState(
                                  () => _selectedCategory = v ?? 'Other'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── QR Code ────────────────────────────────────────────
                  const Text('QR Code',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _qrMode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'generate', child: Text('Generate QR')),
                      DropdownMenuItem(
                          value: 'custom', child: Text('Custom QR')),
                    ],
                    onChanged: (v) => setState(() {
                      _qrMode = v ?? 'generate';
                      if (_qrMode == 'generate') _customQrData = null;
                    }),
                  ),

                  if (_qrMode == 'custom') ...[
                    const SizedBox(height: 16),
                    if (_customQrData != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'QR: ${_customQrData!.length > 36 ? '${_customQrData!.substring(0, 36)}…' : _customQrData!}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _customQrData = null),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(child: _qrButton(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Scan QR',
                          color: AppTheme.primaryColor,
                          isDark: isDark,
                          hasError: _qrError,
                          onTap: _scanQr,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _qrButton(
                          icon: Icons.upload_rounded,
                          label: 'Upload QR',
                          color: AppTheme.accentColor,
                          isDark: isDark,
                          hasError: _qrError,
                          onTap: _uploadQr,
                        )),
                      ],
                    ),
                    if (_qrError) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            'Please scan or upload a QR code',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(height: 40),

                  // ── Add Bag button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedColor,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 24),
                          SizedBox(width: 8),
                          Text('Add Bag',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
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

  Widget _qrButton({
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
          color: hasError
              ? Colors.red.withAlpha(10)
              : color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: hasError
                  ? Colors.red.withAlpha(100)
                  : color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BAG QR SCANNER  (accepts any QR value)
// ─────────────────────────────────────────────────────────────────────────────
class _BagQrScannerScreen extends StatefulWidget {
  const _BagQrScannerScreen();

  @override
  State<_BagQrScannerScreen> createState() => _BagQrScannerScreenState();
}

class _BagQrScannerScreenState extends State<_BagQrScannerScreen> {
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
          MobileScanner(controller: _controller, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _btn(Icons.arrow_back_rounded,
                      () => Navigator.pop(context)),
                  _btn(Icons.flash_on_rounded,
                      () => _controller.toggleTorch()),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                    Colors.black,
                  ],
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
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text('Scan Custom QR Code',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Point at any QR code to use it\nas this bag\'s identifier',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 14,
                        height: 1.4),
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
