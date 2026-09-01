import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/tire_model.dart';
import '../../../providers/tire_provider.dart';

/// Show the add/edit tire form dialog.
void showTireFormDialog(BuildContext context, Tire? existing) {
  final p = context.read<TireProvider>();
  final isEdit = existing != null;

  final serialCtrl = TextEditingController(text: existing?.serialNumber ?? '');
  final brandCtrl = TextEditingController(text: existing?.brand ?? '');
  final modelCtrl = TextEditingController(text: existing?.model ?? '');
  final sizeCtrl = TextEditingController(text: existing?.size ?? '');
  final priceCtrl = TextEditingController(text: existing?.purchasePrice?.toStringAsFixed(0) ?? '');
  final dateCtrl = TextEditingController(text: existing?.purchaseDate != null ? _dateToStr(existing!.purchaseDate!) : '');
  final warrantyCtrl = TextEditingController(text: existing?.warrantyMiles?.toStringAsFixed(0) ?? '');
  final minTreadCtrl = TextEditingController(text: (existing?.minTreadDepth ?? 4).toStringAsFixed(0));

  String type = existing?.type ?? '';
  String condition = existing != null ? _conditionToValue(existing.condition) : 'new';
  String status = existing != null ? _statusToValue(existing.status) : 'in_stock';

  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialog) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Tire' : 'Add Tire'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errors.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList(),
                      ),
                    ),
                  ],
                  const Text('Fields marked * are required.', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  const SizedBox(height: 12),
                  TextField(controller: serialCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Serial Number *', prefixIcon: Icon(Icons.qr_code_2)), textCapitalization: TextCapitalization.characters),
                  const SizedBox(height: 8),
                  _ComboField(controller: brandCtrl, label: 'Brand', items: p.brandOptions, icon: Icons.factory_outlined),
                  const SizedBox(height: 8),
                  _ComboField(controller: modelCtrl, label: 'Model', items: p.modelOptions),
                  const SizedBox(height: 8),
                  _ComboField(controller: sizeCtrl, label: 'Size', items: p.sizeOptions, icon: Icons.straighten),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type.isNotEmpty ? type : null,
                    decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.tire_repair)),
                    items: const ['Steer', 'Drive', 'Trailer', 'All-Position', 'Spare']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialog(() => type = v ?? ''),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: condition,
                    decoration: const InputDecoration(labelText: 'Condition', prefixIcon: Icon(Icons.circle)),
                    items: const [
                      DropdownMenuItem(value: 'new', child: Text('New')),
                      DropdownMenuItem(value: 'second_hand', child: Text('Second Hand')),
                      DropdownMenuItem(value: 'retreaded', child: Text('Retreaded')),
                      DropdownMenuItem(value: 'reclaimed', child: Text('Reclaimed')),
                      DropdownMenuItem(value: 'used', child: Text('Used')),
                    ],
                    onChanged: (v) { if (v != null) setDialog(() => condition = v); },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.swap_horiz)),
                    items: const [
                      DropdownMenuItem(value: 'in_stock', child: Text('In Stock')),
                      DropdownMenuItem(value: 'mounted', child: Text('Mounted')),
                      DropdownMenuItem(value: 'spare', child: Text('Spare')),
                      DropdownMenuItem(value: 'retired', child: Text('Retired')),
                      DropdownMenuItem(value: 'scrapped', child: Text('Scrapped')),
                    ],
                    onChanged: (v) { if (v != null) setDialog(() => status = v); },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date'), readOnly: true, onTap: () async {
                        final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (d != null) dateCtrl.text = _dateToStr(d);
                      })),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: warrantyCtrl, decoration: const InputDecoration(labelText: 'Warranty Miles'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: minTreadCtrl, decoration: const InputDecoration(labelText: 'Min Tread /32"'), keyboardType: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (serialCtrl.text.trim().isEmpty) {
                  setDialog(() => errors = ['Serial number is required.']);
                  return;
                }
                setDialog(() { saving = true; errors = []; });
                final payload = <String, dynamic>{
                  'serial_number': serialCtrl.text.trim(),
                  'brand': brandCtrl.text.trim(),
                  'model': modelCtrl.text.trim(),
                  'size': sizeCtrl.text.trim(),
                  'type': type,
                  'condition': condition,
                  'status': status,
                  'purchase_price': double.tryParse(priceCtrl.text),
                  'purchase_date': dateCtrl.text.isNotEmpty ? dateCtrl.text : null,
                  'warranty_miles': double.tryParse(warrantyCtrl.text),
                  'min_tread_depth': double.tryParse(minTreadCtrl.text) ?? 4,
                };
                try {
                  if (isEdit && existing.id != null) {
                    await p.updateTire(existing.id!, payload);
                  } else {
                    await p.createTire(payload);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setDialog(() { saving = false; errors = [e.toString()]; });
                }
              },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Save'),
            ),
          ],
        );
      });
    },
  );
}

