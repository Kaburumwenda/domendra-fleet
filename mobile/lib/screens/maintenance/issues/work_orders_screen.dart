import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/issues_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'work_orders_dialogs.dart';

String _currencySymbol = 'KSh';

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});
  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.assignment, size: 18), text: 'Records'),
    Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<IssuesProvider>().init();
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
        title: const Text('Work Orders'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<IssuesProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/work-orders'),
      body: TabBarView(
        controller: _tabController,
        children: [_RecordsTab(), _TimelineTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_wo',
        onPressed: () => showWorkOrderFormDialog(context, null),
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
    final p = context.watch<IssuesProvider>();
    if (p.loadingWO && p.workOrders.isEmpty) return const Center(child: CircularProgressIndicator());

    final list = p.workOrders;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(children: [
          Expanded(child: _KpiCard('Total', '${p.woTotal}', Icons.assignment, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Active', '${p.woActive}', Icons.engineering, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Completed', '${p.woCompleted}', Icons.task_alt, const [Color(0xFF10b981), Color(0xFF34d399)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('Total Cost', '$_currencySymbol${p.woTotalCost.toStringAsFixed(0)}', Icons.attach_money, const [Color(0xFF8b5cf6), Color(0xFFa78bfa)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Downtime', '${p.woTotalDowntime.toStringAsFixed(1)}h', Icons.access_time, const [Color(0xFF3b82f6), Color(0xFF60a5fa)])),
        ]),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _EmptyState(icon: Icons.assignment, message: 'No work orders found. Tap + to create one.')
        else
          ...list.map((w) => _WorkOrderCard(wo: w)),
      ],
    );
  }
}

class _TimelineTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IssuesProvider>();
    if (p.loadingWO && p.workOrders.isEmpty) return const Center(child: CircularProgressIndicator());
    final sorted = List<WorkOrder>.from(p.workOrders)..sort((a, b) {
      final ad = a.createdAt; final bd = b.createdAt;
      if (ad == null && bd == null) return 0; if (ad == null) return 1; if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    if (sorted.isEmpty) return _EmptyState(icon: Icons.timeline, message: 'No work orders yet');
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: List.generate(sorted.length, (i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _woStatusColor(sorted[i].status), shape: BoxShape.circle), child: const Icon(Icons.assignment, color: Colors.white, size: 14)),
          if (i < sorted.length - 1) Container(width: 2, height: 40, color: DomendraTheme.outline),
        ]),
        const SizedBox(width: 10),
        Expanded(child: _WorkOrderCard(wo: sorted[i])),
      ])),
    );
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder wo;
  const _WorkOrderCard({required this.wo});

  @override
  Widget build(BuildContext context) {
    final statusColor = _woStatusColor(wo.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.assignment, size: 20, color: statusColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(wo.issueTitle.isEmpty ? 'Work Order #${wo.id}' : wo.issueTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(wo.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showWorkOrderDetailDialog(context, wo); break;
                case 'edit': showWorkOrderFormDialog(context, wo); break;
                case 'start': context.read<IssuesProvider>().startWorkOrder(wo.id!); break;
                case 'complete': context.read<IssuesProvider>().completeWorkOrder(wo.id!); break;
                case 'delete': _confirmDelete(context, wo); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              if (wo.status == 'assigned' || wo.status == 'open')
                const PopupMenuItem(value: 'start', child: Row(children: [Icon(Icons.play_arrow, size: 18), SizedBox(width: 8), Text('Start Work')])),
              if (wo.status == 'in_progress')
                const PopupMenuItem(value: 'complete', child: Row(children: [Icon(Icons.check, size: 18), SizedBox(width: 8), Text('Complete')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(wo.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(wo.assignmentTypeLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.primary))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _CostPill('Est.', wo.estimatedCost),
          const SizedBox(width: 6),
          _CostPill('Actual', wo.actualCost),
          const SizedBox(width: 6),
          _CostPill('Total', wo.totalCost, highlight: true),
        ]),
        if (wo.assignedToName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Assigned: ${wo.assignedToName}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
      ]),
    );
  }
}

class _CostPill extends StatelessWidget {
  final String label;
  final double value;
  final bool highlight;
  const _CostPill(this.label, this.value, {this.highlight = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: highlight ? DomendraTheme.primary.withOpacity(0.1) : DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
    child: Text('$label: $_currencySymbol${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: highlight ? DomendraTheme.primary : DomendraTheme.onSurfaceMuted)),
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

void _confirmDelete(BuildContext context, WorkOrder wo) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Work Order'),
    content: Text('Delete work order #${wo.id}?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<IssuesProvider>().deleteWorkOrder(wo.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

Color _woStatusColor(String s) {
  switch (s) {
    case 'open': return const Color(0xFF6b7280);
    case 'assigned': return const Color(0xFF3b82f6);
    case 'parts_ordered': return const Color(0xFF8b5cf6);
    case 'in_progress': return const Color(0xFFf59e0b);
    case 'on_hold': return const Color(0xFFf97316);
    case 'completed': return const Color(0xFF10b981);
    case 'closed': return const Color(0xFF059669);
    default: return DomendraTheme.onSurfaceMuted;
  }
}
