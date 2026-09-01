import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/data_providers.dart';
import '../providers/dashboard_provider.dart';
import '../utils/num_cast.dart';
import '../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

/// Car Hire & Rental screen — mirrors web `pages/app/rentals/index.vue`.
/// 5 tabs: Dashboard, Agreements, Payments, Customers, Pricing.
class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});
  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Dashboard'),
    Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Agreements'),
    Tab(icon: Icon(Icons.payments_outlined, size: 18), text: 'Payments'),
    Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Customers'),
    Tab(icon: Icon(Icons.price_change_outlined, size: 18), text: 'Pricing'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<RentalsProvider>().refresh();
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
        title: const Text('Car Hire & Rental'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => context.read<RentalsProvider>().refresh())],
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
      drawer: const AppDrawer(currentRoute: '/rentals'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(),
          _AgreementsTab(),
          _PaymentsTab(),
          _CustomersTab(),
          _PricingTab(),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1: DASHBOARD
// ════════════════════════════════════════════════════════════
class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RentalsProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        Row(children: [
          Expanded(child: _KpiCard(
            label: 'Total Agreements',
            value: '${p.totalAgreements}',
            subtitle: '${p.activeCount} active · ${p.overdueCount} overdue · ${p.completedCount} completed',
            gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
            icon: Icons.description_outlined,
          )),
          const SizedBox(width: 4),
          Expanded(child: _KpiCard(
            label: 'Active',
            value: '${p.activeCount}',
            subtitle: 'On rent now',
            gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
            icon: Icons.directions_car,
          )),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: _KpiCard(
            label: 'Customers',
            value: '${p.customersCount}',
            subtitle: '${p.localCount} local · ${p.foreignerCount} foreigner',
            gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            icon: Icons.people_outline,
          )),
          const SizedBox(width: 4),
          Expanded(child: _KpiCard(
            label: 'Revenue',
            value: '$_currencySymbol${_fmtShort(p.totalRevenue)}',
            subtitle: 'All-time total billed',
            gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
            icon: Icons.payments,
          )),
        ]),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Agreement Status', icon: Icons.donut_small),
        _StatusBreakdown(p),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Payment Summary', icon: Icons.account_balance_wallet),
        _PaymentSummaryCard(p),
      ],
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final RentalsProvider p;
  const _StatusBreakdown(this.p);

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('Draft', p.draftAgreements.length, const Color(0xFF94A3B8)),
      ('Active', p.activeAgreements.length, const Color(0xFF10B981)),
      ('Overdue', p.overdueAgreements.length, const Color(0xFFEF4444)),
      ('Completed', p.completedAgreements.length, const Color(0xFF3B82F6)),
      ('Cancelled', p.cancelledAgreements.length, const Color(0xFF94A3B8)),
    ];
    final total = statuses.fold<int>(0, (s, e) => s + e.$2);
    return Card(
      elevation: 0,
      color: DomendraTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: DomendraTheme.outline)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: statuses.map((s) {
          final pct = total > 0 ? (s.$2 / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: s.$3),
              const SizedBox(width: 8),
              Expanded(child: Text(s.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
              Text('${s.$2}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.$3)),
              const SizedBox(width: 8),
              SizedBox(width: 60, child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct / 100, color: s.$3, backgroundColor: s.$3.withOpacity(0.1), minHeight: 6),
              )),
            ]),
          );
        }).toList()),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final RentalsProvider p;
  const _PaymentSummaryCard(this.p);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: DomendraTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: DomendraTheme.outline)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _SummaryRow(label: 'Collected', value: '$_currencySymbol${_fmtShort(p.totalCollected)}', color: const Color(0xFF10B981)),
          const Divider(height: 16),
          _SummaryRow(label: 'Outstanding', value: '$_currencySymbol${_fmtShort(p.totalOutstanding)}', color: const Color(0xFFEF4444)),
          const Divider(height: 16),
          _SummaryRow(label: 'Invoiced', value: '$_currencySymbol${_fmtShort(p.totalInvoices)}', color: const Color(0xFFF59E0B)),
          const Divider(height: 16),
          _SummaryRow(label: 'Collection Rate', value: '${p.collectionRate}%', color: DomendraTheme.primary),
          const Divider(height: 16),
          _SummaryRow(label: 'Payment Count', value: '${p.paymentCount}', color: const Color(0xFF64748B)),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted))),
    Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _KpiCard extends StatelessWidget {
  final String label, value, subtitle;
  final List<Color> gradient;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, required this.subtitle, required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 6), Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 2),
      Text(subtitle, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.85)), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(icon, size: 14, color: DomendraTheme.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.primary))]),
  );
}

