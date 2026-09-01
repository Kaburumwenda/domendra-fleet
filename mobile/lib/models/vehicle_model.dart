/// Vehicle data model and helpers mirroring the web vehicle object.
///
/// Handles the rich field set from the backend `Vehicle` serializer:
/// identity, classification, usage, leasing, financial, specs, and
/// computed/derived fields (display_name, rental_status, etc.).
library;

/// Status enum for a vehicle.
enum VehicleStatus {
  active,
  outOfService,
  inMaintenance,
  retired;

  static VehicleStatus fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'out_of_service':
        return VehicleStatus.outOfService;
      case 'in_maintenance':
        return VehicleStatus.inMaintenance;
      case 'retired':
        return VehicleStatus.retired;
      default:
        return VehicleStatus.active;
    }
  }

  String get label => switch (this) {
        active => 'Active',
        outOfService => 'Out of Service',
        inMaintenance => 'In Maintenance',
        retired => 'Retired',
      };

  String get api => switch (this) {
        active => 'active',
        outOfService => 'out_of_service',
        inMaintenance => 'in_maintenance',
        retired => 'retired',
      };
}

/// Ownership type.
enum VehicleOwnership {
  self,
  lease;

  static VehicleOwnership fromString(String? s) =>
      s?.toLowerCase() == 'lease' ? VehicleOwnership.lease : VehicleOwnership.self;

  String get label => this == VehicleOwnership.self ? 'Owned' : 'Leased';
  String get api => this == VehicleOwnership.self ? 'self' : 'lease';
}

/// Rental status (derived from rental agreement).
enum RentalStatus {
  assigned,
  available,
  none;

  static RentalStatus fromString(String? s) {
    final v = s?.toLowerCase();
    if (v == 'on_rent') return RentalStatus.assigned;
    if (v == 'available') return RentalStatus.available;
    return RentalStatus.none;
  }

  String get label => switch (this) {
        assigned => 'Assigned',
        available => 'Available',
        none => '-',
      };
}

/// Strongly-typed wrapper for a raw vehicle JSON object.
class Vehicle {
  final Map<String, dynamic> _raw;

  Vehicle(this._raw);

  /// Raw JSON map (for full-field access on detail screens).
  Map<String, dynamic> get raw => _raw;

  // ── Identity ───────────────────────────────────────────────
  int? get id => _int('id');
  String get vin => _str('vin');
  String get licensePlate => _str('license_plate');
  String get make => _str('make');
  String get model => _str('model');
  int get year => _int('year') ?? 0;
  String get bodyType => _str('body_type');
  String get vehicleType => _str('vehicle_type');
  String get color => _str('color');
  String get image => _str('image');

  // ── Classification ──────────────────────────────────────────
  String get fuelType => _str('fuel_type');
  VehicleStatus get status => VehicleStatus.fromString(_str('status'));
  VehicleOwnership get ownership => VehicleOwnership.fromString(_str('ownership'));
  String get mileageUnit => (_str('mileage_unit') == 'miles') ? 'mi' : 'km';

  // ── Usage ──────────────────────────────────────────────────
  int get currentMileage => _int('current_mileage') ?? 0;
  int get engineHours => _int('engine_hours') ?? 0;
  String get location => _str('location');

  // ── Relations ──────────────────────────────────────────────
  String get groupName => _str('group_name');
  int? get groupId => _int('group');
  String get assignedDriverName => _str('assigned_driver_name');
  String get lessorName => _str('lessor_name');

  // ── Lease ──────────────────────────────────────────────────
  DateTime? get leaseStartDate => _date('lease_start_date');
  DateTime? get leaseEndDate => _date('lease_end_date');
  double? get leaseMonthlyRate => _double('lease_monthly_rate');
  double? get deposit => _double('deposit');

  // Days remaining in lease (negative if expired)
  int? get leaseDaysLeft {
    final end = leaseEndDate;
    if (end == null) return null;
    final now = DateTime.now();
    return end.difference(now).inDays;
  }

  // ── Electric vehicle ───────────────────────────────────────
  double? get batteryCapacityKwh => _double('battery_capacity_kwh');
  double? get stateOfCharge => _double('state_of_charge');
  double? get stateOfHealth => _double('state_of_health');

  // ── Purchase & depreciation ────────────────────────────────
  double? get purchasePrice => _double('purchase_price');
  DateTime? get purchaseDate => _date('purchase_date');
  double? get salvageValue => _double('salvage_value');
  double? get residualValue => _double('residual_value');
  int? get usefulLifeYears => _int('useful_life_years');
  String get depreciationMethod => _str('depreciation_method');

  // ── Specs ──────────────────────────────────────────────────
  String get engine => _str('engine');
  String get engineSize => _str('engine_size');
  String get transmission => _str('transmission');
  String get drivetrain => _str('drivetrain');
  String get steering => _str('steering');

  // ── Insurance ─────────────────────────────────────────────
  double? get insurancePremium => _double('insurance_premium');
  String get insuranceType => _str('insurance_type');
  DateTime? get insuranceStartDate => _date('insurance_start_date');
  DateTime? get insuranceEndDate => _date('insurance_end_date');
  double? get monthlyPayment => _double('monthly_payment');

  // ── Lifecycle ──────────────────────────────────────────────
  DateTime? get inServiceDate => _date('in_service_date');
  DateTime? get outOfServiceDate => _date('out_of_service_date');
  DateTime? get retiredDate => _date('retired_date');

  // ── Computed (serializer-provided) ─────────────────────────
  String get displayName => _str('display_name');
  double? get annualDepreciation => _double('annual_depreciation');
  double? get currentBookValue => _double('current_book_value');

  // ── Rental (derived) ───────────────────────────────────────
  RentalStatus get rentalStatus => RentalStatus.fromString(_str('rental_status'));
  String get rentalAgreementNo => _str('rental_agreement_no');
  String get rentalCustomerName => _str('rental_customer_name');

  // ── Timestamps ─────────────────────────────────────────────
  DateTime? get createdAt => _date('created_at');
  DateTime? get updatedAt => _date('updated_at');

  bool get hasImage => image.isNotEmpty;
  bool get isElectric => fuelType.toLowerCase() == 'electric';
  bool get isEvOrHybrid {
    final ft = fuelType.toLowerCase();
    return ft == 'electric' ||
        ft.contains('hybrid') ||
        ft.contains('fuel cell') ||
        ft.contains('plug-in');
  }

  // ── Safe accessor helpers ──────────────────────────────────
  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  int? _int(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _double(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _date(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}
