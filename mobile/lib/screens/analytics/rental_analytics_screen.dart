import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Car Hire & Rental Analytics screen — mirrors `pages/app/analytics/rentals.vue`.
/// 3 tabs: Overview, Revenue & Payments, Customers & Vehicles.
class RentalAnalyticsScreen extends StatefulWidget {
  const RentalAnalyticsScreen({super.key});

  @override
  State<RentalAnalyticsScreen> createState() => _RentalAnalyticsScreenState();
}

class _RentalAnalyticsScreenState extends State<RentalAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Revenue & Payments'),
    Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Customers & Vehicles'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<AnalyticsProvider>().fetchRentalAnalytics();
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
        title: const Text('Car Hire & Rental Analytics'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<AnalyticsProvider>().fetchRentalAnalytics(),
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
      drawer: const AppDrawer(currentRoute: '/analytics/rentals'),
      body: Column(
        children: [
          _PeriodBar(onChanged: () => context.read<AnalyticsProvider>().fetchRentalAnalytics()),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(),
                _RevenueTab(),
                _CustomersTab(),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Chip(label: 'All', value: 'all', group: p.rentalPeriod, onSel: (v) { p.setRentalPeriod(v); onChanged(); }),
          _Chip(label: 'Yr', value: 'y', group: p.rentalPeriod, onSel: (v) { p.setRentalPeriod(v); onChanged(); }),
          _Chip(label: '365d', value: '365', group: p.rentalPeriod, onSel: (v) { p.setRentalPeriod(v); onChanged(); }),
          _Chip(label: '90d', value: '90', group: p.rentalPeriod, onSel: (v) { p.setRentalPeriod(v); onChanged(); }),
          _Chip(label: 'Custom…', value: 'custom', group: p.rentalPeriod, onSel: (v) {
            p.setRentalPeriod(v);
            _showRentalCustomDateDialog(context, onChanged);
          }),
        ]),
      ),
    );
  }
}

void _showRentalCustomDateDialog(BuildContext context, VoidCallback onChanged) {
  final p = context.read<AnalyticsProvider>();
  DateTime? tempFrom = p.rentalCustomFrom ?? DateTime.now().subtract(const Duration(days: 365));
  DateTime? tempTo = p.rentalCustomTo ?? DateTime.now();

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
              p.setRentalCustomFrom(tempFrom);
              p.setRentalCustomTo(tempTo);
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
// KPI HEADER
// ════════════════════════════════════════════════════════════
class _KpiHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    if (p.rentalLoading && p.agreements.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Primary KPI row
          Row(children: [
            Expanded(child: _KpiCard(label: 'Agreements', value: '${p.rentalTotal}', gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]), icon: Icons.assignment)),
            const SizedBox(width: 4),
            Expanded(child: _KpiCard(label: 'Revenue', value: _fmtMoney(p.rentalRevenue), gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]), icon: Icons.payments)),
            const SizedBox(width: 4),
            Expanded(child: _KpiCard(label: 'Collection', value: '${p.collectionRate}%', gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]), icon:Icons.percent)),
            const SizedBox(width: 4),
            Expanded(child: _KpiCard(label: 'Outstanding', value: _fmtMoney(p.rentalOutstanding), gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF87171)]), icon: Icons.money_off)),
          ]),
          const SizedBox(height: 4),
          // Secondary KPI row
          Row(children: [
            Expanded(child: _SmallStat(label: 'Active', value: '${p.rentalActive}', color: const Color(0xFF10B981))),
            const SizedBox(width: 4),
            Expanded(child: _SmallStat(label: 'Overdue', value: '${p.rentalOverdue}', color: const Color(0xFFEF4444))),
            const SizedBox(width: 4),
            Expanded(child: _SmallStat(label: 'Customers', value: '${p.rentalCustomers}', color: const Color(0xFF6366F1))),
            const SizedBox(width: 4),
            Expanded(child: _SmallStat(label: 'Payments', value: '${p.rentalPaymentCount}', color: const Color(0xFF8B5CF6))),
          ]),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1: OVERVIEW
