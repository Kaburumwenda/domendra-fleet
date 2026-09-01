import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/services_provider.dart';

void showServiceFormDialog(BuildContext context, Service? existing) {
  final provider = context.read<ServicesProvider>();
  final vehicleCtrl = TextEditingController(text: existing?.vehicleName ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final vendorCtrl = TextEditingController(text: existing?.vendorName ?? '');
  final techCtrl = TextEditingController(text: existing?.technicianName ?? '');
  final costCtrl = TextEditingController(text: existing?.cost.toStringAsFixed(0) ?? '0');
  final odoCtrl = TextEditingController(text: existing?.odometerReading?.toString() ?? '');
  DateTime? performedAt = existing?.performedAt;
  String? serviceType = existing?.serviceType ?? 'oil_change';

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Add Service Record' : 'Edit Service'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      DropdownButtonFormField<String>(
        value: serviceType, decoration: const InputDecoration(labelText: 'Service Type *', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'oil_change', child: Text('Oil Change')),
          DropdownMenuItem(value: 'tire_rotation', child: Text('Tire Rotation')),
          DropdownMenuItem(value: 'brake_service', child: Text('Brake Service')),
          DropdownMenuItem(value: 'inspection', child: Text('Inspection')),
          DropdownMenuItem(value: 'repair', child: Text('Repair')),
          DropdownMenuItem(value: 'preventive', child: Text('Preventive Maintenance')),
          DropdownMenuItem(value: 'other', child: Text('Other')),
        ],
        onChanged: (v) => setState(() => serviceType = v),
      ),
      const SizedBox(height: 10),
      TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: vendorCtrl, decoration: const InputDecoration(labelText: 'Vendor', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'Technician', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: odoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Odometer', isDense: true, border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 10),
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(performedAt != null ? 'Date: ${_fmtDate(performedAt!)}' : 'Select Date'),
        trailing: const Icon(Icons.calendar_today, size: 18),
        onTap: () async {
          final d = await showDatePicker(context: ctx, initialDate: performedAt ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
          if (d != null) setState(() => performedAt = d);
        },
      ),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        if (vehicleCtrl.text.isEmpty) return;
        final data = <String, dynamic>{
          'service_type': serviceType,
          'vehicle_name': vehicleCtrl.text,
          'description': descCtrl.text,
          'vendor_name': vendorCtrl.text,
          'technician_name': techCtrl.text,
          'cost': double.tryParse(costCtrl.text) ?? 0,
          if (odoCtrl.text.isNotEmpty) 'odometer_reading': int.tryParse(odoCtrl.text),
          if (performedAt != null) 'performed_at': performedAt!.toIso8601String(),
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) await provider.updateService(existing.id!, data);
          else await provider.createService(data);
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showServiceDetailDialog(BuildContext context, Service s) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text('${s.serviceTypeLabel} - ${s.vehicleName}'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Type', s.serviceTypeLabel),
      _DetailRow('Vehicle', s.vehicleName),
      _DetailRow('Vendor', s.vendorName),
      _DetailRow('Technician', s.technicianName),
      _DetailRow('Cost', 'KSh${s.cost.toStringAsFixed(0)}'),
      if (s.odometerReading != null) _DetailRow('Odometer', '${s.odometerReading} mi'),
      _DetailRow('Downtime', '${s.downtimeHours.toStringAsFixed(1)} hrs'),
      if (s.performedAt != null) _DetailRow('Performed', _fmtDate(s.performedAt!)),
      if (s.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(s.description, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
  ));
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
