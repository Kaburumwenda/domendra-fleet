import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/invoices_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Invoices screen — mirrors web `/app/invoices`.
/// 2 tabs: Invoices, Stats.
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Invoices'),
    Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Stats'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<InvoicesProvider>().fetchAll();
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
        title: const Text('Invoices'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => context.read<InvoicesProvider>().fetchAll())],
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
      drawer: const AppDrawer(currentRoute: '/invoices'),
      body: Column(
        children: [
          _KpiBar(),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [_InvoicesTab(), _StatsTab()],
          )),
        ],
      ),
    );
  }
}

class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InvoicesProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(children: [
        Expanded(child: _Mini(label: 'Total', value: '${p.total}', color: DomendraTheme.primary, icon: Icons.receipt_long)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Amount', value: '$_currencySymbol${_fmtShort(p.totalAmount)}', color: const Color(0xFF3B82F6), icon: Icons.payments)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Paid', value: '$_currencySymbol${_fmtShort(p.totalPaid)}', color: const Color(0xFF10B981), icon: Icons.check_circle)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Outstanding', value: '$_currencySymbol${_fmtShort(p.totalOutstanding)}', color: const Color(0xFFEF4444), icon: Icons.error_outline)),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Mini({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1))]), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)]),
  );
}

class _InvoicesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InvoicesProvider>();
    final invoices = p.invoices;
    if (invoices.isEmpty) return const Center(child: Text('No invoices', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: invoices.length,
      itemBuilder: (_, i) {
        final inv = invoices[i] as Map<String, dynamic>;
        final number = inv['invoice_number'] as String? ?? '#${inv['id'] ?? ''}';
        final customer = inv['customer_name'] as String? ?? '—';
        final total = toDoubleOr(inv['total_amount']);
        final paid = toDoubleOr(inv['paid_amount']);
        final balance = total - paid;
        final status = inv['status'] as String? ?? 'pending';
        final date = inv['issue_date'] as String? ?? inv['created_at'] as String?;
        final statusColor = _statusColor(status);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt_outlined, size: 16, color: statusColor)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), Text(customer, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Total: $_currencySymbol${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Text('Balance: $_currencySymbol${balance.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: balance > 0 ? DomendraTheme.danger : DomendraTheme.success)),
              ]),
              if (date != null) ...[const SizedBox(height: 2), Row(children: [const Icon(Icons.calendar_today, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Text(_fmtDate(date), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))])],
            ],
          ),
        );
      },
    );
  }
}

class _StatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InvoicesProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _StatTile(label: 'Total Invoices', value: '${p.total}', color: DomendraTheme.primary, icon: Icons.receipt_long),
        _StatTile(label: 'Total Amount', value: '$_currencySymbol${p.totalAmount.toStringAsFixed(0)}', color: const Color(0xFF3B82F6), icon: Icons.payments),
        _StatTile(label: 'Total Paid', value: '$_currencySymbol${p.totalPaid.toStringAsFixed(0)}', color: const Color(0xFF10B981), icon: Icons.check_circle),
        _StatTile(label: 'Outstanding', value: '$_currencySymbol${p.totalOutstanding.toStringAsFixed(0)}', color: DomendraTheme.danger, icon: Icons.error_outline),
        _StatTile(label: 'Pending Count', value: '${p.pendingCount}', color: const Color(0xFFF59E0B), icon: Icons.pending),
        _StatTile(label: 'Paid Count', value: '${p.paidCount}', color: const Color(0xFF10B981), icon: Icons.check_circle),
        _StatTile(label: 'Overdue Count', value: '${p.overdueCount}', color: DomendraTheme.danger, icon: Icons.warning),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatTile({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.15))),
    child: Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)), const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))]),
  );
}

Color _statusColor(String s) => switch (s) {
  'draft' || 'pending' => const Color(0xFFF59E0B),
  'paid' || 'settled' => const Color(0xFF10B981),
  'overdue' || 'unpaid' => const Color(0xFFEF4444),
  'partial' => const Color(0xFF3B82F6),
  'cancelled' || 'void' => const Color(0xFF94A3B8),
  _ => const Color(0xFF94A3B8),
};

String _fmtDate(String d) {
  try {
    final dt = DateTime.parse(d);
    return '${dt.month}/${dt.day}/${dt.year}';
  } catch (_) { return d; }
}

String _fmtShort(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
