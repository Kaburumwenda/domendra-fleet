import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/lessor_model.dart';
import '../../../providers/lessor_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'lessor_dialogs.dart';

/// Module-level currency symbol, populated from [DashboardProvider] in
/// [_LessorsScreenState.initState].  Mirrors the pattern used in
/// `vehicles_screen.dart`.
String _currencySymbol = 'KSh';

/// Lessors screen — mirrors the web `pages/app/lessors/index.vue`.
///
/// Tabbed hub for lease management:
///  1. Overview    — KPIs, monthly payment charts, top lessors, alerts
///  2. Lessors     — searchable/filterable card list
///  3. Contracts   — contract list with activate/terminate actions
///  4. Payments    — payment list with mark-paid/mark-overdue
///  5. Documents   — document card grid
///  6. Locations   — per-location financial analysis
///  7. Profit/Loss — P&L statement with charts
class LessorsScreen extends StatefulWidget {
  const LessorsScreen({super.key});

  @override
  State<LessorsScreen> createState() => _LessorsScreenState();
}

class _LessorsScreenState extends State<LessorsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Lessors'),
    Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Contracts'),
    Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Payments'),
    Tab(icon: Icon(Icons.folder_outlined, size: 18), text: 'Documents'),
    Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Locations'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'P&L'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      final p = context.read<LessorProvider>();
      p.refresh();
      p.refreshAnalytics();
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
        title: const Text('Lessors'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<LessorProvider>().refresh(),
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
      drawer: const AppDrawer(currentRoute: '/lessors'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _LessorsTab(),
          _ContractsTab(),
          _PaymentsTab(),
          _DocumentsTab(),
          _LocationsTab(),
          _ProfitLossTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: DomendraTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final tabIndex = _tabController.index;
    switch (tabIndex) {
      case 1:
        showLessorFormDialog(context, null);
        break;
      case 2:
        showContractFormDialog(context, null);
        break;
      case 3:
        showPaymentFormDialog(context, null);
        break;
      case 4:
        showDocumentFormDialog(context);
        break;
      default:
        showLessorFormDialog(context, null);
    }
  }
}

