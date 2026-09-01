import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/battery_model.dart';
import '../../../providers/battery_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'battery_dialogs.dart';

/// Module-level currency symbol, populated from [DashboardProvider].
String _currencySymbol = 'KSh';

/// Battery Management screen — mirrors the web `pages/app/batteries/index.vue`.
///
/// 6 tabs: Inventory, Readings, Movements, Charge Cycles, Replacements, Analytics.
class BatteriesScreen extends StatefulWidget {
  const BatteriesScreen({super.key});

  @override
  State<BatteriesScreen> createState() => _BatteriesScreenState();
}

class _BatteriesScreenState extends State<BatteriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.battery_charging_full, size: 18), text: 'Inventory'),
    Tab(icon: Icon(Icons.show_chart, size: 18), text: 'Readings'),
    Tab(icon: Icon(Icons.swap_horiz, size: 18), text: 'Movements'),
    Tab(icon: Icon(Icons.battery_std, size: 18), text: 'Cycles'),
    Tab(icon: Icon(Icons.swap_vert, size: 18), text: 'Replacements'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<BatteryProvider>().init();
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
        title: const Text('Battery Management'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<BatteryProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/batteries'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InventoryTab(),
          _ReadingsTab(),
          _MovementsTab(),
          _CyclesTab(),
          _ReplacementsTab(),
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
          heroTag: 'fab_battery',
          onPressed: () => showBatteryFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 1: // Readings
        return FloatingActionButton(
          heroTag: 'fab_reading',
          onPressed: () => showReadingFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 3: // Cycles
        return FloatingActionButton(
          heroTag: 'fab_cycle',
          onPressed: () => showCycleFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 4: // Replacements
        return FloatingActionButton(
          heroTag: 'fab_replacement',
          onPressed: () => showReplacementFormDialog(context, null),
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
    final p = context.watch<BatteryProvider>();

    if (p.loading && p.batteries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = p.stats;
    final list = p.filteredBatteries;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Total Batteries', value: '${stats['total'] ?? 0}',
              subtitle: '${stats['brands'] ?? 0} brands · ${stats['by_chemistry'] != null ? (stats['by_chemistry'] as Map).length : 0} chemistries',
              gradient: const LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF818cf8)]),
              icon: Icons.battery_charging_full,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Installed', value: '${stats['installed'] ?? 0}',
              subtitle: '${stats['in_stock'] ?? 0} in stock · ${stats['spare'] ?? 0} spare · ${stats['charging'] ?? 0} charging',
              gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF34d399)]),
              icon: Icons.electric_car,
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Needs Replacement', value: '${stats['needs_replacement'] ?? 0}',
              subtitle: 'Avg health: ${stats['avg_health'] ?? 0}%',
              gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
              icon: Icons.warning_amber,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Retired / Scrapped', value: '${stats['retired'] ?? 0}',
              subtitle: '$_currencySymbol${(stats['inventory_value'] ?? 0).toStringAsFixed(0)} inventory value',
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
        Text('${list.length} batter${list.length == 1 ? 'y' : 'ies'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        // Battery list
        if (list.isEmpty)
          _EmptyState(icon: Icons.battery_charging_full, message: 'No batteries found. Tap + to add one.')
        else
          ...list.map((b) => _BatteryCard(battery: b)),
      ],
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final Battery battery;
  const _BatteryCard({required this.battery});

  @override
  Widget build(BuildContext context) {
    final p = context.read<BatteryProvider>();
    final statusColor = _batteryStatusColor(battery.status);
    final condColor = _batteryConditionColor(battery.condition);
    final healthColor = _healthColor(battery.healthPct);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: battery.needsReplacement ? DomendraTheme.danger.withOpacity(0.3) : DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.battery_charging_full, size: 22, color: DomendraTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(battery.serialNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${battery.brand} ${battery.model} · ${battery.voltage.toStringAsFixed(0)}V',
                      style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(battery.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'view':
                      showBatteryDetailDialog(context, battery);
                      break;
                    case 'edit':
                      if (context.mounted) showBatteryFormDialog(context, battery);
                      break;
                    case 'reading':
                      if (context.mounted) showReadingFormDialog(context, null, preBatteryId: battery.id);
                      break;
                    case 'uninstall':
                      if (context.mounted) showReasonDialog(context, action: 'uninstall', battery: battery);
                      break;
                    case 'install':
                      if (context.mounted) showInstallDialog(context, battery);
                      break;
                    case 'charge':
                      await p.chargeBattery(battery.id!);
                      break;
                    case 'retire':
                      if (context.mounted) showReasonDialog(context, action: 'retire', battery: battery);
                      break;
                    case 'delete':
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Battery'),
                          content: Text('Delete ${battery.serialNumber}? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true && battery.id != null) {
                        await p.deleteBattery(battery.id!);
                      }
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'reading', child: Text('Record Reading')),
                  if (battery.status == BatteryStatus.installed)
                    const PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
                  if (battery.status == BatteryStatus.inStock || battery.status == BatteryStatus.spare || battery.status == BatteryStatus.charging)
                    const PopupMenuItem(value: 'install', child: Text('Install')),
                  if (battery.status == BatteryStatus.inStock || battery.status == BatteryStatus.spare)
                    const PopupMenuItem(value: 'charge', child: Text('Charge')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (battery.status != BatteryStatus.retired && battery.status != BatteryStatus.scrapped)
                    const PopupMenuItem(value: 'retire', child: Text('Retire')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Health bar
          Row(
            children: [
              const Text('Health', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: battery.healthPct / 100,
                  color: healthColor,
                  backgroundColor: healthColor.withOpacity(0.1),
                  minHeight: 6,
                ),
              )),
              const SizedBox(width: 6),
              Text('${battery.healthPct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: healthColor)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _BatteryChip(label: battery.chemistryLabel, color: _chemistryColor(_chemistryToValue(battery.chemistry))),
              _BatteryChip(label: battery.conditionLabel, color: condColor),
              if (battery.vehicleName.isNotEmpty)
                _DetailPill(icon: Icons.directions_car_outlined, label: battery.vehicleName),
              if (battery.position.isNotEmpty)
                _DetailPill(icon: Icons.location_on_outlined, label: battery.position),
              if (battery.capacityAh != null)
                _DetailPill(icon: Icons.battery_std, label: '${battery.capacityAh!.toStringAsFixed(0)}Ah'),
              if (battery.cca != null)
                _DetailPill(icon: Icons.flash_on, label: '${battery.cca!.toStringAsFixed(0)} CCA'),
              if (battery.purchasePrice != null)
                _DetailPill(icon: Icons.payments, label: '$_currencySymbol${battery.purchasePrice!.toStringAsFixed(0)}'),
              if (battery.warrantyDaysLeft != null)
                _DetailPill(
                  icon: Icons.shield_outlined,
                  label: '${battery.warrantyDaysLeft}d warranty',
                  color: battery.warrantyDaysLeft! < 30 ? DomendraTheme.danger : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _chemistryToValue(BatteryChemistry c) {
  switch (c) {
    case BatteryChemistry.leadAcid: return 'lead_acid';
    case BatteryChemistry.agm: return 'agm';
    case BatteryChemistry.gel: return 'gel';
    case BatteryChemistry.liIon: return 'li_ion';
    case BatteryChemistry.lifepo4: return 'lifepo4';
    case BatteryChemistry.nicd: return 'nicd';
    case BatteryChemistry.nimh: return 'nimh';
  }
}

class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<BatteryProvider>();
    return Column(
      children: [
        TextField(
          onChanged: p.setSearch,
          decoration: InputDecoration(
            hintText: 'Search batteries…',
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
                items: const ['in_stock', 'installed', 'spare', 'charging', 'retired', 'scrapped'],
                labels: const {'in_stock': 'In Stock', 'installed': 'Installed', 'spare': 'Spare', 'charging': 'Charging', 'retired': 'Retired', 'scrapped': 'Scrapped'},
                selected: p.statusFilter,
                onSelected: p.setStatusFilter,
              ),
              const SizedBox(width: 8),
              _FilterChipBtn(
                label: 'Chemistry',
                items: const ['lead_acid', 'agm', 'gel', 'li_ion', 'lifepo4', 'nicd', 'nimh'],
                labels: const {'lead_acid': 'Lead-Acid', 'agm': 'AGM', 'gel': 'Gel', 'li_ion': 'Lithium-Ion', 'lifepo4': 'LiFePO4', 'nicd': 'NiCd', 'nimh': 'NiMH'},
                selected: p.chemistryFilter,
                onSelected: p.setChemistryFilter,
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
// 2. READINGS TAB
// ════════════════════════════════════════════════════════════
class _ReadingsTab extends StatefulWidget {
  @override
  State<_ReadingsTab> createState() => _ReadingsTabState();
}

class _ReadingsTabState extends State<_ReadingsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BatteryProvider>().refreshReadings();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<BatteryProvider>();
    final list = p.readings;

    if (p.readingsLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.show_chart, message: 'No readings recorded yet.')
        else
          ...list.map((r) => _ReadingCard(reading: r)),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final BatteryReading reading;
  const _ReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final p = context.read<BatteryProvider>();
    final vColor = _voltageColor(reading.voltage);
    final hColor = _healthColor(reading.healthPct);
    final trColor = _testResultColor(reading.testResult);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.show_chart, size: 18, color: DomendraTheme.info),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reading.batterySerial.isEmpty ? '#${reading.batteryId}' : reading.batterySerial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    if (reading.vehicleName.isNotEmpty) ...[
                      Text(reading.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      const SizedBox(width: 8),
                    ],
                    Text('${reading.voltage.toStringAsFixed(2)}V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: vColor)),
                    const SizedBox(width: 8),
                    Text('${reading.healthPct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: hColor)),
                  ],
                ),
                Text(_fmtDate(reading.measuredAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: trColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(reading.testResult[0].toUpperCase() + reading.testResult.substring(1),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: trColor)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(onTap: () => showReadingFormDialog(context, reading), child: const Icon(Icons.edit_outlined, size: 16, color: DomendraTheme.warning)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (reading.id == null) return;
                      await p.deleteReading(reading.id!);
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
// 3. MOVEMENTS TAB
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
      context.read<BatteryProvider>().refreshMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<BatteryProvider>();
    final list = p.movements;

    if (p.movementsLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.swap_horiz, message: 'No movement history yet.')
        else
          ...list.map((m) => _MovementCard(movement: m)),
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  final BatteryMovement movement;
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
            child: Icon(Icons.swap_horiz, size: 18, color: moveColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.batterySerial.isEmpty ? '#${movement.batteryId}' : movement.batterySerial,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    _BatteryChip(label: movement.movementTypeLabel, color: moveColor),
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
// 4. CHARGE CYCLES TAB
// ════════════════════════════════════════════════════════════
class _CyclesTab extends StatefulWidget {
  @override
  State<_CyclesTab> createState() => _CyclesTabState();
}

class _CyclesTabState extends State<_CyclesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BatteryProvider>().refreshCycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<BatteryProvider>();
    final list = p.cycles;

    if (p.cyclesLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.battery_std, message: 'No charge cycles recorded yet.')
        else
          ...list.map((c) => _CycleCard(cycle: c)),
      ],
    );
  }
}

class _CycleCard extends StatelessWidget {
  final ChargeCycle cycle;
  const _CycleCard({required this.cycle});

  @override
  Widget build(BuildContext context) {
    final p = context.read<BatteryProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFF8b5cf6).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.battery_std, size: 18, color: Color(0xFF8b5cf6)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cycle.batterySerial.isEmpty ? '#${cycle.batteryId}' : cycle.batterySerial,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    _BatteryChip(label: cycle.chargeMethodLabel, color: const Color(0xFF8b5cf6)),
                    const SizedBox(width: 8),
                    if (cycle.startVoltage != null)
                      Text('${cycle.startVoltage!.toStringAsFixed(1)}V', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    if (cycle.endVoltage != null) ...[
                      const Icon(Icons.arrow_forward, size: 12, color: DomendraTheme.onSurfaceMuted),
                      Text('${cycle.endVoltage!.toStringAsFixed(1)}V', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    ],
                    if (cycle.energyKwh != null)
                      Text(' · ${cycle.energyKwh!.toStringAsFixed(1)} kWh', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
                Text(_fmtDateTime(cycle.completedAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(onTap: () => showCycleFormDialog(context, cycle), child: const Icon(Icons.edit_outlined, size: 16, color: DomendraTheme.warning)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  if (cycle.id == null) return;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Cycle'),
                      content: const Text('Delete this charge cycle?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) await p.deleteCycle(cycle.id!);
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
// 5. REPLACEMENTS TAB
// ════════════════════════════════════════════════════════════
class _ReplacementsTab extends StatefulWidget {
  @override
  State<_ReplacementsTab> createState() => _ReplacementsTabState();
}

class _ReplacementsTabState extends State<_ReplacementsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BatteryProvider>().refreshReplacements();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<BatteryProvider>();
    final list = p.replacements;

    if (p.replacementsLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (list.isEmpty)
          _EmptyState(icon: Icons.swap_vert, message: 'No replacements recorded yet.')
        else
          ...list.map((r) => _ReplacementCard(replacement: r)),
      ],
    );
  }
}

class _ReplacementCard extends StatelessWidget {
  final BatteryReplacement replacement;
  const _ReplacementCard({required this.replacement});

  @override
  Widget build(BuildContext context) {
    final p = context.read<BatteryProvider>();
    final statusColor = _replacementStatusColor(replacement.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.swap_vert, size: 18, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(replacement.batterySerial.isEmpty ? '#${replacement.batteryId}' : replacement.batterySerial,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    _BatteryChip(label: replacement.status[0].toUpperCase() + replacement.status.substring(1), color: statusColor),
                    const SizedBox(width: 8),
                    if (replacement.vehicleName.isNotEmpty)
                      Text(replacement.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
                Row(
                  children: [
                    if (replacement.scheduledDate != null)
                      Text('Sched: ${_fmtDate(replacement.scheduledDate)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    if (replacement.completedDate != null) ...[
                      const SizedBox(width: 8),
                      Text('Done: ${_fmtDate(replacement.completedDate)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    ],
                    if (replacement.estimatedCost != null) ...[
                      const SizedBox(width: 8),
                      Text('$_currencySymbol${replacement.estimatedCost!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ],
                ),
                if (replacement.reason.isNotEmpty)
                  Text(replacement.reason, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(onTap: () => showReplacementFormDialog(context, replacement), child: const Icon(Icons.edit_outlined, size: 16, color: DomendraTheme.warning)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  if (replacement.id == null) return;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Replacement'),
                      content: const Text('Delete this replacement record?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) await p.deleteReplacement(replacement.id!);
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
// 6. ANALYTICS TAB
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<BatteryProvider>();
    final stats = p.stats;
    final needsReplacement = p.needsReplacementBatteries;

    // Chemistry distribution
    final byChemistry = <String, int>{};
    final raw = stats['by_chemistry'] as Map?;
    if (raw != null) {
      raw.forEach((k, v) { byChemistry[k.toString()] = v as int; });
    }
    for (final b in p.batteries) {
      if (b.chemistryLabel.isNotEmpty) {
        byChemistry[b.chemistryLabel] = (byChemistry[b.chemistryLabel] ?? 0) + 1;
      }
    }

    // Condition distribution
    final byCondition = <String, int>{};
    final rawCond = stats['by_condition'] as Map?;
    if (rawCond != null) {
      rawCond.forEach((k, v) { byCondition[k.toString()] = v as int; });
    }
    for (final b in p.batteries) {
      byCondition[b.conditionLabel] = (byCondition[b.conditionLabel] ?? 0) + 1;
    }

    // Status distribution
    final statusCounts = <String, int>{};
    for (final b in p.batteries) {
      statusCounts[b.statusLabel] = (statusCounts[b.statusLabel] ?? 0) + 1;
    }

    // Brand distribution
    final brandCounts = <String, int>{};
    for (final b in p.batteries) {
      if (b.brand.isNotEmpty) {
        brandCounts[b.brand] = (brandCounts[b.brand] ?? 0) + 1;
      }
    }
    final topBrands = brandCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5Brands = topBrands.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // Status distribution
        if (statusCounts.isNotEmpty) ...[
          _AnalyticsCard(
            title: 'Status Distribution', icon: Icons.pie_chart_outline,
            child: _DistributionBars(data: statusCounts, colors: {
              'In Stock': const Color(0xFF10b981),
              'Installed': const Color(0xFF3b82f6),
              'Spare': const Color(0xFFf59e0b),
              'Charging': const Color(0xFF8b5cf6),
              'Retired': const Color(0xFFef4444),
              'Scrapped': const Color(0xFF6b7280),
            }),
          ),
          const SizedBox(height: 12),
        ],
        // Chemistry breakdown
        if (byChemistry.isNotEmpty) ...[
          _AnalyticsCard(
            title: 'By Chemistry', icon: Icons.science_outlined,
            child: _DistributionBars(data: byChemistry, colors: const {}),
          ),
          const SizedBox(height: 12),
        ],
        // Condition breakdown
        if (byCondition.isNotEmpty) ...[
          _AnalyticsCard(
            title: 'By Condition', icon: Icons.battery_alert,
            child: _DistributionBars(data: byCondition, colors: {
              'New': const Color(0xFF10b981),
              'Excellent': const Color(0xFF22c55e),
              'Good': const Color(0xFF84cc16),
              'Fair': const Color(0xFFf59e0b),
              'Poor': const Color(0xFFef4444),
              'Damaged': const Color(0xFFdc2626),
            }),
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
                    Text('All batteries are in good condition.', style: TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
                  ],
                )
              else
                ...needsReplacement.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.serialNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('${b.brand} ${b.model} · ${b.vehicleName.isEmpty ? 'In stock' : b.vehicleName}',
                              style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: DomendraTheme.danger, borderRadius: BorderRadius.circular(10)),
                        child: Text('${b.healthPct.toStringAsFixed(0)}%',
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

class _BatteryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BatteryChip({required this.label, required this.color});

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

String _fmtDateTime(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

Color _batteryStatusColor(BatteryStatus status) {
  switch (status) {
    case BatteryStatus.inStock: return const Color(0xFF10b981);
    case BatteryStatus.installed: return const Color(0xFF3b82f6);
    case BatteryStatus.spare: return const Color(0xFFf59e0b);
    case BatteryStatus.charging: return const Color(0xFF8b5cf6);
    case BatteryStatus.retired: return const Color(0xFFef4444);
    case BatteryStatus.scrapped: return const Color(0xFF6b7280);
  }
}

Color _batteryConditionColor(BatteryCondition cond) {
  switch (cond) {
    case BatteryCondition.newBattery: return const Color(0xFF10b981);
    case BatteryCondition.excellent: return const Color(0xFF22c55e);
    case BatteryCondition.good: return const Color(0xFF84cc16);
    case BatteryCondition.fair: return const Color(0xFFf59e0b);
    case BatteryCondition.poor: return const Color(0xFFef4444);
    case BatteryCondition.damaged: return const Color(0xFFdc2626);
  }
}

Color _voltageColor(double v) {
  if (v >= 12.5) return const Color(0xFF10b981);
  if (v >= 12.0) return const Color(0xFFf59e0b);
  return const Color(0xFFef4444);
}

Color _healthColor(double v) {
  if (v >= 80) return const Color(0xFF10b981);
  if (v >= 60) return const Color(0xFFf59e0b);
  return const Color(0xFFef4444);
}

Color _testResultColor(String v) {
  switch (v) {
    case 'pass': return const Color(0xFF10b981);
    case 'marginal': return const Color(0xFFf59e0b);
    case 'fail': return const Color(0xFFef4444);
    case 'charge': return const Color(0xFF3b82f6);
    default: return const Color(0xFF6b7280);
  }
}

Color _chemistryColor(String v) {
  switch (v) {
    case 'lead_acid': return const Color(0xFF6366f1);
    case 'agm': return const Color(0xFF3b82f6);
    case 'gel': return const Color(0xFF8b5cf6);
    case 'li_ion': return const Color(0xFF10b981);
    case 'lifepo4': return const Color(0xFF22c55e);
    case 'nicd': return const Color(0xFFf59e0b);
    case 'nimh': return const Color(0xFFec4899);
    default: return const Color(0xFF6b7280);
  }
}

Color _movementTypeColor(BatteryMovementType type) {
  switch (type) {
    case BatteryMovementType.install: return const Color(0xFF10b981);
    case BatteryMovementType.uninstall: return const Color(0xFFf59e0b);
    case BatteryMovementType.swap: return const Color(0xFF3b82f6);
    case BatteryMovementType.charge: return const Color(0xFF8b5cf6);
    case BatteryMovementType.retire: return const Color(0xFFef4444);
  }
}

Color _replacementStatusColor(String v) {
  switch (v.toLowerCase()) {
    case 'scheduled': return const Color(0xFFf59e0b);
    case 'ordered': return const Color(0xFF3b82f6);
    case 'completed': return const Color(0xFF10b981);
    case 'cancelled': return const Color(0xFFef4444);
    default: return const Color(0xFF6b7280);
  }
}
