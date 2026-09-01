import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// Financial Overview / Dashboard tab — mirrors web `FinancialAnalytics.vue`.
///
/// Props: `{ summary, trends }` from `GET /reports/financial/overview/`.
class FinancialOverviewTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const FinancialOverviewTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final summary = (data!['summary'] as Map<String, dynamic>?) ?? {};
    final trends = (data!['trends'] as Map<String, dynamic>?) ?? {};

    final totalRevenue = toDouble(summary['total_revenue']);
    final totalCosts = toDouble(summary['total_costs']);
    final netProfit = toDouble(summary['net_profit']);
    final cashCollected = toDouble(summary['cash_collected']);
    final ebitda = toDouble(summary['ebitda']);
    final breakeven = toDouble(summary['breakeven_revenue']);
    final roa = toDouble(summary['roa']);
    final dso = toDouble(summary['dso']);
    final grossProfit = toDouble(summary['gross_profit']);
    final operatingProfit = toDouble(summary['operating_profit']);
    final grossMargin = toDouble(summary['gross_margin']);
    final netMargin = toDouble(summary['net_margin']);

    final revTrend = toDouble(trends['revenue_change_pct']);
    final costTrend = toDouble(trends['cost_change_pct']);
    final profitTrend = toDouble(trends['profit_change_pct']);
    final cashTrend = toDouble(trends['cash_change_pct']);

    final profitPositive = netProfit >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI gradient cards
        kpiGrid([
          ReportKpiCard(icon: Icons.trending_up, color: DomendraTheme.success, label: 'Total Revenue', value: fmtMoney(totalRevenue), trend: revTrend),
          ReportKpiCard(icon: Icons.trending_down, color: DomendraTheme.danger, label: 'Total Costs', value: fmtMoney(totalCosts), trend: costTrend),
          ReportKpiCard(icon: profitPositive ? Icons.account_balance : Icons.account_balance_wallet, color: profitPositive ? DomendraTheme.primary : DomendraTheme.danger, label: 'Net Profit', value: fmtMoney(netProfit), trend: profitTrend),
          ReportKpiCard(icon: Icons.payments, color: DomendraTheme.info, label: 'Cash Collected', value: fmtMoney(cashCollected), trend: cashTrend),
        ]),
        const SizedBox(height: 16),

        // Secondary KPIs
        kpiGrid([
          ReportKpiCard(icon: Icons.analytics, color: DomendraTheme.secondary, label: 'EBITDA', value: fmtMoney(ebitda)),
          ReportKpiCard(icon: Icons.account_balance, color: DomendraTheme.warning, label: 'Breakeven Revenue', value: fmtMoney(breakeven)),
          ReportKpiCard(icon: Icons.percent, color: DomendraTheme.primary, label: 'ROA', value: fmtPct(roa)),
          ReportKpiCard(icon: Icons.schedule, color: DomendraTheme.info, label: 'DSO (days)', value: fmtNum(dso, decimals: 0)),
        ]),
        const SizedBox(height: 20),

        // P&L mini-statement
        sectionTitle('P&L Summary'),
        const SizedBox(height: 10),
        reportCard(child: Column(
          children: [
            dataRow('Rental Revenue', fmtMoney(totalRevenue)),
            thinDivider(),
            dataRow('Gross Profit', fmtMoney(grossProfit), valueColor: DomendraTheme.success),
            thinDivider(),
            dataRow('Gross Margin', fmtPct(grossMargin)),
            thinDivider(),
            dataRow('Operating Profit', fmtMoney(operatingProfit)),
            thinDivider(),
            dataRow('Total Costs', fmtMoney(totalCosts), valueColor: DomendraTheme.danger),
            thinDivider(),
            dataRow('Net Profit', fmtMoney(netProfit),
                valueColor: profitPositive ? DomendraTheme.success : DomendraTheme.danger),
            thinDivider(),
            dataRow('Net Margin', fmtPct(netMargin)),
          ],
        )),
        const SizedBox(height: 20),

        // Financial Ratios
        sectionTitle('Financial Ratios'),
        const SizedBox(height: 10),
        reportCard(child: Column(
          children: [
            _ratioRow('Current Ratio', toDouble(summary['current_ratio'])),
            thinDivider(),
            _ratioRow('Quick Ratio', toDouble(summary['quick_ratio'])),
            thinDivider(),
            _ratioRow('Operating Leverage', toDouble(summary['operating_leverage']), isPct: true),
            thinDivider(),
            _ratioRow('Margin of Safety', toDouble(summary['margin_of_safety']), isPct: true),
            thinDivider(),
            _ratioRow('DSO', dso, suffix: ' days'),
            thinDivider(),
            _ratioRow('ROA', roa, isPct: true),
          ],
        )),
      ],
    );
  }

  Widget _ratioRow(String label, double value, {bool isPct = false, String suffix = ''}) {
    final formatted = isPct ? fmtPct(value) : '${fmtNum(value, decimals: 2)}$suffix';
    return dataRow(label, formatted);
  }
}
