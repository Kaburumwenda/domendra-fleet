/// Fuel & Energy data models — mirrors backend serializers.
library;

// ════════════════════════════════════════════════════════════
// FUEL TRANSACTION
// ════════════════════════════════════════════════════════════

class FuelTransaction {
  final Map<String, dynamic> _raw;
  FuelTransaction(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  int? get fuelCardId => _raw['fuel_card'] as int?;
  DateTime? get date => _date('date');
  String get fuelType => _str('fuel_type');
  double get quantity => _double('quantity') ?? 0;
  String get unit => _str('unit');
  double get totalCost => _double('total_cost') ?? 0;
  double get pricePerUnit => _double('price_per_unit') ?? 0;
  double get mpg => _double('mpg') ?? 0;
  int? get odometerReading => _raw['odometer_reading'] as int?;
  String get stationName => _str('station_name');
  String get stationLocation => _str('station_location');
  String get receiptImage => _str('receipt_image');
  String get notes => _str('notes');
  int get fraudAlertCount => _raw['fraud_alert_count'] as int? ?? 0;
  DateTime? get createdAt => _date('created_at');

  String get fuelTypeLabel => fuelType;
  String get unitSymbol => unit == 'liters' ? 'L' : 'gal';
  bool get hasReceipt => receiptImage.isNotEmpty;

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// FUEL CARD
// ════════════════════════════════════════════════════════════

class FuelCard {
  final Map<String, dynamic> _raw;
  FuelCard(this._raw);

  int? get id => _raw['id'] as int?;
  String get cardNumber => _str('card_number');
  String get provider => _str('provider');
  String get cardHolderName => _str('card_holder_name');
  int? get vehicleId => _raw['vehicle'] as int?;
  int? get driverId => _raw['driver'] as int?;
  DateTime? get expiryDate => _date('expiry_date');
  bool get isActive => _raw['is_active'] == true;
  String get providerAccountId => _str('provider_account_id');
  DateTime? get lastSyncedAt => _date('last_synced_at');

  String get providerLabel {
    const m = {'WEX': 'WEX', 'Comdata': 'Comdata', 'Fleetcor': 'Fleetcor', 'BP': 'BP', 'other': 'Other'};
    return m[provider] ?? provider;
  }

  String get maskedNumber {
    final n = cardNumber;
    if (n.length <= 4) return n;
    return '${n.substring(0, 4)}••••${n.substring(n.length - 4)}';
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// CHARGING SESSION
// ════════════════════════════════════════════════════════════

class ChargingSession {
  final Map<String, dynamic> _raw;
  ChargingSession(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  DateTime? get startTime => _date('start_time');
  DateTime? get endTime => _date('end_time');
  double get energyKwh => _double('energy_kwh') ?? 0;
  double get cost => _double('cost') ?? 0;
  String get stationName => _str('station_name');
  String get stationNetwork => _str('station_network');
  double? get startSoc => _double('start_soc');
  double? get endSoc => _double('end_soc');
  double get durationHours => _double('duration_hours') ?? 0;

  String get networkLabel {
    const m = {'chargepoint': 'ChargePoint', 'tesla': 'Tesla Supercharger', 'evgo': 'EVgo', 'electrify_america': 'Electrify America', 'other': 'Other'};
    return m[stationNetwork] ?? stationNetwork;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// FUEL FRAUD ALERT
// ════════════════════════════════════════════════════════════

class FuelFraudAlert {
  final Map<String, dynamic> _raw;
  FuelFraudAlert(this._raw);

  int? get id => _raw['id'] as int?;
  int? get transactionId => _raw['transaction'] as int?;
  String get vehicleName => _str('vehicle_name');
  DateTime? get transactionDate => _date('transaction_date');
  String get alertType => _str('alert_type');
  String get severity => _str('severity');
  String get actionStatus => _str('action_status');
  bool get isResolved => _raw['is_resolved'] == true;
  String get statusNote => _str('status_note');
  String get description => _str('description');
  DateTime? get createdAt => _date('created_at');

  String get alertTypeLabel {
    const m = {'wrong_fuel': 'Wrong Fuel', 'double_fueling': 'Double Fueling', 'parked_fueling': 'Parked Fueling', 'excessive_qty': 'Excessive Quantity', 'off_hours': 'Off Hours', 'geographic': 'Geographic'};
    return m[alertType] ?? alertType.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String get severityLabel {
    const m = {'low': 'Low', 'medium': 'Medium', 'high': 'High', 'critical': 'Critical'};
    return m[severity] ?? severity;
  }

  String get statusLabel {
    const m = {'open': 'Open', 'under_review': 'Under Review', 'resolved': 'Resolved', 'dismissed': 'Dismissed'};
    return m[actionStatus] ?? actionStatus;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// IDLING EVENT
// ════════════════════════════════════════════════════════════

class IdlingEvent {
  final Map<String, dynamic> _raw;
  IdlingEvent(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  DateTime? get startTime => _date('start_time');
  DateTime? get endTime => _date('end_time');
  double get fuelBurnRate => _double('fuel_burn_rate') ?? 0.5;
  double get fuelPricePerGallon => _double('fuel_price_per_gallon') ?? 3.50;
  String get location => _str('location');
  String get notes => _str('notes');
  double get durationMinutes => _double('duration_minutes') ?? 0;
  double get durationHours => _double('duration_hours') ?? 0;
  double get fuelBurned => _double('fuel_burned') ?? 0;
  double get cost => _double('cost') ?? 0;

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// CHARGE SCHEDULE
// ════════════════════════════════════════════════════════════

class ChargeSchedule {
  final Map<String, dynamic> _raw;
  ChargeSchedule(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  String get startTime => _str('start_time');
  String get endTime => _str('end_time');
  double get targetSoc => _double('target_soc') ?? 80;
  String get recurringDays => _str('recurring_days');
  bool get isActive => _raw['is_active'] == true;
  String get notes => _str('notes');

  List<String> get recurringDaysList => recurringDays.split(',').where((d) => d.isNotEmpty).toList();

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
}

// ════════════════════════════════════════════════════════════
// FUEL BUDGET
// ════════════════════════════════════════════════════════════

class FuelBudget {
  final Map<String, dynamic> _raw;
  FuelBudget(this._raw);

  int? get id => _raw['id'] as int?;
  String get scope => _str('scope');
  String get targetRef => _str('target_ref');
  DateTime? get month => _date('month');
  double get budgetAmount => _double('budget_amount') ?? 0;
  DateTime? get createdAt => _date('created_at');

  String get scopeLabel {
    const m = {'fleet': 'Fleet', 'vehicle_type': 'Vehicle Type', 'location': 'Location'};
    return m[scope] ?? scope;
  }

  String get monthLabel {
    if (month == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[month!.month - 1]} ${month!.year}';
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// FUEL CONSTANTS
// ════════════════════════════════════════════════════════════

const fuelTypes = [
  'Petrol', 'Diesel', 'Hybrid (Petrol)', 'Hybrid (Diesel)',
  'Plug-in Hybrid (Petrol)', 'Plug-in Hybrid (Diesel)', 'Mild Hybrid',
  'Electric', 'Fuel Cell (Hydrogen)', 'LPG', 'CNG', 'LNG',
  'Ethanol (E85)', 'Flex Fuel', 'Biodiesel',
];

const unitOptions = [
  {'value': 'gallons', 'label': 'Gallons'},
  {'value': 'liters', 'label': 'Liters'},
];

const stationOptions = [
  'Shell', 'TotalEnergies', 'Stabex', 'Rubis', 'Vivo Energy', 'Oil Libya',
  'Ola Energy', 'Gulf Energy', 'Tosha', 'National Oil', 'Kenol', 'Kobil',
  'Hashi Energy', 'Galana Oil', 'Lake Oil', 'Engen', 'Delta Petroleum',
  'Astrol Petroleum', 'Be Energy', 'Gapco',
];

const cardProviders = [
  {'value': 'WEX', 'label': 'WEX'},
  {'value': 'Comdata', 'label': 'Comdata'},
  {'value': 'Fleetcor', 'label': 'Fleetcor'},
  {'value': 'BP', 'label': 'BP'},
  {'value': 'other', 'label': 'Other'},
];

const chargingNetworks = [
  {'value': 'chargepoint', 'label': 'ChargePoint'},
  {'value': 'tesla', 'label': 'Tesla Supercharger'},
  {'value': 'evgo', 'label': 'EVgo'},
  {'value': 'electrify_america', 'label': 'Electrify America'},
  {'value': 'other', 'label': 'Other'},
];

const weekdays = [
  {'value': 'mon', 'label': 'Mon'},
  {'value': 'tue', 'label': 'Tue'},
  {'value': 'wed', 'label': 'Wed'},
  {'value': 'thu', 'label': 'Thu'},
  {'value': 'fri', 'label': 'Fri'},
  {'value': 'sat', 'label': 'Sat'},
  {'value': 'sun', 'label': 'Sun'},
];

int fuelTypeColor(String t) {
  switch (t) {
    case 'Diesel': return 0xFFF59E0B;
    case 'Electric':
    case 'Fuel Cell (Hydrogen)': return 0xFF10B981;
    case 'Hybrid (Petrol)':
    case 'Hybrid (Diesel)':
    case 'Plug-in Hybrid (Petrol)':
    case 'Plug-in Hybrid (Diesel)':
    case 'Mild Hybrid': return 0xFF8B5CF6;
    case 'CNG':
    case 'LPG':
    case 'LNG': return 0xFF06B6D4;
    case 'Ethanol (E85)':
    case 'Flex Fuel':
    case 'Biodiesel': return 0xFFEA580C;
    default: return 0xFF3B82F6;
  }
}

int severityColor(String s) {
  switch (s) {
    case 'critical': return 0xFFEF4444;
    case 'high': return 0xFFF59E0B;
    case 'medium': return 0xFFFBBF24;
    case 'low': return 0xFF3B82F6;
    default: return 0xFF6B7280;
  }
}

int fraudStatusColor(String s) {
  switch (s) {
    case 'open': return 0xFFEF4444;
    case 'under_review': return 0xFF3B82F6;
    case 'resolved': return 0xFF10B981;
    case 'dismissed': return 0xFF6B7280;
    default: return 0xFF6B7280;
  }
}
