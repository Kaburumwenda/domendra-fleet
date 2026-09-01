import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/inspections_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'inspections_dialogs.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});
  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.assignment, size: 18), text: 'Reports'),
    Tab(icon: Icon(Icons.fact_check, size: 18), text: 'Forms'),
    Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionsProvider>().init();
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
        title: const Text('Inspections'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<InspectionsProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/inspections'),
      body: TabBarView(
        controller: _tabController,
        children: [_ReportsTab(), _FormsTab(), _AnalyticsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_inspection',
        onPressed: () => showInspectionReportFormDialog(context, null),
        backgroundColor: DomendraTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// REPORTS TAB
// ════════════════════════════════════════════════════════════
class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InspectionsProvider>();
    if (p.loading && p.reports.isEmpty) return const Center(child: CircularProgressIndicator());

    final list = p.filteredReports;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(children: [
          Expanded(child: _KpiCard('Total', '${p.totalReports}', Icons.assignment, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Pass', '${p.totalPass}', Icons.check_circle, const [Color(0xFF10b981), Color(0xFF34d399)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Fail', '${p.totalFail}', Icons.cancel, const [Color(0xFFef4444), Color(0xFFf87171)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('Conditional', '${p.totalConditional}', Icons.warning, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Draft', '${p.totalDraft}', Icons.edit_note, const [Color(0xFF6b7280), Color(0xFF9ca3af)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Pass Rate', '${p.passRate.toStringAsFixed(0)}%', Icons.trending_up, const [Color(0xFF3b82f6), Color(0xFF60a5fa)])),
        ]),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search inspections...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true, fillColor: DomendraTheme.surface, isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
          ),
          onChanged: p.setSearch,
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          ActionChip(
            label: Text(p.statusFilter == null ? 'All Status' : _statusLabel(p.statusFilter!)),
            backgroundColor: DomendraTheme.surface,
            side: BorderSide(color: p.statusFilter != null ? DomendraTheme.primary : DomendraTheme.outline),
            onPressed: () => _showStatusDialog(context, p),
          ),
        ]),
        const SizedBox(height: 12),
        Text('${list.length} report${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty) _EmptyState(icon: Icons.fact_check, message: 'No inspection reports found. Tap + to create one.')
        else ...list.map((r) => _ReportCard(report: r)),
      ],
    );
  }

  void _showStatusDialog(BuildContext context, InspectionsProvider p) {
    const statuses = ['pass', 'fail', 'conditional', 'draft'];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Filter by Status'),
      content: SizedBox(width: 200, child: ListView.builder(shrinkWrap: true, itemCount: statuses.length + 1, itemBuilder: (_, i) {
        if (i == 0) return ListTile(title: const Text('All'), trailing: p.statusFilter == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setStatusFilter(null); Navigator.pop(ctx); });
        final s = statuses[i - 1];
        return ListTile(title: Text(_statusLabel(s)), trailing: p.statusFilter == s ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setStatusFilter(s); Navigator.pop(ctx); });
      })),
    ));
  }
}

// ════════════════════════════════════════════════════════════
// FORMS TAB
// ════════════════════════════════════════════════════════════
class _FormsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InspectionsProvider>();
    if (p.loading && p.forms.isEmpty) return const Center(child: CircularProgressIndicator());

    final forms = p.forms;
    if (forms.isEmpty) return _EmptyState(icon: Icons.fact_check, message: 'No inspection forms available');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        Text('${forms.length} form${forms.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        ...forms.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: (f.isActive ? DomendraTheme.primary : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.fact_check, size: 20, color: f.isActive ? DomendraTheme.primary : Colors.grey)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${f.itemCount} items${f.description.isNotEmpty ? ' · ${f.description}' : ''}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: (f.isActive ? Colors.green : Colors.grey).withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(f.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: f.isActive ? Colors.green : Colors.grey))),
          ]),
        )),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// ANALYTICS TAB
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InspectionsProvider>();
    if (p.loading) return const Center(child: CircularProgressIndicator());

    final total = p.totalReports;
    final passPct = total > 0 ? (p.totalPass / total * 100).toDouble() : 0.0;
    final failPct = total > 0 ? (p.totalFail / total * 100).toDouble() : 0.0;
    final condPct = total > 0 ? (p.totalConditional / total * 100).toDouble() : 0.0;
    final draftPct = total > 0 ? (p.totalDraft / total * 100).toDouble() : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        const Text('Inspection Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        // Status distribution
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Status Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _Bar('Pass', p.totalPass, passPct, Colors.green),
            _Bar('Fail', p.totalFail, failPct, Colors.red),
            _Bar('Conditional', p.totalConditional, condPct, Colors.orange),
            _Bar('Draft', p.totalDraft, draftPct, Colors.grey),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _DataRow('Total Reports', '$total'),
            _DataRow('Pass Rate', '${p.passRate.toStringAsFixed(1)}%'),
            _DataRow('Total Fails', '${p.totalFail}'),
            _DataRow('Total Pass', '${p.totalPass}'),
            _DataRow('Conditional', '${p.totalConditional}'),
            _DataRow('Drafts', '${p.totalDraft}'),
          ]),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  const _Bar(this.label, this.count, this.pct, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      const SizedBox(width: 6),
      Expanded(child: Stack(children: [
        Container(height: 14, decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(7))),
        FractionallySizedBox(widthFactor: pct / 100, child: Container(height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)))),
      ])),
      const SizedBox(width: 6),
      SizedBox(width: 50, child: Text('${pct.toStringAsFixed(0)}% (${count})', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))),
    ]),
  );
}

class _DataRow extends StatelessWidget {
  final String label, value;
  const _DataRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]));
}

class _ReportCard extends StatelessWidget {
  final InspectionReport report;
  const _ReportCard({required this.report});
  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: report.status == 'fail' ? statusColor.withOpacity(0.3) : DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.fact_check, size: 20, color: statusColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(report.vehicleName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(report.formName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showInspectionReportDetailDialog(context, report); break;
                case 'edit': showInspectionReportFormDialog(context, report); break;
                case 'delete': _confirmDelete(context, report); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(report.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
          if (report.driverName.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text('Driver: ${report.driverName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.primary))),
          if (report.failCount > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text('${report.failCount} fail(s)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red))),
        ]),
        if (report.submittedAt != null) ...[
          const SizedBox(height: 6),
          Text('Submitted: ${_fmtDate(report.submittedAt!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
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

void _confirmDelete(BuildContext context, InspectionReport r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Report'),
    content: Text('Delete inspection report for ${r.vehicleName}?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<InspectionsProvider>().deleteReport(r.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

String _statusLabel(String s) {
  const m = {'pass': 'Passed', 'fail': 'Failed', 'conditional': 'Conditional', 'draft': 'Draft'};
  return m[s] ?? s;
}

Color _statusColor(String s) {
  switch (s) {
    case 'pass': return const Color(0xFF10b981);
    case 'fail': return const Color(0xFFef4444);
    case 'conditional': return const Color(0xFFf59e0b);
    case 'draft': return const Color(0xFF6b7280);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
