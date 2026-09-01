import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

export '../models/analytics_model.dart';

/// Analytics provider — drives all 3 Analytics screens:
/// - Vehicle Analytics
/// - Fuel & Energy Analytics
/// - Car Hire & Rental Analytics
class AnalyticsProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  ApiService get api => _api;

  // ── Vehicle Analytics ──────────────────────────────────────
  VehicleAnalyticsData? _vehicleData;
  bool _vehicleLoading = false;
  String _vehiclePeriod = 'all';
  DateTime? _vehicleCustomFrom;
  DateTime? _vehicleCustomTo;

  // ── Fuel Analytics ─────────────────────────────────────────
  Map<String, dynamic> _fuelData = {};
  bool _fuelLoading = false;
  String _fuelPeriod = '30';
  DateTime? _fuelCustomFrom;
  DateTime? _fuelCustomTo;
  List<dynamic> _groups = [];
  List<dynamic> _locations = [];
  String? _fuelTypeFilter;
  int? _groupFilter;
  String? _locationFilter;

  // ── Rental Analytics ───────────────────────────────────────
  List<Map<String, dynamic>> _agreements = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _paymentSummary = {};
  bool _rentalLoading = false;
  String _rentalPeriod = 'all';
  DateTime? _rentalCustomFrom;
  DateTime? _rentalCustomTo;

  // ── Error ──────────────────────────────────────────────────
  String? _error;

  // ═══ Getters ════════════════════════════════════════════════

  // Vehicle
  VehicleAnalyticsData? get vehicleData => _vehicleData;
  bool get vehicleLoading => _vehicleLoading;
  String get vehiclePeriod => _vehiclePeriod;
  DateTime? get vehicleCustomFrom => _vehicleCustomFrom;
  DateTime? get vehicleCustomTo => _vehicleCustomTo;

  // Fuel
  Map<String, dynamic> get fuelData => _fuelData;
  bool get fuelLoading => _fuelLoading;
  String get fuelPeriod => _fuelPeriod;
  DateTime? get fuelCustomFrom => _fuelCustomFrom;
  DateTime? get fuelCustomTo => _fuelCustomTo;
  List<dynamic> get groups => _groups;
  List<dynamic> get locations => _locations;
  String? get fuelTypeFilter => _fuelTypeFilter;
  int? get groupFilter => _groupFilter;
  String? get locationFilter => _locationFilter;

  // Rental
  List<Map<String, dynamic>> get agreements => _agreements;
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get payments => _payments;
  Map<String, dynamic> get paymentSummary => _paymentSummary;
  bool get rentalLoading => _rentalLoading;
  String get rentalPeriod => _rentalPeriod;
  DateTime? get rentalCustomFrom => _rentalCustomFrom;
  DateTime? get rentalCustomTo => _rentalCustomTo;

  String? get error => _error;

  // ── Fuel KPI helpers ───────────────────────────────────────
  double get fuelTotalCost => _num(_fuelData['total_cost']);
  double get fuelTotalGallons => _num(_fuelData['total_gallons']);
  double get fuelAvgPricePerGallon => _num(_fuelData['avg_price_per_gallon']);
  int get fuelTransactionCount => _fuelData['transaction_count'] as int? ?? 0;
  double get fuelMaxTxnCost => _num(_fuelData['max_transaction_cost']);
  double get fuelMinTxnCost => _num(_fuelData['min_transaction_cost']);
  double get fuelAvgPerTxn => _num(_fuelData['avg_price_per_transaction']);
  List<dynamic> get fuelDailyTrend => _fuelData['daily_trend'] as List? ?? [];
  List<dynamic> get fuelPriceTrend => _fuelData['price_trend'] as List? ?? [];
  List<dynamic> get fuelMonthlyTrend => _fuelData['monthly_trend'] as List? ?? [];
  List<dynamic> get fuelByFuelType => _fuelData['by_fuel_type'] as List? ?? [];
  List<dynamic> get fuelByStation => _fuelData['by_station'] as List? ?? [];
  List<dynamic> get fuelByVehicle => _fuelData['by_vehicle'] as List? ?? [];
  List<dynamic> get fuelByGroupDaily => _fuelData['by_group_daily'] as List? ?? [];

  // ── Rental computed stats ─────────────────────────────────
  List<Map<String, dynamic>> get filteredAgreements {
    return _agreements.where((a) => _rentalDateFilter(_agreementDate(a))).toList();
  }

  List<Map<String, dynamic>> get filteredPayments {
    return _payments.where((p) {
      final paidAt = p['paid_at'] as String?;
      if (paidAt == null) return false;
      return _rentalDateFilter(DateTime.tryParse(paidAt));
    }).toList();
  }

  int get rentalTotal => filteredAgreements.length;
  int get rentalActive => filteredAgreements.where((a) => _effectiveStatus(a) == 'active').length;
  int get rentalOverdue => filteredAgreements.where((a) => _effectiveStatus(a) == 'overdue').length;
  int get rentalCompleted => filteredAgreements.where((a) => a['status'] == 'completed').length;
  int get rentalCancelled => filteredAgreements.where((a) => a['status'] == 'cancelled').length;
  int get rentalDraft => filteredAgreements.where((a) => a['status'] == 'draft').length;
  int get rentalCustomers => _customers.length;
  int get rentalLocal => _customers.where((c) => c['customer_type'] == 'local').length;
  int get rentalForeigner => _customers.where((c) => c['customer_type'] == 'foreigner').length;
  int get rentalPaymentCount => filteredPayments.length;

  double get rentalRevenue {
    double sum = 0;
    for (final a in filteredAgreements) {
      sum += _num(a['total_amount']);
    }
    return sum;
  }

  double get rentalCollected => _num(_paymentSummary['total_collected']);
  double get rentalOutstanding => _num(_paymentSummary['total_outstanding']);

  int get collectionRate {
    final inv = rentalRevenue;
    final col = rentalCollected;
    return inv > 0 ? ((col / inv) * 100).round() : 0;
  }

  int get uniqueVehicles {
    final ids = filteredAgreements.map((a) => a['vehicle']).where((v) => v != null).toSet();
    return ids.length;
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // ═══ Period / Filter ════════════════════════════════════════

  void setVehiclePeriod(String period) { _vehiclePeriod = period; notifyListeners(); }
  void setVehicleCustomFrom(DateTime? d) { _vehicleCustomFrom = d; notifyListeners(); }
  void setVehicleCustomTo(DateTime? d) { _vehicleCustomTo = d; notifyListeners(); }

  void setFuelPeriod(String period) { _fuelPeriod = period; notifyListeners(); }
  void setFuelCustomFrom(DateTime? d) { _fuelCustomFrom = d; notifyListeners(); }
  void setFuelCustomTo(DateTime? d) { _fuelCustomTo = d; notifyListeners(); }
  void setFuelTypeFilter(String? v) { _fuelTypeFilter = v; notifyListeners(); }
  void setGroupFilter(int? v) { _groupFilter = v; notifyListeners(); }
  void setLocationFilter(String? v) { _locationFilter = v; notifyListeners(); }

  void setRentalPeriod(String period) { _rentalPeriod = period; notifyListeners(); }
  void setRentalCustomFrom(DateTime? d) { _rentalCustomFrom = d; notifyListeners(); }
  void setRentalCustomTo(DateTime? d) { _rentalCustomTo = d; notifyListeners(); }

  // ═══ Date query builders ═══════════════════════════════════

  ({String? gte, String? lte}) _vehicleDateQuery() {
    final now = DateTime.now();
    switch (_vehiclePeriod) {
      case 'y':
        return (gte: '${now.year}-01-01', lte: null);
      case '365':
        return (gte: now.subtract(const Duration(days: 365)).toIso8601String().split('T')[0], lte: null);
      case '90':
        return (gte: now.subtract(const Duration(days: 90)).toIso8601String().split('T')[0], lte: null);
      case 'custom':
        return (
          gte: _vehicleCustomFrom?.toIso8601String().split('T')[0],
          lte: _vehicleCustomTo?.toIso8601String().split('T')[0],
        );
      default:
        return (gte: null, lte: null);
    }
  }

  ({int? days, String? gte, String? lte}) _fuelDateQuery() {
    switch (_fuelPeriod) {
      case '7': return (days: 7, gte: null, lte: null);
      case '90': return (days: 90, gte: null, lte: null);
      case '365': return (days: 365, gte: null, lte: null);
      case 'custom':
        return (
          days: null,
          gte: _fuelCustomFrom?.toIso8601String().split('T')[0],
          lte: _fuelCustomTo?.toIso8601String().split('T')[0],
        );
      default: return (days: 30, gte: null, lte: null);
    }
  }

  bool _rentalDateFilter(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    switch (_rentalPeriod) {
      case 'all': return true;
      case 'y': return date.year >= now.year;
      case '365': return date.isAfter(now.subtract(const Duration(days: 365)));
      case '90': return date.isAfter(now.subtract(const Duration(days: 90)));
      case 'custom':
        if (_rentalCustomFrom != null && date.isBefore(_rentalCustomFrom!)) return false;
        if (_rentalCustomTo != null && date.isAfter(_rentalCustomTo!.add(const Duration(hours: 23, minutes: 59)))) return false;
        return true;
      default: return true;
    }
  }

  DateTime? _agreementDate(Map<String, dynamic> a) {
    final created = a['created_at'] as String?;
    final start = a['start_datetime'] as String?;
    return DateTime.tryParse(created ?? '') ?? DateTime.tryParse(start ?? '');
  }

  String _effectiveStatus(Map<String, dynamic> a) {
    final status = a['status'] as String? ?? 'draft';
    if (status == 'active') {
      final endStr = a['end_datetime'] as String?;
      final end = endStr != null ? DateTime.tryParse(endStr) : null;
      if (end != null && end.isBefore(DateTime.now())) return 'overdue';
    }
    return status;
  }

  // ═══ Fetch operations ════════════════════════════════════════

  Future<void> fetchVehicleAnalytics() async {
    _vehicleLoading = true;
    _error = null;
    notifyListeners();
    try {
      final q = _vehicleDateQuery();
      _vehicleData = VehicleAnalyticsData(await _api.fetchVehicleAnalytics(
        dateGte: q.gte,
        dateLte: q.lte,
      ));
    } catch (e) {
      _error = e.toString();
    } finally {
      _vehicleLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFuelAnalytics() async {
    _fuelLoading = true;
    _error = null;
    notifyListeners();
    try {
      final q = _fuelDateQuery();
      _fuelData = await _api.fetchFuelAnalytics(
        days: q.days ?? 30,
        fuelType: _fuelTypeFilter,
        vehicleGroup: _groupFilter,
        vehicleLocation: _locationFilter,
        dateGte: q.gte,
        dateLte: q.lte,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _fuelLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroupAndLocationOptions() async {
    try {
      final gRes = await _api.get('/vehicles/groups/');
      _groups = _drToList(gRes.data);
      final lRes = await _api.get('/locations/');
      _locations = _drToList(lRes.data);
      notifyListeners();
    } catch (_) {}
  }

  List<dynamic> _drToList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<void> fetchRentalAnalytics() async {
    _rentalLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchRentalAgreements(),
        _api.fetchCustomers(),
        _api.fetchRentalPayments(),
        _api.fetchRentalPaymentSummary(),
      ]);
      _agreements = (results[0] as List).cast<Map<String, dynamic>>();
      _customers = (results[1] as List).cast<Map<String, dynamic>>();
      _payments = (results[2] as List).cast<Map<String, dynamic>>();
      _paymentSummary = results[3] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _rentalLoading = false;
      notifyListeners();
    }
  }
}
