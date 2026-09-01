import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/ifta_model.dart';
import '../../../providers/ifta_provider.dart';

String _currencySymbol = 'KSh';

// ════════════════════════════════════════════════════════════
// TRIP LOG FORM DIALOG
// ════════════════════════════════════════════════════════════
void showTripLogFormDialog(BuildContext context, TripLog? existing) {
  final p = context.read<IftaProvider>();
  final isEdit = existing != null;

  final dateCtrl = TextEditingController(text: existing?.date != null ? _dateToInput(existing!.date!) : _dateToInput(DateTime.now()));
  final distanceCtrl = TextEditingController(text: existing != null ? existing.distance.toString() : '');
  final startOdoCtrl = TextEditingController(text: existing?.startOdometer?.toString() ?? '');
  final endOdoCtrl = TextEditingController(text: existing?.endOdometer?.toString() ?? '');
  final routeCtrl = TextEditingController(text: existing?.route ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  String distanceUnit = existing?.distanceUnit ?? 'miles';
  String tripType = existing?.tripType ?? 'loaded';
  int? vehicleId = existing?.vehicleId ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  int? driverId = existing?.driverId;
  int? jurisdictionId = existing?.jurisdictionId ?? (p.jurisdictions.isNotEmpty ? p.jurisdictions.first.id : null);
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Trip Log' : 'Add Trip Log'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errors.isNotEmpty) ...[
                  _ErrorBox(errors: errors),
                ],
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: jurisdictionId,
                  decoration: const InputDecoration(labelText: 'Jurisdiction *', prefixIcon: Icon(Icons.map_outlined)),
                  items: p.jurisdictions.map<DropdownMenuItem<int>>((j) => DropdownMenuItem(value: j.id, child: Text('${j.code} - ${j.name}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => jurisdictionId = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date *', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) dateCtrl.text = _dateToInput(d);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: distanceCtrl,
                      decoration: const InputDecoration(labelText: 'Distance *'),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: distanceUnit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [DropdownMenuItem(value: 'miles', child: Text('Miles')), DropdownMenuItem(value: 'km', child: Text('Km'))],
                      onChanged: (v) { if (v != null) setDialog(() => distanceUnit = v); },
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: startOdoCtrl,
                      decoration: const InputDecoration(labelText: 'Start Odometer'),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: endOdoCtrl,
                      decoration: const InputDecoration(labelText: 'End Odometer'),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tripType,
                  decoration: const InputDecoration(labelText: 'Trip Type', prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'loaded', child: Text('Loaded')),
                    DropdownMenuItem(value: 'empty', child: Text('Empty')),
                    DropdownMenuItem(value: 'bobtail', child: Text('Bobtail')),
                  ],
                  onChanged: (v) { if (v != null) setDialog(() => tripType = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: routeCtrl,
                  decoration: const InputDecoration(labelText: 'Route (From / To)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              errors = [];
              if (vehicleId == null) errors.add('Vehicle is required');
              if (jurisdictionId == null) errors.add('Jurisdiction is required');
              if (distanceCtrl.text.isEmpty || double.tryParse(distanceCtrl.text) == null) errors.add('Valid distance required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveTripLog({
                  'vehicle': vehicleId,
                  'jurisdiction': jurisdictionId,
                  'date': dateCtrl.text,
                  'distance': double.parse(distanceCtrl.text),
                  'distance_unit': distanceUnit,
                  if (startOdoCtrl.text.isNotEmpty) 'start_odometer': double.tryParse(startOdoCtrl.text),
                  if (endOdoCtrl.text.isNotEmpty) 'end_odometer': double.tryParse(endOdoCtrl.text),
                  'trip_type': tripType,
                  'route': routeCtrl.text,
                  'notes': notesCtrl.text,
                  'source': 'manual',
                }, id: existing?.id);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() { errors = [e.toString()]; saving = false; });
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// FUEL PURCHASE FORM DIALOG
// ════════════════════════════════════════════════════════════
void showFuelPurchaseFormDialog(BuildContext context, FuelPurchase? existing) {
  final p = context.read<IftaProvider>();
  final isEdit = existing != null;

  final dateCtrl = TextEditingController(text: existing?.date != null ? _dateToInput(existing!.date!) : _dateToInput(DateTime.now()));
  final gallonsCtrl = TextEditingController(text: existing != null ? existing.gallons.toString() : '');
  final costCtrl = TextEditingController(text: existing != null ? existing.totalCost.toString() : '');
  final taxPaidCtrl = TextEditingController(text: existing != null ? existing.taxPaid.toString() : '');
  final vendorCtrl = TextEditingController(text: existing?.vendor ?? '');

  int? vehicleId = existing?.vehicleId ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  int? jurisdictionId = existing?.jurisdictionId ?? (p.jurisdictions.isNotEmpty ? p.jurisdictions.first.id : null);
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Fuel Purchase' : 'Add Fuel Purchase'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errors.isNotEmpty) ...[
                  _ErrorBox(errors: errors),
                ],
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: jurisdictionId,
                  decoration: const InputDecoration(labelText: 'Jurisdiction *', prefixIcon: Icon(Icons.map_outlined)),
                  items: p.jurisdictions.map<DropdownMenuItem<int>>((j) => DropdownMenuItem(value: j.id, child: Text('${j.code} - ${j.name}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => jurisdictionId = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date *', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) dateCtrl.text = _dateToInput(d);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: gallonsCtrl,
                  decoration: const InputDecoration(labelText: 'Gallons *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: costCtrl,
                      decoration: InputDecoration(labelText: 'Total Cost *', prefixText: _currencySymbol),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: taxPaidCtrl,
                      decoration: InputDecoration(labelText: 'Tax Paid', prefixText: _currencySymbol),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: vendorCtrl,
                  decoration: const InputDecoration(labelText: 'Vendor', prefixIcon: Icon(Icons.store_outlined)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              errors = [];
              if (vehicleId == null) errors.add('Vehicle is required');
              if (jurisdictionId == null) errors.add('Jurisdiction is required');
              if (gallonsCtrl.text.isEmpty || double.tryParse(gallonsCtrl.text) == null) errors.add('Valid gallons required');
              if (costCtrl.text.isEmpty || double.tryParse(costCtrl.text) == null) errors.add('Valid cost required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveFuelPurchase({
                  'vehicle': vehicleId,
                  'jurisdiction': jurisdictionId,
                  'date': dateCtrl.text,
                  'gallons': double.parse(gallonsCtrl.text),
                  'total_cost': double.parse(costCtrl.text),
                  if (taxPaidCtrl.text.isNotEmpty) 'tax_paid': double.tryParse(taxPaidCtrl.text) ?? 0,
                  'vendor': vendorCtrl.text,
                  'source': 'manual',
                }, id: existing?.id);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() { errors = [e.toString()]; saving = false; });
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// GENERATE QUARTER DIALOG
// ════════════════════════════════════════════════════════════
void showGenerateQuarterDialog(BuildContext context, {Map<String, dynamic>? prefill}) {
  final p = context.read<IftaProvider>();

  int year = prefill?['year'] ?? DateTime.now().year;
  String quarter = prefill?['quarter'] ?? 'Q1';
  int? vehicleId = prefill?['vehicle'] ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: const Text('Generate Quarterly Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errors.isNotEmpty) ...[
                  _ErrorBox(errors: errors),
                ],
                const Text('This aggregates all trip logs and fuel purchases for the selected quarter.', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      initialValue: year.toString(),
                      decoration: const InputDecoration(labelText: 'Year *'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) { final n = int.tryParse(v); if (n != null) setDialog(() => year = n); },
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: quarter,
                      decoration: const InputDecoration(labelText: 'Quarter *'),
                      items: const [
                        DropdownMenuItem(value: 'Q1', child: Text('Q1 (Jan-Mar)')),
                        DropdownMenuItem(value: 'Q2', child: Text('Q2 (Apr-Jun)')),
                        DropdownMenuItem(value: 'Q3', child: Text('Q3 (Jul-Sep)')),
                        DropdownMenuItem(value: 'Q4', child: Text('Q4 (Oct-Dec)')),
                      ],
                      onChanged: (v) { if (v != null) setDialog(() => quarter = v); },
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: saving ? null : () async {
              errors = [];
              if (vehicleId == null) errors.add('Vehicle is required');
              if (year < 2000 || year > 2100) errors.add('Valid year required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.generateQuarter({
                  'vehicle': vehicleId,
                  'year': year,
                  'quarter': quarter,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                setDialog(() { errors = [e.toString()]; saving = false; });
              }
            },
            child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate'),
          ),
        ],
      );
    }),
  );
}

