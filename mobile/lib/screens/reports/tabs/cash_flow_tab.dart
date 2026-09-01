import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Cash Flow tab — mirrors web `CashFlow.vue`.
///
/// Data from `GET /reports/financial/cash-flow/`.
class CashFlowTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const CashFlowTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final totalInflow = toDouble(data!['total_inflow']);
    final totalOutflow = toDouble(data!['total_outflow']);
    final netCashFlow = toDouble(data!['net_cash_flow']);
    final bucket = data!['bucket'] as String? ?? 'daily';
    final buckets = (data!['buckets'] as List?) ?? [];

    final netPositive = netCashFlow >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header chips
        kpiGrid([
          ReportKpiCard(icon: Icons.south_west, color: DomendraTheme.success, label: 'Total Inflow', value: fmtMoney(totalInflow)),
          ReportKpiCard(icon: Icons.north_east, color: DomendraTheme.danger, label: 'Total Outflow', value: fmtMoney(totalOutflow)),
          ReportKpiCard(icon: netPositive ? Icons.account_balance : Icons.account_balance_wallet,
              color: netPositive ? DomendraTheme.primary : DomendraTheme.warning,
              label: 'Net Cash Flow', value: fmtMoney(netCashFlow)),
        ]),
        const SizedBox(height: 20),

        // Bucket info
        sectionTitle('Cash Flow (${_bucketLabel(bucket)})'),
        const SizedBox(height: 10),

        // Chart
        if (buckets.isNotEmpty) ...[
          reportCard(child: _CashFlowChart(buckets: buckets.cast<Map<String, dynamic>>())),
          const SizedBox(height: 16),
        ],

        // Data table
        sectionTitle('Breakdown'),
        const SizedBox(height: 10),
        reportCard(child: buckets.isEmpty
            ? tabEmpty(message: 'No cash flow data')
            : Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      color: DomendraTheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface))),
                        Expanded(child: Text('In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.success), textAlign: TextAlign.right)),
                        Expanded(child: Text('Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.danger), textAlign: TextAlign.right)),
                        Expanded(child: Text('Net', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  for (int i = 0; i < buckets.length; i++) ...[
                    _bucketRow(buckets[i] as Map<String, dynamic>),
                    if (i < buckets.length - 1) thinDivider(),
                  ],
                ],
              )),
      ],
    );
  }

  Widget _bucketRow(Map<String, dynamic> b) {
    final date = b['date'] as String? ?? '';
    final inflow = toDouble(b['inflow']);
    final outflow = toDouble(b['outflow']);
    final net = toDouble(b['net']);
    final netPositive = net >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurface))),
          Expanded(child: Text(fmtMoney(inflow), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.success), textAlign: TextAlign.right)),
          Expanded(child: Text(fmtMoney(outflow), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.danger), textAlign: TextAlign.right)),
          Expanded(child: Text(fmtMoney(net), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: netPositive ? DomendraTheme.success : DomendraTheme.warning), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _bucketLabel(String bucket) {
    const labels = {'daily': 'Daily', 'weekly': 'Weekly', 'monthly': 'Monthly'};
    return labels[bucket] ?? bucket;
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;

  const _CashFlowChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold<double>(0, (max, b) {
      final inflow = toDouble(b['inflow']);
      final outflow = toDouble(b['outflow']);
      final m = inflow > outflow ? inflow : outflow;
      return m > max ? m : max;
    });

    return SizedBox(
      height: 180,
      child: buckets.isEmpty
          ? tabEmpty(message: 'No chart data')
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.take(16).map((b) {
                final inflow = toDouble(b['inflow']);
                final outflow = toDouble(b['outflow']);
                final inH = maxVal > 0 ? (inflow / maxVal * 120) : 0.0;
                final outH = maxVal > 0 ? (outflow / maxVal * 120) : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: Container(height: inH, color: DomendraTheme.success.withValues(alpha: 0.8))),
                            const SizedBox(width: 2),
                            Expanded(child: Container(height: outH, color: DomendraTheme.danger.withValues(alpha: 0.8))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (b['date'] as String? ?? '').split('-').last,
                          style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted),
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
