import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Vehicle Analytics screen — mirrors `pages/app/analytics/vehicles.vue`.
/// 7 tabs: Composition, Value & Mileage, Utilization, Cost & Depreciation,
/// Fleet Health, Lifecycle, ABC Analysis.
class VehicleAnalyticsScreen extends StatefulWidget {
  const VehicleAnalyticsScreen({super.key});

  @override
  State<VehicleAnalyticsScreen> createState() => _VehicleAnalyticsScreenState();
}

class _VehicleAnalyticsScreenState extends State<VehicleAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.pie_chart_outline, size: 18), text: 'Composition'),
    Tab(icon: Icon(Icons.monetization_on_outlined, size: 18), text: 'Value & Mileage'),
    Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Utilization'),
    Tab(icon: Icon(Icons.trending_down, size: 18), text: 'Cost & Depreciation'),
    Tab(icon: Icon(Icons.health_and_safety_outlined, size: 18), text: 'Fleet Health'),
    Tab(icon: Icon(Icons.timeline, size: 18), text: 'Lifecycle'),
    Tab(icon: Icon(Icons.insights_outlined, size: 18), text: 'ABC Analysis'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<AnalyticsProvider>().fetchVehicleAnalytics();
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
        title: const Text('Vehicle Analytics'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<AnalyticsProvider>().fetchVehicleAnalytics(),
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
      drawer: const AppDrawer(currentRoute: '/analytics/vehicles'),
      body: Column(
        children: [
          _PeriodBar(onChanged: () => context.read<AnalyticsProvider>().fetchVehicleAnalytics()),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CompositionTab(),
                _ValueMileageTab(),
                _UtilizationTab(),
                _CostDepreciationTab(),
                _FleetHealthTab(),
                _LifecycleTab(),
                _AbcTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// PERIOD BAR
// ════════════════════════════════════════════════════════════
class _PeriodBar extends StatelessWidget {
  final VoidCallback onChanged;
  const _PeriodBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PeriodChip(label: 'All', value: 'all', groupValue: p.vehiclePeriod, onSel: (v) { p.setVehiclePeriod(v); onChanged(); }),
                  _PeriodChip(label: 'Yr', value: 'y', groupValue: p.vehiclePeriod, onSel: (v) { p.setVehiclePeriod(v); onChanged(); }),
                  _PeriodChip(label: '365d', value: '365', groupValue: p.vehiclePeriod, onSel: (v) { p.setVehiclePeriod(v); onChanged(); }),
                  _PeriodChip(label: '90d', value: '90', groupValue: p.vehiclePeriod, onSel: (v) { p.setVehiclePeriod(v); onChanged(); }),
                  _PeriodChip(label: 'Custom…', value: 'custom', groupValue: p.vehiclePeriod, onSel: (v) {
                    p.setVehiclePeriod(v);
                    _showCustomDateDialog(context, isVehicle: true, onChanged: onChanged);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showCustomDateDialog(BuildContext context, {required bool isVehicle, required VoidCallback onChanged}) {
  final p = context.read<AnalyticsProvider>();
  DateTime? from = isVehicle ? p.vehicleCustomFrom : p.rentalCustomFrom;
  DateTime? to = isVehicle ? p.vehicleCustomTo : p.rentalCustomTo;
  DateTime? tempFrom = from ?? DateTime.now().subtract(const Duration(days: 365));
  DateTime? tempTo = to ?? DateTime.now();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: const Row(children: [Icon(Icons.calendar_month, size: 20), SizedBox(width: 8), Text('Custom Date Range')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('From'),
              subtitle: Text(tempFrom != null ? _fmtDate(tempFrom!) : '—'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: tempFrom ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) setDialog(() => tempFrom = d);
              },
            ),
            ListTile(
              title: const Text('To'),
              subtitle: Text(tempTo != null ? _fmtDate(tempTo!) : '—'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: tempTo ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) setDialog(() => tempTo = d);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (isVehicle) {
                p.setVehicleCustomFrom(tempFrom);
                p.setVehicleCustomTo(tempTo);
              } else {
                p.setRentalCustomFrom(tempFrom);
                p.setRentalCustomTo(tempTo);
              }
              Navigator.pop(ctx);
              onChanged();
            },
            child: const Text('Apply'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// KPI HEADER (shared by all tabs)
// ════════════════════════════════════════════════════════════
class _KpiHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    if (p.vehicleLoading && p.vehicleData == null) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }
    final d = p.vehicleData;
    if (d == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _KpiCard(label: 'Total Vehicles', value: '${d.totalVehicles}', subtitle: '${d.active} active', gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]), icon: Icons.directions_car)),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(label: 'Fleet Value', value: _fmtMoney(d.totalPurchaseValue), subtitle: 'Avg ${_fmtMoney(d.avgPurchaseValue)}', gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]), icon: Icons.payments)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _KpiCard(label: 'Total Mileage', value: _fmtNumShort(d.totalMileage), subtitle: 'Avg ${_fmtNumShort(d.avgMileage)}', gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), icon: Icons.speed)),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(label: 'Utilization', value: '${d.utilizationRate.toStringAsFixed(0)}%', subtitle: '${d.activeRentals} rentals', gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]), icon: Icons.bar_chart)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _KpiCard(label: 'Fleet Health', value: '${d.fleetHealthScore.toStringAsFixed(0)}/100', subtitle: '${d.vehiclesNeedingAttention} need attention', gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]), icon: Icons.health_and_safety)),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(label: 'ABC Revenue', value: _fmtMoney(d.abcTotalRevenue), subtitle: '${d.abcTotalVehicles} ranked', gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]), icon: Icons.insights)),
            ],
          ),
          const SizedBox(height: 4),
          // Quick insight banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: DomendraTheme.outline)),
            child: Row(
              children: [
                Expanded(child: _Insight(label: 'Rentals', value: '${d.totalRentals}', color: DomendraTheme.success)),
                Expanded(child: _Insight(label: 'Revenue', value: _fmtMoney(d.totalRevenue), color: DomendraTheme.info)),
                Expanded(child: _Insight(label: 'Service', value: _fmtMoney(d.totalServiceCost), color: DomendraTheme.warning)),
                Expanded(child: _Insight(label: 'Deprec.', value: _fmtMoney(d.totalDepreciationLoss), color: DomendraTheme.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1: COMPOSITION
// ════════════════════════════════════════════════════════════
class _CompositionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Status Distribution', icon: Icons.pie_chart_outline),
        _BreakdownList(items: d.statusBreakdown, labelKey: 'status', valueKey: 'count', colorMap: _statusColor),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Fuel Type Breakdown', icon: Icons.local_gas_station_outlined),
        _BreakdownList(items: d.fuelTypeBreakdown, labelKey: 'fuel_type', valueKey: 'count', palette: true),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Vehicle Type', icon: Icons.directions_car_outlined),
        _BreakdownList(items: d.vehicleTypeBreakdown, labelKey: 'vehicle_type', valueKey: 'count', palette: true),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Ownership', icon: Icons.handshake_outlined),
        _BreakdownList(items: d.ownershipBreakdown, labelKey: 'ownership', valueKey: 'count', palette: true),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Top Makes', icon: Icons.factory_outlined),
        _BreakdownList(items: d.topMakes, labelKey: 'make', valueKey: 'count', palette: true),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2: VALUE & MILEAGE
// ════════════════════════════════════════════════════════════
class _ValueMileageTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Total Purchase Value', value: _fmtMoney(d.totalPurchaseValue), color: DomendraTheme.primary)),
          const SizedBox(width: 6),
          Expanded(child: _MiniStat(label: 'Avg Purchase Value', value: _fmtMoney(d.avgPurchaseValue), color: DomendraTheme.info)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Total Fleet Mileage', value: _fmtNum(d.totalMileage), color: DomendraTheme.success)),
          const SizedBox(width: 6),
          Expanded(child: _MiniStat(label: 'Avg Mileage', value: _fmtNum(d.avgMileage), color: DomendraTheme.warning)),
        ]),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Vehicle Count by Status', icon: Icons.bar_chart),
        _BreakdownList(items: d.statusBreakdown, labelKey: 'status', valueKey: 'count', colorMap: _statusColor),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Vehicle Count by Type', icon: Icons.directions_car_outlined),
        _BreakdownList(items: d.vehicleTypeBreakdown, labelKey: 'vehicle_type', valueKey: 'count', palette: true),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Top Makes by Count', icon: Icons.factory_outlined),
        _BreakdownList(items: d.topMakes, labelKey: 'make', valueKey: 'count', palette: true),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3: UTILIZATION
// ════════════════════════════════════════════════════════════
class _UtilizationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Utilization Rate', value: '${d.utilizationRate.toStringAsFixed(0)}%', color: DomendraTheme.primary)),
          const SizedBox(width: 6),
          Expanded(child: _MiniStat(label: 'Active Rentals', value: '${d.activeRentals}', color: DomendraTheme.success)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Completed', value: '${d.completedRentals}', color: DomendraTheme.info)),
          const SizedBox(width: 6),
          Expanded(child: _MiniStat(label: 'Idle Vehicles', value: '${d.idleVehicles}', color: DomendraTheme.warning)),
        ]),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Revenue Trend (12 Months)', icon: Icons.show_chart),
        ...d.revenueMonthly.take(12).map((r) => _BarRow(
          label: (r is Map ? r['month'] ?? '' : '').toString(),
          value: _parseDouble(r is Map ? r['revenue'] : 0),
          max: _maxDouble(d.revenueMonthly.map((e) => e is Map ? _parseDouble(e['revenue']) : 0)),
          color: const Color(0xFF10B981),
          format: _fmtMoney,
        )),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Revenue by Vehicle Type', icon: Icons.bar_chart),
        ...d.revenueByType.take(8).map((r) => _BarRow(
          label: (r is Map ? r['vehicle_type'] ?? '' : '').toString(),
          value: _parseDouble(r is Map ? r['revenue'] : 0),
          max: _maxDouble(d.revenueByType.map((e) => e is Map ? _parseDouble(e['revenue']) : 0)),
          color: DomendraTheme.primary,
          format: _fmtMoney,
        )),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Top Revenue Vehicles', icon: Icons.star),
        ...d.topVehicles.take(5).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final v = entry.value as Map;
          final rank = idx + 1;
          final colors = [const Color(0xFFF59E0B), const Color(0xFF94A3B8), const Color(0xFFCD7F32)];
          final color = idx < 3 ? colors[idx] : DomendraTheme.primary;
          final name = '${v['make'] ?? ''} ${v['model'] ?? ''}';
          final sub = '${v['year'] ?? ''} · ${v['license_plate'] ?? ''} · ${v['rental_cnt'] ?? 0} rentals';
          return _RankCard(rank: rank, title: name, subtitle: sub, value: _fmtMoney(_parseDouble(v['rev'])), color: color);
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 4: COST & DEPRECIATION
// ════════════════════════════════════════════════════════════
class _CostDepreciationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Service Cost', value: _fmtMoney(d.totalServiceCost), color: DomendraTheme.danger)),
          const SizedBox(width: 6),
          Expanded(child: _MiniStat(label: 'Depreciation', value: _fmtMoney(d.totalDepreciationLoss), color: DomendraTheme.warning)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Book Value', value: _fmtMoney(d.totalBookValue), color: DomendraTheme.info)),
          const SizedBox(width: 6),
          Expanded(child: _MiniStat(label: 'Cost / Km', value: _fmtMoney(d.costPerKm), color: DomendraTheme.success)),
        ]),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Service Cost by Type', icon: Icons.build_outlined),
        ...d.serviceByType.take(8).map((s) {
          final m = s as Map;
          final type = m['service_type'] as String? ?? 'other';
          final label = serviceTypeLabels[type] ?? type;
          return _BarRow(label: label, value: _parseDouble(m['cost']), max: _maxDouble(d.serviceByType.map((e) => _parseDouble((e as Map)['cost']))), color: const Color(0xFFEF4444), format: _fmtMoney);
        }),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Depreciation by Vehicle', icon: Icons.trending_down),
        ...d.costVehicles.take(10).map((v) {
          final m = v as Map;
          final name = '${m['make'] ?? ''} ${m['model'] ?? ''}';
          final depreciationPct = _parseDouble(m['depreciation_pct']);
          final chipColor = depreciationPct > 50 ? DomendraTheme.danger : (depreciationPct > 20 ? DomendraTheme.warning : DomendraTheme.success);
          return _DepreciationCard(vehicle: name, ageYears: _parseDouble(m['age_years']), purchasePrice: _parseDouble(m['purchase_price']), bookValue: _parseDouble(m['book_value']), annualDepreciation: _parseDouble(m['annual_depreciation']), depreciationPct: depreciationPct, chipColor: chipColor);
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 5: FLEET HEALTH
// ════════════════════════════════════════════════════════════
class _FleetHealthTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    final healthColor = d.fleetHealthScore >= 70 ? DomendraTheme.success : DomendraTheme.warning;
    final activePct = d.totalVehicles > 0 ? (d.active / d.totalVehicles * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        // Health score card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: healthColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: healthColor.withOpacity(0.2))),
          child: Column(
            children: [
              Icon(Icons.health_and_safety, size: 40, color: healthColor),
              const SizedBox(height: 8),
              Text('${d.fleetHealthScore.toStringAsFixed(0)}/100', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: healthColor)),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: d.fleetHealthScore / 100, color: healthColor, backgroundColor: healthColor.withOpacity(0.1), minHeight: 8),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _HealthSubStat(label: 'Passed', value: d.passCount, color: DomendraTheme.success)),
                Expanded(child: _HealthSubStat(label: 'Failed', value: d.failCount, color: DomendraTheme.danger)),
                Expanded(child: _HealthSubStat(label: 'Total', value: d.totalInspections, color: DomendraTheme.info)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Maintenance & Status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
          child: Column(children: [
            _HealthRow(label: 'In Maintenance', value: d.inMaintenance, pct: d.maintenancePct, color: const Color(0xFFF59E0B)),
            _HealthRow(label: 'Out of Service', value: d.outOfService, pct: d.outOfServicePct, color: const Color(0xFFEF4444)),
            _HealthRow(label: 'Needs Attention', value: d.vehiclesNeedingAttention, pct: 0, color: const Color(0xFFEF4444)),
          ]),
        ),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Inspection Results', icon: Icons.assignment_turned_in_outlined),
        Row(children: [
          Expanded(child: _PieLegend(label: 'Passed', value: d.passCount, color: const Color(0xFF10B981))),
          Expanded(child: _PieLegend(label: 'Failed', value: d.failCount, color: const Color(0xFFEF4444))),
          Expanded(child: _PieLegend(label: 'Other', value: (d.totalInspections - d.passCount - d.failCount).clamp(0, 9999), color: const Color(0xFF64748B))),
        ]),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Fleet Status Overview', icon: Icons.speed),
        Row(children: d.statusBreakdown.take(4).map((s) {
          final m = s as Map;
          final status = m['status'] as String? ?? '';
          final color = Color(_statusColor(status));
          return Expanded(child: _PieLegend(label: _statusLabel(status), value: toIntOr(m['count']), color: color));
        }).toList()),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Health Indicators', icon: Icons.insights_outlined),
        _Indicator(label: 'Utilization Rate', value: d.utilizationRate, color: DomendraTheme.primary),
        _Indicator(label: 'Inspection Pass Rate', value: d.inspectionPassRate, color: DomendraTheme.success),
        _Indicator(label: 'Active Fleet', value: activePct, color: DomendraTheme.success),
        _Indicator(label: 'Maintenance Ratio', value: d.maintenancePct, color: DomendraTheme.warning),
        _Indicator(label: 'Out of Service', value: d.outOfServicePct, color: DomendraTheme.danger),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 6: LIFECYCLE
// ════════════════════════════════════════════════════════════
class _LifecycleTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    final ageEntries = d.ageDistribution.entries.toList();
    final maxAgeCount = ageEntries.isEmpty ? 1.0 : ageEntries.map((e) => _parseDouble(e.value)).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        _SectionTitle(title: 'Fleet Age Distribution', icon: Icons.timeline),
        ...ageEntries.map((e) => _BarRow(label: e.key, value: _parseDouble(e.value), max: maxAgeCount, color: const Color(0xFF6366F1), format: _fmtNum)),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Acquisition Trend', icon: Icons.trending_up),
        ...d.acquisitionTrend.take(12).map((a) {
          final m = a as Map;
          return _BarRow(label: m['month']?.toString() ?? '', value: _parseDouble(m['count']), max: _maxDouble(d.acquisitionTrend.map((e) => _parseDouble((e as Map)['count']))), color: const Color(0xFF10B981), format: _fmtNum);
        }),
        const SizedBox(height: 16),
        // EV stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Icon(Icons.battery_charging_full, size: 18, color: Colors.green), const SizedBox(width: 8), const Text('Electric Vehicle Stats', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _MiniStat(label: 'EV Count', value: '${d.evCount}', color: DomendraTheme.success)),
                const SizedBox(width: 6),
                Expanded(child: _MiniStat(label: 'Avg Charge', value: '${d.evAvgStateOfCharge.toStringAsFixed(0)}%', color: DomendraTheme.info)),
                const SizedBox(width: 6),
                Expanded(child: _MiniStat(label: 'Avg Health', value: '${d.evAvgStateOfHealth.toStringAsFixed(0)}%', color: DomendraTheme.primary)),
              ]),
              const SizedBox(height: 8),
              _Indicator(label: 'State of Charge', value: d.evAvgStateOfCharge, color: DomendraTheme.success),
              _Indicator(label: 'State of Health', value: d.evAvgStateOfHealth, color: DomendraTheme.info),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Status Summary', icon: Icons.list),
        ...d.statusBreakdown.map((s) {
          final m = s as Map;
          final status = m['status'] as String? ?? '';
          final color = Color(_statusColor(status));
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(child: Text(_statusLabel(status), style: const TextStyle(fontSize: 12))),
              Text('${m['count']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 7: ABC ANALYSIS
// ════════════════════════════════════════════════════════════
class _AbcTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final d = p.vehicleData;
    if (d == null) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        // ABC Summary cards
        Row(children: [
          Expanded(child: _AbcSumCard(badge: 'A', label: 'Class A', count: toIntOr(d.abcClassA['count']), revenue: _fmtMoney(_parseDouble(d.abcClassA['revenue'])), pct: _parseDouble(d.abcClassA['pct']), color: const Color(0xFF10B981))),
          const SizedBox(width: 6),
          Expanded(child: _AbcSumCard(badge: 'B', label: 'Class B', count: toIntOr(d.abcClassB['count']), revenue: _fmtMoney(_parseDouble(d.abcClassB['revenue'])), pct: _parseDouble(d.abcClassB['pct']), color: const Color(0xFF3B82F6))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _AbcSumCard(badge: 'C', label: 'Class C', count: toIntOr(d.abcClassC['count']), revenue: _fmtMoney(_parseDouble(d.abcClassC['revenue'])), pct: _parseDouble(d.abcClassC['pct']), color: const Color(0xFFF59E0B))),
          const SizedBox(width: 6),
          Expanded(child: _AbcSumCard(badge: 'Σ', label: 'Total', count: d.abcTotalVehicles, revenue: _fmtMoney(d.abcTotalRevenue), pct: 0, color: const Color(0xFF6366F1), showPct: false, extra: '${d.abcNoRevenueCount} no rentals')),
        ]),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Vehicle Ranking', icon: Icons.list),
        ...d.abcVehicles.take(20).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value as Map;
          final cls = m['abc_class'] as String? ?? '';
          final color = Color(abcClassColor(cls));
          final name = '${m['make'] ?? ''} ${m['model'] ?? ''}';
          final sub = '${m['year'] ?? ''} · ${m['license_plate'] ?? (m['vin'] != null ? '...${(m['vin'] as String).substring(((m['vin'] as String).length - 6).clamp(0, 100))}' : '')}';
          return _AbcRankCard(
            rank: idx + 1,
            name: name,
            subtitle: sub,
            abcClass: cls,
            classColor: color,
            revenue: _parseDouble(m['total_rev']),
            revenuePct: _parseDouble(m['revenue_pct']),
            cumulativePct: _parseDouble(m['cumulative_pct']),
            rentalCount: toIntOr(m['rental_count']),
          );
        }),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Strategy', icon: Icons.lightbulb_outline),
        _StrategyCard(title: 'Class A Strategy', subtitle: '80% of revenue', text: 'High-value, mission-critical vehicles. Prioritize maintenance, uptime and replacement planning.', color: const Color(0xFF10B981)),
        _StrategyCard(title: 'Class B Strategy', subtitle: 'Next 15% of revenue', text: 'Steady contributors. Regular maintenance and utilization tracking.', color: const Color(0xFF3B82F6)),
        _StrategyCard(title: 'Class C Strategy', subtitle: 'Bottom 5% of revenue', text: 'Underperforming assets. Consider redeployment, sale or retirement.', color: const Color(0xFFF59E0B)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSel;
  const _PeriodChip({required this.label, required this.value, required this.groupValue, required this.onSel});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: selected ? DomendraTheme.primary : DomendraTheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        selected: selected,
        onSelected: (_) => onSel(value),
        labelStyle: TextStyle(fontSize: 11, color: selected ? DomendraTheme.primary : DomendraTheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Icon(icon, size: 14, color: Colors.white70),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 8, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _Insight extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Insight({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [Icon(icon, size: 16, color: DomendraTheme.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  final List<dynamic> items;
  final String labelKey;
  final String valueKey;
  final int Function(String)? colorMap;
  final bool palette;
  const _BreakdownList({required this.items, required this.labelKey, required this.valueKey, this.colorMap, this.palette = false});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)));
    final maxVal = _maxDouble(items.map((e) => _parseDouble((e as Map)[valueKey])));
    return Column(
      children: items.take(12).toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final m = entry.value as Map;
        final label = (m[labelKey] ?? '').toString();
        final count = _parseDouble(m[valueKey]);
        final color = colorMap != null ? Color(colorMap!(label)) : Color(chartPalette[idx % chartPalette.length]);
        return _BarRow(label: label, value: count, max: maxVal, color: color, format: _fmtNum);
      }).toList(),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String Function(double) format;
  const _BarRow({required this.label, required this.value, required this.max, required this.color, required this.format});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 8))),
        const SizedBox(width: 8),
        SizedBox(width: 50, child: Text(format(value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String value;
  final Color color;
  const _RankCard({required this.rank, required this.title, required this.subtitle, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('#$rank', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis), Text(subtitle, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)])),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _DepreciationCard extends StatelessWidget {
  final String vehicle;
  final double ageYears;
  final double purchasePrice;
  final double bookValue;
  final double annualDepreciation;
  final double depreciationPct;
  final Color chipColor;
  const _DepreciationCard({required this.vehicle, required this.ageYears, required this.purchasePrice, required this.bookValue, required this.annualDepreciation, required this.depreciationPct, required this.chipColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(vehicle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)), Text('${ageYears.toStringAsFixed(1)} yrs', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))]),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: _StatCol(label: 'Purchase', value: _fmtMoney(purchasePrice))), Expanded(child: _StatCol(label: 'Book Value', value: _fmtMoney(bookValue), color: chipColor)), Expanded(child: _StatCol(label: 'Annual Dep.', value: _fmtMoney(annualDepreciation)))]),
        const SizedBox(height: 6),
        Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (depreciationPct / 100).clamp(0.0, 1.0), color: chipColor, backgroundColor: chipColor.withOpacity(0.1), minHeight: 5))), const SizedBox(width: 8), Text('${depreciationPct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: chipColor))]),
      ]),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCol({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)), Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)]);
  }
}

