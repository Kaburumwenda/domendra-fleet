import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/battery_model.dart';
import '../../../providers/battery_provider.dart';

// ════════════════════════════════════════════════════════════
// BATTERY ADD/EDIT DIALOG
// ════════════════════════════════════════════════════════════
void showBatteryFormDialog(BuildContext context, Battery? existing) {
  final p = context.read<BatteryProvider>();
  final isEdit = existing != null;

  final serialCtrl = TextEditingController(text: existing?.serialNumber ?? '');
  final partCtrl = TextEditingController(text: existing?.partNumber ?? '');
  final brandCtrl = TextEditingController(text: existing?.brand ?? '');
  final modelCtrl = TextEditingController(text: existing?.model ?? '');
  final voltageCtrl = TextEditingController(text: existing != null ? existing.voltage.toStringAsFixed(0) : '12');
  final capacityCtrl = TextEditingController(text: existing?.capacityAh?.toStringAsFixed(0) ?? '');
  final ccaCtrl = TextEditingController(text: existing?.cca?.toStringAsFixed(0) ?? '');
  final rcCtrl = TextEditingController(text: existing?.rcMinutes?.toStringAsFixed(0) ?? '');
  final groupCtrl = TextEditingController(text: existing?.groupCode ?? '');
  final weightCtrl = TextEditingController(text: existing?.weightKg?.toStringAsFixed(1) ?? '');
  final positionCtrl = TextEditingController(text: existing?.position ?? '');
  final priceCtrl = TextEditingController(text: existing?.purchasePrice?.toStringAsFixed(0) ?? '');
  final purchaseDateCtrl = TextEditingController(text: existing != null && existing.purchaseDate != null ? _dateToStr(existing.purchaseDate!) : '');
  final warrantyMonthsCtrl = TextEditingController(text: existing?.warrantyMonths?.toStringAsFixed(0) ?? '');
  final warrantyExpiryCtrl = TextEditingController(text: existing != null && existing.warrantyExpiry != null ? _dateToStr(existing.warrantyExpiry!) : '');
  final lifespanCtrl = TextEditingController(text: existing?.expectedLifespanMonths?.toStringAsFixed(0) ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  String chemistry = existing != null ? _chemistryToValue(existing.chemistry) : 'lead_acid';
  String condition = existing != null ? _conditionToValue(existing.condition) : 'new';
  String status = existing != null ? _statusToValue(existing.status) : 'in_stock';

  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialog) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Battery' : 'Add Battery'),
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
                  TextField(controller: partCtrl, decoration: const InputDecoration(labelText: 'Part Number / SKU')),
                  const SizedBox(height: 8),
                  _ComboField(controller: brandCtrl, label: 'Brand', items: p.brandOptions, icon: Icons.factory_outlined),
                  const SizedBox(height: 8),
                  TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: chemistry,
                    decoration: const InputDecoration(labelText: 'Chemistry', prefixIcon: Icon(Icons.science_outlined)),
                    items: const [
                      DropdownMenuItem(value: 'lead_acid', child: Text('Lead-Acid')),
                      DropdownMenuItem(value: 'agm', child: Text('AGM')),
                      DropdownMenuItem(value: 'gel', child: Text('Gel')),
                      DropdownMenuItem(value: 'li_ion', child: Text('Lithium-Ion')),
                      DropdownMenuItem(value: 'lifepo4', child: Text('LiFePO4')),
                      DropdownMenuItem(value: 'nicd', child: Text('NiCd')),
                      DropdownMenuItem(value: 'nimh', child: Text('NiMH')),
                    ],
                    onChanged: (v) { if (v != null) setDialog(() => chemistry = v); },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: voltageCtrl, decoration: const InputDecoration(labelText: 'Voltage (V)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: capacityCtrl, decoration: const InputDecoration(labelText: 'Capacity (Ah)'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: ccaCtrl, decoration: const InputDecoration(labelText: 'CCA'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: rcCtrl, decoration: const InputDecoration(labelText: 'Reserve Cap (min)'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'BCI Group Code'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        value: condition,
                        decoration: const InputDecoration(labelText: 'Condition', prefixIcon: Icon(Icons.circle)),
                        items: const [
                          DropdownMenuItem(value: 'new', child: Text('New')),
                          DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
                          DropdownMenuItem(value: 'good', child: Text('Good')),
                          DropdownMenuItem(value: 'fair', child: Text('Fair')),
                          DropdownMenuItem(value: 'poor', child: Text('Poor')),
                          DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                        ],
                        onChanged: (v) { if (v != null) setDialog(() => condition = v); },
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'in_stock', child: Text('In Stock')),
                          DropdownMenuItem(value: 'installed', child: Text('Installed')),
                          DropdownMenuItem(value: 'spare', child: Text('Spare')),
                          DropdownMenuItem(value: 'charging', child: Text('Charging')),
                          DropdownMenuItem(value: 'retired', child: Text('Retired')),
                          DropdownMenuItem(value: 'scrapped', child: Text('Scrapped')),
                        ],
                        onChanged: (v) { if (v != null) setDialog(() => status = v); },
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: positionCtrl, decoration: const InputDecoration(labelText: 'Position', hintText: 'Starter, Aux-1, House...')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Purchase Price'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: purchaseDateCtrl, decoration: const InputDecoration(labelText: 'Purchase Date'), readOnly: true, onTap: () async {
                        final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (d != null) purchaseDateCtrl.text = _dateToStr(d);
                      })),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: warrantyMonthsCtrl, decoration: const InputDecoration(labelText: 'Warranty (months)'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: warrantyExpiryCtrl, decoration: const InputDecoration(labelText: 'Warranty Expiry'), readOnly: true, onTap: () async {
                        final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if (d != null) warrantyExpiryCtrl.text = _dateToStr(d);
                      })),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: lifespanCtrl, decoration: const InputDecoration(labelText: 'Expected Life (months)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
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
                  'part_number': partCtrl.text.trim(),
                  'brand': brandCtrl.text.trim(),
                  'model': modelCtrl.text.trim(),
                  'chemistry': chemistry,
                  'voltage': double.tryParse(voltageCtrl.text) ?? 12,
                  'capacity_ah': double.tryParse(capacityCtrl.text),
                  'cca': double.tryParse(ccaCtrl.text),
                  'rc_minutes': double.tryParse(rcCtrl.text),
                  'group_code': groupCtrl.text.trim(),
                  'weight_kg': double.tryParse(weightCtrl.text),
                  'condition': condition,
                  'status': status,
                  'position': positionCtrl.text.trim(),
                  'purchase_price': double.tryParse(priceCtrl.text),
                  'purchase_date': purchaseDateCtrl.text.isNotEmpty ? purchaseDateCtrl.text : null,
                  'warranty_months': int.tryParse(warrantyMonthsCtrl.text),
                  'warranty_expiry': warrantyExpiryCtrl.text.isNotEmpty ? warrantyExpiryCtrl.text : null,
                  'expected_lifespan_months': int.tryParse(lifespanCtrl.text),
                  'notes': notesCtrl.text.trim(),
                };
                try {
                  if (isEdit && existing.id != null) {
                    await p.updateBattery(existing.id!, payload);
                  } else {
                    await p.createBattery(payload);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setDialog(() { saving = false; errors = [e.toString()]; });
                }
              },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        );
      });
    },
  );
}

