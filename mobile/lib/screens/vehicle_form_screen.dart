import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/vehicle_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

/// Vehicle Form Wizard — mirrors the web `VehicleFormWizard.vue`.
///
/// 7-step create/edit wizard:
///  0. Details         — VIN (with decode), plate, make/model/year, type, status
///  1. Maintenance     — preventive reminders
///  2. Lifecycle       — ownership, lease dates, in/out service
///  3. Financials      — purchase price, depreciation, lease rate
///  4. Insurance       — type, premium, dates
///  5. Specifications   — engine, transmission, drivetrain, mileage, EV fields
///  6. Custom Fields   — user-defined dynamic fields
class VehicleFormScreen extends StatefulWidget {
  final int? vehicleId; // null = create, non-null = edit

  const VehicleFormScreen({super.key, this.vehicleId});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  int _currentStep = 0;
  bool _loading = false;
  bool _saving = false;
  bool _decoding = false;

  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{};

  static const _steps = [
    'Details',
    'Maintenance',
    'Lifecycle',
    'Financials',
    'Insurance',
    'Specifications',
    'Custom Fields',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.vehicleId != null) {
      _loadVehicle();
    }
  }

  Future<void> _loadVehicle() async {
    setState(() {
      _loading = true;
    });
    try {
      final v = await ApiService.instance.fetchVehicle(widget.vehicleId!);
      _data.addAll(v);
    } catch (_) {
      // Non-fatal — form fields stay empty for manual entry
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _decodeVin() async {
    final vin = (_data['vin'] as String?)?.toUpperCase().trim() ?? '';
    if (vin.length != 17) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VIN must be exactly 17 characters (US/EU vehicles).'),
          backgroundColor: DomendraTheme.warning,
        ),
      );
      return;
    }
    setState(() => _decoding = true);
    try {
      final result = await context.read<VehiclesProvider>().vinDecode(vin);
      if (result != null) {
        setState(() {
          if (result['make'] != null && (result['make'] as String).isNotEmpty) _data['make'] = result['make'];
          if (result['model'] != null && (result['model'] as String).isNotEmpty) _data['model'] = result['model'];
          if (result['year'] != null) _data['year'] = int.tryParse(result['year'].toString());
          if (result['engine'] != null && (result['engine'] as String).isNotEmpty) _data['engine'] = result['engine'];
          if (result['transmission'] != null && (result['transmission'] as String).isNotEmpty) _data['transmission'] = result['transmission'];
          if (result['fuel_type'] != null && (result['fuel_type'] as String).isNotEmpty) _data['fuel_type'] = _matchFuelType(result['fuel_type']);
          if (result['weight_rating'] != null && (result['weight_rating'] as String).isNotEmpty) _data['weight_rating'] = result['weight_rating'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('VIN decoded successfully'), backgroundColor: DomendraTheme.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to decode VIN'), backgroundColor: DomendraTheme.danger),
          );
        }
      }
    } finally {
      setState(() => _decoding = false);
    }
  }

  String _matchFuelType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('electric')) return 'Electric';
    if (lower.contains('hybrid') && lower.contains('plug')) return 'Plug-in Hybrid (Petrol)';
    if (lower.contains('hybrid')) return 'Hybrid (Petrol)';
    if (lower.contains('diesel')) return 'Diesel';
    if (lower.contains('gasoline') || lower.contains('petrol')) return 'Petrol';
    if (lower.contains('hydrogen') || lower.contains('fuel cell')) return 'Fuel Cell (Hydrogen)';
    if (lower.contains('lpg')) return 'LPG';
    if (lower.contains('cng')) return 'CNG';
    if (lower.contains('ethanol')) return 'Ethanol (E85)';
    return raw;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });
    try {
      final provider = context.read<VehiclesProvider>();
      if (widget.vehicleId != null) {
        await provider.updateVehicleData(widget.vehicleId!, _data);
      } else {
        await provider.createVehicle(_data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicleId != null ? 'Vehicle updated' : 'Vehicle created'),
            backgroundColor: DomendraTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _prev() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicleId != null;

    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Vehicle' : 'New Vehicle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/app/vehicles'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _StepIndicator(currentStep: _currentStep, steps: _steps),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildCurrentStep(),
                    ),
                  ),
                  _BottomNav(
                    currentStep: _currentStep,
                    totalSteps: _steps.length,
                    onPrev: _prev,
                    onNext: _next,
                    saving: _saving,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _DetailsStep(data: _data, onDecode: _decodeVin, decoding: _decoding, onChanged: () => setState(() {}));
      case 1:
        return _MaintenanceStep(data: _data, onChanged: () => setState(() {}));
      case 2:
        return _LifecycleStep(data: _data, onChanged: () => setState(() {}));
      case 3:
        return _FinancialsStep(data: _data, onChanged: () => setState(() {}));
      case 4:
        return _InsuranceStep(data: _data, onChanged: () => setState(() {}));
      case 5:
        return _SpecsStep(data: _data, onChanged: () => setState(() {}));
      case 6:
        return _CustomFieldsStep(data: _data, onChanged: () => setState(() {}));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ════════════════════════════════════════════════════════════
// Step indicator
// ════════════════════════════════════════════════════════════
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (i) {
            final isActive = i == currentStep;
            final isDone = i < currentStep;
            final color = isActive
                ? DomendraTheme.primary
                : isDone
                    ? DomendraTheme.success
                    : DomendraTheme.onSurfaceMuted;
            return Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: isActive || isDone ? DomendraTheme.primaryGradient : null,
                    color: !isActive && !isDone ? DomendraTheme.surfaceVariant : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive || isDone ? Colors.white : DomendraTheme.onSurfaceMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
                if (i < steps.length - 1) ...[
                  const SizedBox(width: 6),
                  Container(width: 24, height: 2, color: i < currentStep ? DomendraTheme.success : DomendraTheme.outline),
                  const SizedBox(width: 6),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Bottom navigation (Back / Next / Save)
// ════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool saving;

  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.onPrev,
    required this.onNext,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        border: Border(top: BorderSide(color: DomendraTheme.outline)),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrev,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: saving ? null : onNext,
              icon: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.save : Icons.arrow_forward, size: 18),
              label: Text(isLast ? 'Save' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 0: DETAILS
// ════════════════════════════════════════════════════════════
class _DetailsStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDecode;
  final bool decoding;
  final VoidCallback onChanged;

  const _DetailsStep({
    required this.data,
    required this.onDecode,
    required this.decoding,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Vehicle Details'),
        // VIN with decode
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextFormField(
                initialValue: data['vin']?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'VIN'),
                maxLength: 17,
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => data['vin'] = v.toUpperCase(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: decoding ? null : onDecode,
                child: decoding
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Decode'),
              ),
            ),
          ],
        ),
        TextFormField(
          initialValue: data['license_plate']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'License Plate'),
          onChanged: (v) => data['license_plate'] = v,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: data['year']?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
                onChanged: (v) => data['year'] = int.tryParse(v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: data['make']?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Make'),
                onChanged: (v) => data['make'] = v,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: data['model']?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Model'),
                onChanged: (v) => data['model'] = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: data['body_type']?.toString() ?? '',
                decoration: const InputDecoration(labelText: 'Body Type'),
                onChanged: (v) => data['body_type'] = v,
              ),
            ),
          ],
        ),
        _DropdownField(
          label: 'Vehicle Type',
          value: data['vehicle_type']?.toString(),
          options: const [
            ('vehicle', 'Vehicle'),
            ('trailer', 'Trailer'),
            ('equipment', 'Equipment'),
            ('non_powered', 'Non-Powered'),
          ],
          onChanged: (v) {
            data['vehicle_type'] = v;
            onChanged();
          },
        ),
        _DropdownField(
          label: 'Status',
          value: data['status']?.toString() ?? 'active',
          options: const [
            ('active', 'Active'),
            ('out_of_service', 'Out of Service'),
            ('in_maintenance', 'In Maintenance'),
            ('retired', 'Retired'),
          ],
          onChanged: (v) {
            data['status'] = v;
            onChanged();
          },
        ),
        TextFormField(
          initialValue: data['location']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Location / Yard'),
          onChanged: (v) => data['location'] = v,
        ),
        TextFormField(
          initialValue: data['color']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Color'),
          onChanged: (v) => data['color'] = v,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 1: MAINTENANCE (Reminders)
// ════════════════════════════════════════════════════════════
class _MaintenanceStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _MaintenanceStep({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final reminders = (data['reminders'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Preventive Maintenance Reminders'),
        Text(
          'Reminders are managed per-vehicle after creation.',
          style: TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted),
        ),
        const SizedBox(height: 16),
        if (reminders.isEmpty)
          const _InfoCard(
            icon: Icons.notifications_outlined,
            title: 'No reminders',
            subtitle: 'Maintenance reminders can be added after the vehicle is saved.',
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 2: LIFECYCLE
// ════════════════════════════════════════════════════════════
class _LifecycleStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _LifecycleStep({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ownership = (data['ownership'] as String?) ?? 'self';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Ownership & Lifecycle'),
        _DropdownField(
          label: 'Ownership',
          value: ownership,
          options: const [('self', 'Owned'), ('lease', 'Leased')],
          onChanged: (v) {
            data['ownership'] = v;
            onChanged();
          },
        ),
        if (ownership == 'lease') ...[
          TextFormField(
            initialValue: data['lease_start_date']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Lease Start Date (YYYY-MM-DD)'),
            onChanged: (v) => data['lease_start_date'] = v,
          ),
          TextFormField(
            initialValue: data['lease_end_date']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Lease End Date (YYYY-MM-DD)'),
            onChanged: (v) => data['lease_end_date'] = v,
          ),
        ],
        TextFormField(
          initialValue: data['in_service_date']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'In Service Date (YYYY-MM-DD)'),
          onChanged: (v) => data['in_service_date'] = v,
        ),
        TextFormField(
          initialValue: data['out_of_service_date']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Out of Service Date (YYYY-MM-DD)'),
          onChanged: (v) => data['out_of_service_date'] = v,
        ),
        TextFormField(
          initialValue: data['retired_date']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Retired Date (YYYY-MM-DD)'),
          onChanged: (v) => data['retired_date'] = v,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 3: FINANCIALS
// ════════════════════════════════════════════════════════════
class _FinancialsStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _FinancialsStep({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ownership = (data['ownership'] as String?) ?? 'self';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Financial Details'),
        if (ownership == 'lease') ...[
          TextFormField(
            initialValue: data['lease_monthly_rate']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Lease Monthly Rate'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['lease_monthly_rate'] = double.tryParse(v),
          ),
          TextFormField(
            initialValue: data['deposit']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Deposit'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['deposit'] = double.tryParse(v),
          ),
        ] else ...[
          TextFormField(
            initialValue: data['purchase_price']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Purchase Price'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['purchase_price'] = double.tryParse(v),
          ),
          TextFormField(
            initialValue: data['purchase_date']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Purchase Date (YYYY-MM-DD)'),
            onChanged: (v) => data['purchase_date'] = v,
          ),
          TextFormField(
            initialValue: data['salvage_value']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Salvage / Residual Value'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['salvage_value'] = double.tryParse(v),
          ),
          TextFormField(
            initialValue: data['useful_life_years']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Useful Life (Years)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['useful_life_years'] = int.tryParse(v),
          ),
          _DropdownField(
            label: 'Depreciation Method',
            value: data['depreciation_method']?.toString() ?? 'straight_line',
            options: const [
              ('straight_line', 'Straight Line'),
              ('declining_balance', 'Declining Balance'),
              ('none', 'None'),
            ],
            onChanged: (v) {
              data['depreciation_method'] = v;
              onChanged();
            },
          ),
          TextFormField(
            initialValue: data['monthly_payment']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Monthly Payment'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['monthly_payment'] = double.tryParse(v),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 4: INSURANCE
// ════════════════════════════════════════════════════════════
class _InsuranceStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _InsuranceStep({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Insurance'),
        _DropdownField(
          label: 'Coverage Type',
          value: data['insurance_type']?.toString(),
          options: const [
            ('comprehensive', 'Comprehensive'),
            ('third_party', 'Third Party'),
            ('collision', 'Collision'),
            ('liability', 'Liability'),
            ('gap', 'GAP'),
          ],
          onChanged: (v) {
            data['insurance_type'] = v;
            onChanged();
          },
        ),
        TextFormField(
          initialValue: data['insurance_premium']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Premium Amount'),
          keyboardType: TextInputType.number,
          onChanged: (v) => data['insurance_premium'] = double.tryParse(v),
        ),
        TextFormField(
          initialValue: data['insurance_start_date']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Policy Start Date (YYYY-MM-DD)'),
          onChanged: (v) => data['insurance_start_date'] = v,
        ),
        TextFormField(
          initialValue: data['insurance_end_date']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Policy End Date (YYYY-MM-DD)'),
          onChanged: (v) => data['insurance_end_date'] = v,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 5: SPECIFICATIONS
// ════════════════════════════════════════════════════════════
class _SpecsStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _SpecsStep({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fuelType = (data['fuel_type'] as String?) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Powertrain'),
        _DropdownField(
          label: 'Fuel Type',
          value: fuelType,
          options: fuelTypes.map((f) => (f, f)).toList(),
          onChanged: (v) {
            data['fuel_type'] = v;
            onChanged();
          },
        ),
        if (!fuelType.toLowerCase().contains('electric')) ...[
          TextFormField(
            initialValue: data['engine_size']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Engine Size'),
            onChanged: (v) => data['engine_size'] = v,
          ),
          TextFormField(
            initialValue: data['tank_capacity']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Tank Capacity'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['tank_capacity'] = double.tryParse(v),
          ),
        ],
        TextFormField(
          initialValue: data['engine']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Engine'),
          onChanged: (v) => data['engine'] = v,
        ),
        TextFormField(
          initialValue: data['transmission']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Transmission'),
          onChanged: (v) => data['transmission'] = v,
        ),
        _DropdownField(
          label: 'Drivetrain',
          value: data['drivetrain']?.toString(),
          options: const [
            ('2WD', '2WD'),
            ('4WD', '4WD'),
            ('4x2', '4x2'),
            ('4x4', '4x4'),
            ('6x2', '6x2'),
            ('6x4', '6x4'),
            ('8x4', '8x4'),
          ],
          onChanged: (v) {
            data['drivetrain'] = v;
            onChanged();
          },
        ),
        _DropdownField(
          label: 'Steering',
          value: data['steering']?.toString(),
          options: const [('left', 'Left'), ('right', 'Right')],
          onChanged: (v) {
            data['steering'] = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Mileage'),
        TextFormField(
          initialValue: data['current_mileage']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Current Mileage'),
          keyboardType: TextInputType.number,
          onChanged: (v) => data['current_mileage'] = int.tryParse(v),
        ),
        _DropdownField(
          label: 'Mileage Unit',
          value: data['mileage_unit']?.toString() ?? 'km',
          options: const [('km', 'Kilometers'), ('miles', 'Miles')],
          onChanged: (v) {
            data['mileage_unit'] = v;
            onChanged();
          },
        ),
        TextFormField(
          initialValue: data['engine_hours']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Engine Hours'),
          keyboardType: TextInputType.number,
          onChanged: (v) => data['engine_hours'] = double.tryParse(v),
        ),
        const SizedBox(height: 16),
        if (_isEvOrHybrid(fuelType)) ...[
          const _SectionTitle('Battery'),
          TextFormField(
            initialValue: data['battery_capacity_kwh']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'Battery Capacity (kWh)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['battery_capacity_kwh'] = double.tryParse(v),
          ),
          TextFormField(
            initialValue: data['state_of_charge']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'State of Charge (%)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['state_of_charge'] = double.tryParse(v),
          ),
          TextFormField(
            initialValue: data['state_of_health']?.toString() ?? '',
            decoration: const InputDecoration(labelText: 'State of Health (%)'),
            keyboardType: TextInputType.number,
            onChanged: (v) => data['state_of_health'] = double.tryParse(v),
          ),
        ],
      ],
    );
  }

  bool _isEvOrHybrid(String fuelType) {
    final ft = fuelType.toLowerCase();
    return ft == 'electric' || ft.contains('hybrid') || ft.contains('fuel cell') || ft.contains('plug-in');
  }
}

// ════════════════════════════════════════════════════════════
// Step 6: CUSTOM FIELDS
// ════════════════════════════════════════════════════════════
class _CustomFieldsStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  const _CustomFieldsStep({required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Custom Fields'),
        const _InfoCard(
          icon: Icons.extension_outlined,
          title: 'User-defined fields',
          subtitle: 'Custom fields can be configured after the vehicle is saved.',
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;

  const _DropdownField({required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: options.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DomendraTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: DomendraTheme.onSurfaceMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
