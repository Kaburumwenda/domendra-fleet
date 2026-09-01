import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/drivers_provider.dart';
import '../widgets/app_drawer.dart';

/// Drivers screen — mirrors web `pages/app/drivers/index.vue`.
/// 3 tabs: All Drivers, Compliance Issues, Active Assignments.
class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});
  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _search = TextEditingController();
  String? _employmentFilter;
  String? _mvrFilter;
  bool _activeOnly = false;

  static const _tabs = [
    Tab(icon: Icon(Icons.drive_eta, size: 18), text: 'All'),
    Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'Compliance'),
    Tab(icon: Icon(Icons.assignment, size: 18), text: 'Assignments'),
  ];

  static const _employmentOptions = [
    ('Active', 'active'),
    ('On Leave', 'on_leave'),
    ('Suspended', 'suspended'),
    ('Terminated', 'terminated'),
    ('Probation', 'probation'),
  ];

  static const _mvrOptions = [
    ('Clean', 'clean'),
    ('Warning', 'warning'),
    ('Suspended', 'suspended'),
    ('Expired', 'expired'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriversProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  List<dynamic> _filterList(List<dynamic> list) {
    final q = _search.text.trim().toLowerCase();
    var result = list;
    if (q.isNotEmpty) {
      result = result.where((d) {
        final m = d as Map<String, dynamic>;
        return (m['full_name'] as String? ?? '').toLowerCase().contains(q) ||
            (m['email'] as String? ?? '').toLowerCase().contains(q) ||
            (m['phone'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }
    if (_employmentFilter != null || _mvrFilter != null || _activeOnly) {
      result = result.where((d) {
        final m = d as Map<String, dynamic>;
        final profile = m['driver_profile'] as Map<String, dynamic>?;
        final empStatus = profile?['employment_status'] as String?;
        final mvrStatus = profile?['mvr_status'] as String?;
        final isActive = m['is_active'] as bool? ?? false;
        bool pass = true;
        if (_employmentFilter != null) pass = pass && empStatus == _employmentFilter;
        if (_mvrFilter != null) pass = pass && mvrStatus == _mvrFilter;
        if (_activeOnly) pass = pass && isActive;
        return pass;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriversProvider>();
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Drivers'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => p.refresh()),
          IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () {}),
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
      drawer: const AppDrawer(currentRoute: '/drivers'),
      body: Column(
        children: [
          // KPI bar
          _KpiBar(),
          // Search + filters
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            color: DomendraTheme.surface,
            child: Column(children: [
              Row(children: [
                Expanded(child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search drivers…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DomendraTheme.outline)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onChanged: (_) => setState(() {}),
                )),
              ]),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  ..._employmentOptions.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(t.$1, style: TextStyle(fontSize: 10)),
                      selected: _employmentFilter == t.$2,
                      onSelected: (v) => setState(() => _employmentFilter = v ? t.$2 : null),
                      selectedColor: DomendraTheme.primary,
                      labelStyle: TextStyle(fontSize: 10, color: _employmentFilter == t.$2 ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                      backgroundColor: DomendraTheme.surfaceVariant,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )),
                  const SizedBox(width: 4),
                  ..._mvrOptions.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text('MVR: ${t.$1}', style: TextStyle(fontSize: 10)),
                      selected: _mvrFilter == t.$2,
                      onSelected: (v) => setState(() => _mvrFilter = v ? t.$2 : null),
                      selectedColor: _mvrColor(t.$2),
                      labelStyle: TextStyle(fontSize: 10, color: _mvrFilter == t.$2 ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
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
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _DriversList(drivers: _filterList(p.drivers), showComplianceChips: false, showAssignment: false),
              _DriversList(drivers: _filterList(p.complianceIssues), showComplianceChips: true, showAssignment: false),
              _DriversList(drivers: _filterList(p.activeAssignments), showComplianceChips: false, showAssignment: true),
            ],
          )),
        ],
      ),
    );
  }
}

class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriversProvider>();
    final expiring30d = p.licensesExpiring30d + p.medCardsExpiring30d;
    final mvrIssues = p.mvrWarning + p.mvrSuspended;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(children: [
        Expanded(child: _Mini(label: 'Total', value: '${p.total}', color: DomendraTheme.primary, icon: Icons.drive_eta)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Active', value: '${p.activeCount}', color: const Color(0xFF10B981), icon: Icons.check_circle)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Expiring 30d', value: '$expiring30d', color: const Color(0xFFF59E0B), icon: Icons.schedule)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'MVR Issues', value: '$mvrIssues', color: const Color(0xFFEF4444), icon: Icons.warning)),
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
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1))]), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color))]),
  );
}

