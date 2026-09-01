import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/ifta_model.dart';
import '../../../providers/ifta_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'ifta_dialogs.dart';

String _currencySymbol = 'KSh';

/// IFTA & Fuel Tax screen — mirrors the web `pages/app/ifta/index.vue` (3 tabs).
class IftaScreen extends StatefulWidget {
  const IftaScreen({super.key});

  @override
  State<IftaScreen> createState() => _IftaScreenState();
}

class _IftaScreenState extends State<IftaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Trip Logs'),
    Tab(icon: Icon(Icons.assessment_outlined, size: 18), text: 'Quarterly Reports'),
    Tab(icon: Icon(Icons.local_gas_station_outlined, size: 18), text: 'Fuel Purchases'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<IftaProvider>().refreshAll();
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
        title: const Text('IFTA & Fuel Tax'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<IftaProvider>().refreshAll(),
          ),
          IconButton(
            icon: const Icon(Icons.data_usage, size: 20),
            tooltip: 'Seed Demo Data',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Seed Demo Data'),
                  content: const Text('This will create sample IFTA data. Continue?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Seed')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                context.read<IftaProvider>().seedDemo();
              }
            },
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
      drawer: const AppDrawer(currentRoute: '/ifta'),
      body: Column(
        children: [
          // Stats + breakdown row (always visible)
          _StatsHeader(),
          // Search/filter bar
          _FilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TripLogsTab(),
                _QuartersTab(),
                _FuelPurchasesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    final index = _tabController.index;
    switch (index) {
      case 0: // Trip Logs
        return FloatingActionButton(
          heroTag: 'fab_ifta_trip',
          onPressed: () => showTripLogFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 1: // Quarterly Reports
        return FloatingActionButton(
          heroTag: 'fab_ifta_quarter',
          onPressed: () => showGenerateQuarterDialog(context),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 2: // Fuel Purchases
        return FloatingActionButton(
          heroTag: 'fab_ifta_purchase',
          onPressed: () => showFuelPurchaseFormDialog(context, null),
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
// STATS HEADER (KPI cards + breakdown row)
// ════════════════════════════════════════════════════════════
class _StatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IftaProvider>();

    if (p.statsLoading && p.stats.isEmpty) {
      return const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator());
    }

    final netTax = p.totalNetTax;
    final netTaxColor = netTax > 0 ? DomendraTheme.danger : (netTax < 0 ? DomendraTheme.success : DomendraTheme.onSurfaceMuted);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Total Miles', value: p.totalMiles.toStringAsFixed(0),
                subtitle: '${p.totalTrips} trip logs',
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                icon: Icons.map,
              )),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(
                label: 'Total Gallons', value: p.totalGallons.toStringAsFixed(1),
                subtitle: '${p.totalFuelPurchases} purchases · ${_fmtMoney(p.totalFuelCost)}',
                gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
                icon: Icons.local_gas_station,
              )),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Avg MPG', value: p.avgMpg.toStringAsFixed(1),
                subtitle: '${p.jurisdictionCount} jurisdictions',
                gradient: const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF34d399)]),
                icon: Icons.speed,
              )),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(
                label: 'Net Tax Due', value: _fmtMoney(netTax),
                subtitle: '${p.quarterCount} reports',
                gradient: LinearGradient(colors: [netTaxColor, netTaxColor.withOpacity(0.8)]),
                icon: netTax > 0 ? Icons.attach_money : Icons.money_off,
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Breakdown row
          _BreakdownRow(),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IftaProvider>();
    final byStatus = p.byStatus;
    final byQuarter = p.byQuarter;
    final byVehicle = p.byVehicle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Report Status
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DomendraTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DomendraTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.assessment_outlined, size: 14, color: DomendraTheme.primary),
                  const SizedBox(width: 4),
                  const Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                _StatusChip(label: 'Draft', count: byStatus['draft'] as int? ?? 0, color: const Color(0xFF6B7280)),
                _StatusChip(label: 'Submitted', count: byStatus['submitted'] as int? ?? 0, color: DomendraTheme.warning),
                _StatusChip(label: 'Filed', count: byStatus['filed'] as int? ?? 0, color: DomendraTheme.success),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Net Tax by Quarter
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DomendraTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DomendraTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.calendar_month, size: 14, color: DomendraTheme.primary),
                  const SizedBox(width: 4),
                  const Text('By Quarter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                if (byQuarter.isEmpty)
                  const Text('No data', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))
                else
                  ...byQuarter.entries.take(5).map((e) {
                    final v = _parseDouble(e.value);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(_fmtMoney(v), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: v > 0 ? DomendraTheme.danger : (v < 0 ? DomendraTheme.success : DomendraTheme.onSurfaceMuted))),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Trips by Vehicle
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DomendraTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DomendraTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.directions_car, size: 14, color: DomendraTheme.primary),
                  const SizedBox(width: 4),
                  const Text('By Vehicle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                if (byVehicle.isEmpty)
                  const Text('No data', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))
                else
                  ...byVehicle.take(5).map((v) {
                    final m = v is Map ? v : {};
                    final name = m['vehicle_name']?.toString() ?? '—';
                    final trips = m['trips'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('$trips', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// FILTER BAR
// ════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IftaProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          TextField(
            onChanged: p.setSearch,
            decoration: InputDecoration(
              hintText: 'Search…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              suffixIcon: p.search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => p.setSearch(''))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: p.vehicleFilter,
                  decoration: const InputDecoration(labelText: 'Vehicle', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('All Vehicles')),
                    ...p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))),
                  ],
                  onChanged: (v) => p.setVehicleFilter(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: p.jurisdictionFilter,
                  decoration: const InputDecoration(labelText: 'Jurisdiction', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('All')),
                    ...p.jurisdictions.map<DropdownMenuItem<int>>((j) => DropdownMenuItem(value: j.id, child: Text(j.code))),
                  ],
                  onChanged: (v) => p.setJurisdictionFilter(v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: p.clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 20),
                tooltip: 'Clear filters',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 1. TRIP LOGS TAB
// ════════════════════════════════════════════════════════════
class _TripLogsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IftaProvider>();

    if (p.tripLogsLoading && p.tripLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.filteredTripLogs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      children: [
        Text('${list.length} trip${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.map_outlined, message: 'No trip logs. Tap + to add one.')
        else
          ...list.map((t) => _TripLogCard(tripLog: t)),
      ],
    );
  }
}