/// Show the tire detail dialog.
void showTireDetailDialog(BuildContext context, Tire tire) {
  final p = context.read<TireProvider>();
  final inspections = p.inspections.where((i) => i.tireId == tire.id).take(5).toList();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.tire_repair, color: DomendraTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(tire.serialNumber, style: const TextStyle(fontSize: 16))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _tireStatusColor(tire.status).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(tire.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _tireStatusColor(tire.status))),
                  ),
                  const Spacer(),
                  if (tire.needsReplacement)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: DomendraTheme.danger, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Needs Replacement', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _SpecRow('Brand', '${tire.brand} ${tire.model}'.trim()),
              _SpecRow('Size', tire.size),
              _SpecRow('Type', tire.type),
              _SpecRow('Condition', tire.conditionLabel),
              _SpecRow('Vehicle', tire.vehicleName),
              _SpecRow('Position', tire.position),
              _SpecRow('Latest Tread', tire.latestTreadDepth != null ? '${tire.latestTreadDepth!.toStringAsFixed(1)}/32"' : '—'),
              _SpecRow('Total Miles', tire.totalMiles.toStringAsFixed(0)),
              _SpecRow('Purchase Date', _dateToStr2(tire.purchaseDate)),
              _SpecRow('Purchase Price', tire.purchasePrice != null ? '${tire.purchasePrice!.toStringAsFixed(0)}' : '—'),
              _SpecRow('Warranty Miles', tire.warrantyMiles?.toStringAsFixed(0) ?? '—'),
              _SpecRow('Min Tread', '${tire.minTreadDepth.toStringAsFixed(0)}/32"'),
              if (tire.lastMountDate != null)
                _SpecRow('Mounted On', _dateToStr2(tire.lastMountDate)),
              if (tire.retiredDate != null)
                _SpecRow('Retired On', _dateToStr2(tire.retiredDate)),
              // Recent inspections
              if (inspections.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Recent Inspections', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...inspections.map((ins) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: DomendraTheme.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _inspectionCondColor(ins.condition).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(ins.condition.isEmpty ? 'OK' : ins.condition[0].toUpperCase() + ins.condition.substring(1),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _inspectionCondColor(ins.condition))),
                          ),
                          const SizedBox(width: 8),
                          Text('${ins.treadDepth.toStringAsFixed(1)}/32"', style: const TextStyle(fontSize: 12)),
                          if (ins.pressurePsi != null)
                            Text(' · ${ins.pressurePsi!.toStringAsFixed(0)} psi', style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
                        ],
                      ),
                      Text(_dateToStr2(ins.measuredAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        FilledButton.tonal(onPressed: () { Navigator.pop(ctx); showTireFormDialog(context, tire); }, child: const Text('Edit')),
      ],
    ),
  );
}

