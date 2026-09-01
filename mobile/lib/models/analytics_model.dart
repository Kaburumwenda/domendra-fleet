/// Analytics data models for the 3 Analytics screens.
/// Uses a single raw-map wrapper approach — each model wraps a Map<String, dynamic>
/// with typed getters, matching the backend response shapes.
library;

// ════════════════════════════════════════════════════════════
// VEHICLE ANALYTICS WRAPPER
// ════════════════════════════════════════════════════════════

class VehicleAnalyticsData {
  final Map<String, dynamic> _raw;
  VehicleAnalyticsData(this._raw);

  // ── Top-level ──────────────────────────────────────────────
  int get totalVehicles => _raw['total_vehicles'] as int? ?? 0;
  int get active => _raw['active'] as int? ?? 0;
  int get inMaintenance => _raw['in_maintenance'] as int? ?? 0;
  int get outOfService => _raw['out_of_service'] as int? ?? 0;

  // ── value_stats ────────────────────────────────────────────
  double get totalPurchaseValue => _num(_valueStats, 'total_purchase_value');
  double get avgPurchaseValue => _num(_valueStats, 'avg_purchase_value');

  // ── mileage_stats ──────────────────────────────────────────
  double get totalMileage => _num(_mileageStats, 'total_mileage');
  double get avgMileage => _num(_mileageStats, 'avg_mileage');

  // ── utilization ────────────────────────────────────────────
  double get utilizationRate => _num(_utilization, 'utilization_rate');
  int get activeRentals => _utilization['active_rentals'] as int? ?? 0;
  int get completedRentals => _utilization['completed_rentals'] as int? ?? 0;
  int get idleVehicles => _utilization['idle_vehicles'] as int? ?? 0;
  int get totalRentals => _utilization['total_rentals'] as int? ?? 0;
  double get totalRevenue => _num(_utilization, 'total_revenue');
  List<dynamic> get revenueMonthly => _utilization['revenue_monthly'] as List? ?? [];
  List<dynamic> get revenueByType => _utilization['revenue_by_type'] as List? ?? [];
  List<dynamic> get topVehicles => _utilization['top_vehicles'] as List? ?? [];

  // ── cost_analysis ──────────────────────────────────────────
  double get totalServiceCost => _num(_costAnalysis, 'total_service_cost');
  double get totalDepreciationLoss => _num(_costAnalysis, 'total_depreciation_loss');
  double get totalBookValue => _num(_costAnalysis, 'total_book_value');
  double get costPerKm => _num(_costAnalysis, 'cost_per_km');
  List<dynamic> get serviceByType => _costAnalysis['service_by_type'] as List? ?? [];
  List<dynamic> get costVehicles => _costAnalysis['vehicles'] as List? ?? [];

  // ── fleet_health ──────────────────────────────────────────
  double get fleetHealthScore => _num(_fleetHealth, 'fleet_health_score');
  int get passCount => _fleetHealth['pass_count'] as int? ?? 0;
  int get failCount => _fleetHealth['fail_count'] as int? ?? 0;
  int get totalInspections => _fleetHealth['total_inspections'] as int? ?? 0;
  int get vehiclesNeedingAttention => _fleetHealth['vehicles_needing_attention'] as int? ?? 0;
  double get maintenancePct => _num(_fleetHealth, 'maintenance_pct');
  double get outOfServicePct => _num(_fleetHealth, 'out_of_service_pct');
  double get inspectionPassRate => _num(_fleetHealth, 'inspection_pass_rate');

  // ── ev_stats ──────────────────────────────────────────────
  int get evCount => _evStats['count'] as int? ?? 0;
  double get evAvgStateOfCharge => _num(_evStats, 'avg_state_of_charge');
  double get evAvgStateOfHealth => _num(_evStats, 'avg_state_of_health');