// ════════════════════════════════════════════════════════════
// TAB 2: AGREEMENTS (list + board + search + filters)
// ════════════════════════════════════════════════════════════
class _AgreementsTab extends StatefulWidget {
  @override
  State<_AgreementsTab> createState() => _AgreementsTabState();
}

class _AgreementsTabState extends State<_AgreementsTab> {
  final _search = TextEditingController();
  String? _statusFilter;
  bool _boardView = false;

  static const _statusOptions = ['All', 'draft', 'active', 'overdue', 'completed', 'cancelled'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<dynamic> _filteredList(RentalsProvider p) {
    final q = _search.text.trim().toLowerCase();
    var list = p.agreements;
    if (q.isNotEmpty) {
      list = list.where((a) {
        final m = a as Map<String, dynamic>;
        return (m['agreement_no'] as String? ?? '').toLowerCase().contains(q) ||
            (m['customer_name'] as String? ?? '').toLowerCase().contains(q) ||
            (m['vehicle_display'] as String? ?? m['vehicle_label'] as String? ?? '').toLowerCase().contains(q) ||
            (m['vehicle_license_plate'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }
    if (_statusFilter != null && _statusFilter != 'All') {
      list = list.where((a) => p.effectiveStatus(a as Map<String, dynamic>) == _statusFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RentalsProvider>();
    final filtered = _filteredList(p);
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        color: DomendraTheme.surface,
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search agreements, customer, vehicle…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DomendraTheme.outline)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              onChanged: (_) => setState(() {}),
            )),
            IconButton(
              icon: Icon(_boardView ? Icons.view_list : Icons.view_kanban, size: 20),
              onPressed: () => setState(() => _boardView = !_boardView),
            ),
          ]),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ..._statusOptions.map((s) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                  label: Text(s),
                  selected: _statusFilter == s || (s == 'All' && _statusFilter == null),
                  onSelected: (v) => setState(() => _statusFilter = v ? (s == 'All' ? null : s) : null),
                  labelStyle: TextStyle(fontSize: 10, color: (_statusFilter == s || (s == 'All' && _statusFilter == null)) ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                  selectedColor: DomendraTheme.primary,
                  backgroundColor: DomendraTheme.surfaceVariant,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )),
            ]),
          ),
        ]),
      ),
      Expanded(child: _boardView ? _AgreementBoard(p) : _AgreementList(filtered)),
    ]);
  }
}

class _AgreementList extends StatelessWidget {
  final List<dynamic> agreements;
  const _AgreementList(this.agreements);

  @override
  Widget build(BuildContext context) {
    if (agreements.isEmpty) return const Center(child: Text('No rental agreements found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: agreements.length,
      itemBuilder: (_, i) => _AgreementCard(agreement: agreements[i] as Map<String, dynamic>),
    );
  }
}

class _AgreementBoard extends StatelessWidget {
  final RentalsProvider p;
  const _AgreementBoard(this.p);

