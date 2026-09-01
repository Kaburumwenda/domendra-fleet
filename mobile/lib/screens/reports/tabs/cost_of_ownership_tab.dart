import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Cost of Ownership tab — mirrors web `CostOfOwnershipReport.vue`.
///
/// Data from `GET /reports/financial/ownership/`.
class CostOfOwnershipTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const CostOfOwnershipTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final summary = (data!['summary'] as Map<String, dynamic>?) ?? {};
    final vehicles = (data!['vehicles'] as List?) ?? [];
    final breakdown = (data!['breakdown'] as List?) ?? [];
    final monthly = (data!['monthly'] as List?) ?? [];

    final totalCost = toDouble(summary['total_cost']);
    final totalRevenue = toDouble(summary['total_revenue']);
    final netCost = toDouble(summary['net_cost']);
    final capitalCost = toDouble(summary['capital_cost']);
    final energyCost = toDouble(summary['energy_cost']);
    final operatingCost = toDouble(summary['operating_cost']);
    final bookValue = toDouble(summary['total_book_value']);
    final vehicleCount = toInt(data!['vehicle_count']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI grid
        kpiGrid([
          ReportKpiCard(icon: Icons.domain, color: DomendraTheme.primary, label: 'Capital', value: fmtMoney(capitalCost)),
          ReportKpiCard(icon: Icons.bolt, color: DomendraTheme.warning, label: 'Energy', value: fmtMoney(energyCost)),
          ReportKpiCard(icon: Icons.build, color: DomendraTheme.info, label: 'Operating', value: fmtMoney(operatingCost)),
        ]),
        const SizedBox(height: 10),
        kpiGrid([
          ReportKpiCard(icon: Icons.savings, color: DomendraTheme.danger, label: 'Total Cost (TCO)', value: fmtMoney(totalCost)),
          ReportKpiCard(icon: Icons.trending_up, color: DomendraTheme.success, label: 'Revenue', value: fmtMoney(totalRevenue)),
          ReportKpiCard(icon: Icons.account_balance, color: netCost >= 0 ? DomendraTheme.danger : DomendraTheme.success,
              label: 'Net Cost', value: fmtMoney(netCost)),
        ]),
        const SizedBox(height: 10),
        kpiGrid([
          ReportKpiCard(icon: Icons.menu_book, color: DomendraTheme.secondary, label: 'Book Value', value: fmtMoney(bookValue)),
          ReportKpiCard(icon: Icons.directions_car, color: DomendraTheme.info, label: 'Vehicles', value: fmtNum(vehicleCount)),
        ]),
        const SizedBox(height: 20),

        // Cost breakdown
        if (breakdown.isNotEmpty) ...[
          sectionTitle('Cost Breakdown'),
          const SizedBox(height: 10),
          reportCard(child: Column(
            children: breakdown.map((b) {
              final m = b as Map<String, dynamic>;
              final value = toDouble(m['value']);
              final pct = totalCost > 0 ? (value / totalCost * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] as String? ?? '?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: DomendraTheme.onSurface)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: DomendraTheme.surfaceVariant,
                              color: DomendraTheme.primary,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(fmtMoney(value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
                    const SizedBox(width: 6),
                    Text(fmtPct(pct), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              );
            }).toList(),
          )),
          const SizedBox(height: 20),
        ],

        // Monthly TCO trend
        if (monthly.isNotEmpty) ...[
          sectionTitle('Monthly TCO Trend'),
          const SizedBox(height: 10),
          reportCard(child: _MonthlyBar(data: monthly.cast<Map<String, dynamic>>())),
          const SizedBox(height: 20),
        ],

        // Per-vehicle table
        sectionTitle('Per-Vehicle TCO'),
        const SizedBox(height: 10),
        reportCard(child: vehicles.isEmpty
            ? tabEmpty(message: 'No vehicle data')
            : Column(
                children: [
                  for (int i = 0; i < vehicles.length; i++) ...[
                    _vehicleRow(vehicles[i] as Map<String, dynamic>),
                    if (i < vehicles.length - 1) thinDivider(),
                  ],
                ],
              )),
      ],
    );
  }

  Widget _vehicleRow(Map<String, dynamic> v) {
    final name = v['vehicle'] as String? ?? 'Unknown';
    final ownership = v['ownership'] as String? ?? 'self';
    final capital = toDouble(v['capital_cost']);
    final energy = toDouble(v['energy_cost']);
    final operating = toDouble(v['operating_cost']);
    final total = toDouble(v['total_cost']);
    final revenue = toDouble(v['revenue']);
    final net = toDouble(v['net_profit']);
    final perKm = toDouble(v['cost_per_km']);
    final perDay = toDouble(v['cost_per_day']);

    final netPositive = net >= 0;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text(ownership == 'lease' ? 'Leased' : 'Owned', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtMoney(total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DomendraTheme.danger)),
              Text('/km ${fmtMoney(perKm)}', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Column(
            children: [
              dataRow('Capital Cost', fmtMoney(capital)),
              thinDivider(),
              dataRow('Energy Cost', fmtMoney(energy)),
              thinDivider(),
              dataRow('Operating Cost', fmtMoney(operating)),
              thinDivider(),
              dataRow('Total Cost', fmtMoney(total), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Revenue', fmtMoney(revenue), valueColor: DomendraTheme.success),
              thinDivider(),
              dataRow('Net Profit', fmtMoney(net), valueColor: netPositive ? DomendraTheme.success : DomendraTheme.danger),
              thinDivider(),
              dataRow('Cost per KM', fmtMoney(perKm)),
              thinDivider(),
              dataRow('Cost per Day', fmtMoney(perDay)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyBar extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _MonthlyBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (max, m) {
      final v = toDouble(m['cost']);
      return v > max ? v : max;
    });

    return SizedBox(
      height: 160,
      child: data.isEmpty
          ? tabEmpty(message: 'No trend data')
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.take(12).map((m) {
                final cost = toDouble(m['cost']);
                final h = maxVal > 0 ? (cost / maxVal * 120) : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: DomendraTheme.primary.withValues(alpha: 0.7),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['month'] as String? ?? '',
                          style: const TextStyle(fontSize: 7, color: DomendraTheme.onSurfaceMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
