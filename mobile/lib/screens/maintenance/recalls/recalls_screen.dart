import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/recalls_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'recalls_dialogs.dart';

class RecallsScreen extends StatefulWidget {
  const RecallsScreen({super.key});
  @override
  State<RecallsScreen> createState() => _RecallsScreenState();
}

class _RecallsScreenState extends State<RecallsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.view_kanban, size: 18), text: 'Board'),
    Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Records'),
    Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecallsProvider>().init();
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
        title: const Text('Recalls'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<RecallsProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/recalls'),
      body: TabBarView(
        controller: _tabController,
        children: [_BoardTab(), _RecordsTab(), _TimelineTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_recall',
        onPressed: () => showRecallFormDialog(context, null),
        backgroundColor: DomendraTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BOARD TAB
// ════════════════════════════════════════════════════════════
class _BoardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RecallsProvider>();
    if (p.loading && p.recalls.isEmpty) return const Center(child: CircularProgressIndicator());

    final groups = <String, List<Recall>>{};
    for (final r in p.recalls) {
      groups.putIfAbsent(r.status, () => []).add(r);
    }
    final statuses = ['open', 'in_progress', 'completed', 'closed'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(children: [
          Expanded(child: _KpiCard('Total', '${p.totalRecalls}', Icons.campaign, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Open', '${p.totalOpen}', Icons.flag, const [Color(0xFFef4444), Color(0xFFf87171)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Critical', '${p.totalCritical}', Icons.priority_high, const [Color(0xFFdc2626), Color(0xFFf87171)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('Affected', '${p.totalAffected}', Icons.car_repair, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Resolved', '${p.totalResolved}', Icons.task_alt, const [Color(0xFF10b981), Color(0xFF34d399)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('In Progress', '${p.totalInProgress}', Icons.engineering, const [Color(0xFF3b82f6), Color(0xFF60a5fa)])),
        ]),
        const SizedBox(height: 16),
        ...statuses.where((s) => groups.containsKey(s) && groups[s]!.isNotEmpty).map((status) {
          final items = groups[status]!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${_statusLabel(status)} (${items.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            ...items.map((r) => _RecallCard(recall: r)),
            const SizedBox(height: 14),
          ]);
        }),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// RECORDS TAB
// ════════════════════════════════════════════════════════════
class _RecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RecallsProvider>();
    if (p.loading && p.recalls.isEmpty) return const Center(child: CircularProgressIndicator());

    final list = p.filteredRecalls;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search recalls...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true, fillColor: DomendraTheme.surface, isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
          ),
          onChanged: p.setSearch,
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          _buildFilterBtn(context, 'Status', p.statusFilter, _statusOptions, p.setStatusFilter),
          _buildFilterBtn(context, 'Type', p.typeFilter, _typeOptions, p.setTypeFilter),
          ActionChip(
            label: Text(p.criticalOnly == null ? 'All' : (p.criticalOnly! ? 'Critical Only' : 'Non-Critical')),
            backgroundColor: DomendraTheme.surface,
            side: BorderSide(color: p.criticalOnly != null ? Colors.red : DomendraTheme.outline),
            onPressed: () => _showCriticalDialog(context, p),
          ),
        ]),
        const SizedBox(height: 12),
        Text('${list.length} recall${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty) _EmptyState(icon: Icons.campaign, message: 'No recalls found. Tap + to add one.')
        else ...list.map((r) => _RecallCard(recall: r)),
      ],
    );
  }

  Widget _buildFilterBtn(BuildContext context, String label, String? current, List<String> options, void Function(String?) onSelected) {
    return ActionChip(
      label: Text(current != null ? '$label: $current' : label),
      backgroundColor: DomendraTheme.surface,
      side: BorderSide(color: current != null ? DomendraTheme.primary : DomendraTheme.outline),
      onPressed: () => _showFilterDialog(context, label, current, options, onSelected),
    );
  }

  void _showFilterDialog(BuildContext context, String title, String? current, List<String> options, void Function(String?) onSelected) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Filter by $title'),
      content: SizedBox(width: 200, child: ListView.builder(shrinkWrap: true, itemCount: options.length + 1, itemBuilder: (_, i) {
        if (i == 0) return ListTile(title: const Text('All'), trailing: current == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { onSelected(null); Navigator.pop(ctx); });
        final opt = options[i - 1];
        return ListTile(title: Text(opt), trailing: current == opt ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { onSelected(opt); Navigator.pop(ctx); });
      })),
    ));
  }

  void _showCriticalDialog(BuildContext context, RecallsProvider p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Filter by Criticality'),
      content: SizedBox(width: 200, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text('All'), trailing: p.criticalOnly == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setCriticalOnly(null); Navigator.pop(ctx); }),
        ListTile(title: const Text('Critical Only'), trailing: p.criticalOnly == true ? const Icon(Icons.check, color: Colors.red) : null, onTap: () { p.setCriticalOnly(true); Navigator.pop(ctx); }),
        ListTile(title: const Text('Non-Critical'), trailing: p.criticalOnly == false ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setCriticalOnly(false); Navigator.pop(ctx); }),
      ])),
    ));
  }
}

