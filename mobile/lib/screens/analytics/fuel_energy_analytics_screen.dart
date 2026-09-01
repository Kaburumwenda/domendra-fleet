import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/fuel_model.dart' show fuelTypes;
import '../../providers/analytics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Fuel & Energy Analytics screen — mirrors `pages/app/analytics/fuel-energy.vue`.
/// 3 tabs: Trends, Breakdown, By Vehicle.
class FuelEnergyAnalyticsScreen extends StatefulWidget {
  const FuelEnergyAnalyticsScreen({super.key});

  @override
  State<FuelEnergyAnalyticsScreen> createState() => _FuelEnergyAnalyticsScreenState();
}

class _FuelEnergyAnalyticsScreenState extends State<FuelEnergyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.trending_up, size: 18), text: 'Trends'),
    Tab(icon: Icon(Icons.pie_chart_outline, size: 18), text: 'Breakdown'),
    Tab(icon: Icon(Icons.directions_car_outlined, size: 18), text: 'By Vehicle'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      final p = context.read<AnalyticsProvider>();
      p.fetchGroupAndLocationOptions();
      p.fetchFuelAnalytics();
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
        title: const Text('Fuel & Energy Analytics'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<AnalyticsProvider>().fetchFuelAnalytics(),
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
      drawer: const AppDrawer(currentRoute: '/analytics/fuel-energy'),
      body: Column(
        children: [
          _FiltersBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TrendsTab(),
                _BreakdownTab(),
                _ByVehicleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// CUSTOM DATE DIALOG + HELPERS
// ════════════════════════════════════════════════════════════

void _showFuelCustomDateDialog(BuildContext context) {
  final p = context.read<AnalyticsProvider>();
  DateTime? tempFrom = p.fuelCustomFrom ?? DateTime.now().subtract(const Duration(days: 30));
  DateTime? tempTo = p.fuelCustomTo ?? DateTime.now();

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
              p.setFuelCustomFrom(tempFrom);
              p.setFuelCustomTo(tempTo);
              Navigator.pop(ctx);
              p.fetchFuelAnalytics();
            },
            child: const Text('Apply'),
          ),
        ],
      );
    }),
  );
}

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

// ════════════════════════════════════════════════════════════
// FILTERS + KPI HEADER
// ════════════════════════════════════════════════════════════
class _FiltersBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Column(
        children: [
          // Filter row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: p.fuelTypeFilter,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Fuel Type', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...fuelTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) { p.setFuelTypeFilter(v); p.fetchFuelAnalytics(); },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: p.groupFilter,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Group', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...p.groups.map<DropdownMenuItem<int>>((g) => DropdownMenuItem(value: g['id'] as int?, child: Text(g['name']?.toString() ?? '', overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) { p.setGroupFilter(v); p.fetchFuelAnalytics(); },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: p.locationFilter,
                  isExpanded: true,
                  isDense: true,
                  decoration: const InputDecoration(labelText: 'Location', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...p.locations.map<DropdownMenuItem<String>>((l) => DropdownMenuItem(value: l['name'] as String?, child: Text(l['name']?.toString() ?? '', overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) { p.setLocationFilter(v); p.fetchFuelAnalytics(); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Period toggle + clear
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _Chip(label: '7d', value: '7', group: p.fuelPeriod, onSel: (v) { p.setFuelPeriod(v); p.fetchFuelAnalytics(); }),
                    _Chip(label: '30d', value: '30', group: p.fuelPeriod, onSel: (v) { p.setFuelPeriod(v); p.fetchFuelAnalytics(); }),
                    _Chip(label: '90d', value: '90', group: p.fuelPeriod, onSel: (v) { p.setFuelPeriod(v); p.fetchFuelAnalytics(); }),
                    _Chip(label: '365d', value: '365', group: p.fuelPeriod, onSel: (v) { p.setFuelPeriod(v); p.fetchFuelAnalytics(); }),
                    _Chip(label: 'Custom…', value: 'custom', group: p.fuelPeriod, onSel: (v) {
                      p.setFuelPeriod(v);
                      _showFuelCustomDateDialog(context);
                    }),
                  ]),
                ),
              ),
              if (p.fuelTypeFilter != null || p.groupFilter != null || p.locationFilter != null)
                IconButton(icon: const Icon(Icons.filter_alt_off_outlined, size: 18), onPressed: () { p.setFuelTypeFilter(null); p.setGroupFilter(null); p.setLocationFilter(null); p.fetchFuelAnalytics(); }),
            ],
          ),
          const SizedBox(height: 8),
          _KpiHeader(),
        ],
      ),
    );
  }
}

