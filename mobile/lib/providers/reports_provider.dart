import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Reports data provider — mirrors the web `pages/app/reports/index.vue`.
///
/// Fetches financial & operational report data from the backend
/// `/api/reports/` endpoints. Each report type is stored as raw JSON
/// (matching the API response shape) and exposed via typed getters.
class ReportsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  // ── State ───────────────────────────────────────────────────
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ── Data ────────────────────────────────────────────────────
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? _revenue;
  Map<String, dynamic>? _costs;
  List<dynamic> _vehicleRoi = [];
  Map<String, dynamic>? _cashFlow;
  Map<String, dynamic>? _profitLoss;
  Map<String, dynamic>? _locations;
  Map<String, dynamic>? _ownership;
  Map<String, dynamic>? _generalLedger;
  List<dynamic> _templates = [];
  List<dynamic> _schedules = [];
  List<dynamic> _executions = [];

  Map<String, dynamic>? get overview => _overview;
  Map<String, dynamic>? get revenue => _revenue;
  Map<String, dynamic>? get costs => _costs;
  List<dynamic> get vehicleRoi => _vehicleRoi;
  Map<String, dynamic>? get cashFlow => _cashFlow;
  Map<String, dynamic>? get profitLoss => _profitLoss;
  Map<String, dynamic>? get locations => _locations;
  Map<String, dynamic>? get ownership => _ownership;
  Map<String, dynamic>? get generalLedger => _generalLedger;
  List<dynamic> get templates => _templates;
  List<dynamic> get schedules => _schedules;
  List<dynamic> get executions => _executions;

  // ── Standard reports (5 pre-built) ──────────────────────────
  final Map<String, Map<String, dynamic>> _standardReports = {};
  Map<String, Map<String, dynamic>> get standardReports => _standardReports;

  // ── Fetch all reports ───────────────────────────────────────
  Future<void> refreshAll({String? start, String? end}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchReportOverview(start: start, end: end),
        _api.fetchReportRevenue(start: start, end: end),
        _api.fetchReportCosts(start: start, end: end),
        _api.fetchReportVehicleRoi(start: start, end: end),
        _api.fetchReportCashFlow(start: start, end: end),
        _api.fetchReportProfitLoss(start: start, end: end),
        _api.fetchReportLocations(start: start, end: end),
        _api.fetchReportOwnership(start: start, end: end),
        _api.fetchReportGeneralLedger(start: start, end: end),
      ]);
      _overview = results[0] as Map<String, dynamic>;
      _revenue = results[1] as Map<String, dynamic>;
      _costs = results[2] as Map<String, dynamic>;
      _vehicleRoi = results[3] as List<dynamic>;
      _cashFlow = results[4] as Map<String, dynamic>;
      _profitLoss = results[5] as Map<String, dynamic>;
      _locations = results[6] as Map<String, dynamic>;
      _ownership = results[7] as Map<String, dynamic>;
      _generalLedger = results[8] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
      debugPrint('Reports refresh failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Fetch individual reports (for lazy loading) ────────────
  Future<void> fetchOverview({String? start, String? end}) async {
    try {
      _overview = await _api.fetchReportOverview(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Overview fetch failed: $e');
    }
  }

  Future<void> fetchRevenue({String? start, String? end}) async {
    try {
      _revenue = await _api.fetchReportRevenue(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Revenue fetch failed: $e');
    }
  }

  Future<void> fetchCosts({String? start, String? end}) async {
    try {
      _costs = await _api.fetchReportCosts(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Costs fetch failed: $e');
    }
  }

  Future<void> fetchVehicleRoi({String? start, String? end}) async {
    try {
      _vehicleRoi = await _api.fetchReportVehicleRoi(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Vehicle ROI fetch failed: $e');
    }
  }

  Future<void> fetchCashFlow({String? start, String? end}) async {
    try {
      _cashFlow = await _api.fetchReportCashFlow(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Cash flow fetch failed: $e');
    }
  }

  Future<void> fetchProfitLoss({String? start, String? end}) async {
    try {
      _profitLoss = await _api.fetchReportProfitLoss(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('P&L fetch failed: $e');
    }
  }

  Future<void> fetchLocations({String? start, String? end}) async {
    try {
      _locations = await _api.fetchReportLocations(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Locations fetch failed: $e');
    }
  }

  Future<void> fetchOwnership({String? start, String? end}) async {
    try {
      _ownership = await _api.fetchReportOwnership(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('Ownership fetch failed: $e');
    }
  }

  Future<void> fetchGeneralLedger({String? start, String? end}) async {
    try {
      _generalLedger = await _api.fetchReportGeneralLedger(start: start, end: end);
      notifyListeners();
    } catch (e) {
      debugPrint('GL fetch failed: $e');
    }
  }

  // ── Standard reports ───────────────────────────────────────
  Future<void> fetchStandardReport(String type, {int days = 30}) async {
    try {
      final data = await _api.fetchStandardReport(type, days: days);
      _standardReports[type] = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Standard report $type fetch failed: $e');
    }
  }

  Future<void> fetchAllStandardReports({int days = 30}) async {
    const types = ['cost-per-mile', 'fuel-efficiency', 'mechanic-utilization', 'fleet-aging', 'benchmark'];
    try {
      await Future.wait(types.map((t) => fetchStandardReport(t, days: days)));
    } catch (e) {
      debugPrint('Standard reports fetch failed: $e');
    }
  }

  // ── Templates, schedules, executions ───────────────────────
  Future<void> fetchTemplates() async {
    try {
      _templates = await _api.fetchReportTemplates();
      notifyListeners();
    } catch (e) {
      debugPrint('Templates fetch failed: $e');
    }
  }

  Future<void> fetchSchedules() async {
    try {
      _schedules = await _api.fetchReportSchedules();
      notifyListeners();
    } catch (e) {
      debugPrint('Schedules fetch failed: $e');
    }
  }

  Future<void> fetchExecutions() async {
    try {
      _executions = await _api.fetchReportExecutions();
      notifyListeners();
    } catch (e) {
      debugPrint('Executions fetch failed: $e');
    }
  }

  // ── Schedule CRUD ──────────────────────────────────────────
  Future<bool> createSchedule(Map<String, dynamic> data) async {
    try {
      await _api.createReportSchedule(data);
      await fetchSchedules();
      return true;
    } catch (e) {
      debugPrint('Create schedule failed: $e');
      return false;
    }
  }

  Future<bool> updateSchedule(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateReportSchedule(id, data);
      await fetchSchedules();
      return true;
    } catch (e) {
      debugPrint('Update schedule failed: $e');
      return false;
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _api.deleteReportSchedule(id);
      await fetchSchedules();
    } catch (e) {
      debugPrint('Delete schedule failed: $e');
    }
  }

  // ── Misc ───────────────────────────────────────────────────
  Future<bool> seedDemo() async {
    try {
      await _api.seedReportDemo();
      return true;
    } catch (e) {
      debugPrint('Seed demo failed: $e');
      return false;
    }
  }
}