class _TripLogCard extends StatelessWidget {
  final TripLog tripLog;
  const _TripLogCard({required this.tripLog});

  @override
  Widget build(BuildContext context) {
    final p = context.read<IftaProvider>();
    final t = tripLog;
    final tripTypeColor = t.tripType == 'loaded' ? DomendraTheme.success : (t.tripType == 'empty' ? DomendraTheme.warning : DomendraTheme.onSurfaceMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.map, size: 22, color: DomendraTheme.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.vehicleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (t.date != null) Text(_fmtDate(t.date!), style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    if (t.driverName.isNotEmpty) Text(t.driverName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      if (context.mounted) showTripLogFormDialog(context, t);
                      break;
                    case 'delete':
                      final ok = await _confirmDelete(context, 'Delete this trip log?');
                      if (ok == true && t.id != null) await p.deleteTripLog(t.id!);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Chip(label: t.jurisdictionCode, color: DomendraTheme.primary),
              _DetailPill(icon: Icons.straighten, label: '${t.distance.toStringAsFixed(0)} ${t.distanceUnit}'),
              _DetailPill(icon: Icons.speed, label: '${t.distanceMiles.toStringAsFixed(0)} mi'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: tripTypeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(t.tripTypeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tripTypeColor)),
              ),
              _DetailPill(icon: t.source == 'telematics' ? Icons.router : Icons.edit, label: t.sourceLabel),
              if (t.route.isNotEmpty) _DetailPill(icon: Icons.alt_route, label: t.route),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. QUARTERLY REPORTS TAB
// ════════════════════════════════════════════════════════════
class _QuartersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IftaProvider>();

    if (p.quartersLoading && p.quarters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.quarters;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      children: [
        Text('${list.length} report${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.assessment_outlined, message: 'No quarterly reports. Tap + to generate one.')
        else
          ...list.map((q) => _QuarterCard(quarter: q)),
      ],
    );
  }
}

class _QuarterCard extends StatelessWidget {
  final IftaQuarter quarter;
  const _QuarterCard({required this.quarter});

  @override
  Widget build(BuildContext context) {
    final p = context.read<IftaProvider>();
    final q = quarter;
    final statusColor = q.status == 'draft' ? const Color(0xFF6B7280) : (q.status == 'submitted' ? DomendraTheme.warning : DomendraTheme.success);
    final netTaxColor = q.netTax > 0 ? DomendraTheme.danger : (q.netTax < 0 ? DomendraTheme.success : DomendraTheme.onSurfaceMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.assessment_outlined, size: 22, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.vehicleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(q.label, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(q.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'breakdown':
                      if (context.mounted && q.id != null) showQuarterBreakdownDialog(context, q);
                      break;
                    case 'submit':
                      if (q.id != null) await p.saveQuarter({'status': 'submitted'}, id: q.id);
                      break;
                    case 'file':
                      if (q.id != null) await p.saveQuarter({'status': 'filed'}, id: q.id);
                      break;
                    case 'revert':
                      if (q.id != null) await p.saveQuarter({'status': 'draft'}, id: q.id);
                      break;
                    case 'regenerate':
                      if (q.vehicleId != null && context.mounted) {
                        showGenerateQuarterDialog(context, prefill: {
                          'vehicle': q.vehicleId,
                          'year': q.year,
                          'quarter': q.quarter,
                        });
                      }
                      break;
                    case 'delete':
                      final ok = await _confirmDelete(context, 'Delete this quarterly report?');
                      if (ok == true && q.id != null) await p.deleteQuarter(q.id!);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'breakdown', child: Text('View Breakdown')),
                  if (q.status == 'draft') const PopupMenuItem(value: 'submit', child: Text('Submit')),
                  if (q.status == 'submitted') const PopupMenuItem(value: 'file', child: Text('File')),
                  if (q.status != 'draft') const PopupMenuItem(value: 'revert', child: Text('Revert to Draft')),
                  const PopupMenuItem(value: 'regenerate', child: Text('Regenerate')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatMini(label: 'Miles', value: q.totalMiles.toStringAsFixed(0))),
              Expanded(child: _StatMini(label: 'Gallons', value: q.totalGallons.toStringAsFixed(1))),
              Expanded(child: _StatMini(label: 'Tax Due', value: _fmtMoney(q.totalTaxDue), color: DomendraTheme.danger)),
              Expanded(child: _StatMini(label: 'Credit', value: _fmtMoney(q.totalTaxCredit), color: DomendraTheme.success)),
              Expanded(child: _StatMini(label: 'Net', value: _fmtMoney(q.netTax), color: netTaxColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. FUEL PURCHASES TAB
// ════════════════════════════════════════════════════════════
class _FuelPurchasesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IftaProvider>();

    if (p.fuelPurchasesLoading && p.fuelPurchases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.filteredFuelPurchases;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      children: [
        Text('${list.length} purchase${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.local_gas_station_outlined, message: 'No fuel purchases. Tap + to add one.')
        else
          ...list.map((fp) => _FuelPurchaseCard(purchase: fp)),
      ],
    );
  }
}

class _FuelPurchaseCard extends StatelessWidget {
  final FuelPurchase purchase;
  const _FuelPurchaseCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final p = context.read<IftaProvider>();
    final fp = purchase;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_gas_station, size: 22, color: DomendraTheme.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fp.vehicleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(fp.date != null ? _fmtDate(fp.date!) : '—', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtMoney(fp.totalCost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${fp.gallons.toStringAsFixed(1)} gal', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      if (context.mounted) showFuelPurchaseFormDialog(context, fp);
                      break;
                    case 'delete':
                      final ok = await _confirmDelete(context, 'Delete this fuel purchase?');
                      if (ok == true && fp.id != null) await p.deleteFuelPurchase(fp.id!);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Chip(label: fp.jurisdictionCode, color: DomendraTheme.info),
              _DetailPill(icon: Icons.payments, label: _fmtMoney(fp.pricePerGallon)),
              _DetailPill(icon: Icons.receipt, label: 'Tax: ${_fmtMoney(fp.taxPaid)}'),
              if (fp.vendor.isNotEmpty) _DetailPill(icon: Icons.store_outlined, label: fp.vendor),
              _DetailPill(icon: fp.source == 'fuel_card' ? Icons.credit_card : Icons.edit, label: fp.sourceLabel),
            ],
          ),
        ],
      ),
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
  final LinearGradient gradient;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, this.subtitle = '', required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 16, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatMini({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color ?? DomendraTheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

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
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DomendraTheme.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

String _fmtMoney(double v) => '$_currencySymbol${v.toStringAsFixed(v >= 1000 ? 0 : 2)}';

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

Future<bool?> _confirmDelete(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
      ],
    ),
  );
}
