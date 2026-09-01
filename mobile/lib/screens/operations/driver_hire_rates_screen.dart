import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/driver_hire_rates_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Driver Hire Rates screen — mirrors web `/app/rentals/driver-hire-rates`.
class DriverHireRatesScreen extends StatefulWidget {
  const DriverHireRatesScreen({super.key});
  @override
  State<DriverHireRatesScreen> createState() => _DriverHireRatesScreenState();
}

class _DriverHireRatesScreenState extends State<DriverHireRatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<DriverHireRatesProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Driver Hire Rates'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => context.read<DriverHireRatesProvider>().fetchAll())],
      ),
      drawer: const AppDrawer(currentRoute: '/driver-hire-rates'),
      body: Column(
        children: [
          _KpiBar(),
          Expanded(child: _RatesList()),
        ],
      ),
    );
  }
}

class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriverHireRatesProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(children: [
        Expanded(child: _Mini(label: 'Total Rates', value: '${p.rates.length}', color: DomendraTheme.primary, icon: Icons.payments_outlined)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Active', value: '${p.activeCount}', color: const Color(0xFF10B981), icon: Icons.check_circle)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Avg Daily', value: '$_currencySymbol${_fmtShort(p.avgDaily)}', color: const Color(0xFF3B82F6), icon: Icons.today)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Avg Weekly', value: '$_currencySymbol${_fmtShort(p.avgWeekly)}', color: const Color(0xFFF59E0B), icon: Icons.date_range)),
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

class _RatesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriverHireRatesProvider>();
    final rates = p.rates;
    if (rates.isEmpty) return const Center(child: Text('No driver hire rate plans', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: rates.length,
      itemBuilder: (_, i) {
        final r = rates[i] as Map<String, dynamic>;
        final id = toIntOr(r['id']);
        final driver = r['driver_name'] as String? ?? 'Unknown';
        final vehicleType = r['vehicle_type_name'] as String? ?? r['vehicle_type'] as String? ?? '—';
        final dailyRate = toDoubleOr(r['daily_rate']);
        final weeklyRate = toDoubleOr(r['weekly_rate']);
        final monthlyRate = toDoubleOr(r['monthly_rate']);
        final isActive = r['is_active'] as bool? ?? true;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.person_4, size: 16, color: DomendraTheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(driver, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), Text(vehicleType, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _RateChip(label: 'Daily', value: '$_currencySymbol${dailyRate.toStringAsFixed(0)}', color: const Color(0xFF3B82F6))),
                const SizedBox(width: 4),
                Expanded(child: _RateChip(label: 'Weekly', value: '$_currencySymbol${weeklyRate.toStringAsFixed(0)}', color: const Color(0xFFF59E0B))),
                const SizedBox(width: 4),
                Expanded(child: _RateChip(label: 'Monthly', value: '$_currencySymbol${monthlyRate.toStringAsFixed(0)}', color: DomendraTheme.primary)),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _RateChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RateChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.15))),
    child: Column(children: [Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)]),
  );
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
