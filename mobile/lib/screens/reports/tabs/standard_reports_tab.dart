import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/reports_provider.dart';
import 'report_helpers.dart';

/// Standard Reports tab — mirrors web `StandardReportsTab.vue`.
///
/// 5 pre-built reports + scheduled reports + execution history.
/// This tab manages its own data fetching for standard reports.
class StandardReportsTab extends StatefulWidget {
  const StandardReportsTab({super.key});

  @override
  State<StandardReportsTab> createState() => _StandardReportsTabState();
}

class _StandardReportsTabState extends State<StandardReportsTab> {
  int _selectedDays = 30;
  bool _initialised = false;

  static const _reportTypes = [
    {'type': 'cost-per-mile', 'label': 'Cost per Mile', 'icon': Icons.attach_money, 'color': DomendraTheme.warning},
    {'type': 'fuel-efficiency', 'label': 'Fuel Efficiency', 'icon': Icons.local_gas_station, 'color': DomendraTheme.info},
    {'type': 'mechanic-utilization', 'label': 'Mechanic Utilization', 'icon': Icons.build, 'color': DomendraTheme.secondary},
    {'type': 'fleet-aging', 'label': 'Fleet Aging', 'icon': Icons.access_time, 'color': DomendraTheme.danger},
    {'type': 'benchmark', 'label': 'Fleet Benchmark', 'icon': Icons.compare, 'color': DomendraTheme.primary},
  ];

  static const _dayOptions = [30, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    if (_initialised) return;
    _initialised = true;
    final reports = context.read<ReportsProvider>();
    reports.fetchAllStandardReports(days: _selectedDays);
    reports.fetchTemplates();
    reports.fetchSchedules();
    reports.fetchExecutions();
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        sectionTitle('Standard Reports'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _dayOptions.map((d) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$d days'),
                  selected: _selectedDays == d,
                  onSelected: (_) {
                    setState(() => _selectedDays = d);
                    context.read<ReportsProvider>().fetchAllStandardReports(days: d);
                  },
                  selectedColor: DomendraTheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: _selectedDays == d ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedDays == d ? DomendraTheme.primary : DomendraTheme.onSurfaceMuted,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Report cards grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _reportTypes.length,
          itemBuilder: (_, i) {
            final rt = _reportTypes[i];
            final type = rt['type'] as String;
            final data = reports.standardReports[type];
            return _ReportCard(
              type: type,
              label: rt['label'] as String,
              icon: rt['icon'] as IconData,
              color: rt['color'] as Color,
              data: data,
              days: _selectedDays,
              onReload: () => reports.fetchStandardReport(type, days: _selectedDays),
            );
          },
        ),
        const SizedBox(height: 24),

        // Scheduled reports
        sectionTitle('Scheduled Reports'),
        const SizedBox(height: 10),
        reportCard(child: reports.schedules.isEmpty
            ? tabEmpty(message: 'No scheduled reports')
            : Column(
                children: [
                  for (int i = 0; i < reports.schedules.length; i++) ...[
                    _scheduleRow(reports.schedules[i] as Map<String, dynamic>, reports),
                    if (i < reports.schedules.length - 1) thinDivider(),
                  ],
                ],
              )),
        const SizedBox(height: 20),

        // Execution history
        sectionTitle('Execution History'),
        const SizedBox(height: 10),
        reportCard(child: reports.executions.isEmpty
            ? tabEmpty(message: 'No executions yet')
            : Column(
                children: [
                  for (int i = 0; i < reports.executions.take(10).length; i++) ...[
                    _executionRow(reports.executions[i] as Map<String, dynamic>),
                    if (i < 9 && i < reports.executions.length - 1) thinDivider(),
                  ],
                ],
              )),
      ],
    );
  }

  Widget _scheduleRow(Map<String, dynamic> s, ReportsProvider provider) {
    final name = s['name'] as String? ?? 'Unnamed';
    final frequency = s['frequency'] as String? ?? 'daily';
    final format = s['format'] as String? ?? 'pdf';
    final isActive = s['is_active'] as bool? ?? false;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
      subtitle: Text('$frequency • ${format.toUpperCase()}',
          style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
      trailing: Switch(
        value: isActive,
        activeThumbColor: DomendraTheme.success,
        onChanged: (val) async {
          await provider.updateSchedule(toInt(s['id']), {'is_active': val});
        },
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Column(
            children: [
              dataRow('Frequency', frequency),
              thinDivider(),
              dataRow('Format', format.toUpperCase()),
              thinDivider(),
              dataRow('Recipients', (s['recipients'] as String?) ?? 'None'),
              thinDivider(),
              dataRow('Next Run', (s['next_run'] as String?)?.substring(0, 10) ?? 'N/A'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await provider.deleteSchedule(toInt(s['id']));
                },
                icon: const Icon(Icons.delete, size: 16, color: DomendraTheme.danger),
                label: const Text('Delete', style: TextStyle(color: DomendraTheme.danger)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _executionRow(Map<String, dynamic> e) {
    final status = e['status'] as String? ?? 'pending';
    final createdAt = (e['created_at'] as String?)?.substring(0, 10) ?? '';
    final fileFormat = e['file_format'] as String? ?? '';

    final statusColor = switch (status) {
      'completed' => DomendraTheme.success,
      'failed' => DomendraTheme.danger,
      'pending' => DomendraTheme.warning,
      _ => DomendraTheme.onSurfaceMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.file_present, size: 20, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(createdAt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text(fileFormat.toUpperCase(), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          statusChip(status, statusColor),
        ],
      ),
    );
  }
}

/// Report card for each standard report type.
class _ReportCard extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  final Map<String, dynamic>? data;
  final int days;
  final VoidCallback onReload;

  const _ReportCard({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.data,
    required this.days,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: DomendraTheme.onSurfaceMuted),
                onPressed: onReload,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
          Text('$days days', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 8),
          _previewData(),
        ],
      ),
    );
  }

  Widget _previewData() {
    if (data == null) {
      return const SizedBox(
        height: 50,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: DomendraTheme.primary))),
      );
    }

    // Each standard report has a "vehicles" key (list of per-vehicle data)
    final vehicles = (data!['vehicles'] as List?) ?? [];

    if (vehicles.isEmpty) {
      return const Text('No data', style: TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < vehicles.take(3).length; i++)
          _vehiclePreview(vehicles[i] as Map<String, dynamic>),
      ],
    );
  }

  Widget _vehiclePreview(Map<String, dynamic> v) {
    String name;
    String value;

    switch (type) {
      case 'cost-per-mile':
        name = v['vehicle'] as String? ?? '?';
        value = '${fmtMoney(toDouble(v["cost_per_mile"]))}/mi';
      case 'fuel-efficiency':
        name = v['vehicle'] as String? ?? '?';
        value = '${fmtNum(toDouble(v["mpg"]), decimals: 1)} mpg';
      case 'mechanic-utilization':
        name = v['mechanic'] as String? ?? '?';
        value = '${fmtNum(toDouble(v["total_hours"]), decimals: 1)}h';
      case 'fleet-aging':
        name = v['vehicle'] as String? ?? '?';
        value = '${fmtNum(toDouble(v["age_years"]), decimals: 1)}y old';
      case 'benchmark':
        name = v['vehicle'] as String? ?? '?';
        final variance = toDouble(v['variance_pct']);
        value = '${variance >= 0 ? "+" : ""}${fmtPct(variance)}';
      default:
        name = '?';
        value = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted), overflow: TextOverflow.ellipsis)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
        ],
      ),
    );
  }
}