  // ── Breakdown arrays ──────────────────────────────────────
  List<dynamic> get statusBreakdown => _raw['status_breakdown'] as List? ?? [];
  List<dynamic> get fuelTypeBreakdown => _raw['fuel_type_breakdown'] as List? ?? [];
  List<dynamic> get vehicleTypeBreakdown => _raw['vehicle_type_breakdown'] as List? ?? [];
  List<dynamic> get ownershipBreakdown => _raw['ownership_breakdown'] as List? ?? [];
  List<dynamic> get topMakes => _raw['top_makes'] as List? ?? [];
  Map<String, dynamic> get ageDistribution => (_raw['age_distribution'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get acquisitionTrend => _raw['acquisition_trend'] as List? ?? [];

  // ── ABC Analysis ──────────────────────────────────────────
  Map<String, dynamic> get _abcAnalysis => (_raw['abc_analysis'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get abcSummary => (_abcAnalysis['summary'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get abcVehicles => _abcAnalysis['vehicles'] as List? ?? [];
  int get abcNoRevenueCount => _abcAnalysis['no_revenue_count'] as int? ?? 0;
  double get abcTotalRevenue => _num(abcSummary, 'total_revenue');
  int get abcTotalVehicles => abcSummary['total_vehicles'] as int? ?? 0;
  Map<String, dynamic> get abcClassA => (abcSummary['A'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get abcClassB => (abcSummary['B'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get abcClassC => (abcSummary['C'] as Map<String, dynamic>?) ?? {};

  // ── Nested map getters ───────────────────────────────────
  Map<String, dynamic> get _valueStats => (_raw['value_stats'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _mileageStats => (_raw['mileage_stats'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _utilization => (_raw['utilization'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _costAnalysis => (_raw['cost_analysis'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _fleetHealth => (_raw['fleet_health'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get _evStats => (_raw['ev_stats'] as Map<String, dynamic>?) ?? {};

  double _num(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

// ════════════════════════════════════════════════════════════
// ANALYTICS CONSTANTS
// ════════════════════════════════════════════════════════════

const vehicleStatusMap = {
  'active':         {'color': 0xFF10B981, 'icon': 'check_circle', 'label': 'Active'},
  'in_maintenance': {'color': 0xFFF59E0B, 'icon': 'wrench', 'label': 'In Maintenance'},
  'out_of_service': {'color': 0xFFEF4444, 'icon': 'car_off', 'label': 'Out of Service'},
  'retired':        {'color': 0xFF64748B, 'icon': 'archive', 'label': 'Retired'},
};

const rentalStatusMap = {
  'draft':     {'color': 0xFF64748B, 'icon': 'edit', 'label': 'Draft'},
  'active':    {'color': 0xFF10B981, 'icon': 'play', 'label': 'Active'},
  'overdue':   {'color': 0xFFEF4444, 'icon': 'clock', 'label': 'Overdue'},
  'completed': {'color': 0xFF6366F1, 'icon': 'check', 'label': 'Completed'},
  'cancelled': {'color': 0xFF94A3B8, 'icon': 'cancel', 'label': 'Cancelled'},
};

const serviceTypeLabels = {
  'oil_change': 'Oil Change',
  'tire_rotation': 'Tire Rotation',
  'brake_service': 'Brake',
  'inspection': 'Inspection',
  'repair': 'Repair',
  'preventive': 'Preventive',
  'other': 'Other',
};

const ratePeriodLabels = {
  'daily': 'Daily',
  'weekly': 'Weekly',
  'monthly': 'Monthly',
  'weekend': 'Weekend',
};

const paymentMethodLabels = {
  'mpesa': 'M-Pesa',
  'cash': 'Cash',
  'card': 'Card',
  'bank_transfer': 'Bank Transfer',
  'cheque': 'Cheque',
  'other': 'Other',
};

int abcClassColor(String cls) {
  switch (cls) {
    case 'A': return 0xFF10B981;
    case 'B': return 0xFF3B82F6;
    case 'C': return 0xFFF59E0B;
    default: return 0xFF94A3B8;
  }
}

List<int> get chartPalette => [
  0xFF6366F1, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444,
  0xFF8B5CF6, 0xFF06B6D4, 0xFFEC4899, 0xFF84CC16,
];
