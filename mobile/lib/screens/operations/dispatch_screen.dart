import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/dispatch_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

/// Dispatch screen — mirrors web `/app/dispatch`.
/// 4 tabs: Board (Kanban), List, Assignments.
class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});
  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.view_kanban_outlined, size: 18), text: 'Board'),
    Tab(icon: Icon(Icons.list_alt, size: 18), text: 'List'),
    Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Assignments'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DispatchProvider>().fetchAll();
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
        title: const Text('Dispatch'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => context.read<DispatchProvider>().fetchAll())],
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
      drawer: const AppDrawer(currentRoute: '/dispatch'),
      body: Column(
        children: [
          _KpiBar(),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [_BoardTab(), _ListTab(), _AssignmentsTab()],
          )),
        ],
      ),
    );
  }
}

class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DispatchProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(children: [
        Expanded(child: _Mini(label: 'Total', value: '${p.totalJobs}', color: DomendraTheme.primary, icon: Icons.assignment)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Pending', value: '${p.pendingCount}', color: const Color(0xFFF59E0B), icon: Icons.pending)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Active', value: '${p.activeJobs}', color: const Color(0xFF3B82F6), icon: Icons.play_arrow)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Done', value: '${p.completedCount}', color: const Color(0xFF10B981), icon: Icons.check_circle)),
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
    child: Column(children: [Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1))]), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color))]),
  );
}

// ════════════════════════════════════════════════════════════
// TAB 1: BOARD (Kanban columns)
// ════════════════════════════════════════════════════════════
class _BoardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DispatchProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        _KanbanColumn(title: 'Pending', color: const Color(0xFFF59E0B), jobs: p.pendingJobs),
        const SizedBox(height: 12),
        _KanbanColumn(title: 'Assigned', color: DomendraTheme.primary, jobs: p.assignedJobs),
        const SizedBox(height: 12),
        _KanbanColumn(title: 'In Progress', color: const Color(0xFF3B82F6), jobs: p.inProgressJobs),
        const SizedBox(height: 12),
        _KanbanColumn(title: 'Completed', color: const Color(0xFF10B981), jobs: p.completedJobs),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<dynamic> jobs;
  const _KanbanColumn({required this.title, required this.color, required this.jobs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
          child: Row(children: [Icon(Icons.circle, size: 8, color: color), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)), const Spacer(), Text('${jobs.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))]),
        ),
        if (jobs.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No jobs', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)))
        else ...jobs.map((j) => _JobCard(job: j as Map<String, dynamic>)),
      ]),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final p = context.read<DispatchProvider>();
    final id = toIntOr(job['id']);
    final title = job['title'] as String? ?? 'Job #$id';
    final customer = job['customer_name'] as String? ?? '';
    final vehicle = job['vehicle_name'] as String? ?? 'Unassigned';
    final driver = job['driver_name'] as String? ?? '';
    final status = job['status'] as String? ?? 'pending';
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis))]),
        if (customer.isNotEmpty) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.person, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(customer, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))])],
        if (vehicle.isNotEmpty) ...[const SizedBox(height: 2), Row(children: [const Icon(Icons.directions_car, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(vehicle, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))])],
        if (driver.isNotEmpty) ...[const SizedBox(height: 2), Row(children: [const Icon(Icons.person_4, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(driver, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))])],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (status == 'pending')
            TextButton.icon(onPressed: () async => p.startJob(id), icon: const Icon(Icons.play_arrow, size: 14), label: const Text('Start', style: TextStyle(fontSize: 11))),
          if (status == 'in_progress') ...[
            TextButton.icon(onPressed: () async => p.completeJob(id), icon: const Icon(Icons.check, size: 14), label: const Text('Complete', style: TextStyle(fontSize: 11))),
            TextButton.icon(onPressed: () async => p.cancelJob(id), icon: const Icon(Icons.close, size: 14), label: const Text('Cancel', style: TextStyle(fontSize: 11))),
          ],
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2: LIST
// ════════════════════════════════════════════════════════════
class _ListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DispatchProvider>();
    final jobs = p.jobs;
    if (jobs.isEmpty) return const Center(child: Text('No jobs', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: jobs.length,
      itemBuilder: (_, i) => _JobCard(job: jobs[i] as Map<String, dynamic>),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3: ASSIGNMENTS
// ════════════════════════════════════════════════════════════
class _AssignmentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DispatchProvider>();
    final assignments = p.assignments;
    if (assignments.isEmpty) return const Center(child: Text('No assignments', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: assignments.length,
      itemBuilder: (_, i) {
        final a = assignments[i] as Map<String, dynamic>;
        final jobTitle = a['job_title'] as String? ?? 'Job #${a['job'] ?? ''}';
        final vehicle = a['vehicle_name'] as String? ?? '—';
        final driver = a['driver_name'] as String? ?? '—';
        final status = a['status'] as String? ?? 'assigned';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(jobTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.directions_car, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(vehicle, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)))]),
            const SizedBox(height: 2),
            Row(children: [const Icon(Icons.person_4, size: 12, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(driver, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)))]),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor(status)))),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
Color _statusColor(String s) => switch (s) {
  'pending' => const Color(0xFFF59E0B),
  'assigned' => DomendraTheme.primary,
  'in_progress' => const Color(0xFF3B82F6),
  'completed' => const Color(0xFF10B981),
  'cancelled' => const Color(0xFFEF4444),
  _ => const Color(0xFF94A3B8),
};