  @override
  Widget build(BuildContext context) {
    final columns = [
      ('Draft', p.draftAgreements, const Color(0xFF94A3B8)),
      ('Active', p.activeAgreements, const Color(0xFF10B981)),
      ('Overdue', p.overdueAgreements, const Color(0xFFEF4444)),
      ('Completed', p.completedAgreements, const Color(0xFF3B82F6)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: columns.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(color: c.$3.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.$3.withOpacity(0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: c.$3.withOpacity(0.08), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
              child: Row(children: [Icon(Icons.circle, size: 8, color: c.$3), const SizedBox(width: 8), Text(c.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.$3)), const Spacer(), Text('${c.$2.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.$3))]),
            ),
            if (c.$2.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No agreements', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)))
            else ...c.$2.map((a) => _AgreementCard(agreement: a as Map<String, dynamic>)),
          ]),
        ),
      )).toList(),
    );
  }
}

class _AgreementCard extends StatelessWidget {
  final Map<String, dynamic> agreement;
  const _AgreementCard({required this.agreement});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RentalsProvider>();
    final agNo = agreement['agreement_no'] as String? ?? '';
    final customerRaw = agreement['customer'];
    final vehicleRaw = agreement['vehicle'];
    final customerName = agreement['customer_name'] as String? ??
        (customerRaw is Map ? (customerRaw['full_name'] as String? ?? customerRaw['name'] as String? ?? '') : '');
    final vehicle = agreement['vehicle_display'] as String? ??
        agreement['vehicle_label'] as String? ??
        (vehicleRaw is Map ? (vehicleRaw['label'] as String? ?? vehicleRaw['license_plate'] as String? ?? '') : '');
    final licensePlate = agreement['vehicle_license_plate'] as String? ?? '';
    final status = p.effectiveStatus(agreement);
    final totalAmount = toDoubleOr(agreement['total_amount']) == 0
        ? toDoubleOr(agreement['grand_total'])
        : toDoubleOr(agreement['total_amount']);
    final payStatus = agreement['payment_status'] as String? ?? 'unpaid';
    final amountPaid = toDoubleOr(agreement['amount_paid']);
    final statusColor = _statusColor(status);
    final payColor = _payStatusColor(payStatus);
    final countdown = _countdownText(agreement, status);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.car_rental, size: 16, color: statusColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(agNo.isNotEmpty ? agNo : 'Agreement #${agreement['id'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            if (customerName.isNotEmpty) Text(customerName, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vehicle.isEmpty ? 'No vehicle' : vehicle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (licensePlate.isNotEmpty) Text(licensePlate, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$_currencySymbol${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DomendraTheme.primary)),
            Text('Paid: $_currencySymbol${amountPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
          ]),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: payColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(payStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: payColor))),
          const Spacer(),
          if (countdown.isNotEmpty) Text(countdown, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _countdownColor(agreement, status))),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (status == 'active' || status == 'overdue') TextButton.icon(onPressed: () async => p.completeAgreement(toIntOr(agreement['id'])), icon: const Icon(Icons.key, size: 14), label: const Text('Return', style: TextStyle(fontSize: 11))),
          if (status != 'draft' && status != 'cancelled') TextButton.icon(onPressed: () => _showPaymentDialog(context, agreement), icon: const Icon(Icons.payments, size: 14), label: const Text('Payment', style: TextStyle(fontSize: 11))),
          if (status == 'draft') TextButton.icon(onPressed: () async => p.activateAgreement(toIntOr(agreement['id'])), icon: const Icon(Icons.play_arrow, size: 14), label: const Text('Activate', style: TextStyle(fontSize: 11))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 0),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'invoice', child: Row(children: [Icon(Icons.receipt, size: 14), SizedBox(width: 8), Text('Generate Invoice', style: TextStyle(fontSize: 12))])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 14, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red))])),
            ],
            onSelected: (val) {
              final id = toIntOr(agreement['id']);
              if (val == 'delete') p.deleteAgreement(id);
              if (val == 'invoice') p.generateInvoiceFromAgreement(id);
            },
          ),
        ]),
      ]),
    );
  }
}

void _showPaymentDialog(BuildContext context, Map<String, dynamic> agreement) {
  showDialog(context: context, builder: (_) => _PaymentDialog(agreement: agreement));
}

