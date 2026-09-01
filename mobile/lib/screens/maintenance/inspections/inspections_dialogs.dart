import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/inspections_provider.dart';

void showInspectionReportFormDialog(BuildContext context, InspectionReport? existing) {
  final provider = context.read<InspectionsProvider>();
  final vehicleCtrl = TextEditingController(text: existing?.vehicleName ?? '');
  final driverCtrl = TextEditingController(text: existing?.driverName ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  final odoCtrl = TextEditingController(text: existing?.odometerReading?.toString() ?? '');
  String? status = existing?.status ?? 'draft';
  InspectionForm? selectedForm;

  // Use first available form if existing
  if (existing != null && provider.forms.isNotEmpty) {
    final idx = provider.forms.indexWhere((f) => f.id == existing.formId);
    if (idx >= 0) selectedForm = provider.forms[idx];
  }

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Create Inspection Report' : 'Edit Report'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      if (provider.forms.isNotEmpty) ...[
        DropdownButtonFormField<int>(
          value: selectedForm?.id, decoration: const InputDecoration(labelText: 'Form', isDense: true, border: OutlineInputBorder()),
          items: provider.forms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
          onChanged: (v) { final idx = provider.forms.indexWhere((f) => f.id == v); if (idx >= 0) setState(() => selectedForm = provider.forms[idx]); },
        ),
        const SizedBox(height: 10),
      ],
      TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: status, decoration: const InputDecoration(labelText: 'Status', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'draft', child: Text('Draft')),
          DropdownMenuItem(value: 'pass', child: Text('Passed')),
          DropdownMenuItem(value: 'fail', child: Text('Failed')),
          DropdownMenuItem(value: 'conditional', child: Text('Conditional')),
        ],
        onChanged: (v) => setState(() => status = v),
      ),
      const SizedBox(height: 10),
      TextField(controller: odoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Odometer', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes', isDense: true, border: OutlineInputBorder())),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        final data = <String, dynamic>{
          'vehicle_name': vehicleCtrl.text,
          'driver_name': driverCtrl.text,
          'status': status,
          'notes': notesCtrl.text,
          if (odoCtrl.text.isNotEmpty) 'odometer_reading': int.tryParse(odoCtrl.text),
          if (selectedForm != null) 'form': selectedForm!.id,
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) await provider.updateReport(existing.id!, data);
          else await provider.createReport(data);
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showInspectionReportDetailDialog(BuildContext context, InspectionReport r) {
  final statusColor = _statusColor(r.status);
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text('${r.vehicleName} - ${r.statusLabel}'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Form', r.formName),
      _DetailRow('Vehicle', r.vehicleName),
      _DetailRow('Driver', r.driverName),
      _DetailRow('Status', r.statusLabel),
      if (r.odometerReading != null) _DetailRow('Odometer', '${r.odometerReading} mi'),
      if (r.submittedAt != null) _DetailRow('Submitted', _fmtDate(r.submittedAt!)),
      _DetailRow('Fail Count', '${r.failCount}'),
      _DetailRow('Critical Fails', '${r.criticalFailCount}'),
      if (r.notes.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(r.notes, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
      if (r.responses.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Responses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ...r.responses.map((resp) {
          final r2 = resp as Map<String, dynamic>;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
            Expanded(child: Text(r2['item_label']?.toString() ?? r2['label']?.toString() ?? 'Item', style: const TextStyle(fontSize: 11))),
            Text(r2['value']?.toString() ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r2['is_fail'] == true ? Colors.red : DomendraTheme.onSurfaceMuted)),
          ]));
        }),
      ],
    ])),
    actions: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(r.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
    ],
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

Color _statusColor(String s) {
  switch (s) {
    case 'pass': return const Color(0xFF10b981);
    case 'fail': return const Color(0xFFef4444);
    case 'conditional': return const Color(0xFFf59e0b);
    case 'draft': return const Color(0xFF6b7280);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
