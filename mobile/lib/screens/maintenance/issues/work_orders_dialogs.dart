import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/issues_provider.dart';

void showWorkOrderFormDialog(BuildContext context, WorkOrder? existing) {
  final provider = context.read<IssuesProvider>();
  final issueIdCtrl = TextEditingController(text: existing?.issueId?.toString() ?? '');
  final assignedToIdCtrl = TextEditingController(text: existing?.assignedTo?.toString() ?? '');
  final estCostCtrl = TextEditingController(text: existing?.estimatedCost.toStringAsFixed(0) ?? '0');
  final actualCostCtrl = TextEditingController(text: existing?.actualCost.toStringAsFixed(0) ?? '0');
  final internalNotesCtrl = TextEditingController(text: existing?.internalNotes ?? '');
  final externalNotesCtrl = TextEditingController(text: existing?.externalNotes ?? '');
  String? status = existing?.status ?? 'open';
  String? assignmentType = existing?.assignmentType ?? 'internal';

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Create Work Order' : 'Edit Work Order'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      TextField(controller: issueIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Issue ID *', helperText: 'The issue this work order is for', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: assignmentType, decoration: const InputDecoration(labelText: 'Assignment Type', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'internal', child: Text('Internal Mechanic')),
          DropdownMenuItem(value: 'external', child: Text('External Shop')),
        ],
        onChanged: (v) => setState(() => assignmentType = v),
      ),
      const SizedBox(height: 10),
      TextField(controller: assignedToIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Assigned To (Contact ID)', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: status, decoration: const InputDecoration(labelText: 'Status', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'open', child: Text('Open')),
          DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
          DropdownMenuItem(value: 'parts_ordered', child: Text('Parts Ordered')),
          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
          DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
          DropdownMenuItem(value: 'completed', child: Text('Completed')),
          DropdownMenuItem(value: 'closed', child: Text('Closed')),
        ],
        onChanged: (v) => setState(() => status = v),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: estCostCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Est. Cost', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: actualCostCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Cost', isDense: true, border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 10),
      TextField(controller: internalNotesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Internal Notes', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: externalNotesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'External Notes', isDense: true, border: OutlineInputBorder())),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        if (issueIdCtrl.text.isEmpty) return;
        final data = <String, dynamic>{
          'issue': int.tryParse(issueIdCtrl.text),
          'assignment_type': assignmentType,
          if (assignedToIdCtrl.text.isNotEmpty) 'assigned_to': int.tryParse(assignedToIdCtrl.text),
          'status': status,
          'estimated_cost': double.tryParse(estCostCtrl.text) ?? 0,
          if (existing != null) 'actual_cost': double.tryParse(actualCostCtrl.text) ?? 0,
          'internal_notes': internalNotesCtrl.text,
          'external_notes': externalNotesCtrl.text,
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) {
            await provider.updateWorkOrder(existing.id!, data);
          } else {
            await provider.createWorkOrder(data);
          }
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showWorkOrderDetailDialog(BuildContext context, WorkOrder wo) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text(wo.issueTitle.isEmpty ? 'Work Order #${wo.id}' : wo.issueTitle),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Vehicle', wo.vehicleName),
      _DetailRow('Status', wo.statusLabel),
      _DetailRow('Assignment', wo.assignmentTypeLabel),
      _DetailRow('Assigned To', wo.assignedToName),
      _DetailRow('Est. Cost', 'KSh${wo.estimatedCost.toStringAsFixed(0)}'),
      _DetailRow('Actual Cost', 'KSh${wo.actualCost.toStringAsFixed(0)}'),
      _DetailRow('Parts Cost', 'KSh${wo.partsCost.toStringAsFixed(0)}'),
      _DetailRow('Labor Cost', 'KSh${wo.laborCost.toStringAsFixed(0)}'),
      _DetailRow('Total Cost', 'KSh${wo.totalCost.toStringAsFixed(0)}'),
      _DetailRow('Downtime', '${wo.downtimeHours.toStringAsFixed(1)} hrs'),
      if (wo.startedAt != null) _DetailRow('Started', _fmtDate(wo.startedAt!)),
      if (wo.completedAt != null) _DetailRow('Completed', _fmtDate(wo.completedAt!)),
      if (wo.internalNotes.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(wo.internalNotes, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
    ])),
    actions: [
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

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