// ════════════════════════════════════════════════════════════
// TAB 3: PAYMENTS
// ════════════════════════════════════════════════════════════
class _PaymentsTab extends StatefulWidget {
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<dynamic> _filteredList(RentalsProvider p) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return p.payments;
    return p.payments.where((pay) {
      final m = pay as Map<String, dynamic>;
      return (m['agreement_no'] as String? ?? '').toLowerCase().contains(q) ||
          (m['customer_name'] as String? ?? '').toLowerCase().contains(q) ||
          (m['reference'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RentalsProvider>();
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        color: DomendraTheme.surface,
        child: Row(children: [
          Expanded(child: _PayMini(label: 'Collected', value: '$_currencySymbol${_fmtShort(p.totalCollected)}', color: const Color(0xFF10B981), icon: Icons.payments)),
          const SizedBox(width: 4),
          Expanded(child: _PayMini(label: 'Outstanding', value: '$_currencySymbol${_fmtShort(p.totalOutstanding)}', color: const Color(0xFFEF4444), icon: Icons.money_off)),
          const SizedBox(width: 4),
          Expanded(child: _PayMini(label: 'Rate', value: '${p.collectionRate}%', color: DomendraTheme.primary, icon: Icons.donut_small)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        color: DomendraTheme.surface,
        child: Row(children: [
          Expanded(child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search payments…',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DomendraTheme.outline)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onChanged: (_) => setState(() {}),
          )),
          TextButton.icon(onPressed: () => showDialog(context: context, builder: (_) => const _PaymentDialog()), icon: const Icon(Icons.add, size: 16), label: const Text('Record', style: TextStyle(fontSize: 12))),
        ]),
      ),
      Expanded(child: _PaymentsList(payments: _filteredList(p))),
    ]);
  }
}

class _PayMini extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _PayMini({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1))]), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)]),
  );
}

class _PaymentsList extends StatelessWidget {
  final List<dynamic> payments;
  const _PaymentsList({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const Center(child: Text('No payments recorded', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    final p = context.read<RentalsProvider>();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: payments.length,
      itemBuilder: (_, i) {
        final pay = payments[i] as Map<String, dynamic>;
        final agNo = pay['agreement_no'] as String? ?? '—';
        final customer = pay['customer_name'] as String? ?? '—';
        final amount = toDoubleOr(pay['amount']);
        final method = pay['payment_method'] as String? ?? 'other';
        final reference = pay['reference'] as String? ?? '';
        final status = pay['status'] as String? ?? 'pending';
        final paidAt = pay['paid_at'] as String?;
        final statusColor = _payStatusChipColor(status);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.payments, size: 16, color: const Color(0xFF10B981))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(agNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), Text(customer, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$_currencySymbol${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF10B981))), if (paidAt != null) Text(_fmtDate(paidAt), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted))]),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _methodColor(method).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(_methodLabel(method), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _methodColor(method)))),
              if (reference.isNotEmpty) ...[const SizedBox(width: 6), Expanded(child: Text('Ref: $reference', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))],
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor))),
              IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 0), onPressed: () async => p.deletePayment(toIntOr(pay['id']))),
            ]),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 4: CUSTOMERS
