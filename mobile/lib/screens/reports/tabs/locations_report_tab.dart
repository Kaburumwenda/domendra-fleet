import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Locations Report tab — mirrors web `LocationsReport.vue`.
///
/// Data from `GET /reports/financial/locations/`.
class LocationsReportTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const LocationsReportTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final summary = (data!['summary'] as Map<String, dynamic>?) ?? {};
    final locations = (data!['locations'] as List?) ?? [];

    final totalRevenue = toDouble(summary['total_revenue']);
    final totalCosts = toDouble(summary['total_costs']);
    final netProfit = toDouble(summary['net_profit']);
    final locCount = toInt(summary['total_locations']);
    final topProfitLoc = summary['top_profit_location'] as String?;
    final topLossLoc = summary['top_loss_location'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        kpiGrid([
          ReportKpiCard(icon: Icons.place, color: DomendraTheme.info, label: 'Locations', value: fmtNum(locCount)),
          ReportKpiCard(icon: Icons.trending_up, color: DomendraTheme.success, label: 'Total Revenue', value: fmtMoney(totalRevenue)),
          ReportKpiCard(icon: Icons.trending_down, color: DomendraTheme.danger, label: 'Total Costs', value: fmtMoney(totalCosts)),
          ReportKpiCard(icon: netProfit >= 0 ? Icons.account_balance : Icons.account_balance_wallet,
              color: netProfit >= 0 ? DomendraTheme.primary : DomendraTheme.danger,
              label: 'Net Profit', value: fmtMoney(netProfit)),
        ]),
        const SizedBox(height: 20),

        // Top/bottom alerts
        if (topProfitLoc != null || topLossLoc != null) ...[
          if (topProfitLoc != null)
            _alertBanner('Top: $topProfitLoc', fmtMoney(summary['top_profit_value']), DomendraTheme.success),
          const SizedBox(height: 8),
          if (topLossLoc != null)
            _alertBanner('Bottom: $topLossLoc', fmtMoney(summary['top_loss_value']), DomendraTheme.danger),
          const SizedBox(height: 20),
        ],

        sectionTitle('Locations Breakdown'),
        const SizedBox(height: 10),
        reportCard(child: locations.isEmpty
            ? tabEmpty(message: 'No location data')
            : Column(
                children: [
                  for (int i = 0; i < locations.length; i++) ...[
                    _locationExpansion(locations[i] as Map<String, dynamic>),
                    if (i < locations.length - 1) thinDivider(),
                  ],
                ],
              )),
      ],
    );
  }

  Widget _alertBanner(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(color == DomendraTheme.success ? Icons.trending_up : Icons.trending_down, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _locationExpansion(Map<String, dynamic> loc) {
    final name = loc['name'] as String? ?? 'Unknown';
    final type = loc['type'] as String? ?? '';
    final vehicleCount = toInt(loc['vehicle_count']);
    final revenue = toDouble(loc['revenue']);
    final totalCosts = toDouble(loc['total_costs']);
    final netProfit = toDouble(loc['net_profit']);
    final margin = toDouble(loc['net_margin']);

    final profitPositive = netProfit >= 0;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (profitPositive ? DomendraTheme.success : DomendraTheme.danger).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.place, size: 18, color: profitPositive ? DomendraTheme.success : DomendraTheme.danger),
      ),
      title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
      subtitle: Text('$type • $vehicleCount vehicles • ${fmtPct(margin)} margin',
          style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(fmtMoney(revenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DomendraTheme.success)),
          Text(fmtMoney(netProfit), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: profitPositive ? DomendraTheme.success : DomendraTheme.danger)),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Column(
            children: [
              dataRow('Revenue', fmtMoney(revenue), valueColor: DomendraTheme.success),
              thinDivider(),
              dataRow('Cash Collected', fmtMoney(toDouble(loc['cash_collected']))),
              thinDivider(),
              dataRow('Fuel Cost', fmtMoney(toDouble(loc['fuel_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Charging Cost', fmtMoney(toDouble(loc['charging_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Service Cost', fmtMoney(toDouble(loc['service_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Idling Cost', fmtMoney(toDouble(loc['idling_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Accident Cost', fmtMoney(toDouble(loc['accident_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Damage Cost', fmtMoney(toDouble(loc['damage_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Expense Cost', fmtMoney(toDouble(loc['expense_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Lease Cost', fmtMoney(toDouble(loc['lease_cost'])), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Total Costs', fmtMoney(totalCosts), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Net Profit', fmtMoney(netProfit), valueColor: profitPositive ? DomendraTheme.success : DomendraTheme.danger),
              thinDivider(),
              dataRow('Gross Margin', fmtPct(toDouble(loc['gross_margin']))),
              thinDivider(),
              dataRow('Net Margin', fmtPct(margin)),
            ],
          ),
        ),
      ],
    );
  }
}
