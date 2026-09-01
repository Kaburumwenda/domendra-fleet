/// Maintenance data models — mirrors backend serializers for Issues, Work Orders,
/// Services, Reminders, Inspections, Garage, and Recalls.
library;

// ════════════════════════════════════════════════════════════
// ISSUES
// ════════════════════════════════════════════════════════════

class Issue {
  final Map<String, dynamic> _raw;
  Issue(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  String get title => _str('title');
  String get description => _str('description');
  String get status => _str('status');
  String get priority => _str('priority');
  String get reportedByName => _str('reported_by_name');
  bool get hasWorkOrder => _raw['has_work_order'] == true;
  int? get workOrderId => _raw['work_order_id'] as int?;
  List<dynamic> get photos => _raw['issue_photos'] as List? ?? [];
  DateTime? get createdAt => _date('created_at');
  DateTime? get updatedAt => _date('updated_at');

  String get statusLabel {
    const m = {'open': 'Open', 'assigned': 'Assigned', 'parts_ordered': 'Parts Ordered', 'in_progress': 'In Progress', 'resolved': 'Resolved', 'closed': 'Closed'};
    return m[status] ?? status;
  }

  String get priorityLabel {
    const m = {'low': 'Low', 'medium': 'Medium', 'high': 'High', 'critical': 'Critical'};
    return m[priority] ?? priority;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// WORK ORDERS
// ════════════════════════════════════════════════════════════

class WorkOrder {
  final Map<String, dynamic> _raw;
  WorkOrder(this._raw);

  int? get id => _raw['id'] as int?;
  int? get issueId => _raw['issue'] as int?;
  String get issueTitle => _str('issue_title');
  String get vehicleName => _str('vehicle_name');
  int? get assignedTo => _raw['assigned_to'] as int?;
  String get assignedToName => _str('assigned_to_name');
  String get assignmentType => _str('assignment_type');
  String get status => _str('status');
  double get estimatedCost => _double('estimated_cost') ?? 0;
  double get actualCost => _double('actual_cost') ?? 0;
  double get partsCost => _double('parts_cost') ?? 0;
  double get laborCost => _double('labor_cost') ?? 0;
  double get totalCost => _double('total_cost') ?? 0;
  double get downtimeHours => _double('downtime_hours') ?? 0;
  DateTime? get startedAt => _date('started_at');
  DateTime? get completedAt => _date('completed_at');
  String get internalNotes => _str('internal_notes');
  String get externalNotes => _str('external_notes');
  List<dynamic> get notes => _raw['notes'] as List? ?? [];
  List<dynamic> get timeLogs => _raw['time_logs'] as List? ?? [];
  List<dynamic> get partsUsed => _raw['parts_used'] as List? ?? [];
  DateTime? get createdAt => _date('created_at');

  String get statusLabel {
    const m = {'open': 'Open', 'assigned': 'Assigned', 'parts_ordered': 'Parts Ordered', 'in_progress': 'In Progress', 'on_hold': 'On Hold', 'completed': 'Completed', 'closed': 'Closed'};
    return m[status] ?? status;
  }

  String get assignmentTypeLabel {
    return assignmentType == 'external' ? 'External Shop' : 'Internal Mechanic';
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// SERVICES
// ════════════════════════════════════════════════════════════

class Service {
  final Map<String, dynamic> _raw;
  Service(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  int? get workOrderId => _raw['work_order'] as int?;
  String get serviceType => _str('service_type');
  String get description => _str('description');
  DateTime? get performedAt => _date('performed_at');
  double get cost => _double('cost') ?? 0;
  int? get vendorId => _raw['vendor'] as int?;
  String get vendorName => _str('vendor_name');
  String get technicianName => _str('technician_name');
  int? get odometerReading => _raw['odometer_reading'] as int?;
  double get downtimeHours => _double('downtime_hours') ?? 0;
  Map<String, dynamic>? get rating => _raw['rating'] as Map<String, dynamic>?;
  DateTime? get createdAt => _date('created_at');

  String get serviceTypeLabel {
    const m = {'oil_change': 'Oil Change', 'tire_rotation': 'Tire Rotation', 'brake_service': 'Brake Service', 'inspection': 'Inspection', 'repair': 'Repair', 'preventive': 'Preventive Maintenance', 'other': 'Other'};
    return m[serviceType] ?? serviceType;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// REMINDERS
// ════════════════════════════════════════════════════════════

class Reminder {
  final Map<String, dynamic> _raw;
  Reminder(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  String get title => _str('title');
  String get triggerType => _str('trigger_type');
  int get triggerInterval => _raw['trigger_interval'] as int? ?? 6;
  int get lastTriggeredValue => _raw['last_triggered_value'] as int? ?? 0;
  DateTime? get nextDueDate => _date('next_due_date');
  int? get nextDueMileage => _raw['next_due_mileage'] as int?;
  double? get nextDueEngineHours => _double('next_due_engine_hours');
  int get escalationLevel => _raw['escalation_level'] as int? ?? 0;
  bool get autoGenerateWorkOrder => _raw['auto_generate_work_order'] == true;
  bool get isActive => _raw['is_active'] == true;
  bool get isDue => _raw['is_due'] == true;
  bool get isOverdue => _raw['is_overdue'] == true;
  DateTime? get createdAt => _date('created_at');
  DateTime? get updatedAt => _date('updated_at');

  String get triggerTypeLabel {
    const m = {'time': 'Time (Months)', 'mileage': 'Mileage', 'engine_hours': 'Engine Hours'};
    return m[triggerType] ?? triggerType;
  }

  String get escalationLabel {
    const m = {0: 'None', 1: 'Email Driver', 2: 'SMS Manager', 3: 'Block Dispatch'};
    return m[escalationLevel] ?? 'None';
  }

  String get nextDueText {
    switch (triggerType) {
      case 'time': return nextDueDate != null ? '${nextDueDate!.year}-${nextDueDate!.month.toString().padLeft(2, '0')}-${nextDueDate!.day.toString().padLeft(2, '0')}' : '—';
      case 'mileage': return nextDueMileage != null ? '$nextDueMileage mi' : '—';
      case 'engine_hours': return nextDueEngineHours != null ? '${nextDueEngineHours!.toStringAsFixed(0)} hrs' : '—';
      default: return '—';
    }
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// INSPECTIONS
// ════════════════════════════════════════════════════════════

class InspectionForm {
  final Map<String, dynamic> _raw;
  InspectionForm(this._raw);

  int? get id => _raw['id'] as int?;
  String get name => _str('name');
  String get description => _str('description');
  bool get isActive => _raw['is_active'] == true;
  int get itemCount => _raw['item_count'] as int? ?? 0;
  List<dynamic> get items => _raw['items'] as List? ?? [];
  DateTime? get createdAt => _date('created_at');

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

class InspectionReport {
  final Map<String, dynamic> _raw;
  InspectionReport(this._raw);

  int? get id => _raw['id'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  int? get formId => _raw['form'] as int?;
  String get formName => _str('form_name');
  int? get driverId => _raw['driver'] as int?;
  String get driverName => _str('driver_name');
  String get status => _str('status');
  String get notes => _str('notes');
  int? get odometerReading => _raw['odometer_reading'] as int?;
  DateTime? get submittedAt => _date('submitted_at');
  DateTime? get updatedAt => _date('updated_at');
  List<dynamic> get responses => _raw['responses'] as List? ?? [];

  String get statusLabel {
    const m = {'pass': 'Passed', 'fail': 'Failed', 'conditional': 'Conditional', 'draft': 'Draft'};
    return m[status] ?? status;
  }

  int get failCount => responses.where((r) => (r as Map)['is_fail'] == true).length;
  int get criticalFailCount => responses.where((r) => (r as Map)['is_fail'] == true && (r as Map)['is_critical'] == true).length;

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// GARAGE
// ════════════════════════════════════════════════════════════

class GarageBay {
  final Map<String, dynamic> _raw;
  GarageBay(this._raw);

  int? get id => _raw['id'] as int?;
  String get name => _str('name');
  String get bayType => _str('bay_type');
  int get capacity => _raw['capacity'] as int? ?? 1;
  bool get isActive => _raw['is_active'] == true;
  bool get isOccupied => _raw['is_occupied'] == true;
  String get notes => _str('notes');

  String get bayTypeLabel {
    const m = {'lift': 'Lift Bay', 'flat': 'Flat Bay', 'paint': 'Paint Bay', 'wash': 'Wash Bay', 'inspection': 'Inspection Bay', 'general': 'General Bay'};
    return m[bayType] ?? bayType;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
}

class BayReservation {
  final Map<String, dynamic> _raw;
  BayReservation(this._raw);

  int? get id => _raw['id'] as int?;
  int? get bayId => _raw['bay'] as int?;
  String get bayName => _str('bay_name');
  int? get workOrderId => _raw['work_order'] as int?;
  int? get vehicleId => _raw['vehicle'] as int?;
  String get vehicleName => _str('vehicle_name');
  DateTime? get startTime => _date('start_time');
  DateTime? get endTime => _date('end_time');
  String get status => _str('status');
  String get notes => _str('notes');
  double get durationHours => _double('duration_hours') ?? 0;

  String get statusLabel {
    const m = {'scheduled': 'Scheduled', 'active': 'Active', 'completed': 'Completed', 'cancelled': 'Cancelled'};
    return m[status] ?? status;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  double? _double(String k) { final v = _raw[k]; if (v == null) return null; if (v is double) return v; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v); return null; }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}

// ════════════════════════════════════════════════════════════
// RECALLS
// ════════════════════════════════════════════════════════════

class Recall {
  final Map<String, dynamic> _raw;
  Recall(this._raw);

  int? get id => _raw['id'] as int?;
  String get title => _str('title');
  String get recallType => _str('recall_type');
  String get nhtsaCampaignNumber => _str('nhtsa_campaign_number');
  String get manufacturerCampaignNumber => _str('manufacturer_campaign_number');
  String get oem => _str('oem');
  String get component => _str('component');
  String get description => _str('description');
  String get remedy => _str('remedy');
  String get risk => _str('risk');
  DateTime? get issueDate => _date('issue_date');
  String get status => _str('status');
  bool get isCritical => _raw['is_critical'] == true;
  String get affectedMake => _str('affected_make');
  String get affectedModels => _str('affected_models');
  int? get affectedYearFrom => _raw['affected_year_from'] as int?;
  int? get affectedYearTo => _raw['affected_year_to'] as int?;
  List<dynamic> get vehicles => _raw['vehicles'] as List? ?? [];
  int get affectedCount => _raw['affected_count'] as int? ?? 0;
  int get resolvedCount => _raw['resolved_count'] as int? ?? 0;
  DateTime? get createdAt => _date('created_at');

  String get recallTypeLabel {
    const m = {'safety_recall': 'Safety Recall', 'campaign': 'Service Campaign', 'field_notice': 'Field Notice', 'emission': 'Emission'};
    return m[recallType] ?? recallType;
  }

  String get statusLabel {
    const m = {'open': 'Open', 'in_progress': 'In Progress', 'completed': 'Completed', 'closed': 'Closed'};
    return m[status] ?? status;
  }

  String _str(String k) { final v = _raw[k]; return v == null ? '' : v.toString(); }
  DateTime? _date(String k) { final v = _str(k); return v.isEmpty ? null : DateTime.tryParse(v); }
}