/// Show the mount tire dialog.
void showMountDialog(BuildContext context, Tire tire) {
  final p = context.read<TireProvider>();
  int? vehicleId;
  String position = '';
  double? odometer;
  String notes = '';
  bool saving = false;

  const positions = ['FL_Outer', 'FL_Inner', 'FR_Outer', 'FR_Inner', 'RL_Outer', 'RL_Inner', 'RR_Outer', 'RR_Inner', 'Spare'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text('Mount ${tire.serialNumber}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: vehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car)),
                items: p.vehicles.map<DropdownMenuItem<int>>((v) {
                  final m = v as Map<String, dynamic>;
                  final id = m['id'] as int?;
                  final name = m['display_name']?.toString() ?? m['license_plate']?.toString() ?? 'Vehicle #$id';
                  return DropdownMenuItem<int>(value: id, child: Text(name, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setDialog(() => vehicleId = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: position.isNotEmpty ? position : null,
                decoration: const InputDecoration(labelText: 'Position *', prefixIcon: Icon(Icons.location_on_outlined)),
                items: positions.map((pos) => DropdownMenuItem(value: pos, child: Text(_formatPosition(pos)))).toList(),
                onChanged: (v) { if (v != null) setDialog(() => position = v); },
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Odometer'),
                keyboardType: TextInputType.number,
                onChanged: (v) => odometer = double.tryParse(v),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
                onChanged: (v) => notes = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              if (vehicleId == null || position.isEmpty || tire.id == null) return;
              setDialog(() => saving = true);
              final ok = await p.mountTire(tire.id!, vehicleId: vehicleId!, position: position, odometer: odometer, notes: notes.isNotEmpty ? notes : null);
              if (ctx.mounted) {
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tire mounted'), backgroundColor: DomendraTheme.success));
                } else {
                  setDialog(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mount failed: ${p.error ?? ""}'), backgroundColor: DomendraTheme.danger));
                }
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Mount'),
          ),
        ],
      );
    }),
  );
}

/// Show the reason dialog (Unmount / Retire).
void showReasonDialog(BuildContext context, {required String action, required Tire tire}) {
  final p = context.read<TireProvider>();
  final isUnmount = action == 'unmount';
  final title = isUnmount ? 'Unmount ${tire.serialNumber}' : 'Retire ${tire.serialNumber}';
  final reasonLabel = isUnmount ? 'Reason for unmounting' : 'Reason for retiring';
  final confirmText = isUnmount ? 'Unmount' : 'Retire';
  final confirmColor = isUnmount ? DomendraTheme.warning : DomendraTheme.danger;

  final reasonCtrl = TextEditingController();
  bool saving = false;

  final options = isUnmount
      ? ['Seasonal changeover', 'Rotation', 'Tread below threshold', 'Damage / puncture', 'Repair needed', 'Vehicle change', 'Storage']
      : ['Tread worn out', 'Sidewall damage', 'Beyond repair', 'Age / dry rot', 'Irreparable puncture', 'Failed inspection', 'End of lifecycle'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${tire.serialNumber} — ${tire.brand} ${tire.model}', style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: (isUnmount ? DomendraTheme.warning : DomendraTheme.danger).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  isUnmount
                      ? '${tire.serialNumber} will be removed from its vehicle and returned to in-stock inventory.'
                      : '${tire.serialNumber} will be marked retired and no longer tracked.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(labelText: reasonLabel, prefixIcon: const Icon(Icons.note)),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              const Text('Quick select', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: options.map((opt) => GestureDetector(
                  onTap: () { reasonCtrl.text = opt; setDialog(() {}); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reasonCtrl.text == opt ? confirmColor.withOpacity(0.15) : DomendraTheme.surfaceVariant,
                      border: Border.all(color: reasonCtrl.text == opt ? confirmColor : Colors.transparent),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(opt, style: TextStyle(fontSize: 10, color: reasonCtrl.text == opt ? confirmColor : DomendraTheme.onSurfaceMuted)),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            onPressed: saving || reasonCtrl.text.trim().isEmpty ? null : () async {
              if (tire.id == null) return;
              setDialog(() => saving = true);
              final ok = isUnmount
                  ? await p.unmountTire(tire.id!, notes: reasonCtrl.text.trim())
                  : await p.retireTire(tire.id!, notes: reasonCtrl.text.trim());
              if (ctx.mounted) {
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmText), backgroundColor: DomendraTheme.success));
                } else {
                  setDialog(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$confirmText failed'), backgroundColor: DomendraTheme.danger));
                }
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(confirmText),
          ),
        ],
      );
    }),
  );
}

