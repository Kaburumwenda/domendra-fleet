import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/issues_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'issues_dialogs.dart';

String _currencySymbol = 'KSh';

class IssuesScreen extends StatefulWidget {
  const IssuesScreen({super.key});
  @override
  State<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends State<IssuesScreen>
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
        title: const Text('Issues'),
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
      drawer: const AppDrawer(currentRoute: '/issues'),
      body: TabBarView(
        controller: _tabController,
        children: [_BoardTab(), _RecordsTab(), _TimelineTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_issue',
        onPressed: () => showIssueFormDialog(context, null),
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
    final p = context.watch<IssuesProvider>();
    if (p.loading && p.issues.isEmpty) return const Center(child: CircularProgressIndicator());

    final groups = <String, List<Issue>>{};
    for (final issue in p.issues) {
      groups.putIfAbsent(issue.status, () => []).add(issue);
    }
    final statuses = ['open', 'assigned', 'parts_ordered', 'in_progress', 'resolved', 'closed'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI ROW
        Row(children: [
          Expanded(child: _KpiCard('Total', '${p.totalIssues}', Icons.bug_report, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('In Progress', '${p.totalInProgress}', Icons.engineering, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Resolved', '${p.totalResolved}', Icons.check_circle, const [Color(0xFF10b981), Color(0xFF34d399)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('Work Orders', '${p.totalWorkOrders}', Icons.assignment, const [Color(0xFF8b5cf6), Color(0xFFa78bfa)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Open Issues', '${p.totalOpen}', Icons.flag, const [Color(0xFFef4444), Color(0xFFf87171)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Critical', '${p.totalCritical}', Icons.priority_high, const [Color(0xFFdc2626), Color(0xFFf87171)])),
        ]),
        const SizedBox(height: 16),
        ...statuses.where((s) => groups.containsKey(s) && groups[s]!.isNotEmpty).map((status) {
          final items = groups[status]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${_statusLabel(status)} (${items.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              ...items.map((issue) => _IssueCard(issue: issue)),
              const SizedBox(height: 14),
            ],
          );
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
    final p = context.watch<IssuesProvider>();
    if (p.loading && p.issues.isEmpty) return const Center(child: CircularProgressIndicator());

    final list = p.filteredIssues;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: 'Search issues...',
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
        // Filter chips
        Wrap(
          spacing: 6,
          children: [
            _buildFilterBtn(context, 'Status', p.statusFilter, _statusOptions, p.setStatusFilter),
            _buildFilterBtn(context, 'Priority', p.priorityFilter, _priorityOptions, p.setPriorityFilter),
          ],
        ),
        const SizedBox(height: 12),
        Text('${list.length} issue${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.bug_report, message: 'No issues found. Tap + to report one.')
        else
          ...list.map((i) => _IssueCard(issue: i)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// TIMELINE TAB
// ════════════════════════════════════════════════════════════
class _TimelineTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<IssuesProvider>();
    if (p.loading && p.issues.isEmpty) return const Center(child: CircularProgressIndicator());

    final issues = p.issues;
    final sorted = List<Issue>.from(issues)..sort((a, b) {
      final ad = a.createdAt;
      final bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    if (sorted.isEmpty) return _EmptyState(icon: Icons.timeline, message: 'No issues yet');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: List.generate(sorted.length * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(height: 4);
        final issue = sorted[i ~/ 2];
        return _TimelineItem(issue: issue, isLast: i == sorted.length * 2 - 2);
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════

class _IssueCard extends StatelessWidget {
  final Issue issue;
  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(issue.status);
    final priorityColor = _priorityColor(issue.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: issue.priority == 'critical' ? priorityColor.withOpacity(0.4) : DomendraTheme.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.bug_report, size: 20, color: priorityColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(issue.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(issue.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showIssueDetailDialog(context, issue); break;
                case 'edit': showIssueFormDialog(context, issue); break;
                case 'delete': _confirmDelete(context, issue); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
        if (issue.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(issue.description, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(issue.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: priorityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(issue.priorityLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor))),
          if (issue.hasWorkOrder)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Text('Has Work Order', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.primary))),
        ]),
        if (issue.createdAt != null) ...[
          const SizedBox(height: 6),
          Text('Reported ${_fmtDate(issue.createdAt!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Issue issue;
  final bool isLast;
  const _TimelineItem({required this.issue, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(issue.status);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.bug_report, color: Colors.white, size: 14)),
        if (!isLast) Container(width: 2, height: 40, color: DomendraTheme.outline),
      ]),
      const SizedBox(width: 10),
      Expanded(child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(issue.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(issue.vehicleName, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          if (issue.createdAt != null)
            Text(_fmtDate(issue.createdAt!), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ]),
      )),
    ]);
  }
}

// ── Helpers ──

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<Color> colors;
  const _KpiCard(this.label, this.value, this.icon, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13)),
    ]),
  ));
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
  showDialog(context: context, builder: (ctx) {
    return AlertDialog(
      title: Text('Filter by $title'),
      content: SizedBox(width: 200, child: ListView.builder(shrinkWrap: true, itemCount: options.length + 1, itemBuilder: (_, i) {
        if (i == 0) return ListTile(title: const Text('All'), trailing: current == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null,
          onTap: () { onSelected(null); Navigator.pop(ctx); });
        final opt = options[i - 1];
        return ListTile(title: Text(opt), trailing: current == opt ? const Icon(Icons.check, color: DomendraTheme.primary) : null,
          onTap: () { onSelected(opt); Navigator.pop(ctx); });
      })),
    );
  });
}

void _confirmDelete(BuildContext context, Issue issue) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Issue'),
    content: Text('Are you sure you want to delete "${issue.title}"?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<IssuesProvider>().deleteIssue(issue.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

// ── Option lists ──
const _statusOptions = ['open', 'assigned', 'parts_ordered', 'in_progress', 'resolved', 'closed'];
const _priorityOptions = ['low', 'medium', 'high', 'critical'];

String _statusLabel(String s) {
  const m = {'open': 'Open', 'assigned': 'Assigned', 'parts_ordered': 'Parts Ordered', 'in_progress': 'In Progress', 'resolved': 'Resolved', 'closed': 'Closed'};
  return m[s] ?? s;
}

Color _statusColor(String s) {
  switch (s) {
    case 'open': return const Color(0xFFef4444);
    case 'assigned': return const Color(0xFF3b82f6);
    case 'parts_ordered': return const Color(0xFF8b5cf6);
    case 'in_progress': return const Color(0xFFf59e0b);
    case 'resolved': return const Color(0xFF10b981);
    case 'closed': return const Color(0xFF6b7280);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

Color _priorityColor(String p) {
  switch (p) {
    case 'low': return const Color(0xFF6b7280);
    case 'medium': return const Color(0xFF3b82f6);
    case 'high': return const Color(0xFFf59e0b);
    case 'critical': return const Color(0xFFef4444);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

String _fmtDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