// ════════════════════════════════════════════════════════════
class _CustomersTab extends StatefulWidget {
  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<dynamic> _filteredList(RentalsProvider p) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return p.customers;
    return p.customers.where((c) {
      final m = c as Map<String, dynamic>;
      return (m['full_name'] as String? ?? '').toLowerCase().contains(q) ||
          (m['email'] as String? ?? '').toLowerCase().contains(q) ||
          (m['phone'] as String? ?? '').toLowerCase().contains(q) ||
          (m['id_number'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RentalsProvider>();
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        color: DomendraTheme.surface,
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search customers…',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DomendraTheme.outline)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      Expanded(child: _CustomerList(customers: _filteredList(p))),
    ]);
  }
}

class _CustomerList extends StatelessWidget {
  final List<dynamic> customers;
  const _CustomerList({required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) return const Center(child: Text('No customers found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    final p = context.read<RentalsProvider>();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: customers.length,
      itemBuilder: (_, i) {
        final c = customers[i] as Map<String, dynamic>;
        final name = c['full_name'] as String? ?? 'Unknown';
        final type = c['customer_type'] as String? ?? 'local';
        final phone = c['phone'] as String? ?? '';
        final email = c['email'] as String? ?? '';
        final idType = c['id_type'] as String? ?? '';
        final idNumber = c['id_number'] as String? ?? '';
        final typeColor = type == 'foreigner' ? const Color(0xFF3B82F6) : const Color(0xFF10B981);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, size: 16, color: typeColor)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)), child: Text(type, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: typeColor))),
              ])),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () async => p.deleteCustomer(toIntOr(c['id']))),
            ]),
            if (phone.isNotEmpty) Row(children: [const Icon(Icons.phone, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Text(phone, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))]),
            if (email.isNotEmpty) Row(children: [const Icon(Icons.email, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(email, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))]),
            if (idNumber.isNotEmpty) Row(children: [const Icon(Icons.badge, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Text('$idType: $idNumber', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)]),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 5: PRICING
// ════════════════════════════════════════════════════════════
class _PricingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RentalsProvider>();
    final plans = p.pricing;
    if (plans.isEmpty) return const Center(child: Text('No pricing plans found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: plans.length,
      itemBuilder: (_, i) {
        final plan = plans[i] as Map<String, dynamic>;
        final name = plan['name'] as String? ?? 'Plan';
        final desc = plan['description'] as String? ?? '';
        final isActive = plan['is_active'] as bool? ?? true;
        final applyTo = plan['apply_to'] as String? ?? 'group';
        final vehicleTypeName = plan['vehicle_type_name'] as String? ?? 'All Types';
        final daily = toDoubleOr(plan['daily_rate']);
        final weekly = toDoubleOr(plan['weekly_rate']);
        final weekend = toDoubleOr(plan['weekend_rate']);
        final monthly = toDoubleOr(plan['monthly_rate']);
        final dailyDisc = toDoubleOr(plan['daily_discount_percent']);
        final weeklyDisc = toDoubleOr(plan['weekly_discount_percent']);
        final vehicleCount = plan['vehicle_list'] != null ? (plan['vehicle_list'] as List).length : 0;
        final applyLabel = applyTo == 'group' ? vehicleTypeName : '$vehicleCount vehicle(s)';
        final applyColor = applyTo == 'group' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: applyColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(applyTo == 'group' ? Icons.category : Icons.directions_car, size: 16, color: applyColor)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), if (desc.isNotEmpty) Text(desc, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)))),
            ]),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: applyColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(applyLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: applyColor))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _RateChip(label: 'Daily', value: '$_currencySymbol${daily.toStringAsFixed(0)}', discount: dailyDisc, color: const Color(0xFF3B82F6))),
              const SizedBox(width: 4),
              Expanded(child: _RateChip(label: 'Wkly', value: '$_currencySymbol${weekly.toStringAsFixed(0)}', discount: weeklyDisc, color: const Color(0xFFF59E0B))),
              const SizedBox(width: 4),
              Expanded(child: _RateChip(label: 'Wknd', value: '$_currencySymbol${weekend.toStringAsFixed(0)}', color: DomendraTheme.primary)),
              const SizedBox(width: 4),
              Expanded(child: _RateChip(label: 'Mnth', value: '$_currencySymbol${monthly.toStringAsFixed(0)}', color: const Color(0xFF10B981))),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () async => p.deletePricing(toIntOr(plan['id']))),
            ]),
          ]),
        );
      },
    );
  }
}

class _RateChip extends StatelessWidget {
  final String label, value;
  final double discount;
  final Color color;
  const _RateChip({required this.label, required this.value, this.discount = 0, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.15))),
    child: Column(children: [Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color)), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis), if (discount > 0) Text('-${discount.toStringAsFixed(0)}%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)))]),
  );
}

// ════════════════════════════════════════════════════════════
// PAYMENT DIALOG
// ════════════════════════════════════════════════════════════
class _PaymentDialog extends StatefulWidget {
  final Map<String, dynamic>? agreement;
  const _PaymentDialog({this.agreement});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  String _method = 'cash';
  String _status = 'completed';

