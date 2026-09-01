import 'package:flutter/foundation.dart';
import '../models/fuel_model.dart';
import '../services/api_service.dart';

export '../models/fuel_model.dart';

/// Fuel & Energy provider — mirrors the web `pages/app/fuel/index.vue` (8 tabs).
class FuelProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  ApiService get api => _api;

  // ── Transactions ────────────────────────────────────────────
  List<FuelTransaction> _transactions = [];
  bool _transactionsLoading = false;
  String _txnSearch = '';

  // ── Analytics ───────────────────────────────────────────────
  Map<String, dynamic> _analytics = {};
  bool _analyticsLoading = false;

  // ── Cards ──────────────────────────────────────────────────
  List<FuelCard> _cards = [];
  bool _cardsLoading = false;

  // ── Charging ────────────────────────────────────────────────
  List<ChargingSession> _charging = [];
  bool _chargingLoading = false;
  Map<String, dynamic> _chargingSummary = {};
  bool _chargingSummaryLoading = false;

  // ── Idling ──────────────────────────────────────────────────
  List<IdlingEvent> _idling = [];
  bool _idlingLoading = false;
  Map<String, dynamic> _idlingSummary = {};
  bool _idlingSummaryLoading = false;

  // ── Fraud ────────────────────────────────────────────────────
  List<FuelFraudAlert> _fraud = [];
  bool _fraudLoading = false;
  Map<String, dynamic> _fraudSummary = {};
  bool _fraudSummaryLoading = false;

  // ── Charge Schedules ───────────────────────────────────────
  List<ChargeSchedule> _schedules = [];
  bool _schedulesLoading = false;

  // ── Budgets ─────────────────────────────────────────────────
  List<FuelBudget> _budgets = [];
  bool _budgetsLoading = false;
  Map<String, dynamic> _budgetSummary = {};
  bool _budgetSummaryLoading = false;

  // ── Vehicles (for dropdowns) ────────────────────────────────
  List<dynamic> _vehicles = [];

  // ── Error ────────────────────────────────────────────────────
  String? _error;

  // ═══ Getters ════════════════════════════════════════════════
  List<FuelTransaction> get transactions => _transactions;
  bool get transactionsLoading => _transactionsLoading;
  String get txnSearch => _txnSearch;

  Map<String, dynamic> get analytics => _analytics;
  bool get analyticsLoading => _analyticsLoading;

  List<FuelCard> get cards => _cards;
  bool get cardsLoading => _cardsLoading;

  List<ChargingSession> get charging => _charging;
  bool get chargingLoading => _chargingLoading;
  Map<String, dynamic> get chargingSummary => _chargingSummary;
  bool get chargingSummaryLoading => _chargingSummaryLoading;

  List<IdlingEvent> get idling => _idling;
  bool get idlingLoading => _idlingLoading;
  Map<String, dynamic> get idlingSummary => _idlingSummary;
  bool get idlingSummaryLoading => _idlingSummaryLoading;

  List<FuelFraudAlert> get fraud => _fraud;
  bool get fraudLoading => _fraudLoading;
  Map<String, dynamic> get fraudSummary => _fraudSummary;
  bool get fraudSummaryLoading => _fraudSummaryLoading;

  List<ChargeSchedule> get schedules => _schedules;
  bool get schedulesLoading => _schedulesLoading;

  List<FuelBudget> get budgets => _budgets;
  bool get budgetsLoading => _budgetsLoading;
  Map<String, dynamic> get budgetSummary => _budgetSummary;
  bool get budgetSummaryLoading => _budgetSummaryLoading;

  List<dynamic> get vehicles => _vehicles;
  String? get error => _error;

  // ── Overview KPI helpers (computed from analytics) ──────────
  double get totalFuelCost => _num(_analytics['total_cost']);
  double get totalVolume => _num(_analytics['total_gallons']);
  double get avgPricePerUnit => _num(_analytics['avg_price_per_gallon']);
  int get fraudAlertCount => _fraudSummary['total'] as int? ?? (_analytics['fraud_count'] as int? ?? 0);

  // ── Charging KPI helpers ────────────────────────────────────
  int get chargingSessionCount => _chargingSummary['session_count'] as int? ?? 0;
  double get chargingTotalKwh => _num(_chargingSummary['total_kwh']);
  double get chargingTotalCost => _num(_chargingSummary['total_cost']);
  double get chargingAvgPerKwh => _num(_chargingSummary['avg_cost_per_kwh']);

  // ── Idling KPI helpers ──────────────────────────────────────
  int get idlingEventCount => _idlingSummary['total_events'] as int? ?? 0;
  double get idlingTotalHours => _num(_idlingSummary['total_hours']);
  double get idlingTotalFuelBurned => _num(_idlingSummary['total_fuel_burned']);
  double get idlingTotalWastedCost => _num(_idlingSummary['total_cost']);

  // ── Fraud KPI helpers ───────────────────────────────────────
  // Backend returns by_status as a list: [{'action_status': 'open', 'count': 3}, ...]
  int _fraudCountByStatus(String status) {
    final byStatus = _fraudSummary['by_status'];
    if (byStatus is List) {
      for (final e in byStatus) {
        if (e is Map && e['action_status'] == status) {
          return (e['count'] as num?)?.toInt() ?? 0;
        }
      }
    } else if (byStatus is Map) {
      return (byStatus[status] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  int get fraudOpenCount => _fraudCountByStatus('open');
  int get fraudReviewCount => _fraudCountByStatus('under_review');
  int get fraudResolvedCount => _fraudCountByStatus('resolved');
  int get fraudDismissedCount => _fraudCountByStatus('dismissed');

  // ── Analytics chart data helpers ───────────────────────────
  List<dynamic> get dailyTrend => _analytics['daily_trend'] as List? ?? [];
  List<dynamic> get byFuelType => _analytics['by_fuel_type'] as List? ?? [];
  List<dynamic> get priceTrend => _analytics['price_trend'] as List? ?? [];
  List<dynamic> get byVehicle => _analytics['by_vehicle'] as List? ?? [];

  // ── Charging chart helpers ─────────────────────────────────
  List<dynamic> get chargingByNetwork => _chargingSummary['by_network'] as List? ?? [];
  List<dynamic> get chargingByVehicle => _chargingSummary['by_vehicle'] as List? ?? [];

  // ── Idling chart helpers ────────────────────────────────────
  List<dynamic> get idlingByVehicle => _idlingSummary['by_vehicle'] as List? ?? [];

  // ── Fraud chart helpers ────────────────────────────────────
  List<dynamic> get fraudByType => _fraudSummary['by_type'] as List? ?? [];

  // ── Budget helpers ──────────────────────────────────────────
  List<dynamic> get budgetRows => _budgetSummary['rows'] as List? ?? [];
  double get actualFleet => _num(_budgetSummary['actual_fleet']);

  // ── Search ──────────────────────────────────────────────────
  void setTxnSearch(String value) { _txnSearch = value; notifyListeners(); }

  List<FuelTransaction> get filteredTransactions {
    if (_txnSearch.isEmpty) return _transactions;
    final q = _txnSearch.toLowerCase();
    return _transactions.where((t) {
      final hay = '${t.vehicleName} ${t.fuelType} ${t.stationName} ${t.notes}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

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
    // Fetch each independently so one failure doesn't nuke all
    fetchTransactions();
    fetchAnalytics();
    fetchCards();
    fetchCharging();
    fetchChargingSummary();
    fetchIdling();
    fetchIdlingSummary();
    fetchFraud();
    fetchFraudSummary();
    fetchSchedules();
    fetchBudgets();
    fetchBudgetSummary();
    _loadVehicles();
  }

  Future<void> fetchTransactions() async {
    _transactionsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchFuelTransactions();
      _transactions = raw.map((e) => FuelTransaction(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _transactionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnalytics({int days = 30}) async {
    _analyticsLoading = true;
    notifyListeners();
    try {
      _analytics = await _api.fetchFuelAnalytics(days: days);
    } catch (e) {
      _error = e.toString();
    } finally {
      _analyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCards() async {
    _cardsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchFuelCards();
      _cards = raw.map((e) => FuelCard(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cardsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCharging() async {
    _chargingLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchChargingSessions();
      _charging = raw.map((e) => ChargingSession(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _chargingLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChargingSummary({int days = 30}) async {
    _chargingSummaryLoading = true;
    notifyListeners();
    try {
      _chargingSummary = await _api.fetchChargingSummary(days: days);
    } catch (e) {
      _error = e.toString();
    } finally {
      _chargingSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIdling() async {
    _idlingLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchIdlingEvents();
      _idling = raw.map((e) => IdlingEvent(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _idlingLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIdlingSummary({int days = 30}) async {
    _idlingSummaryLoading = true;
    notifyListeners();
    try {
      _idlingSummary = await _api.fetchIdlingSummary(days: days);
    } catch (e) {
      _error = e.toString();
    } finally {
      _idlingSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFraud() async {
    _fraudLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchFraudAlerts();
      _fraud = raw.map((e) => FuelFraudAlert(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _fraudLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFraudSummary() async {
    _fraudSummaryLoading = true;
    notifyListeners();
    try {
      _fraudSummary = await _api.fetchFraudSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _fraudSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSchedules() async {
    _schedulesLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchChargeSchedules();
      _schedules = raw.map((e) => ChargeSchedule(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _schedulesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBudgets() async {
    _budgetsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchFuelBudgets();
      _budgets = raw.map((e) => FuelBudget(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _budgetsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBudgetSummary() async {
    _budgetSummaryLoading = true;
    notifyListeners();
    try {
      _budgetSummary = await _api.fetchFuelBudgetSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _budgetSummaryLoading = false;
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

  // ── Transactions ────────────────────────────────────────────
  Future<void> saveTransaction(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveFuelTransaction(payload, id: id);
    await fetchTransactions();
    await fetchAnalytics();
  }

  Future<void> deleteTransaction(int id) async {
    await _api.deleteFuelTransaction(id);
    await fetchTransactions();
    await fetchAnalytics();
  }

  // ── Cards ───────────────────────────────────────────────────
  Future<void> saveCard(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveFuelCard(payload, id: id);
    await fetchCards();
  }

  Future<void> deleteCard(int id) async {
    await _api.deleteFuelCard(id);
    await fetchCards();
  }

  Future<void> syncCard(int id) async {
    await _api.syncFuelCard(id);
    await fetchCards();
  }

  Future<void> syncAllCards() async {
    await _api.syncAllFuelCards();
    await fetchCards();
  }

  // ── Charging ────────────────────────────────────────────────
  Future<void> saveCharging(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveChargingSession(payload, id: id);
    await fetchCharging();
    await fetchChargingSummary();
  }

  Future<void> deleteCharging(int id) async {
    await _api.deleteChargingSession(id);
    await fetchCharging();
    await fetchChargingSummary();
  }

  // ── Idling ──────────────────────────────────────────────────
  Future<void> saveIdling(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveIdlingEvent(payload, id: id);
    await fetchIdling();
    await fetchIdlingSummary();
  }

  Future<void> deleteIdling(int id) async {
    await _api.deleteIdlingEvent(id);
    await fetchIdling();
    await fetchIdlingSummary();
  }

  // ── Schedules ──────────────────────────────────────────────
  Future<void> saveSchedule(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveChargeSchedule(payload, id: id);
    await fetchSchedules();
  }

  Future<void> deleteSchedule(int id) async {
    await _api.deleteChargeSchedule(id);
    await fetchSchedules();
  }

  // ── Budgets ────────────────────────────────────────────────
  Future<void> saveBudget(Map<String, dynamic> payload, {int? id}) async {
    await _api.saveFuelBudget(payload, id: id);
    await fetchBudgets();
    await fetchBudgetSummary();
  }

  Future<void> deleteBudget(int id) async {
    await _api.deleteFuelBudget(id);
    await fetchBudgets();
    await fetchBudgetSummary();
  }

  // ── Fraud actions ───────────────────────────────────────────
  Future<void> resolveFraud(int id, {String note = ''}) async {
    await _api.resolveFraud(id, note: note);
    await fetchFraud();
    await fetchFraudSummary();
  }

  Future<void> dismissFraud(int id, {String note = ''}) async {
    await _api.dismissFraud(id, note: note);
    await fetchFraud();
    await fetchFraudSummary();
  }

  Future<void> reviewFraud(int id, {String note = ''}) async {
    await _api.reviewFraud(id, note: note);
    await fetchFraud();
    await fetchFraudSummary();
  }

  Future<void> reopenFraud(int id, {String note = ''}) async {
    await _api.reopenFraud(id, note: note);
    await fetchFraud();
    await fetchFraudSummary();
  }
}
