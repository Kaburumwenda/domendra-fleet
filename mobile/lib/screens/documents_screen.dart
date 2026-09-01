import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/app_config.dart';
import '../providers/documents_provider.dart';
import '../widgets/app_drawer.dart';

// ── Document type options (top-level so all widgets can access) ─
const typeOptions = [
  ('Insurance', 'insurance'),
  ('Registration', 'registration'),
  ('Title', 'title'),
  ('Inspection', 'inspection'),
  ('License', 'license'),
  ('Medical Card', 'medical_card'),
  ('Warranty', 'warranty'),
  ('Contract', 'contract'),
  ('Permit', 'permit'),
  ('Maintenance', 'maintenance'),
  ('Other', 'other'),
];

const expiryOptions = [
  ('Expired', 'expired'),
  ('Expiring Soon', 'expiring'),
  ('No Expiry', 'no_expiry'),
];

/// Documents screen — mirrors web `pages/app/documents/index.vue`.
/// 3 tabs: Grid, Table, Expiring Soon.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _search = TextEditingController();
  String? _typeFilter;
  String? _expiryFilter;
  int? _vehicleFilter;

  static const _tabs = [
    Tab(icon: Icon(Icons.grid_view_outlined, size: 18), text: 'Grid'),
    Tab(icon: Icon(Icons.list_alt_outlined, size: 18), text: 'Table'),
    Tab(icon: Icon(Icons.access_time_filled_outlined, size: 18), text: 'Expiring'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsProvider>().refresh();
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
        return (m['title'] as String? ?? '').toLowerCase().contains(q) ||
            (m['notes'] as String? ?? '').toLowerCase().contains(q) ||
            (m['vehicle_name'] as String? ?? '').toLowerCase().contains(q) ||
            (m['contact_name'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }
    if (_typeFilter != null) {
      result = result.where((d) => (d as Map<String, dynamic>)['document_type'] == _typeFilter).toList();
    }
    if (_vehicleFilter != null) {
      result = result.where((d) => (d as Map<String, dynamic>)['vehicle'] == _vehicleFilter).toList();
    }
    if (_expiryFilter != null) {
      final now = DateTime.now();
      result = result.where((d) {
        final m = d as Map<String, dynamic>;
        final expiryStr = m['expiry_date'] as String?;
        if (_expiryFilter == 'no_expiry') return expiryStr == null;
        if (expiryStr == null) return false;
        try {
          final exp = DateTime.parse(expiryStr);
          if (_expiryFilter == 'expired') return exp.isBefore(now);
          if (_expiryFilter == 'expiring') return !exp.isBefore(now) && exp.difference(now).inDays <= 30;
        } catch (_) {}
        return false;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DocumentsProvider>();
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Documents'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => p.refresh()),
          IconButton(icon: const Icon(Icons.upload_file, size: 20), onPressed: () => _showUploadDialog(context)),
          IconButton(icon: const Icon(Icons.preview, size: 20), tooltip: 'Seed Demo', onPressed: () => p.seedDemo()),
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
      drawer: const AppDrawer(currentRoute: '/documents'),
      body: Column(
        children: [
          // KPI bar
          _KpiBar(),
          // Search + filters
          _FilterBar(
            search: _search,
            onChanged: () => setState(() {}),
            typeFilter: _typeFilter,
            onTypeChanged: (v) => setState(() => _typeFilter = v),
            expiryFilter: _expiryFilter,
            onExpiryChanged: (v) => setState(() => _expiryFilter = v),
            vehicleFilter: _vehicleFilter,
            onVehicleChanged: (v) => setState(() => _vehicleFilter = v),
            vehicles: p.vehicles,
            onClear: () => setState(() {
              _typeFilter = null;
              _expiryFilter = null;
              _vehicleFilter = null;
              _search.clear();
            }),
          ),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _GridTab(documents: _filterList(p.documents)),
              _TableTab(documents: _filterList(p.documents)),
              _ExpiringTab(documents: p.expiringSoon),
            ],
          )),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, {Map<String, dynamic>? doc}) {
    showDialog(context: context, builder: (_) => _UploadDialog(doc: doc));
  }
}

// ════════════════════════════════════════════════════════════
// KPI BAR
// ════════════════════════════════════════════════════════════
class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<DocumentsProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Column(children: [
        Row(children: [
          Expanded(child: _Mini(label: 'Total', value: '${p.total}', sub: p.totalSizeDisplay, color: DomendraTheme.primary, icon: Icons.description)),
          const SizedBox(width: 4),
          Expanded(child: _Mini(label: 'Expiring Soon', value: '${p.totalExpiringSoon}', sub: 'Within 30d', color: const Color(0xFFF59E0B), icon: Icons.schedule)),
          const SizedBox(width: 4),
          Expanded(child: _Mini(label: 'Expired', value: '${p.totalExpired}', sub: 'Need renewal', color: const Color(0xFFEF4444), icon: Icons.error_outline)),
          const SizedBox(width: 4),
          Expanded(child: _Mini(label: 'No Expiry', value: '${p.totalNoExpiry}', sub: 'Permanent', color: const Color(0xFF10B981), icon: Icons.archive)),
        ]),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  const _Mini({required this.label, required this.value, required this.sub, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1))]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(sub, style: TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ════════════════════════════════════════════════════════════
// FILTER BAR
// ════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final TextEditingController search;
  final VoidCallback onChanged;
  final String? typeFilter;
  final ValueChanged<String?> onTypeChanged;
  final String? expiryFilter;
  final ValueChanged<String?> onExpiryChanged;
  final int? vehicleFilter;
  final ValueChanged<int?> onVehicleChanged;
  final List<dynamic> vehicles;
  final VoidCallback onClear;

  const _FilterBar({
    required this.search,
    required this.onChanged,
    required this.typeFilter,
    required this.onTypeChanged,
    required this.expiryFilter,
    required this.onExpiryChanged,
    required this.vehicleFilter,
    required this.onVehicleChanged,
    required this.vehicles,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      color: DomendraTheme.surface,
      child: Column(children: [
        Row(children: [
          Expanded(child: TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: 'Search documents…',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: DomendraTheme.outline)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onChanged: (_) => onChanged(),
          )),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            tooltip: 'Clear filters',
            onPressed: onClear,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ]),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            // Type filter chips
            ...typeOptions.map((t) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilterChip(
                label: Text(t.$1, style: TextStyle(fontSize: 10)),
                selected: typeFilter == t.$2,
                onSelected: (v) => onTypeChanged(v ? t.$2 : null),
                selectedColor: _typeColor(t.$2),
                labelStyle: TextStyle(fontSize: 10, color: typeFilter == t.$2 ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                backgroundColor: DomendraTheme.surfaceVariant,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )),
            const SizedBox(width: 4),
            // Expiry filter chips
            ...expiryOptions.map((t) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilterChip(
                label: Text(t.$1, style: TextStyle(fontSize: 10)),
                selected: expiryFilter == t.$2,
                onSelected: (v) => onExpiryChanged(v ? t.$2 : null),
                selectedColor: t.$2 == 'expired' ? const Color(0xFFEF4444) : t.$2 == 'expiring' ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                labelStyle: TextStyle(fontSize: 10, color: expiryFilter == t.$2 ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                backgroundColor: DomendraTheme.surfaceVariant,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )),
          ]),
        ),
        // Vehicle filter dropdown
        if (vehicles.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: DropdownButton<int?>(
              value: vehicleFilter,
              hint: const Text('All Vehicles', style: TextStyle(fontSize: 11)),
              isDense: true,
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All Vehicles', style: TextStyle(fontSize: 11))),
                ...vehicles.map((v) {
                  final m = v as Map<String, dynamic>;
                  final name = m['display_name'] as String? ?? '${m['year'] ?? ''} ${m['make'] ?? ''} ${m['model'] ?? ''}'.trim();
                  return DropdownMenuItem<int?>(value: m['id'] as int, child: Text(name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis));
                }),
              ],
              onChanged: onVehicleChanged,
            ),
          ),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// GRID TAB
// ════════════════════════════════════════════════════════════
class _GridTab extends StatelessWidget {
  final List<dynamic> documents;
  const _GridTab({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const Center(child: Text('No documents found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: documents.length,
      itemBuilder: (_, i) {
        final d = documents[i] as Map<String, dynamic>;
        final title = d['title'] as String? ?? 'Untitled';
        final type = d['document_type'] as String? ?? 'other';
        final vehicleName = d['vehicle_name'] as String?;
        final contactName = d['contact_name'] as String?;
        final entity = vehicleName ?? contactName ?? 'General';
        final fileSize = d['file_size_display'] as String? ?? '';
        final expiryDate = d['expiry_date'] as String?;
        final isExpired = d['is_expired'] as bool? ?? false;
        final isExpiringSoon = d['is_expiring_soon'] as bool? ?? false;
        final typeColor = _typeColor(type);

        return GestureDetector(
          onTap: () => _showDetailDialog(context, d),
          child: Container(
            decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header with icon
              Container(
                height: 70,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                child: Stack(children: [
                  Center(child: Icon(_typeIcon(type), size: 32, color: typeColor)),
                  if (isExpired || isExpiringSoon)
                    Positioned(top: 4, right: 4,
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(4)),
                        child: Text(isExpired ? 'Expired' : 'Soon', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 4),
              // Content
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(entity, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [const Icon(Icons.attach_file, size: 10, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 2), Expanded(child: Text(fileSize, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 2),
                _ExpiryBadge(expiryDate: expiryDate, isExpired: isExpired, isExpiringSoon: isExpiringSoon),
              ])),
            ]),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// TABLE TAB
// ════════════════════════════════════════════════════════════
class _TableTab extends StatelessWidget {
  final List<dynamic> documents;
  const _TableTab({required this.documents});

  @override
  Widget build(BuildContext context) {
    final p = context.read<DocumentsProvider>();
    if (documents.isEmpty) return const Center(child: Text('No documents found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: documents.length,
      itemBuilder: (_, i) {
        final d = documents[i] as Map<String, dynamic>;
        final title = d['title'] as String? ?? 'Untitled';
        final type = d['document_type'] as String? ?? 'other';
        final vehicleName = d['vehicle_name'] as String?;
        final contactName = d['contact_name'] as String?;
        final entity = vehicleName ?? contactName ?? 'General';
        final fileSize = d['file_size_display'] as String? ?? '';
        final expiryDate = d['expiry_date'] as String?;
        final isExpired = d['is_expired'] as bool? ?? false;
        final isExpiringSoon = d['is_expiring_soon'] as bool? ?? false;
        final uploadedBy = d['uploaded_by_name'] as String? ?? '';
        final createdAt = d['created_at'] as String?;
        final typeColor = _typeColor(type);

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Icon(_typeIcon(type), size: 16, color: typeColor)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(entity, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)), child: Text(_typeLabel(type), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: typeColor))),
                const SizedBox(height: 2),
                Text(fileSize, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
              ]),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (uploadedBy.isNotEmpty) _InfoLine(icon: Icons.person, text: uploadedBy),
                if (createdAt != null) _InfoLine(icon: Icons.calendar_today, text: _formatDate(createdAt)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _ExpiryBadge(expiryDate: expiryDate, isExpired: isExpired, isExpiringSoon: isExpiringSoon),
              ]),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(onPressed: () => _showDetailDialog(context, d), icon: const Icon(Icons.visibility, size: 14), label: const Text('View', style: TextStyle(fontSize: 11))),
              TextButton.icon(onPressed: () => _showUploadDialog(context, doc: d), icon: const Icon(Icons.edit, size: 14), label: const Text('Edit', style: TextStyle(fontSize: 11))),
              TextButton.icon(onPressed: () async => p.delete(d['id'] as int), icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red))),
            ]),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// EXPIRING SOON TAB (Timeline)
// ════════════════════════════════════════════════════════════
class _ExpiringTab extends StatelessWidget {
  final List<dynamic> documents;
  const _ExpiringTab({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const Center(child: Text('No documents expiring soon', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: documents.length,
      itemBuilder: (_, i) {
        final d = documents[i] as Map<String, dynamic>;
        final title = d['title'] as String? ?? 'Untitled';
        final type = d['document_type'] as String? ?? 'other';
        final entity = (d['vehicle_name'] as String?) ?? (d['contact_name'] as String?) ?? 'General';
        final expiryDate = d['expiry_date'] as String?;
        final daysToExpiry = d['days_to_expiry'] as int?;
        final isExpired = d['is_expired'] as bool? ?? false;
        final typeColor = _typeColor(type);
        final isOverdue = (daysToExpiry ?? 0) < 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DomendraTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withOpacity(0.3)),
          ),
          child: Row(children: [
            // Timeline dot
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(isOverdue ? Icons.error : Icons.access_time, size: 18, color: isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_typeIcon(type), size: 12, color: typeColor),
                const SizedBox(width: 4),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 2),
              Text(entity, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Text(_typeLabel(type), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeColor)),
                const SizedBox(width: 8),
                if (expiryDate != null)
                  Text(_formatDate(expiryDate), style: TextStyle(fontSize: 9, color: isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
              ]),
            ])),
            // Days badge
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: (isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(
                daysToExpiry != null
                  ? (daysToExpiry < 0 ? '${daysToExpiry.abs()}d overdue' : daysToExpiry == 0 ? 'Today' : '${daysToExpiry}d left')
                  : '',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// EXPIRY BADGE
// ════════════════════════════════════════════════════════════
class _ExpiryBadge extends StatelessWidget {
  final String? expiryDate;
  final bool isExpired;
  final bool isExpiringSoon;
  const _ExpiryBadge({required this.expiryDate, required this.isExpired, required this.isExpiringSoon});

  @override
  Widget build(BuildContext context) {
    if (expiryDate == null) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
        child: const Text('No expiry', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF10B981))));
    }
    final color = isExpired ? const Color(0xFFEF4444) : isExpiringSoon ? const Color(0xFFF59E0B) : DomendraTheme.onSurfaceMuted;
    final prefix = isExpired ? 'Exp ' : isExpiringSoon ? 'Soon ' : '';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text('$prefix${_formatDate(expiryDate!)}', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color)));
  }
}

// ════════════════════════════════════════════════════════════
// INFO LINE
// ════════════════════════════════════════════════════════════
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [Icon(icon, size: 10, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Expanded(child: Text(text, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis))]),
  );
}

// ════════════════════════════════════════════════════════════
// DETAIL DIALOG
// ════════════════════════════════════════════════════════════
void _showDetailDialog(BuildContext context, Map<String, dynamic> doc) {
  showDialog(context: context, builder: (_) => _DetailDialog(doc: doc));
}

class _DetailDialog extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DetailDialog({required this.doc});

  @override
  Widget build(BuildContext context) {
    final p = context.read<DocumentsProvider>();
    final title = doc['title'] as String? ?? 'Untitled';
    final type = doc['document_type'] as String? ?? 'other';
    final vehicleName = doc['vehicle_name'] as String?;
    final contactName = doc['contact_name'] as String?;
    final fileSize = doc['file_size_display'] as String? ?? '';
    final expiryDate = doc['expiry_date'] as String?;
    final isExpired = doc['is_expired'] as bool? ?? false;
    final isExpiringSoon = doc['is_expiring_soon'] as bool? ?? false;
    final daysToExpiry = doc['days_to_expiry'] as int?;
    final uploadedBy = doc['uploaded_by_name'] as String? ?? '';
    final notes = doc['notes'] as String? ?? '';
    final createdAt = doc['created_at'] as String?;
    final updatedAt = doc['updated_at'] as String?;
    final file = doc['file'] as String?;
    final fileTypeIcon = doc['file_type_icon'] as String? ?? 'other';
    final fileExt = doc['file_extension'] as String? ?? '';
    final typeColor = _typeColor(type);
    final fileName = file != null ? file.split('/').last : '';

    double width = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: DomendraTheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width * 0.9, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              // Header
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(_typeIcon(type), size: 20, color: typeColor)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)), child: Text(_typeLabel(type), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeColor))),
                    const SizedBox(width: 4),
                    _ExpiryBadge(expiryDate: expiryDate, isExpired: isExpired, isExpiringSoon: isExpiringSoon),
                  ]),
                ])),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
              ]),
              const Divider(height: 16),
              // File preview card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(_fileTypeIcon(fileTypeIcon), size: 28, color: _fileTypeColor(fileTypeIcon)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fileName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('$fileSize • ${fileExt.toUpperCase()}', style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
                  ])),
                  if (file != null)
                    IconButton(icon: const Icon(Icons.download, size: 18, color: DomendraTheme.primary), onPressed: () => _downloadFile(context, file), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero),
                ]),
              ),
              const SizedBox(height: 12),
              // Info grid
              _InfoGrid(items: [
                ('Vehicle', vehicleName ?? '—'),
                ('Contact / Driver', contactName ?? '—'),
                ('Uploaded By', uploadedBy.isNotEmpty ? uploadedBy : '—'),
                ('Expiry Date', expiryDate != null
                  ? '${_formatDate(expiryDate)} (${daysToExpiry != null
                    ? (daysToExpiry < 0 ? '${daysToExpiry.abs()} days overdue' : '$daysToExpiry days left')
                    : 'no expiry'})'
                  : 'No expiry'),
                ('Uploaded', createdAt != null ? _formatDate(createdAt) : '—'),
                ('Updated', updatedAt != null ? _formatDate(updatedAt) : '—'),
              ]),
              // Notes
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(6)), child: Text(notes, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurface))),
              ],
              const SizedBox(height: 12),
              // Action buttons
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                TextButton.icon(onPressed: () {
                  Navigator.pop(context);
                  _showUploadDialog(context, doc: doc);
                }, icon: const Icon(Icons.edit, size: 16), label: const Text('Edit', style: TextStyle(fontSize: 12))),
                if (file != null)
                  TextButton.icon(onPressed: () => _downloadFile(context, file), icon: const Icon(Icons.download, size: 16), label: const Text('Download', style: TextStyle(fontSize: 12))),
                TextButton.icon(onPressed: () async {
                  await p.delete(doc['id'] as int);
                  if (context.mounted) Navigator.pop(context);
                }, icon: const Icon(Icons.delete, size: 16, color: Colors.red), label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String)> items;
  const _InfoGrid({required this.items});
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3.2, crossAxisSpacing: 8, mainAxisSpacing: 4),
    itemCount: items.length,
    itemBuilder: (_, i) {
      final item = items[i];
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.$1, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 2),
          Text(item.$2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      );
    },
  );
}