// ════════════════════════════════════════════════════════════
// QUARTER BREAKDOWN DIALOG (bottom sheet)
// ════════════════════════════════════════════════════════════
void showQuarterBreakdownDialog(BuildContext context, IftaQuarter quarter) {
  final p = context.read<IftaProvider>();

  if (quarter.id != null && p.breakdownFor(quarter.id!) == null) {
    p.fetchBreakdown(quarter.id!);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Consumer<IftaProvider>(
                builder: (ctx, prov, _) {
                  final isLoading = quarter.id != null && prov.isBreakdownLoading(quarter.id!);
                  final breakdown = quarter.id != null ? prov.breakdownFor(quarter.id!) : null;
                  final statusColor = quarter.status == 'draft' ? const Color(0xFF6B7280) : (quarter.status == 'submitted' ? DomendraTheme.warning : DomendraTheme.success);
                  final netTaxColor = quarter.netTax > 0 ? DomendraTheme.danger : (quarter.netTax < 0 ? DomendraTheme.success : DomendraTheme.onSurfaceMuted);

                  return ListView(
                    controller: scrollController,
                    children: [
                      // Drag handle
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DomendraTheme.outline, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 12),
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                    child: Text(quarter.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(quarter.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                ]),
                                const SizedBox(height: 4),
                                Text(quarter.vehicleName, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // KPI grid 2x2
                      Row(
                        children: [
                          Expanded(child: _KpiTile(label: 'Total Miles', value: quarter.totalMiles.toStringAsFixed(0), color: DomendraTheme.primary)),
                          const SizedBox(width: 8),
                          Expanded(child: _KpiTile(label: 'Total Gallons', value: quarter.totalGallons.toStringAsFixed(1), color: DomendraTheme.warning)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _KpiTile(label: 'Avg MPG', value: quarter.totalGallons > 0 ? (quarter.totalMiles / quarter.totalGallons).toStringAsFixed(1) : '0', color: DomendraTheme.info)),
                          const SizedBox(width: 8),
                          Expanded(child: _KpiTile(label: 'Net Tax', value: _fmtMoney(quarter.netTax), color: netTaxColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tax Due vs Credit
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DomendraTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _TaxRow(label: 'Tax Due', value: quarter.totalTaxDue, color: DomendraTheme.danger),
                            _TaxRow(label: 'Tax Credit', value: quarter.totalTaxCredit, color: DomendraTheme.success),
                            const Divider(height: 16),
                            _TaxRow(label: 'Net Tax Owed', value: quarter.netTax, color: netTaxColor, bold: true),
                          ],
                        ),
                      ),
                      if (quarter.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(quarter.notes, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
                      ],
                      const SizedBox(height: 16),
                      // Breakdown table
                      const Text('Per-Jurisdiction Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (isLoading)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
                      else if (breakdown == null || breakdown.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No breakdown data', style: TextStyle(color: DomendraTheme.onSurfaceMuted))))
                      else
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: DomendraTheme.outline), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: [
                              // Header row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: const BorderRadius.vertical(top: Radius.circular(7))),
                                child: Row(
                                  children: const [
                                    Expanded(child: Text('Jur', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted))),
                                    SizedBox(width: 40, child: Text('Miles', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.right)),
                                    SizedBox(width: 50, child: Text('Gallons', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.right)),
                                    SizedBox(width: 50, child: Text('Rate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.right)),
                                    SizedBox(width: 50, child: Text('Tax Due', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.right)),
                                  ],
                                ),
                              ),
                              ...breakdown.map((row) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(row.jurisdiction, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
                                    SizedBox(width: 40, child: Text(row.miles.toStringAsFixed(0), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right)),
                                    SizedBox(width: 50, child: Text(row.gallons.toStringAsFixed(1), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right)),
                                    SizedBox(width: 50, child: Text(row.rate.toStringAsFixed(4), style: const TextStyle(fontSize: 10), textAlign: TextAlign.right)),
                                    SizedBox(width: 50, child: Text(_fmtMoney(row.taxDue), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.danger), textAlign: TextAlign.right)),
                                  ],
                                ),
                              )),
                              if (breakdown.isNotEmpty)
                                const Divider(height: 1),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Metadata
                      if (quarter.createdAt != null)
                        Text('Created: ${_fmtDate(quarter.createdAt!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                      const SizedBox(height: 8),
                      // Action buttons
                      Row(
                        children: [
                          if (quarter.status == 'draft')
                            Expanded(child: FilledButton.icon(
                              onPressed: () async {
                                if (quarter.id != null) await p.saveQuarter({'status': 'submitted'}, id: quarter.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.send, size: 14),
                              label: const Text('Submit', style: TextStyle(fontSize: 12)),
                            )),
                          if (quarter.status == 'submitted')
                            Expanded(child: FilledButton.icon(
                              onPressed: () async {
                                if (quarter.id != null) await p.saveQuarter({'status': 'filed'}, id: quarter.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text('File', style: TextStyle(fontSize: 12)),
                            )),
                          if (quarter.status != 'draft')
                            Expanded(child: TextButton.icon(
                              onPressed: () async {
                                if (quarter.id != null) await p.saveQuarter({'status': 'draft'}, id: quarter.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              icon: const Icon(Icons.undo, size: 14),
                              label: const Text('Revert', style: TextStyle(fontSize: 12)),
                            )),
                          Expanded(child: TextButton.icon(
                            onPressed: () async {
                              if (quarter.vehicleId != null && quarter.id != null) {
                                await p.generateQuarter({
                                  'vehicle': quarter.vehicleId,
                                  'year': quarter.year,
                                  'quarter': quarter.quarter,
                                });
                                await p.fetchBreakdown(quarter.id!);
                                setSheet(() {});
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Delete Report'),
                              content: const Text('Delete this quarterly report? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(dCtx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true && quarter.id != null) {
                            await p.deleteQuarter(quarter.id!);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 16, color: DomendraTheme.danger),
                        label: const Text('Delete Report', style: TextStyle(fontSize: 12, color: DomendraTheme.danger)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            );
          },
        );
      });
    },
  );
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS & HELPERS
// ════════════════════════════════════════════════════════════

class _ErrorBox extends StatelessWidget {
  final List<String> errors;
  const _ErrorBox({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList()),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _TaxRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _TaxRow({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 13 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(_fmtMoney(value), style: TextStyle(fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

String _fmtMoney(double v) => '$_currencySymbol${v.toStringAsFixed(v >= 1000 ? 0 : 2)}';

String _dateToInput(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
