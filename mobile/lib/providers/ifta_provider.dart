import 'package:flutter/foundation.dart';
import '../models/ifta_model.dart';
import '../services/api_service.dart';

export '../models/ifta_model.dart';

/// IFTA & Fuel Tax provider — mirrors the web `pages/app/ifta/index.vue` (3 tabs).
class IftaProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  ApiService get api => _api;

  // ── Trip Logs ──────────────────────────────────────────────
  List<TripLog> _tripLogs = [];
  bool _tripLogsLoading = false;

  // ── Fuel Purchases ─────────────────────────────────────────
  List<FuelPurchase> _fuelPurchases = [];
  bool _fuelPurchasesLoading = false;

  // ── Quarters ───────────────────────────────────────────────
  List<IftaQuarter> _quarters = [];
  bool _quartersLoading = false;

  // ── Stats ──────────────────────────────────────────────────
  Map<String, dynamic> _stats = {};
  bool _statsLoading = false;

  // ── Jurisdictions ─────────────────────────────────────────
  List<Jurisdiction> _jurisdictions = [];
  bool _jurisdictionsLoading = false;

  // ── Breakdown ──────────────────────────────────────────────
  Map<int, List<QuarterBreakdownRow>> _breakdownCache = {};
  Map<int, bool> _breakdownLoading = {};

  // ── Vehicles ──────────────────────────────────────────────
  List<dynamic> _vehicles = [];

  // ── Search/filter ──────────────────────────────────────────
  String _search = '';
  int? _vehicleFilter;
  int? _jurisdictionFilter;

  // ── Error ──────────────────────────────────────────────────
  String? _error;

  // ═══ Getters ════════════════════════════════════════════════
  List<TripLog> get tripLogs => _tripLogs;
  bool get tripLogsLoading => _tripLogsLoading;

  List<FuelPurchase> get fuelPurchases => _fuelPurchases;
  bool get fuelPurchasesLoading => _fuelPurchasesLoading;

  List<IftaQuarter> get quarters => _quarters;
  bool get quartersLoading => _quartersLoading;

  Map<String, dynamic> get stats => _stats;
  bool get statsLoading => _statsLoading;

  List<Jurisdiction> get jurisdictions => _jurisdictions;
  bool get jurisdictionsLoading => _jurisdictionsLoading;

  List<dynamic> get vehicles => _vehicles;
  String? get error => _error;

  String get search => _search;
  int? get vehicleFilter => _vehicleFilter;
  int? get jurisdictionFilter => _jurisdictionFilter;

  // ── Stats helpers ──────────────────────────────────────────
  int get totalTrips => _stats['total_trips'] as int? ?? 0;
  int get totalFuelPurchases => _stats['total_fuel_purchases'] as int? ?? 0;
  double get totalMiles => _num(_stats['total_miles']);
  double get totalGallons => _num(_stats['total_gallons']);
  double get totalFuelCost => _num(_stats['total_fuel_cost']);
  double get totalTaxPaid => _num(_stats['total_tax_paid']);
  double get totalNetTax => _num(_stats['total_net_tax']);
  double get avgMpg => _num(_stats['avg_mpg']);
  int get jurisdictionCount => _stats['jurisdiction_count'] as int? ?? 0;
  int get quarterCount => _stats['quarter_count'] as int? ?? 0;
  Map<String, dynamic> get byStatus => (_stats['by_status'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get byQuarter => (_stats['by_quarter'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get byVehicle => _stats['by_vehicle'] as List? ?? [];

  // ── Search/filter ──────────────────────────────────────────
  void setSearch(String value) { _search = value; notifyListeners(); }
  void setVehicleFilter(int? value) { _vehicleFilter = value; notifyListeners(); }
  void setJurisdictionFilter(int? value) { _jurisdictionFilter = value; notifyListeners(); }
  void clearFilters() { _search = ''; _vehicleFilter = null; _jurisdictionFilter = null; notifyListeners(); }

  List<TripLog> get filteredTripLogs {
    if (_search.isEmpty && _vehicleFilter == null && _jurisdictionFilter == null) return _tripLogs;
    final q = _search.toLowerCase();
    return _tripLogs.where((t) {
      if (_search.isNotEmpty) {
        final hay = '${t.vehicleName} ${t.jurisdictionName} ${t.jurisdictionCode} ${t.route} ${t.notes}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_vehicleFilter != null && t.vehicleId != _vehicleFilter) return false;
      if (_jurisdictionFilter != null && t.jurisdictionId != _jurisdictionFilter) return false;
      return true;
    }).toList();
  }

  List<FuelPurchase> get filteredFuelPurchases {
    if (_search.isEmpty && _vehicleFilter == null && _jurisdictionFilter == null) return _fuelPurchases;
    final q = _search.toLowerCase();
    return _fuelPurchases.where((p) {
      if (_search.isNotEmpty) {
        final hay = '${p.vehicleName} ${p.jurisdictionCode} ${p.vendor}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_vehicleFilter != null && p.vehicleId != _vehicleFilter) return false;
      if (_jurisdictionFilter != null && p.jurisdictionId != _jurisdictionFilter) return false;
      return true;
    }).toList();
  }

  bool isBreakdownLoading(int id) => _breakdownLoading[id] ?? false;
  List<QuarterBreakdownRow>? breakdownFor(int id) => _breakdownCache[id];

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // ═══ Fetch operations ════════════════════════════════════════

  Future<void> refreshAll() async {
    _error = null;
    notifyListeners();
    fetchTripLogs();
    fetchFuelPurchases();
    fetchQuarters();
    fetchStats();
    fetchJurisdictions();
    _loadVehicles();
  }

  Future<void> fetchTripLogs() async {
    _tripLogsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchTripLogs();
      _tripLogs = raw.map((e) => TripLog(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _tripLogsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFuelPurchases() async {
    _fuelPurchasesLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchFuelPurchases();
      _fuelPurchases = raw.map((e) => FuelPurchase(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _fuelPurchasesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchQuarters() async {
    _quartersLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchIftaQuarters();
      _quarters = raw.map((e) => IftaQuarter(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _quartersLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    _statsLoading = true;
    notifyListeners();
    try {
      _stats = await _api.fetchIftaStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchJurisdictions() async {
    _jurisdictionsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchJurisdictions();
      _jurisdictions = raw.map((e) => Jurisdiction(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _jurisdictionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBreakdown(int id) async {
    _breakdownLoading[id] = true;
    notifyListeners();
    try {
      final raw = await _api.fetchQuarterBreakdown(id);
      _breakdownCache[id] = raw.map((e) => QuarterBreakdownRow(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _breakdownLoading[id] = false;
      notifyListeners();
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final raw = await _api.get('/vehicles/').then((r) {
        final d = r.data;
        if (d is List) return d;
        if (d is Map<String, dynamic> && d['results'] != null) return d['results'] as List;
        return [];
      });
      _vehicles = raw;
      notifyListeners();
    } catch (_) {}
  }

  // ═══ CRUD ═══════════════════════════════════════════════════

  // ── Trip Logs ──────────────────────────────────────────────
  Future<void> saveTripLog(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveTripLog(payload, id: id);
    await fetchTripLogs();
    await fetchStats();
  }

  Future<void> deleteTripLog(int id) async {
    await _api.deleteTripLog(id);
    await fetchTripLogs();
    await fetchStats();
  }

  // ── Fuel Purchases ─────────────────────────────────────────
  Future<void> saveFuelPurchase(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveFuelPurchase(payload, id: id);
    await fetchFuelPurchases();
    await fetchStats();
  }

  Future<void> deleteFuelPurchase(int id) async {
    await _api.deleteFuelPurchase(id);
    await fetchFuelPurchases();
    await fetchStats();
  }

  // ── Jurisdictions ──────────────────────────────────────────
  Future<void> saveJurisdiction(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveJurisdiction(payload, id: id);
    await fetchJurisdictions();
  }

  Future<void> deleteJurisdiction(int id) async {
    await _api.deleteJurisdiction(id);
    await fetchJurisdictions();
  }

  // ── Quarters ──────────────────────────────────────────────
  Future<void> saveQuarter(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveIftaQuarter(payload, id: id);
    await fetchQuarters();
    await fetchStats();
  }

  Future<void> deleteQuarter(int id) async {
    await _api.deleteIftaQuarter(id);
    await fetchQuarters();
    await fetchStats();
  }

  Future<void> generateQuarter(Map<String, dynamic> payload) async {
    await _api.generateIftaQuarter(payload);
    await fetchQuarters();
    await fetchStats();
  }

  Future<void> seedDemo() async {
    await _api.seedIftaDemo();
    await refreshAll();
  }
}