// ════════════════════════════════════════════════════════════
// TIMELINE TAB
// ════════════════════════════════════════════════════════════
class _TimelineTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RecallsProvider>();
    if (p.loading && p.recalls.isEmpty) return const Center(child: CircularProgressIndicator());
    final sorted = List<Recall>.from(p.recalls)..sort((a, b) {
      final ad = a.issueDate; final bd = b.issueDate;
      if (ad == null && bd == null) return 0; if (ad == null) return 1; if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    if (sorted.isEmpty) return _EmptyState(icon: Icons.timeline, message: 'No recalls yet');
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: List.generate(sorted.length, (i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: sorted[i].isCritical ? Colors.red : _statusColor(sorted[i].status), shape: BoxShape.circle), child: const Icon(Icons.campaign, color: Colors.white, size: 14)),
          if (i < sorted.length - 1) Container(width: 2, height: 40, color: DomendraTheme.outline),
        ]),
        const SizedBox(width: 10),
        Expanded(child: _RecallCard(recall: sorted[i])),
      ])),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════

class _RecallCard extends StatelessWidget {
  final Recall recall;
  const _RecallCard({required this.recall});
  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(recall.status);
    final typeColor = _typeColor(recall.recallType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: recall.isCritical ? Colors.red.withOpacity(0.3) : DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.campaign, size: 20, color: typeColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(recall.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: recall.isCritical ? Colors.red : null), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(recall.oem.isEmpty ? recall.recallTypeLabel : '${recall.oem} · ${recall.recallTypeLabel}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showRecallDetailDialog(context, recall); break;
                case 'edit': showRecallFormDialog(context, recall); break;
                case 'auto': context.read<RecallsProvider>().autoMatchRecall(recall.id!); break;
                case 'delete': _confirmDelete(context, recall); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'auto', child: Row(children: [Icon(Icons.auto_fix_high, size: 18), SizedBox(width: 8), Text('Auto-Match')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
        if (recall.component.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Component: ${recall.component}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(recall.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(recall.recallTypeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor))),
          if (recall.isCritical) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Text('CRITICAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red))),
          if (recall.affectedCount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)), child: Text('${recall.affectedCount} affected · ${recall.resolvedCount} resolved', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted))),
        ]),
        if (recall.issueDate != null) ...[
          const SizedBox(height: 6),
          Text('Issued: ${_fmtDate(recall.issueDate!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
      ]),
    );
  }
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

void _confirmDelete(BuildContext context, Recall r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Recall'),
    content: Text('Delete recall "${r.title}"?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<RecallsProvider>().deleteRecall(r.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

const _statusOptions = ['open', 'in_progress', 'completed', 'closed'];
const _typeOptions = ['safety_recall', 'campaign', 'field_notice', 'emission'];

String _statusLabel(String s) {
  const m = {'open': 'Open', 'in_progress': 'In Progress', 'completed': 'Completed', 'closed': 'Closed'};
  return m[s] ?? s;
}

Color _statusColor(String s) {
  switch (s) {
    case 'open': return const Color(0xFFef4444);
    case 'in_progress': return const Color(0xFF3b82f6);
    case 'completed': return const Color(0xFF10b981);
    case 'closed': return const Color(0xFF6b7280);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

Color _typeColor(String t) {
  switch (t) {
    case 'safety_recall': return const Color(0xFFef4444);
    case 'campaign': return const Color(0xFF3b82f6);
    case 'field_notice': return const Color(0xFFf59e0b);
    case 'emission': return const Color(0xFF10b981);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
