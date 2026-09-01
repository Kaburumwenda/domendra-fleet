import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Profit & Loss tab — mirrors web `ProfitLoss.vue`.
///
/// Data from `GET /reports/financial/profit-loss/`.
class ProfitLossTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const ProfitLossTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final summary = (data!['summary'] as Map<String, dynamic>?) ?? {};
    final statement = (data!['statement'] as List?) ?? [];
    final monthlySeries = (data!['monthly_series'] as List?) ?? [];
    final costBreakdown = (data!['cost_breakdown'] as List?) ?? [];
    final trends = (data!['trends'] as Map<String, dynamic>?) ?? {};

    final totalRevenue = toDouble(summary['total_revenue']);
    final totalCosts = toDouble(summary['total_costs']);
    final netProfit = toDouble(summary['net_profit']);
    final netMargin = toDouble(summary['net_margin']);

    final profitPositive = netProfit >= 0;
    final revTrend = toDouble(trends['revenue_change_pct']);
    final costTrend = toDouble(trends['cost_change_pct']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPIs
        kpiGrid([
          ReportKpiCard(icon: Icons.trending_up, color: DomendraTheme.success, label: 'Total Revenue', value: fmtMoney(totalRevenue), trend: revTrend),
          ReportKpiCard(icon: Icons.trending_down, color: DomendraTheme.danger, label: 'Total Costs', value: fmtMoney(totalCosts), trend: costTrend),
          ReportKpiCard(icon: profitPositive ? Icons.account_balance : Icons.account_balance_wallet,
              color: profitPositive ? DomendraTheme.primary : DomendraTheme.danger,
              label: profitPositive ? 'Net Profit' : 'Net Loss', value: fmtMoney(netProfit)),
          ReportKpiCard(icon: Icons.percent, color: DomendraTheme.info, label: 'Net Margin', value: fmtPct(netMargin)),
        ]),
        const SizedBox(height: 20),

        // Secondary KPIs
        kpiGrid([
          ReportKpiCard(icon: Icons.payments, color: DomendraTheme.success, label: 'Cash Collected', value: fmtMoney(summary['cash_collected'])),
          ReportKpiCard(icon: Icons.outbound, color: DomendraTheme.warning, label: 'Outstanding A/R', value: fmtMoney(summary['outstanding_ar'])),
          ReportKpiCard(icon: Icons.business, color: DomendraTheme.primary, label: 'Operating Profit', value: fmtMoney(summary['operating_profit'])),
          ReportKpiCard(icon: Icons.savings, color: DomendraTheme.info, label: 'Gross Profit', value: fmtMoney(summary['gross_profit'])),
        ]),
        const SizedBox(height: 20),

        // P&L Statement
        sectionTitle('P&L Statement'),
        const SizedBox(height: 10),
        reportCard(child: statement.isEmpty
            ? tabEmpty(message: 'No statement data')
            : Column(
                children: statement.map((s) {
                  final row = s as Map<String, dynamic>;
                  return _statementRow(row);
                }).toList(),
              )),
        const SizedBox(height: 20),

        // Monthly trend
        if (monthlySeries.isNotEmpty) ...[
          sectionTitle('Monthly Trend'),
          const SizedBox(height: 10),
          reportCard(child: _MonthlyTrend(data: monthlySeries.cast<Map<String, dynamic>>())),
          const SizedBox(height: 20),
        ],

        // Cost breakdown
        if (costBreakdown.isNotEmpty) ...[
          sectionTitle('Cost Breakdown'),
          const SizedBox(height: 10),
          reportCard(child: Column(
            children: costBreakdown.map((c) {
              final m = c as Map<String, dynamic>;
              return dataRow(
                m['name'] as String? ?? '?',
                fmtMoney(toDouble(m['value'])),
                valueColor: DomendraTheme.danger,
              );
            }).toList(),
          )),
        ],
      ],
    );
  }

  Widget _statementRow(Map<String, dynamic> row) {
    final section = row['section'] as String? ?? '';
    final label = row['label'] as String? ?? '';
    final amount = toDouble(row['amount']);
    final type = row['type'] as String? ?? '';

    final isHeader = section == 'header';
    final isSubtotal = section == 'subtotal';
    final isResult = section == 'result';
    final isRevenue = type == 'revenue';
    final isCost = type == 'cost';

    Color? amountColor;
    if (isRevenue) amountColor = DomendraTheme.success;
    if (isCost) amountColor = DomendraTheme.danger;
    if (isResult) amountColor = amount >= 0 ? DomendraTheme.success : DomendraTheme.danger;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isHeader || isSubtotal || isResult ? 10 : 7,
        horizontal: 4,
      ),
      decoration: (isHeader || isSubtotal || isResult)
          ? BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(6))
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isHeader ? 12 : 13,
                fontWeight: isHeader || isSubtotal || isResult ? FontWeight.w800 : FontWeight.w500,
                color: DomendraTheme.onSurface,
              ),
            ),
          ),
          Text(
            fmtMoney(amount),
            style: TextStyle(
              fontSize: isHeader || isSubtotal || isResult ? 13 : 13,
              fontWeight: isHeader || isSubtotal || isResult ? FontWeight.w800 : FontWeight.w600,
              color: amountColor ?? DomendraTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrend extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _MonthlyTrend({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (max, m) {
      final r = toDouble(m['revenue']);
      final c = toDouble(m['costs']);
      final p = toDouble(m['profit']);
      final v = r > c ? r : c;
      final v2 = v > p ? v : p;
      return v2 > max ? v2 : max;
    });

    return SizedBox(
      height: 180,
      child: data.isEmpty
          ? tabEmpty(message: 'No trend data')
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.take(12).map((m) {
                final rev = toDouble(m['revenue']);
                final cost = toDouble(m['costs']);
                final profit = toDouble(m['profit']);
                final revH = maxVal > 0 ? (rev / maxVal * 120) : 0.0;
                final costH = maxVal > 0 ? (cost / maxVal * 120) : 0.0;
                final profitH = maxVal > 0 ? (profit / maxVal * 120) : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: Container(height: revH, color: DomendraTheme.success.withValues(alpha: 0.7))),
                            const SizedBox(width: 2),
                            Expanded(child: Container(height: costH, color: DomendraTheme.danger.withValues(alpha: 0.7))),
                            const SizedBox(width: 2),
                            Expanded(child: Container(height: profitH, color: DomendraTheme.primary.withValues(alpha: 0.7))),
                          ],
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
