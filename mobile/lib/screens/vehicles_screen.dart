import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/vehicle_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/vehicle_location_map.dart';

/// Module-level currency symbol for [_fmtMoney]; set from [DashboardProvider]
/// in [_VehiclesScreenState.initState].
String _currencySymbol = 'KSh';

/// Vehicles screen — mirrors the web `pages/app/vehicles/index.vue`.
///
/// Tabbed hub for fleet management:
///  1. Overview     — analytics KPIs + breakdowns
///  2. Vehicles     — searchable/filterable card list with swipe actions
///  3. Fleet Health  — health score, inspection, maintenance ratios
///  4. Utilization   — rental utilization, revenue trend, top vehicles
///  5. Analytics     — cost analysis, ABC, type/location analysis
///  6. Catalog       — makes/body-types/models
///  7. Groups        — fleet groups
///  8. Vehicle Types — categories
///  9. Locations     — fleet locations
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.directions_car_outlined, size: 18), text: 'Vehicles'),
    Tab(icon: Icon(Icons.health_and_safety_outlined, size: 18), text: 'Health'),
    Tab(icon: Icon(Icons.insights_outlined, size: 18), text: 'Utilization'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Analytics'),
    Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Catalog'),
    Tab(icon: Icon(Icons.folder_outlined, size: 18), text: 'Groups'),
    Tab(icon: Icon(Icons.category_outlined, size: 18), text: 'Types'),
    Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Locations'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {}); // rebuild so the FAB updates for the active tab
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DashboardProvider>();
      _currencySymbol = dp.currencySymbol;
      final p = context.read<VehiclesProvider>();
      p.refresh();
      p.loadSupportingData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Vehicles'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
          tabAlignment: TabAlignment.start,
          labelColor: DomendraTheme.primary,
          unselectedLabelColor: DomendraTheme.onSurfaceMuted,
          indicatorColor: DomendraTheme.primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/app/vehicles'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _VehiclesTab(scrollController: _scrollController),
          _FleetHealthTab(),
          _UtilizationTab(),
          _AnalyticsTab(),
          _CatalogTab(),
          _GroupsTab(),
          _VehicleTypesTab(),
          _LocationsTab(),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    final index = _tabController.index;
    // Tabs 5–8: Catalog, Groups, Types, Locations → show add dialog for that entity
    switch (index) {
      case 5: // Catalog (uses sub-tabs internally, so we show a generic catalog dialog)
        return FloatingActionButton(
          heroTag: 'fab_catalog',
          onPressed: () => _showCatalogAddDialog(context),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 6: // Groups
        return FloatingActionButton(
          heroTag: 'fab_groups',
          onPressed: () => _showAddGroupDialog(context),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 7: // Vehicle Types
        return FloatingActionButton(
          heroTag: 'fab_types',
          onPressed: () => _showAddVehicleTypeDialog(context),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 8: // Locations
        return FloatingActionButton(
          heroTag: 'fab_locations',
          onPressed: () => _showAddLocationDialog(context),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      default:
        // Tabs 0–4: Overview, Vehicles, Health, Utilization, Analytics → add vehicle
        return FloatingActionButton(
          heroTag: 'fab_vehicle',
          onPressed: () => Navigator.pushNamed(context, '/app/vehicles/new'),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
    }
  }

  // ── Add dialogs for Catalog / Groups / Types / Locations ───

  void _showCatalogAddDialog(BuildContext context) {
    // The catalog tab has 3 sub-tabs. Show a chooser dialog.
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Add to Catalog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ListTile(leading: const Icon(Icons.directions_car), title: const Text('Add Make'), onTap: () { Navigator.pop(ctx); _showAddMakeDialog(context); }),
            ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Add Body Type'), onTap: () { Navigator.pop(ctx); _showAddBodyTypeDialog(context); }),
            ListTile(leading: const Icon(Icons.format_list_bulleted), title: const Text('Add Model'), onTap: () { Navigator.pop(ctx); _showAddModelDialog(context); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddMakeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Add Make'),
            content: TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Make Name', hintText: 'e.g. Toyota'), textCapitalization: TextCapitalization.words),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDialog(() => saving = true);
                  try {
                    final p = context.read<VehiclesProvider>();
                    await p.api.createMake({'name': nameCtrl.text.trim()});
                    if (context.mounted) Navigator.pop(ctx);
                    p.loadSupportingData();
                  } catch (e) {
                    if (context.mounted) {
                      setDialog(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddBodyTypeDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: 'mdi-car');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Add Body Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Label', hintText: 'e.g. Sedan'), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icon', hintText: 'mdi-car', helperText: 'Material Design Icon name')),
              ],
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  final label = labelCtrl.text.trim();
                  if (label.isEmpty) return;
                  setDialog(() => saving = true);
                  try {
                    final p = context.read<VehiclesProvider>();
                    final value = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
                    await p.api.createBodyType({'label': label, 'value': value, 'icon': iconCtrl.text.trim()});
                    if (context.mounted) Navigator.pop(ctx);
                    p.loadSupportingData();
                  } catch (e) {
                    if (context.mounted) {
                      setDialog(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddModelDialog(BuildContext context) {
    final p = context.read<VehiclesProvider>();
    final nameCtrl = TextEditingController();
    int? makeId;
    int? bodyTypeId;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Add Model'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: makeId,
                  decoration: const InputDecoration(labelText: 'Make'),
                  items: p.makes.map<DropdownMenuItem<int>>((m) {
                    final id = (m as Map<String, dynamic>)['id'] as int?;
                    final name = m['name']?.toString() ?? '';
                    return DropdownMenuItem<int>(value: id, child: Text(name));
                  }).toList(),
                  onChanged: (v) => setDialog(() => makeId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: bodyTypeId,
                  decoration: const InputDecoration(labelText: 'Body Type'),
                  items: p.bodyTypes.map<DropdownMenuItem<int>>((m) {
                    final id = (m as Map<String, dynamic>)['id'] as int?;
                    final label = m['label']?.toString() ?? '';
                    return DropdownMenuItem<int>(value: id, child: Text(label));
                  }).toList(),
                  onChanged: (v) => setDialog(() => bodyTypeId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Model Name', hintText: 'e.g. Corolla'), textCapitalization: TextCapitalization.words),
              ],
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty || makeId == null || bodyTypeId == null) return;
                  setDialog(() => saving = true);
                  try {
                    final vp = context.read<VehiclesProvider>();
                    await vp.api.createModel({'make': makeId, 'body_type': bodyTypeId, 'name': nameCtrl.text.trim()});
                    if (context.mounted) Navigator.pop(ctx);
                    vp.loadSupportingData();
                  } catch (e) {
                    if (context.mounted) {
                      setDialog(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String color = '#6366f1';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Add Vehicle Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Group Name', hintText: 'e.g. Delivery'), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Color:', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    for (final c in const ['#6366f1', '#22c55e', '#f59e0b', '#ef4444', '#ec4899', '#06b6d4', '#64748b'])
                      GestureDetector(
                        onTap: () => setDialog(() => color = c),
                        child: Container(
                          width: 28, height: 28, margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: _parseColor(c), shape: BoxShape.circle, border: Border.all(color: color == c ? Colors.black87 : Colors.transparent, width: 2)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDialog(() => saving = true);
                  try {
                    final p = context.read<VehiclesProvider>();
                    await p.api.createGroup({'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'color': color});
                    if (context.mounted) Navigator.pop(ctx);
                    p.loadSupportingData();
                  } catch (e) {
                    if (context.mounted) {
                      setDialog(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddVehicleTypeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final iconCtrl = TextEditingController(text: 'mdi-car');
    final paxCtrl = TextEditingController(text: '0');
    final cargoCtrl = TextEditingController(text: '0');
    final sortCtrl = TextEditingController(text: '0');
    String color = '#6366f1';
    bool isActive = true;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Add Vehicle Type'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. SUV'), textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 8),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: paxCtrl, decoration: const InputDecoration(labelText: 'Passengers'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: cargoCtrl, decoration: const InputDecoration(labelText: 'Cargo (kg)'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: sortCtrl, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Color:', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        for (final c in const ['#6366f1', '#22c55e', '#f59e0b', '#ef4444', '#ec4899', '#06b6d4', '#64748b'])
                          GestureDetector(
                            onTap: () => setDialog(() => color = c),
                            child: Container(
                              width: 26, height: 26, margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(color: _parseColor(c), shape: BoxShape.circle, border: Border.all(color: color == c ? Colors.black87 : Colors.transparent, width: 2)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setDialog(() => isActive = v),
                      title: const Text('Active', style: TextStyle(fontSize: 13)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDialog(() => saving = true);
                  try {
                    final p = context.read<VehiclesProvider>();
                    await p.api.createVehicleType({
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'icon': iconCtrl.text.trim(),
                      'color': color,
                      'passenger_capacity': int.tryParse(paxCtrl.text) ?? 0,
                      'cargo_capacity_kg': double.tryParse(cargoCtrl.text) ?? 0,
                      'sort_order': int.tryParse(sortCtrl.text) ?? 0,
                      'is_active': isActive,
                    });
                    if (context.mounted) Navigator.pop(ctx);
                    p.loadSupportingData();
                  } catch (e) {
                    if (context.mounted) {
                      setDialog(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    const typeOptions = <String>['depot', 'fuel_station', 'charging_station', 'warehouse', 'customer_site', 'service_center', 'parking_lot', 'rest_stop', 'office', 'hq', 'maintenance_bay', 'other'];
    String type = 'depot';
    String color = '#6366f1';
    bool isActive = true;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: const Text('Add Location'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Location Name', hintText: 'e.g. Main Depot'), textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: typeOptions.map<DropdownMenuItem<String>>((t) => DropdownMenuItem(value: t, child: Text(t.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')))).toList(),
                      onChanged: (v) { if (v != null) setDialog(() => type = v); },
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                    const SizedBox(height: 8),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Color:', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        for (final c in const ['#6366f1', '#22c55e', '#f59e0b', '#ef4444', '#ec4899', '#06b6d4', '#64748b'])
                          GestureDetector(
                            onTap: () => setDialog(() => color = c),
                            child: Container(
                              width: 26, height: 26, margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(color: _parseColor(c), shape: BoxShape.circle, border: Border.all(color: color == c ? Colors.black87 : Colors.transparent, width: 2)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (v) => setDialog(() => isActive = v),
                      title: const Text('Active', style: TextStyle(fontSize: 13)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setDialog(() => saving = true);
                  try {
                    final p = context.read<VehiclesProvider>();
                    await p.api.createLocation({
                      'name': nameCtrl.text.trim(),
                      'type': type,
                      'address': addressCtrl.text.trim(),
                      'notes': notesCtrl.text.trim(),
                      'color': color,
                      'is_active': isActive,
                    });
                    if (context.mounted) Navigator.pop(ctx);
                    p.loadSupportingData();
                  } catch (e) {
                    if (context.mounted) {
                      setDialog(() => saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// 1. OVERVIEW TAB
// ════════════════════════════════════════════════════════════
class _OverviewTab extends StatefulWidget {
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _datePreset = 'all';

  static const _presets = [
    ('month', 'This Month'),
    ('quarter', 'This Quarter'),
    ('year', 'This Year'),
    ('12m', 'Last 12 Months'),
    ('all', 'All Time'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAnalytics());
  }

  void _fetchAnalytics() {
    final (start, end) = _dateRange(_datePreset);
    context.read<VehiclesProvider>().refreshAnalytics(revStart: start, revEnd: end);
  }

  static (String, String) _dateRange(String key) {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final end = fmt(now);
    switch (key) {
      case 'month':
        return (fmt(DateTime(now.year, now.month, 1)), end);
      case 'quarter':
        return (fmt(DateTime(now.year, (now.month ~/ 3) * 3, 1)), end);
      case 'year':
        return (fmt(DateTime(now.year, 1, 1)), end);
      case '12m':
        final d = DateTime(now.year, now.month - 12, now.day);
        return (fmt(d), end);
      default:
        return ('', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();

    return RefreshIndicator(
      onRefresh: () => p.refreshAnalytics(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Date preset chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (key, label) = _presets[i];
                final selected = _datePreset == key;
                return FilterChip(
                  label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : DomendraTheme.onSurfaceMuted)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _datePreset = key);
                    _fetchAnalytics();
                  },
                  selectedColor: DomendraTheme.primary,
                  backgroundColor: DomendraTheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          if (p.analyticsLoading && p.analytics == null)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else if (p.analytics == null)
            _AnalyticsEmptyState(onRetry: _fetchAnalytics)
          else ...[
            // ── KPI StatCards ──────────────────────────
            _OverviewKpiRow(data: p.analytics!),
            const SizedBox(height: 16),

            // ── Mini charts: Acquisition Trend + Revenue Trend ──
            _AcquisitionTrendCard(data: p.analytics!),
            const SizedBox(height: 16),
            _OverviewRevenueTrendCard(data: p.analytics!),
            const SizedBox(height: 16),

            // ── Analytics charts (Fuel Type, Vehicle Type, Top Makes) ──
            _FuelTypeBreakdownCard(data: p.analytics!),
            const SizedBox(height: 16),
            _VehicleTypeDistCard(data: p.analytics!),
            const SizedBox(height: 16),
            _TopMakesCard(data: p.analytics!),
            const SizedBox(height: 16),

            // ── Fleet Health + Fleet Composition ───────
            _OverviewHealthComposition(data: p.analytics!),
            const SizedBox(height: 16),

            // ── Utilization and Revenue ────────────────
            _OverviewUtilizationCard(data: p.analytics!),
            const SizedBox(height: 16),

            // ── More analytics charts ──
            _RevenueByTypeCard(data: p.analytics!),
            const SizedBox(height: 16),
            _ServiceByTypeCard(data: p.analytics!),
            const SizedBox(height: 16),

            // ── Attention grid ─────────────────────────
            _OverviewAttentionCard(data: p.analytics!),
            const SizedBox(height: 16),

            // ── Recent vehicles ───────────────────────
            _RecentVehiclesCard(),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. VEHICLES TAB (main list + search + filters)
// ════════════════════════════════════════════════════════════
class _VehiclesTab extends StatelessWidget {
  final ScrollController scrollController;
  const _VehiclesTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final list = p.filtered;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: p.setSearch,
            decoration: InputDecoration(
              hintText: 'Search vehicles...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: p.search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => p.setSearch(''))
                  : null,
              isDense: true,
            ),
          ),
        ),
        // Filter chips row
        _FilterBar(),
        // Vehicle count + sort
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${list.length} vehicle${list.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted),
              ),
              const Spacer(),
              if (p.hasActiveFilters)
                TextButton(
                  onPressed: p.clearFilters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.refresh,
            child: p.loading && p.vehicles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : p.error != null && p.vehicles.isEmpty
                    ? _ErrorState(error: p.error!, onRetry: p.refresh)
                    : list.isEmpty
                        ? _EmptyState(onAdd: () => Navigator.pushNamed(context, '/app/vehicles/new'))
                        : CustomScrollView(
                            controller: scrollController,
                            slivers: [
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _VehicleCard(vehicle: list[i]),
                                  childCount: list.length,
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
                                  child: _VehiclesTabMap(vehicles: p.vehicles, locations: p.locations),
                                ),
                              ),
                            ],
                          ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Filter bar
// ════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterChip(
            label: 'Status',
            value: p.statusFilter,
            options: const [
              ('active', 'Active'),
              ('out_of_service', 'Out of Service'),
              ('in_maintenance', 'In Maintenance'),
              ('retired', 'Retired'),
            ],
            onSelect: p.setStatusFilter,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Fuel',
            value: p.fuelFilter,
            options: fuelTypes.map((f) => (f, f)).toList(),
            onSelect: p.setFuelFilter,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Group',
            value: p.groupFilter,
            options: p.groups.map((g) {
              final m = g as Map<String, dynamic>;
              return (m['id']?.toString() ?? '', m['name']?.toString() ?? '');
            }).toList(),
            onSelect: p.setGroupFilter,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Location',
            value: p.locationFilter,
            options: p.locations.map((l) {
              final m = l as Map<String, dynamic>;
              return (m['name']?.toString() ?? '', m['name']?.toString() ?? 'Unknown');
            }).toList(),
            onSelect: p.setLocationFilter,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Rental',
            value: p.rentalFilter,
            options: const [('on_rent', 'Assigned'), ('available', 'Available')],
            onSelect: p.setRentalFilter,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onSelect;

  const _FilterChip({required this.label, required this.value, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return ActionChip(
      label: Text(
        hasValue ? options.where((o) => o.$1 == value).first.$2 : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: hasValue ? Colors.white : DomendraTheme.onSurfaceMuted,
        ),
      ),
      avatar: hasValue ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      onPressed: () => _showOptions(context),
      backgroundColor: hasValue ? DomendraTheme.primary : DomendraTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Filter by $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('All'),
                onTap: () {
                  onSelect(null);
                  Navigator.pop(ctx);
                },
              ),
              ...options.map((o) => ListTile(
                    leading: Icon(o.$1 == value ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 20, color: DomendraTheme.primary),
                    title: Text(o.$2),
                    onTap: () {
                      onSelect(o.$1);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Vehicle Card
// ════════════════════════════════════════════════════════════
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(vehicle.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: DomendraTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: DomendraTheme.danger),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: DomendraTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.edit, color: DomendraTheme.primary),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          Navigator.pushNamed(context, '/app/vehicles/${vehicle.id}/edit');
          return false;
        }
        // Delete
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Vehicle'),
            content: Text('Are you sure you want to delete "${vehicle.displayName}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd && vehicle.id != null) {
          await context.read<VehiclesProvider>().deleteVehicle(vehicle.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle deleted'), backgroundColor: DomendraTheme.danger),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/app/vehicles/${vehicle.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DomendraTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DomendraTheme.outline),
          ),
          child: Column(
            children: [
              // Top row
              Row(
                children: [
                  // Vehicle avatar (image or icon)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: vehicle.hasImage
                        ? Image.network(
                            vehicle.image,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _VehicleIconPlaceholder(vehicle: vehicle),
                          )
                        : _VehicleIconPlaceholder(vehicle: vehicle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.displayName.isNotEmpty ? vehicle.displayName : 'Unknown Vehicle',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface),
                        ),
                        if (vehicle.vin.isNotEmpty)
                          Text(
                            'VIN: ${vehicle.vin}',
                            style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _StatusChip(status: vehicle.status),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Detail pills
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (vehicle.licensePlate.isNotEmpty)
                    _DetailPill(icon: Icons.tag, label: vehicle.licensePlate),
                  if (vehicle.fuelType.isNotEmpty)
                    _DetailPill(icon: Icons.local_gas_station_outlined, label: vehicle.fuelType),
                  if (vehicle.currentMileage > 0)
                    _DetailPill(icon: Icons.speed, label: '${_fmtNum(vehicle.currentMileage)} ${vehicle.mileageUnit}'),
                  if (vehicle.ownership == VehicleOwnership.lease)
                    _DetailPill(icon: Icons.handshake_outlined, label: 'Leased'),
                ],
              ),
              // Rental status row
              if (vehicle.rentalStatus != RentalStatus.none) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (vehicle.rentalStatus == RentalStatus.assigned ? DomendraTheme.info : DomendraTheme.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vehicle.rentalStatus == RentalStatus.assigned ? Icons.assignment : Icons.check_circle,
                        size: 14,
                        color: vehicle.rentalStatus == RentalStatus.assigned ? DomendraTheme.info : DomendraTheme.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicle.rentalCustomerName.isNotEmpty
                            ? '${vehicle.rentalStatus.label}: ${vehicle.rentalCustomerName}'
                            : vehicle.rentalStatus.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: vehicle.rentalStatus == RentalStatus.assigned ? DomendraTheme.info : DomendraTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Lease countdown
              if (vehicle.ownership == VehicleOwnership.lease && vehicle.leaseDaysLeft != null) ...[
                const SizedBox(height: 6),
                _LeaseCountdown(daysLeft: vehicle.leaseDaysLeft!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _VehicleIconPlaceholder extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleIconPlaceholder({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: DomendraTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        vehicle.isElectric ? Icons.electric_car : Icons.directions_car,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Lease countdown widget
// ════════════════════════════════════════════════════════════
class _LeaseCountdown extends StatelessWidget {
  final int daysLeft;
  const _LeaseCountdown({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final isExpired = daysLeft < 0;
    final isWarning = daysLeft >= 0 && daysLeft <= 30;
    final color = isExpired ? DomendraTheme.danger : (isWarning ? DomendraTheme.warning : DomendraTheme.success);
    final abs = daysLeft.abs();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          isExpired ? 'Expired ${abs}d ago' : '${abs}d left',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2b. MAP TAB — fleet location map
// ════════════════════════════════════════════════════════════
class _VehiclesTabMap extends StatelessWidget {
  final List<Vehicle> vehicles;
  final List<dynamic> locations;

  const _VehiclesTabMap({required this.vehicles, required this.locations});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Fleet Location Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: VehicleLocationMap(
              vehicles: vehicles,
              locations: locations,
              onVehicleSelected: (v) {
                if (v.id != null) Navigator.pushNamed(context, '/app/vehicles/${v.id}');
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. FLEET HEALTH TAB
// ════════════════════════════════════════════════════════════
class _FleetHealthTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final a = p.analytics;

    if (a == null && !p.analyticsLoading) {
      return _AnalyticsEmptyState(onRetry: () => p.refreshAnalytics());
    }
    if (p.analyticsLoading && a == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final health = _readMap(a, 'fleet_health');
    final score = _readDouble(health, 'fleet_health_score') ?? 0;
    final healthColor = score >= 75 ? DomendraTheme.success : (score >= 50 ? DomendraTheme.warning : DomendraTheme.danger);
    final inspectionRate = _readDouble(health, 'inspection_pass_rate') ?? 0;
    final passCount = _readInt(health, 'pass_count') ?? 0;
    final failCount = _readInt(health, 'fail_count') ?? 0;
    final maintenancePct = _readDouble(health, 'maintenance_pct') ?? 0;
    final oosPct = _readDouble(health, 'out_of_service_pct') ?? 0;
    final totalInspec = _readInt(health, 'total_inspections') ?? 0;
    final inMaint = _readInt(a, 'in_maintenance') ?? 0;
    final oosCount = _readInt(a, 'out_of_service') ?? 0;
    final active = _readInt(a, 'active') ?? 0;
    final total = _readInt(a, 'total_vehicles') ?? 0;
    final utilRate = _readDouble(a, 'utilization', 'utilization_rate') ?? 0;
    final onRent = _readInt(a, 'utilization', 'vehicles_with_active_rentals') ?? 0;
    final activePct = total > 0 ? (active / total * 100).roundToDouble() : 0.0;
    final attentionCount = _readInt(health, 'vehicles_needing_attention') ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Gauge + label ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, size: 16, color: DomendraTheme.success),
                  const SizedBox(width: 6),
                  const Text('Fleet Health Score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: DomendraTheme.surfaceVariant,
                      color: healthColor,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${score.round()}%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: healthColor)),
                        Text(
                          score >= 75 ? 'Excellent' : score >= 50 ? 'Fair' : 'Needs Attention',
                          style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Weighted: Utilization 30% + Inspections 30% + Active 40%',
                style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Health indicators ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, size: 18, color: DomendraTheme.primary),
                  SizedBox(width: 6),
                  Text('Health Indicators', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              _HealthIndicatorFull(label: 'Inspection Pass Rate', value: inspectionRate, color: DomendraTheme.success, sub: '$passCount pass / $failCount fail'),
              _HealthIndicatorFull(label: 'Utilization Rate', value: utilRate, color: DomendraTheme.primary, sub: '$onRent on rent'),
              _HealthIndicatorFull(label: 'Active Fleet', value: activePct, color: DomendraTheme.success, sub: '$active active / $total total'),
              _HealthIndicatorFull(label: 'Maintenance Ratio', value: maintenancePct, color: DomendraTheme.warning, sub: '$inMaint in service'),
              _HealthIndicatorFull(label: 'Out of Service', value: oosPct, color: DomendraTheme.danger, sub: '$oosCount out'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Attention required ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: DomendraTheme.danger),
                  const SizedBox(width: 6),
                  const Text('Attention Required', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: attentionCount > 0 ? DomendraTheme.danger.withOpacity(0.12) : DomendraTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$attentionCount items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: attentionCount > 0 ? DomendraTheme.danger : DomendraTheme.success)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AttentionRow(label: 'In Maintenance', count: inMaint, color: DomendraTheme.warning),
              _AttentionRow(label: 'Out of Service', count: oosCount, color: DomendraTheme.danger),
              _AttentionRow(label: 'Failed Inspections', count: failCount, color: DomendraTheme.danger),
              _AttentionRow(label: 'Total Inspections', count: totalInspec, color: DomendraTheme.info),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthIndicatorFull extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String sub;
  const _HealthIndicatorFull({required this.label, required this.value, required this.color, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text('${value.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: DomendraTheme.surfaceVariant,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(sub, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AttentionRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. UTILIZATION TAB (mirrors web VehicleUtilization)
// ════════════════════════════════════════════════════════════
class _UtilizationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final a = p.analytics;

    if (a == null && !p.analyticsLoading) {
      return _AnalyticsEmptyState(onRetry: () => p.refreshAnalytics());
    }
    if (p.analyticsLoading && a == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final util = _readMap(a, 'utilization');
    final utilRate = _readDouble(util, 'utilization_rate') ?? 0;
    final onRentCount = _readInt(util, 'vehicles_with_active_rentals') ?? 0;
    final activeRentals = _readInt(util, 'active_rentals') ?? 0;
    final completed = _readInt(util, 'completed_rentals') ?? 0;
    final totalRevenue = _readDouble(util, 'total_revenue') ?? 0;
    final avgRev = _readDouble(util, 'avg_revenue_per_vehicle') ?? 0;
    final idle = _readInt(util, 'idle_vehicles') ?? 0;
    final overdue = _readInt(util, 'overdue_rentals') ?? 0;
    final topVehicles = (util['top_vehicles'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── KPI Row ──
        Row(
          children: [
            Expanded(child: _OverviewStatCard(label: 'Utilization', value: '${utilRate.round()}%', subtitle: '$onRentCount on rent', icon: Icons.speed, iconBg: const Color(0xFFDCFCE7), iconColor: DomendraTheme.success)),
            const SizedBox(width: 8),
            Expanded(child: _OverviewStatCard(label: 'Active Rentals', value: '$activeRentals', subtitle: '$completed completed', icon: Icons.key, iconBg: const Color(0xFFDBEAFE), iconColor: DomendraTheme.info)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _OverviewStatCard(label: 'Total Revenue', value: _fmtMoney(totalRevenue), subtitle: '${_fmtMoney(avgRev)} avg', icon: Icons.monetization_on, iconBg: const Color(0xFFFEF3C7), iconColor: DomendraTheme.warning)),
            const SizedBox(width: 8),
            Expanded(child: _OverviewStatCard(label: 'Idle Vehicles', value: '$idle', subtitle: '$overdue overdue', icon: Icons.local_parking, iconBg: const Color(0xFFFCE7F3), iconColor: const Color(0xFF7C3AED))),
          ],
        ),
        const SizedBox(height: 16),

        // ── Revenue monthly trend mini chart ──
        _RevenueTrendCard(util: util),
        const SizedBox(height: 16),

        // ── Top Revenue Vehicles ──
        if (topVehicles.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: DomendraTheme.warning),
              SizedBox(width: 6),
              Text('Top Revenue Vehicles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...topVehicles.map((v) {
            final m = v as Map<String, dynamic>;
            final name = '${m['make'] ?? ''} ${m['model'] ?? ''}'.trim();
            final plate = m['license_plate']?.toString() ?? '';
            final rev = (m['rev'] as num?)?.toDouble() ?? 0;
            final rentCnt = (m['rental_cnt'] as num?)?.toInt() ?? 0;
            final status = m['status']?.toString() ?? '';
            return _TopVehicleTile(name: name, plate: plate, revenue: rev, rentalCount: rentCnt, status: status);
          }),
        ],
      ],
    );
  }
}

class _RevenueTrendCard extends StatelessWidget {
  final Map<String, dynamic> util;
  const _RevenueTrendCard({required this.util});

  @override
  Widget build(BuildContext context) {
    final monthly = (util['revenue_monthly'] as List?) ?? [];
    if (monthly.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    final xLabels = <String>[];
    double maxY = 0;
    for (var i = 0; i < monthly.length; i++) {
      final m = monthly[i] as Map<String, dynamic>;
      final rev = (m['revenue'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), rev));
      xLabels.add(m['month']?.toString() ?? '');
      if (rev > maxY) maxY = rev;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: DomendraTheme.success),
              SizedBox(width: 6),
              Text('Revenue Monthly Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final computedWidth = monthly.length * 70.0;
                final chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: LineChart(LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(color: DomendraTheme.outline, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(xLabels[i], style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(_compactNum(value), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY == 0 ? 1 : maxY * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: DomendraTheme.success,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: DomendraTheme.success.withOpacity(0.08)),
                        ),
                      ],
                    )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _compactNum(double v) {
  if (v == 0) return '0';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

// ════════════════════════════════════════════════════════════
// 5. ANALYTICS TAB (nested sub-tabs: Cost / ABC / Type / Location)
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatefulWidget {
  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  static const _subTabs = [
    Tab(icon: Icon(Icons.monetization_on, size: 16), text: 'Cost'),
    Tab(icon: Icon(Icons.bar_chart, size: 16), text: 'ABC'),
    Tab(icon: Icon(Icons.category, size: 16), text: 'Type'),
    Tab(icon: Icon(Icons.location_on, size: 16), text: 'Location'),
  ];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: _subTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final a = p.analytics;

    if (a == null && !p.analyticsLoading) {
      return _AnalyticsEmptyState(onRetry: () => p.refreshAnalytics());
    }
    if (p.analyticsLoading && a == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: _subTabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: DomendraTheme.primary,
          unselectedLabelColor: DomendraTheme.onSurfaceMuted,
          indicatorColor: DomendraTheme.primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _CostSubTab(data: a!),
              _AbcSubTab(data: a!),
              _TypeSubTab(data: a!),
              _LocationSubTab(data: a!),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cost Analysis sub-tab ──
class _CostSubTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CostSubTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final cost = _readMap(data, 'cost_analysis');
    final bookValue = _readDouble(cost, 'total_book_value') ?? 0;
    final depLoss = _readDouble(cost, 'total_depreciation_loss') ?? 0;
    final annualDep = _readDouble(cost, 'total_annual_depreciation') ?? 0;
    final costPerKm = _readDouble(cost, 'cost_per_km') ?? 0;
    final serviceCost = _readDouble(cost, 'total_service_cost') ?? 0;
    final totalServices = _readInt(cost, 'total_services') ?? 0;
    final downtime = _readDouble(cost, 'total_downtime_hours') ?? 0;
    final avgServiceCost = _readDouble(cost, 'avg_service_cost') ?? 0;
    final depVehicles = (cost['vehicles'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _OverviewStatCard(label: 'Book Value', value: _fmtMoney(bookValue), subtitle: '${_fmtMoney(depLoss)} dep loss', icon: Icons.account_balance, iconBg: const Color(0xFFDCFCE7), iconColor: DomendraTheme.success)),
            const SizedBox(width: 8),
            Expanded(child: _OverviewStatCard(label: 'Annual Dep.', value: _fmtMoney(annualDep), subtitle: '${_fmtMoney(costPerKm)} / km', icon: Icons.trending_down, iconBg: const Color(0xFFFEF3C7), iconColor: DomendraTheme.warning)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _OverviewStatCard(label: 'Service Cost', value: _fmtMoney(serviceCost), subtitle: '$totalServices services', icon: Icons.build, iconBg: const Color(0xFFDBEAFE), iconColor: DomendraTheme.info)),
            const SizedBox(width: 8),
            Expanded(child: _OverviewStatCard(label: 'Downtime', value: '${downtime.round()}h', subtitle: '${_fmtMoney(avgServiceCost)} avg', icon: Icons.timer, iconBg: const Color(0xFFFEE2E2), iconColor: DomendraTheme.danger)),
          ],
        ),
        const SizedBox(height: 16),

        if (depVehicles.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.trending_down, size: 18, color: DomendraTheme.warning),
              SizedBox(width: 6),
              Text('Depreciation Detail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...depVehicles.take(20).map((v) {
            final m = v as Map<String, dynamic>;
            final name = '${m['make'] ?? ''} ${m['model'] ?? ''} (${m['year'] ?? ''})'.trim();
            final purchase = (m['purchase_price'] as num?)?.toDouble() ?? 0;
            final bv = (m['book_value'] as num?)?.toDouble() ?? 0;
            final annDep = (m['annual_depreciation'] as num?)?.toDouble() ?? 0;
            final depPct = (m['depreciation_pct'] as num?)?.toDouble() ?? 0;
            final age = (m['age_years'] as num?)?.toDouble() ?? 0;
            final depColor = depPct >= 75 ? DomendraTheme.danger : (depPct >= 50 ? DomendraTheme.warning : (depPct >= 25 ? DomendraTheme.info : DomendraTheme.success));
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      Text('${age.toStringAsFixed(1)} yrs', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _DepKV('Purchase', _fmtMoney(purchase))),
                      Expanded(child: _DepKV('Book', _fmtMoney(bv), color: const Color(0xFF059669))),
                      Expanded(child: _DepKV('Annual', _fmtMoney(annDep))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (depPct / 100).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: DomendraTheme.surfaceVariant,
                            color: depColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${depPct.round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: depColor)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _DepKV extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _DepKV(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color ?? DomendraTheme.onSurface)),
      ],
    );
  }
}

// ── ABC sub-tab ──
class _AbcSubTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AbcSubTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final abc = _readMap(data, 'abc_analysis');
    final summary = _readMap(abc, 'summary');
    final aData = _readMap(summary, 'A');
    final bData = _readMap(summary, 'B');
    final cData = _readMap(summary, 'C');
    final noRev = _readInt(abc, 'no_revenue_count') ?? 0;
    final totalRev = _readDouble(summary, 'total_revenue') ?? 0;
    final totalVehicles = _readInt(summary, 'total_vehicles') ?? 0;
    final vehicles = (abc['vehicles'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _AbcBigCard(letter: 'A', subtitle: 'Top 80%', data: aData, color: DomendraTheme.success)),
            const SizedBox(width: 8),
            Expanded(child: _AbcBigCard(letter: 'B', subtitle: 'Next 15%', data: bData, color: DomendraTheme.info)),
            const SizedBox(width: 8),
            Expanded(child: _AbcBigCard(letter: 'C', subtitle: 'Bottom 5%', data: cData, color: DomendraTheme.onSurfaceMuted)),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart, size: 18, color: DomendraTheme.primary),
                  SizedBox(width: 6),
                  Text('Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              _AbcSummaryRow(label: 'Total Revenue', value: _fmtMoney(totalRev), color: const Color(0xFF059669)),
              _AbcSummaryRow(label: 'Classified Vehicles', value: '$totalVehicles'),
              _AbcSummaryRow(label: 'No Revenue (Excluded)', value: '$noRev'),
              _AbcSummaryRow(label: 'Class A Revenue', value: _fmtMoney((aData['revenue'] as num?)?.toDouble() ?? 0), color: DomendraTheme.success),
              _AbcSummaryRow(label: 'Class B Revenue', value: _fmtMoney((bData['revenue'] as num?)?.toDouble() ?? 0), color: DomendraTheme.info),
              _AbcSummaryRow(label: 'Class C Revenue', value: _fmtMoney((cData['revenue'] as num?)?.toDouble() ?? 0), color: DomendraTheme.onSurfaceMuted),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (vehicles.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.format_list_numbered, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Vehicle Classification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...vehicles.take(20).map((v) {
            final m = v as Map<String, dynamic>;
            final name = '${m['make'] ?? ''} ${m['model'] ?? ''}'.trim();
            final rev = (m['total_rev'] as num?)?.toDouble() ?? 0;
            final cls = m['abc_class']?.toString() ?? 'C';
            final pct = (m['revenue_pct'] as num?)?.toDouble() ?? 0;
            final clsColor = cls == 'A' ? DomendraTheme.success : (cls == 'B' ? DomendraTheme.info : DomendraTheme.onSurfaceMuted);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: clsColor, borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text(cls, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(_fmtMoney(rev), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                  const SizedBox(width: 8),
                  Text('${pct.round()}%', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _AbcBigCard extends StatelessWidget {
  final String letter;
  final String subtitle;
  final Map<String, dynamic> data;
  final Color color;
  const _AbcBigCard({required this.letter, required this.subtitle, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final count = (data['count'] as num?)?.toInt() ?? 0;
    final revenue = (data['revenue'] as num?)?.toDouble() ?? 0;
    final pct = (data['pct'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(letter, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const Icon(Icons.emoji_events, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$count vehicles', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(_fmtMoney(revenue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text('$pct% of fleet', style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _AbcSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _AbcSummaryRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color ?? DomendraTheme.onSurface)),
        ],
      ),
    );
  }
}

// ── Type Analysis sub-tab ──
class _TypeSubTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TypeSubTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = (data['type_analysis'] as List?) ?? [];
    if (rows.isEmpty) return _AnalyticsEmptyState(onRetry: () => context.read<VehiclesProvider>().refreshAnalytics());

    final totalRev = rows.fold<double>(0, (s, r) => s + ((r as Map)['revenue'] as num?)!.toDouble());
    final totalActive = rows.fold<int>(0, (s, r) => s + ((r as Map)['active_count'] as num?)!.toInt());
    final totalEv = rows.fold<int>(0, (s, r) => s + ((r as Map)['ev_count'] as num?)!.toInt());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _MiniStatCard(label: 'Types', value: '${rows.length}', color: DomendraTheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(label: 'Active', value: '$totalActive', color: DomendraTheme.success)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MiniStatCard(label: 'Revenue', value: _fmtMoney(totalRev), color: DomendraTheme.warning)),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(label: 'EV / H2', value: '$totalEv', color: DomendraTheme.info)),
          ],
        ),
        const SizedBox(height: 16),

        const Row(
          children: [
            Icon(Icons.category, size: 18, color: DomendraTheme.primary),
            SizedBox(width: 6),
            Text('Vehicle Type Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map((t) {
          final m = t as Map<String, dynamic>;
          return _AnalysisDetailRow(
            label: m['vehicle_type']?.toString() ?? 'Unknown',
            count: (m['count'] as num?)?.toInt() ?? 0,
            revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
            serviceCost: (m['service_cost'] as num?)?.toDouble() ?? 0,
            activeCount: (m['active_count'] as num?)?.toInt() ?? 0,
            evCount: (m['ev_count'] as num?)?.toInt() ?? 0,
          );
        }),
      ],
    );
  }
}

// ── Location Analysis sub-tab ──
class _LocationSubTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LocationSubTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = (data['location_analysis'] as List?) ?? [];
    if (rows.isEmpty) return _AnalyticsEmptyState(onRetry: () => context.read<VehiclesProvider>().refreshAnalytics());

    final totalRev = rows.fold<double>(0, (s, r) => s + ((r as Map)['revenue'] as num?)!.toDouble());
    final totalActive = rows.fold<int>(0, (s, r) => s + ((r as Map)['active_count'] as num?)!.toInt());
    final totalEv = rows.fold<int>(0, (s, r) => s + ((r as Map)['ev_count'] as num?)!.toInt());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _MiniStatCard(label: 'Locations', value: '${rows.length}', color: DomendraTheme.danger)),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(label: 'Active', value: '$totalActive', color: DomendraTheme.success)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MiniStatCard(label: 'Revenue', value: _fmtMoney(totalRev), color: DomendraTheme.warning)),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(label: 'EV / H2', value: '$totalEv', color: DomendraTheme.info)),
          ],
        ),
        const SizedBox(height: 16),

        const Row(
          children: [
            Icon(Icons.location_on, size: 18, color: DomendraTheme.danger),
            SizedBox(width: 6),
            Text('Location Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.map((l) {
          final m = l as Map<String, dynamic>;
          return _AnalysisDetailRow(
            label: m['location']?.toString() ?? 'Unknown',
            count: (m['count'] as num?)?.toInt() ?? 0,
            revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
            serviceCost: (m['service_cost'] as num?)?.toDouble() ?? 0,
            activeCount: (m['active_count'] as num?)?.toInt() ?? 0,
            evCount: (m['ev_count'] as num?)?.toInt() ?? 0,
          );
        }),
      ],
    );
  }
}

class _AnalysisDetailRow extends StatelessWidget {
  final String label;
  final int count;
  final double revenue;
  final double serviceCost;
  final int activeCount;
  final int evCount;

  const _AnalysisDetailRow({
    required this.label,
    required this.count,
    required this.revenue,
    required this.serviceCost,
    required this.activeCount,
    required this.evCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('$activeCount active', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.success)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _DepKV('Count', '$count')),
              Expanded(child: _DepKV('Revenue', _fmtMoney(revenue), color: const Color(0xFF059669))),
              Expanded(child: _DepKV('Services', _fmtMoney(serviceCost), color: DomendraTheme.warning)),
              if (evCount > 0) Expanded(child: _DepKV('EV', '$evCount', color: DomendraTheme.info)),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 6. CATALOG TAB (makes, body types, models)
// ════════════════════════════════════════════════════════════
class _CatalogTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: DomendraTheme.primary,
            unselectedLabelColor: DomendraTheme.onSurfaceMuted,
            indicatorColor: DomendraTheme.primary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(icon: Icon(Icons.directions_car, size: 16), text: 'Makes'),
              Tab(icon: Icon(Icons.category_outlined, size: 16), text: 'Body Types'),
              Tab(icon: Icon(Icons.format_list_bulleted, size: 16), text: 'Models'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MakesList(items: p.makes),
                _BodyTypesList(items: p.bodyTypes),
                _ModelsList(items: p.models, makes: p.makes, bodyTypes: p.bodyTypes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MakesList extends StatefulWidget {
  final List<dynamic> items;
  const _MakesList({required this.items});

  @override
  State<_MakesList> createState() => _MakesListState();
}

class _MakesListState extends State<_MakesList> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      final m = item as Map<String, dynamic>;
      final name = m['name']?.toString().toLowerCase() ?? '';
      return _search.isEmpty || name.contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search makes...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = ''))
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _CatalogEmpty(icon: Icons.directions_car, text: 'No makes found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i] as Map<String, dynamic>;
                    final name = m['name']?.toString() ?? 'Unknown';
                    final modelCount = (m['model_count'] as num?)?.toInt() ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.directions_car, size: 18, color: DomendraTheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('$modelCount models', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BodyTypesList extends StatefulWidget {
  final List<dynamic> items;
  const _BodyTypesList({required this.items});

  @override
  State<_BodyTypesList> createState() => _BodyTypesListState();
}

class _BodyTypesListState extends State<_BodyTypesList> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      final m = item as Map<String, dynamic>;
      final label = m['label']?.toString().toLowerCase() ?? '';
      return _search.isEmpty || label.contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search body types...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = '')) : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _CatalogEmpty(icon: Icons.category_outlined, text: 'No body types found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i] as Map<String, dynamic>;
                    final label = m['label']?.toString() ?? 'Unknown';
                    final value = m['value']?.toString() ?? '';
                    final modelCount = (m['model_count'] as num?)?.toInt() ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.directions_car, size: 18, color: DomendraTheme.info),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                if (value.isNotEmpty)
                                  Text(value, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('$modelCount models', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.info)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ModelsList extends StatefulWidget {
  final List<dynamic> items;
  final List<dynamic> makes;
  final List<dynamic> bodyTypes;
  const _ModelsList({required this.items, required this.makes, required this.bodyTypes});

  @override
  State<_ModelsList> createState() => _ModelsListState();
}

class _ModelsListState extends State<_ModelsList> {
  String? _makeFilter;
  String? _btFilter;

  String _makeName(dynamic makeId) {
    if (makeId == null) return '';
    final found = widget.makes.where((m) => (m as Map)['id'].toString() == makeId.toString());
    return found.isEmpty ? '' : (found.first as Map)['name']?.toString() ?? '';
  }

  String _btLabel(dynamic btId) {
    if (btId == null) return '';
    final found = widget.bodyTypes.where((b) => (b as Map)['id'].toString() == btId.toString());
    return found.isEmpty ? '' : (found.first as Map)['label']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      final m = item as Map<String, dynamic>;
      if (_makeFilter != null && m['make']?.toString() != _makeFilter) return false;
      if (_btFilter != null && m['body_type']?.toString() != _btFilter) return false;
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String?>(
                  value: _makeFilter,
                  hint: const Text('All Makes', style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Makes')),
                    ...widget.makes.map((m) => DropdownMenuItem<String?>(
                      value: (m as Map)['id']?.toString(),
                      child: Text(m['name']?.toString() ?? 'Unknown'),
                    )),
                  ],
                  onChanged: (v) => setState(() => _makeFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  value: _btFilter,
                  hint: const Text('All Body Types', style: TextStyle(fontSize: 13)),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Body Types')),
                    ...widget.bodyTypes.map((b) => DropdownMenuItem<String?>(
                      value: (b as Map)['id']?.toString(),
                      child: Text(b['label']?.toString() ?? 'Unknown'),
                    )),
                  ],
                  onChanged: (v) => setState(() => _btFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Text('${filtered.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _CatalogEmpty(icon: Icons.format_list_bulleted, text: 'No models found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i] as Map<String, dynamic>;
                    final makeName = m['make_name']?.toString() ?? _makeName(m['make']);
                    final btLabel = m['body_type_label']?.toString() ?? _btLabel(m['body_type']);
                    final name = m['name']?.toString() ?? 'Unknown';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: DomendraTheme.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.format_list_bulleted, size: 18, color: DomendraTheme.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('$makeName · $btLabel', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CatalogEmpty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CatalogEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 7. GROUPS TAB (mirrors web GroupsTab.vue)
// ════════════════════════════════════════════════════════════
class _GroupsTab extends StatefulWidget {
  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final groups = p.groups.where((item) {
      final m = item as Map<String, dynamic>;
      final name = m['name']?.toString().toLowerCase() ?? '';
      final desc = m['description']?.toString().toLowerCase() ?? '';
      return _search.isEmpty || name.contains(_search.toLowerCase()) || desc.contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search groups...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = '')) : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${groups.length} groups', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? _CatalogEmpty(icon: Icons.folder_outlined, text: 'No groups found. Create one to organize your fleet.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final m = groups[i] as Map<String, dynamic>;
                    final name = m['name']?.toString() ?? 'Unknown';
                    final description = m['description']?.toString() ?? '';
                    final colorStr = m['color']?.toString() ?? '';
                    final vehicleCount = (m['vehicle_count'] as num?)?.toInt() ?? 0;
                    final color = _parseColor(colorStr) ?? DomendraTheme.primary;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.folder, size: 22, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                                    const SizedBox(width: 6),
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ],
                                ),
                                if (description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(description, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('$vehicleCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 8. VEHICLE TYPES TAB (mirrors web VehicleTypesTab.vue)
// ════════════════════════════════════════════════════════════
class _VehicleTypesTab extends StatefulWidget {
  @override
  State<_VehicleTypesTab> createState() => _VehicleTypesTabState();
}

class _VehicleTypesTabState extends State<_VehicleTypesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final types = p.vehicleTypes.where((item) {
      final m = item as Map<String, dynamic>;
      final name = m['name']?.toString().toLowerCase() ?? '';
      final desc = m['description']?.toString().toLowerCase() ?? '';
      return _search.isEmpty || name.contains(_search.toLowerCase()) || desc.contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search vehicle types...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = '')) : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${types.length} types', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ),
        Expanded(
          child: types.isEmpty
              ? _CatalogEmpty(icon: Icons.category_outlined, text: 'No vehicle types found')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: types.length,
                  itemBuilder: (context, i) {
                    final m = types[i] as Map<String, dynamic>;
                    final name = m['name']?.toString() ?? 'Unknown';
                    final description = m['description']?.toString() ?? '';
                    final isActive = m['is_active'] == true || m['is_active'] == 1;
                    final colorStr = m['color']?.toString() ?? '#6366f1';
                    final color = _parseColor(colorStr) ?? DomendraTheme.primary;
                    final passengerCap = (m['passenger_capacity'] as num?)?.toInt() ?? 0;
                    final cargoCap = (m['cargo_capacity_kg'] as num?)?.toInt() ?? 0;
                    final sortOrder = (m['sort_order'] as num?)?.toInt() ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.directions_car, size: 22, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (description.isNotEmpty)
                                      Text(description, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (passengerCap > 0)
                                _TypePill(icon: Icons.people_outline, label: '$passengerCap pax'),
                              if (passengerCap > 0) const SizedBox(width: 8),
                              if (cargoCap > 0)
                                _TypePill(icon: Icons.inventory_2_outlined, label: '${_fmtNum(cargoCap)} kg'),
                              if (cargoCap > 0) const SizedBox(width: 8),
                              _TypePill(icon: Icons.sort, label: '#$sortOrder'),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _TypePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TypePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DomendraTheme.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 9. LOCATIONS TAB (mirrors web LocationsTab.vue)
// ════════════════════════════════════════════════════════════
class _LocationsTab extends StatefulWidget {
  @override
  State<_LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<_LocationsTab> {
  String _search = '';

  static const _typeLabels = {
    'depot': 'Depot',
    'yard': 'Yard',
    'warehouse': 'Warehouse',
    'office': 'Office',
    'shop': 'Shop',
    'site': 'Site',
    'garage': 'Garage',
    'parking': 'Parking',
    'other': 'Other',
  };

  String _typeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Location';
    return _typeLabels[type] ?? type[0].toUpperCase() + type.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    final locations = p.locations.where((item) {
      final m = item as Map<String, dynamic>;
      final name = m['name']?.toString().toLowerCase() ?? '';
      final address = m['address']?.toString().toLowerCase() ?? '';
      final type = m['type']?.toString().toLowerCase() ?? '';
      return _search.isEmpty || name.contains(_search.toLowerCase()) || address.contains(_search.toLowerCase()) || type.contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search locations...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _search = '')) : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${locations.length} locations', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ),
        Expanded(
          child: locations.isEmpty
              ? _CatalogEmpty(icon: Icons.location_on_outlined, text: 'No locations found. Add a depot, yard or site.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: locations.length,
                  itemBuilder: (context, i) {
                    final m = locations[i] as Map<String, dynamic>;
                    final name = m['name']?.toString() ?? 'Unknown';
                    final type = m['type']?.toString() ?? '';
                    final address = m['address']?.toString() ?? '';
                    final isActive = m['is_active'] == true || m['is_active'] == 1;
                    final colorStr = m['color']?.toString() ?? '';
                    final color = _parseColor(colorStr) ?? DomendraTheme.danger;
                    final vehicleCount = (m['vehicle_count'] as num?)?.toInt() ?? 0;
                    final notes = m['notes']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.location_on, size: 22, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    if (address.isNotEmpty)
                                      Text(address, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (type.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                  child: Text(_typeLabel(type), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text('$vehicleCount vehicles', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
                              ),
                            ],
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: [
                                  const Icon(Icons.notes, size: 12, color: DomendraTheme.onSurfaceMuted),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(notes, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final VehicleStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      VehicleStatus.active => (DomendraTheme.success, 'Active'),
      VehicleStatus.outOfService => (DomendraTheme.warning, 'OOS'),
      VehicleStatus.inMaintenance => (DomendraTheme.warning, 'Maint'),
      VehicleStatus.retired => (DomendraTheme.danger, 'Retired'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DomendraTheme.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text('${pct.round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: DomendraTheme.surfaceVariant,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AbcCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final Color color;

  const _AbcCard({required this.label, required this.subtitle, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label;
  final int count;
  final double revenue;

  const _AnalysisRow({required this.label, required this.count, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Text('$count units', style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(width: 12),
          Text(_fmtMoney(revenue), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.success)),
        ],
      ),
    );
  }
}

class _TopVehicleTile extends StatelessWidget {
  final String name;
  final String plate;
  final double revenue;
  final int rentalCount;
  final String status;

  const _TopVehicleTile({
    required this.name,
    this.plate = '',
    required this.revenue,
    this.rentalCount = 0,
    this.status = '',
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, size: 18, color: DomendraTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (status.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                ),
                const SizedBox(width: 6),
              ],
              Text(_fmtMoney(revenue), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.success)),
            ],
          ),
          if (plate.isNotEmpty || rentalCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (plate.isNotEmpty)
                  Expanded(child: Text(plate, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted))),
                if (rentalCount > 0)
                  Text('$rentalCount rentals', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Overview KPI Row (mirrors web VehicleOverview 4 StatCards)
// ════════════════════════════════════════════════════════════
class _OverviewKpiRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewKpiRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalVehicles = _readInt(data, 'total_vehicles') ?? 0;
    final active = _readInt(data, 'active') ?? 0;
    final healthScore = _readDouble(data, 'fleet_health', 'fleet_health_score') ?? 0;
    final utilRate = _readDouble(data, 'utilization', 'utilization_rate') ?? 0;
    final activeRentals = _readInt(data, 'utilization', 'active_rentals') ?? 0;
    final totalRevenue = _readDouble(data, 'utilization', 'total_revenue') ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _OverviewStatCard(
                label: 'Total Vehicles',
                value: '$totalVehicles',
                subtitle: '$active active',
                icon: Icons.directions_car,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: DomendraTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewStatCard(
                label: 'Fleet Health',
                value: '${healthScore.round()}%',
                subtitle: healthScore >= 75 ? 'Excellent' : (healthScore >= 50 ? 'Fair' : 'Needs Attention'),
                icon: Icons.shield,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: DomendraTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _OverviewStatCard(
                label: 'Utilization',
                value: '${utilRate.round()}%',
                subtitle: '$activeRentals active rentals',
                icon: Icons.show_chart,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: DomendraTheme.info,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewStatCard(
                label: 'Total Revenue',
                value: _fmtMoney(totalRevenue),
                subtitle: 'From rentals',
                icon: Icons.monetization_on,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: DomendraTheme.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Overview Acquisition Trend chart (bar chart — mirrors web)
// ════════════════════════════════════════════════════════════
class _AcquisitionTrendCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AcquisitionTrendCard({required this.data});

  static const _barColors = [
    Color(0xFF6366f1),
    Color(0xFF10b981),
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFFA855F7),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    final acq = (data['acquisition_trend'] as List?) ?? [];
    if (acq.isEmpty) return const SizedBox.shrink();

    final xLabels = acq.map((a) {
      final m = a as Map<String, dynamic>;
      return m['month']?.toString() ?? '';
    }).toList();
    final values = acq.map((a) {
      final m = a as Map<String, dynamic>;
      return (m['count'] as num?)?.toDouble() ?? 0;
    }).toList();
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Acquisition Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final computedWidth = acq.length * 50.0;
                final chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(color: DomendraTheme.outline, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(xLabels[i], style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY == 0 ? 1 : maxY + 1,
                      barGroups: List.generate(values.length, (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            color: _barColors[i % _barColors.length],
                            width: 18,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      )),
                    )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Overview Revenue Trend chart (line chart — mirrors web)
// ════════════════════════════════════════════════════════════
class _OverviewRevenueTrendCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewRevenueTrendCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final monthly = (data['utilization']?['revenue_monthly'] as List?) ?? [];
    if (monthly.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    final xLabels = <String>[];
    double maxY = 0;
    for (var i = 0; i < monthly.length; i++) {
      final m = monthly[i] as Map<String, dynamic>;
      final rev = (m['revenue'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), rev));
      xLabels.add(m['month']?.toString() ?? '');
      if (rev > maxY) maxY = rev;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: DomendraTheme.success),
              SizedBox(width: 6),
              Text('Revenue Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final computedWidth = monthly.length * 70.0;
                final chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: LineChart(LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(color: DomendraTheme.outline, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(xLabels[i], style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(_compactNum(value), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY == 0 ? 1 : maxY * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withOpacity(0.3),
                                const Color(0xFF10B981).withOpacity(0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 1. Fuel Type Breakdown (stacked bar / legend — mirrors web fuelMixOption)
// ════════════════════════════════════════════════════════════
class _FuelTypeBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FuelTypeBreakdownCard({required this.data});

  static const _colors = [
    Color(0xFF6366f1), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF0EA5E9),
    Color(0xFFA855F7), Color(0xFF06B6D4), Color(0xFFEF4444), Color(0xFF94A3B8),
    Color(0xFFEC4899), Color(0xFF84CC16),
  ];

  @override
  Widget build(BuildContext context) {
    final fuel = (data['fuel_type_breakdown'] as List?) ?? [];
    if (fuel.isEmpty) return const SizedBox.shrink();

    final total = fuel.fold<int>(0, (s, f) => s + ((f as Map)['count'] as num?)!.toInt());
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_gas_station, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Fuel Type Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 32,
              child: Row(
                children: fuel.asMap().entries.map((e) {
                  final i = e.key;
                  final m = e.value as Map<String, dynamic>;
                  final count = (m['count'] as num?)?.toInt() ?? 0;
                  final pct = total > 0 ? count / total : 0.0;
                  return Expanded(
                    flex: (pct * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: _colors[i % _colors.length]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: fuel.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value as Map<String, dynamic>;
              final ft = m['fuel_type']?.toString() ?? 'Unknown';
              final count = (m['count'] as num?)?.toInt() ?? 0;
              final pct = total > 0 ? (count / total * 100).round() : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('$ft ($count · $pct%)', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. Vehicle Type Distribution (bar chart — mirrors web vehicleTypeOption)
// ════════════════════════════════════════════════════════════
class _VehicleTypeDistCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VehicleTypeDistCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final vtypes = ((data['vehicle_type_breakdown'] as List?) ?? [])
        .where((v) => (v as Map)['vehicle_type'] != null && (v)['vehicle_type'].toString().isNotEmpty)
        .toList();
    if (vtypes.isEmpty) return const SizedBox.shrink();

    final xLabels = vtypes.map((v) => (v as Map)['vehicle_type'].toString()).toList();
    final values = vtypes.map((v) => ((v as Map)['count'] as num?)?.toDouble() ?? 0.0).toList();
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category, size: 18, color: DomendraTheme.info),
              SizedBox(width: 6),
              Text('Vehicle Type Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final computedWidth = vtypes.length * 50.0;
                final chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(color: DomendraTheme.outline, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(xLabels[i], style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY == 0 ? 1 : maxY + 1,
                      barGroups: List.generate(values.length, (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            width: 22,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                          ),
                        ],
                      )),
                    )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. Top Makes (horizontal bar — mirrors web topMakesOption)
// ════════════════════════════════════════════════════════════
class _TopMakesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TopMakesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final makes = (data['top_makes'] as List?) ?? [];
    if (makes.isEmpty) return const SizedBox.shrink();

    final labels = makes.map((m) => (m as Map)['make']?.toString() ?? '').toList();
    final values = makes.map((m) => ((m as Map)['count'] as num?)?.toDouble() ?? 0.0).toList();
    final maxX = values.fold<double>(0, (a, b) => a > b ? a : b);

    // Reverse for left-to-right descending (web reverses too)
    final revLabels = labels.reversed.toList();
    final revValues = values.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car, size: 18, color: Color(0xFFA855F7)),
              SizedBox(width: 6),
              Text('Top Makes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: makes.length * 36.0 + 20,
            child: BarChart(BarChartData(
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => const FlLine(color: DomendraTheme.outline, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 80,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= revLabels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(revLabels[i], style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              groupsSpace: 6,
              barGroups: List.generate(revValues.length, (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: revValues[i],
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    width: 18,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                  ),
                ],
              )),
            )),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. Revenue by Vehicle Type (bar chart — mirrors web revenueByTypeOption)
// ════════════════════════════════════════════════════════════
class _RevenueByTypeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RevenueByTypeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final rbt = ((data['utilization']?['revenue_by_type'] as List?) ?? [])
        .where((r) => (r as Map)['vehicle_type'] != null && (r)['vehicle_type'].toString().isNotEmpty)
        .toList();
    if (rbt.isEmpty) return const SizedBox.shrink();

    final xLabels = rbt.map((r) => (r as Map)['vehicle_type'].toString()).toList();
    final values = rbt.map((r) => ((r as Map)['revenue'] as num?)?.toDouble() ?? 0.0).toList();
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: DomendraTheme.success),
              SizedBox(width: 6),
              Text('Revenue by Vehicle Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final computedWidth = rbt.length * 55.0;
                final chartWidth = computedWidth > constraints.maxWidth ? computedWidth : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: BarChart(BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(color: DomendraTheme.outline, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(xLabels[i], style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(_compactNum(value), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY == 0 ? 1 : maxY * 1.2,
                      barGroups: List.generate(values.length, (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            width: 24,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                          ),
                        ],
                      )),
                    )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 5. Service Cost by Type (pie/donut — mirrors web serviceByTypeOption)
// ════════════════════════════════════════════════════════════
class _ServiceByTypeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ServiceByTypeCard({required this.data});

  static const _colorMap = {
    'oil_change': Color(0xFF10B981),
    'tire_rotation': Color(0xFF0EA5E9),
    'brake_service': Color(0xFFEF4444),
    'inspection': Color(0xFFA855F7),
    'repair': Color(0xFFF59E0B),
    'preventive': Color(0xFF6366F1),
    'other': Color(0xFF94A3B8),
  };
  static const _labels = {
    'oil_change': 'Oil Change',
    'tire_rotation': 'Tire Rotation',
    'brake_service': 'Brake Service',
    'inspection': 'Inspection',
    'repair': 'Repair',
    'preventive': 'Preventive',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final sbt = (data['cost_analysis']?['service_by_type'] as List?) ?? [];
    if (sbt.isEmpty) return const SizedBox.shrink();

    final items = sbt.map((s) => s as Map<String, dynamic>).where((m) => (m['cost'] as num?)?.toDouble() != null && m['cost'] != 0).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final slices = items.map((m) {
      final st = m['service_type']?.toString() ?? 'other';
      final cost = (m['cost'] as num?)?.toDouble() ?? 0;
      return (st, cost, _colorMap[st] ?? const Color(0xFF94A3B8));
    }).toList();
    final totalCost = slices.fold<double>(0, (s, x) => s + x.$2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build, size: 18, color: DomendraTheme.warning),
              SizedBox(width: 6),
              Text('Service Cost by Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // Donut - approximate with custom painted slices + center label
          SizedBox(
            height: 180,
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _DonutPainter(slices.map((s) => (s.$3, s.$2)).toList()),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_compactNum(totalCost), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const Text('Total', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: slices.map((s) {
                      final pct = totalCost > 0 ? (s.$2 / totalCost * 100).round() : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_labels[s.$1] ?? s.$1} ($pct%)',
                                style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(_compactNum(s.$2), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(Color, double)> slices;
  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, x) => s + x.$2);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width * 0.45;
    final inner = outer * 0.55;
    final rect = Rect.fromCircle(center: center, radius: outer);
    final innerRect = Rect.fromCircle(center: center, radius: inner);

    double start = -pi / 2;
    for (final (color, value) in slices) {
      final sweep = (value / total) * 2 * pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    // inner hole
    canvas.drawCircle(center, inner, Paint()..color = DomendraTheme.surface);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (slices.length != oldDelegate.slices.length) return true;
    for (var i = 0; i < slices.length; i++) {
      if (slices[i] != oldDelegate.slices[i]) return true;
    }
    return false;
  }
}

// ════════════════════════════════════════════════════════════
// Overview Health + Composition card
// ════════════════════════════════════════════════════════════
class _OverviewHealthComposition extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewHealthComposition({required this.data});

  @override
  Widget build(BuildContext context) {
    final healthScore = _readDouble(data, 'fleet_health', 'fleet_health_score') ?? 0;
    final healthColor = healthScore >= 75
        ? DomendraTheme.success
        : (healthScore >= 50 ? DomendraTheme.warning : DomendraTheme.danger);

    final inspectionRate = _readDouble(data, 'fleet_health', 'inspection_pass_rate') ?? 0;
    final maintenancePct = _readDouble(data, 'fleet_health', 'maintenance_pct') ?? 0;
    final oosPct = _readDouble(data, 'fleet_health', 'out_of_service_pct') ?? 0;
    final totalInspections = _readInt(data, 'fleet_health', 'total_inspections') ?? 0;

    final statusBreakdown = (data['status_breakdown'] as List?) ?? [];
    final ownershipBreakdown = (data['ownership_breakdown'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // ── Health score gauge + composition ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gauge
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (healthScore / 100).clamp(0.0, 1.0),
                      strokeWidth: 10,
                      backgroundColor: DomendraTheme.surfaceVariant,
                      color: healthColor,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${healthScore.round()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        const Text('Health', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Health indicators
              Expanded(
                child: Column(
                  children: [
                    _HealthIndicator(label: 'Inspection Pass', value: inspectionRate, color: DomendraTheme.success),
                    _HealthIndicator(label: 'Maintenance', value: maintenancePct, color: DomendraTheme.warning),
                    _HealthIndicator(label: 'Out of Service', value: oosPct, color: DomendraTheme.danger),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, size: 14, color: DomendraTheme.info),
                          const SizedBox(width: 6),
                          const Text('Total Inspections', style: TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
                          const Spacer(),
                          Text('$totalInspections', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // ── Fleet composition ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // By Status
              Expanded(
                child: _CompositionSection(
                  title: 'BY STATUS',
                  items: statusBreakdown.map((s) {
                    final m = s as Map<String, dynamic>;
                    final status = m['status']?.toString() ?? '?';
                    final count = (m['count'] as num?)?.toInt() ?? 0;
                    final color = _statusColor(status);
                    return _CompositionItem(label: status.replaceAll('_', ' '), count: count, color: color);
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              // By Ownership
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompositionSection(
                      title: 'BY OWNERSHIP',
                      items: ownershipBreakdown.map((o) {
                        final m = o as Map<String, dynamic>;
                        final own = m['ownership']?.toString() ?? '?';
                        final count = (m['count'] as num?)?.toInt() ?? 0;
                        final color = own == 'lease' ? const Color(0xFF7C3AED) : DomendraTheme.success;
                        final label = own == 'lease' ? 'Leased' : 'Owned';
                        return _CompositionItem(label: label, count: count, color: color);
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // EV stats
                    Builder(builder: (_) {
                      final ev = data['ev_stats'] as Map<String, dynamic>?;
                      final evCount = ev != null ? (ev['count'] as num?)?.toInt() ?? 0 : 0;
                      final avgSoc = ev != null ? (ev['avg_state_of_charge'] as num?)?.toDouble() ?? 0 : 0;
                      final avgSoh = ev != null ? (ev['avg_state_of_health'] as num?)?.toDouble() ?? 0 : 0;
                      return Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.ev_station, size: 14, color: DomendraTheme.success),
                              const SizedBox(width: 6),
                              const Expanded(child: Text('Electric / Hydrogen', style: TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted))),
                              Text('$evCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (evCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 20, top: 2),
                              child: Row(
                                children: [
                                  const Text('Avg SOC / SOH', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                                  const Spacer(),
                                  Text('${avgSoc.round()}% / ${avgSoh.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _HealthIndicator({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted))),
              Text('${value.round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: DomendraTheme.surfaceVariant,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositionSection extends StatelessWidget {
  final String title;
  final List<_CompositionItem> items;

  const _CompositionSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted, letterSpacing: 1)),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(child: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DomendraTheme.onSurface))),
              Text('${item.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        )),
      ],
    );
  }
}

class _CompositionItem {
  final String label;
  final int count;
  final Color color;
  const _CompositionItem({required this.label, required this.count, required this.color});
}

Color _statusColor(String status) {
  switch (status) {
    case 'active':
      return DomendraTheme.success;
    case 'in_maintenance':
      return DomendraTheme.info;
    case 'out_of_service':
      return DomendraTheme.warning;
    case 'retired':
      return DomendraTheme.onSurfaceMuted;
    default:
      return DomendraTheme.onSurfaceMuted;
  }
}

// ════════════════════════════════════════════════════════════
// Overview Utilization and Revenue card
// ════════════════════════════════════════════════════════════
class _OverviewUtilizationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewUtilizationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final util = _readMap(data, 'utilization');
    final activeRentals = _readInt(util, 'active_rentals') ?? 0;
    final completed = _readInt(util, 'completed_rentals') ?? 0;
    final overdue = _readInt(util, 'overdue_rentals') ?? 0;
    final idle = _readInt(util, 'idle_vehicles') ?? 0;
    final totalRevenue = _readDouble(util, 'total_revenue') ?? 0;
    final avgRev = _readDouble(util, 'avg_revenue_per_vehicle') ?? 0;
    final maxRev = _readDouble(util, 'max_revenue') ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, size: 18, color: DomendraTheme.info),
              const SizedBox(width: 6),
              const Text('Utilization and Revenue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // mini stats grid
          Row(
            children: [
              Expanded(child: _UtilMini(value: '$activeRentals', label: 'Active', color: const Color(0xFF16A34A))),
              const SizedBox(width: 8),
              Expanded(child: _UtilMini(value: '$completed', label: 'Completed', color: const Color(0xFF0EA5E9))),
              const SizedBox(width: 8),
              Expanded(child: _UtilMini(value: '$overdue', label: 'Overdue', color: const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _UtilMini(value: '$idle', label: 'Idle', color: const Color(0xFFA855F7))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          _RevenueRow(label: 'Total Revenue', value: totalRevenue, bold: true),
          _RevenueRow(label: 'Avg Revenue / Vehicle', value: avgRev),
          _RevenueRow(label: 'Max Revenue (single)', value: maxRev),
        ],
      ),
    );
  }
}

class _UtilMini extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _UtilMini({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _RevenueRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted))),
          Text(_fmtMoney(value), style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: const Color(0xFF059669))),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Overview Attention card
// ════════════════════════════════════════════════════════════
class _OverviewAttentionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OverviewAttentionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final inMaint = _readInt(data, 'in_maintenance') ?? 0;
    final oos = _readInt(data, 'out_of_service') ?? 0;
    final fail = _readInt(data, 'fleet_health', 'fail_count') ?? 0;
    final retired = _readInt(data, 'retired') ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 18, color: DomendraTheme.danger),
              const SizedBox(width: 6),
              const Text('Vehicles Needing Attention', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _AttentionTile(icon: Icons.build, value: inMaint, label: 'In Maintenance', color: DomendraTheme.warning)),
              const SizedBox(width: 8),
              Expanded(child: _AttentionTile(icon: Icons.car_crash, value: oos, label: 'Out of Service', color: DomendraTheme.danger)),
              const SizedBox(width: 8),
              Expanded(child: _AttentionTile(icon: Icons.assignment_late, value: fail, label: 'Failed Insp.', color: DomendraTheme.danger)),
              const SizedBox(width: 8),
              Expanded(child: _AttentionTile(icon: Icons.car_repair, value: retired, label: 'Retired', color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  const _AttentionTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _OverviewStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalVehicles = _readInt(data, 'total_vehicles') ?? _readInt(data, 'kpis', 'total_vehicles') ?? 0;
    final fleetHealth = _readDouble(data, 'fleet_health', 'health_score') ?? _readDouble(data, 'health_score') ?? 0;
    final utilization = _readDouble(data, 'utilization', 'utilization_rate') ?? _readDouble(data, 'utilization_rate') ?? 0;
    final totalRevenue = _readDouble(data, 'total_revenue') ?? _readDouble(data, 'kpis', 'total_revenue') ?? 0;
    final bookValue = _readDouble(data, 'book_value') ?? _readDouble(data, 'cost_analysis', 'total_book_value') ?? 0;
    final evCount = _readInt(data, 'ev_count') ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        _KpiCard(label: 'Total Vehicles', value: '$totalVehicles', icon: Icons.directions_car, color: DomendraTheme.primary),
        _KpiCard(label: 'Fleet Health', value: '${fleetHealth.round()}%', icon: Icons.health_and_safety, color: DomendraTheme.success),
        _KpiCard(label: 'Utilization', value: '${utilization.round()}%', icon: Icons.insights, color: DomendraTheme.info),
        _KpiCard(label: 'Total Revenue', value: _fmtMoney(totalRevenue), icon: Icons.attach_money, color: DomendraTheme.warning),
        _KpiCard(label: 'Book Value', value: _fmtMoney(bookValue), icon: Icons.account_balance, color: DomendraTheme.secondary),
        _KpiCard(label: 'EV Count', value: '$evCount', icon: Icons.electric_car, color: DomendraTheme.primary),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
          Text(label, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  const _BreakdownCard({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final statusBreakdown = _readMap(data, 'status_breakdown').isNotEmpty ? _readMap(data, 'status_breakdown') : _readMap(data, 'vehicles_by_status');
    final fuelBreakdown = _readMap(data, 'fuel_type_breakdown').isNotEmpty ? _readMap(data, 'fuel_type_breakdown') : _readMap(data, 'vehicles_by_fuel_type');
    final typeBreakdown = _readMap(data, 'vehicle_type_breakdown').isNotEmpty ? _readMap(data, 'vehicle_type_breakdown') : _readMap(data, 'vehicles_by_type');
    final ownershipBreakdown = _readMap(data, 'ownership_breakdown').isNotEmpty ? _readMap(data, 'ownership_breakdown') : _readMap(data, 'vehicles_by_ownership');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (statusBreakdown.isNotEmpty) ...[
            _BreakdownSection(label: 'By Status', breakdown: statusBreakdown, colors: const [DomendraTheme.success, DomendraTheme.warning, DomendraTheme.danger, DomendraTheme.onSurfaceMuted]),
            const SizedBox(height: 12),
          ],
          if (fuelBreakdown.isNotEmpty) ...[
            _BreakdownSection(label: 'By Fuel Type', breakdown: fuelBreakdown, colors: const [DomendraTheme.primary, DomendraTheme.secondary, DomendraTheme.info, DomendraTheme.success, DomendraTheme.warning, DomendraTheme.danger]),
            const SizedBox(height: 12),
          ],
          if (typeBreakdown.isNotEmpty) ...[
            _BreakdownSection(label: 'By Vehicle Type', breakdown: typeBreakdown, colors: const [DomendraTheme.primary, DomendraTheme.info, DomendraTheme.secondary]),
            const SizedBox(height: 12),
          ],
          if (ownershipBreakdown.isNotEmpty)
            _BreakdownSection(label: 'By Ownership', breakdown: ownershipBreakdown, colors: const [DomendraTheme.primary, DomendraTheme.secondary]),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  final String label;
  final Map<String, dynamic> breakdown;
  final List<Color> colors;

  const _BreakdownSection({required this.label, required this.breakdown, required this.colors});

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) {
        final av = (a.value as num?)?.toDouble() ?? 0;
        final bv = (b.value as num?)?.toDouble() ?? 0;
        return bv.compareTo(av);
      });

    final total = entries.fold<double>(0, (sum, e) => sum + ((e.value as num?)?.toDouble() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 6),
        ...entries.map((e) {
          final idx = entries.indexOf(e) % colors.length;
          final color = colors[idx];
          final value = (e.value as num?)?.toDouble() ?? 0;
          final pct = total > 0 ? (value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(_prettifyLabel(e.key), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                Text('${value.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${pct.round()}%', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          );
        }),
      ],
    );
  }

  static String _prettifyLabel(String key) {
    return key.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

class _RecentVehiclesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiclesProvider>();
    if (p.vehicles.isEmpty) return const SizedBox.shrink();
    final recent = p.vehicles.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Vehicles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => DefaultTabController.of(context).animateTo(1),
                child: const Text('View all', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recent.map((v) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DomendraTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(v.isElectric ? Icons.electric_car : Icons.directions_car, size: 18, color: DomendraTheme.primary),
                ),
                title: Text(v.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${v.licensePlate.isNotEmpty ? v.licensePlate : v.vin}', style: const TextStyle(fontSize: 11)),
                trailing: _StatusChip(status: v.status),
                onTap: () => Navigator.pushNamed(context, '/app/vehicles/${v.id}'),
              )),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.error_outline, size: 48, color: DomendraTheme.danger),
        const SizedBox(height: 16),
        const Text('Failed to load vehicles', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurface)),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Icon(Icons.directions_car_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
        const SizedBox(height: 12),
        const Text('No vehicles found', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        const Text('Add your first vehicle to get started.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Vehicle')),
      ],
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _AnalyticsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No analytics data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Load Analytics')),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════════════════

BoxDecoration _cardDecoration() => BoxDecoration(
      color: DomendraTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: DomendraTheme.outline),
    );

String _fmtMoney(double v) {
  final sym = _currencySymbol;
  if (v >= 1000000) return '$sym ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '$sym ${(v / 1000).toStringAsFixed(1)}k';
  return '$sym ${v.toStringAsFixed(0)}';
}

Color? _parseColor(String hex) {
  if (hex.isEmpty) return null;
  try {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('0xFF$cleaned'));
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _readMap(Map<String, dynamic>? data, [String? key1, String? key2]) {
  if (data == null) return {};
  if (key2 != null && key1 != null) {
    final inner = data[key1];
    if (inner is Map<String, dynamic>) return inner;
  }
  if (key1 != null) {
    final v = data[key1];
    if (v is Map<String, dynamic>) return v;
  }
  return {};
}

double? _readDouble(Map<String, dynamic>? data, [String? key1, String? key2]) {
  if (data == null) return null;
  if (key2 != null && key1 != null) {
    final inner = data[key1];
    if (inner is Map<String, dynamic>) {
      final v = inner[key2];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    }
  }
  if (key1 != null) {
    final v = data[key1];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
  }
  return null;
}

int? _readInt(Map<String, dynamic>? data, [String? key1, String? key2]) {
  final d = _readDouble(data, key1, key2);
  return d?.round();
}

List<dynamic> _readList(Map<String, dynamic>? data, String key) {
  if (data == null) return [];
  final v = data[key];
  if (v is List) return v;
  return [];
}
