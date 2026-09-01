import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/billing_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';
import 'billing_dialogs.dart';

/// Billing screen — mirrors web `/app/billing`.
///
/// 3 tabs: Overview, Usage Analytics, Invoices.
class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.show_chart, size: 18), text: 'Usage'),
    Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Invoices'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dash = context.read<DashboardProvider>();
      final billing = context.read<BillingProvider>();
      billing.refreshAll();
      billing.fetchExchangeRate();
      // warm up currency symbol
      dash.loadCurrency();
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
        title: const Text('Billing & API Usage'),
        leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              context.read<BillingProvider>().refreshAll();
              context.read<BillingProvider>().fetchExchangeRate();
            },
          ),
        ],
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
      drawer: const AppDrawer(currentRoute: '/billing'),
      body: Consumer<BillingProvider>(
        builder: (context, p, _) {
          if (p.loading && p.summary.isEmpty && p.bills.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.error != null && p.summary.isEmpty && p.bills.isEmpty) {
            return _ErrorState(message: p.error!, onRetry: () => p.refreshAll());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(provider: p),
              _UsageTab(provider: p),
              _InvoicesTab(provider: p),
            ],
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Overview tab — subscription KPIs + analytics summary + projection
// ════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final BillingProvider provider;
  const _OverviewTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // ── Subscription KPI cards ──
        _KpiGrid(children: [
          _KpiCard(
            label: 'Requests This Month',
            value: fmtInt(provider.requestCount),
            icon: Icons.api,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            subtitle: 'Cycle day ${provider.cycleDay}',
          ),
          _KpiCard(
            label: 'Cost This Month (USD)',
            value: '\$${fmtMoney(provider.estimatedCostUsd)}',
            icon: Icons.attach_money,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: DomendraTheme.primary,
            subtitle: provider.billingCurrency != 'USD'
                ? '${symbolFor(provider.billingCurrency)}${fmtMoney(provider.estimatedCostLocal)}'
                : null,
          ),
          _KpiCard(
            label: 'Projected Month-End (USD)',
            value: '\$${fmtMoney(provider.projectedCostUsd)}',
            icon: Icons.trending_up,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF59E0B),
            subtitle: provider.billingCurrency != 'USD'
                ? '${symbolFor(provider.billingCurrency)}${fmtMoney(provider.projectedCostLocal)}'
                : null,
          ),
          _KpiCard(
            label: 'Avg Requests / Day',
            value: fmtInt(provider.monthlyAverage),
            icon: Icons.bar_chart,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF10B981),
            subtitle: '~${fmtInt(provider.endOfMonthProjection)} by period end',
          ),
        ]),

        const SizedBox(height: 12),

        // ── Rate explanation banner ──
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Billing is purely usage-based at \$${fmtRate(provider.ratePer1000)} per 1,000 API requests in USD.'
                  '${provider.billingCurrency != 'USD' ? ' Converted to ${provider.billingCurrency} at ${fmtRate(provider.exchangeRate)} for display.' : ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Analytics summary cards ──
        _KpiGrid(children: [
          _KpiCard(
            label: 'Total Requests',
            value: fmtInt(provider.totalRequests),
            icon: Icons.show_chart,
            iconBg: const Color(0xFFEEF2FF),
            iconColor: DomendraTheme.primary,
          ),
          _KpiCard(
            label: 'Errors',
            value: fmtInt(provider.totalErrors),
            icon: Icons.error_outline,
            iconBg: const Color(0xFFFEF2F2),
            iconColor: DomendraTheme.danger,
          ),
          _KpiCard(
            label: 'Error Rate',
            value: '${fmtMoney(provider.errorRate)}%',
            icon: Icons.percent,
            iconBg: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFF59E0B),
          ),
          _KpiCard(
            label: 'Avg Response',
            value: '${fmtInt(provider.avgResponseMs)}ms',
            icon: Icons.timer,
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF10B981),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Current Cycle Projection ──
        _SectionCard(
          title: 'Current Cycle Projection',
          chip: '\$${fmtRate(provider.ratePer1000)}/1k rate',
          children: [
            _ProjectionRow(label: 'Requests used', value: fmtInt(provider.requestCount)),
            _ProjectionRow(label: 'Avg / day', value: fmtInt(provider.monthlyAverage)),
            _ProjectionRow(label: 'Projected requests', value: fmtInt(provider.endOfMonthProjection)),
            _ProjectionRow(label: 'Period ends', value: fmtDate(provider.currentPeriodEnd)),
            const Divider(height: 16),
            _ProjectionRow(label: 'Cost so far (USD)', value: '\$${fmtMoney(provider.estimatedCostUsd)}'),
            _ProjectionRow(label: 'Projected total (USD)', value: '\$${fmtMoney(provider.projectedCostUsd)}', bold: true),
            if (provider.billingCurrency != 'USD') ...[
              _ProjectionRow(
                label: 'Cost so far (${provider.billingCurrency})',
                value: '${symbolFor(provider.billingCurrency)}${fmtMoney(provider.estimatedCostLocal)}',
              ),
              _ProjectionRow(
                label: 'Projected total (${provider.billingCurrency})',
                value: '${symbolFor(provider.billingCurrency)}${fmtMoney(provider.projectedCostLocal)}',
                bold: true,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Usage tab — charts
// ════════════════════════════════════════════════════════════

class _UsageTab extends StatelessWidget {
  final BillingProvider provider;
  const _UsageTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // Date filter preset bar
        _PresetBar(provider: provider),
        const SizedBox(height: 12),

        // Daily requests chart
        _DailyRequestsChart(provider: provider),
        const SizedBox(height: 12),

        // Method distribution donut + status codes pie
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _MethodDonutChart(provider: provider)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _StatusPieChart(provider: provider)),
          ],
        ),
        const SizedBox(height: 12),

        // Hour distribution
        _HourBarChart(provider: provider),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Invoices tab — bills list
// ════════════════════════════════════════════════════════════

class _InvoicesTab extends StatelessWidget {
  final BillingProvider provider;
  const _InvoicesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preset bar for filtering
        _PresetBar(provider: provider),
        // Overdue alert
        if (provider.overdueCount > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DomendraTheme.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DomendraTheme.danger.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, size: 16, color: DomendraTheme.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${provider.overdueCount} unpaid invoice(s) are past due. Please settle to avoid service interruption.',
                    style: const TextStyle(fontSize: 11, color: DomendraTheme.danger, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(child: provider.bills.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text('No invoices found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                itemCount: provider.bills.length,
                itemBuilder: (ctx, i) {
                  final bill = provider.bills[i] as Map<String, dynamic>;
                  final status = bill['status'] as String? ?? 'unpaid';
                  final sColor = billStatusColor(status);
                  final currency = bill['billing_currency'] as String? ?? 'USD';
                  final totalUsd = toDoubleOr(bill['grand_total_usd'] ?? bill['grand_total']);
                  final balance = toDoubleOr(bill['balance_due'] != null ? bill['balance_due'] : totalUsd);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DomendraTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DomendraTheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: sColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.receipt, size: 16, color: sColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bill['invoice_number'] as String? ?? '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    fmtMonth(bill['billing_month']),
                                    style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(billStatusIcon(status), size: 12, color: sColor),
                                  const SizedBox(width: 4),
                                  Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _BillInfo(label: 'Requests', value: fmtInt(bill['total_requests'])),
                            ),
                            Expanded(
                              child: _BillInfo(
                                label: 'Amount (USD)',
                                value: '\$${fmtMoney(totalUsd)}',
                                bold: true,
                              ),
                            ),
                            if (currency != 'USD')
                              Expanded(
                                child: _BillInfo(
                                  label: currency,
                                  value: '${symbolFor(currency)}${fmtMoney(bill['grand_total_local'])}',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: DomendraTheme.onSurfaceMuted),
                            const SizedBox(width: 4),
                            Text('Due: ${fmtDate(bill['due_date'])}',
                                style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                            const Spacer(),
                            if (status == 'unpaid' || status == 'overdue')
                              SizedBox(
                                height: 28,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () => showBillingPaymentDialog(context, bill: bill, provider: provider),
                                  icon: const Icon(Icons.payment, size: 14),
                                  label: Text('Pay \$${fmtMoney(balance)}'),
                                ),
                              )
                            else
                              SizedBox(
                                height: 28,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () => showBillingBillDetailDialog(context, bill: bill, provider: provider),
                                  icon: const Icon(Icons.visibility, size: 14),
                                  label: const Text('View'),
                                ),
                              ),
                            const SizedBox(width: 4),
                            IconButton(
                              iconSize: 16,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                              icon: Icon(Icons.info_outline, size: 16, color: DomendraTheme.onSurfaceMuted),
                              onPressed: () => showBillingBillDetailDialog(context, bill: bill, provider: provider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              )),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════════════

class _KpiGrid extends StatelessWidget {
  final List<Widget> children;
  const _KpiGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 2 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg, iconColor;
  final String? subtitle;

  const _KpiCard({
    required this.label, required this.value, required this.icon,
    required this.iconBg, required this.iconColor, this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String chip;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.chip, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DomendraTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(chip, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _ProjectionRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? const Color(0xFF1E293B) : DomendraTheme.onSurfaceMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillInfo extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _BillInfo({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: DomendraTheme.danger),
              const SizedBox(height: 12),
              Text('Failed to load billing data', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ],
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
// Date preset filter bar
// ════════════════════════════════════════════════════════════

class _PresetBar extends StatelessWidget {
  final BillingProvider provider;
  const _PresetBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: BillingProvider.presets.map((p) {
            final active = provider.preset == p['value'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: active ? DomendraTheme.primary : Colors.transparent,
                  foregroundColor: active ? Colors.white : DomendraTheme.onSurfaceMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 30),
                  textStyle: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => provider.setPreset(p['value']!),
                child: Text(p['label']!),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Charts (fl_chart)
// ════════════════════════════════════════════════════════════

class _DailyRequestsChart extends StatelessWidget {
  final BillingProvider provider;
  const _DailyRequestsChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.dailySeries;
    if (data.isEmpty) return const SizedBox.shrink();

    double maxReq = 0;
    for (final d in data) {
      final r = toDoubleOr(d['requests']);
      if (r > maxReq) maxReq = r;
    }
    if (maxReq == 0) maxReq = 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      height: 240,
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.show_chart, size: 16, color: DomendraTheme.primary),
            const SizedBox(width: 6),
            const Text('Daily API Requests', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: maxReq * 1.3,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      final r = toDoubleOr(e.value['requests']);
                      return FlSpot(e.key.toDouble(), r);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF6366F1),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFF6366F1).withOpacity(0.25), const Color(0xFF6366F1).withOpacity(0.02)],
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (data.length / 5).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final date = data[i]['date'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(date.length >= 5 ? date.substring(5) : date, style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(_compact(value), style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodDonutChart extends StatelessWidget {
  final BillingProvider provider;
  const _MethodDonutChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.methodDist;
    return Container(
      padding: const EdgeInsets.all(12),
      height: 240,
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Method Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: data.asMap().entries.map((e) {
                        final m = e.value;
                        final count = toDoubleOr(m['count']);
                        final total = data.fold<double>(0, (s, d) => s + toDoubleOr((d as Map)['count']));
                        final pct = total > 0 ? (count / total * 100) : 0.0;
                        final colors = [const Color(0xFF6366F1), const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF3B82F6)];
                        return PieChartSectionData(
                          value: count,
                          title: '${pct.toInt()}%',
                          color: colors[e.key % colors.length],
                          radius: 32,
                          titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          if (data.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: data.asMap().entries.map((e) {
                final colors = [const Color(0xFF6366F1), const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF3B82F6)];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: colors[e.key % colors.length])),
                    const SizedBox(width: 4),
                    Text('${e.value['method']} (${fmtInt(e.value['count'])})', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final BillingProvider provider;
  const _StatusPieChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.statusDist;
    return Container(
      padding: const EdgeInsets.all(12),
      height: 240,
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Codes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      sections: data.map((s) {
                        final code = toIntOr(s['status_code']);
                        return PieChartSectionData(
                          value: toDoubleOr(s['count']),
                          title: '$code',
                          color: code >= 500 ? const Color(0xFFEF4444) : code >= 400 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          radius: 28,
                          titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: data.map((s) {
              final code = toIntOr(s['status_code']);
              final c = code >= 500 ? const Color(0xFFEF4444) : code >= 400 ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
                  const SizedBox(width: 4),
                  Text('$code (${fmtInt(s['count'])})', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HourBarChart extends StatelessWidget {
  final BillingProvider provider;
  const _HourBarChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hours = provider.hourDist;
    final maxVal = hours.fold<int>(0, (a, b) => math.max(a, b)).toDouble();
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      height: 220,
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: DomendraTheme.primary),
            const SizedBox(width: 6),
            const Text('Usage by Hour of Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final h = value.toInt();
                        if (h < 0 || h > 23) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${h}h', style: const TextStyle(fontSize: 7, color: DomendraTheme.onSurfaceMuted)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(_compact(value), style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: hours
                    .asMap()
                    .entries
                    .map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              color: const Color(0xFF6366F1),
                              width: 8,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────

String _compact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toInt().toString();
}
