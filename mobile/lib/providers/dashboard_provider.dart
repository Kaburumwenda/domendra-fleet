import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Dashboard data provider — mirrors the web `pages/app/index.vue`.
///
/// The backend `GET /api/dashboard/` returns nested objects:
///   { period, kpis, alerts, upcoming, monthly, cost_trend,
///     recent_rentals, recent_fuel, recent_services, status_counts,
///     monthly_bar, revenue_by_type, charts }
///
/// This provider exposes typed getters for each field.
class DashboardProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;
  String _currencySymbol = 'KSh';

  Map<String, dynamic>? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  String get currencySymbol => _currencySymbol;

  static const Map<String, String> _symbolFor = {
    'USD': r'$', 'EUR': '€', 'GBP': '£', 'KES': 'KSh', 'NGN': '₦', 'ZAR': 'R',
    'AED': 'AED', 'SAR': 'SAR', 'INR': '₹', 'CAD': r'C$', 'AUD': r'A$',
    'JPY': '¥', 'CNY': '¥', 'BRL': r'R$', 'GHS': '₵', 'TZS': 'TSh',
    'UGX': 'USh', 'RWF': 'FRw', 'ETB': 'Br',
  };

  /// Resolve a currency code to its display symbol.
  static String symbolFor(String? code) {
    if (code == null || code.isEmpty) return 'KSh';
    return _symbolFor[code.toUpperCase()] ?? code.toUpperCase();
  }

  /// Load the tenant's currency from the backend.
  Future<void> loadCurrency() async {
    try {
      final tenant = await _api.fetchTenantSettings();
      final code = tenant['currency'] as String?;
      _currencySymbol = symbolFor(code);
      notifyListeners();
    } catch (e) {
      debugPrint('Currency load failed: \$e');
    }
  }

  // ── Period ──────────────────────────────────────────────────
  String get periodStart => _data?['period']?['start'] as String? ?? '';
  String get periodEnd => _data?['period']?['end'] as String? ?? '';

  // ── KPIs ───────────────────────────────────────────────────
  int get totalVehicles => _readInt('kpis', 'total_vehicles');
  int get activeVehicles => _readInt('kpis', 'active_vehicles');
  int get outOfService => _readInt('kpis', 'out_of_service');
  double get fleetUtilization => _readDouble('kpis', 'fleet_utilization');
  int get totalDrivers => _readInt('kpis', 'total_drivers');
  double get totalPurchaseValue => _readDouble('kpis', 'total_purchase_value');

  // ── Period label ──────────────────────────────────────────
  String get periodLabel {
    final p = _data?['period'];
    if (p == null) return '';
    final s = _parseDate(p['start'] as String?);
    final e = _parseDate(p['end'] as String?);
    if (s == null || e == null) return '';
    return '${_fmtDate(s)} — ${_fmtDate(e)}';
  }

  static DateTime? _parseDate(String? v) {
    if (v == null || v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  static String _fmtDate(DateTime d) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${names[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ── Alerts ─────────────────────────────────────────────────
  int get openIssues => _readInt('alerts', 'open_issues');
  int get criticalIssues => _readInt('alerts', 'critical_issues');
  int get openWorkOrders => _readInt('alerts', 'open_work_orders');
  int get overdueReminders => _readInt('alerts', 'overdue_reminders');
  int get expiredDocs => _readInt('alerts', 'expired_docs');
  int get lowStockItems => _readInt('alerts', 'low_stock_items');
  int get failedInspections30d => _readInt('alerts', 'failed_inspections_30d');

  // ── Upcoming ──────────────────────────────────────────────
  int get reminders7d => _readInt('upcoming', 'reminders_7d');
  int get expiringDocs30d => _readInt('upcoming', 'expiring_docs_30d');
  int get recentInspections30d => _readInt('upcoming', 'recent_inspections_30d');

  // ── Monthly ───────────────────────────────────────────────
  double get monthlyRevenue => _readDouble('monthly', 'revenue');
  double get monthlyRentalTotal => _readDouble('monthly', 'rental_total');
  double get monthlyFuelCost => _readDouble('monthly', 'fuel_cost');
  double get monthlyServiceCost => _readDouble('monthly', 'service_cost');
  int get monthlyAccidents => _readInt('monthly', 'accidents');

  // ── Charts ────────────────────────────────────────────────
  List<dynamic> get vehiclesByStatus => _data?['charts']?['vehicles_by_status'] as List? ?? [];
  List<dynamic> get vehiclesByType => _data?['charts']?['vehicles_by_type'] as List? ?? [];
  List<dynamic> get vehiclesByFuel => _data?['charts']?['vehicles_by_fuel'] as List? ?? [];
  List<dynamic> get costTrend => _data?['cost_trend'] as List? ?? [];
  List<dynamic> get monthlyBar => _data?['monthly_bar'] as List? ?? [];
  List<dynamic> get revenueByType => _data?['revenue_by_type'] as List? ?? [];
  Map<String, dynamic>? get statusCounts => _data?['status_counts'] as Map<String, dynamic>?;

  // ── Recent activity ──────────────────────────────────────
  List<dynamic> get recentRentals => _data?['recent_rentals'] as List? ?? [];
  List<dynamic> get recentFuel => _data?['recent_fuel'] as List? ?? [];
  List<dynamic> get recentServices => _data?['recent_services'] as List? ?? [];

  // ── Rental trend ──────────────────────────────────────────
  List<dynamic> _trend = [];
  String _trendPeriod = 'month';

  List<dynamic> get trend => _trend;
  String get trendPeriod => _trendPeriod;

  Future<void> fetchTrend({String? period, String? start, String? end}) async {
    try {
      final params = <String, dynamic>{};
      if (period != null) params['period'] = period;
      if (start != null) params['start'] = start;
      if (end != null) params['end'] = end;
      final res = await ApiService.instance.get('/dashboard/rental-trend/', query: params);
      _trend = res.data['trend'] as List? ?? [];
      _trendPeriod = res.data['bucket'] as String? ?? period ?? 'month';
      notifyListeners();
    } catch (e) {
      // Trend is supplementary — don't overwrite main error
      debugPrint('Trend fetch failed: $e');
    }
  }

  // ── Fetch main dashboard ──────────────────────────────────
  Future<void> refresh({String? startDate, String? endDate}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _api.fetchDashboard(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  int _readInt(String section, String key) {
    final v = _data?[section]?[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  double _readDouble(String section, String key) {
    final v = _data?[section]?[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
