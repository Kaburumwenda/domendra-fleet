import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Revenue Analysis tab — mirrors web `RevenueAnalysis.vue`.
///
/// Data from `GET /reports/financial/revenue/`.
class RevenueAnalysisTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const RevenueAnalysisTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final totalRevenue = toDouble(data!['total_revenue']);
    final addonTotal = toDouble(data!['addon_total']);
    final byCustomer = (data!['by_customer'] as List?) ?? [];
    final byVehicle = (data!['by_vehicle'] as List?) ?? [];
    final addonRevenue = (data!['addon_revenue'] as Map<String, dynamic>?) ?? {};
    final paymentMethods = (data!['payment_methods'] as List?) ?? [];
    final trend = (data!['trend'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top KPIs
        kpiGrid([
          ReportKpiCard(icon: Icons.attach_money, color: DomendraTheme.success, label: 'Total Revenue', value: fmtMoney(totalRevenue)),
          ReportKpiCard(icon: Icons.add_circle_outline, color: DomendraTheme.info, label: 'Add-on Revenue', value: fmtMoney(addonTotal)),
        ]),
        const SizedBox(height: 20),

        // Top customers
        sectionTitle('Top Customers'),
        const SizedBox(height: 10),
        reportCard(child: byCustomer.isEmpty
            ? tabEmpty(message: 'No customer data')
            : Column(
                children: [
                  for (int i = 0; i < byCustomer.take(5).length; i++) ...[
                    _customerRow(byCustomer[i] as Map<String, dynamic>, i),
                    if (i < 4 && i < byCustomer.length - 1) thinDivider(),
                  ],
                ],
              )),
        const SizedBox(height: 20),

        // Top vehicles
        sectionTitle('Top Vehicles by Revenue'),
        const SizedBox(height: 10),
        reportCard(child: byVehicle.isEmpty
            ? tabEmpty(message: 'No vehicle data')
            : Column(
                children: [
                  for (int i = 0; i < byVehicle.take(8).length; i++) ...[
                    _vehicleRow(byVehicle[i] as Map<String, dynamic>),
                    if (i < 7 && i < byVehicle.length - 1) thinDivider(),
                  ],
                ],
              )),
        const SizedBox(height: 20),

        // Add-on revenue breakdown
        sectionTitle('Add-on Revenue'),
        const SizedBox(height: 10),
        reportCard(child: addonRevenue.isEmpty
            ? tabEmpty(message: 'No add-on data')
            : Column(
                children: addonRevenue.entries.map((e) {
                  final labels = {
                    'insurance': 'Insurance',
                    'gps': 'GPS',
                    'child_seat': 'Child Seat',
                    'additional_driver': 'Additional Driver',
                    'delivery': 'Delivery',
                  };
                  return dataRow(labels[e.key] ?? e.key, fmtMoney(toDouble(e.value)));
                }).toList(),
              )),
        const SizedBox(height: 20),

        // Payment methods
        sectionTitle('Payment Methods'),
        const SizedBox(height: 10),
        reportCard(child: paymentMethods.isEmpty
            ? tabEmpty(message: 'No payment data')
            : Column(
                children: paymentMethods.map((pm) {
                  final m = pm as Map<String, dynamic>;
                  return dataRow(
                    _methodLabel(m['method'] as String? ?? ''),
                    fmtMoney(toDouble(m['amount'])),
                    valueColor: DomendraTheme.primary,
                  );
                }).toList(),
              )),
        const SizedBox(height: 20),

        // Revenue trend
        if (trend.isNotEmpty) ...[
          sectionTitle('Revenue Trend'),
          const SizedBox(height: 10),
          reportCard(child: _TrendChart(data: trend)),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _customerRow(Map<String, dynamic> c, int i) {
    final name = c['customer'] as String? ?? 'Unknown';
    final count = toInt(c['count']);
    final revenue = toDouble(c['revenue']);
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: DomendraTheme.primary.withValues(alpha: 0.12),
            child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text('$count rentals', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Text(fmtMoney(revenue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DomendraTheme.success)),
        ],
      ),
    );
  }

  Widget _vehicleRow(Map<String, dynamic> v) {
    final name = v['vehicle'] as String? ?? 'Unknown';
    final count = toInt(v['count']);
    final revenue = toDouble(v['revenue']);
    final net = toDouble(v['net']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text('$count rentals • Net: ${fmtMoney(net)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Text(fmtMoney(revenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    const labels = {
      'mpesa': 'M-Pesa',
      'cash': 'Cash',
      'card': 'Card',
      'bank_transfer': 'Bank Transfer',
      'cheque': 'Cheque',
      'other': 'Other',
    };
    return labels[method] ?? method.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}

class _TrendChart extends StatelessWidget {
  final List<dynamic> data;

  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final pts = data.cast<Map<String, dynamic>>();
    return SizedBox(
      height: 160,
      child: pts.isEmpty
          ? tabEmpty(message: 'No trend data')
          : Column(
              children: [
                // Simple line-chart representation using bars
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: pts.take(14).map((p) {
                      final rev = toDouble(p['revenue']);
                      final pay = toDouble(p['payments']);
                      final maxVal = pts.fold<double>(0, (max, pe) {
                        final r = toDouble((pe as Map)['revenue']);
                        final pa = toDouble(pe['payments']);
                        final m = r > pa ? r : pa;
                        return m > max ? m : max;
                      });
                      final revH = maxVal > 0 ? (rev / maxVal * 100) : 0.0;
                      final payH = maxVal > 0 ? (pay / maxVal * 100) : 0.0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(child: Container(height: revH, color: DomendraTheme.success.withValues(alpha: 0.8))),
                                  const SizedBox(width: 2),
                                  Expanded(child: Container(height: payH, color: DomendraTheme.primary.withValues(alpha: 0.8))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(DomendraTheme.success, 'Revenue'),
                    const SizedBox(width: 12),
                    _legendDot(DomendraTheme.primary, 'Payments'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}
