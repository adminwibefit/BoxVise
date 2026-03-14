import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'box_details_screen.dart';
import '../models/box_model.dart';
import '../models/item_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  
  // Filters
  final List<String> _selectedTags = [];
  final List<String> _selectedLocations = [];
  String? _selectedBoxId;
  String? _quantityCategory;
  String? _dateFilter;
  String _sortBy = 'name_asc';

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // No initial search, following user preference to remove recommended searches
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch() {
    final provider = context.read<InventoryProvider>();
    setState(() {
      _results = provider.searchItems(
        _searchCtrl.text,
        selectedTags: _selectedTags,
        selectedLocations: _selectedLocations,
        selectedBoxId: _selectedBoxId,
        quantityCategory: _quantityCategory,
        dateFilter: _dateFilter,
        sortBy: _sortBy,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedLocations.clear();
      _selectedBoxId = null;
      _quantityCategory = null;
      _dateFilter = null;
      _sortBy = 'name_asc';
      _performSearch();
    });
  }

  void _toggleLocation(String loc) {
    setState(() {
      if (_selectedLocations.contains(loc)) {
        _selectedLocations.remove(loc);
      } else {
        _selectedLocations.clear(); // User asked for All/Select behavior
        _selectedLocations.add(loc);
      }
      _performSearch();
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchCtrl.text = val.recognizedWords;
            _performSearch();
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<InventoryProvider>();
    final isSearching = _searchCtrl.text.isNotEmpty || _selectedTags.isNotEmpty || _selectedLocations.isNotEmpty || _selectedBoxId != null || _quantityCategory != null || _dateFilter != null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Search', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          actions: [
            IconButton(
              tooltip: 'Advanced Filters',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSearching ? AppTheme.primaryColor.withAlpha(20) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune_rounded, color: isSearching ? AppTheme.primaryColor : null),
              ),
              onPressed: () => _showFilterSheet(context),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SearchBarWidget(
                controller: _searchCtrl,
                hintText: 'Search boxes, items, or tags...',
                onChanged: (_) => _performSearch(),
                onVoiceTap: _listen,
                isListening: _isListening,
              ),
            ),
          ),
        ),
        
        // Location Quick Chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MOST USED LOCATIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.2)),
                    _buildLocationDropdown(provider, isDark),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: provider.locationHeatmap.keys.take(6).map((loc) {
                      final isSelected = _selectedLocations.contains(loc);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(loc),
                          selected: isSelected,
                          onSelected: (_) => _toggleLocation(loc),
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          selectedColor: AppTheme.primaryColor.withAlpha(40),
                          checkmarkColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            fontSize: 13, 
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white70 : Colors.black87)
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(5))),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSortDropdown(isDark),
              ],
            ),
          ),
        ),

        if (!isSearching && _searchCtrl.text.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, size: 80, color: Colors.grey.withAlpha(50)),
                  const SizedBox(height: 24),
                  const Text(
                    'Search Your Inventory',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Type above or use filters to find specific items instantly',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else if (_results.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.withAlpha(80)),
                const SizedBox(height: 24),
                const Text('No Items Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.grey)),
                const SizedBox(height: 12),
                const Text('Try another keyword or filter', style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset All Filters'),
                ),
              ],
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final r = _results[index];
                  final box = r['box'] as BoxModel;
                  final item = r['item'] as ItemModel;
                  final color = Color(box.colorValue ?? 0xFF2563EB);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      onTap: () {
                        context.read<InventoryProvider>().accessBox(box);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BoxDetailsScreen(box: box)));
                      },
                      leading: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Icon(Icons.inventory_2_rounded, color: color, size: 28),
                        ),
                      ),
                      title: Text(item.name ?? 'Unnamed Item', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.move_to_inbox_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 4),
                              Flexible(child: Text(box.name ?? 'Unnamed Box', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 4),
                              Text(box.location ?? 'Home', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _results.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationDropdown(InventoryProvider provider, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (loc) {
        setState(() {
          if (loc == 'ALL') {
            _selectedLocations.clear();
          } else {
            _selectedLocations.clear();
            _selectedLocations.add(loc);
          }
          _performSearch();
        });
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'ALL', child: Text('All Locations')),
        ...provider.allLocations.map((loc) => PopupMenuItem(value: loc, child: Text(loc))),
      ],
      child: Row(
        children: [
          Text(_selectedLocations.isEmpty ? 'All' : _selectedLocations.first, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(bool isDark) {
    final sortNames = {
      'name_asc': 'Name A-Z',
      'name_desc': 'Name Z-A',
      'newest': 'Recently Added',
      'oldest': 'Oldest First',
      'qty_high': 'Quantity High → Low',
      'qty_low': 'Quantity Low → High',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('SORT BY: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
        PopupMenuButton<String>(
          onSelected: (val) {
            setState(() {
              _sortBy = val;
              _performSearch();
            });
          },
          itemBuilder: (ctx) => sortNames.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            child: Row(
              children: [
                Text(sortNames[_sortBy]!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Icon(Icons.sort_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => StatefulBuilder(
          builder: (context, setModalState) {
            final provider = context.watch<InventoryProvider>();
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advanced Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      TextButton(onPressed: () { _clearFilters(); Navigator.pop(ctx); }, child: const Text('Reset All')),
                    ],
                  ),
                  const Divider(height: 32),

                  // Filter by Box
                  _buildFilterHeader('📦 FILTER BY BOX'),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.boxes.length,
                      itemBuilder: (ctx, index) {
                        final box = provider.boxes[index];
                        final isSelected = _selectedBoxId == box.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(box.name ?? ''),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() => _selectedBoxId = val ? box.id : null);
                              setState(() => _selectedBoxId = val ? box.id : null);
                              _performSearch();
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Filter by Tag
                  _buildFilterHeader('🏷 FILTER BY TAG'),
                  Wrap(
                    spacing: 8,
                    children: provider.allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() {
                            if (val) _selectedTags.add(tag);
                            else _selectedTags.remove(tag);
                          });
                          setState(() {
                             if (val) _selectedTags.add(tag);
                             else _selectedTags.remove(tag);
                          });
                          _performSearch();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Filter by Quantity
                  _buildFilterHeader('📊 FILTER BY QUANTITY'),
                  _buildQuantityOption(setModalState, 'Low stock (≤1)', 'low'),
                  _buildQuantityOption(setModalState, 'Out of stock', 'out'),
                  _buildQuantityOption(setModalState, '1-5 items', '1-5'),
                  _buildQuantityOption(setModalState, '5-20 items', '5-20'),
                  _buildQuantityOption(setModalState, '20+ items', '20+'),

                  const SizedBox(height: 24),

                  // Filter by Date
                  _buildFilterHeader('📅 FILTER BY DATE ADDED'),
                  _buildDateOption(setModalState, 'Today', 'today'),
                  _buildDateOption(setModalState, 'Last 7 days', '7days'),
                  _buildDateOption(setModalState, 'Last 30 days', '30days'),
                  _buildDateOption(setModalState, 'Older items', 'older'),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildQuantityOption(StateSetter setModalState, String label, String value) {
    final isSelected = _quantityCategory == value;
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _quantityCategory,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setModalState(() => _quantityCategory = val);
        setState(() => _quantityCategory = val);
        _performSearch();
      },
      controlAffinity: ListTileControlAffinity.trailing,
      toggleable: true,
    );
  }

  Widget _buildDateOption(StateSetter setModalState, String label, String value) {
    final isSelected = _dateFilter == value;
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _dateFilter,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setModalState(() => _dateFilter = val);
        setState(() => _dateFilter = val);
        _performSearch();
      },
      controlAffinity: ListTileControlAffinity.trailing,
      toggleable: true,
    );
  }
}
