/// Battery data models mirroring the backend serializers.
library;

/// Battery status enum.
enum BatteryStatus { inStock, installed, spare, charging, retired, scrapped }

/// Battery condition enum.
enum BatteryCondition { newBattery, excellent, good, fair, poor, damaged }

/// Battery chemistry enum.
enum BatteryChemistry { leadAcid, agm, gel, liIon, lifepo4, nicd, nimh }

/// Battery movement type enum.
enum BatteryMovementType { install, uninstall, swap, charge, retire }

/// Battery wrapper — mirrors `BatterySerializer`.
class Battery {
  final Map<String, dynamic> _raw;
  Battery(this._raw);

  Map<String, dynamic> get raw => _raw;

  int? get id => _raw['id'] as int?;
  String get serialNumber => _str('serial_number');
  String get brand => _str('brand');
  String get model => _str('model');
  String get partNumber => _str('part_number');
  String get groupCode => _str('group_code');

  BatteryChemistry get chemistry {
    const map = {
      'lead_acid': BatteryChemistry.leadAcid,
      'agm': BatteryChemistry.agm,
      'gel': BatteryChemistry.gel,
      'li_ion': BatteryChemistry.liIon,
      'lifepo4': BatteryChemistry.lifepo4,
      'nicd': BatteryChemistry.nicd,
      'nimh': BatteryChemistry.nimh,
    };
    return map[_str('chemistry')] ?? BatteryChemistry.leadAcid;
  }

  double get voltage => _double('voltage') ?? 12;
  double? get capacityAh => _double('capacity_ah');
  double? get cca => _double('cca');
  double? get rcMinutes => _double('rc_minutes');
  double? get weightKg => _double('weight_kg');

  BatteryCondition get condition {
    const map = {
      'new': BatteryCondition.newBattery,
      'excellent': BatteryCondition.excellent,
      'good': BatteryCondition.good,
      'fair': BatteryCondition.fair,
      'poor': BatteryCondition.poor,
      'damaged': BatteryCondition.damaged,
    };
    return map[_str('condition')] ?? BatteryCondition.newBattery;
  }

  BatteryStatus get status {
    const map = {
      'in_stock': BatteryStatus.inStock,
      'installed': BatteryStatus.installed,
      'spare': BatteryStatus.spare,
      'charging': BatteryStatus.charging,
      'retired': BatteryStatus.retired,
      'scrapped': BatteryStatus.scrapped,
    };
    return map[_str('status')] ?? BatteryStatus.inStock;
  }

  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  String get vehicleLicensePlate => _str('vehicle_license_plate');
  String get vehicleType => _str('vehicle_type');
  String get position => _str('position');

  double? get purchasePrice => _double('purchase_price');
  DateTime? get purchaseDate => _date('purchase_date');
  int? get warrantyMonths => _int('warranty_months');
  DateTime? get warrantyExpiry => _date('warranty_expiry');
  int? get expectedLifespanMonths => _int('expected_lifespan_months');
  DateTime? get installDate => _date('install_date');
  DateTime? get lastTested => _date('last_tested');
  String get notes => _str('notes');

  bool get warrantyExpired => _raw['warranty_expired'] == true;
  int? get warrantyDaysLeft => _raw['warranty_days_left'] as int?;
  int? get ageMonths => _raw['age_months'] as int?;
  bool get needsReplacement => _raw['needs_replacement'] == true;
  double get healthPct => _double('health_pct') ?? 80;
  double? get lastVoltage => _double('last_voltage');
  DateTime? get lastVoltageDate => _date('last_voltage_date');
  int get cycleCount => _int('cycle_count') ?? 0;

  // Computed helpers
  String get chemistryLabel {
    const map = {
      BatteryChemistry.leadAcid: 'Lead-Acid',
      BatteryChemistry.agm: 'AGM',
      BatteryChemistry.gel: 'Gel',
      BatteryChemistry.liIon: 'Lithium-Ion',
      BatteryChemistry.lifepo4: 'LiFePO4',
      BatteryChemistry.nicd: 'NiCd',
      BatteryChemistry.nimh: 'NiMH',
    };
    return map[chemistry] ?? 'Unknown';
  }

  String get conditionLabel {
    const map = {
      BatteryCondition.newBattery: 'New',
      BatteryCondition.excellent: 'Excellent',
      BatteryCondition.good: 'Good',
      BatteryCondition.fair: 'Fair',
      BatteryCondition.poor: 'Poor',
      BatteryCondition.damaged: 'Damaged',
    };
    return map[condition] ?? 'Unknown';
  }

