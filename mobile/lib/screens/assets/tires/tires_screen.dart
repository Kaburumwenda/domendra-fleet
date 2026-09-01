import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/tire_model.dart';
import '../../../providers/tire_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'tire_dialogs.dart';

/// Module-level currency symbol, populated from [DashboardProvider].
String _currencySymbol = 'KSh';

/// Tire Management screen — mirrors the web `pages/app/tires/index.vue`.
///
/// 5 tabs: Inventory, Inspections, Rotations, Movements, Analytics.
class TiresScreen extends StatefulWidget {
  const TiresScreen({super.key});

  @override
  State<TiresScreen> createState() => _TiresScreenState();
}

class _TiresScreenState extends State<TiresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.tire_repair, size: 18), text: 'Inventory'),
    Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'Inspections'),
    Tab(icon: Icon(Icons.swap_horiz, size: 18), text: 'Rotations'),
    Tab(icon: Icon(Icons.import_export, size: 18), text: 'Movements'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<TireProvider>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Tire Management'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<TireProvider>().init(),
          ),
        ],
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
      drawer: const AppDrawer(currentRoute: '/tires'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InventoryTab(),
          _InspectionsTab(),
          _RotationsTab(),
          _MovementsTab(),
          _AnalyticsTab(),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    final index = _tabController.index;
    switch (index) {
      case 0: // Inventory
        return FloatingActionButton(
          heroTag: 'fab_tire',
          onPressed: () => showTireFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 1: // Inspections
        return FloatingActionButton(
          heroTag: 'fab_inspection',
          onPressed: () => showInspectionFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 2: // Rotations
        return FloatingActionButton(
          heroTag: 'fab_rotation',
          onPressed: () => showRotationFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ════════════════════════════════════════════════════════════
// 1. INVENTORY TAB
// ════════════════════════════════════════════════════════════
class _InventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TireProvider>();

    if (p.loading && p.tires.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = p.stats;
    final list = p.filteredTires;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Total Tires', value: '${stats['total']}',
              subtitle: '${stats['brands']} brands · ${stats['sizes']} sizes',
              gradient: const LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF818cf8)]),
              icon: Icons.tire_repair,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Mounted', value: '${stats['mounted']}',
              subtitle: '${stats['inStock']} in stock · ${stats['spare']} spare',
              gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF34d399)]),
              icon: Icons.directions_car,
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Needs Replacement', value: '${stats['needsReplacement']}',
              subtitle: 'Tread at or below threshold',
              gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
              icon: Icons.warning_amber,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Retired / Scrapped', value: '${stats['retired']}',
              subtitle: '$_currencySymbol${(stats['inventoryValue'] as double).toStringAsFixed(0)} inventory value',
              gradient: const LinearGradient(colors: [Color(0xFFef4444), Color(0xFFf87171)]),
              icon: Icons.archive_outlined,
            )),
          ],
        ),
        const SizedBox(height: 16),
        // Search + Filters
        _FilterBar(),
        const SizedBox(height: 8),
        // Count
        Text('${list.length} tire${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        // Tire list
        if (list.isEmpty)
          _EmptyState(icon: Icons.tire_repair, message: 'No tires found. Tap + to add one.')
        else
          ...list.map((t) => _TireCard(tire: t)),
      ],
    );
  }
}

class _TireCard extends StatelessWidget {
  final Tire tire;
  const _TireCard({required this.tire});