/// Show the inspection form dialog.
void showInspectionFormDialog(BuildContext context, TireInspection? existing) {
  final p = context.read<TireProvider>();
  final isEdit = existing != null;

  int? tireId = existing?.tireId;
  int? vehicleId = existing?.vehicleId;
  final treadCtrl = TextEditingController(text: existing?.treadDepth.toStringAsFixed(1) ?? '');
  final pressureCtrl = TextEditingController(text: existing?.pressurePsi?.toStringAsFixed(1) ?? '');
  final odometerCtrl = TextEditingController(text: existing?.odometer?.toStringAsFixed(0) ?? '');
  String condition = existing?.condition ?? 'ok';
  String position = existing?.position ?? '';
  final dateCtrl = TextEditingController(text: existing != null ? _dateToStr(existing.measuredAt ?? DateTime.now()) : _dateToStr(DateTime.now()));
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  bool saving = false;

  const conditions = ['good', 'ok', 'worn', 'damaged'];
  const positions = ['FL_Outer', 'FL_Inner', 'FR_Outer', 'FR_Inner', 'RL_Outer', 'RL_Inner', 'RR_Outer', 'RR_Inner', 'Spare'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Inspection' : 'Record Inspection'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: tireId,
                decoration: const InputDecoration(labelText: 'Tire *', prefixIcon: Icon(Icons.tire_repair)),
                items: p.tires.map<DropdownMenuItem<int>>((t) {
                  return DropdownMenuItem<int>(
                    value: t.id,
                    child: Text('${t.serialNumber} · ${t.brand} ${t.size}'.trim(), style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setDialog(() => tireId = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: vehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle', prefixIcon: Icon(Icons.directions_car)),
                items: p.vehicles.map<DropdownMenuItem<int>>((v) {
                  final m = v as Map<String, dynamic>;
                  final id = m['id'] as int?;
                  final name = m['display_name']?.toString() ?? 'Vehicle #$id';
                  return DropdownMenuItem<int>(value: id, child: Text(name, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setDialog(() => vehicleId = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: treadCtrl, decoration: const InputDecoration(labelText: 'Tread /32" *'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: pressureCtrl, decoration: const InputDecoration(labelText: 'Psi'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: odometerCtrl, decoration: const InputDecoration(labelText: 'Odometer'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: condition,
                      decoration: const InputDecoration(labelText: 'Condition'),
                      items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                      onChanged: (v) { if (v != null) setDialog(() => condition = v); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: position.isNotEmpty ? position : null,
                decoration: const InputDecoration(labelText: 'Position', prefixIcon: Icon(Icons.location_on_outlined)),
                items: positions.map((pos) => DropdownMenuItem(value: pos, child: Text(_formatPosition(pos)))).toList(),
                onChanged: (v) { if (v != null) setDialog(() => position = v); },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Measured On *', prefixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) { dateCtrl.text = _dateToStr(d); setDialog(() {}); }
                },
              ),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              if (tireId == null || treadCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;
              setDialog(() => saving = true);
              final payload = <String, dynamic>{
                'tire': tireId,
                'tread_depth': double.tryParse(treadCtrl.text) ?? 0,
                'pressure_psi': double.tryParse(pressureCtrl.text),
                'odometer': double.tryParse(odometerCtrl.text),
                'position': position,
                'condition': condition,
                'measured_at': dateCtrl.text,
                'notes': notesCtrl.text.trim(),
                if (vehicleId != null) 'vehicle': vehicleId,
              };
              try {
                if (isEdit && existing.id != null) {
                  await p.api.updateTireInspection(existing.id!, payload);

                } else {
                  await p.createInspection(payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  setDialog(() => saving = false);
                }
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Save'),
          ),
        ],
      );
    }),
  );
}

/// Show the rotation form dialog.
void showRotationFormDialog(BuildContext context, TireRotation? existing) {
  final p = context.read<TireProvider>();
  final isEdit = existing != null;

  int? vehicleId = existing?.vehicleId;
  String rotationPattern = existing?.rotationPattern ?? '';
  double? odometer = existing?.odometer;
  final dateCtrl = TextEditingController(text: existing != null ? _dateToStr(existing.performedAt ?? DateTime.now()) : _dateToStr(DateTime.now()));
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  const patterns = ['Front-to-Rear', 'Rear-to-Front', 'X-Pattern', 'Forward Cross', 'Rearward Cross', 'Side-to-Side'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Rotation' : 'Record Rotation'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: vehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car)),
                items: p.vehicles.map<DropdownMenuItem<int>>((v) {
                  final m = v as Map<String, dynamic>;
                  final id = m['id'] as int?;
                  final name = m['display_name']?.toString() ?? 'Vehicle #$id';
                  return DropdownMenuItem<int>(value: id, child: Text(name, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setDialog(() => vehicleId = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: rotationPattern.isNotEmpty ? rotationPattern : null,
                decoration: const InputDecoration(labelText: 'Rotation Pattern', prefixIcon: Icon(Icons.swap_horiz)),
                items: patterns.map((pat) => DropdownMenuItem(value: pat, child: Text(pat))).toList(),
                onChanged: (v) { if (v != null) setDialog(() => rotationPattern = v); },
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Odometer'),
                keyboardType: TextInputType.number,
                onChanged: (v) => odometer = double.tryParse(v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Performed On *', prefixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (d != null) { dateCtrl.text = _dateToStr(d); setDialog(() {}); }
                },
              ),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (vehicleId == null || dateCtrl.text.isEmpty) return;
              final payload = <String, dynamic>{
                'vehicle': vehicleId,
                if (rotationPattern.isNotEmpty) 'rotation_pattern': rotationPattern,
                if (odometer != null) 'odometer': odometer,
                'performed_at': dateCtrl.text,
                'notes': notesCtrl.text.trim(),
                'swaps': existing?.swaps ?? [],
              };
              final ok = await p.createRotation(payload);
              if (ctx.mounted && ok) Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Update' : 'Save'),
          ),
        ],
      );
    }),
  );
}

/// Show the rotation detail dialog.
void showRotationDetailDialog(BuildContext context, TireRotation rotation) {
  final swaps = rotation.swapsDetail;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: DomendraTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(rotation.vehicleName.isEmpty ? 'Rotation #${rotation.id}' : rotation.vehicleName, style: const TextStyle(fontSize: 16))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpecRow('Vehicle', rotation.vehicleName.isEmpty ? '#${rotation.vehicleId}' : rotation.vehicleName),
              if (rotation.vehicleLicensePlate.isNotEmpty)
                _SpecRow('License Plate', rotation.vehicleLicensePlate),
              _SpecRow('Pattern', rotation.rotationPattern),
              _SpecRow('Odometer', rotation.odometer?.toStringAsFixed(0) ?? '—'),
              _SpecRow('Date', _dateToStr2(rotation.performedAt)),
              _SpecRow('Swaps', '${rotation.swaps.length}'),
                _SpecRow('Notes', rotation.notes),
              if (swaps.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Swap Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...swaps.map((s) {
                  final m = s as Map<String, dynamic>;
                  final tireSerial = m['tire_serial']?.toString() ?? '#${m['tire']}';
                  final fromPos = m['from_position']?.toString() ?? '';
                  final toPos = m['to_position']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: DomendraTheme.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.tire_repair, size: 16, color: DomendraTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(tireSerial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        if (fromPos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(_formatPosition(fromPos), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.info)),
                          ),
                        const Icon(Icons.arrow_forward, size: 14, color: DomendraTheme.onSurfaceMuted),
                        if (toPos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(_formatPosition(toPos), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.success)),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

// ── Helpers ──────────────────────────────────────────────────

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final v = value.isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ComboField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final List<String> items;
  final IconData? icon;
  const _ComboField({required this.controller, required this.label, required this.items, this.icon});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      fieldViewBuilder: (ctx, fieldCtrl, focus, onFieldSubmitted) {
        // Sync the external controller
        fieldCtrl.addListener(() { controller.text = fieldCtrl.text; });
        return TextField(
          controller: fieldCtrl,
          focusNode: focus,
          decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon) : null),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return items.where((item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase())).take(10);
      },
      onSelected: (selection) { controller.text = selection; },
    );
  }
}

String _dateToStr(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
String _dateToStr2(DateTime? dt) => dt == null ? '—' : _dateToStr(dt);

String _formatPosition(String pos) {
  if (pos.isEmpty) return '—';
  return pos.replaceAll('_', ' ');
}

String _conditionToValue(TireCondition c) {
  switch (c) {
    case TireCondition.newTire: return 'new';
    case TireCondition.secondHand: return 'second_hand';
    case TireCondition.retreaded: return 'retreaded';
    case TireCondition.reclaimed: return 'reclaimed';
    case TireCondition.used: return 'used';
  }
}

String _statusToValue(TireStatus s) {
  switch (s) {
    case TireStatus.inStock: return 'in_stock';
    case TireStatus.mounted: return 'mounted';
    case TireStatus.spare: return 'spare';
    case TireStatus.retired: return 'retired';
    case TireStatus.scrapped: return 'scrapped';
  }
}

Color _tireStatusColor(TireStatus status) {
  switch (status) {
    case TireStatus.inStock: return const Color(0xFF94a3b8);
    case TireStatus.mounted: return DomendraTheme.success;
    case TireStatus.spare: return DomendraTheme.info;
    case TireStatus.retired: return DomendraTheme.danger;
    case TireStatus.scrapped: return const Color(0xFF475569);
  }
}

Color _inspectionCondColor(String cond) {
  switch (cond) {
    case 'good': return DomendraTheme.success;
    case 'ok': return DomendraTheme.info;
    case 'worn': return DomendraTheme.warning;
    case 'damaged': return DomendraTheme.danger;
    default: return DomendraTheme.onSurfaceMuted;
  }
}