// ════════════════════════════════════════════════════════════
// 1. OVERVIEW TAB
// ════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessorProvider>();
    final a = p.analytics;

    if (p.analyticsLoading && a == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (a == null) {
      return _SimpleEmpty(
        icon: Icons.analytics_outlined,
        message: 'No analytics data',
        onRetry: () => p.refreshAnalytics(),
      );
    }

    final summary = a['summary'] as Map<String, dynamic>? ?? {};
    final monthlySeries = (a['monthly_series'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final topLessors = (a['top_lessors'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalLessors = _getInt(summary, 'total_lessors');
    final activeLessors = _getInt(summary, 'active_lessors');
    final activeContracts = _getInt(summary, 'active_contracts');
    final expiring30 = _getInt(summary, 'expiring_30d');
    final totalPending = _getDouble(summary, 'total_pending');
    final overdueCount = _getInt(summary, 'overdue_count');
    final totalMonthlyLease = _getDouble(summary, 'total_monthly_lease');
    final leasedVehicles = _getInt(summary, 'leased_vehicles');
    final totalPaid = _getDouble(summary, 'total_paid');
    final overdueAmount = _getDouble(summary, 'overdue_amount');
    final companyLessors = _getInt(summary, 'company_lessors');
    final individualLessors = _getInt(summary, 'individual_lessors');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI cards
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Total Lessors', value: '$totalLessors', subtitle: '$activeLessors active', color: DomendraTheme.primary)),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(label: 'Active Contracts', value: '$activeContracts', subtitle: '$expiring30 expiring 30d', color: DomendraTheme.info)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Pending', value: _fmtMoney(totalPending), subtitle: '$overdueCount overdue', color: DomendraTheme.warning)),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(label: 'Monthly Lease', value: _fmtMoney(totalMonthlyLease), subtitle: '$leasedVehicles leased', color: DomendraTheme.success)),
          ],
        ),
        const SizedBox(height: 16),
        // Monthly payments chart
        if (monthlySeries.isNotEmpty) ...[
          _MonthlyPaymentsChart(data: monthlySeries),
          const SizedBox(height: 16),
        ],
        // Top lessors by fleet
        if (topLessors.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DomendraTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DomendraTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 18, color: DomendraTheme.primary),
                    SizedBox(width: 6),
                    Text('Top Lessors by Fleet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                ...topLessors.asMap().entries.map((e) {
                  final m = e.value;
                  final name = m['display_name']?.toString() ??
                      m['company_name']?.toString() ??
                      '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
                  final count = _getInt(m, 'vehicle_count');
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: DomendraTheme.primary.withOpacity(0.1),
                      child: Text('${e.key + 1}', style: const TextStyle(color: DomendraTheme.primary, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text('$count vehicles', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Alerts row
        Row(
          children: [
            Expanded(child: _AlertCard(icon: Icons.check_circle, color: DomendraTheme.success, label: 'Total Paid', value: _fmtMoney(totalPaid))),
            const SizedBox(width: 8),
            Expanded(child: _AlertCard(icon: Icons.schedule, color: DomendraTheme.warning, label: 'Pending', value: _fmtMoney(totalPending))),
            const SizedBox(width: 8),
            Expanded(child: _AlertCard(icon: Icons.dangerous, color: DomendraTheme.danger, label: 'Overdue', value: _fmtMoney(overdueAmount))),
          ],
        ),
        const SizedBox(height: 16),
        // Composition
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DomendraTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DomendraTheme.outline),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 18, color: DomendraTheme.primary),
                  SizedBox(width: 6),
                  Text('Lessor Composition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('$companyLessors', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: DomendraTheme.primary)),
                        const Text('Companies', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: DomendraTheme.outline),
                  Expanded(
                    child: Column(
                      children: [
                        Text('$individualLessors', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: DomendraTheme.info)),
                        const Text('Individuals', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. LESSORS TAB
// ════════════════════════════════════════════════════════════
class _LessorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessorProvider>();
    final list = p.filteredLessors;

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: p.setSearch,
            decoration: InputDecoration(
              hintText: 'Search lessors...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: p.search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => p.setSearch(''))
                  : null,
              isDense: true,
            ),
          ),
        ),
        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _TypeChip(label: 'All', value: null, current: p.typeFilter, onSelect: p.setTypeFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Individual', value: 'individual', current: p.typeFilter, onSelect: p.setTypeFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Company', value: 'company', current: p.typeFilter, onSelect: p.setTypeFilter),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${list.length} lessor${list.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
          ),
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.refresh,
            child: p.loading && p.lessors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : p.error != null && p.lessors.isEmpty
                    ? _ErrorState(error: p.error!, onRetry: p.refresh)
                    : list.isEmpty
                        ? _EmptyState(icon: Icons.handshake_outlined, message: 'No lessors found', onAdd: () => showLessorFormDialog(context, null))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                            itemCount: list.length,
                            itemBuilder: (context, i) => _LessorCard(lessor: list[i]),
                          ),
          ),
        ),
      ],
    );
  }
}

