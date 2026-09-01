/// Equipment data model and helpers mirroring the backend `Equipment` serializer.
library;

/// Equipment status enum.
enum EquipmentStatus {
  available,
  inUse,
  inMaintenance,
  retired;

  static EquipmentStatus fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'in_use':
        return EquipmentStatus.inUse;
      case 'in_maintenance':
        return EquipmentStatus.inMaintenance;
      case 'retired':
        return EquipmentStatus.retired;
      default:
        return EquipmentStatus.available;
    }
  }

  String get label => switch (this) {
        available => 'Available',
        inUse => 'In Use',
        inMaintenance => 'In Maintenance',
        retired => 'Retired',
      };

  String get api => switch (this) {
        available => 'available',
        inUse => 'in_use',
        inMaintenance => 'in_maintenance',
        retired => 'retired',
      };
}

/// Calibration status derived from dates.
enum CalibrationStatus {
  notRequired,
  overdue,
  dueSoon,
  ok;

  static CalibrationStatus fromItem(Map<String, dynamic> item) {
    final requiresCalibration = item['requires_calibration'] == true;
    if (!requiresCalibration) return CalibrationStatus.notRequired;
    final overdue = item['calibration_overdue'] == true;
    if (overdue) return CalibrationStatus.overdue;
    final dueSoon = item['calibration_due_soon'] == true;
    if (dueSoon) return CalibrationStatus.dueSoon;
    return CalibrationStatus.ok;
  }

  String get label => switch (this) {
        notRequired => 'N/A',
        overdue => 'Overdue',
        dueSoon => 'Due Soon',
        ok => 'OK',
      };
}

/// Strongly-typed wrapper for a raw equipment JSON object.
class EquipmentItem {
  final Map<String, dynamic> _raw;

  EquipmentItem(this._raw);

  Map<String, dynamic> get raw => _raw;

  // ── Identity ───────────────────────────────────────────────
  int? get id => _int('id');
  String get name => _str('name');
  String get assetNumber => _str('asset_number');
  String get serialNumber => _str('serial_number');
  String get barcode => _str('barcode');
  String get displayName => _str('display_name');
  String get description => _str('description');

  // ── Classification ──────────────────────────────────────────
  int? get categoryId => _int('category');
  String get categoryName => _str('category_name');
  EquipmentStatus get status => EquipmentStatus.fromString(_str('status'));
  String get location => _str('location');

  // ── Relations ──────────────────────────────────────────────
  int? get assignedToId => _int('assigned_to');
  String get assignedToName => _str('assigned_to_name');
  int? get assignedVehicleId => _int('assigned_vehicle');
  String get assignedVehicleName => _str('assigned_vehicle_name');

  // ── Usage ──────────────────────────────────────────────────
  double get currentHours => _double('current_hours') ?? 0.0;

  // ── Calibration ────────────────────────────────────────────
  bool get requiresCalibration => _raw['requires_calibration'] == true;
  DateTime? get lastCalibratedAt => _date('last_calibrated_at');
  DateTime? get nextCalibrationDue => _date('next_calibration_due');
  int get calibrationIntervalDays => _int('calibration_interval_days') ?? 365;
  bool get calibrationOverdue => _raw['calibration_overdue'] == true;
  bool get calibrationDueSoon => _raw['calibration_due_soon'] == true;

  CalibrationStatus get calibrationStatus {
    if (!requiresCalibration) return CalibrationStatus.notRequired;
    if (calibrationOverdue) return CalibrationStatus.overdue;
    if (calibrationDueSoon) return CalibrationStatus.dueSoon;
    return CalibrationStatus.ok;
  }

  // ── Checkout ───────────────────────────────────────────────
  bool get isCheckedOut => _raw['is_checked_out'] == true;

  // ── Financials ────────────────────────────────────────────
  double? get purchasePrice => _double('purchase_price');
  DateTime? get purchaseDate => _date('purchase_date');

  // ── Timestamps ────────────────────────────────────────────
  DateTime? get createdAt => _date('created_at');
  DateTime? get updatedAt => _date('updated_at');

  // ── Helpers ────────────────────────────────────────────────
  bool get hasImage => false; // no image field in current model

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

/// Wrapper for checkout records.
class EquipmentCheckout {
  final Map<String, dynamic> _raw;
  EquipmentCheckout(this._raw);

  int? get id => _raw['id'] as int?;
  int? get equipmentId => _raw['equipment'] as int?;
  String get equipmentName => _str('equipment_name');
  int? get checkedOutToId => _raw['checked_out_to'] as int?;
  String get checkedOutToName => _str('checked_out_to_name');
  DateTime? get checkedOutAt => _date('checked_out_at');
  DateTime? get expectedReturnAt => _date('expected_return_at');
  DateTime? get returnedAt => _date('returned_at');
  bool get isOverdue => _raw['is_overdue'] == true;
  double get durationHours => (_raw['duration_hours'] as num?)?.toDouble() ?? 0;
  String get notes => _str('notes');

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

/// Wrapper for meter entries.
class EquipmentMeterEntry {
  final Map<String, dynamic> _raw;
  EquipmentMeterEntry(this._raw);

  int? get id => _raw['id'] as int?;
  int? get equipmentId => _raw['equipment'] as int?;
  double get hours => (_raw['hours'] as num?)?.toDouble() ?? 0;
  DateTime? get recordedAt => _date('recorded_at');
  String get notes => _str('notes');

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

/// Wrapper for calibration records.
class CalibrationRecord {
  final Map<String, dynamic> _raw;
  CalibrationRecord(this._raw);

  int? get id => _raw['id'] as int?;
  int? get equipmentId => _raw['equipment'] as int?;
  DateTime? get calibratedAt => _date('calibrated_at');
  String get result => _str('result');
  String get calibratedBy => _str('calibrated_by');
  String get certificateNumber => _str('certificate_number');
  String get notes => _str('notes');

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