  static const _methods = ['cash', 'mpesa', 'card', 'bank_transfer', 'cheque', 'other'];
  static const _statuses = ['completed', 'pending', 'failed'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<RentalsProvider>();
    final balance = widget.agreement != null
        ? toDoubleOr(widget.agreement!['total_amount']) - toDoubleOr(widget.agreement!['amount_paid'])
        : 0.0;
    if (_amountCtrl.text.isEmpty && balance > 0) _amountCtrl.text = balance.toStringAsFixed(0);

    return AlertDialog(
      title: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.agreement != null) ...[
            Text(widget.agreement!['agreement_no'] as String? ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.primary)),
            Text('Balance: $_currencySymbol${balance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount', prefixText: '$_currencySymbol ', border: const OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _method,
            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder(), isDense: true),
            items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(_methodLabel(m)))).toList(),
            onChanged: (v) => setState(() => _method = v ?? 'cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(labelText: 'Reference (optional)', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true),
            items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _status = v ?? 'completed'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(_amountCtrl.text) ?? 0;
            if (amount <= 0) return;
            final data = <String, dynamic>{
              'amount': amount,
              'payment_method': _method,
              'reference': _referenceCtrl.text,
              'status': _status,
            };
            if (widget.agreement != null) data['agreement'] = toIntOr(widget.agreement!['id']);
            await p.recordPayment(data);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
Color _statusColor(String s) => switch (s) {
  'draft' => const Color(0xFF94A3B8),
  'active' => const Color(0xFF10B981),
  'overdue' => const Color(0xFFEF4444),
  'completed' => const Color(0xFF3B82F6),
  'cancelled' => const Color(0xFF94A3B8),
  _ => const Color(0xFF94A3B8),
};

Color _payStatusColor(String s) => switch (s) {
  'paid' => const Color(0xFF10B981),
  'partial' => const Color(0xFFF59E0B),
  'unpaid' => const Color(0xFFEF4444),
  _ => const Color(0xFF94A3B8),
};

Color _payStatusChipColor(String s) => switch (s) {
  'completed' || 'paid' || 'success' => const Color(0xFF10B981),
  'pending' => const Color(0xFFF59E0B),
  'failed' => const Color(0xFFEF4444),
  'refunded' => const Color(0xFF3B82F6),
  _ => const Color(0xFF94A3B8),
};

Color _methodColor(String m) => switch (m) {
  'mpesa' => const Color(0xFF10B981),
  'cash' => const Color(0xFFF59E0B),
  'card' => const Color(0xFF3B82F6),
  'bank_transfer' => DomendraTheme.primary,
  'cheque' => const Color(0xFF8B5CF6),
  _ => const Color(0xFF94A3B8),
};

String _methodLabel(String m) => switch (m) {
  'mpesa' => 'M-Pesa',
  'cash' => 'Cash',
  'card' => 'Card',
  'bank_transfer' => 'Bank Transfer',
  'cheque' => 'Cheque',
  _ => 'Other',
};

String _countdownText(Map<String, dynamic> a, String status) {
  if (status == 'cancelled' || status == 'draft') return '';
  final endStr = a['end_datetime'] as String?;
  if (endStr == null) return '';
  try {
    final end = DateTime.parse(endStr);
    if (status == 'completed') {
      final startStr = a['start_datetime'] as String?;
      if (startStr == null) return '';
      final start = DateTime.parse(startStr);
      final diff = end.difference(start);
      final days = diff.inDays;
      final hrs = diff.inHours % 24;
      return days > 0 ? '${days}d ${hrs}h' : '${hrs}h';
    }
    final diff = end.difference(DateTime.now());
    final abs = diff.isNegative ? -diff : diff;
    final days = abs.inDays;
    final hrs = abs.inHours % 24;
    final mins = abs.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hrs > 0 || days > 0) parts.add('${hrs}h');
    if (days == 0) parts.add('${mins}m');
    final label = parts.join(' ');
    return diff.isNegative ? '$label over' : '$label left';
  } catch (_) { return ''; }
}

Color _countdownColor(Map<String, dynamic> a, String status) {
  if (status == 'completed') return const Color(0xFF3B82F6);
  final endStr = a['end_datetime'] as String?;
  if (endStr == null) return const Color(0xFF94A3B8);
  try {
    final diff = DateTime.parse(endStr).difference(DateTime.now());
    if (diff.isNegative) return const Color(0xFFEF4444);
    if (diff.inHours <= 6) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  } catch (_) { return const Color(0xFF94A3B8); }
}

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
