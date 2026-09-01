import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/services_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'services_dialogs.dart';

String _currencySymbol = 'KSh';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.build, size: 18), text: 'Records'),
    Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline'),
    Tab(icon: Icon(Icons.store, size: 18), text: 'Vendors'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<ServicesProvider>().init();
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
        title: const Text('Services'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<ServicesProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/services'),
      body: TabBarView(
        controller: _tabController,
        children: [_RecordsTab(), _TimelineTab(), _VendorsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_service',
        onPressed: () => showServiceFormDialog(context, null),
        backgroundColor: DomendraTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServicesProvider>();
    if (p.loading && p.services.isEmpty) return const Center(child: CircularProgressIndicator());

    final list = p.filteredServices;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(children: [
          Expanded(child: _KpiCard('Total', '${p.totalServices}', Icons.build, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('This Month', '${p.thisMonthCount}', Icons.calendar_today, const [Color(0xFF3b82f6), Color(0xFF60a5fa)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Total Cost', '$_currencySymbol${p.totalCost.toStringAsFixed(0)}', Icons.attach_money, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('This Month Cost', '$_currencySymbol${p.thisMonthCost.toStringAsFixed(0)}', Icons.trending_up, const [Color(0xFF10b981), Color(0xFF34d399)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Avg Cost', '$_currencySymbol${p.totalServices > 0 ? (p.totalCost / p.totalServices).toStringAsFixed(0) : '0'}', Icons.analytics, const [Color(0xFF8b5cf6), Color(0xFFa78bfa)])),
        ]),
        const SizedBox(height: 16),
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: 'Search services...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: DomendraTheme.surface,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
          ),
          onChanged: p.setSearch,
        ),
        const SizedBox(height: 8),
        // Type filter chips
        Wrap(spacing: 6, children: _buildTypeChips(context, p)),
        const SizedBox(height: 12),
        Text('${list.length} service${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.build, message: 'No services found. Tap + to add one.')
        else
          ...list.map((s) => _ServiceCard(service: s)),
      ],
    );
  }

  List<Widget> _buildTypeChips(BuildContext context, ServicesProvider p) {
    const types = ['oil_change', 'tire_rotation', 'brake_service', 'inspection', 'repair', 'preventive', 'other'];
    return [
      ActionChip(
        label: Text(p.typeFilter == null ? 'All Types' : _typeLabel(p.typeFilter!)),
        backgroundColor: DomendraTheme.surface,
        side: BorderSide(color: p.typeFilter != null ? DomendraTheme.primary : DomendraTheme.outline),
        onPressed: () => _showTypeDialog(context, p),
      ),
    ];
  }

  void _showTypeDialog(BuildContext context, ServicesProvider p) {
    const types = ['oil_change', 'tire_rotation', 'brake_service', 'inspection', 'repair', 'preventive', 'other'];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Filter by Type'),
      content: SizedBox(width: 200, child: ListView.builder(shrinkWrap: true, itemCount: types.length + 1, itemBuilder: (_, i) {
        if (i == 0) return ListTile(title: const Text('All'), trailing: p.typeFilter == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null,
          onTap: () { p.setTypeFilter(null); Navigator.pop(ctx); });
        final t = types[i - 1];
        return ListTile(title: Text(_typeLabel(t)), trailing: p.typeFilter == t ? const Icon(Icons.check, color: DomendraTheme.primary) : null,
          onTap: () { p.setTypeFilter(t); Navigator.pop(ctx); });
      })),
    ));
  }
}

class _TimelineTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServicesProvider>();
    if (p.loading && p.services.isEmpty) return const Center(child: CircularProgressIndicator());
    final sorted = List<Service>.from(p.services)..sort((a, b) {
      final ad = a.performedAt; final bd = b.performedAt;
      if (ad == null && bd == null) return 0; if (ad == null) return 1; if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    if (sorted.isEmpty) return _EmptyState(icon: Icons.timeline, message: 'No services yet');
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: List.generate(sorted.length, (i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _typeColor(sorted[i].serviceType), shape: BoxShape.circle), child: const Icon(Icons.build, color: Colors.white, size: 14)),
          if (i < sorted.length - 1) Container(width: 2, height: 40, color: DomendraTheme.outline),
        ]),
        const SizedBox(width: 10),
        Expanded(child: _ServiceCard(service: sorted[i])),
      ])),
    );
  }
}

class _VendorsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ServicesProvider>();
    if (p.loading && p.services.isEmpty) return const Center(child: CircularProgressIndicator());

    // Build vendor summary from services
    final vendorMap = <String, List<Service>>{};
    for (final s in p.services) {
      final key = s.vendorName.isEmpty ? 'No Vendor' : s.vendorName;
      vendorMap.putIfAbsent(key, () => []).add(s);
    }
    final vendors = vendorMap.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (vendors.isEmpty) return _EmptyState(icon: Icons.store, message: 'No vendor data yet');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: vendors.map((entry) {
        final services = entry.value;
        final avgCost = services.fold(0.0, (s, sv) => s + sv.cost) / services.length;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.store, size: 20, color: DomendraTheme.primary)),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              Text('${services.length} svc', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _Pill('Avg Cost', '$_currencySymbol${avgCost.toStringAsFixed(0)}'),
              const SizedBox(width: 6),
              _Pill('Total', '$_currencySymbol${services.fold(0.0, (s, sv) => s + sv.cost).toStringAsFixed(0)}'),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});
  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(service.serviceType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(_typeIcon(service.serviceType), size: 20, color: typeColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(service.vehicleName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(service.serviceTypeLabel, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showServiceDetailDialog(context, service); break;
                case 'edit': showServiceFormDialog(context, service); break;
                case 'delete': _confirmDelete(context, service); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
        if (service.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(service.description, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(service.serviceTypeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor))),
          if (service.vendorName.isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(service.vendorName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.primary))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)), child: Text('$_currencySymbol${service.cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        if (service.performedAt != null) ...[
          const SizedBox(height: 6),
          Text('Performed: ${_fmtDate(service.performedAt!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label, value;
  const _Pill(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
    child: Text('$label: $value', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted)),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<Color> colors;
  const _KpiCard(this.label, this.value, this.icon, this.colors);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 4), Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted), const SizedBox(height: 12), Text(message, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13))]),
  ));
}

void _confirmDelete(BuildContext context, Service s) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Service'),
    content: Text('Delete service record for ${s.vehicleName}?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<ServicesProvider>().deleteService(s.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

// ── Helpers ──
String _typeLabel(String t) {
  const m = {'oil_change': 'Oil Change', 'tire_rotation': 'Tire Rotation', 'brake_service': 'Brake Service', 'inspection': 'Inspection', 'repair': 'Repair', 'preventive': 'Preventive', 'other': 'Other'};
  return m[t] ?? t;
}

Color _typeColor(String t) {
  switch (t) {
    case 'oil_change': return const Color(0xFFf59e0b);
    case 'tire_rotation': return const Color(0xFF3b82f6);
    case 'brake_service': return const Color(0xFFef4444);
    case 'inspection': return const Color(0xFF10b981);
    case 'repair': return const Color(0xFF8b5cf6);
    case 'preventive': return const Color(0xFF06b6d4);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

IconData _typeIcon(String t) {
  switch (t) {
    case 'oil_change': return Icons.oil_barrel;
    case 'tire_rotation': return Icons.tire_repair;
    case 'brake_service': return Icons.disc_full;
    case 'inspection': return Icons.fact_check;
    case 'repair': return Icons.build_circle;
    case 'preventive': return Icons.shield;
    default: return Icons.build;
  }
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