  String get statusLabel {
    const map = {
      BatteryStatus.inStock: 'In Stock',
      BatteryStatus.installed: 'Installed',
      BatteryStatus.spare: 'Spare',
      BatteryStatus.charging: 'Charging',
      BatteryStatus.retired: 'Retired',
      BatteryStatus.scrapped: 'Scrapped',
    };
    return map[status] ?? 'Unknown';
  }

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

/// Battery reading wrapper — mirrors `BatteryReadingSerializer`.
class BatteryReading {
  final Map<String, dynamic> _raw;
  BatteryReading(this._raw);

  int? get id => _raw['id'] as int?;
  int? get batteryId => _raw['battery'] as int?;
  String get batterySerial => _str('battery_serial');
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  DateTime? get measuredAt => _date('measured_at');
  double get voltage => _double('voltage') ?? 0;
  double? get specificGravity => _double('specific_gravity');
  double? get internalResistance => _double('internal_resistance');
  double? get temperatureC => _double('temperature_c');
  double? get socPct => _double('soc_pct');
  String get testResult => _str('test_result');
  String get notes => _str('notes');
  double get healthPct => _double('health_pct') ?? 0;

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
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

/// Battery movement wrapper — mirrors `BatteryMovementSerializer`.
class BatteryMovement {
  final Map<String, dynamic> _raw;
  BatteryMovement(this._raw);

  int? get id => _raw['id'] as int?;
  int? get batteryId => _raw['battery'] as int?;
  String get batterySerial => _str('battery_serial');

  BatteryMovementType get movementType {
    const map = {
      'install': BatteryMovementType.install,
      'uninstall': BatteryMovementType.uninstall,
      'swap': BatteryMovementType.swap,
      'charge': BatteryMovementType.charge,
      'retire': BatteryMovementType.retire,
    };
    return map[_str('movement_type')] ?? BatteryMovementType.install;
  }

  String get movementTypeLabel {
    const map = {
      BatteryMovementType.install: 'Install',
      BatteryMovementType.uninstall: 'Uninstall',
      BatteryMovementType.swap: 'Swap',
      BatteryMovementType.charge: 'Charge',
      BatteryMovementType.retire: 'Retire',
    };
    return map[movementType] ?? 'Unknown';
  }

  int? get fromVehicleId => _raw['from_vehicle'] as int?;
  String get fromVehicleName => _str('from_vehicle_name');
  int? get toVehicleId => _raw['to_vehicle'] as int?;
  String get toVehicleName => _str('to_vehicle_name');
  String get fromPosition => _str('from_position');
  String get toPosition => _str('to_position');
  String get notes => _str('notes');
  DateTime? get performedAt => _date('performed_at');

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  DateTime? _date(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// Charge cycle wrapper — mirrors `ChargeCycleSerializer`.
class ChargeCycle {
  final Map<String, dynamic> _raw;
  ChargeCycle(this._raw);

  int? get id => _raw['id'] as int?;
  int? get batteryId => _raw['battery'] as int?;
  String get batterySerial => _str('battery_serial');
  DateTime? get startedAt => _dateTime('started_at');
  DateTime? get completedAt => _dateTime('completed_at');
  double? get startVoltage => _double('start_voltage');
  double? get endVoltage => _double('end_voltage');
  double? get energyKwh => _double('energy_kwh');
  String get chargeMethod => _str('charge_method');
  String get notes => _str('notes');

  String get chargeMethodLabel {
    const map = {
      'ac': 'AC',
      'dc': 'DC',
      'regen': 'Regen',
      'alternator': 'Alternator',
      'solar': 'Solar',
    };
    return map[chargeMethod] ?? chargeMethod;
  }

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  double? _double(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _dateTime(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// Battery replacement wrapper — mirrors `BatteryReplacementSerializer`.
class BatteryReplacement {
  final Map<String, dynamic> _raw;
  BatteryReplacement(this._raw);

  int? get id => _raw['id'] as int?;
  int? get batteryId => _raw['battery'] as int?;
  String get batterySerial => _str('battery_serial');
  int? get oldBatteryId => _raw['old_battery'] as int?;
  String get oldBatterySerial => _str('old_battery_serial');
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  DateTime? get scheduledDate => _date('scheduled_date');
  DateTime? get completedDate => _date('completed_date');
  String get reason => _str('reason');
  double? get estimatedCost => _double('estimated_cost');
  String get status => _str('status');
  String get notes => _str('notes');

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
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
