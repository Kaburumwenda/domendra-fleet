import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/reminders_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'reminders_dialogs.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
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
      context.read<RemindersProvider>().init();
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
        title: const Text('Reminders'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<RemindersProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/reminders'),
      body: TabBarView(
        controller: _tabController,
        children: [_BoardTab(), _RecordsTab(), _TimelineTab()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_reminder',
        onPressed: () => showReminderFormDialog(context, null),
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
    final p = context.watch<RemindersProvider>();
    if (p.loading && p.reminders.isEmpty) return const Center(child: CircularProgressIndicator());

    final due = p.reminders.where((r) => r.isDue && !r.isOverdue).toList();
    final overdue = p.reminders.where((r) => r.isOverdue).toList();
    final upcoming = p.reminders.where((r) => !r.isDue && r.isActive).toList();
    final inactive = p.reminders.where((r) => !r.isActive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(children: [
          Expanded(child: _KpiCard('Total', '${p.totalReminders}', Icons.notifications, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Due', '${p.totalDue}', Icons.schedule, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Overdue', '${p.totalOverdue}', Icons.warning, const [Color(0xFFef4444), Color(0xFFf87171)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('Active', '${p.totalActive}', Icons.check_circle, const [Color(0xFF10b981), Color(0xFF34d399)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Escalated', '${p.reminders.where((r) => r.escalationLevel > 0).length}', Icons.priority_high, const [Color(0xFF8b5cf6), Color(0xFFa78bfa)])),
        ]),
        const SizedBox(height: 16),
        if (overdue.isNotEmpty) _buildSection('Overdue', overdue, Colors.red),
        if (due.isNotEmpty) _buildSection('Due Now', due, Colors.orange),
        if (upcoming.isNotEmpty) _buildSection('Upcoming', upcoming, Colors.blue),
        if (inactive.isNotEmpty) _buildSection('Inactive', inactive, Colors.grey),
      ],
    );
  }

  Widget _buildSection(String title, List<Reminder> items, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$title (${items.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ...items.map((r) => _ReminderCard(reminder: r)),
      const SizedBox(height: 14),
    ]);
  }
}

// ════════════════════════════════════════════════════════════
// RECORDS TAB
// ════════════════════════════════════════════════════════════
class _RecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RemindersProvider>();
    if (p.loading && p.reminders.isEmpty) return const Center(child: CircularProgressIndicator());

    final list = p.filteredReminders;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search reminders...',
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
            label: Text(p.triggerFilter == null ? 'All Triggers' : _triggerLabel(p.triggerFilter!)),
            backgroundColor: DomendraTheme.surface,
            side: BorderSide(color: p.triggerFilter != null ? DomendraTheme.primary : DomendraTheme.outline),
            onPressed: () => _showTriggerDialog(context, p),
          ),
          ActionChip(
            label: Text(p.activeOnly == null ? 'All' : (p.activeOnly! ? 'Active Only' : 'Inactive Only')),
            backgroundColor: DomendraTheme.surface,
            side: BorderSide(color: p.activeOnly != null ? DomendraTheme.primary : DomendraTheme.outline),
            onPressed: () => _showActiveDialog(context, p),
          ),
        ]),
        const SizedBox(height: 12),
        Text('${list.length} reminder${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty) _EmptyState(icon: Icons.notifications, message: 'No reminders found. Tap + to add one.')
        else ...list.map((r) => _ReminderCard(reminder: r)),
      ],
    );
  }

  void _showTriggerDialog(BuildContext context, RemindersProvider p) {
    const types = ['time', 'mileage', 'engine_hours'];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Filter by Trigger'),
      content: SizedBox(width: 200, child: ListView.builder(shrinkWrap: true, itemCount: types.length + 1, itemBuilder: (_, i) {
        if (i == 0) return ListTile(title: const Text('All'), trailing: p.triggerFilter == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setTriggerFilter(null); Navigator.pop(ctx); });
        final t = types[i - 1];
        return ListTile(title: Text(_triggerLabel(t)), trailing: p.triggerFilter == t ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setTriggerFilter(t); Navigator.pop(ctx); });
      })),
    ));
  }

  void _showActiveDialog(BuildContext context, RemindersProvider p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Filter by Status'),
      content: SizedBox(width: 200, child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text('All'), trailing: p.activeOnly == null ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setActiveOnly(null); Navigator.pop(ctx); }),
        ListTile(title: const Text('Active Only'), trailing: p.activeOnly == true ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setActiveOnly(true); Navigator.pop(ctx); }),
        ListTile(title: const Text('Inactive Only'), trailing: p.activeOnly == false ? const Icon(Icons.check, color: DomendraTheme.primary) : null, onTap: () { p.setActiveOnly(false); Navigator.pop(ctx); }),
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
    final p = context.watch<RemindersProvider>();
    if (p.loading && p.reminders.isEmpty) return const Center(child: CircularProgressIndicator());
    final sorted = List<Reminder>.from(p.reminders)..sort((a, b) {
      final ad = a.nextDueDate; final bd = b.nextDueDate;
      if (ad == null && bd == null) return 0; if (ad == null) return 1; if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    if (sorted.isEmpty) return _EmptyState(icon: Icons.timeline, message: 'No reminders yet');
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: List.generate(sorted.length, (i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: sorted[i].isOverdue ? Colors.red : (sorted[i].isDue ? Colors.orange : DomendraTheme.primary), shape: BoxShape.circle), child: const Icon(Icons.notifications, color: Colors.white, size: 14)),
          if (i < sorted.length - 1) Container(width: 2, height: 40, color: DomendraTheme.outline),
        ]),
        const SizedBox(width: 10),
        Expanded(child: _ReminderCard(reminder: sorted[i])),
      ])),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});
  @override
  Widget build(BuildContext context) {
    final color = reminder.isOverdue ? Colors.red : (reminder.isDue ? Colors.orange : (reminder.isActive ? DomendraTheme.primary : Colors.grey));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: reminder.isOverdue ? Colors.red.withOpacity(0.3) : DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.notifications, size: 20, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(reminder.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showReminderDetailDialog(context, reminder); break;
                case 'edit': showReminderFormDialog(context, reminder); break;
                case 'delete': _confirmDelete(context, reminder); break;
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
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(reminder.triggerTypeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
          if (reminder.isOverdue) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Text('OVERDUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)))
          else if (reminder.isDue) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Text('DUE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange))),
          if (reminder.escalationLevel > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text('Esc: ${reminder.escalationLabel}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.purple))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('Next: ${reminder.nextDueText}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(width: 8),
          if (reminder.autoGenerateWorkOrder) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Text('Auto-WO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DomendraTheme.primary))),
        ]),
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

void _confirmDelete(BuildContext context, Reminder r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Reminder'),
    content: Text('Delete reminder "${r.title}"?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<RemindersProvider>().deleteReminder(r.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

String _triggerLabel(String t) {
  const m = {'time': 'Time (Months)', 'mileage': 'Mileage', 'engine_hours': 'Engine Hours'};
  return m[t] ?? t;
}
