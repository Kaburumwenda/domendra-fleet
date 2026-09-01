import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/reminders_provider.dart';

void showReminderFormDialog(BuildContext context, Reminder? existing) {
  final provider = context.read<RemindersProvider>();
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final vehicleCtrl = TextEditingController(text: existing?.vehicleName ?? '');
  final intervalCtrl = TextEditingController(text: existing?.triggerInterval.toString() ?? '6');
  String? triggerType = existing?.triggerType ?? 'time';
  int escalationLevel = existing?.escalationLevel ?? 0;
  bool autoWO = existing?.autoGenerateWorkOrder ?? false;
  bool isActive = existing?.isActive ?? true;
  DateTime? nextDueDate = existing?.nextDueDate;
  final mileageCtrl = TextEditingController(text: existing?.nextDueMileage?.toString() ?? '');
  final hoursCtrl = TextEditingController(text: existing?.nextDueEngineHours?.toString() ?? '');

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Add Reminder' : 'Edit Reminder'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: triggerType, decoration: const InputDecoration(labelText: 'Trigger Type', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'time', child: Text('Time (Months)')),
          DropdownMenuItem(value: 'mileage', child: Text('Mileage')),
          DropdownMenuItem(value: 'engine_hours', child: Text('Engine Hours')),
        ],
        onChanged: (v) => setState(() => triggerType = v),
      ),
      const SizedBox(height: 10),
      TextField(controller: intervalCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: triggerType == 'time' ? 'Interval (months)' : (triggerType == 'mileage' ? 'Interval (miles)' : 'Interval (hours)'), isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      if (triggerType == 'time')
        ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(nextDueDate != null ? 'Next Due: ${_fmtDate(nextDueDate!)}' : 'Select Next Due Date'), trailing: const Icon(Icons.calendar_today, size: 18), onTap: () async {
          final d = await showDatePicker(context: ctx, initialDate: nextDueDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
          if (d != null) setState(() => nextDueDate = d);
        }),
      if (triggerType == 'mileage')
        TextField(controller: mileageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Next Due Mileage', isDense: true, border: OutlineInputBorder())),
      if (triggerType == 'engine_hours')
        TextField(controller: hoursCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Next Due Hours', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<int>(
        value: escalationLevel, decoration: const InputDecoration(labelText: 'Escalation Level', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 0, child: Text('None')),
          DropdownMenuItem(value: 1, child: Text('Email Driver')),
          DropdownMenuItem(value: 2, child: Text('SMS Manager')),
          DropdownMenuItem(value: 3, child: Text('Block Dispatch')),
        ],
        onChanged: (v) => setState(() => escalationLevel = v ?? 0),
      ),
      const SizedBox(height: 10),
      SwitchListTile(title: const Text('Auto-Generate Work Order'), value: autoWO, onChanged: (v) => setState(() => autoWO = v), dense: true),
      SwitchListTile(title: const Text('Active'), value: isActive, onChanged: (v) => setState(() => isActive = v), dense: true),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        if (titleCtrl.text.isEmpty) return;
        final data = <String, dynamic>{
          'title': titleCtrl.text,
          'vehicle_name': vehicleCtrl.text,
          'trigger_type': triggerType,
          'trigger_interval': int.tryParse(intervalCtrl.text) ?? 6,
          'escalation_level': escalationLevel,
          'auto_generate_work_order': autoWO,
          'is_active': isActive,
          if (triggerType == 'time' && nextDueDate != null) 'next_due_date': nextDueDate!.toIso8601String(),
          if (triggerType == 'mileage' && mileageCtrl.text.isNotEmpty) 'next_due_mileage': int.tryParse(mileageCtrl.text),
          if (triggerType == 'engine_hours' && hoursCtrl.text.isNotEmpty) 'next_due_engine_hours': double.tryParse(hoursCtrl.text),
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) await provider.updateReminder(existing.id!, data);
          else await provider.createReminder(data);
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showReminderDetailDialog(BuildContext context, Reminder r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text(r.title),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Vehicle', r.vehicleName),
      _DetailRow('Trigger', r.triggerTypeLabel),
      _DetailRow('Interval', '${r.triggerInterval} ${r.triggerType == 'time' ? 'months' : (r.triggerType == 'mileage' ? 'miles' : 'hours')}'),
      _DetailRow('Next Due', r.nextDueText),
      _DetailRow('Escalation', r.escalationLabel),
      _DetailRow('Auto WO', r.autoGenerateWorkOrder ? 'Yes' : 'No'),
      _DetailRow('Active', r.isActive ? 'Yes' : 'No'),
      _DetailRow('Due', r.isDue ? 'Yes' : 'No'),
      _DetailRow('Overdue', r.isOverdue ? 'Yes' : 'No'),
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
