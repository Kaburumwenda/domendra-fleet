import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/date_presets.dart';
import '../widgets/app_drawer.dart';

/// Dashboard screen — mirrors the web `pages/app/index.vue`.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DatePreset _preset = DatePreset.thisYear;
  DateTime? _customStart;
  DateTime? _customEnd;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetch() {
    final range = resolvePreset(_preset, customStart: _customStart, customEnd: _customEnd);
    final dash = context.read<DashboardProvider>();
    dash.refresh(startDate: range.startDateStr, endDate: range.endDateStr);
    dash.fetchTrend(period: 'month');
    dash.loadCurrency();
  }

  void _onPresetChanged(DatePreset? p) {
    if (p == null) return;
    setState(() => _preset = p);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Fleet Dashboard'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: dash.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: DomendraTheme.primary))
                : const Icon(Icons.refresh, color: DomendraTheme.onSurfaceMuted),
            onPressed: dash.loading ? null : _fetch,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/app'),
      body: RefreshIndicator(
        onRefresh: () async => _fetch(),
        child: dash.loading && dash.data == null
            ? const Center(child: CircularProgressIndicator())
            : dash.error != null && dash.data == null
                ? _ErrorBanner(error: dash.error!, onRetry: _fetch)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    controller: _scrollController,
                    children: [
                      // 1 ── Page header ─────────────────────────────
                      _PageHeader(dash: dash, onRefresh: _fetch),
                      const SizedBox(height: 16),

                      // 2 ── Greeting card ────────────────────────────
                      _GreetingCard(auth: auth),
                      const SizedBox(height: 16),

                      // 3 ── Date filter ──────────────────────────────
                      _DateFilterBar(
                        preset: _preset,
                        onPresetChanged: _onPresetChanged,
                        customStart: _customStart,
                        customEnd: _customEnd,
                        onCustomStart: (d) => setState(() => _customStart = d),
                        onCustomEnd: (d) => setState(() => _customEnd = d),
                        onApply: _fetch,
                      ),
                      const SizedBox(height: 20),

                      // 4 ── KPI cards ───────────────────────────────
                      _KpiGrid(dash: dash),
                      const SizedBox(height: 24),

                      // 5 ── Cost trend + monthly summary ─────────────
                      _sectionTitle('Revenue & Costs'),
                      const SizedBox(height: 12),
                      if (dash.costTrend.isNotEmpty) _CostTrendChart(dash: dash),
                      const SizedBox(height: 12),
                      _MonthlySummaryCard(dash: dash),
                      const SizedBox(height: 24),

                      // 6 ── Monthly bar + revenue by type ────────────
                      _sectionTitle('Financial Breakdown'),
                      const SizedBox(height: 12),
                      if (dash.monthlyBar.isNotEmpty) _MonthlyBarChart(dash: dash),
                      const SizedBox(height: 12),
                      if (dash.revenueByType.isNotEmpty) _RevenueByTypeChart(dash: dash),
                      const SizedBox(height: 24),

                      // 7 ── Fleet composition charts ────────────────
                      _sectionTitle('Fleet Composition'),
                      const SizedBox(height: 12),
                      if (dash.vehiclesByStatus.isNotEmpty) _FleetPieChart(
                        title: 'By Status',
                        data: dash.vehiclesByStatus.map((e) => PieData(
                          label: (e['status'] as String?) ?? '?',
                          value: (e['count'] as num?)?.toDouble() ?? 0,
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      if (dash.vehiclesByType.isNotEmpty) _FleetPieChart(
                        title: 'By Type',
                        data: dash.vehiclesByType.map((e) => PieData(
                          label: (e['vehicle_type'] as String?) ?? '?',
                          value: (e['count'] as num?)?.toDouble() ?? 0,
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      if (dash.vehiclesByFuel.isNotEmpty) _FleetPieChart(
                        title: 'By Fuel Type',
                        data: dash.vehiclesByFuel.map((e) => PieData(
                          label: (e['fuel_type'] as String?) ?? '?',
                          value: (e['count'] as num?)?.toDouble() ?? 0,
                        )).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 8 ── Alerts + upcoming ────────────────────────
                      _sectionTitle('Alerts'),
                      const SizedBox(height: 12),
                      _AlertsGrid(dash: dash),
                      const SizedBox(height: 12),
                      _UpcomingCard(dash: dash),
                      const SizedBox(height: 24),

                      // 9 ── Rental trend ─────────────────────────────
                      _sectionTitle('Rental & Revenue Trend'),
                      const SizedBox(height: 12),
                      if (dash.trend.isNotEmpty) _TrendChart(dash: dash),
                      const SizedBox(height: 24),

                      // 10 ── Recent activity ─────────────────────────
                      _sectionTitle('Recent Activity'),
                      const SizedBox(height: 12),
                      _RecentRentalsCard(dash: dash),
                      const SizedBox(height: 12),
                      _RecentFuelServicesCard(dash: dash),
                    ],
                  ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: DomendraTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: DomendraTheme.onSurface,
        )),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 1. Page Header
// ════════════════════════════════════════════════════════════
class _PageHeader extends StatelessWidget {
  final DashboardProvider dash;
  final VoidCallback onRefresh;
  const _PageHeader({required this.dash, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: DomendraTheme.heroGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.dashboard_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fleet Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
                Text(
                  dash.periodLabel.isNotEmpty ? dash.periodLabel : 'Real-time fleet overview',
                  style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: dash.loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: DomendraTheme.primary))
                : const Icon(Icons.refresh, color: DomendraTheme.onSurfaceMuted),
            onPressed: dash.loading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. Greeting Card
// ════════════════════════════════════════════════════════════
class _GreetingCard extends StatelessWidget {
  final AuthProvider auth;
  const _GreetingCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DomendraTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              auth.initials.isNotEmpty ? auth.initials : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${auth.fullName.split(' ').firstOrNull ?? 'User'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  auth.role.isNotEmpty ? auth.role.toUpperCase() : 'Fleet Manager',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. Date Filter Bar
// ════════════════════════════════════════════════════════════
class _DateFilterBar extends StatelessWidget {
  final DatePreset preset;
  final ValueChanged<DatePreset?> onPresetChanged;
  final DateTime? customStart;
  final DateTime? customEnd;
  final ValueChanged<DateTime> onCustomStart;
  final ValueChanged<DateTime> onCustomEnd;
  final VoidCallback onApply;

  const _DateFilterBar({
    required this.preset,
    required this.onPresetChanged,
    required this.customStart,
    required this.customEnd,
    required this.onCustomStart,
    required this.onCustomEnd,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              const Icon(Icons.calendar_month, size: 18, color: DomendraTheme.primary),
              const SizedBox(width: 8),
              const Text('Period', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DatePreset.values.map((p) {
                final selected = preset == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(p.label),
                    selected: selected,
                    onSelected: (_) => onPresetChanged(p),
                    selectedColor: DomendraTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : DomendraTheme.onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (preset == DatePreset.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start',
                    value: customStart,
                    onChanged: onCustomStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'End',
                    value: customEnd,
                    onChanged: onCustomEnd,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: onApply, child: const Text('Apply')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: DomendraTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: DomendraTheme.onSurfaceMuted),
            const SizedBox(width: 8),
            Text(
              value != null ? '${value!.month}/${value!.day}/${value!.year}' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value != null ? DomendraTheme.onSurface : DomendraTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. KPI Grid
// ════════════════════════════════════════════════════════════
class _KpiGrid extends StatelessWidget {
  final DashboardProvider dash;
  const _KpiGrid({required this.dash});

  @override
  Widget build(BuildContext context) {
    final kpis = [
      _KpiData(Icons.directions_car, const Color(0xFF4F46E5), const Color(0xFFE0E7FF), 'Total Vehicles', dash.totalVehicles.toString()),
      _KpiData(Icons.check_circle, const Color(0xFF10B981), const Color(0xFFD1FAE5), 'Active', dash.activeVehicles.toString()),
      _KpiData(Icons.car_repair, const Color(0xFFF59E0B), const Color(0xFFFFEDD5), 'Out of Service', dash.outOfService.toString()),
      _KpiData(Icons.donut_small, const Color(0xFF3B82F6), const Color(0xFFDBEAFE), 'Utilization', '${dash.fleetUtilization.toStringAsFixed(1)}%'),
      _KpiData(Icons.people, const Color(0xFF7C3AED), const Color(0xFFF3E8FF), 'Drivers', dash.totalDrivers.toString()),
      _KpiData(Icons.monetization_on, const Color(0xFF059669), const Color(0xFFD1FAE5), 'Fleet Value', _fmtMoney(context, dash.totalPurchaseValue)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _KpiCard(kpis[i]),
    );
  }

  static String _fmtMoney(BuildContext context, double v) {
    final sym = Provider.of<DashboardProvider>(context, listen: false).currencySymbol;
    if (v >= 1000000) return '$sym ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '$sym ${(v / 1000).toStringAsFixed(0)}K';
    return '$sym ${v.toStringAsFixed(0)}';
  }
}

class _KpiData {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;
  const _KpiData(this.icon, this.color, this.bg, this.label, this.value);
}

class _KpiCard extends StatelessWidget {
  final _KpiData kpi;
  const _KpiCard(this.kpi);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, kpi.bg],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kpi.bg.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kpi.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(kpi.icon, color: kpi.color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            kpi.value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kpi.color, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            kpi.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 5. Cost Trend Chart
// ════════════════════════════════════════════════════════════
class _CostTrendChart extends StatelessWidget {
  final DashboardProvider dash;
  const _CostTrendChart({required this.dash});

  @override
  Widget build(BuildContext context) {
    final points = dash.costTrend;
    final fuelSpots = <FlSpot>[];
    final serviceSpots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < points.length; i++) {
      final fuel = (points[i]['fuel'] as num?)?.toDouble() ?? 0;
      final service = (points[i]['service'] as num?)?.toDouble() ?? 0;
      fuelSpots.add(FlSpot(i.toDouble(), fuel));
      serviceSpots.add(FlSpot(i.toDouble(), service));
      if (fuel > maxY) maxY = fuel;
      if (service > maxY) maxY = service;
    }
    final xLabels = points.map((p) => (p['month'] as String?) ?? '').toList();

    final chartH = 200.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      height: chartH + 60,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _chartTitle('Cost Trend (Fuel vs Service)'),
          const SizedBox(height: 8),
          _Legend([
            _LegendItem(color: DomendraTheme.warning, label: 'Fuel'),
            _LegendItem(color: DomendraTheme.info, label: 'Service'),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final computedWidth = points.length * 50.0;
                final chartWidth = computedWidth > constraints.maxWidth
                    ? computedWidth
                    : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: _LineChart(
                      series: [fuelSpots, serviceSpots],
                      colors: [DomendraTheme.warning, DomendraTheme.info],
                      xLabels: xLabels,
                      maxY: maxY * 1.2,
                    ),
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
// Monthly Summary Card
// ════════════════════════════════════════════════════════════
class _MonthlySummaryCard extends StatelessWidget {
  final DashboardProvider dash;
  const _MonthlySummaryCard({required this.dash});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(Icons.payments, DomendraTheme.success, 'Revenue', dash.monthlyRevenue),
      _SummaryItem(Icons.receipt_long, DomendraTheme.info, 'Rental Total', dash.monthlyRentalTotal),
      _SummaryItem(Icons.local_gas_station, DomendraTheme.warning, 'Fuel Cost', dash.monthlyFuelCost),
      _SummaryItem(Icons.build, DomendraTheme.danger, 'Service Cost', dash.monthlyServiceCost),
      _SummaryItem(Icons.car_crash, DomendraTheme.danger, 'Accidents', dash.monthlyAccidents.toDouble()),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(item.icon, color: item.color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: DomendraTheme.onSurface))),
              Text(
                item.isMoney ? _fmtCurrency(context, item.value) : item.value.toStringAsFixed(0),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: item.color),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final Color color;
  final String label;
  final double value;
  bool get isMoney => label != 'Accidents';
  const _SummaryItem(this.icon, this.color, this.label, this.value);
}

// ════════════════════════════════════════════════════════════
// 5. Monthly Bar Chart
// ════════════════════════════════════════════════════════════
class _MonthlyBarChart extends StatelessWidget {
  final DashboardProvider dash;
  const _MonthlyBarChart({required this.dash});

  @override
  Widget build(BuildContext context) {
    final bars = dash.monthlyBar;
    double maxVal = 0;
    for (final b in bars) {
      final v = (b['value'] as num?)?.toDouble() ?? 0;
      if (v > maxVal) maxVal = v;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      height: 200,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _chartTitle('Monthly Summary'),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          (bars[i]['label'] as String?) ?? '',
                          style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      _compactNum(value),
                      style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted),
                    ),
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: bars.asMap().entries.map((e) {
                final v = (e.value['value'] as num?)?.toDouble() ?? 0;
                final c = _hexColor(e.value['color'] as String?) ?? DomendraTheme.primary;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: v, color: c, width: 24, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Revenue by Type Chart
// ════════════════════════════════════════════════════════════
class _RevenueByTypeChart extends StatelessWidget {
  final DashboardProvider dash;
  const _RevenueByTypeChart({required this.dash});

  @override
  Widget build(BuildContext context) {
    final items = dash.revenueByType;
    double maxVal = 0;
    for (final r in items) {
      final v = (r['total'] as num?)?.toDouble() ?? 0;
      if (v > maxVal) maxVal = v;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      height: 220,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _chartTitle('Revenue by Vehicle Type'),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.15,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= items.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 60,
                          child: Text(
                            (items[i]['type'] as String?) ?? '',
                            style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
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
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: items.asMap().entries.map((e) {
                final v = (e.value['total'] as num?)?.toDouble() ?? 0;
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: v, color: _typeColor(e.key), width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Color _typeColor(int i) {
    const colors = [
      Color(0xFF4F46E5), Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF8B5CF6),
    ];
    return colors[i % colors.length];
  }
}

// ════════════════════════════════════════════════════════════
// 6. Fleet Pie Chart
// ════════════════════════════════════════════════════════════
class PieData {
  final String label;
  final double value;
  PieData({required this.label, required this.value});
}

class _FleetPieChart extends StatelessWidget {
  final String title;
  final List<PieData> data;
  const _FleetPieChart({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, e) => sum + e.value);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _chartTitle(title),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sections: data.asMap().entries.map((e) {
                    final color = _pieColor(e.key);
                    return PieChartSectionData(
                      value: e.value.value,
                      color: color,
                      radius: 55,
                      title: total > 0 ? '${(e.value.value / total * 100).round()}%' : '',
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 35,
                  sectionsSpace: 2,
                )),
                Positioned(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${total.round()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
                      const Text('Total', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: data.asMap().entries.map((e) {
              return _Legend([
                _LegendItem(color: _pieColor(e.key), label: '${e.value.label} (${e.value.value.round()})'),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _pieColor(int i) {
    const colors = [
      Color(0xFF4F46E5), Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEF4444), Color(0xFF3B82F6), Color(0xFF8B5CF6),
      Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF97316),
    ];
    return colors[i % colors.length];
  }
}

// ════════════════════════════════════════════════════════════
// 7. Alerts Grid
// ════════════════════════════════════════════════════════════
class _AlertsGrid extends StatelessWidget {
  final DashboardProvider dash;
  const _AlertsGrid({required this.dash});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      _AlertData(Icons.warning_amber, DomendraTheme.danger, 'Open Issues', dash.openIssues),
      _AlertData(Icons.error_outline, DomendraTheme.danger, 'Critical', dash.criticalIssues),
      _AlertData(Icons.build, DomendraTheme.warning, 'Work Orders', dash.openWorkOrders),
      _AlertData(Icons.notifications_off, DomendraTheme.danger, 'Overdue Rem.', dash.overdueReminders),
      _AlertData(Icons.file_present, DomendraTheme.danger, 'Expired Docs', dash.expiredDocs),
      _AlertData(Icons.inventory_2, DomendraTheme.warning, 'Low Stock', dash.lowStockItems),
    ];

    return Column(
      children: [
        for (int i = 0; i < alerts.length; i += 2) ...[
          Row(
            children: [
              Expanded(child: _AlertCard(alerts[i])),
              const SizedBox(width: 10),
              Expanded(child: _AlertCard(alerts[i + 1])),
            ],
          ),
          if (i < alerts.length - 2) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AlertData {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  const _AlertData(this.icon, this.color, this.label, this.count);
}

class _AlertCard extends StatelessWidget {
  final _AlertData alert;
  const _AlertCard(this.alert);

  @override
  Widget build(BuildContext context) {
    final isZero = alert.count == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isZero ? DomendraTheme.surface : alert.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isZero ? DomendraTheme.outline : alert.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(alert.icon, color: isZero ? DomendraTheme.onSurfaceMuted : alert.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.count}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isZero ? DomendraTheme.onSurfaceMuted : alert.color, height: 1),
                ),
                Text(alert.label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Upcoming Card
// ════════════════════════════════════════════════════════════
class _UpcomingCard extends StatelessWidget {
  final DashboardProvider dash;
  const _UpcomingCard({required this.dash});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartTitle('Upcoming (7-30 days)'),
          const SizedBox(height: 10),
          _upcomingRow(Icons.notifications_active, DomendraTheme.warning, 'Reminders (7d)', dash.reminders7d),
          _upcomingRow(Icons.file_copy, DomendraTheme.info, 'Expiring Docs (30d)', dash.expiringDocs30d),
          _upcomingRow(Icons.fact_check, DomendraTheme.success, 'Inspections (30d)', dash.recentInspections30d),
        ],
      ),
    );
  }

  Widget _upcomingRow(IconData icon, Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: DomendraTheme.onSurface))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 8. Trend Chart
// ════════════════════════════════════════════════════════════
class _TrendChart extends StatefulWidget {
  final DashboardProvider dash;
  const _TrendChart({required this.dash});

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

enum _TrendPeriod { week, month, year, custom }

class _TrendChartState extends State<_TrendChart> {
  _TrendPeriod _period = _TrendPeriod.year;
  DateTime? _customStart;
  DateTime? _customEnd;

  void _setPeriod(_TrendPeriod p) {
    setState(() => _period = p);
    _fetchTrend();
  }

  void _fetchTrend() {
    final dash = widget.dash;
    if (_period == _TrendPeriod.custom) {
      if (_customStart == null || _customEnd == null) return;
      dash.fetchTrend(
        start: _toIso(_customStart!),
        end: _toIso(_customEnd!),
        period: 'custom',
      );
      return;
    }
    dash.fetchTrend(period: _period.name);
  }

  static String _toIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? (_customStart ?? DateTime.now())
        : (_customEnd ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
      } else {
        _customEnd = picked;
      }
    });
    if (_customStart != null && _customEnd != null) _fetchTrend();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.dash.trend;
    final revSpots = <FlSpot>[];
    final paySpots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < items.length; i++) {
      final rev = (items[i]['revenue'] as num?)?.toDouble() ?? 0;
      final pay = (items[i]['payments'] as num?)?.toDouble() ?? 0;
      revSpots.add(FlSpot(i.toDouble(), rev));
      paySpots.add(FlSpot(i.toDouble(), pay));
      if (rev > maxY) maxY = rev;
      if (pay > maxY) maxY = pay;
    }
    final xLabels = items.map((t) {
      final date = t['date'] as String?;
      if (date == null) return '';
      try {
        final dt = DateTime.parse(date);
        return '${dt.month}/${dt.day}';
      } catch (_) {
        return date;
      }
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      height: _period == _TrendPeriod.custom ? 300 : 240,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chartTitle('Rental & Revenue Trend'),
              if (widget.dash.trendPeriod.isNotEmpty)
                Text(
                  widget.dash.trendPeriod[0].toUpperCase() + widget.dash.trendPeriod.substring(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.primary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _TrendPeriod.values.map((p) {
                final selected = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                    selected: selected,
                    onSelected: (_) => _setPeriod(p),
                    selectedColor: DomendraTheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : DomendraTheme.onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_period == _TrendPeriod.custom) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start',
                    value: _customStart,
                    onChanged: (d) {
                      setState(() => _customStart = d);
                      if (_customEnd != null) _fetchTrend();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'End',
                    value: _customEnd,
                    onChanged: (d) {
                      setState(() => _customEnd = d);
                      if (_customStart != null) _fetchTrend();
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          _Legend([
            _LegendItem(color: DomendraTheme.info, label: 'Revenue'),
            _LegendItem(color: DomendraTheme.success, label: 'Payments'),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Give each data point ~50px; use the wider of computed vs available.
                final computedWidth = items.length * 50.0;
                final chartWidth = computedWidth > constraints.maxWidth
                    ? computedWidth
                    : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: _LineChart(
                      series: [revSpots, paySpots],
                      colors: [DomendraTheme.info, DomendraTheme.success],
                      xLabels: xLabels,
                      maxY: maxY * 1.2,
                      showDots: true,
                    ),
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
// 9. Recent Activity Tables
// ════════════════════════════════════════════════════════════
class _RecentRentalsCard extends StatelessWidget {
  final DashboardProvider dash;
  const _RecentRentalsCard({required this.dash});

  @override
  Widget build(BuildContext context) {
    final rentals = dash.recentRentals;
    if (rentals.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _chartTitle('Recent Rentals'),
          ),
          ...rentals.map((r) => _RentalTile(rental: r)),
        ],
      ),
    );
  }
}

class _RentalTile extends StatelessWidget {
  final dynamic rental;
  const _RentalTile({required this.rental});

  @override
  Widget build(BuildContext context) {
    final r = rental as Map<String, dynamic>;
    final agNo = r['agreement_no'] as String? ?? '#${r['id'] ?? ''}';
    final customer = r['customer_name'] as String? ?? '';
    final vehicle = r['vehicle_display'] as String? ?? '';
    final status = r['status'] as String? ?? 'draft';
    final amount = (r['total_amount'] as num?)?.toDouble() ?? 0;
    final (color, label) = _rentalStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: DomendraTheme.outline, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                if (customer.isNotEmpty) Text(customer, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(vehicle, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(width: 8),
          Text(_fmtCurrency(context, amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
        ],
      ),
    );
  }

  (Color, String) _rentalStatus(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'on_rent':
        return (DomendraTheme.success, 'ACTIVE');
      case 'completed':
      case 'returned':
        return (DomendraTheme.info, 'DONE');
      case 'overdue':
        return (DomendraTheme.danger, 'OVERDUE');
      case 'cancelled':
        return (DomendraTheme.onSurfaceMuted, 'CXL');
      case 'draft':
        return (DomendraTheme.warning, 'DRAFT');
      default:
        return (DomendraTheme.onSurfaceMuted, s.toUpperCase());
    }
  }
}

class _RecentFuelServicesCard extends StatefulWidget {
  final DashboardProvider dash;
  const _RecentFuelServicesCard({required this.dash});

  @override
  State<_RecentFuelServicesCard> createState() => _RecentFuelServicesCardState();
}

class _RecentFuelServicesCardState extends State<_RecentFuelServicesCard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: DomendraTheme.primary,
              labelColor: DomendraTheme.primary,
              unselectedLabelColor: DomendraTheme.onSurfaceMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(icon: Icon(Icons.local_gas_station, size: 18), text: 'Fuel'),
                Tab(icon: Icon(Icons.build, size: 18), text: 'Services'),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _tabController,
              children: [
                _FuelList(items: widget.dash.recentFuel),
                _ServiceList(items: widget.dash.recentServices),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelList extends StatelessWidget {
  final List<dynamic> items;
  const _FuelList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No recent fuel transactions', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: DomendraTheme.outline),
      itemBuilder: (context, i) {
        final f = items[i] as Map<String, dynamic>;
        final vehicle = f['vehicle_display'] as String? ?? '';
        final fuelType = f['fuel_type'] as String? ?? '';
        final qty = f['quantity'] as num?;
        final cost = (f['total_cost'] as num?)?.toDouble() ?? 0;
        final date = f['date'] as String?;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_gas_station, color: DomendraTheme.warning, size: 22),
          title: Text(vehicle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DomendraTheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('$fuelType · ${qty ?? ''} · ${_fmtDate(date)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          trailing: Text(_fmtCurrency(context, cost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.warning)),
        );
      },
    );
  }
}

class _ServiceList extends StatelessWidget {
  final List<dynamic> items;
  const _ServiceList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No recent services', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: DomendraTheme.outline),
      itemBuilder: (context, i) {
        final s = items[i] as Map<String, dynamic>;
        final vehicle = s['vehicle_display'] as String? ?? '';
        final serviceType = s['service_type'] as String? ?? '';
        final cost = (s['cost'] as num?)?.toDouble() ?? 0;
        final date = s['performed_at'] as String?;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.build, color: DomendraTheme.danger, size: 22),
          title: Text(vehicle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DomendraTheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('$serviceType · ${_fmtDate(date)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          trailing: Text(_fmtCurrency(context, cost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.danger)),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared widgets & helpers
// ════════════════════════════════════════════════════════════
class _LineChart extends StatelessWidget {
  final List<List<FlSpot>> series;
  final List<Color> colors;
  final List<String> xLabels;
  final double maxY;
  final bool showDots;

  const _LineChart({
    required this.series,
    required this.colors,
    required this.xLabels,
    required this.maxY,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
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
            interval: 1,
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
      maxY: maxY == 0 ? 1 : maxY,
      lineBarsData: series.asMap().entries.map((e) {
        return LineChartBarData(
          spots: e.value,
          isCurved: true,
          color: colors[e.key],
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: showDots),
          belowBarData: BarAreaData(
            show: true,
            color: colors[e.key].withOpacity(0.08),
          ),
        );
      }).toList(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                _compactNum(spot.y),
                TextStyle(color: colors[spot.spotIndex], fontWeight: FontWeight.w700, fontSize: 12),
              );
            }).toList();
          },
        ),
      ),
    ));
  }
}

class _Legend extends StatelessWidget {
  final List<_LegendItem> items;
  const _Legend(this.items);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(item.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted)),
          ],
        ),
      )).toList(),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: DomendraTheme.danger),
          const SizedBox(height: 16),
          const Text('Failed to load dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Utilities ─────────────────────────────────────────────
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: DomendraTheme.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: DomendraTheme.outline),
  );
}

Widget _chartTitle(String text) {
  return Row(
    children: [
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
    ],
  );
}

String _fmtCurrency(BuildContext context, double v) {
  final sym = Provider.of<DashboardProvider>(context, listen: false).currencySymbol;
  if (v >= 1000000) return '$sym ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '$sym ${(v / 1000).toStringAsFixed(1)}K';
  return '$sym ${v.toStringAsFixed(0)}';
}

String _compactNum(double v) {
  if (v == 0) return '0';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}

String _fmtDate(String? iso) {
  if (iso == null) return '';
  try {
    final d = DateTime.parse(iso);
    return '${_monthShort(d.month)} ${d.day}';
  } catch (_) {
    return iso;
  }
}

String _monthShort(int m) {
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[m - 1];
}

Color? _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return null;
  }
}