// ════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    // Agreement status distribution
    final statusCounts = <String, int>{};
    for (final a in p.filteredAgreements) {
      final s = _effectiveStatus(a);
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }
    final statusEntries = statusCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Payment status distribution
    final payStatusCounts = <String, int>{};
    for (final pay in p.filteredPayments) {
      final s = (pay['status'] as String?) ?? 'pending';
      payStatusCounts[s] = (payStatusCounts[s] ?? 0) + 1;
    }
    final payEntries = payStatusCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Agreement trend (by month from created_at)
    final trendMap = <String, int>{};
    for (final a in p.filteredAgreements) {
      final dt = _agreementDate(a);
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      trendMap[key] = (trendMap[key] ?? 0) + 1;
    }
    final trendEntries = trendMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxTrend = trendEntries.isEmpty ? 1 : trendEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        // Agreement status
        _SectionTitle(title: 'Agreement Status', icon: Icons.assignment_outlined),
        if (statusEntries.isEmpty)
          const _Empty()
        else
          ...statusEntries.map((e) => _BarRow(label: _rentalStatus(e.key), value: e.value.toDouble(), max: statusEntries.first.value.toDouble(), color: _rentalStatusColor(e.key), format: _fmtNum)),
        const SizedBox(height: 16),
        // Payment status
        _SectionTitle(title: 'Payment Status', icon: Icons.payments_outlined),
        if (payEntries.isEmpty)
          const _Empty()
        else
          ...payEntries.map((e) => _BarRow(label: _rentalStatus(e.key), value: e.value.toDouble(), max: payEntries.first.value.toDouble(), color: _rentalStatusColor(e.key), format: _fmtNum)),
        const SizedBox(height: 16),
        // Agreement trend
        _SectionTitle(title: 'Agreement Trend', icon: Icons.show_chart),
        if (trendEntries.isEmpty)
          const _Empty()
        else
          ...trendEntries.take(12).map((e) => _BarRow(label: e.key, value: e.value.toDouble(), max: maxTrend.toDouble(), color: DomendraTheme.primary, format: _fmtNum)),
        const SizedBox(height: 16),
        // Status summary list
        _SectionTitle(title: 'Status Summary', icon: Icons.list),
        if (statusEntries.isEmpty)
          const _Empty()
        else
          ...statusEntries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _rentalStatusColor(e.key), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(child: Text(_rentalStatus(e.key), style: const TextStyle(fontSize: 12))),
              Text('${e.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          )),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2: REVENUE & PAYMENTS
// ════════════════════════════════════════════════════════════
class _RevenueTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    // Revenue trend (monthly from agreements)
    final revMap = <String, double>{};
    for (final a in p.filteredAgreements) {
      final dt = _agreementDate(a);
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      revMap[key] = (revMap[key] ?? 0) + _parseDouble(a['total_amount']);
    }
    final revEntries = revMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxRev = revEntries.isEmpty ? 1.0 : revEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Payment methods
    final payMethods = <String, double>{};
    for (final pay in p.filteredPayments) {
      final m = (pay['payment_method'] as String?) ?? 'unknown';
      payMethods[m] = (payMethods[m] ?? 0) + _parseDouble(pay['amount']);
    }
    final methodEntries = payMethods.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxMethod = methodEntries.isEmpty ? 1.0 : methodEntries.first.value;

    // Monthly collected vs revenue
    final colMap = <String, double>{};
    for (final pay in p.filteredPayments) {
      final paidAt = pay['paid_at'] as String?;
      if (paidAt == null) continue;
      final dt = DateTime.tryParse(paidAt);
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      if (pay['status'] == 'paid' || pay['status'] == 'completed') {
        colMap[key] = (colMap[key] ?? 0) + _parseDouble(pay['amount']);
      }
    }
    final colEntries = colMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Collected', value: _fmtMoney(p.rentalCollected), color: DomendraTheme.success)),
          const SizedBox(width: 4),
          Expanded(child: _MiniStat(label: 'Outstanding', value: _fmtMoney(p.rentalOutstanding), color: DomendraTheme.danger)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Invoiced', value: _fmtMoney(p.rentalRevenue), color: DomendraTheme.info)),
          const SizedBox(width: 4),
          Expanded(child: _MiniStat(label: 'Collection Rate', value: '${p.collectionRate}%', color: DomendraTheme.primary)),
        ]),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Revenue Trend', icon: Icons.show_chart),
        if (revEntries.isEmpty)
          const _Empty()
        else
          ...revEntries.take(12).map((e) => _BarRow(label: e.key, value: e.value, max: maxRev, color: const Color(0xFF10B981), format: _fmtMoney)),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Payment Methods', icon: Icons.payments_outlined),
        if (methodEntries.isEmpty)
          const _Empty()
        else
          ...methodEntries.map((e) => _BarRow(label: paymentMethodLabels[e.key] ?? e.key, value: e.value, max: maxMethod, color: DomendraTheme.primary, format: _fmtMoney)),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Monthly Collected', icon: Icons.savings_outlined),
        if (colEntries.isEmpty)
          const _Empty()
        else
          ...colEntries.take(12).map((e) => _BarRow(label: e.key, value: e.value, max: colEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b), color: const Color(0xFF3B82F6), format: _fmtMoney)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3: CUSTOMERS & VEHICLES