class _HealthSubStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _HealthSubStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted))]);
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final int value;
  final double pct;
  final Color color;
  const _HealthRow({required this.label, required this.value, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(children: [
        Row(children: [Icon(Icons.circle, size: 8, color: color), const SizedBox(width: 6), Expanded(child: Text(label, style: const TextStyle(fontSize: 12))), Text('$value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))]),
        if (pct > 0) ...[const SizedBox(height: 4), ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct / 100, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 5))],
      ]),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _PieLegend({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))), const SizedBox(height: 4), Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center)]);
  }
}

class _Indicator extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Indicator({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 11))), Text('${value.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))]), const SizedBox(height: 3), ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (value / 100).clamp(0.0, 1.0), color: color, backgroundColor: color.withOpacity(0.1), minHeight: 5))]),
    );
  }
}

class _AbcSumCard extends StatelessWidget {
  final String badge;
  final String label;
  final int count;
  final String revenue;
  final double pct;
  final Color color;
  final bool showPct;
  final String? extra;
  const _AbcSumCard({required this.badge, required this.label, required this.count, required this.revenue, required this.pct, required this.color, this.showPct = true, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(badge, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)), if (showPct) Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70))]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(revenue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('$count vehicles', style: const TextStyle(fontSize: 9, color: Colors.white60)),
        if (extra != null) Text(extra!, style: const TextStyle(fontSize: 9, color: Colors.white60)),
      ]),
    );
  }
}