  @override
  Widget build(BuildContext context) {
    final p = context.read<TireProvider>();
    final statusColor = _tireStatusColor(tire.status);
    final condColor = _tireConditionColor(tire.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tire.needsReplacement ? DomendraTheme.danger.withOpacity(0.3) : DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tire_repair, size: 22, color: DomendraTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tire.serialNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${tire.brand} ${tire.model} · ${tire.size.isEmpty ? '—' : tire.size}',
                      style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(tire.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'view':
                      showTireDetailDialog(context, tire);
                      break;
                    case 'edit':
                      if (context.mounted) showTireFormDialog(context, tire);
                      break;
                    case 'unmount':
                      if (context.mounted) showReasonDialog(context, action: 'unmount', tire: tire);
                      break;
                    case 'mount':
                      if (context.mounted) showMountDialog(context, tire);
                      break;
                    case 'retire':
                      if (context.mounted) showReasonDialog(context, action: 'retire', tire: tire);
                      break;
                    case 'delete':
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Tire'),
                          content: Text('Delete ${tire.serialNumber}? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true && tire.id != null) {
                        await p.deleteTire(tire.id!);
                      }
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (tire.status == TireStatus.mounted)
                    const PopupMenuItem(value: 'unmount', child: Text('Unmount')),
                  if (tire.status == TireStatus.inStock || tire.status == TireStatus.spare)
                    const PopupMenuItem(value: 'mount', child: Text('Mount')),
                  if (tire.status != TireStatus.retired && tire.status != TireStatus.scrapped)
                    const PopupMenuItem(value: 'retire', child: Text('Retire')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              if (tire.type.isNotEmpty)
                _TireChip(label: tire.type, color: DomendraTheme.info),
              _TireChip(label: tire.conditionLabel, color: condColor),
              if (tire.vehicleName.isNotEmpty)
                _DetailPill(icon: Icons.directions_car_outlined, label: tire.vehicleName),
              if (tire.position.isNotEmpty)
                _DetailPill(icon: Icons.location_on_outlined, label: tire.position),
              if (tire.latestTreadDepth != null)
                _DetailPill(
                  icon: Icons.straighten,
                  label: '${tire.latestTreadDepth!.toStringAsFixed(1)}/32"',
                  color: tire.needsReplacement ? DomendraTheme.danger : null,
                ),
              if (tire.purchasePrice != null)
                _DetailPill(icon: Icons.payments, label: '$_currencySymbol${tire.purchasePrice!.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TireProvider>();
    return Column(
      children: [
        TextField(
          onChanged: p.setSearch,
          decoration: InputDecoration(
            hintText: 'Search tires…',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            suffixIcon: p.search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => p.setSearch('')) : null,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChipBtn(
                label: 'Status',
                items: const ['in_stock', 'mounted', 'spare', 'retired', 'scrapped'],
                labels: const {'in_stock': 'In Stock', 'mounted': 'Mounted', 'spare': 'Spare', 'retired': 'Retired', 'scrapped': 'Scrapped'},
                selected: p.statusFilter,
                onSelected: p.setStatusFilter,
              ),
              const SizedBox(width: 8),
              _FilterChipBtn(
                label: 'Condition',
                items: const ['new', 'second_hand', 'retreaded', 'reclaimed', 'used'],
                labels: const {'new': 'New', 'second_hand': 'Second Hand', 'retreaded': 'Retreaded', 'reclaimed': 'Reclaimed', 'used': 'Used'},
                selected: p.conditionFilter,
                onSelected: p.setConditionFilter,
              ),
              const SizedBox(width: 8),
              if (p.brandOptions.isNotEmpty)
                _FilterDropdown(
                  label: 'Brand',
                  value: p.brandFilter,
                  items: p.brandOptions,
                  onChanged: p.setBrandFilter,
                ),
              if (p.activeFilterCount > 0) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: Text('Clear (${p.activeFilterCount})', style: const TextStyle(fontSize: 11)),
                  onPressed: p.clearFilters,
                  backgroundColor: DomendraTheme.danger.withOpacity(0.1),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. INSPECTIONS TAB
// ════════════════════════════════════════════════════════════
class _InspectionsTab extends StatefulWidget {
  @override
  State<_InspectionsTab> createState() => _InspectionsTabState();
}

class _InspectionsTabState extends State<_InspectionsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TireProvider>().refreshInspections();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<TireProvider>();
    final list = p.inspections;

    if (p.inspectionsLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.fact_check_outlined, message: 'No inspections recorded yet.')
        else
          ...list.map((ins) => _InspectionCard(inspection: ins)),
      ],
    );
  }
}

class _InspectionCard extends StatelessWidget {
  final TireInspection inspection;
  const _InspectionCard({required this.inspection});

  @override
  Widget build(BuildContext context) {
    final p = context.read<TireProvider>();
    final condColor = _inspectionConditionColor(inspection.condition);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.fact_check_outlined, size: 18, color: DomendraTheme.info),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inspection.tireSerial.isEmpty ? '#${inspection.tireId}' : inspection.tireSerial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    if (inspection.vehicleName.isNotEmpty)
                      Text(inspection.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    if (inspection.vehicleName.isNotEmpty) const SizedBox(width: 8),
                    Text('${inspection.treadDepth.toStringAsFixed(1)}/32"', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    if (inspection.pressurePsi != null) ...[
                      const SizedBox(width: 8),
                      Text('${inspection.pressurePsi!.toStringAsFixed(1)} psi', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ],
                ),
                Text(_fmtDate(inspection.measuredAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: condColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(inspection.condition.isEmpty ? 'OK' : inspection.condition[0].toUpperCase() + inspection.condition.substring(1),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: condColor)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(onTap: () => showInspectionFormDialog(context, inspection), child: const Icon(Icons.edit_outlined, size: 16, color: DomendraTheme.warning)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (inspection.id == null) return;
                      await p.deleteInspection(inspection.id!);
                    },
                    child: const Icon(Icons.delete_outline, size: 16, color: DomendraTheme.danger),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. ROTATIONS TAB
// ════════════════════════════════════════════════════════════
class _RotationsTab extends StatefulWidget {
  @override
  State<_RotationsTab> createState() => _RotationsTabState();
}

class _RotationsTabState extends State<_RotationsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TireProvider>().refreshRotations();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<TireProvider>();
    final list = p.rotations;

    if (p.rotationsLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.swap_horiz, message: 'No rotations logged yet.')
        else
          ...list.map((r) => _RotationCard(rotation: r)),
      ],
    );
  }
}

class _RotationCard extends StatelessWidget {
  final TireRotation rotation;
  const _RotationCard({required this.rotation});

  @override
  Widget build(BuildContext context) {
    final p = context.read<TireProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.swap_horiz, size: 18, color: DomendraTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotation.vehicleName.isEmpty ? 'Vehicle #${rotation.vehicleId}' : rotation.vehicleName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Wrap(
                  spacing: 8,
                  children: [
                    if (rotation.rotationPattern.isNotEmpty)
                      _TireChip(label: rotation.rotationPattern, color: DomendraTheme.primary),
                    Text('${rotation.swaps.length} swaps', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    if (rotation.odometer != null)
                      Text('${rotation.odometer!.toStringAsFixed(0)} mi', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    Text(_fmtDate(rotation.performedAt), style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
                if (rotation.notes.isNotEmpty)
                  Text(rotation.notes, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(onTap: () => showRotationDetailDialog(context, rotation), child: const Icon(Icons.visibility_outlined, size: 16, color: DomendraTheme.info)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  if (rotation.id == null) return;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Rotation'),
                      content: const Text('Delete this rotation record?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) await p.deleteRotation(rotation.id!);
                },
                child: const Icon(Icons.delete_outline, size: 16, color: DomendraTheme.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. MOVEMENTS TAB
// ════════════════════════════════════════════════════════════
class _MovementsTab extends StatefulWidget {
  @override
  State<_MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends State<_MovementsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TireProvider>().refreshMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<TireProvider>();
    final list = p.movements;

    if (p.movementsLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.import_export, message: 'No movement history yet.')
        else
          ...list.map((m) => _MovementCard(movement: m)),
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  final TireMovement movement;
  const _MovementCard({required this.movement});

  @override
  Widget build(BuildContext context) {
    final moveColor = _movementTypeColor(movement.movementType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: moveColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.import_export, size: 18, color: moveColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.tireSerial.isEmpty ? '#${movement.tireId}' : movement.tireSerial,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    _TireChip(label: movement.movementTypeLabel, color: moveColor),
                    const SizedBox(width: 8),
                    if (movement.fromVehicleName.isNotEmpty || movement.fromPosition.isNotEmpty)
                      Expanded(child: Text('${movement.fromVehicleName} ${movement.fromPosition}'.trim(),
                        style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (movement.toVehicleName.isNotEmpty || movement.toPosition.isNotEmpty) ...[
                      const Icon(Icons.arrow_forward, size: 12, color: DomendraTheme.onSurfaceMuted),
                      Expanded(child: Text('${movement.toVehicleName} ${movement.toPosition}'.trim(),
                        style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
                Text(_fmtDate(movement.performedAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 5. ANALYTICS TAB
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TireProvider>();
    final stats = p.stats;
    final needsReplacement = p.needsReplacementTires;

    // Status distribution
    final statusCounts = <String, int>{
      'In Stock': stats['inStock'] as int,
      'Mounted': stats['mounted'] as int,
      'Spare': stats['spare'] as int,
      'Retired/Scrapped': stats['retired'] as int,
    };

    // Brand distribution
    final brandCounts = <String, int>{};
    for (final t in p.tires) {
      if (t.brand.isNotEmpty) {
        brandCounts[t.brand] = (brandCounts[t.brand] ?? 0) + 1;
      }
    }
    final topBrands = brandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Brands = topBrands.take(5).toList();

    // Type distribution
    final typeCounts = <String, int>{};
    for (final t in p.tires) {
      if (t.type.isNotEmpty) {
        typeCounts[t.type] = (typeCounts[t.type] ?? 0) + 1;
      }
    }

    // Tread health buckets
    int goodCount = 0, warningCount = 0, criticalCount = 0, noDataCount = 0;
    for (final t in p.tires) {
      if (t.latestTreadDepth == null) {
        noDataCount++;
      } else if (t.needsReplacement) {
        criticalCount++;
      } else if (t.latestTreadDepth! <= t.minTreadDepth + 2) {
        warningCount++;
      } else {
        goodCount++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // Status distribution
        _AnalyticsCard(
          title: 'Status Distribution', icon: Icons.pie_chart_outline,
          child: _DistributionBars(data: statusCounts, colors: {
            'In Stock': const Color(0xFF94a3b8),
            'Mounted': DomendraTheme.success,
            'Spare': DomendraTheme.info,
            'Retired/Scrapped': DomendraTheme.danger,
          }),
        ),
        const SizedBox(height: 12),
        // Type breakdown
        if (typeCounts.isNotEmpty) ...[
          _AnalyticsCard(
            title: 'Tire Type Breakdown', icon: Icons.directions_car,
            child: _DistributionBars(data: typeCounts, colors: const {}),
          ),
          const SizedBox(height: 12),
        ],
        // Top brands
        if (top5Brands.isNotEmpty) ...[
          _AnalyticsCard(
            title: 'Top Brands', icon: Icons.factory_outlined,
            child: _DistributionBars(
              data: {for (final e in top5Brands) e.key: e.value},
              colors: const {},
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Tread health
        _AnalyticsCard(
          title: 'Tread Health Distribution', icon: Icons.bar_chart,
          child: _DistributionBars(data: {
            'Good': goodCount,
            'Warning': warningCount,
            'Critical': criticalCount,
            'No Data': noDataCount,
          }, colors: {
            'Good': DomendraTheme.success,
            'Warning': DomendraTheme.warning,
            'Critical': DomendraTheme.danger,
            'No Data': DomendraTheme.onSurfaceMuted,
          }),
        ),
        const SizedBox(height: 12),
        // Needs replacement list
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.danger.withOpacity(0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber, size: 18, color: DomendraTheme.danger),
                  const SizedBox(width: 6),
                  const Text('Needs Replacement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              if (needsReplacement.isEmpty)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: DomendraTheme.success, size: 20),
                    SizedBox(width: 8),
                    Text('All tires are within safe tread depth.', style: TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
                  ],
                )
              else
                ...needsReplacement.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.serialNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('${t.brand} ${t.size} · ${t.vehicleName.isEmpty ? 'In stock' : t.vehicleName}',
                              style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: DomendraTheme.danger, borderRadius: BorderRadius.circular(10)),
                        child: Text('${t.latestTreadDepth!.toStringAsFixed(1)}/32"',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Gradient gradient;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.subtitle, required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500))]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _TireChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TireChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _DetailPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? DomendraTheme.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color ?? DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  final String label;
  final List<String> items;
  final Map<String, String> labels;
  final List<String> selected;
  final ValueChanged<List<String>> onSelected;

  const _FilterChipBtn({required this.label, required this.items, required this.labels, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected.isNotEmpty ? Colors.white : DomendraTheme.onSurfaceMuted)),
      selected: selected.isNotEmpty,
      onSelected: (_) => _showDialog(context),
      selectedColor: DomendraTheme.primary,
      backgroundColor: DomendraTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final tempSelected = List<String>.from(selected);
        return StatefulBuilder(builder: (ctx, setDialog) {
          return AlertDialog(
            title: Text(label),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected = tempSelected.contains(item);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(labels[item] ?? item),
                    onChanged: (v) {
                      if (v == true) {
                        tempSelected.add(item);
                      } else {
                        tempSelected.remove(item);
                      }
                      setDialog(() {});
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: () { onSelected(tempSelected); Navigator.pop(ctx); }, child: const Text('Apply')),
            ],
          );
        });
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(20)),
      child: DropdownButton<String>(
        value: value,
        hint: Text(label, style: const TextStyle(fontSize: 11)),
        underline: const SizedBox(),
        isDense: true,
        items: [const DropdownMenuItem(value: null, child: Text('All Brands')), ...items.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 11))))],
        onChanged: onChanged,
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _AnalyticsCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 18, color: DomendraTheme.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DistributionBars extends StatelessWidget {
  final Map<String, int> data;
  final Map<String, Color> colors;
  const _DistributionBars({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const Text('No data', style: TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted));
    final palette = [DomendraTheme.primary, DomendraTheme.success, DomendraTheme.warning, DomendraTheme.danger, DomendraTheme.info, DomendraTheme.onSurfaceMuted];
    int colorIdx = 0;

    return Column(
      children: data.entries.map((e) {
        final color = colors[e.key] ?? palette[colorIdx++ % palette.length];
        final pct = maxVal > 0 ? (e.value / maxVal) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(e.key, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: color.withOpacity(0.1),
                    color: color,
                    minHeight: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 28, child: Text('${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════════════════
String _fmtDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

Color _tireStatusColor(TireStatus status) {
  switch (status) {
    case TireStatus.inStock: return const Color(0xFF94a3b8);
    case TireStatus.mounted: return DomendraTheme.success;
    case TireStatus.spare: return DomendraTheme.info;
    case TireStatus.retired: return DomendraTheme.danger;
    case TireStatus.scrapped: return const Color(0xFF475569);
  }
}

Color _tireConditionColor(TireCondition cond) {
  switch (cond) {
    case TireCondition.newTire: return DomendraTheme.success;
    case TireCondition.secondHand: return DomendraTheme.warning;
    case TireCondition.retreaded: return const Color(0xFF8b5cf6);
    case TireCondition.reclaimed: return const Color(0xFF14b8a6);
    case TireCondition.used: return DomendraTheme.warning;
  }
}

Color _inspectionConditionColor(String cond) {
  switch (cond) {
    case 'good': return DomendraTheme.success;
    case 'ok': return DomendraTheme.info;
    case 'worn': return DomendraTheme.warning;
    case 'damaged': return DomendraTheme.danger;
    default: return DomendraTheme.onSurfaceMuted;
  }
}

Color _movementTypeColor(TireMovementType type) {
  switch (type) {
    case TireMovementType.mount: return DomendraTheme.success;
    case TireMovementType.unmount: return DomendraTheme.warning;
    case TireMovementType.transfer: return DomendraTheme.info;
    case TireMovementType.retread: return const Color(0xFF8b5cf6);
  }
}