class _DriversList extends StatelessWidget {
  final List<dynamic> drivers;
  final bool showComplianceChips;
  final bool showAssignment;
  const _DriversList({required this.drivers, required this.showComplianceChips, required this.showAssignment});

  @override
  Widget build(BuildContext context) {
    final p = context.read<DriversProvider>();
    if (drivers.isEmpty) return const Center(child: Text('No drivers found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: drivers.length,
      itemBuilder: (_, i) {
        final d = drivers[i] as Map<String, dynamic>;
        final name = d['full_name'] as String? ?? 'Unknown';
        final email = d['email'] as String? ?? '';
        final phone = d['phone'] as String? ?? '';
        final photo = d['photo'] as String?;
        final profile = d['driver_profile'] as Map<String, dynamic>?;
        final licenseNumber = profile?['license_number'] as String?;
        final licenseClass = profile?['license_class'] as String?;
        final licenseExpiry = profile?['license_expiry'] as String?;
        final medCardExpiry = profile?['medical_card_expiry'] as String?;
        final mvrStatus = profile?['mvr_status'] as String? ?? 'clean';
        final empStatus = profile?['employment_status'] as String? ?? 'active';
        final hireDate = profile?['hire_date'] as String?;
        final assignment = profile?['active_assignment'] as Map<String, dynamic>?;
        final assignmentActive = assignment?['is_active'] as bool? ?? false;
        final vehicle = assignment?['vehicle'] as Map<String, dynamic>?;
        final vehicleName = vehicle != null
            ? '${vehicle['year'] ?? ''} ${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim()
            : (assignment?['vehicle_unit_number'] as String?);
        final assignedDate = assignment?['assigned_date'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: photo != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Text('IMG'))
                    : Center(child: Text(_initials(name), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DomendraTheme.primary))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(email.isNotEmpty ? email : (phone.isNotEmpty ? phone : '—'), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              _EmploymentChip(status: empStatus),
            ]),
            const SizedBox(height: 8),
            // License info
            if (licenseNumber != null) _InfoLine(icon: Icons.badge, text: 'License: $licenseNumber${licenseClass != null ? ' (Class $licenseClass)' : ''}'),
            if (licenseExpiry != null) _DateLine(icon: Icons.card_membership, label: 'License Expiry', dateStr: licenseExpiry),
            if (medCardExpiry != null) _DateLine(icon: Icons.medical_services, label: 'Med Card', dateStr: medCardExpiry),
            // MVR status
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.history, size: 10, color: _mvrColor(mvrStatus)),
              const SizedBox(width: 4),
              Text('MVR: ', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: _mvrColor(mvrStatus).withOpacity(0.12), borderRadius: BorderRadius.circular(4)), child: Text(_mvrLabel(mvrStatus), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _mvrColor(mvrStatus)))),
            ]),
            if (hireDate != null) ...[const SizedBox(height: 4), _InfoLine(icon: Icons.event, text: 'Hired: ${_formatDate(hireDate)}')],
            // Compliance issues chips
            if (showComplianceChips) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 4, runSpacing: 4, children: _complianceChips(licenseExpiry, medCardExpiry, mvrStatus)),
            ],
            // Active assignment info
            if (showAssignment && assignmentActive) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.assignment, size: 12, color: Color(0xFF10B981)), const SizedBox(width: 4), const Text('Active Assignment', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF10B981)))]),
                  const SizedBox(height: 4),
                  if (vehicleName != null) _InfoLine(icon: Icons.directions_car, text: vehicleName),
                  if (assignedDate != null) _InfoLine(icon: Icons.event, text: 'Since: ${_formatDate(assignedDate)}'),
                ]),
              ),
            ],
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit, size: 14), label: const Text('Edit', style: TextStyle(fontSize: 11))),
              TextButton.icon(onPressed: () async => p.delete(d['id'] as int), icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red))),
            ]),
          ]),
        );
      },
    );
  }
}

