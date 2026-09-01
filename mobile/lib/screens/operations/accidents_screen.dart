import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/accidents_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Accidents screen — mirrors web `/app/accidents`.
/// 2 tabs: Reports, Claims.
class AccidentsScreen extends StatefulWidget {
  const AccidentsScreen({super.key});
  @override
  State<AccidentsScreen> createState() => _AccidentsScreenState();
}

class _AccidentsScreenState extends State<AccidentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.error_outline, size: 18), text: 'Reports'),
    Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Claims'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<AccidentsProvider>().fetchAll();
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
        title: const Text('Accidents'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => context.read<AccidentsProvider>().fetchAll())],
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
      drawer: const AppDrawer(currentRoute: '/accidents'),
      body: Column(
        children: [
          _KpiBar(),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [_ReportsTab(), _ClaimsTab()],
          )),
        ],
      ),
    );
  }
}

class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AccidentsProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(children: [
        Expanded(child: _Mini(label: 'Total', value: '${p.totalAccidents}', color: const Color(0xFFEF4444), icon: Icons.error_outline)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Open', value: '${p.openAccidents}', color: const Color(0xFFF59E0B), icon: Icons.pending)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Resolved', value: '${p.resolvedAccidents}', color: const Color(0xFF10B981), icon: Icons.check_circle)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Damage', value: '$_currencySymbol${_fmtShort(p.totalDamageCost)}', color: DomendraTheme.primary, icon: Icons.payments)),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Mini({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1))]), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)]),
  );
}

class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AccidentsProvider>();
    final reports = p.reports;
    if (reports.isEmpty) return const Center(child: Text('No accident reports', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: reports.length,
      itemBuilder: (_, i) {
        final r = reports[i] as Map<String, dynamic>;
        return _ReportCard(report: r);
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final id = toIntOr(report['id']);
    final vehicle = report['vehicle_name'] as String? ?? 'Unknown';
    final driver = report['driver_name'] as String? ?? '—';
    final date = report['accident_date'] as String?;
    final location = report['location'] as String? ?? '';
    final status = report['status'] as String? ?? 'reported';
    final damageCost = toDoubleOr(report['estimated_damage_cost']);
    final severity = report['severity'] as String? ?? 'minor';
    final statusColor = _statusColor(status);
    final sevColor = _severityColor(severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.error_outline, size: 16, color: statusColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vehicle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), Text(driver, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor))),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sevColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(severity, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sevColor))),
          ]),
        ]),
        if (location.isNotEmpty) ...[const SizedBox(height: 6), Row(children: [const Icon(Icons.place, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(location, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))])],
        if (date != null) ...[const SizedBox(height: 2), Row(children: [const Icon(Icons.calendar_today, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Text(_fmtDate(date), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))])],
        if (damageCost > 0) ...[const SizedBox(height: 4), Text('$_currencySymbol${damageCost.toStringAsFixed(0)} damage', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.danger))],
      ]),
    );
  }
}

class _ClaimsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AccidentsProvider>();
    final claims = p.claims;
    if (claims.isEmpty) return const Center(child: Text('No insurance claims', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: claims.length,
      itemBuilder: (_, i) {
        final c = claims[i] as Map<String, dynamic>;
        final claimNumber = c['claim_number'] as String? ?? '—';
        final accidentRef = toInt(c['accident_report']);
        final status = c['status'] as String? ?? 'pending';
        final settledAmount = toDoubleOr(c['settled_amount']);
        final claimedAmount = toDoubleOr(c['claimed_amount']);
        final insurer = c['insurer_name'] as String? ?? '';
        final statusColor = _statusColor(status);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(claimNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)))]),
            if (insurer.isNotEmpty) Text(insurer, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
            const SizedBox(height: 6),
            Row(children: [Expanded(child: Text('Claimed: $_currencySymbol${claimedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted))), Text('Settled: $_currencySymbol${settledAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.success))]),
          ]),
        );
      },
    );
  }
}

Color _statusColor(String s) => switch (s) {
  'open' || 'reported' => const Color(0xFFF59E0B),
  'resolved' || 'closed' || 'settled' || 'paid' => const Color(0xFF10B981),
  'pending' || 'submitted' => const Color(0xFF3B82F6),
  'rejected' || 'denied' => const Color(0xFFEF4444),
  _ => const Color(0xFF94A3B8),
};

Color _severityColor(String s) => switch (s) {
  'critical' || 'major' => const Color(0xFFEF4444),
  'moderate' => const Color(0xFFF59E0B),
  'minor' => const Color(0xFF10B981),
  _ => const Color(0xFF94A3B8),
};

String _fmtDate(String d) {
  try {
    final dt = DateTime.parse(d);
    return '${dt.month}/${dt.day}/${dt.year}';
  } catch (_) { return d; }
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
