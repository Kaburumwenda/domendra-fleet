import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/fuel_model.dart';
import '../../../providers/fuel_provider.dart';

String _currencySymbol = 'KSh';

void showFuelTransactionFormDialog(BuildContext context, FuelTransaction? existing) {
  final p = context.read<FuelProvider>();
  final isEdit = existing != null;

  final dateCtrl = TextEditingController(text: existing?.date != null ? _dateToInput(existing!.date!) : _dateToInput(DateTime.now()));
  final quantityCtrl = TextEditingController(text: existing != null ? existing.quantity.toString() : '');
  final costCtrl = TextEditingController(text: existing != null ? existing.totalCost.toString() : '');
  final odometerCtrl = TextEditingController(text: existing?.odometerReading?.toString() ?? '');
  final stationCtrl = TextEditingController(text: existing?.stationName ?? '');
  final locationCtrl = TextEditingController(text: existing?.stationLocation ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  String fuelType = existing?.fuelType ?? 'Diesel';
  String unit = existing?.unit ?? 'gallons';
  int? vehicleId = existing?.vehicleId ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  int? fuelCardId = existing?.fuelCardId;
  int? cardIdx = p.cards.indexWhere((c) => c.id == fuelCardId);
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Transaction' : 'Add Transaction'),
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
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) {
                    return DropdownMenuItem<int>(
                      value: v['id'] as int?,
                      child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: cardIdx != -1 ? cardIdx : null,
                  decoration: const InputDecoration(labelText: 'Fuel Card (optional)', prefixIcon: Icon(Icons.credit_card_outlined)),
                  items: p.cards.asMap().entries.map<DropdownMenuItem<int>>((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text('${e.value.providerLabel} •${e.value.maskedNumber}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) { if (v != null) setDialog(() { cardIdx = v; fuelCardId = p.cards[v].id; }); },
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
                DropdownButtonFormField<String>(
                  value: fuelType,
                  decoration: const InputDecoration(labelText: 'Fuel Type *', prefixIcon: Icon(Icons.local_gas_station_outlined)),
                  items: fuelTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => fuelType = v); },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: quantityCtrl,
                      decoration: const InputDecoration(labelText: 'Quantity *'),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: unitOptions.map((u) => DropdownMenuItem(value: u['value'], child: Text(u['label']!))).toList(),
                      onChanged: (v) { if (v != null) setDialog(() => unit = v); },
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costCtrl,
                  decoration: InputDecoration(labelText: 'Total Cost *', prefixText: '$_currencySymbol'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: odometerCtrl,
                  decoration: const InputDecoration(labelText: 'Odometer Reading'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                _ComboField(controller: stationCtrl, label: 'Station Name', items: stationOptions, icon: Icons.store_outlined),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Station Location'),
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
              if (quantityCtrl.text.isEmpty || double.tryParse(quantityCtrl.text) == null) errors.add('Valid quantity required');
              if (costCtrl.text.isEmpty || double.tryParse(costCtrl.text) == null) errors.add('Valid cost required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveTransaction({
                  'vehicle': vehicleId,
                  if (fuelCardId != null) 'fuel_card': fuelCardId,
                  'date': dateCtrl.text,
                  'fuel_type': fuelType,
                  'quantity': double.parse(quantityCtrl.text),
                  'unit': unit,
                  'total_cost': double.parse(costCtrl.text),
                  if (odometerCtrl.text.isNotEmpty) 'odometer_reading': int.tryParse(odometerCtrl.text),
                  'station_name': stationCtrl.text,
                  'station_location': locationCtrl.text,
                  'notes': notesCtrl.text,
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

void showFuelCardFormDialog(BuildContext context, FuelCard? existing) {
  final p = context.read<FuelProvider>();
  final isEdit = existing != null;

  final numberCtrl = TextEditingController(text: existing?.cardNumber ?? '');
  final holderCtrl = TextEditingController(text: existing?.cardHolderName ?? '');
  final expiryCtrl = TextEditingController(text: existing?.expiryDate != null ? _dateToInput(existing!.expiryDate!) : '');
  final accountIdCtrl = TextEditingController(text: existing?.providerAccountId ?? '');

  String provider = existing?.provider ?? 'WEX';
  int? vehicleId = existing?.vehicleId;
  bool isActive = existing?.isActive ?? true;
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Fuel Card' : 'Add Fuel Card'),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList()),
                  ),
                ],
                DropdownButtonFormField<String>(
                  value: provider,
                  decoration: const InputDecoration(labelText: 'Provider *', prefixIcon: Icon(Icons.credit_card)),
                  items: cardProviders.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => provider = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numberCtrl,
                  decoration: const InputDecoration(labelText: 'Card Number *', prefixIcon: Icon(Icons.numbers)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: holderCtrl,
                  decoration: const InputDecoration(labelText: 'Card Holder Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle (optional)', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('— No vehicle —')),
                    ...p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))),
                  ],
                  onChanged: (v) => setDialog(() => vehicleId = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: expiryCtrl,
                  decoration: const InputDecoration(labelText: 'Expiry Date', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (d != null) expiryCtrl.text = _dateToInput(d);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: accountIdCtrl,
                  decoration: const InputDecoration(labelText: 'Provider Account ID'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialog(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
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
              if (numberCtrl.text.isEmpty) errors.add('Card number required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveCard({
                  'provider': provider,
                  'card_number': numberCtrl.text,
                  'card_holder_name': holderCtrl.text,
                  if (vehicleId != null) 'vehicle': vehicleId,
                  if (expiryCtrl.text.isNotEmpty) 'expiry_date': expiryCtrl.text,
                  'provider_account_id': accountIdCtrl.text,
                  'is_active': isActive,
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

void showChargingFormDialog(BuildContext context, ChargingSession? existing) {
  final p = context.read<FuelProvider>();
  final isEdit = existing != null;

  final startCtrl = TextEditingController(text: existing?.startTime != null ? _dtToInput(existing!.startTime!) : _dtToInput(DateTime.now()));
  final endCtrl = TextEditingController(text: existing?.endTime != null ? _dtToInput(existing!.endTime!) : '');
  final energyCtrl = TextEditingController(text: existing != null ? existing.energyKwh.toString() : '');
  final costCtrl = TextEditingController(text: existing != null ? existing.cost.toString() : '');
  final stationCtrl = TextEditingController(text: existing?.stationName ?? '');
  final startSocCtrl = TextEditingController(text: existing?.startSoc?.toString() ?? '');
  final endSocCtrl = TextEditingController(text: existing?.endSoc?.toString() ?? '');

  String network = existing?.stationNetwork ?? 'chargepoint';
  int? vehicleId = existing?.vehicleId ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Charging Session' : 'Add Charging Session'),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList()),
                  ),
                ],
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(labelText: 'Start Time *', prefixIcon: Icon(Icons.play_arrow)),
                  readOnly: true,
                  onTap: () async => _pickDateTime(ctx, startCtrl),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.stop)),
                  readOnly: true,
                  onTap: () async => _pickDateTime(ctx, endCtrl),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: energyCtrl,
                      decoration: const InputDecoration(labelText: 'Energy (kWh) *'),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: costCtrl,
                      decoration: InputDecoration(labelText: 'Cost *', prefixText: _currencySymbol),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: network,
                  decoration: const InputDecoration(labelText: 'Network', prefixIcon: Icon(Icons.ev_station)),
                  items: chargingNetworks.map((n) => DropdownMenuItem(value: n['value'], child: Text(n['label']!))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => network = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stationCtrl,
                  decoration: const InputDecoration(labelText: 'Station Name'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startSocCtrl, decoration: const InputDecoration(labelText: 'Start SoC %'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endSocCtrl, decoration: const InputDecoration(labelText: 'End SoC %'), keyboardType: TextInputType.number)),
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
              if (vehicleId == null) errors.add('Vehicle required');
              if (energyCtrl.text.isEmpty || double.tryParse(energyCtrl.text) == null) errors.add('Valid energy required');
              if (costCtrl.text.isEmpty || double.tryParse(costCtrl.text) == null) errors.add('Valid cost required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveCharging({
                  'vehicle': vehicleId,
                  'start_time': startCtrl.text,
                  if (endCtrl.text.isNotEmpty) 'end_time': endCtrl.text,
                  'energy_kwh': double.parse(energyCtrl.text),
                  'cost': double.parse(costCtrl.text),
                  'station_network': network,
                  'station_name': stationCtrl.text,
                  if (startSocCtrl.text.isNotEmpty) 'start_soc': double.parse(startSocCtrl.text),
                  if (endSocCtrl.text.isNotEmpty) 'end_soc': double.parse(endSocCtrl.text),
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

void showIdlingFormDialog(BuildContext context, IdlingEvent? existing) {
  final p = context.read<FuelProvider>();
  final isEdit = existing != null;

  final startCtrl = TextEditingController(text: existing?.startTime != null ? _dtToInput(existing!.startTime!) : _dtToInput(DateTime.now()));
  final endCtrl = TextEditingController(text: existing?.endTime != null ? _dtToInput(existing!.endTime!) : '');
  final burnRateCtrl = TextEditingController(text: existing != null ? existing.fuelBurnRate.toString() : '0.5');
  final priceCtrl = TextEditingController(text: existing != null ? existing.fuelPricePerGallon.toString() : '3.50');
  final locationCtrl = TextEditingController(text: existing?.location ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  int? vehicleId = existing?.vehicleId ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Idling Event' : 'Add Idling Event'),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList()),
                  ),
                ],
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(labelText: 'Start Time *', prefixIcon: Icon(Icons.play_arrow)),
                  readOnly: true,
                  onTap: () async => _pickDateTime(ctx, startCtrl),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(labelText: 'End Time', prefixIcon: Icon(Icons.stop)),
                  readOnly: true,
                  onTap: () async => _pickDateTime(ctx, endCtrl),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: burnRateCtrl, decoration: const InputDecoration(labelText: 'Burn Rate (gal/h)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: priceCtrl, decoration: InputDecoration(labelText: 'Fuel Price', prefixText: _currencySymbol), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
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
              if (vehicleId == null) errors.add('Vehicle required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveIdling({
                  'vehicle': vehicleId,
                  'start_time': startCtrl.text,
                  if (endCtrl.text.isNotEmpty) 'end_time': endCtrl.text,
                  'fuel_burn_rate': double.tryParse(burnRateCtrl.text) ?? 0.5,
                  'fuel_price_per_gallon': double.tryParse(priceCtrl.text) ?? 3.50,
                  'location': locationCtrl.text,
                  'notes': notesCtrl.text,
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

void showFuelBudgetFormDialog(BuildContext context, FuelBudget? existing) {
  final p = context.read<FuelProvider>();
  final isEdit = existing != null;

  final monthCtrl = TextEditingController(text: existing?.month != null ? _dateToInput(existing!.month!) : _dateToInput(DateTime.now()));
  final budgetCtrl = TextEditingController(text: existing != null ? existing.budgetAmount.toString() : '');
  final targetRefCtrl = TextEditingController(text: existing?.targetRef ?? '');

  String scope = existing?.scope ?? 'fleet';
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Budget' : 'Add Budget'),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList()),
                  ),
                ],
                DropdownButtonFormField<String>(
                  value: scope,
                  decoration: const InputDecoration(labelText: 'Scope *', prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'fleet', child: Text('Fleet')),
                    DropdownMenuItem(value: 'vehicle_type', child: Text('Vehicle Type')),
                    DropdownMenuItem(value: 'location', child: Text('Location')),
                  ],
                  onChanged: (v) { if (v != null) setDialog(() => scope = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: targetRefCtrl,
                  decoration: InputDecoration(labelText: 'Target Reference ${scope == 'fleet' ? '(optional)' : '*'}'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: monthCtrl,
                  decoration: const InputDecoration(labelText: 'Month *', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) monthCtrl.text = _dateToInput(d);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: budgetCtrl,
                  decoration: InputDecoration(labelText: 'Budget Amount *', prefixText: _currencySymbol),
                  keyboardType: TextInputType.number,
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
              if (budgetCtrl.text.isEmpty || double.tryParse(budgetCtrl.text) == null) errors.add('Valid budget amount required');
              if (scope != 'fleet' && targetRefCtrl.text.isEmpty) errors.add('Target reference required for this scope');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveBudget({
                  'scope': scope,
                  'target_ref': targetRefCtrl.text,
                  'month': monthCtrl.text,
                  'budget_amount': double.parse(budgetCtrl.text),
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

void showScheduleFormDialog(BuildContext context, ChargeSchedule? existing) {
  final p = context.read<FuelProvider>();
  final isEdit = existing != null;

  final startCtrl = TextEditingController(text: existing?.startTime ?? '22:00');
  final endCtrl = TextEditingController(text: existing?.endTime ?? '06:00');
  final socCtrl = TextEditingController(text: existing != null ? existing.targetSoc.toString() : '80');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  final daysCtrl = TextEditingController(text: existing?.recurringDays ?? '');

  int? vehicleId = existing?.vehicleId ?? (p.vehicles.isNotEmpty ? p.vehicles.first['id'] : null);
  bool isActive = existing?.isActive ?? true;
  Set<String> selectedDays = existing != null ? existing.recurringDaysList.toSet() : {};
  bool saving = false;
  List<String> errors = [];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) {
      return AlertDialog(
        title: Text(isEdit ? 'Edit Charge Schedule' : 'Add Charge Schedule'),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: errors.map((e) => Text('• $e', style: const TextStyle(fontSize: 12, color: DomendraTheme.danger))).toList()),
                  ),
                ],
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle *', prefixIcon: Icon(Icons.directions_car_outlined)),
                  items: p.vehicles.map<DropdownMenuItem<int>>((v) => DropdownMenuItem(value: v['id'] as int?, child: Text(v['display_name'] ?? v['name'] ?? 'Vehicle ${v['id']}'))).toList(),
                  onChanged: (v) { if (v != null) setDialog(() => vehicleId = v); },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start (HH:mm)'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End (HH:mm)'))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: socCtrl,
                  decoration: const InputDecoration(labelText: 'Target SoC (%)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Recurring Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: weekdays.map((wd) {
                    final selected = selectedDays.contains(wd['value']);
                    return FilterChip(
                      label: Text(wd['label']!, style: TextStyle(fontSize: 10)),
                      selected: selected,
                      onSelected: (v) => setDialog(() {
                        if (v) selectedDays.add(wd['value']!);
                        else selectedDays.remove(wd['value']!);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialog(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
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
              if (vehicleId == null) errors.add('Vehicle required');
              if (errors.isNotEmpty) { setDialog(() {}); return; }

              setDialog(() => saving = true);
              try {
                await p.saveSchedule({
                  'vehicle': vehicleId,
                  'start_time': startCtrl.text,
                  'end_time': endCtrl.text,
                  'target_soc': double.tryParse(socCtrl.text) ?? 80,
                  'recurring_days': selectedDays.join(','),
                  'is_active': isActive,
                  'notes': notesCtrl.text,
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
// Shared helpers
// ════════════════════════════════════════════════════════════

class _ComboField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final List<String> items;
  final IconData icon;
  const _ComboField({required this.controller, required this.label, required this.items, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return items.take(5);
        return items.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (v) => controller.text = v,
      fieldViewBuilder: (ctx2, ctrl, focus, onFieldSubmitted) {
        return TextField(
          controller: ctrl,
          focusNode: focus,
          onSubmitted: (v) { controller.text = v; onFieldSubmitted(); },
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        );
      },
    );
  }
}

String _dateToInput(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _dtToInput(DateTime d) => '${_dateToInput(d)}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Future<void> _pickDateTime(BuildContext ctx, TextEditingController ctrl) async {
  final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
  if (d == null) return;
  if (!ctx.mounted) return;
  final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
  if (t == null) return;
  ctrl.text = _dtToInput(DateTime(d.year, d.month, d.day, t.hour, t.minute));
}