class _KpiHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    if (p.fuelLoading && p.fuelData.isEmpty) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }

    return Row(
      children: [
        Expanded(child: _KpiCard(label: 'Total Cost', value: _fmtMoney(p.fuelTotalCost), gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]), icon: Icons.attach_money)),
        const SizedBox(width: 4),
        Expanded(child: _KpiCard(label: 'Total Volume', value: '${p.fuelTotalGallons.toStringAsFixed(1)} gal', gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), icon: Icons.speed)),
        const SizedBox(width: 4),
        Expanded(child: _KpiCard(label: 'Avg Price/Unit', value: _fmtMoney(p.fuelAvgPricePerGallon), gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]), icon: Icons.sell_outlined)),
        const SizedBox(width: 4),
        Expanded(child: _KpiCard(label: 'Txns', value: '${p.fuelTransactionCount}', gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]), icon: Icons.receipt)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1: TRENDS
// ════════════════════════════════════════════════════════════
class _TrendsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _Section(title: 'Daily Fuel Cost', icon: Icons.show_chart, items: p.fuelDailyTrend, labelKey: 'day', valueKey: 'total_cost', color: const Color(0xFF6366F1), format: _fmtMoney),
        const SizedBox(height: 16),
        // Day of week aggregated
        _DayOfWeekSection(dailyTrend: p.fuelDailyTrend),
        const SizedBox(height: 16),
        _Section(title: 'Price / Unit Trend', icon: Icons.trending_up, items: p.fuelPriceTrend, labelKey: 'day', valueKey: 'avg_price_per_gallon', color: const Color(0xFF10B981), format: _fmtMoney),
        const SizedBox(height: 16),
        _Section(title: 'Monthly Trend', icon: Icons.calendar_view_week, items: p.fuelMonthlyTrend, labelKey: 'month', valueKey: 'total_cost', color: const Color(0xFFF59E0B), format: _fmtMoney),
      ],
    );
  }
}

class _DayOfWeekSection extends StatelessWidget {
  final List<dynamic> dailyTrend;
  const _DayOfWeekSection({required this.dailyTrend});

