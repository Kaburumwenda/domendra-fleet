import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

/// Vehicle Detail / View screen — mirrors the web `VehicleViewWizard.vue`.
///
/// Read-only vertical wizard showing per-vehicle details:
///  1. Details  2. Maintenance  3. Lifecycle  4. Financials  5. Insurance
///  6. Specifications  7. Custom Fields  8. Profit & Loss  9. Cost of Ownership
class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profitLoss;
  Map<String, dynamic>? _tco;
  bool _loadingPnl = false;
  bool _loadingTco = false;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.fetchVehicle(widget.vehicleId);
      setState(() => _vehicle = Vehicle(data));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPnl() async {
    if (_loadingPnl) return;
    setState(() => _loadingPnl = true);
    try {
      final data = await ApiService.instance.fetchVehicleProfitLoss(widget.vehicleId);
      setState(() => _profitLoss = data);
    } catch (_) {}
    finally {
      setState(() => _loadingPnl = false);
    }
  }

  Future<void> _loadTco() async {
    if (_loadingTco) return;
    setState(() => _loadingTco = true);
    try {
      final data = await ApiService.instance.fetchVehicleCostOfOwnership(widget.vehicleId);
      setState(() => _tco = data);
    } catch (_) {}
    finally {
      setState(() => _loadingTco = false);
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete "${_vehicle?.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<VehiclesProvider>();
      await provider.deleteVehicle(widget.vehicleId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle deleted'), backgroundColor: DomendraTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(_vehicle?.displayName ?? 'Vehicle Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_vehicle != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pushNamed(context, '/app/vehicles/${_vehicle!.id}/edit'),
            ),
          if (_vehicle != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: DomendraTheme.danger),
              onPressed: _deleteVehicle,
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/app/vehicles'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadVehicle)
              : _vehicle == null
                  ? const Center(child: Text('Vehicle not found'))
                  : RefreshIndicator(
                      onRefresh: _loadVehicle,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _HeaderCard(vehicle: _vehicle!),
                          const SizedBox(height: 12),
                          _DetailsSection(vehicle: _vehicle!),
                          const SizedBox(height: 8),
                          _LifecycleSection(vehicle: _vehicle!),
                          const SizedBox(height: 8),
                          _FinancialsSection(vehicle: _vehicle!),
                          const SizedBox(height: 8),
                          _InsuranceSection(vehicle: _vehicle!),
                          const SizedBox(height: 8),
                          _SpecsSection(vehicle: _vehicle!),
                          const SizedBox(height: 8),
                          _ProfitLossSection(
                            vehicleId: widget.vehicleId,
                            data: _profitLoss,
                            loading: _loadingPnl,
                            onLoad: _loadPnl,
                          ),
                          const SizedBox(height: 8),
                          _TcoSection(
                            vehicleId: widget.vehicleId,
                            data: _tco,
                            loading: _loadingTco,
                            onLoad: _loadTco,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Header card with key info
// ════════════════════════════════════════════════════════════
class _HeaderCard extends StatelessWidget {
  final Vehicle vehicle;
  const _HeaderCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: DomendraTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  vehicle.isElectric ? Icons.electric_car : Icons.directions_car,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    if (vehicle.licensePlate.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehicle.licensePlate,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: vehicle.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (vehicle.fuelType.isNotEmpty)
                _HeaderChip(icon: Icons.local_gas_station, label: vehicle.fuelType),
              if (vehicle.location.isNotEmpty) ...[
                const SizedBox(width: 8),
                _HeaderChip(icon: Icons.location_on, label: vehicle.location),
              ],
              const SizedBox(width: 8),
              _HeaderChip(icon: vehicle.ownership == VehicleOwnership.lease ? Icons.handshake : Icons.person, label: vehicle.ownership.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final VehicleStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VehicleStatus.active => Colors.green.shade100,
      VehicleStatus.outOfService => Colors.orange.shade100,
      VehicleStatus.inMaintenance => Colors.amber.shade100,
      VehicleStatus.retired => Colors.red.shade100,
    };
    final textColor = switch (status) {
      VehicleStatus.active => Colors.green.shade800,
      VehicleStatus.outOfService => Colors.orange.shade800,
      VehicleStatus.inMaintenance => Colors.amber.shade800,
      VehicleStatus.retired => Colors.red.shade800,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Detail sections
// ════════════════════════════════════════════════════════════
class _DetailsSection extends StatelessWidget {
  final Vehicle vehicle;
  const _DetailsSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Details',
      icon: Icons.info_outline,
      children: [
        _FieldRow(label: 'VIN', value: vehicle.vin),
        _FieldRow(label: 'License Plate', value: vehicle.licensePlate),
        _FieldRow(label: 'Year', value: vehicle.year > 0 ? '${vehicle.year}' : '-'),
        _FieldRow(label: 'Make', value: vehicle.make),
        _FieldRow(label: 'Model', value: vehicle.model),
        _FieldRow(label: 'Body Type', value: vehicle.bodyType),
        _FieldRow(label: 'Vehicle Type', value: vehicle.vehicleType),
        _FieldRow(label: 'Group', value: vehicle.groupName),
        _FieldRow(label: 'Location', value: vehicle.location),
        _FieldRow(label: 'Assigned Driver', value: vehicle.assignedDriverName),
        _FieldRow(label: 'Color', value: vehicle.color),
      ],
    );
  }
}

class _LifecycleSection extends StatelessWidget {
  final Vehicle vehicle;
  const _LifecycleSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Lifecycle',
      icon: Icons.timeline,
      children: [
        _FieldRow(label: 'Ownership', value: vehicle.ownership.label),
        if (vehicle.ownership == VehicleOwnership.lease) ...[
          if (vehicle.lessorName.isNotEmpty) _FieldRow(label: 'Lessor', value: vehicle.lessorName),
          _FieldRow(label: 'Lease Start', value: _fmtDate(vehicle.leaseStartDate)),
          _FieldRow(label: 'Lease End', value: _fmtDate(vehicle.leaseEndDate)),
          if (vehicle.leaseDaysLeft != null)
            _FieldRow(
              label: 'Lease Remaining',
              value: vehicle.leaseDaysLeft! < 0
                  ? 'Expired ${vehicle.leaseDaysLeft!.abs()}d ago'
                  : '${vehicle.leaseDaysLeft}d left',
            ),
        ],
        _FieldRow(label: 'In Service', value: _fmtDate(vehicle.inServiceDate)),
        _FieldRow(label: 'Out of Service', value: _fmtDate(vehicle.outOfServiceDate)),
        _FieldRow(label: 'Retired', value: _fmtDate(vehicle.retiredDate)),
      ],
    );
  }
}

class _FinancialsSection extends StatelessWidget {
  final Vehicle vehicle;
  const _FinancialsSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Financials',
      icon: Icons.attach_money,
      children: [
        if (vehicle.ownership == VehicleOwnership.lease) ...[
          _FieldRow(label: 'Lease Monthly Rate', value: _fmtMoney(vehicle.leaseMonthlyRate)),
          _FieldRow(label: 'Deposit', value: _fmtMoney(vehicle.deposit)),
        ] else ...[
          _FieldRow(label: 'Purchase Price', value: _fmtMoney(vehicle.purchasePrice)),
          _FieldRow(label: 'Purchase Date', value: _fmtDate(vehicle.purchaseDate)),
          _FieldRow(label: 'Salvage Value', value: _fmtMoney(vehicle.salvageValue)),
          _FieldRow(label: 'Useful Life', value: vehicle.usefulLifeYears != null ? '${vehicle.usefulLifeYears} years' : '-'),
          _FieldRow(label: 'Depreciation Method', value: vehicle.depreciationMethod.isNotEmpty ? vehicle.depreciationMethod : '-'),
          _FieldRow(label: 'Residual Value', value: _fmtMoney(vehicle.residualValue)),
          _FieldRow(label: 'Monthly Payment', value: _fmtMoney(vehicle.monthlyPayment)),
          _FieldRow(label: 'Annual Depreciation', value: _fmtMoney(vehicle.annualDepreciation)),
          _FieldRow(label: 'Current Book Value', value: _fmtMoney(vehicle.currentBookValue)),
        ],
      ],
    );
  }
}

class _InsuranceSection extends StatelessWidget {
  final Vehicle vehicle;
  const _InsuranceSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Insurance',
      icon: Icons.shield_outlined,
      children: [
        _FieldRow(label: 'Coverage Type', value: vehicle.insuranceType),
        _FieldRow(label: 'Premium', value: _fmtMoney(vehicle.insurancePremium)),
        _FieldRow(label: 'Policy Start', value: _fmtDate(vehicle.insuranceStartDate)),
        _FieldRow(label: 'Policy End', value: _fmtDate(vehicle.insuranceEndDate)),
      ],
    );
  }
}