// ════════════════════════════════════════════════════════════
// BATTERY DETAIL DIALOG
// ════════════════════════════════════════════════════════════
void showBatteryDetailDialog(BuildContext context, Battery battery) {
  final p = context.read<BatteryProvider>();
  final readings = p.readings.where((r) => r.batteryId == battery.id).take(5).toList();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.battery_charging_full, color: DomendraTheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(battery.serialNumber, style: const TextStyle(fontSize: 16))),
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
                    decoration: BoxDecoration(color: _batteryStatusColor(battery.status).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(battery.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _batteryStatusColor(battery.status))),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _batteryConditionColor(battery.condition).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(battery.conditionLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _batteryConditionColor(battery.condition))),
                  ),
                  const Spacer(),
                  if (battery.needsReplacement)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: DomendraTheme.danger, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Needs Replacement', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _SpecRow('Brand', '${battery.brand} ${battery.model}'.trim()),
              _SpecRow('Part Number', battery.partNumber),
              _SpecRow('Chemistry', battery.chemistryLabel),
              _SpecRow('Voltage', '${battery.voltage}V'),
              _SpecRow('Capacity', battery.capacityAh != null ? '${battery.capacityAh!.toStringAsFixed(0)} Ah' : '—'),
              _SpecRow('CCA', battery.cca?.toStringAsFixed(0) ?? '—'),
              _SpecRow('Group Code', battery.groupCode.isEmpty ? '—' : battery.groupCode),
              if (battery.weightKg != null) _SpecRow('Weight', '${battery.weightKg!.toStringAsFixed(1)} kg'),
              _SpecRow('Health', '${battery.healthPct.toStringAsFixed(0)}%'),
              if (battery.lastVoltage != null) _SpecRow('Last Voltage', '${battery.lastVoltage!.toStringAsFixed(1)}V'),
              _SpecRow('Cycle Count', '${battery.cycleCount}'),
              _SpecRow('Vehicle', battery.vehicleName.isEmpty ? '—' : battery.vehicleName),
              _SpecRow('Position', battery.position.isEmpty ? '—' : battery.position),
              _SpecRow('Purchase Price', battery.purchasePrice != null ? '₵${battery.purchasePrice!.toStringAsFixed(0)}' : '—'),
              _SpecRow('Purchase Date', _dateToStr2(battery.purchaseDate)),
              _SpecRow('Warranty Expiry', _dateToStr2(battery.warrantyExpiry)),
              if (battery.warrantyDaysLeft != null)
                _SpecRow('Warranty Days Left', '${battery.warrantyDaysLeft}'),
              _SpecRow('Age (months)', battery.ageMonths?.toString() ?? '—'),
              if (battery.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
                Text(battery.notes, style: const TextStyle(fontSize: 12)),
              ],
              if (readings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Recent Readings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...readings.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(_dateToStr2(r.measuredAt), style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      const SizedBox(width: 8),
                      Text('${r.voltage.toStringAsFixed(1)}V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _voltageColor(r.voltage))),
                      const SizedBox(width: 8),
                      Text('${r.healthPct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: _healthColor(r.healthPct))),
                      const SizedBox(width: 8),
                      Text(r.testResult, style: TextStyle(fontSize: 10, color: _testResultColor(r.testResult))),
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
        FilledButton.tonal(onPressed: () { Navigator.pop(ctx); showBatteryFormDialog(context, battery); }, child: const Text('Edit')),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
// INSTALL DIALOG
// ════════════════════════════════════════════════════════════
void showInstallDialog(BuildContext context, Battery battery) {
  final p = context.read<BatteryProvider>();
  int? vehicleId;
  final positionCtrl = TextEditingController();
  final dateCtrl = TextEditingController(text: _dateToStr(DateTime.now()));
  final notesCtrl = TextEditingController();
  bool saving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: const Text('Install Battery'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Installing ${battery.serialNumber}', style: const TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: vehicleId,
                decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                items: p.vehicles.map((v) {
                  final name = v['display_name'] ?? v['license_plate'] ?? '#${v['id']}';
                  return DropdownMenuItem<int>(value: v['id'] as int, child: Text(name.toString()));
                }).cast<DropdownMenuItem<int>>().toList(),
                onChanged: (v) => setDialog(() => vehicleId = v),
              ),
              const SizedBox(height: 8),
              TextField(controller: positionCtrl, decoration: const InputDecoration(labelText: 'Position', hintText: 'Starter, Aux, House...')),
              const SizedBox(height: 8),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date'), readOnly: true, onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) dateCtrl.text = _dateToStr(d);
              }),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving || vehicleId == null ? null : () async {
              setDialog(() => saving = true);
              try {
                await p.installBattery(battery.id!, vehicleId: vehicleId!, position: positionCtrl.text.trim(), performedAt: dateCtrl.text, notes: notesCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() => saving = false);
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Install'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// REASON DIALOG (Uninstall / Retire)
// ════════════════════════════════════════════════════════════
void showReasonDialog(BuildContext context, {required String action, required Battery battery}) {
  final p = context.read<BatteryProvider>();
  final isRetire = action == 'retire';
  final notesCtrl = TextEditingController();
  bool saving = false;
  final quickReasons = isRetire
      ? ['End of life', 'Failed load test', 'Damaged', 'Upgrading', ' Warranty expired']
      : ['Vehicle sold', 'Battery replacement', 'Maintenance', 'Seasonal removal'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isRetire ? 'Retire Battery' : 'Uninstall Battery'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${isRetire ? 'Retire' : 'Uninstall'} ${battery.serialNumber}?', style: const TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
              const SizedBox(height: 12),
              const Text('Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: quickReasons.map((r) => ActionChip(
                  label: Text(r, style: const TextStyle(fontSize: 11)),
                  onPressed: () { notesCtrl.text = r; setDialog(() {}); },
                )).toList(),
              ),
              const SizedBox(height: 8),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: isRetire ? DomendraTheme.danger : DomendraTheme.warning),
            onPressed: saving ? null : () async {
              setDialog(() => saving = true);
              try {
                if (isRetire) {
                  await p.retireBattery(battery.id!, notes: notesCtrl.text.trim());
                } else {
                  await p.uninstallBattery(battery.id!, notes: notesCtrl.text.trim());
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() => saving = false);
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isRetire ? 'Retire' : 'Uninstall'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// READING DIALOG
// ════════════════════════════════════════════════════════════
void showReadingFormDialog(BuildContext context, BatteryReading? existing, {int? preBatteryId}) {
  final p = context.read<BatteryProvider>();
  final isEdit = existing != null;

  int? batteryId = existing?.batteryId ?? preBatteryId;
  final voltageCtrl = TextEditingController(text: existing?.voltage.toStringAsFixed(2) ?? '12.60');
  final sgCtrl = TextEditingController(text: existing?.specificGravity?.toStringAsFixed(3) ?? '');
  final resistanceCtrl = TextEditingController(text: existing?.internalResistance?.toStringAsFixed(1) ?? '');
  final tempCtrl = TextEditingController(text: existing?.temperatureC?.toStringAsFixed(1) ?? '');
  final socCtrl = TextEditingController(text: existing?.socPct?.toStringAsFixed(1) ?? '');
  final dateCtrl = TextEditingController(text: existing != null ? _dateToStr(existing.measuredAt ?? DateTime.now()) : _dateToStr(DateTime.now()));
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  String testResult = existing?.testResult ?? 'pass';
  bool saving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Reading' : 'Record Reading'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: batteryId,
                  decoration: const InputDecoration(labelText: 'Battery *', prefixIcon: Icon(Icons.battery_charging_full)),
                  items: p.batteries.map((b) => DropdownMenuItem<int>(
                    value: b.id,
                    child: Text('${b.serialNumber} – ${b.brand}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialog(() => batteryId = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date *'), readOnly: true, onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) dateCtrl.text = _dateToStr(d);
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: voltageCtrl, decoration: const InputDecoration(labelText: 'Voltage (V) *'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: sgCtrl, decoration: const InputDecoration(labelText: 'Specific Gravity'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: resistanceCtrl, decoration: const InputDecoration(labelText: 'Resistance (mΩ)'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: tempCtrl, decoration: const InputDecoration(labelText: 'Temp (°C)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: socCtrl, decoration: const InputDecoration(labelText: 'SOC (%)'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: testResult,
                  decoration: const InputDecoration(labelText: 'Test Result'),
                  items: const [
                    DropdownMenuItem(value: 'pass', child: Text('Pass')),
                    DropdownMenuItem(value: 'marginal', child: Text('Marginal')),
                    DropdownMenuItem(value: 'fail', child: Text('Fail')),
                    DropdownMenuItem(value: 'charge', child: Text('Charge & Retest')),
                  ],
                  onChanged: (v) { if (v != null) setDialog(() => testResult = v); },
                ),
                const SizedBox(height: 8),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving || batteryId == null ? null : () async {
              final payload = <String, dynamic>{
                'battery': batteryId,
                'measured_at': dateCtrl.text,
                'voltage': double.tryParse(voltageCtrl.text) ?? 12.6,
                'specific_gravity': double.tryParse(sgCtrl.text),
                'internal_resistance': double.tryParse(resistanceCtrl.text),
                'temperature_c': double.tryParse(tempCtrl.text),
                'soc_pct': double.tryParse(socCtrl.text),
                'test_result': testResult,
                'notes': notesCtrl.text.trim(),
              };
              setDialog(() => saving = true);
              try {
                if (isEdit && existing.id != null) {
                  await p.updateReading(existing.id!, payload);
                } else {
                  await p.createReading(payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() => saving = false);
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save' : 'Record'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// CHARGE CYCLE DIALOG
// ════════════════════════════════════════════════════════════
void showCycleFormDialog(BuildContext context, ChargeCycle? existing) {
  final p = context.read<BatteryProvider>();
  final isEdit = existing != null;

  int? batteryId = existing?.batteryId;
  final startVCtrl = TextEditingController(text: existing?.startVoltage?.toStringAsFixed(2) ?? '');
  final endVCtrl = TextEditingController(text: existing?.endVoltage?.toStringAsFixed(2) ?? '');
  final energyCtrl = TextEditingController(text: existing?.energyKwh?.toStringAsFixed(2) ?? '');
  final startedAtCtrl = TextEditingController(text: existing?.startedAt != null ? _dateTimeToStr(existing!.startedAt!) : '');
  final completedAtCtrl = TextEditingController(text: existing?.completedAt != null ? _dateTimeToStr(existing!.completedAt!) : '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  String chargeMethod = existing?.chargeMethod ?? 'ac';
  bool saving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Charge Cycle' : 'Record Charge Cycle'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: batteryId,
                  decoration: const InputDecoration(labelText: 'Battery *', prefixIcon: Icon(Icons.battery_charging_full)),
                  items: p.batteries.map((b) => DropdownMenuItem<int>(
                    value: b.id,
                    child: Text('${b.serialNumber} – ${b.brand}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialog(() => batteryId = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startedAtCtrl, decoration: const InputDecoration(labelText: 'Started At'), readOnly: true, onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) startedAtCtrl.text = _dateTimeToStr(d);
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: completedAtCtrl, decoration: const InputDecoration(labelText: 'Completed At'), readOnly: true, onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) completedAtCtrl.text = _dateTimeToStr(d);
                    })),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startVCtrl, decoration: const InputDecoration(labelText: 'Start V'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endVCtrl, decoration: const InputDecoration(labelText: 'End V'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: energyCtrl, decoration: const InputDecoration(labelText: 'Energy (kWh)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: chargeMethod,
                      decoration: const InputDecoration(labelText: 'Method'),
                      items: const [
                        DropdownMenuItem(value: 'ac', child: Text('AC')),
                        DropdownMenuItem(value: 'dc', child: Text('DC')),
                        DropdownMenuItem(value: 'regen', child: Text('Regen')),
                        DropdownMenuItem(value: 'alternator', child: Text('Alternator')),
                        DropdownMenuItem(value: 'solar', child: Text('Solar')),
                      ],
                      onChanged: (v) { if (v != null) setDialog(() => chargeMethod = v); },
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving || batteryId == null ? null : () async {
              final payload = <String, dynamic>{
                'battery': batteryId,
                'start_voltage': double.tryParse(startVCtrl.text),
                'end_voltage': double.tryParse(endVCtrl.text),
                'energy_kwh': double.tryParse(energyCtrl.text),
                'charge_method': chargeMethod,
                'started_at': startedAtCtrl.text.isNotEmpty ? startedAtCtrl.text : null,
                'completed_at': completedAtCtrl.text.isNotEmpty ? completedAtCtrl.text : null,
                'notes': notesCtrl.text.trim(),
              };
              setDialog(() => saving = true);
              try {
                if (isEdit && existing.id != null) {
                  await p.updateCycle(existing.id!, payload);
                } else {
                  await p.createCycle(payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() => saving = false);
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save' : 'Record'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// REPLACEMENT DIALOG
// ════════════════════════════════════════════════════════════
void showReplacementFormDialog(BuildContext context, BatteryReplacement? existing) {
  final p = context.read<BatteryProvider>();
  final isEdit = existing != null;

  int? batteryId = existing?.batteryId;
  int? vehicleId = existing?.vehicleId;
  final scheduledCtrl = TextEditingController(text: existing != null && existing.scheduledDate != null ? _dateToStr(existing.scheduledDate!) : '');
  final completedCtrl = TextEditingController(text: existing != null && existing.completedDate != null ? _dateToStr(existing.completedDate!) : '');
  final costCtrl = TextEditingController(text: existing?.estimatedCost?.toStringAsFixed(0) ?? '');
  final reasonCtrl = TextEditingController(text: existing?.reason ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  String status = existing?.status ?? 'scheduled';
  bool saving = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Replacement' : 'Schedule Replacement'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: batteryId,
                  decoration: const InputDecoration(labelText: 'Battery *', prefixIcon: Icon(Icons.battery_charging_full)),
                  items: p.batteries.map((b) => DropdownMenuItem<int>(
                    value: b.id,
                    child: Text('${b.serialNumber} – ${b.brand}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialog(() => batteryId = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
                  items: p.vehicles.map((v) {
                    final name = v['display_name'] ?? v['license_plate'] ?? '#${v['id']}';
                    return DropdownMenuItem<int>(value: v['id'] as int, child: Text(name.toString()));
                  }).cast<DropdownMenuItem<int>>().toList(),
                  onChanged: (v) => setDialog(() => vehicleId = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: scheduledCtrl, decoration: const InputDecoration(labelText: 'Scheduled Date'), readOnly: true, onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) scheduledCtrl.text = _dateToStr(d);
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: completedCtrl, decoration: const InputDecoration(labelText: 'Completed Date'), readOnly: true, onTap: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) completedCtrl.text = _dateToStr(d);
                    })),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                        DropdownMenuItem(value: 'ordered', child: Text('Ordered')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (v) { if (v != null) setDialog(() => status = v); },
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Est. Cost'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
                const SizedBox(height: 8),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving || batteryId == null ? null : () async {
              final payload = <String, dynamic>{
                'battery': batteryId,
                'vehicle': vehicleId,
                'scheduled_date': scheduledCtrl.text.isNotEmpty ? scheduledCtrl.text : null,
                'completed_date': completedCtrl.text.isNotEmpty ? completedCtrl.text : null,
                'estimated_cost': double.tryParse(costCtrl.text),
                'reason': reasonCtrl.text.trim(),
                'status': status,
                'notes': notesCtrl.text.trim(),
              };
              setDialog(() => saving = true);
              try {
                if (isEdit && existing.id != null) {
                  await p.updateReplacement(existing.id!, payload);
                } else {
                  await p.createReplacement(payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() => saving = false);
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Save' : 'Schedule'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════
class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
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

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════
String _dateToStr(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
String _dateToStr2(DateTime? dt) => dt == null ? '—' : _dateToStr(dt);
String _dateTimeToStr(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _chemistryToValue(BatteryChemistry c) {
  switch (c) {
    case BatteryChemistry.leadAcid: return 'lead_acid';
    case BatteryChemistry.agm: return 'agm';
    case BatteryChemistry.gel: return 'gel';
    case BatteryChemistry.liIon: return 'li_ion';
    case BatteryChemistry.lifepo4: return 'lifepo4';
    case BatteryChemistry.nicd: return 'nicd';
    case BatteryChemistry.nimh: return 'nimh';
  }
}

String _conditionToValue(BatteryCondition c) {
  switch (c) {
    case BatteryCondition.newBattery: return 'new';
    case BatteryCondition.excellent: return 'excellent';
    case BatteryCondition.good: return 'good';
    case BatteryCondition.fair: return 'fair';
    case BatteryCondition.poor: return 'poor';
    case BatteryCondition.damaged: return 'damaged';
  }
}

String _statusToValue(BatteryStatus s) {
  switch (s) {
    case BatteryStatus.inStock: return 'in_stock';
    case BatteryStatus.installed: return 'installed';
    case BatteryStatus.spare: return 'spare';
    case BatteryStatus.charging: return 'charging';
    case BatteryStatus.retired: return 'retired';
    case BatteryStatus.scrapped: return 'scrapped';
  }
}

Color _batteryStatusColor(BatteryStatus status) {
  switch (status) {
    case BatteryStatus.inStock: return const Color(0xFF10b981);
    case BatteryStatus.installed: return const Color(0xFF3b82f6);
    case BatteryStatus.spare: return const Color(0xFFf59e0b);
    case BatteryStatus.charging: return const Color(0xFF8b5cf6);
    case BatteryStatus.retired: return const Color(0xFFef4444);
    case BatteryStatus.scrapped: return const Color(0xFF6b7280);
  }
}

Color _batteryConditionColor(BatteryCondition cond) {
  switch (cond) {
    case BatteryCondition.newBattery: return const Color(0xFF10b981);
    case BatteryCondition.excellent: return const Color(0xFF22c55e);
    case BatteryCondition.good: return const Color(0xFF84cc16);
    case BatteryCondition.fair: return const Color(0xFFf59e0b);
    case BatteryCondition.poor: return const Color(0xFFef4444);
    case BatteryCondition.damaged: return const Color(0xFFdc2626);
  }
}

Color _voltageColor(double v) {
  if (v >= 12.5) return const Color(0xFF10b981);
  if (v >= 12.0) return const Color(0xFFf59e0b);
  return const Color(0xFFef4444);
}

Color _healthColor(double v) {
  if (v >= 80) return const Color(0xFF10b981);
  if (v >= 60) return const Color(0xFFf59e0b);
  return const Color(0xFFef4444);
}

Color _testResultColor(String v) {
  switch (v) {
    case 'pass': return const Color(0xFF10b981);
    case 'marginal': return const Color(0xFFf59e0b);
    case 'fail': return const Color(0xFFef4444);
    case 'charge': return const Color(0xFF3b82f6);
    default: return const Color(0xFF6b7280);
  }
}
