import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/garage_provider.dart';

void showGarageBayFormDialog(BuildContext context, GarageBay? existing) {
  final provider = context.read<GarageProvider>();
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  final capCtrl = TextEditingController(text: existing?.capacity.toString() ?? '1');
  String? bayType = existing?.bayType ?? 'lift';
  bool isActive = existing?.isActive ?? true;

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Add Garage Bay' : 'Edit Bay'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Bay Name *', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: bayType, decoration: const InputDecoration(labelText: 'Bay Type', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'lift', child: Text('Lift Bay')),
          DropdownMenuItem(value: 'flat', child: Text('Flat Bay')),
          DropdownMenuItem(value: 'paint', child: Text('Paint Bay')),
          DropdownMenuItem(value: 'wash', child: Text('Wash Bay')),
          DropdownMenuItem(value: 'inspection', child: Text('Inspection Bay')),
          DropdownMenuItem(value: 'general', child: Text('General Bay')),
        ],
        onChanged: (v) => setState(() => bayType = v),
      ),
      const SizedBox(height: 10),
      TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setState(() => isActive = v), dense: true),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        if (nameCtrl.text.isEmpty) return;
        final data = <String, dynamic>{
          'name': nameCtrl.text,
          'bay_type': bayType,
          'capacity': int.tryParse(capCtrl.text) ?? 1,
          'notes': notesCtrl.text,
          'is_active': isActive,
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) await provider.updateBay(existing.id!, data);
          else await provider.createBay(data);
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showBayReservationFormDialog(BuildContext context, BayReservation? existing) {
  final provider = context.read<GarageProvider>();
  final bayCtrl = TextEditingController(text: existing?.bayName ?? '');
  final vehicleCtrl = TextEditingController(text: existing?.vehicleName ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  String? status = existing?.status ?? 'scheduled';
  DateTime? startTime = existing?.startTime;
  DateTime? endTime = existing?.endTime;

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Create Reservation' : 'Edit Reservation'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      TextField(controller: bayCtrl, decoration: const InputDecoration(labelText: 'Bay Name', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: status, decoration: const InputDecoration(labelText: 'Status', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'completed', child: Text('Completed')),
          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
        ],
        onChanged: (v) => setState(() => status = v),
      ),
      const SizedBox(height: 10),
      ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(startTime != null ? 'Start: ${_fmtDT(startTime!)}' : 'Select Start Time'), trailing: const Icon(Icons.calendar_today, size: 18), onTap: () async {
        final d = await showDatePicker(context: ctx, initialDate: startTime ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime(2100));
        if (d != null) {
          final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(startTime ?? DateTime.now()));
          if (t != null) setState(() => startTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
        }
      }),
      ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(endTime != null ? 'End: ${_fmtDT(endTime!)}' : 'Select End Time'), trailing: const Icon(Icons.calendar_today, size: 18), onTap: () async {
        final d = await showDatePicker(context: ctx, initialDate: endTime ?? startTime ?? DateTime.now(), firstDate: startTime ?? DateTime.now(), lastDate: DateTime(2100));
        if (d != null) {
          final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(endTime ?? DateTime.now()));
          if (t != null) setState(() => endTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
        }
      }),
      const SizedBox(height: 10),
      TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', isDense: true, border: OutlineInputBorder())),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        final data = <String, dynamic>{
          'bay_name': bayCtrl.text,
          'vehicle_name': vehicleCtrl.text,
          'status': status,
          'notes': notesCtrl.text,
          if (startTime != null) 'start_time': startTime!.toIso8601String(),
          if (endTime != null) 'end_time': endTime!.toIso8601String(),
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) await provider.updateReservation(existing.id!, data);
          else await provider.createReservation(data);
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showBayReservationDetailDialog(BuildContext context, BayReservation r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text('Reservation - ${r.vehicleName}'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Bay', r.bayName),
      _DetailRow('Vehicle', r.vehicleName),
      _DetailRow('Status', r.statusLabel),
      if (r.startTime != null) _DetailRow('Start', _fmtDT(r.startTime!)),
      if (r.endTime != null) _DetailRow('End', _fmtDT(r.endTime!)),
      _DetailRow('Duration', '${r.durationHours.toStringAsFixed(1)} hrs'),
      if (r.notes.isNotEmpty) _DetailRow('Notes', r.notes),
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

String _fmtDT(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