class _LessorCard extends StatelessWidget {
  final Lessor lessor;
  const _LessorCard({required this.lessor});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(lessor.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: DomendraTheme.danger),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit, color: DomendraTheme.primary),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          showLessorFormDialog(context, lessor);
          return false;
        }
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Lessor'),
            content: Text('Delete "${lessor.displayName}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd && lessor.id != null) {
          await context.read<LessorProvider>().deleteLessor(lessor.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lessor deleted'), backgroundColor: DomendraTheme.danger));
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DomendraTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DomendraTheme.outline),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: (lessor.lessorType == LessorType.company ? DomendraTheme.primary : DomendraTheme.info).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    lessor.lessorType == LessorType.company ? Icons.business : Icons.person,
                    color: lessor.lessorType == LessorType.company ? DomendraTheme.primary : DomendraTheme.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lessor.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (lessor.email.isNotEmpty)
                        Text(lessor.email, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _Chip(label: lessor.typeLabel, color: lessor.lessorType == LessorType.company ? DomendraTheme.primary : DomendraTheme.info),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12, runSpacing: 6,
              children: [
                _DetailPill(icon: Icons.directions_car_outlined, label: '${lessor.vehicleCount} vehicles'),
                _DetailPill(icon: Icons.link_outlined, label: '${lessor.activeLeaseCount} active leases'),
                _DetailPill(icon: Icons.payments, label: _fmtMoney(lessor.monthlyEarnings)),
                if (lessor.unpaidAmount > 0)
                  _DetailPill(icon: Icons.warning_amber, label: 'Unpaid: ${_fmtMoney(lessor.unpaidAmount)}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showLessorFormDialog(context, lessor),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showPaymentFormDialog(context, lessor),
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Payment', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: const Size(0, 32)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36, height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline, size: 16, color: DomendraTheme.danger),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Lessor'),
                          content: Text('Delete "${lessor.displayName}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true && lessor.id != null) {
                        await context.read<LessorProvider>().deleteLessor(lessor.id!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. CONTRACTS TAB
// ════════════════════════════════════════════════════════════
class _ContractsTab extends StatefulWidget {
  @override
  State<_ContractsTab> createState() => _ContractsTabState();
}

class _ContractsTabState extends State<_ContractsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessorProvider>().refreshContracts();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<LessorProvider>();
    final list = p.filteredContracts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: p.setContractSearch,
            decoration: InputDecoration(
              hintText: 'Search contracts...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _TypeChip(label: 'All', value: null, current: p.contractStatusFilter, onSelect: p.setContractStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Active', value: 'active', current: p.contractStatusFilter, onSelect: p.setContractStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Draft', value: 'draft', current: p.contractStatusFilter, onSelect: p.setContractStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Pending', value: 'pending', current: p.contractStatusFilter, onSelect: p.setContractStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Expired', value: 'expired', current: p.contractStatusFilter, onSelect: p.setContractStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Terminated', value: 'terminated', current: p.contractStatusFilter, onSelect: p.setContractStatusFilter),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.refreshContracts,
            child: p.contractsLoading && p.contracts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? _EmptyState(icon: Icons.description_outlined, message: 'No contracts found', onAdd: () => showContractFormDialog(context, null))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _ContractCard(contract: list[i]),
                      ),
          ),
        ),
      ],
    );
  }
}