// ════════════════════════════════════════════════════════════
class _CustomersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    // Customer type distribution
    final localCount = p.rentalLocal;
    final foreignerCount = p.rentalForeigner;
    final totalCustomers = p.rentalCustomers;

    // Top vehicles by rental count
    final vehicleCounts = <String, int>{};
    for (final a in p.filteredAgreements) {
      final vId = a['vehicle']?.toString();
      if (vId == null) continue;
      final vName = a['vehicle_name'] as String? ?? a['vehicle__license_plate'] as String? ?? 'Vehicle #$vId';
      vehicleCounts[vName] = (vehicleCounts[vName] ?? 0) + 1;
    }
    final vehicleEntries = vehicleCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVehicle = vehicleEntries.isEmpty ? 1 : vehicleEntries.first.value;

    // Top customers by total spent
    final customerSpend = <String, double>{};
    for (final a in p.filteredAgreements) {
      final cId = a['customer']?.toString();
      if (cId == null) continue;
      final cName = a['customer_name'] as String? ?? 'Customer #$cId';
      customerSpend[cName] = (customerSpend[cName] ?? 0) + _parseDouble(a['total_amount']);
    }
    final customerEntries = customerSpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCust = customerEntries.isEmpty ? 1.0 : customerEntries.first.value;

    // Customer breakdown (local vs foreigner as percentages)
    final localPct = totalCustomers > 0 ? (localCount / totalCustomers * 100) : 0.0;
    final foreignerPct = totalCustomers > 0 ? (foreignerCount / totalCustomers * 100) : 0.0;

    // Average rental duration
    final durations = <double>[];
    for (final a in p.filteredAgreements) {
      final start = _parseDate(a['start_datetime']);
      final end = _parseDate(a['end_datetime']);
      if (start != null && end != null && end.isAfter(start)) {
        durations.add(end.difference(start).inHours / 24.0);
      }
    }
    final avgDuration = durations.isEmpty ? 0.0 : durations.reduce((a, b) => a + b) / durations.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KpiHeader(),
        const SizedBox(height: 12),
        // Customer type
        _SectionTitle(title: 'Customer Type', icon: Icons.people_outline),
        Row(children: [
          Expanded(child: _TypeCard(label: 'Local', count: localCount, pct: localPct, color: const Color(0xFF6366F1))),
          const SizedBox(width: 4),
          Expanded(child: _TypeCard(label: 'Foreigner', count: foreignerCount, pct: foreignerPct, color: const Color(0xFF10B981))),
        ]),
        const SizedBox(height: 16),
        // Top vehicles
        _SectionTitle(title: 'Top Vehicles by Rentals', icon: Icons.directions_car_outlined),
        if (vehicleEntries.isEmpty)
          const _Empty()
        else
          ...vehicleEntries.take(10).map((e) => _BarRow(label: e.key, value: e.value.toDouble(), max: maxVehicle.toDouble(), color: const Color(0xFF6366F1), format: _fmtNum)),
        const SizedBox(height: 16),
        // Top customers
        _SectionTitle(title: 'Top Customers by Revenue', icon: Icons.star),
        if (customerEntries.isEmpty)
          const _Empty()
        else
          ...customerEntries.take(10).map((e) => _BarRow(label: e.key, value: e.value, max: maxCust, color: const Color(0xFFF59E0B), format: _fmtMoney)),
        const SizedBox(height: 16),
        // Average rental duration
        Row(children: [
          Expanded(child: _MiniStat(label: 'Unique Vehicles', value: '${p.uniqueVehicles}', color: DomendraTheme.primary)),
          const SizedBox(width: 4),
          Expanded(child: _MiniStat(label: 'Avg Duration', value: '${avgDuration.toStringAsFixed(1)} days', color: DomendraTheme.info)),
          const SizedBox(width: 4),
          Expanded(child: _MiniStat(label: 'Total Customers', value: '${p.rentalCustomers}', color: DomendraTheme.success)),
        ]),
      ],
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

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SmallStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis), Text(label, style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)]),
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

class _TypeCard extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  const _TypeCard({required this.label, required this.count, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (pct / 100).clamp(0.0, 1.0), color: color, backgroundColor: color.withOpacity(0.1), minHeight: 5)), const SizedBox(height: 4), Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))]),
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
      child: Row(children: [SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 8))), const SizedBox(width: 8), SizedBox(width: 55, child: Text(format(value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis))]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)));
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

DateTime? _agreementDate(Map<String, dynamic> a) {
  final created = a['created_at'] as String?;
  final start = a['start_datetime'] as String?;
  return DateTime.tryParse(created ?? '') ?? DateTime.tryParse(start ?? '');
}

String _effectiveStatus(Map<String, dynamic> a) {
  final status = a['status'] as String? ?? 'draft';
  if (status == 'active') {
    final endStr = a['end_datetime'] as String?;
    final end = endStr != null ? DateTime.tryParse(endStr) : null;
    if (end != null && end.isBefore(DateTime.now())) return 'overdue';
  }
  return status;
}

String _rentalStatus(String s) {
  final v = rentalStatusMap[s];
  if (v != null && v is Map) return (v as Map)['label'] as String? ?? s;
  return s;
}

Color _rentalStatusColor(String s) {
  switch (s) {
    case 'active': return const Color(0xFF10B981);
    case 'overdue': return const Color(0xFFEF4444);
    case 'completed': return const Color(0xFF3B82F6);
    case 'cancelled': return const Color(0xFF64748B);
    case 'draft': return const Color(0xFFF59E0B);
    case 'pending': return const Color(0xFFF59E0B);
    case 'paid': return const Color(0xFF10B981);
    default: return const Color(0xFF94A3B8);
  }
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String _fmtMoney(double v) => '$_currencySymbol${v >= 1000 ? _fmtShort(v) : v.toStringAsFixed(2)}';
String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
String _fmtNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
