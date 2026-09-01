import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/contacts_provider.dart';
import '../widgets/app_drawer.dart';

/// Contacts screen — mirrors web `pages/app/contacts/index.vue`.
/// 3 tabs: All Contacts, Vendors, Staff.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _search = TextEditingController();
  String? _typeFilter;
  String? _activeFilter;

  static const _tabs = [
    Tab(icon: Icon(Icons.contact_page_outlined, size: 18), text: 'All'),
    Tab(icon: Icon(Icons.store_outlined, size: 18), text: 'Vendors'),
    Tab(icon: Icon(Icons.engineering_outlined, size: 18), text: 'Staff'),
  ];

  static const _typeOptions = [
    ('Driver', 'driver'),
    ('Vendor', 'vendor'),
    ('Mechanic', 'mechanic'),
    ('Manager', 'manager'),
    ('Insurance Agent', 'insurance_agent'),
    ('Towing', 'towing'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().refresh();
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
      result = result.where((c) {
        final m = c as Map<String, dynamic>;
        return (m['full_name'] as String? ?? '').toLowerCase().contains(q) ||
            (m['email'] as String? ?? '').toLowerCase().contains(q) ||
            (m['phone'] as String? ?? '').toLowerCase().contains(q) ||
            (m['company_name'] as String? ?? '').toLowerCase().contains(q);
      }).toList();
    }
    if (_typeFilter != null) {
      result = result.where((c) => (c as Map<String, dynamic>)['contact_type'] == _typeFilter).toList();
    }
    if (_activeFilter != null) {
      result = result.where((c) {
        final isActive = (c as Map<String, dynamic>)['is_active'] as bool? ?? false;
        return _activeFilter == 'true' ? isActive : !isActive;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContactsProvider>();
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Contacts'),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: () => p.refresh()),
          IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => _showFormDialog(context)),
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
      drawer: const AppDrawer(currentRoute: '/contacts'),
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
                    hintText: 'Search contacts…',
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
                  ..._typeOptions.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(t.$1, style: TextStyle(fontSize: 10)),
                      selected: _typeFilter == t.$2,
                      onSelected: (v) => setState(() => _typeFilter = v ? t.$2 : null),
                      selectedColor: DomendraTheme.primary,
                      labelStyle: TextStyle(fontSize: 10, color: _typeFilter == t.$2 ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                      backgroundColor: DomendraTheme.surfaceVariant,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: Text('Active', style: TextStyle(fontSize: 10)),
                    selected: _activeFilter == 'true',
                    onSelected: (v) => setState(() => _activeFilter = v ? 'true' : null),
                    selectedColor: const Color(0xFF10B981),
                    labelStyle: TextStyle(fontSize: 10, color: _activeFilter == 'true' ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                    backgroundColor: DomendraTheme.surfaceVariant,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  FilterChip(
                    label: Text('Inactive', style: TextStyle(fontSize: 10)),
                    selected: _activeFilter == 'false',
                    onSelected: (v) => setState(() => _activeFilter = v ? 'false' : null),
                    selectedColor: const Color(0xFF94A3B8),
                    labelStyle: TextStyle(fontSize: 10, color: _activeFilter == 'false' ? Colors.white : DomendraTheme.onSurface, fontWeight: FontWeight.w600),
                    backgroundColor: DomendraTheme.surfaceVariant,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ]),
              ),
            ]),
          ),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _ContactsList(contacts: _filterList(p.contacts)),
              _ContactsList(contacts: _filterList(p.vendorContacts)),
              _ContactsList(contacts: _filterList(p.staffContacts)),
            ],
          )),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ContactFormDialog());
  }
}

