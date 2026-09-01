import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/issues_provider.dart';

void showIssueFormDialog(BuildContext context, Issue? existing) {
  final provider = context.read<IssuesProvider>();
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final vehicleIdCtrl = TextEditingController(text: existing?.vehicleId?.toString() ?? '');
  String? status = existing?.status ?? 'open';
  String? priority = existing?.priority ?? 'medium';

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Report Issue' : 'Edit Issue'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: vehicleIdCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Vehicle ID *', helperText: existing?.vehicleName ?? 'The vehicle this issue is for', isDense: true, border: const OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: status, decoration: const InputDecoration(labelText: 'Status', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'open', child: Text('Open')),
          DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
          DropdownMenuItem(value: 'parts_ordered', child: Text('Parts Ordered')),
          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
          DropdownMenuItem(value: 'closed', child: Text('Closed')),
        ],
        onChanged: (v) => setState(() => status = v),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: priority, decoration: const InputDecoration(labelText: 'Priority', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'low', child: Text('Low')),
          DropdownMenuItem(value: 'medium', child: Text('Medium')),
          DropdownMenuItem(value: 'high', child: Text('High')),
          DropdownMenuItem(value: 'critical', child: Text('Critical')),
        ],
        onChanged: (v) => setState(() => priority = v),
      ),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        if (titleCtrl.text.isEmpty) return;
        final data = <String, dynamic>{
          'title': titleCtrl.text,
          'description': descCtrl.text,
          'vehicle': int.tryParse(vehicleIdCtrl.text),
          'status': status,
          'priority': priority,
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) {
            await provider.updateIssue(existing.id!, data);
          } else {
            await provider.createIssue(data);
          }
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showIssueDetailDialog(BuildContext context, Issue issue) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text(issue.title),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Vehicle', issue.vehicleName),
      _DetailRow('Status', issue.statusLabel),
      _DetailRow('Priority', issue.priorityLabel),
      _DetailRow('Reported By', issue.reportedByName),
      _DetailRow('Has Work Order', issue.hasWorkOrder ? 'Yes' : 'No'),
      if (issue.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(issue.description, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
      if (issue.photos.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('${issue.photos.length} photo(s) attached'),
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
