import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Vehicle ROI tab — mirrors web `VehicleROI.vue`.
///
/// Data from `GET /reports/financial/vehicle-roi/` (array).
class VehicleRoiTab extends StatelessWidget {
  final List<dynamic> vehicles;

  const VehicleRoiTab({super.key, this.vehicles = const []});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) return tabEmpty(message: 'No vehicle ROI data');

    final totalRevenue = vehicles.fold<double>(0, (s, v) => s + toDouble((v as Map)['revenue']));
    final totalCost = vehicles.fold<double>(0, (s, v) => s + toDouble((v as Map)['total_cost']));
    final totalProfit = vehicles.fold<double>(0, (s, v) => s + toDouble((v as Map)['net_profit']));
    final avgRoi = vehicles.isNotEmpty
        ? vehicles.fold<double>(0, (s, v) => s + toDouble((v as Map)['roi_pct'])) / vehicles.length
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        kpiGrid([
          ReportKpiCard(icon: Icons.trending_up, color: DomendraTheme.success, label: 'Total Revenue', value: fmtMoney(totalRevenue)),
          ReportKpiCard(icon: Icons.trending_down, color: DomendraTheme.danger, label: 'Total Cost', value: fmtMoney(totalCost)),
          ReportKpiCard(icon: Icons.account_balance, color: totalProfit >= 0 ? DomendraTheme.primary : DomendraTheme.danger, label: 'Net Profit', value: fmtMoney(totalProfit)),
          ReportKpiCard(icon: Icons.percent, color: avgRoi >= 0 ? DomendraTheme.success : DomendraTheme.warning, label: 'Avg ROI', value: fmtPct(avgRoi)),
        ]),
        const SizedBox(height: 20),

        sectionTitle('Vehicle ROI Table'),
        const SizedBox(height: 10),
        reportCard(child: Column(
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
    final vin = v['vin'] as String? ?? '';
    final revenue = toDouble(v['revenue']);
    final fuelCost = toDouble(v['fuel_cost']);
    final serviceCost = toDouble(v['service_cost']);
    final fixedCost = toDouble(v['fixed_cost']);
    final totalCost = toDouble(v['total_cost']);
    final netProfit = toDouble(v['net_profit']);
    final roi = toDouble(v['roi_pct']);
    final ownership = v['ownership'] as String? ?? 'self';

    final profitPositive = netProfit >= 0;
    final roiColor = roi >= 0 ? DomendraTheme.success : DomendraTheme.danger;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text('${vin.isNotEmpty ? '${vin.substring(0, vin.length > 8 ? 8 : vin.length)}… ' : ''}($ownership)',
                    style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtPct(roi), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: roiColor)),
              Text(fmtMoney(netProfit), style: TextStyle(fontSize: 10, color: profitPositive ? DomendraTheme.success : DomendraTheme.danger)),
            ],
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Column(
            children: [
              dataRow('Revenue', fmtMoney(revenue), valueColor: DomendraTheme.success),
              thinDivider(),
              dataRow('Fuel Cost', fmtMoney(fuelCost), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Service Cost', fmtMoney(serviceCost), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Fixed Cost', fmtMoney(fixedCost), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Total Cost', fmtMoney(totalCost), valueColor: DomendraTheme.danger),
              thinDivider(),
              dataRow('Net Profit', fmtMoney(netProfit), valueColor: profitPositive ? DomendraTheme.success : DomendraTheme.danger),
              thinDivider(),
              dataRow('ROI', fmtPct(roi), valueColor: roiColor),
              thinDivider(),
              dataRow('Cost per Mile', fmtMoney(toDouble(v['cost_per_mile']))),
              thinDivider(),
              dataRow('Revenue per Mile', fmtMoney(toDouble(v['revenue_per_mile']))),
              thinDivider(),
              dataRow('Book Value', fmtMoney(toDouble(v['book_value']))),
            ],
          ),
        ),
      ],
    );
  }
}