class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContactsProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(children: [
        Expanded(child: _Mini(label: 'Total', value: '${p.total}', color: DomendraTheme.primary, icon: Icons.contact_page)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Active', value: '${p.active}', color: const Color(0xFF10B981), icon: Icons.check_circle)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Vendors', value: '${p.vendorCount}', color: const Color(0xFF14B8A6), icon: Icons.store)),
        const SizedBox(width: 4),
        Expanded(child: _Mini(label: 'Drivers', value: '${p.driverCount}', color: const Color(0xFF6366F1), icon: Icons.drive_eta)),
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

class _ContactsList extends StatelessWidget {
  final List<dynamic> contacts;
  const _ContactsList({required this.contacts});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ContactsProvider>();
    if (contacts.isEmpty) return const Center(child: Text('No contacts found', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final c = contacts[i] as Map<String, dynamic>;
        final name = c['full_name'] as String? ?? 'Unknown';
        final email = c['email'] as String? ?? '';
        final phone = c['phone'] as String? ?? '';
        final company = c['company_name'] as String? ?? '';
        final city = c['city'] as String? ?? '';
        final state = c['state'] as String? ?? '';
        final type = c['contact_type'] as String? ?? '—';
        final isActive = c['is_active'] as bool? ?? false;
        final photo = c['photo'] as String?;
        final typeColor = _typeColor(type);
        final vendorRating = c['vendor_profile'] != null
            ? (c['vendor_profile'] as Map<String, dynamic>)['rating'] as num?
            : null;
        final serviceType = c['vendor_profile'] != null
            ? (c['vendor_profile'] as Map<String, dynamic>)['service_type'] as String?
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: photo != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Text('IMG'))
                    : Center(child: Text(_initials(c), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: typeColor))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(email.isNotEmpty ? email : (phone.isNotEmpty ? phone : '—'), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Row(children: [Icon(_typeIcon(type), size: 10, color: typeColor), const SizedBox(width: 2), Text(_typeLabel(type), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeColor))])),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (company.isNotEmpty) _InfoLine(icon: Icons.business, text: company),
                if (city.isNotEmpty || state.isNotEmpty) _InfoLine(icon: Icons.place, text: [city, state].where((s) => s.isNotEmpty).join(', ')),
                if (serviceType != null) _InfoLine(icon: Icons.build, text: serviceType),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8)))),
                if (vendorRating != null) ...[const SizedBox(height: 4), Row(children: [Icon(Icons.star, size: 10, color: const Color(0xFFF59E0B)), const SizedBox(width: 2), Text('${vendorRating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)))])],
              ]),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(onPressed: () => _showFormDialog(context, contact: c), icon: const Icon(Icons.edit, size: 14), label: const Text('Edit', style: TextStyle(fontSize: 11))),
              TextButton.icon(onPressed: () async => p.delete(c['id'] as int), icon: const Icon(Icons.delete, size: 14, color: Colors.red), label: const Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red))),
            ]),
          ]),
        );
      },
    );
  }
}

void _showFormDialog(BuildContext context, {Map<String, dynamic>? contact}) {
  showDialog(context: context, builder: (_) => _ContactFormDialog(contact: contact));
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

class _ContactFormDialog extends StatefulWidget {
  final Map<String, dynamic>? contact;
  const _ContactFormDialog({this.contact});

  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _type = 'vendor';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      final c = widget.contact!;
      _firstNameCtrl.text = c['first_name'] as String? ?? '';
      _lastNameCtrl.text = c['last_name'] as String? ?? '';
      _companyCtrl.text = c['company_name'] as String? ?? '';
      _emailCtrl.text = c['email'] as String? ?? '';
      _phoneCtrl.text = c['phone'] as String? ?? '';
      _cityCtrl.text = c['city'] as String? ?? '';
      _type = c['contact_type'] as String? ?? 'vendor';
      _isActive = c['is_active'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact != null ? 'Edit Contact' : 'New Contact', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder(), isDense: true))),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Contact Type', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: 'driver', child: Text('Driver')),
              DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
              DropdownMenuItem(value: 'mechanic', child: Text('Mechanic')),
              DropdownMenuItem(value: 'manager', child: Text('Manager')),
              DropdownMenuItem(value: 'insurance_agent', child: Text('Insurance Agent')),
              DropdownMenuItem(value: 'towing', child: Text('Towing Company')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'vendor'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Active', style: TextStyle(fontSize: 13)),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            dense: true,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final data = <String, dynamic>{
            'first_name': _firstNameCtrl.text,
            'last_name': _lastNameCtrl.text,
            'company_name': _companyCtrl.text,
            'email': _emailCtrl.text,
            'phone': _phoneCtrl.text,
            'city': _cityCtrl.text,
            'contact_type': _type,
            'is_active': _isActive,
          };
          final p = context.read<ContactsProvider>();
          await p.save(data, widget.contact?['id'] as int?);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
String _initials(Map<String, dynamic> c) {
  final f = (c['first_name'] as String?) ?? '';
  final l = (c['last_name'] as String?) ?? '';
  final result = '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}';
  return result.toUpperCase().isEmpty ? '?' : result.toUpperCase();
}

Color _typeColor(String t) => switch (t) {
  'driver' => const Color(0xFF6366F1),
  'vendor' => const Color(0xFF14B8A6),
  'mechanic' => const Color(0xFFF59E0B),
  'manager' => const Color(0xFF8B5CF6),
  'insurance_agent' => const Color(0xFF06B6D4),
  'towing' => const Color(0xFFEF4444),
  _ => const Color(0xFF94A3B8),
};

IconData _typeIcon(String t) => switch (t) {
  'driver' => Icons.drive_eta,
  'vendor' => Icons.store,
  'mechanic' => Icons.build,
  'manager' => Icons.person_4,
  'insurance_agent' => Icons.shield,
  'towing' => Icons.local_shipping,
  _ => Icons.person,
};

String _typeLabel(String t) => switch (t) {
  'driver' => 'Driver',
  'vendor' => 'Vendor',
  'mechanic' => 'Mechanic',
  'manager' => 'Manager',
  'insurance_agent' => 'Insurance',
  'towing' => 'Towing',
  _ => t,
};
