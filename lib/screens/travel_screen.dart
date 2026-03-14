import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/box_model.dart';
import '../models/travel_model.dart';
import '../theme/app_theme.dart';
import 'box_details_screen.dart';
import 'qr_scanner_screen.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _nameCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final List<BoxModel> _selectedBoxes = [];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final activeTravel = provider.activeTravel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Box', style: TextStyle(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Start'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStartTab(provider),
          _buildActiveTab(provider, activeTravel),
          _buildHistoryTab(provider),
        ],
      ),
    );
  }

  Widget _buildStartTab(InventoryProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Travel Trip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(_nameCtrl, 'Trip Name', Icons.drive_file_rename_outline_rounded),
          const SizedBox(height: 16),
          _buildTextField(_fromCtrl, 'From Location', Icons.location_on_outlined),
          const SizedBox(height: 16),
          _buildTextField(_toCtrl, 'Destination', Icons.flag_rounded),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Boxes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showBoxPicker(provider),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Select'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedBoxes.isEmpty)
            const Center(child: Text('No boxes selected', style: TextStyle(color: Colors.grey)))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedBoxes.length,
              itemBuilder: (ctx, i) {
                final box = _selectedBoxes[i];
                return ListTile(
                  leading: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor),
                  title: Text(box.name ?? 'Unnamed Box'),
                  subtitle: Text(box.location ?? 'No location'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                    onPressed: () => setState(() => _selectedBoxes.removeAt(i)),
                  ),
                );
              },
            ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                if (_nameCtrl.text.isEmpty || _selectedBoxes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and select boxes')));
                  return;
                }
                provider.startTravel(
                  name: _nameCtrl.text,
                  from: _fromCtrl.text,
                  to: _toCtrl.text,
                  selectedBoxes: _selectedBoxes,
                );
                _nameCtrl.clear();
                _fromCtrl.clear();
                _toCtrl.clear();
                _selectedBoxes.clear();
                _tabController.animateTo(1);
              },
              child: const Text('Start Travel Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(InventoryProvider provider, TravelModel? travel) {
    if (travel == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active travel trip', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Start one from the "Start" tab', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    final loadedCount = travel.itemStatuses.where((s) => s.status == TravelStatus.loaded).length;
    final unloadedCount = travel.itemStatuses.where((s) => s.status == TravelStatus.unloaded).length;
    final total = travel.itemStatuses.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(travel.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('${travel.fromLocation} → ${travel.toLocation}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: const Text('In Progress', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressCard(loadedCount, unloadedCount, total),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _scanToUpdate(provider, travel, TravelStatus.loaded),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan Load', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _scanToUpdate(provider, travel, TravelStatus.unloaded),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan Unload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: travel.itemStatuses.length,
            itemBuilder: (ctx, i) {
              final item = travel.itemStatuses[i];
              return _buildTravelItemTile(provider, travel.id, item);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _confirmEndTravel(provider, travel),
              child: const Text('Complete Trip & Update Locations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int loaded, int unloaded, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(51)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trip Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$unloaded / $total Unloaded', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : unloaded / total,
              backgroundColor: Colors.grey.withAlpha(51),
              color: Colors.green,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _progressStat('Loaded', '$loaded/$total', Colors.orange),
              _progressStat('Unloaded', '$unloaded/$total', Colors.green),
              _progressStat('Missing', '${total - loaded}', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTravelItemTile(InventoryProvider provider, String travelId, TravelItemStatus status) {
    IconData statusIcon;
    Color statusColor;
    switch (status.status) {
      case TravelStatus.pending: statusIcon = Icons.circle_outlined; statusColor = Colors.grey; break;
      case TravelStatus.loaded: statusIcon = Icons.check_circle_rounded; statusColor = Colors.orange; break;
      case TravelStatus.unloaded: statusIcon = Icons.verified_rounded; statusColor = Colors.green; break;
      case TravelStatus.missing: statusIcon = Icons.error_rounded; statusColor = Colors.red; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () => _showManualStatusChange(provider, travelId, status),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
        ),
        title: Text(status.boxName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Status: ${status.status.name.toUpperCase()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
        onTap: () {
          final box = provider.boxes.firstWhereOrNull((b) => b.id == status.boxId);
          if (box != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
          }
        },
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            switch (val) {
              case 'details':
                final box = provider.boxes.firstWhereOrNull((b) => b.id == status.boxId);
                if (box != null) Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
                break;
              case 'remove':
                provider.removeFromTravel(travelId, status.boxId);
                break;
              case 'missing':
                provider.updateTravelStatus(travelId, status.boxId, TravelStatus.missing);
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.info_outline, size: 18), SizedBox(width: 8), Text('View Box Details')])),
            const PopupMenuItem(value: 'remove', child: Row(children: [Icon(Icons.remove_circle_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Remove From Trip', style: TextStyle(color: Colors.red))])),
            const PopupMenuItem(value: 'missing', child: Row(children: [Icon(Icons.report_problem_outlined, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Report Missing', style: TextStyle(color: Colors.orange))])),
          ],
        ),
      ),
    );
  }

  void _showManualStatusChange(InventoryProvider provider, String travelId, TravelItemStatus status) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update Box Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: const Text('Mark as Pending'),
              onTap: () { provider.updateTravelStatus(travelId, status.boxId, TravelStatus.pending); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded, color: Colors.orange),
              title: const Text('Mark as Loaded'),
              onTap: () { provider.updateTravelStatus(travelId, status.boxId, TravelStatus.loaded); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.verified_rounded, color: Colors.green),
              title: const Text('Mark as Unloaded'),
              onTap: () { provider.updateTravelStatus(travelId, status.boxId, TravelStatus.unloaded); Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.error_rounded, color: Colors.red),
              title: const Text('Mark as Missing'),
              onTap: () { provider.updateTravelStatus(travelId, status.boxId, TravelStatus.missing); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHistoryTab(InventoryProvider provider) {
    final history = provider.travelLogs.where((t) => t.isCompleted).toList();
    if (history.isEmpty) {
      return const Center(child: Text('No travel history', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final travel = history[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(travel.name),
            subtitle: Text('${travel.fromLocation} → ${travel.toLocation}\n${travel.timestamp.toString().split('.')[0]}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showSummary(travel),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
      ),
    );
  }

  void _scanToUpdate(InventoryProvider provider, TravelModel travel, TravelStatus status) async {
    final uuid = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen(returnMode: true)),
    );

    if (uuid != null) {
      final box = provider.findBoxByUuid(uuid);
      if (box != null) {
        if (travel.itemStatuses.any((s) => s.boxId == box.id)) {
          provider.updateTravelStatus(travel.id, box.id, status);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${box.name} marked as ${status.name}')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This box is not part of this travel trip')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanned box not found in inventory')));
        }
      }
    }
  }
  void _showBoxPicker(InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Pick Boxes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.boxes.length,
                  itemBuilder: (ctx2, i) {
                    final box = provider.boxes[i];
                    final isSelected = _selectedBoxes.any((b) => b.id == box.id);
                    return CheckboxListTile(
                      title: Text(box.name ?? 'Unnamed Box'),
                      subtitle: Text(box.location ?? ''),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) _selectedBoxes.add(box);
                          else _selectedBoxes.removeWhere((b) => b.id == box.id);
                        });
                        Navigator.pop(ctx);
                        _showBoxPicker(provider);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmEndTravel(InventoryProvider provider, TravelModel travel) {
    final unloadedCount = travel.itemStatuses.where((s) => s.status == TravelStatus.unloaded).length;
    final totalCount = travel.itemStatuses.length;
    final missingCount = totalCount - unloadedCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(missingCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded, 
                 color: missingCount > 0 ? Colors.orange : Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text('Complete Trip?', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trip Summary', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _summaryRow('Boxes Unloaded', '$unloadedCount / $totalCount', Colors.green),
            if (missingCount > 0)
              _summaryRow('Boxes Missing/Loaded', '$missingCount', Colors.red),
            const Divider(height: 24),
            Text(
              missingCount > 0 
                ? 'Warning: $missingCount boxes are not marked as "Unloaded". Their locations will NOT be updated.' 
                : 'All box locations will be updated to "${travel.toLocation}".',
              style: TextStyle(fontSize: 13, color: missingCount > 0 ? Colors.red : Colors.grey),
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
                    backgroundColor: missingCount > 0 ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    provider.endTravel(travel.id);
                    Navigator.pop(ctx);
                    _showFinalResults(context, travel, unloadedCount, missingCount);
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

  void _showFinalResults(BuildContext context, TravelModel travel, int unloaded, int missing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Trip Completed', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text('Congratulations! Your trip "${travel.name}" is finished.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Boxes'), Text('${travel.itemStatuses.length}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Moved Successfully'), Text('$unloaded', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                  if (missing > 0) ...[
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Unaccounted'), Text('$missing', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Inventory locations have been updated.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
    final unloaded = travel.itemStatuses.where((s) => s.status == TravelStatus.unloaded).length;
    final missing = travel.itemStatuses.where((s) => s.status == TravelStatus.missing).length;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(travel.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${travel.fromLocation} → ${travel.toLocation}', style: const TextStyle(color: Colors.grey)),
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
