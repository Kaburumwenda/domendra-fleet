import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/recalls_provider.dart';

void showRecallFormDialog(BuildContext context, Recall? existing) {
  final provider = context.read<RecallsProvider>();
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final nhtsaCtrl = TextEditingController(text: existing?.nhtsaCampaignNumber ?? '');
  final mfrCtrl = TextEditingController(text: existing?.manufacturerCampaignNumber ?? '');
  final oemCtrl = TextEditingController(text: existing?.oem ?? '');
  final componentCtrl = TextEditingController(text: existing?.component ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final remedyCtrl = TextEditingController(text: existing?.remedy ?? '');
  final riskCtrl = TextEditingController(text: existing?.risk ?? '');
  final makeCtrl = TextEditingController(text: existing?.affectedMake ?? '');
  final modelsCtrl = TextEditingController(text: existing?.affectedModels ?? '');
  final yearFromCtrl = TextEditingController(text: existing?.affectedYearFrom?.toString() ?? '');
  final yearToCtrl = TextEditingController(text: existing?.affectedYearTo?.toString() ?? '');
  String? recallType = existing?.recallType ?? 'safety_recall';
  String? status = existing?.status ?? 'open';
  bool isCritical = existing?.isCritical ?? false;
  DateTime? issueDate = existing?.issueDate;

  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
    title: Text(existing == null ? 'Add Recall' : 'Edit Recall'),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: recallType, decoration: const InputDecoration(labelText: 'Recall Type', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'safety_recall', child: Text('Safety Recall')),
          DropdownMenuItem(value: 'campaign', child: Text('Service Campaign')),
          DropdownMenuItem(value: 'field_notice', child: Text('Field Notice')),
          DropdownMenuItem(value: 'emission', child: Text('Emission')),
        ],
        onChanged: (v) => setState(() => recallType = v),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: status, decoration: const InputDecoration(labelText: 'Status', isDense: true, border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'open', child: Text('Open')),
          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
          DropdownMenuItem(value: 'completed', child: Text('Completed')),
          DropdownMenuItem(value: 'closed', child: Text('Closed')),
        ],
        onChanged: (v) => setState(() => status = v),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: nhtsaCtrl, decoration: const InputDecoration(labelText: 'NHTSA #', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: mfrCtrl, decoration: const InputDecoration(labelText: 'Mfr #', isDense: true, border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: oemCtrl, decoration: const InputDecoration(labelText: 'OEM', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: componentCtrl, decoration: const InputDecoration(labelText: 'Component', isDense: true, border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 10),
      TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: remedyCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Remedy', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      TextField(controller: riskCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Risk', isDense: true, border: OutlineInputBorder())),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: makeCtrl, decoration: const InputDecoration(labelText: 'Make', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: modelsCtrl, decoration: const InputDecoration(labelText: 'Models', isDense: true, border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: yearFromCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year From', isDense: true, border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: yearToCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year To', isDense: true, border: OutlineInputBorder()))),
      ]),
      const SizedBox(height: 10),
      ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(issueDate != null ? 'Issue Date: ${_fmtDate(issueDate!)}' : 'Select Issue Date'), trailing: const Icon(Icons.calendar_today, size: 18), onTap: () async {
        final d = await showDatePicker(context: ctx, initialDate: issueDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (d != null) setState(() => issueDate = d);
      }),
      const SizedBox(height: 10),
      SwitchListTile(title: const Text('Critical'), value: isCritical, onChanged: (v) => setState(() => isCritical = v), dense: true),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () async {
        if (titleCtrl.text.isEmpty) return;
        final data = <String, dynamic>{
          'title': titleCtrl.text,
          'recall_type': recallType,
          'status': status,
          'nhtsa_campaign_number': nhtsaCtrl.text,
          'manufacturer_campaign_number': mfrCtrl.text,
          'oem': oemCtrl.text,
          'component': componentCtrl.text,
          'description': descCtrl.text,
          'remedy': remedyCtrl.text,
          'risk': riskCtrl.text,
          'affected_make': makeCtrl.text,
          'affected_models': modelsCtrl.text,
          if (yearFromCtrl.text.isNotEmpty) 'affected_year_from': int.tryParse(yearFromCtrl.text),
          if (yearToCtrl.text.isNotEmpty) 'affected_year_to': int.tryParse(yearToCtrl.text),
          if (issueDate != null) 'issue_date': issueDate!.toIso8601String(),
          'is_critical': isCritical,
        };
        Navigator.pop(ctx);
        try {
          if (existing != null) await provider.updateRecall(existing.id!, data);
          else await provider.createRecall(data);
        } catch (e) {
          if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }, child: Text(existing == null ? 'Create' : 'Save')),
    ],
  )));
}

void showRecallDetailDialog(BuildContext context, Recall r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: Text(r.title),
    content: SizedBox(width: 400, child: ListView(shrinkWrap: true, children: [
      _DetailRow('Type', r.recallTypeLabel),
      _DetailRow('Status', r.statusLabel),
      _DetailRow('OEM', r.oem),
      _DetailRow('Component', r.component),
      _DetailRow('NHTSA #', r.nhtsaCampaignNumber),
      _DetailRow('Mfr #', r.manufacturerCampaignNumber),
      _DetailRow('Critical', r.isCritical ? 'Yes' : 'No'),
      if (r.issueDate != null) _DetailRow('Issue Date', _fmtDate(r.issueDate!)),
      _DetailRow('Affected', '${r.affectedCount} vehicles'),
      _DetailRow('Resolved', '${r.resolvedCount} vehicles'),
      if (r.affectedMake.isNotEmpty) _DetailRow('Make', r.affectedMake),
      if (r.affectedModels.isNotEmpty) _DetailRow('Models', r.affectedModels),
      if (r.affectedYearFrom != null) _DetailRow('Year From', '${r.affectedYearFrom}'),
      if (r.affectedYearTo != null) _DetailRow('Year To', '${r.affectedYearTo}'),
      if (r.description.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(r.description, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
      if (r.remedy.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Remedy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(r.remedy, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
      if (r.risk.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Risk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(r.risk, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
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
      Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 12))),
    ]),
  );
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
