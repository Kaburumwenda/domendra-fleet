import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Billing provider — mirrors the web `pages/app/billing/index.vue`.
///
/// Usage-based billing at USD 0.077 / 1,000 API requests. This provider
/// exposes:
///   - [subscription]  – current cycle counters + cost projections
///   - [summary]       – analytics KPIs (total requests, errors, etc.)
///   - [dailySeries]   – per-day request/error counts for charts
///   - [methodDist]    – HTTP method distribution (GET/POST/…)
///   - [statusDist]   – HTTP status-code distribution
///   - [hourDist]      – requests per hour (0-23)
///   - [bills]         – monthly invoices with pay/view actions
///   - [billingCurrency] / [exchangeRate] – local currency conversion
class BillingProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  Map<String, dynamic>? _analytics;
  List<dynamic> _bills = [];
  String _billingCurrency = 'USD';
  double _exchangeRate = 1;
  bool _loading = false;
  bool _paying = false;
  String? _error;

  // ── Date-range filter state ───────────────────────────────
  /// One of: today, this_week, last_week, this_month, last_month,
  /// this_quarter, this_year, last_year, all_time, or 'custom'.
  String _preset = 'this_month';
  String? _customStart;
  String? _customEnd;

  // ── Public getters ────────────────────────────────────────
  bool get loading => _loading;
  bool get paying => _paying;
  String? get error => _error;
  String get preset => _preset;
  String? get customStart => _customStart;
  String? get customEnd => _customEnd;
  String get billingCurrency => _billingCurrency;
  double get exchangeRate => _exchangeRate;

  /// Raw subscription object (may be null before load).
  Map<String, dynamic>? get subscription =>
      _analytics?['subscription'] as Map<String, dynamic>?;

  /// Analytics summary KPIs.
  Map<String, dynamic> get summary {
    final s = _analytics?['summary'];
    if (s is Map<String, dynamic>) return s;
    return {};
  }

  List<Map<String, dynamic>> get dailySeries {
    final raw = _analytics?['daily_series'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  List<Map<String, dynamic>> get methodDist {
    final raw = _analytics?['method_distribution'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  List<Map<String, dynamic>> get statusDist {
    final raw = _analytics?['status_distribution'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  /// Hours 0-23 → request counts.
  List<int> get hourDist {
    final raw = _analytics?['hour_distribution'];
    if (raw is List) return raw.map((e) => _toInt(e)).toList();
    return List.filled(24, 0);
  }

  List<dynamic> get bills => _bills;
  int get billCount => _bills.length;

  int get overdueCount =>
      _bills.where((b) => (b as Map)['status'] == 'overdue').length;

  // ── Subscription helper getters ───────────────────────────
  int get requestCount => _readInt(subscription, 'request_count');
  int get cycleDay => _readInt(subscription, 'cycle_day');
  int get monthlyAverage => _readInt(subscription, 'monthly_average');
  int get endOfMonthProjection =>
      _readInt(subscription, 'end_of_month_projection');
  double get estimatedCostUsd =>
      _readDouble(subscription, 'estimated_cost_usd');
  double get projectedCostUsd =>
      _readDouble(subscription, 'projected_cost_usd');
  double get estimatedCostLocal =>
      _readDouble(subscription, 'estimated_cost_local');
  double get projectedCostLocal =>
      _readDouble(subscription, 'projected_cost_local');
  double get ratePer1000 {
    final v = _readDouble(subscription, 'rate_per_1000_requests');
    return v > 0 ? v : 0.077;
  }
  String? get currentPeriodEnd =>
      subscription?['current_period_end'] as String?;

  // ── Analytics summary getters ─────────────────────────────
  int get totalRequests => _readInt(summary, 'total_requests');
  int get totalErrors => _readInt(summary, 'total_errors');
  double get errorRate => _readDouble(summary, 'error_rate');
  double get avgResponseMs => _readDouble(summary, 'avg_response_ms');
  double get requestTrend => _readDouble(summary, 'request_trend');

  // ── Date-range helpers ────────────────────────────────────

  static const List<Map<String, String>> presets = [
    {'label': 'Today', 'value': 'today'},
    {'label': 'This Week', 'value': 'this_week'},
    {'label': 'Last Week', 'value': 'last_week'},
    {'label': 'This Month', 'value': 'this_month'},
    {'label': 'Last Month', 'value': 'last_month'},
    {'label': 'This Quarter', 'value': 'this_quarter'},
    {'label': 'This Year', 'value': 'this_year'},
    {'label': 'Last Year', 'value': 'last_year'},
    {'label': 'All Time', 'value': 'all_time'},
  ];

  void setPreset(String value) {
    _preset = value;
    _customStart = null;
    _customEnd = null;
    notifyListeners();
    refreshAll();
  }

  void setCustomRange(String start, String end) {
    _preset = 'custom';
    _customStart = start;
    _customEnd = end;
    notifyListeners();
    refreshAll();
  }

  Map<String, String?> get activeParams {
    if (_preset == 'custom' && _customStart != null && _customEnd != null) {
      return {'start': _customStart, 'end': _customEnd};
    }
    return {'preset': _preset, 'start': null, 'end': null};
  }

  // ── Data fetching ─────────────────────────────────────────

  Future<void> refreshAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
    await Future.wait([
        _fetchAnalytics(),
        _fetchBills(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Billing fetch failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExchangeRate() async {
    try {
      final res = await _api.fetchBillingExchangeRate();
      _billingCurrency = res['currency'] as String? ?? 'USD';
      _exchangeRate = _toDouble(res['rate']) ?? 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Exchange rate fetch failed: $e');
    }
  }

  Future<void> _fetchAnalytics() async {
    final params = activeParams;
    _analytics = await _api.fetchBillingAnalytics(
      preset: params['preset'],
      start: params['start'],
      end: params['end'],
    );
  }

  Future<void> _fetchBills() async {
    final params = activeParams;
    _bills = await _api.fetchBillingBills(
      preset: params['preset'] != 'custom' ? params['preset'] : null,
      start: params['start'],
      end: params['end'],
    );
  }

  /// Make a payment against a bill, then re-fetch bills + analytics.
  Future<bool> payBill(int billId, {required double amount, required String method, String? reference}) async {
    _paying = true;
    notifyListeners();
    try {
      await _api.payBillingBill(billId, amount: amount, method: method, reference: reference);
      await Future.wait([_fetchAnalytics(), _fetchBills()]);
      return true;
    } catch (e) {
      debugPrint('Payment failed: $e');
      rethrow;
    } finally {
      _paying = false;
      notifyListeners();
    }
  }

  /// Fetch a single bill's full detail (with payments array).
  Future<Map<String, dynamic>> fetchBillDetail(int id) async {
    return _api.fetchBillingBill(id);
  }

  // ── Private helpers ───────────────────────────────────────

  static int _readInt(Map<String, dynamic>? m, String key) {
    if (m == null) return 0;
    final v = m[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _readDouble(Map<String, dynamic>? m, String key) {
    if (m == null) return 0;
    final v = m[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