class _SpecsSection extends StatelessWidget {
  final Vehicle vehicle;
  const _SpecsSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Specifications',
      icon: Icons.settings,
      children: [
        _FieldRow(label: 'Fuel Type', value: vehicle.fuelType),
        _FieldRow(label: 'Engine', value: vehicle.engine),
        _FieldRow(label: 'Engine Size', value: vehicle.engineSize),
        _FieldRow(label: 'Transmission', value: vehicle.transmission),
        _FieldRow(label: 'Drivetrain', value: vehicle.drivetrain),
        _FieldRow(label: 'Steering', value: vehicle.steering),
        _FieldRow(label: 'Current Mileage', value: '${_fmtNum(vehicle.currentMileage)} ${vehicle.mileageUnit}'),
        _FieldRow(label: 'Engine Hours', value: vehicle.engineHours > 0 ? vehicle.engineHours.toString() : '-'),
        if (vehicle.isEvOrHybrid) ...[
          _FieldRow(label: 'Battery (kWh)', value: _fmtNum2(vehicle.batteryCapacityKwh)),
          _FieldRow(label: 'State of Charge', value: _fmtPct(vehicle.stateOfCharge)),
          _FieldRow(label: 'State of Health', value: _fmtPct(vehicle.stateOfHealth)),
        ],
        if (vehicle.rentalStatus != RentalStatus.none) ...[
          const SizedBox(height: 8),
          _FieldRow(label: 'Rental Status', value: vehicle.rentalStatus.label),
          _FieldRow(label: 'Agreement #', value: vehicle.rentalAgreementNo),
          _FieldRow(label: 'Customer', value: vehicle.rentalCustomerName),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Profit & Loss section
// ════════════════════════════════════════════════════════════
class _ProfitLossSection extends StatefulWidget {
  final int vehicleId;
  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onLoad;

  const _ProfitLossSection({
    required this.vehicleId,
    required this.data,
    required this.loading,
    required this.onLoad,
  });

  @override
  State<_ProfitLossSection> createState() => _ProfitLossSectionState();
}

class _ProfitLossSectionState extends State<_ProfitLossSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Profit & Loss',
      icon: Icons.trending_up,
      children: [
        if (widget.loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (widget.data == null)
          const Text('No P&L data available', style: TextStyle(color: DomendraTheme.onSurfaceMuted))
        else ...[
          _FieldRow(label: 'Revenue', value: _fmtMoney(widget.data!['revenue'] as num?)),
          _FieldRow(label: 'Variable Costs', value: _fmtMoney(widget.data!['variable_costs'] as num?)),
          _FieldRow(label: 'Fixed Costs', value: _fmtMoney(widget.data!['fixed_costs'] as num?)),
          _FieldRow(label: 'Net Profit', value: _fmtMoney(widget.data!['net_profit'] as num?)),
          _FieldRow(label: 'Margin', value: _fmtPct(widget.data!['margin'] as num?)),
          _FieldRow(label: 'Cash Collected', value: _fmtMoney(widget.data!['cash_collected'] as num?)),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Cost of Ownership section
// ════════════════════════════════════════════════════════════
class _TcoSection extends StatefulWidget {
  final int vehicleId;
  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onLoad;

  const _TcoSection({
    required this.vehicleId,
    required this.data,
    required this.loading,
    required this.onLoad,
  });

  @override
  State<_TcoSection> createState() => _TcoSectionState();
}

class _TcoSectionState extends State<_TcoSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoad());
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Cost of Ownership',
      icon: Icons.account_balance_wallet,
      children: [
        if (widget.loading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (widget.data == null)
          const Text('No TCO data available', style: TextStyle(color: DomendraTheme.onSurfaceMuted))
        else ...[
          _FieldRow(label: 'Capital Cost', value: _fmtMoney(widget.data!['capital_cost'] as num?)),
          _FieldRow(label: 'Energy Cost', value: _fmtMoney(widget.data!['energy_cost'] as num?)),
          _FieldRow(label: 'Maintenance Cost', value: _fmtMoney(widget.data!['maintenance_cost'] as num?)),
          _FieldRow(label: 'Insurance Cost', value: _fmtMoney(widget.data!['insurance_cost'] as num?)),
          _FieldRow(label: 'Total Cost', value: _fmtMoney(widget.data!['total_cost'] as num?)),
          _FieldRow(label: 'Cost/Day', value: _fmtMoney(widget.data!['cost_per_day'] as num?)),
          _FieldRow(label: 'Cost/km', value: _fmtMoney(widget.data!['cost_per_km'] as num?)),
          _FieldRow(label: 'Lifetime Estimate', value: _fmtMoney(widget.data!['lifetime_estimate'] as num?)),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared section card widget
// ════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon, size: 20, color: DomendraTheme.primary),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: const Border(),
        children: children,
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.isEmpty || value == '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                color: isEmpty ? DomendraTheme.onSurfaceMuted : DomendraTheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: DomendraTheme.danger),
          const SizedBox(height: 16),
          const Text('Failed to load', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────
String _fmtDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _fmtMoney(num? v) {
  if (v == null) return '-';
  final d = v.toDouble();
  if (d >= 1000000) return '\$${(d / 1000000).toStringAsFixed(1)}M';
  if (d >= 1000) return '\$${(d / 1000).toStringAsFixed(1)}k';
  return '\$${d.toStringAsFixed(0)}';
}

String _fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

String _fmtNum2(double? v) => v == null ? '-' : v.toStringAsFixed(1);

String _fmtPct(num? v) {
  if (v == null) return '-';
  return '${v.toDouble().toStringAsFixed(1)}%';
}
