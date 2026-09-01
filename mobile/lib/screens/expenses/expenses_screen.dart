import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/api_service.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';
import 'expense_dialogs.dart';

/// Expenses screen — mirrors web `/app/expenses`.
///
/// 6 tabs: Overview, Records, Approvals, Recurring, Budgets, Categories.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Records'),
    Tab(icon: Icon(Icons.check_circle_outline, size: 18), text: 'Approvals'),
    Tab(icon: Icon(Icons.repeat, size: 18), text: 'Recurring'),
    Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 18), text: 'Budgets'),
    Tab(icon: Icon(Icons.category_outlined, size: 18), text: 'Categories'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadCurrency();
      context.read<ExpensesProvider>().refresh();
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
        title: const Text('Expenses'),
        leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<ExpensesProvider>().refresh(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              final provider = context.read<ExpensesProvider>();
              if (value == 'seed') provider.seedDemo();
              if (value == 'new') showExpenseFormDialog(context, provider);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'new', child: Text('New Expense')),
              const PopupMenuItem(value: 'seed', child: Text('Seed Demo Data')),
            ],
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
      drawer: const AppDrawer(currentRoute: '/expenses'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final provider = context.read<ExpensesProvider>();
          showExpenseFormDialog(context, provider);
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ExpensesProvider>(
        builder: (context, p, _) {
          if (p.loading && p.expenses.isEmpty && p.summary.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.error != null && p.expenses.isEmpty && p.summary.isEmpty) {
            return _ErrorState(message: p.error!, onRetry: () => p.refresh());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(provider: p),
              _RecordsTab(provider: p),
              _ApprovalsTab(provider: p),
              _RecurringTab(provider: p),
              _BudgetsTab(provider: p),
              _CategoriesTab(provider: p),
            ],
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Overview tab
// ════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final ExpensesProvider provider;
  const _OverviewTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<DashboardProvider>().currencySymbol;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI cards
        _KpiGrid(children: [
          _KpiCard(
            label: 'Total Spend', value: '$cur${fmtMoney(provider.totalAmount)}',
            icon: Icons.payments, iconBg: const Color(0xFFEEF2FF), iconColor: DomendraTheme.primary,
            subtitle: '${provider.totalCount} expenses',
          ),
          _KpiCard(
            label: 'Pending', value: '${provider.pendingCount}',
            icon: Icons.pending, iconBg: const Color(0xFFFFFBEB), iconColor: DomendraTheme.warning,
            subtitle: 'Awaiting approval',
          ),
          _KpiCard(
            label: 'Rejected', value: '${provider.rejectedCount}',
            icon: Icons.cancel, iconBg: const Color(0xFFFEF2F2), iconColor: DomendraTheme.danger,
          ),
          _KpiCard(
            label: 'Billable', value: '$cur${fmtMoney(provider.billableTotal)}',
            icon: Icons.receipt, iconBg: const Color(0xFFECFDF5), iconColor: DomendraTheme.success,
          ),
        ]),
        const SizedBox(height: 12),

        // Monthly trend chart
        if (provider.monthly.isNotEmpty) ...[
          _MonthlyTrendChart(provider: provider, currency: cur),
          const SizedBox(height: 12),
        ],

        // Category breakdown donut
        if (provider.byCategory.isNotEmpty) ...[
          _CategoryDonut(provider: provider, currency: cur),
          const SizedBox(height: 12),
        ],

        // Status breakdown
        if (provider.byStatus.isNotEmpty) ...[
          _StatusBreakdown(provider: provider),
          const SizedBox(height: 12),
        ],

        // Top vendors
        if (provider.topVendors.isNotEmpty) ...[
          _TopVendors(provider: provider, currency: cur),
          const SizedBox(height: 12),
        ],

        // Recent expenses (6)
        if (provider.recentExpenses.isNotEmpty) ...[
          const Text('Recent Expenses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...provider.recentExpenses.map((e) => _ExpenseTile(
            expense: e as Map<String, dynamic>,
            currency: cur,
            onTap: () => showExpenseDetail(context, e as Map<String, dynamic>, provider),
          )),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Records tab — full list with filter
// ════════════════════════════════════════════════════════════

class _RecordsTab extends StatefulWidget {
  final ExpensesProvider provider;
  const _RecordsTab({required this.provider});

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab> {
  String _search = '';
  String _statusFilter = '';
  String _categoryFilter = '';

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final cur = context.watch<DashboardProvider>().currencySymbol;
    final filtered = p.expenses.where((e) {
      final m = e as Map<String, dynamic>;
      if (_statusFilter.isNotEmpty && (m['status'] as String? ?? '') != _statusFilter) return false;
      if (_categoryFilter.isNotEmpty) {
        final catId = m['category'] as int?;
        if (catId?.toString() != _categoryFilter) return false;
      }
      if (_search.isNotEmpty) {
        final title = (m['title'] as String? ?? '').toLowerCase();
        final vendor = (m['vendor_name'] as String? ?? '').toLowerCase();
        final num = (m['expense_number'] as String? ?? '').toLowerCase();
        if (!title.contains(_search.toLowerCase()) &&
            !vendor.contains(_search.toLowerCase()) &&
            !num.contains(_search.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter row
        Container(
          padding: const EdgeInsets.all(8),
          color: DomendraTheme.surface,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search expenses…',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter.isEmpty ? null : _statusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status', border: OutlineInputBorder(), isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoryFilter.isEmpty ? null : _categoryFilter,
                      decoration: const InputDecoration(
                        labelText: 'Category', border: OutlineInputBorder(), isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All')),
                        ...p.categories.map((c) {
                          final cm = c as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: '${cm['id'] ?? 0}',
                            child: Text(cm['name'] as String? ?? '', overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No expenses found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final e = filtered[i] as Map<String, dynamic>;
                    return _ExpenseTile(
                      expense: e,
                      currency: cur,
                      onTap: () => showExpenseDetail(ctx, e, p),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Approvals tab
// ════════════════════════════════════════════════════════════

class _ApprovalsTab extends StatelessWidget {
  final ExpensesProvider provider;
  const _ApprovalsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<DashboardProvider>().currencySymbol;
    final pending = provider.pendingApprovals;
    if (pending.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 48, color: DomendraTheme.success.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No pending approvals', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: pending.length,
      itemBuilder: (ctx, i) {
        final e = pending[i] as Map<String, dynamic>;
        final status = e['status'] as String? ?? 'draft';
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
                      color: expenseStatusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt, size: 16, color: expenseStatusColor(status)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['title'] as String? ?? 'Untitled',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('${e['expense_number'] ?? ''} • ${e['category_name'] ?? '—'}',
                            style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  Text('$cur${fmtMoney(e['total_amount'] ?? e['amount'])}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (status == 'draft')
                    SizedBox(
                      height: 28,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        onPressed: () async {
                          await provider.submitExpense(e['id'] as int);
                        },
                        icon: const Icon(Icons.send, size: 14),
                        label: const Text('Submit'),
                      ),
                    ),
                  if (status == 'submitted') ...[
                    SizedBox(
                      height: 28,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: DomendraTheme.success,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          await provider.approveExpense(e['id'] as int);
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DomendraTheme.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => showRejectDialog(context, e, provider),
                        icon: const Icon(Icons.close, size: 14),
                        label: const Text('Reject'),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    iconSize: 18,
                    icon: const Icon(Icons.visibility, color: DomendraTheme.onSurfaceMuted),
                    onPressed: () => showExpenseDetail(context, e, provider),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Recurring tab
// ════════════════════════════════════════════════════════════

class _RecurringTab extends StatelessWidget {
  final ExpensesProvider provider;
  const _RecurringTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<DashboardProvider>().currencySymbol;
    if (provider.recurring.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No recurring rules', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: provider.recurring.length,
      itemBuilder: (ctx, i) {
        final r = provider.recurring[i] as Map<String, dynamic>;
        final next = r['next_date'] as String?;
        final daysUntil = next != null ? DateTime.parse(next).difference(DateTime.now()).inDays : null;
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
                      color: (r['auto_approve'] == true ? DomendraTheme.success : DomendraTheme.info).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.repeat, size: 16, color: r['auto_approve'] == true ? DomendraTheme.success : DomendraTheme.info),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['title'] as String? ?? 'Untitled',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('${r['frequency_display'] ?? r['frequency'] ?? '—'} • ${r['category_name'] ?? '—'}',
                            style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  Text('$cur${fmtMoney(r['amount'])}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (next != null) ...[
                    Icon(Icons.event, size: 12, color: daysUntil != null && daysUntil <= 0 ? DomendraTheme.danger : daysUntil != null && daysUntil <= 3 ? DomendraTheme.warning : DomendraTheme.success),
                    const SizedBox(width: 4),
                    Text('Next: $next', style: TextStyle(fontSize: 10, color: daysUntil != null && daysUntil <= 0 ? DomendraTheme.danger : DomendraTheme.onSurfaceMuted)),
                  ],
                  const Spacer(),
                  if (r['is_active'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Active', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: DomendraTheme.success)),
                    ),
                  IconButton(
                    iconSize: 18,
                    icon: const Icon(Icons.delete_outline, color: DomendraTheme.danger),
                    onPressed: () => provider.deleteRecurring(r['id'] as int),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Budgets tab
// ════════════════════════════════════════════════════════════

class _BudgetsTab extends StatefulWidget {
  final ExpensesProvider provider;
  const _BudgetsTab({required this.provider});

  @override
  State<_BudgetsTab> createState() => _BudgetsTabState();
}

class _BudgetsTabState extends State<_BudgetsTab> {
  Map<String, dynamic>? _budgetSummary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final s = await ApiService.instance.fetchExpenseBudgetSummary();
      if (mounted) setState(() => _budgetSummary = s);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final cur = context.watch<DashboardProvider>().currencySymbol;
    final rows = _budgetSummary?['rows'] as List<dynamic>? ?? p.budgets;

    if (rows.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No budgets set', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i] as Map<String, dynamic>;
        final budget = toDoubleOr(r['budget_amount']);
        final actual = toDoubleOr(r['actual_amount']);
        final pct = budget > 0 ? (actual / budget * 100) : 0.0;
        final variance = toDoubleOr(r['variance']);
        final pctColor = pct >= 100 ? DomendraTheme.danger : pct >= 80 ? DomendraTheme.warning : DomendraTheme.success;
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
                  Expanded(
                    child: Text(r['budget_label'] as String? ?? r['scope'] as String? ?? 'Budget',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pctColor)),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: DomendraTheme.outline,
                  color: pctColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget: $cur${fmtMoney(budget)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                  Text('Actual: $cur${fmtMoney(actual)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  Text('Variance: $cur${fmtMoney(variance)}', style: TextStyle(fontSize: 10, color: variance >= 0 ? DomendraTheme.danger : DomendraTheme.success)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Categories tab
// ════════════════════════════════════════════════════════════

class _CategoriesTab extends StatelessWidget {
  final ExpensesProvider provider;
  const _CategoriesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.categories.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No categories', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
        ],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: provider.categories.length,
      itemBuilder: (ctx, i) {
        final c = provider.categories[i] as Map<String, dynamic>;
        final color = _parseColor(c['color'] as String?);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DomendraTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DomendraTheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.label, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'] as String? ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${c['type'] ?? '—'} • ${c['expense_count'] ?? 0} expenses',
                        style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              if (c['is_active'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Active', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: DomendraTheme.success)),
                ),
            ],
          ),
        );
      },
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (_, i) => children[i],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconBg, iconColor;
  final String? subtitle;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.iconBg, required this.iconColor, this.subtitle});

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
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
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

class _ExpenseTile extends StatelessWidget {
  final Map<String, dynamic> expense;
  final String currency;
  final VoidCallback onTap;
  const _ExpenseTile({required this.expense, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = expense['status'] as String? ?? 'draft';
    final sColor = expenseStatusColor(status);
    final total = toDoubleOr(expense['total_amount'] ?? expense['amount']);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
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
                  decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.receipt, size: 16, color: sColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense['title'] as String? ?? 'Untitled',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${expense['expense_number'] ?? ''} • ${expense['category_name'] ?? '—'}',
                          style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$currency${fmtMoney(total)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sColor)),
                    ),
                  ],
                ),
              ],
            ),
            if (expense['vendor_name'] != null || expense['expense_date'] != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (expense['vendor_name'] != null) ...[
                    Icon(Icons.store, size: 12, color: DomendraTheme.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(expense['vendor_name'] as String? ?? '', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    const SizedBox(width: 8),
                  ],
                  if (expense['expense_date'] != null) ...[
                    Icon(Icons.calendar_today, size: 12, color: DomendraTheme.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(fmtDate(expense['expense_date']), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
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
              const Text('Failed to load expenses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
// Charts
// ════════════════════════════════════════════════════════════

class _MonthlyTrendChart extends StatelessWidget {
  final ExpensesProvider provider;
  final String currency;
  const _MonthlyTrendChart({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final data = provider.monthly;
    double maxVal = 0;
    for (final d in data) {
      final v = toDoubleOr((d as Map)['amount'] ?? d['total_amount']);
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      height: 220,
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.bar_chart, size: 16, color: DomendraTheme.primary),
            const SizedBox(width: 6),
            const Text('Monthly Spend Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(BarChartData(
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      final m = data[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text((m['month'] as String? ?? '').substring(0, math.min(7, (m['month'] as String? ?? '').length)),
                            style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(_compact(value), style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final v = toDoubleOr(e.value['amount'] ?? e.value['total_amount']);
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: v, color: DomendraTheme.primary, width: 20, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  final ExpensesProvider provider;
  final String currency;
  const _CategoryDonut({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final data = provider.byCategory.take(8).toList();
    double total = data.fold(0, (s, d) => s + toDoubleOr((d as Map)['amount'] ?? d['total']));
    if (total == 0) total = 1;
    final palette = [const Color(0xFF6366F1), const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF3B82F6), const Color(0xFFEC4899), const Color(0xFF14B8A6), const Color(0xFFF97316)];

    return Container(
      padding: const EdgeInsets.all(12),
      height: 260,
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spend by Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: data.asMap().entries.map((e) {
                final m = e.value;
                final amt = toDoubleOr(m['amount'] ?? m['total']);
                final pct = (amt / total * 100);
                return PieChartSectionData(
                  value: amt,
                  title: '${pct.toInt()}%',
                  color: palette[e.key % palette.length],
                  radius: 32,
                  titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }).toList(),
            )),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 2,
            children: data.asMap().entries.map((e) {
              final m = e.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: palette[e.key % palette.length])),
                  const SizedBox(width: 4),
                  Text('${m['category_name'] ?? m['name'] ?? '—'} ($currency${_compact(toDoubleOr(m['amount'] ?? m['total']))})',
                      style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), overflow: TextOverflow.ellipsis),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final ExpensesProvider provider;
  const _StatusBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.byStatus;
    return Container(
      padding: const EdgeInsets.all(12),
      height: 200,
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: data.map((s) {
                final m = s as Map<String, dynamic>;
                final status = m['status'] as String? ?? 'draft';
                return PieChartSectionData(
                  value: toDoubleOr(m['count']),
                  title: '${toIntOr(m['count'])}',
                  color: expenseStatusColor(status),
                  radius: 28,
                  titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }).toList(),
            )),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6, runSpacing: 2,
            children: data.map((s) {
              final m = s as Map<String, dynamic>;
              final status = m['status'] as String? ?? 'draft';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: expenseStatusColor(status))),
                  const SizedBox(width: 4),
                  Text('$status (${toIntOr(m['count'])})', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TopVendors extends StatelessWidget {
  final ExpensesProvider provider;
  final String currency;
  const _TopVendors({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final data = provider.topVendors.take(8).toList();
    double maxVal = data.fold(0, (s, d) => math.max(s as double, toDoubleOr((d as Map)['amount'])));
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: const EdgeInsets.all(12),
      height: 220,
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Vendors', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(BarChartData(
              maxY: maxVal * 1.2,
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      final name = (data[i] as Map)['vendor_name'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(name.length > 6 ? '${name.substring(0, 6)}…' : name, style: const TextStyle(fontSize: 7, color: DomendraTheme.onSurfaceMuted)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(_compact(value), style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                  ),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final v = toDoubleOr(e.value['amount']);
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: v, color: const Color(0xFF6366F1), width: 16, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                ]);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────

Color expenseStatusColor(String s) => switch (s) {
      'draft' => const Color(0xFF64748B),
      'submitted' => const Color(0xFFF59E0B),
      'approved' => const Color(0xFF3B82F6),
      'rejected' => const Color(0xFFEF4444),
      'paid' => const Color(0xFF10B981),
      _ => const Color(0xFF64748B),
    };

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return DomendraTheme.primary;
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return DomendraTheme.primary;
  }
}

String fmtMoney(dynamic v) => toDoubleOr(v).toStringAsFixed(2);

String fmtInt(dynamic v) => toIntOr(v).toString();

String fmtDate(dynamic d) {
  if (d == null || d is! String || d.isEmpty) return '—';
  try {
    final dt = DateTime.parse(d);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return d;
  }
}

String _compact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toInt().toString();
}