class _ContractCard extends StatelessWidget {
  final LessorContract contract;
  const _ContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final p = context.read<LessorProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description, size: 18, color: DomendraTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${contract.contractNumber}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              _ContractStatusChip(status: contract.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12, runSpacing: 4,
            children: [
              _DetailPill(icon: Icons.person_outline, label: contract.lessorName),
              _DetailPill(icon: Icons.payments, label: _fmtMoney(contract.monthlyRate)),
              _DetailPill(icon:Icons.account_balance_wallet, label: _fmtMoney(contract.totalValue)),
              if (contract.daysRemaining != null)
                _DetailPill(
                  icon: Icons.calendar_today,
                  label: contract.daysRemaining! > 0 ? '${contract.daysRemaining}d left' : 'Expired',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (contract.status == ContractStatus.draft || contract.status == ContractStatus.pending)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await p.activateContract(contract.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract activated'), backgroundColor: DomendraTheme.success));
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Activate', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), minimumSize: const Size(0, 32)),
                  ),
                )
              else if (contract.status == ContractStatus.active) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await p.terminateContract(contract.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract terminated'), backgroundColor: DomendraTheme.warning));
                      }
                    },
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Terminate', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: DomendraTheme.danger, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), minimumSize: const Size(0, 32)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 36, height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: () => showContractFormDialog(context, contract),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 36, height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete_outline, size: 16, color: DomendraTheme.danger),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Contract'),
                        content: Text('Delete "${contract.title}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await p.deleteContract(contract.id!);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. PAYMENTS TAB
// ════════════════════════════════════════════════════════════
class _PaymentsTab extends StatefulWidget {
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessorProvider>().refreshPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<LessorProvider>();
    final list = p.filteredPayments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            onChanged: p.setPaymentSearch,
            decoration: InputDecoration(
              hintText: 'Search payments...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _TypeChip(label: 'All', value: null, current: p.paymentStatusFilter, onSelect: p.setPaymentStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Pending', value: 'pending', current: p.paymentStatusFilter, onSelect: p.setPaymentStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Paid', value: 'paid', current: p.paymentStatusFilter, onSelect: p.setPaymentStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Overdue', value: 'overdue', current: p.paymentStatusFilter, onSelect: p.setPaymentStatusFilter),
              const SizedBox(width: 8),
              _TypeChip(label: 'Cancelled', value: 'cancelled', current: p.paymentStatusFilter, onSelect: p.setPaymentStatusFilter),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final count = await p.markAllOverdue();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count payments marked overdue'), backgroundColor: DomendraTheme.warning));
                  }
                },
                icon: const Icon(Icons.update, size: 16),
                label: const Text('Mark Overdue', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: const Size(0, 32)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => showPaymentFormDialog(context, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Record', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), minimumSize: const Size(0, 32)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.refreshPayments,
            child: p.paymentsLoading && p.payments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? _EmptyState(icon: Icons.payments_outlined, message: 'No payments found', onAdd: () => showPaymentFormDialog(context, null))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _PaymentCard(payment: list[i]),
                      ),
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final LessorPayment payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final p = context.read<LessorProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: payment.isOverdue ? DomendraTheme.danger.withOpacity(0.3) : DomendraTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _paymentColor(payment.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(payment.isOverdue ? Icons.warning : Icons.payment, size: 18, color: _paymentColor(payment.status)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmtMoney(payment.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(payment.lessorName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (payment.invoiceNumber.isNotEmpty)
                  Text('# ${payment.invoiceNumber}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PaymentStatusChip(status: payment.status),
              const SizedBox(height: 4),
              Text(_fmtDate(payment.dueDate), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) async {
              switch (action) {
                case 'paid':
                  await p.markPaymentPaid(payment.id!);
                  break;
                case 'edit':
                  if (context.mounted) showPaymentFormDialog(context, payment);
                  break;
                case 'delete':
                  await p.deletePayment(payment.id!);
                  break;
              }
            },
            itemBuilder: (_) => [
              if (payment.status == PaymentStatus.pending || payment.status == PaymentStatus.overdue)
                const PopupMenuItem(value: 'paid', child: Text('Mark Paid')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

Color _paymentColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid: return DomendraTheme.success;
    case PaymentStatus.pending: return DomendraTheme.warning;
    case PaymentStatus.overdue: return DomendraTheme.danger;
    case PaymentStatus.cancelled: return DomendraTheme.onSurfaceMuted;
  }
}

// ════════════════════════════════════════════════════════════
// 5. DOCUMENTS TAB
// ════════════════════════════════════════════════════════════
class _DocumentsTab extends StatefulWidget {
  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessorProvider>().refreshDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<LessorProvider>();

    return RefreshIndicator(
      onRefresh: p.refreshDocuments,
      child: p.documentsLoading && p.documents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : p.documents.isEmpty
              ? _EmptyState(icon: Icons.folder_outlined, message: 'No documents found', onAdd: () => showDocumentFormDialog(context))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                  itemCount: p.documents.length,
                  itemBuilder: (context, i) => _DocumentCard(doc: p.documents[i]),
                ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final LessorDocument doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final p = context.read<LessorProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: doc.isExpired ? DomendraTheme.danger.withOpacity(0.3) : DomendraTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.insert_drive_file_outlined, size: 20, color: DomendraTheme.info),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(doc.lessorName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                Row(
                  children: [
                    _Chip(label: doc.typeLabel, color: DomendraTheme.info),
                    if (doc.isExpired) ...[
                      const SizedBox(width: 6),
                      _Chip(label: 'Expired', color: DomendraTheme.danger),
                    ] else if (doc.expiresAt != null) ...[
                      const SizedBox(width: 6),
                      Text(_fmtDate(doc.expiresAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) async {
              if (action == 'delete') {
                await p.deleteDocument(doc.id!);
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 6. LOCATIONS TAB
// ════════════════════════════════════════════════════════════
class _LocationsTab extends StatefulWidget {
  @override
  State<_LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<_LocationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessorProvider>().refreshLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessorProvider>();
    final data = p.locationsData;

    if (p.locationsLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _SimpleEmpty(icon: Icons.location_on_outlined, message: 'No locations data', onRetry: () => p.refreshLocations());
    }

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final locations = (data['locations'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalLocations = _getInt(summary, 'total_locations');
    final totalMonthlyLease = _getDouble(summary, 'total_monthly_lease');
    final totalNetProfit = _getDouble(summary, 'total_net_profit');
    final totalDeposit = _getDouble(summary, 'total_deposit_held');
    final expiring30d = _getInt(summary, 'expiring_30d');
    final topProfitLoc = summary['top_profit_location']?.toString() ?? '';
    final topLossLoc = summary['top_loss_location']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Locations', value: '$totalLocations', subtitle: '$expiring30d expiring', color: DomendraTheme.primary)),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(label: 'Monthly Lease', value: _fmtMoney(totalMonthlyLease), subtitle: 'total', color: DomendraTheme.info)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Net Profit', value: _fmtMoney(totalNetProfit), subtitle: 'all locations', color: totalNetProfit >= 0 ? DomendraTheme.success : DomendraTheme.danger)),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(label: 'Deposits', value: _fmtMoney(totalDeposit), subtitle: 'held', color: DomendraTheme.warning)),
          ],
        ),
        const SizedBox(height: 12),
        if (topProfitLoc.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.success.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: DomendraTheme.success, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(topProfitLoc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Text(_fmtMoney(_getDouble(summary, 'top_profit_value')), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.success)),
              ],
            ),
          ),
        if (topLossLoc.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.danger.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.trending_down, color: DomendraTheme.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(topLossLoc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Text(_fmtMoney(_getDouble(summary, 'top_loss_value')), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.danger)),
              ],
            ),
          ),
        ...locations.map((loc) {
          final name = loc['name']?.toString() ?? 'Unknown';
          final vehicleCount = _getInt(loc, 'vehicle_count');
          final revenue = _getDouble(loc, 'revenue');
          final costs = _getDouble(loc, 'total_costs');
          final netProfit = _getDouble(loc, 'net_profit');

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: DomendraTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    _Chip(label: '$vehicleCount vehicles', color: DomendraTheme.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _MiniCell(label: 'Revenue', value: _fmtMoney(revenue), color: DomendraTheme.success)),
                    Expanded(child: _MiniCell(label: 'Costs', value: _fmtMoney(costs), color: DomendraTheme.danger)),
                    Expanded(child: _MiniCell(label: 'Profit', value: _fmtMoney(netProfit), color: netProfit >= 0 ? DomendraTheme.success : DomendraTheme.danger)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 7. PROFIT & LOSS TAB
// ════════════════════════════════════════════════════════════
class _ProfitLossTab extends StatefulWidget {
  @override
  State<_ProfitLossTab> createState() => _ProfitLossTabState();
}

class _ProfitLossTabState extends State<_ProfitLossTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessorProvider>().refreshProfitLoss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LessorProvider>();
    final data = p.profitLoss;

    if (p.profitLossLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data == null) {
      return _SimpleEmpty(icon: Icons.analytics_outlined, message: 'No P&L data', onRetry: () => p.refreshProfitLoss());
    }

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final statement = (data['statement'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final monthlySeries = (data['monthly_series'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final costBreakdown = (data['cost_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final totalRevenue = _getDouble(summary, 'total_revenue');
    final totalCosts = _getDouble(summary, 'total_costs');
    final netProfit = _getDouble(summary, 'net_profit');
    final netMargin = _getDouble(summary, 'net_margin');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI cards
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Revenue', value: _fmtMoney(totalRevenue), subtitle: 'total', color: DomendraTheme.success)),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(label: 'Costs', value: _fmtMoney(totalCosts), subtitle: 'total', color: DomendraTheme.danger)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Net Profit', value: _fmtMoney(netProfit), subtitle: 'total', color: netProfit >= 0 ? DomendraTheme.success : DomendraTheme.danger)),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(label: 'Net Margin', value: '${netMargin.toStringAsFixed(1)}%', subtitle: 'margin', color: DomendraTheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        // Monthly trend line chart
        if (monthlySeries.isNotEmpty) ...[
          _ProfitTrendChart(data: monthlySeries),
          const SizedBox(height: 16),
        ],
        // Cost distribution donut
        if (costBreakdown.isNotEmpty) ...[
          _CostDonutChart(data: costBreakdown),
          const SizedBox(height: 16),
        ],
        // P&L Statement
        if (statement.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: DomendraTheme.outline)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18, color: DomendraTheme.primary),
                    SizedBox(width: 6),
                    Text('P&L Statement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                ...statement.map((item) {
                  final label = item['label']?.toString() ?? '';
                  final amount = _getDouble(item, 'amount');
                  final type = item['type']?.toString() ?? '';
                  final isHeader = type == 'header';
                  final isTotal = type == 'total';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: isHeader || isTotal ? 13 : 12,
                              fontWeight: isHeader || isTotal ? FontWeight.w700 : FontWeight.w400,
                              color: isHeader ? DomendraTheme.primary : (isTotal ? DomendraTheme.onSurface : DomendraTheme.onSurfaceMuted),
                            ),
                          ),
                        ),
                        if (!isHeader)
                          Text(
                            _fmtMoney(amount),
                            style: TextStyle(
                              fontSize: isTotal ? 13 : 12,
                              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                              color: amount < 0 ? DomendraTheme.danger : (isTotal ? DomendraTheme.onSurface : DomendraTheme.onSurfaceMuted),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _AlertCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _MiniCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  final ValueChanged<String?> onSelect;
  const _TypeChip({required this.label, required this.value, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : DomendraTheme.onSurfaceMuted)),
      selected: selected,
      onSelected: (_) => onSelect(selected ? null : value),
      selectedColor: DomendraTheme.primary,
      backgroundColor: DomendraTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ContractStatusChip extends StatelessWidget {
  final ContractStatus status;
  const _ContractStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ContractStatus.draft => (DomendraTheme.onSurfaceMuted, 'Draft'),
      ContractStatus.pending => (DomendraTheme.warning, 'Pending'),
      ContractStatus.active => (DomendraTheme.success, 'Active'),
      ContractStatus.expired => (DomendraTheme.danger, 'Expired'),
      ContractStatus.terminated => (DomendraTheme.danger, 'Terminated'),
    };
    return _Chip(label: label, color: color);
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;
  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      PaymentStatus.paid => (DomendraTheme.success, 'Paid'),
      PaymentStatus.pending => (DomendraTheme.warning, 'Pending'),
      PaymentStatus.overdue => (DomendraTheme.danger, 'Overdue'),
      PaymentStatus.cancelled => (DomendraTheme.onSurfaceMuted, 'Cancelled'),
    };
    return _Chip(label: label, color: color);
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DomendraTheme.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}

class _MonthlyPaymentsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _MonthlyPaymentsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final collected = data.map((e) => _getDouble(e, 'collected')).toList();
    final paid = data.map((e) => _getDouble(e, 'paid')).toList();
    final maxV = [...collected, ...paid].fold<double>(0, (a, b) => a > b ? a : b);
    if (maxV == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Monthly Payments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: DomendraTheme.primary, label: 'Collected'),
              const SizedBox(width: 12),
              _LegendDot(color: DomendraTheme.success, label: 'Paid'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxV * 1.2,
              barGroups: data.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(toY: collected[e.key], color: DomendraTheme.primary, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  BarChartRodData(toY: paid[e.key], color: DomendraTheme.success, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ]);
              }).toList(),
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            )),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (_, i) => SizedBox(
                width: 60,
                child: Text(_truncateMonth(data[i]['month']?.toString() ?? ''), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ProfitTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final revenues = data.map((e) => _getDouble(e, 'revenue')).toList();
    final costs = data.map((e) => _getDouble(e, 'costs')).toList();
    final profits = data.map((e) => _getDouble(e, 'profit')).toList();
    final allValues = [...revenues, ...costs, ...profits.map((p) => p.abs())];
    final maxV = allValues.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxV == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Revenue vs Costs vs Profit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: DomendraTheme.success, label: 'Revenue'),
              const SizedBox(width: 12),
              _LegendDot(color: DomendraTheme.danger, label: 'Costs'),
              const SizedBox(width: 12),
              _LegendDot(color: DomendraTheme.primary, label: 'Profit'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              maxY: maxV * 1.1,
              minY: 0,
              lineBarsData: [
                LineChartBarData(spots: revenues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), color: DomendraTheme.success, isCurved: true, dotData: const FlDotDataShow(false), belowBarData: BarAreaData(show: true, color: DomendraTheme.success.withOpacity(0.1))),
                LineChartBarData(spots: costs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), color: DomendraTheme.danger, isCurved: true, dotData: const FlDotDataShow(false), belowBarData: BarAreaData(show: true, color: DomendraTheme.danger.withOpacity(0.1))),
                LineChartBarData(spots: profits.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), color: DomendraTheme.primary, isCurved: true, dotData: const FlDotDataShow(false)),
              ],
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            )),
          ),
        ],
      ),
    );
  }
}

class _CostDonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CostDonutChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [DomendraTheme.danger, DomendraTheme.warning, DomendraTheme.info, DomendraTheme.primary, DomendraTheme.onSurfaceMuted];
    final total = data.fold<double>(0, (s, e) => s + _getDouble(e, 'value'));
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: DomendraTheme.outline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.donut_small, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Cost Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sections: data.asMap().entries.map((e) {
                    final value = _getDouble(e.value, 'value');
                    return PieChartSectionData(
                      value: value,
                      color: colors[e.key % colors.length],
                      radius: 45,
                      title: value > 0 ? '${(value / total * 100).round()}%' : '',
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                )),
                Positioned(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fmtMoney(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const Text('Total', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: data.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Text(e.value['name']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared states
// ════════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.error_outline, size: 48, color: DomendraTheme.danger),
        const SizedBox(height: 16),
        const Text('Failed to load', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onAdd;
  const _EmptyState({required this.icon, required this.message, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
      ],
    );
  }
}

class _SimpleEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  const _SimpleEmpty({required this.icon, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Load')),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════════════════
int _getInt(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _getDouble(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String _fmtDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _fmtMoney(double v) {
  final sym = _currencySymbol;
  if (v == 0) return '$sym 0';
  final abs = v.abs();
  if (abs >= 1000000) return '$sym ${(v / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '$sym ${(v / 1000).toStringAsFixed(1)}k';
  return '$sym ${v.toStringAsFixed(0)}';
}

String _truncateMonth(String m) {
  // "Jan 2025" → "Jan"
  return m.split(' ').first;
}

// FlDotData show workaround for const constructor
class FlDotDataShow extends FlDotData {
  const FlDotDataShow(bool show) : super(show: show);
}
