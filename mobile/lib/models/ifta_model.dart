/// IFTA & Fuel Tax data models — mirrors backend serializers.
library;

// ════════════════════════════════════════════════════════════
// JURISDICTION
// ════════════════════════════════════════════════════════════

class Jurisdiction {
  final Map<String, dynamic> _raw;
  Jurisdiction(this._raw);

  int? get id => _raw['id'] as int?;
  String get code => _str('code');
  String get name => _str('name');
  String get country => _str('country');
  double get fuelTaxRate => _double('fuel_tax_rate') ?? 0;
  bool get isIfta => _raw['is_ifta'] == true;

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
}

// ════════════════════════════════════════════════════════════
// TRIP LOG
// ════════════════════════════════════════════════════════════

class TripLog {
  final Map<String, dynamic> _raw;
  TripLog(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  int? get driverId => _raw['driver'] as int?;
  String get driverName => _str('driver_name');
  int? get jurisdictionId => _raw['jurisdiction'] as int?;
  String get jurisdictionCode => _str('jurisdiction_code');
  String get jurisdictionName => _str('jurisdiction_name');
  DateTime? get date => _date('date');
  double? get startOdometer => _double('start_odometer');
  double? get endOdometer => _double('end_odometer');
  double get distance => _double('distance') ?? 0;
  String get distanceUnit => _str('distance_unit');
  double get distanceMiles => _double('distance_miles') ?? 0;
  String get tripType => _str('trip_type');
  String get route => _str('route');
  String get notes => _str('notes');
  String get source => _str('source');
  DateTime? get createdAt => _date('created_at');

  String get tripTypeLabel {
    const m = {'loaded': 'Loaded', 'empty': 'Empty', 'bobtail': 'Bobtail'};
    return m[tripType] ?? tripType;
  }

  String get sourceLabel => source == 'telematics' ? 'Telematics' : 'Manual';

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// FUEL PURCHASE
// ════════════════════════════════════════════════════════════

class FuelPurchase {
  final Map<String, dynamic> _raw;
  FuelPurchase(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  int? get jurisdictionId => _raw['jurisdiction'] as int?;
  String get jurisdictionCode => _str('jurisdiction_code');
  DateTime? get date => _date('date');
  double get gallons => _double('gallons') ?? 0;
  double get totalCost => _double('total_cost') ?? 0;
  double get taxPaid => _double('tax_paid') ?? 0;
  double get pricePerGallon => _double('price_per_gallon') ?? 0;
  String get vendor => _str('vendor');
  String get source => _str('source');
  DateTime? get createdAt => _date('created_at');

  String get sourceLabel => source == 'fuel_card' ? 'Fuel Card' : 'Manual';

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// IFTA QUARTER
// ════════════════════════════════════════════════════════════

class IftaQuarter {
  final Map<String, dynamic> _raw;
  IftaQuarter(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  int get year => _raw['year'] as int? ?? 0;
  String get quarter => _str('quarter');
  String get label => _str('label');
  String get status => _str('status');
  double get totalMiles => _double('total_miles') ?? 0;
  double get totalGallons => _double('total_gallons') ?? 0;
  double get totalTaxDue => _double('total_tax_due') ?? 0;
  double get totalTaxCredit => _double('total_tax_credit') ?? 0;
  double get netTax => _double('net_tax') ?? 0;
  String get notes => _str('notes');
  DateTime? get createdAt => _date('created_at');
  DateTime? get updatedAt => _date('updated_at');

  String get statusLabel {
    const m = {'draft': 'Draft', 'submitted': 'Submitted', 'filed': 'Filed'};
    return m[status] ?? status;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// QUARTER BREAKDOWN ROW
// ════════════════════════════════════════════════════════════

class QuarterBreakdownRow {
  String get jurisdiction => _str('jurisdiction');
  String get name => _str('name');
  double get miles => _double('miles') ?? 0;
  double get gallons => _double('gallons') ?? 0;
  double get rate => _double('rate') ?? 0;
  double get consumedGallons => _double('consumed_gallons') ?? 0;
  double get taxDue => _double('tax_due') ?? 0;

  final Map<String, dynamic> _raw;
  QuarterBreakdownRow(this._raw);

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
}