// ════════════════════════════════════════════════════════════
// UPLOAD / EDIT DIALOG
// ════════════════════════════════════════════════════════════
void _showUploadDialog(BuildContext context, {Map<String, dynamic>? doc}) {
  showDialog(context: context, builder: (_) => _UploadDialog(doc: doc));
}

class _UploadDialog extends StatefulWidget {
  final Map<String, dynamic>? doc;
  const _UploadDialog({this.doc});
  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'other';
  DateTime? _expiryDate;
  int? _vehicleId;
  int? _contactId;
  PlatformFile? _pickedFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      final d = widget.doc!;
      _titleCtrl.text = d['title'] as String? ?? '';
      _notesCtrl.text = d['notes'] as String? ?? '';
      _type = d['document_type'] as String? ?? 'other';
      _vehicleId = d['vehicle'] as int?;
      _contactId = d['contact'] as int?;
      final expStr = d['expiry_date'] as String?;
      if (expStr != null) {
        try { _expiryDate = DateTime.parse(expStr); } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        if (_titleCtrl.text.isEmpty) {
          // Auto-fill title from filename
          final base = _pickedFile!.name.split('.').first;
          _titleCtrl.text = base.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now.add(const Duration(days: 365)), firstDate: now, lastDate: now.add(const Duration(days: 3650)));
    if (picked != null) setState(() => _expiryDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<DocumentsProvider>();
    final isEdit = widget.doc != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Document' : 'Upload Document', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // File picker (create mode only)
          if (!isEdit) ...[
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DomendraTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _pickedFile != null ? DomendraTheme.primary : DomendraTheme.outline),
                ),
                child: Column(children: [
                  Icon(_pickedFile != null ? Icons.check_circle : Icons.upload_file, size: 32, color: _pickedFile != null ? DomendraTheme.primary : DomendraTheme.onSurfaceMuted),
                  const SizedBox(height: 4),
                  Text(_pickedFile != null ? _pickedFile!.name : 'Tap to select file', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _pickedFile != null ? DomendraTheme.primary : DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Images, PDF, Word, Excel, Text', style: TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder(), isDense: true),
            items: typeOptions.map((t) => DropdownMenuItem(value: t.$2, child: Text(t.$1, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _type = v ?? 'other'),
          ),
          const SizedBox(height: 12),
          // Expiry date
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: DomendraTheme.outline), borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: DomendraTheme.onSurfaceMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _expiryDate != null ? _formatDate(_expiryDate.toString()) : 'Expiry date (optional)',
                  style: TextStyle(fontSize: 12, color: _expiryDate != null ? DomendraTheme.onSurface : DomendraTheme.onSurfaceMuted),
                )),
                if (_expiryDate != null)
                  GestureDetector(onTap: () => setState(() => _expiryDate = null), child: const Icon(Icons.clear, size: 16, color: DomendraTheme.onSurfaceMuted)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Vehicle dropdown
          DropdownButtonFormField<int?>(
            value: _vehicleId,
            decoration: const InputDecoration(labelText: 'Vehicle', border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('—', style: TextStyle(fontSize: 12))),
              ...p.vehicles.map((v) {
                final m = v as Map<String, dynamic>;
                final name = m['display_name'] as String? ?? '${m['year'] ?? ''} ${m['make'] ?? ''} ${m['model'] ?? ''}'.trim();
                return DropdownMenuItem<int?>(value: m['id'] as int, child: Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
              }),
            ],
            onChanged: (v) => setState(() => _vehicleId = v),
          ),
          const SizedBox(height: 12),
          // Contact dropdown
          DropdownButtonFormField<int?>(
            value: _contactId,
            decoration: const InputDecoration(labelText: 'Contact / Driver', border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('—', style: TextStyle(fontSize: 12))),
              ...p.contacts.map((c) {
                final m = c as Map<String, dynamic>;
                final name = m['full_name'] as String? ?? m['company_name'] as String? ?? 'Unknown';
                return DropdownMenuItem<int?>(value: m['id'] as int, child: Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis));
              }),
            ],
            onChanged: (v) => setState(() => _contactId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), isDense: true, alignLabelWithHint: true),
            maxLines: 2,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : () async {
            if (_titleCtrl.text.trim().isEmpty) return;
            if (!isEdit && _pickedFile == null) return;
            setState(() => _saving = true);
            try {
              if (isEdit) {
                final data = <String, dynamic>{
                  'title': _titleCtrl.text.trim(),
                  'document_type': _type,
                  'vehicle': _vehicleId,
                  'contact': _contactId,
                  'notes': _notesCtrl.text,
                };
                if (_expiryDate != null) data['expiry_date'] = _expiryDate!.toIso8601String().split('T').first;
                else data['expiry_date'] = null;
                await p.update(widget.doc!['id'] as int, data);
              } else {
                final formData = dio.FormData.fromMap({
                  'title': _titleCtrl.text.trim(),
                  'document_type': _type,
                  'vehicle': _vehicleId,
                  'contact': _contactId,
                  'notes': _notesCtrl.text,
                  if (_expiryDate != null) 'expiry_date': _expiryDate!.toIso8601String().split('T').first,
                });
                formData.files.add(MapEntry('file', await dio.MultipartFile.fromFile(_pickedFile!.path!)));
                await p.create(formData);
              }
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            } finally {
              if (mounted) setState(() => _saving = false);
            }
          },
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Upload'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// DOWNLOAD HELPER
// ════════════════════════════════════════════════════════════
String _resolveMediaUrl(String path) {
  if (path.startsWith('http')) return path;
  final base = AppConfig.apiBase.replaceAll('/api', '');
  return '$base$path';
}

void _downloadFile(BuildContext context, String file) {
  final url = _resolveMediaUrl(file);
  // Use url_launcher via SnackBar for now since the app doesn't have it
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Download: ${url.split('/').last}'), action: SnackBarAction(label: 'Copy URL', onPressed: () {})),
  );
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
String _formatDate(String dateStr) {
  try {
    final d = DateTime.parse(dateStr);
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return dateStr;
  }
}

Color _typeColor(String t) => switch (t) {
  'insurance' => const Color(0xFF3B82F6),
  'registration' => const Color(0xFF06B6D4),
  'title' => const Color(0xFF22C55E),
  'inspection' => const Color(0xFFF59E0B),
  'license' => const Color(0xFF8B5CF6),
  'medical_card' => const Color(0xFFEC4899),
  'warranty' => const Color(0xFF14B8A6),
  'contract' => const Color(0xFF6366F1),
  'permit' => const Color(0xFFF97316),
  'maintenance' => const Color(0xFF06B6D4),
  'other' => const Color(0xFF94A3B8),
  _ => const Color(0xFF94A3B8),
};

IconData _typeIcon(String t) => switch (t) {
  'insurance' => Icons.shield_outlined,
  'registration' => Icons.description,
  'title' => Icons.bookmark_outline,
  'inspection' => Icons.assignment_outlined,
  'license' => Icons.badge_outlined,
  'medical_card' => Icons.health_and_safety_outlined,
  'warranty' => Icons.shield_moon_outlined,
  'contract' => Icons.handshake_outlined,
  'permit' => Icons.confirmation_number,
  'maintenance' => Icons.build,
  'other' => Icons.file_copy_outlined,
  _ => Icons.file_copy_outlined,
};

String _typeLabel(String t) => switch (t) {
  'insurance' => 'Insurance',
  'registration' => 'Registration',
  'title' => 'Title',
  'inspection' => 'Inspection',
  'license' => 'License',
  'medical_card' => 'Medical Card',
  'warranty' => 'Warranty',
  'contract' => 'Contract',
  'permit' => 'Permit',
  'maintenance' => 'Maintenance',
  'other' => 'Other',
  _ => t,
};

IconData _fileTypeIcon(String t) => switch (t) {
  'pdf' => Icons.picture_as_pdf,
  'image' => Icons.image,
  'word' => Icons.description,
  'excel' => Icons.table_chart,
  'text' => Icons.text_snippet,
  _ => Icons.insert_drive_file,
};

Color _fileTypeColor(String t) => switch (t) {
  'pdf' => const Color(0xFFEF4444),
  'image' => const Color(0xFF10B981),
  'word' => const Color(0xFF3B82F6),
  'excel' => const Color(0xFF22C55E),
  'text' => const Color(0xFF6B7280),
  _ => const Color(0xFF94A3B8),
};
