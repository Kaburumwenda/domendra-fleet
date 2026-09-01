import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Cost Analysis tab — mirrors web `CostAnalysis.vue`.
///
/// Data from `GET /reports/financial/costs/`.
class CostAnalysisTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const CostAnalysisTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final total = toDouble(data!['total']);
    final totalVariable = toDouble(data!['total_variable']);
    final totalFixed = toDouble(data!['total_fixed']);
    final byCategory = (data!['by_category'] as List?) ?? [];
    final byVehicle = (data!['by_vehicle'] as List?) ?? [];
    final byServiceType = (data!['by_service_type'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top KPIs
        kpiGrid([
          ReportKpiCard(icon: Icons.trending_down, color: DomendraTheme.danger, label: 'Total Costs', value: fmtMoney(total)),
          ReportKpiCard(icon: Icons.fast_rewind, color: DomendraTheme.warning, label: 'Variable Costs', value: fmtMoney(totalVariable)),
          ReportKpiCard(icon: Icons.lock, color: DomendraTheme.info, label: 'Fixed Costs', value: fmtMoney(totalFixed)),
        ]),
        const SizedBox(height: 20),

        // Cost by category
        sectionTitle('Cost by Category'),
        const SizedBox(height: 10),
        reportCard(child: byCategory.isEmpty
            ? tabEmpty(message: 'No category data')
            : Column(
                children: byCategory.map((cat) {
                  final c = cat as Map<String, dynamic>;
                  final amount = toDouble(c['amount']);
                  final pct = total > 0 ? (amount / total * 100) : 0.0;
                  return _categoryRow(
                    c['category'] as String? ?? 'Other',
                    amount,
                    pct,
                    _parseColor(c['color'] as String?),
                    c['type'] as String? ?? 'variable',
                  );
                }).toList(),
              )),
        const SizedBox(height: 20),

        // Cost by vehicle (top 10)
        sectionTitle('Cost by Vehicle (Top 10)'),
        const SizedBox(height: 10),
        reportCard(child: byVehicle.isEmpty
            ? tabEmpty(message: 'No vehicle data')
            : Column(
                children: [
                  for (int i = 0; i < byVehicle.take(10).length; i++) ...[
                    _vehicleRow(byVehicle[i] as Map<String, dynamic>),
                    if (i < 9 && i < byVehicle.length - 1) thinDivider(),
                  ],
                ],
              )),
        const SizedBox(height: 20),

        // Service cost by type
        if (byServiceType.isNotEmpty) ...[
          sectionTitle('Service Cost by Type'),
          const SizedBox(height: 10),
          reportCard(child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: byServiceType.map((st) {
              final s = st as Map<String, dynamic>;
              return _serviceChip(s['type'] as String? ?? 'unknown', toDouble(s['cost']), toInt(s['count']));
            }).toList(),
          )),
        ],
      ],
    );
  }

  Widget _categoryRow(String name, double amount, double pct, Color color, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, size: 14, color: color),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                      const SizedBox(width: 6),
                      statusChip(type, type == 'variable' ? DomendraTheme.warning : DomendraTheme.info),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: DomendraTheme.surfaceVariant,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtMoney(amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
              Text(fmtPct(pct), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ],
      ),
      ],
      ),
    );
  }

  Widget _vehicleRow(Map<String, dynamic> v) {
    final name = v['vehicle'] as String? ?? 'Unknown';
    final fuel = toDouble(v['fuel_cost']);
    final charging = toDouble(v['charging_cost']);
    final service = toDouble(v['service_cost']);
    final fixed = toDouble(v['fixed_cost']);
    final totalCost = toDouble(v['total_cost']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface))),
              Text(fmtMoney(totalCost), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DomendraTheme.danger)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _costSegment('Fuel', fuel, DomendraTheme.warning),
              _costSegment('EV', charging, DomendraTheme.info),
              _costSegment('Svc', service, DomendraTheme.primary),
              _costSegment('Fixed', fixed, DomendraTheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costSegment(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          Text(fmtMoney(amount), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }

  Widget _serviceChip(String type, double cost, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DomendraTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
          const SizedBox(width: 6),
          Text(fmtMoney(cost), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DomendraTheme.danger)),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text('×$count', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
          ],
        ],
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return DomendraTheme.primary;
    try {
      final v = hex.replaceFirst('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return DomendraTheme.primary;
    }
  }
}
