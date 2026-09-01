/// Tire data models mirroring the backend serializers.
library;

/// Tire status enum.
enum TireStatus { inStock, mounted, spare, retired, scrapped }

/// Tire condition enum.
enum TireCondition { newTire, secondHand, retreaded, reclaimed, used }

/// Tire movement type enum.
enum TireMovementType { mount, unmount, transfer, retread }

/// Tire wrapper — mirrors `TireSerializer`.
class Tire {
  final Map<String, dynamic> _raw;
  Tire(this._raw);

  Map<String, dynamic> get raw => _raw;

  int? get id => _raw['id'] as int?;
  String get serialNumber => _str('serial_number');
  String get brand => _str('brand');
  String get model => _str('model');
  String get size => _str('size');
  String get type => _str('type');

  TireCondition get condition {
    const map = {
      'new': TireCondition.newTire,
      'second_hand': TireCondition.secondHand,
      'retreaded': TireCondition.retreaded,
      'reclaimed': TireCondition.reclaimed,
      'used': TireCondition.used,
    };
    return map[_str('condition')] ?? TireCondition.newTire;
  }

  TireStatus get status {
    const map = {
      'in_stock': TireStatus.inStock,
      'mounted': TireStatus.mounted,
      'spare': TireStatus.spare,
      'retired': TireStatus.retired,
      'scrapped': TireStatus.scrapped,
    };
    return map[_str('status')] ?? TireStatus.inStock;
  }

  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  String get vehicleLicensePlate => _str('vehicle_license_plate');
  String get position => _str('position');

  double? get purchasePrice => _double('purchase_price');
  DateTime? get purchaseDate => _date('purchase_date');
  double? get warrantyMiles => _double('warranty_miles');
  double get minTreadDepth => _double('min_tread_depth') ?? 4;
  int get quantity => _int('quantity') ?? 1;

  double? get latestTreadDepth => _double('latest_tread_depth');
  double get totalMiles => _double('total_miles') ?? 0;
  bool get needsReplacement => _raw['needs_replacement'] == true;
  DateTime? get lastMountDate => _date('last_mount_date');
  DateTime? get retiredDate => _date('retired_date');

  // Computed helpers
  String get conditionLabel {
    const map = {
      TireCondition.newTire: 'New',
      TireCondition.secondHand: 'Second Hand',
      TireCondition.retreaded: 'Retreaded',
      TireCondition.reclaimed: 'Reclaimed',
      TireCondition.used: 'Used',
    };
    return map[condition] ?? 'Unknown';
  }

  String get statusLabel {
    const map = {
      TireStatus.inStock: 'In Stock',
      TireStatus.mounted: 'Mounted',
      TireStatus.spare: 'Spare',
      TireStatus.retired: 'Retired',
      TireStatus.scrapped: 'Scrapped',
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

/// Tire inspection wrapper — mirrors `TireInspectionSerializer`.
class TireInspection {
  final Map<String, dynamic> _raw;
  TireInspection(this._raw);

  int? get id => _raw['id'] as int?;
  int? get tireId => _raw['tire'] as int?;
  String get tireSerial => _str('tire_serial');
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  double get treadDepth => _double('tread_depth') ?? 0;
  double? get pressurePsi => _double('pressure_psi');
  double? get odometer => _double('odometer');
  String get position => _str('position');
  String get condition => _str('condition');
  String get notes => _str('notes');
  DateTime? get measuredAt => _date('measured_at');

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

/// Tire rotation wrapper — mirrors `TireRotationSerializer`.
class TireRotation {
  final Map<String, dynamic> _raw;
  TireRotation(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  String get vehicleLicensePlate => _str('vehicle_license_plate');
  String get rotationPattern => _str('rotation_pattern');
  double? get odometer => _double('odometer');
  String get notes => _str('notes');
  List<dynamic> get swaps => _raw['swaps'] as List? ?? [];
  List<dynamic> get swapsDetail => _raw['swaps_detail'] as List? ?? [];
  DateTime? get performedAt => _date('performed_at');

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

/// Tire movement wrapper — mirrors `TireMovementSerializer`.
class TireMovement {
  final Map<String, dynamic> _raw;
  TireMovement(this._raw);

  int? get id => _raw['id'] as int?;
  int? get tireId => _raw['tire'] as int?;
  String get tireSerial => _str('tire_serial');
  TireMovementType get movementType {
    const map = {
      'mount': TireMovementType.mount,
      'unmount': TireMovementType.unmount,
      'transfer': TireMovementType.transfer,
      'retread': TireMovementType.retread,
    };
    return map[_str('movement_type')] ?? TireMovementType.mount;
  }

  String get movementTypeLabel {
    const map = {
      TireMovementType.mount: 'Mount',
      TireMovementType.unmount: 'Unmount',
      TireMovementType.transfer: 'Transfer',
      TireMovementType.retread: 'Retread',
    };
    return map[movementType] ?? 'Unknown';
  }

  int? get fromVehicleId => _raw['from_vehicle'] as int?;
  int? get toVehicleId => _raw['to_vehicle'] as int?;
  String get fromVehicleName => _str('from_vehicle_name');
  String get toVehicleName => _str('to_vehicle_name');
  String get fromPosition => _str('from_position');
  String get toPosition => _str('to_position');
  double? get odometer => _double('odometer');
  String get notes => _str('notes');
  DateTime? get performedAt => _date('performed_at');

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