class _EmploymentChip extends StatelessWidget {
  final String status;
  const _EmploymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _employmentColor(status);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(_employmentLabel(status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)));
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [Icon(icon, size: 10, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))]),
  );
}

class _DateLine extends StatelessWidget {
  final IconData icon;
  final String label, dateStr;
  const _DateLine({required this.icon, required this.label, required this.dateStr});
  @override
  Widget build(BuildContext context) {
    final color = _dateColor(dateStr);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [Icon(icon, size: 10, color: color), const SizedBox(width: 4), Text('$label: ', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)), Text(_formatDate(dateStr), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
String _initials(String name) {
  final parts = name.split(' ');
  if (parts.isEmpty) return '?';
  final f = parts.first.isNotEmpty ? parts.first[0] : '';
  final l = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  final result = '$f$l'.toUpperCase();
  return result.isEmpty ? '?' : result;
}

Color _employmentColor(String s) => switch (s) {
  'active' => const Color(0xFF10B981),
  'on_leave' => const Color(0xFFF59E0B),
  'suspended' => const Color(0xFFEF4444),
  'terminated' => const Color(0xFF6B7280),
  'probation' => const Color(0xFF8B5CF6),
  _ => const Color(0xFF94A3B8),
};

String _employmentLabel(String s) => switch (s) {
  'active' => 'Active',
  'on_leave' => 'On Leave',
  'suspended' => 'Suspended',
  'terminated' => 'Terminated',
  'probation' => 'Probation',
  _ => s,
};

Color _mvrColor(String s) => switch (s) {
  'clean' => const Color(0xFF10B981),
  'warning' => const Color(0xFFF59E0B),
  'suspended' => const Color(0xFFEF4444),
  'expired' => const Color(0xFFDC2626),
  _ => const Color(0xFF94A3B8),
};

String _mvrLabel(String s) => switch (s) {
  'clean' => 'Clean',
  'warning' => 'Warning',
  'suspended' => 'Suspended',
  'expired' => 'Expired',
  _ => s,
};

Color _dateColor(String dateStr) {
  try {
    final exp = DateTime.parse(dateStr);
    final now = DateTime.now();
    if (exp.isBefore(now)) return const Color(0xFFEF4444);
    if (exp.difference(now).inDays <= 30) return const Color(0xFFF59E0B);
    return DomendraTheme.onSurfaceMuted;
  } catch (_) {
    return DomendraTheme.onSurfaceMuted;
  }
}

String _formatDate(String dateStr) {
  try {
    final d = DateTime.parse(dateStr);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return dateStr;
  }
}

List<Widget> _complianceChips(String? licenseExpiry, String? medCardExpiry, String mvrStatus) {
  final chips = <Widget>[];
  final now = DateTime.now();

  void addChip(String text, Color color) {
    chips.add(Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warning_amber, size: 10, color: color), const SizedBox(width: 2), Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color))])));
  }

  bool isExpired(String? d) {
    if (d == null) return false;
    try { return DateTime.parse(d).isBefore(now); } catch (_) { return false; }
  }
  bool isExpiring30d(String? d) {
    if (d == null) return false;
    try { final exp = DateTime.parse(d); return exp.isAfter(now) && exp.difference(now).inDays <= 30; } catch (_) { return false; }
  }

  if (isExpired(licenseExpiry)) addChip('License Expired', const Color(0xFFEF4444));
  else if (isExpiring30d(licenseExpiry)) addChip('License Expiring', const Color(0xFFF59E0B));

  if (isExpired(medCardExpiry)) addChip('Med Card Expired', const Color(0xFFEF4444));
  else if (isExpiring30d(medCardExpiry)) addChip('Med Card Expiring', const Color(0xFFF59E0B));

  if (mvrStatus == 'warning') addChip('MVR Warning', const Color(0xFFF59E0B));
  if (mvrStatus == 'suspended') addChip('MVR Suspended', const Color(0xFFEF4444));
  if (mvrStatus == 'expired') addChip('MVR Expired', const Color(0xFFDC2626));

  if (chips.isEmpty) {
    chips.add(Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, size: 10, color: Color(0xFF10B981)), const SizedBox(width: 2), const Text('No Issues', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))])));
  }
  return chips;
}
