import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/equipment_model.dart';
import '../../../providers/equipment_provider.dart';

/// Equipment dialogs — mirrors the web page's 4 dialogs:
///  1. Create/Edit Equipment
///  2. Checkout / Check-in
///  3. Meter Entry
///  4. Calibration Record

// ════════════════════════════════════════════════════════════
// 1. Equipment Form Dialog (Create / Edit)
// ════════════════════════════════════════════════════════════
void showEquipmentFormDialog(BuildContext context, EquipmentItem? item) {
  showDialog(
    context: context,
    builder: (ctx) => _EquipmentFormDialog(item: item),
  );
}

class _EquipmentFormDialog extends StatefulWidget {
  final EquipmentItem? item;
  const _EquipmentFormDialog({this.item});

  @override
  State<_EquipmentFormDialog> createState() => _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends State<_EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{};
  bool _saving = false;
  bool _requiresCalibration = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _data.addAll(widget.item!.raw);
      _requiresCalibration = widget.item!.requiresCalibration;
    } else {
      _data['status'] = 'available';
      _data['calibration_interval_days'] = 365;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<EquipmentProvider>();
      if (widget.item != null && widget.item!.id != null) {
        await provider.updateItem(widget.item!.id!, _data);
      } else {
        await provider.createItem(_data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.item != null ? 'Equipment updated' : 'Equipment created'),
            backgroundColor: DomendraTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final p = context.read<EquipmentProvider>();

    return AlertDialog(
      title: Text(isEdit ? 'Edit Equipment' : 'Add Equipment'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _data['name']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  onChanged: (v) => _data['name'] = v,
                ),
                TextFormField(
                  initialValue: _data['asset_number']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Asset Number *'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  onChanged: (v) => _data['asset_number'] = v,
                ),
                TextFormField(
                  initialValue: _data['serial_number']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Serial Number'),
                  onChanged: (v) => _data['serial_number'] = v,
                ),
                TextFormField(
                  initialValue: _data['barcode']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Barcode'),
                  onChanged: (v) => _data['barcode'] = v,
                ),
                DropdownButtonFormField<String>(
                  value: _data['category']?.toString(),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: p.categories.map((c) {
                    final m = c as Map<String, dynamic>;
                    return DropdownMenuItem(value: m['id']?.toString(), child: Text(m['name']?.toString() ?? ''));
                  }).toList(),
                  onChanged: (v) => _data['category'] = v,
                ),
                DropdownButtonFormField<String>(
                  value: _data['status']?.toString() ?? 'available',
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('Available')),
                    DropdownMenuItem(value: 'in_use', child: Text('In Use')),
                    DropdownMenuItem(value: 'in_maintenance', child: Text('In Maintenance')),
                    DropdownMenuItem(value: 'retired', child: Text('Retired')),
                  ],
                  onChanged: (v) => _data['status'] = v,
                ),
                TextFormField(
                  initialValue: _data['location']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (v) => _data['location'] = v,
                ),
                DropdownButtonFormField<String>(
                  value: _data['assigned_vehicle']?.toString(),
                  decoration: const InputDecoration(labelText: 'Assigned Vehicle'),
                  items: p.vehiclesList.map((v) {
                    final m = v as Map<String, dynamic>;
                    return DropdownMenuItem(value: m['id']?.toString(), child: Text(m['display_name']?.toString() ?? m['make']?.toString() ?? ''));
                  }).toList(),
                  onChanged: (v) => _data['assigned_vehicle'] = v,
                ),
                TextFormField(
                  initialValue: _data['current_hours']?.toString() ?? '0',
                  decoration: const InputDecoration(labelText: 'Hour Meter'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['current_hours'] = double.tryParse(v) ?? 0,
                ),
                TextFormField(
                  initialValue: _data['purchase_price']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Purchase Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['purchase_price'] = double.tryParse(v),
                ),
                TextFormField(
                  initialValue: _data['purchase_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Purchase Date (YYYY-MM-DD)'),
                  onChanged: (v) => _data['purchase_date'] = v,
                ),
                // Requires calibration
                SwitchListTile(
                  title: const Text('Requires Calibration'),
                  value: _requiresCalibration,
                  onChanged: (v) => setState(() {
                    _requiresCalibration = v;
                    _data['requires_calibration'] = v;
                  }),
                  activeColor: DomendraTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_requiresCalibration) ...[
                  TextFormField(
                    initialValue: _data['calibration_interval_days']?.toString() ?? '365',
                    decoration: const InputDecoration(labelText: 'Calibration Interval (days)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _data['calibration_interval_days'] = int.tryParse(v) ?? 365,
                  ),
                  TextFormField(
                    initialValue: _data['next_calibration_due']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Next Calibration Due (YYYY-MM-DD)'),
                    onChanged: (v) => _data['next_calibration_due'] = v,
                  ),
                ],
                TextFormField(
                  initialValue: _data['description']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  onChanged: (v) => _data['description'] = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. Checkout Dialog
// ════════════════════════════════════════════════════════════
void showCheckoutDialog(BuildContext context, EquipmentItem item) {
  showDialog(
    context: context,
    builder: (ctx) => _CheckoutDialog(item: item),
  );
}

class _CheckoutDialog extends StatefulWidget {
  final EquipmentItem item;
  const _CheckoutDialog({required this.item});

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  int? _checkedOutTo;
  String _expectedReturnAt = '';
  String _notes = '';
  bool _saving = false;

  Future<void> _submit() async {
    if (_checkedOutTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a person to check out to'), backgroundColor: DomendraTheme.warning),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final provider = context.read<EquipmentProvider>();
      await provider.checkOut(
        widget.item.id!,
        checkedOutTo: _checkedOutTo!,
        expectedReturnAt: _expectedReturnAt.isNotEmpty ? _expectedReturnAt : null,
        notes: _notes.isNotEmpty ? _notes : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipment checked out'), backgroundColor: DomendraTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<EquipmentProvider>();
    // Filter contacts to drivers only
    final drivers = p.contacts.where((c) {
      final m = c as Map<String, dynamic>;
      final type = m['type']?.toString().toLowerCase() ?? '';
      return type.contains('driver');
    }).toList();
    final allContacts = drivers.isNotEmpty ? drivers : p.contacts;

    return AlertDialog(
      title: Text('Check Out: ${widget.item.displayName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _checkedOutTo,
              decoration: const InputDecoration(labelText: 'Check Out To *'),
              items: allContacts.map((c) {
                final m = c as Map<String, dynamic>;
                final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
                return DropdownMenuItem(value: m['id'] as int?, child: Text(name.isNotEmpty ? name : 'Unknown'));
              }).toList(),
              onChanged: (v) => setState(() => _checkedOutTo = v),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Expected Return (YYYY-MM-DDTHH:MM)'),
              onChanged: (v) => _expectedReturnAt = v,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
              onChanged: (v) => _notes = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Check Out'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. Meter Entry Dialog
// ════════════════════════════════════════════════════════════
void showMeterEntryDialog(BuildContext context, EquipmentItem? item) {
  showDialog(
    context: context,
    builder: (ctx) => _MeterEntryDialog(item: item),
  );
}

class _MeterEntryDialog extends StatefulWidget {
  final EquipmentItem? item;
  const _MeterEntryDialog({this.item});

  @override
  State<_MeterEntryDialog> createState() => _MeterEntryDialogState();
}

class _MeterEntryDialogState extends State<_MeterEntryDialog> {
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();
  int? _selectedEquipmentId;
  bool _saving = false;

  Future<void> _submit() async {
    final hours = double.tryParse(_hoursController.text);
    if (hours == null || hours < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid hours'), backgroundColor: DomendraTheme.warning),
      );
      return;
    }
    final equipId = widget.item?.id ?? _selectedEquipmentId;
    if (equipId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select equipment'), backgroundColor: DomendraTheme.warning),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<EquipmentProvider>().addMeterEntry(
            equipId,
            hours: hours,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meter entry added'), backgroundColor: DomendraTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<EquipmentProvider>();
    return AlertDialog(
      title: const Text('Meter Entry'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.item == null)
              DropdownButtonFormField<int>(
                value: _selectedEquipmentId,
                decoration: const InputDecoration(labelText: 'Equipment *'),
                items: p.items.map((e) {
                  return DropdownMenuItem(value: e.id, child: Text(e.displayName));
                }).toList(),
                onChanged: (v) => setState(() => _selectedEquipmentId = v),
              )
            else
              ListTile(
                title: Text(widget.item!.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Current: ${widget.item!.currentHours.toStringAsFixed(1)} h'),
                leading: const Icon(Icons.build, color: DomendraTheme.primary),
              ),
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(labelText: 'Hour Reading *'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. Calibration Dialog
// ════════════════════════════════════════════════════════════
void showCalibrationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => _CalibrationDialog(),
  );
}

class _CalibrationDialog extends StatefulWidget {
  @override
  State<_CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<_CalibrationDialog> {
  final _calibratedAtController = TextEditingController();
  final _calibratedByController = TextEditingController();
  final _certController = TextEditingController();
  final _notesController = TextEditingController();
  int? _equipmentId;
  String _result = 'pass';
  bool _saving = false;

  Future<void> _submit() async {
    if (_equipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select equipment'), backgroundColor: DomendraTheme.warning),
      );
      return;
    }
    if (_calibratedAtController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calibration date required'), backgroundColor: DomendraTheme.warning),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<EquipmentProvider>().addCalibration({
        'equipment': _equipmentId,
        'calibrated_at': _calibratedAtController.text,
        'result': _result,
        'calibrated_by': _calibratedByController.text,
        'certificate_number': _certController.text,
        'notes': _notesController.text,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calibration recorded'), backgroundColor: DomendraTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<EquipmentProvider>();
    final calibratable = p.items.where((e) => e.requiresCalibration).toList();

    return AlertDialog(
      title: const Text('Add Calibration'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _equipmentId,
              decoration: const InputDecoration(labelText: 'Equipment *'),
              items: calibratable.map((e) {
                return DropdownMenuItem(value: e.id, child: Text(e.displayName));
              }).toList(),
              onChanged: (v) => setState(() => _equipmentId = v),
            ),
            TextFormField(
              controller: _calibratedAtController,
              decoration: const InputDecoration(labelText: 'Calibration Date * (YYYY-MM-DD)'),
            ),
            DropdownButtonFormField<String>(
              value: _result,
              decoration: const InputDecoration(labelText: 'Result'),
              items: const [
                DropdownMenuItem(value: 'pass', child: Text('Pass')),
                DropdownMenuItem(value: 'fail', child: Text('Fail')),
                DropdownMenuItem(value: 'adjusted', child: Text('Adjusted')),
              ],
              onChanged: (v) => setState(() => _result = v ?? 'pass'),
            ),
            TextFormField(
              controller: _calibratedByController,
              decoration: const InputDecoration(labelText: 'Calibrated By'),
            ),
            TextFormField(
              controller: _certController,
              decoration: const InputDecoration(labelText: 'Certificate #'),
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