  @override
  Widget build(BuildContext context) {
    // Aggregate by weekday
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayCosts = List<double>.filled(7, 0);
    for (final d in dailyTrend) {
      if (d is! Map) continue;
      final day = d['day'] as String?;
      if (day == null) continue;
      final dt = DateTime.tryParse(day);
      if (dt == null) continue;
      final weekday = dt.weekday - 1; // Mon=0
      dayCosts[weekday] += _parseDouble(d['total_cost']);
    }
    final maxVal = dayCosts.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.calendar_view_day, size: 16, color: DomendraTheme.primary), const SizedBox(width: 6), const Text('Fuel Cost by Day of Week', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 6),
        ...dayNames.asMap().entries.map((e) => _BarRow(label: e.value, value: dayCosts[e.key], max: maxVal, color: const Color(0xFF6366F1), format: _fmtMoney)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2: BREAKDOWN
// ════════════════════════════════════════════════════════════
class _BreakdownTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    final avgDailyCost = p.fuelDailyTrend.isEmpty ? 0.0 : p.fuelDailyTrend.map((e) => _parseDouble(e is Map ? e['total_cost'] : 0)).reduce((a, b) => a + b) / p.fuelDailyTrend.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        // By fuel type (breakdown bars)
        _Section(title: 'By Fuel Type', icon: Icons.local_gas_station_outlined, items: p.fuelByFuelType, labelKey: 'fuel_type', valueKey: 'total_cost', color: const Color(0xFF10B981), format: _fmtMoney),
        const SizedBox(height: 16),
        // By group
        _GroupSection(byGroupDaily: p.fuelByGroupDaily),
        const SizedBox(height: 16),
        // Top stations
        _Section(title: 'Top Stations by Cost', icon: Icons.store_outlined, items: p.fuelByStation, labelKey: 'station_name', valueKey: 'total_cost', color: const Color(0xFFEF4444), format: _fmtMoney),
        const SizedBox(height: 16),
        // Mini stats
        Row(children: [
          Expanded(child: _MiniStat(label: 'Max Txn', value: _fmtMoney(p.fuelMaxTxnCost), color: DomendraTheme.danger)),
          const SizedBox(width: 4),
          Expanded(child: _MiniStat(label: 'Min Txn', value: _fmtMoney(p.fuelMinTxnCost), color: DomendraTheme.success)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Avg / Txn', value: _fmtMoney(p.fuelAvgPerTxn), color: DomendraTheme.info)),
          const SizedBox(width: 4),
          Expanded(child: _MiniStat(label: 'Avg Daily', value: _fmtMoney(avgDailyCost), color: DomendraTheme.warning)),
        ]),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  final List<dynamic> byGroupDaily;
  const _GroupSection({required this.byGroupDaily});

  @override
  Widget build(BuildContext context) {
    // Aggregate by group
    final groups = <String, double>{};
    for (final e in byGroupDaily) {
      if (e is! Map) continue;
      final name = (e['vehicle__group__name'] ?? 'Unknown').toString();
      groups[name] = (groups[name] ?? 0) + _parseDouble(e['total_cost']);
    }
    final entries = groups.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.isEmpty ? 1.0 : entries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.folder_outlined, size: 16, color: DomendraTheme.primary), const SizedBox(width: 6), const Text('By Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 6),
        if (entries.isEmpty)
          const Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted))
        else
          ...entries.take(10).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color = Color([0xFF6366F1, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444, 0xFF8B5CF6, 0xFF06B6D4][idx % 6]);
            return _BarRow(label: e.key, value: e.value, max: maxVal, color: color, format: _fmtMoney);
          }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3: BY VEHICLE
// ════════════════════════════════════════════════════════════
class _ByVehicleTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    // Sort by total_cost desc
    final items = p.fuelByVehicle.where((e) => e is Map).toList();
    items.sort((a, b) => _parseDouble((b as Map)['total_cost']).compareTo(_parseDouble((a as Map)['total_cost'])));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        // Top vehicles list
        ...items.take(15).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value as Map;
          final name = '${m['vehicle__make'] ?? ''} ${m['vehicle__model'] ?? ''}'.trim();
          final plate = m['vehicle__license_plate'] as String? ?? '';
          final totalCost = _parseDouble(m['total_cost']);
          final totalGallons = _parseDouble(m['total_gallons']);
          final fillCount = m['fill_count'] as int? ?? 0;
          final avgPrice = totalGallons > 0 ? totalCost / totalGallons : 0.0;
          return _VehicleCard(name: name.isEmpty ? (m['vehicle__vin'] as String? ?? 'Unknown') : name, plate: plate, fillCount: fillCount, totalGallons: totalGallons, totalCost: totalCost, avgPrice: avgPrice, maxCost: items.isEmpty ? 1.0 : _parseDouble((items.first as Map)['total_cost']));
        }),
        const SizedBox(height: 16),
        _Section(title: 'Cost by Vehicle', icon: Icons.payments, items: items.take(15).toList(), labelKey: 'vehicle__make', valueKey: 'total_cost', color: const Color(0xFF6366F1), format: _fmtMoney, nameOverride: (m) => '${m['vehicle__make'] ?? ''} ${m['vehicle__model'] ?? ''}'),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String name;
  final String plate;
  final int fillCount;
  final double totalGallons;
  final double totalCost;
  final double avgPrice;
  final double maxCost;
  const _VehicleCard({required this.name, required this.plate, required this.fillCount, required this.totalGallons, required this.totalCost, required this.avgPrice, required this.maxCost});

  @override
  Widget build(BuildContext context) {
    final pct = maxCost > 0 ? (totalCost / maxCost).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis), Text(plate, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(_fmtMoney(totalCost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)), Text('$fillCount fills', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted))]),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, color: DomendraTheme.primary, backgroundColor: DomendraTheme.primary.withOpacity(0.1), minHeight: 6)),
        const SizedBox(height: 4),
        Row(children: [Expanded(child: Text('${totalGallons.toStringAsFixed(1)} gal', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))), Text('Avg ${_fmtMoney(avgPrice)}/gal', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String group;
  final ValueChanged<String> onSel;
  const _Chip({required this.label, required this.value, required this.group, required this.onSel});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return Padding(padding: const EdgeInsets.only(right: 4), child: FilterChip(label: Text(label, style: TextStyle(fontSize: 11, color: selected ? DomendraTheme.primary : DomendraTheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)), selected: selected, onSelected: (_) => onSel(value), labelStyle: TextStyle(fontSize: 11, color: selected ? DomendraTheme.primary : DomendraTheme.onSurface, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)));
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)), Icon(icon, size: 12, color: Colors.white70)]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> items;
  final String labelKey;
  final String valueKey;
  final Color color;
  final String Function(double) format;
  final String Function(Map)? nameOverride;
  const _Section({required this.title, required this.icon, required this.items, required this.labelKey, required this.valueKey, required this.color, required this.format, this.nameOverride});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 16, color: DomendraTheme.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]), const SizedBox(height: 6), const Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted))]);
    final maxVal = _maxDouble(items.map((e) => _parseDouble((e as Map)[valueKey])));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 16, color: DomendraTheme.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 6),
      ...items.take(12).map((e) {
        final m = e as Map;
        final label = nameOverride != null ? nameOverride!(m) : (m[labelKey] ?? '').toString();
        return _BarRow(label: label, value: _parseDouble(m[valueKey]), max: maxVal, color: color, format: format);
      }),
    ]);
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
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 8))), const SizedBox(width: 8), SizedBox(width: 55, child: Text(format(value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis))]));
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

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

String _fmtMoney(double v) => '$_currencySymbol${v >= 1000 ? _fmtShort(v) : v.toStringAsFixed(2)}';
String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