class _AbcRankCard extends StatelessWidget {
  final int rank;
  final String name;
  final String subtitle;
  final String abcClass;
  final Color classColor;
  final double revenue;
  final double revenuePct;
  final double cumulativePct;
  final int rentalCount;
  const _AbcRankCard({required this.rank, required this.name, required this.subtitle, required this.abcClass, required this.classColor, required this.revenue, required this.revenuePct, required this.cumulativePct, required this.rentalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 24, child: Text('#$rank', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: rank < 3 ? DomendraTheme.primary : DomendraTheme.onSurfaceMuted))),
          Container(width: 24, height: 24, decoration: BoxDecoration(color: classColor, borderRadius: BorderRadius.circular(6)), child: Center(child: Text(abcClass, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis), Text(subtitle, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)])),
          Text(_fmtMoney(revenue), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: classColor)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text('%', style: TextStyle(fontSize: 9, color: classColor)), const Spacer(), Text('${revenuePct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: classColor))]), ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: (revenuePct / 100).clamp(0.0, 1.0), color: classColor, backgroundColor: classColor.withOpacity(0.1), minHeight: 4))])),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text('Cum', style: TextStyle(fontSize: 9, color: DomendraTheme.primary)), const Spacer(), Text('${cumulativePct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: DomendraTheme.primary))]), ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: (cumulativePct / 100).clamp(0.0, 1.0), color: DomendraTheme.primary, backgroundColor: DomendraTheme.primary.withOpacity(0.1), minHeight: 4))])),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: classColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text('$rentalCount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: classColor))),
        ]),
      ]),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String text;
  final Color color;
  const _StrategyCard({required this.title, required this.subtitle, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))), Text(subtitle, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))]),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

int _statusColor(String s) {
  switch (s) {
    case 'active': return 0xFF10B981;
    case 'in_maintenance': return 0xFFF59E0B;
    case 'out_of_service': return 0xFFEF4444;
    case 'retired': return 0xFF64748B;
    default: return 0xFF94A3B8;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'active': return 'Active';
    case 'in_maintenance': return 'Maintenance';
    case 'out_of_service': return 'Out of Service';
    case 'retired': return 'Retired';
    default: return s;
  }
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

double _maxDouble(Iterable<double> vals) {
  final list = vals.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a > b ? a : b);
}

String _fmtMoney(double v) => '$_currencySymbol${v >= 1000 ? _fmtNumShort(v) : v.toStringAsFixed(2)}';
String _fmtNum(double v) => v >= 1000 ? _fmtNumShort(v) : v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
String _fmtNumShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
