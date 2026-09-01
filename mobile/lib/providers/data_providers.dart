import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/num_cast.dart';

/// Rentals / Car Hire provider — drives all 5 tabs of the rentals screen
/// (Dashboard, Agreements, Payments, Customers, Pricing).
class RentalsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  // ── Data ────────────────────────────────────────────────────
  List<dynamic> _agreements = [];
  List<dynamic> _customers = [];
  List<dynamic> _payments = [];
  List<dynamic> _pricing = [];
  Map<String, dynamic> _paymentSummary = {};

  bool _loading = false;
  bool _customersLoading = false;
  bool _paymentsLoading = false;
  bool _pricingLoading = false;
  String? _error;

  // ── Getters ─────────────────────────────────────────────────
  List<dynamic> get agreements => _agreements;
  List<dynamic> get customers => _customers;
  List<dynamic> get payments => _payments;
  List<dynamic> get pricing => _pricing;
  Map<String, dynamic> get paymentSummary => _paymentSummary;

  bool get loading => _loading;
  bool get customersLoading => _customersLoading;
  bool get paymentsLoading => _paymentsLoading;
  bool get pricingLoading => _pricingLoading;
  String? get error => _error;

  /// Effective status — turns `active` into `overdue` when end time has passed.
  String effectiveStatus(Map<String, dynamic> a) {
    final s = (a['status'] as String?) ?? 'draft';
    if (s == 'active') {
      final end = a['end_datetime'] as String?;
      if (end != null) {
        try {
          if (DateTime.parse(end).isBefore(DateTime.now())) return 'overdue';
        } catch (_) {}
      }
    }
    return s;
  }

  // ── Stats / KPIs ────────────────────────────────────────────
  int get totalAgreements => _agreements.length;
  int get activeCount => _agreements.where((a) => effectiveStatus(a as Map<String, dynamic>) == 'active').length;
  int get overdueCount => _agreements.where((a) => effectiveStatus(a as Map<String, dynamic>) == 'overdue').length;
  int get completedCount => _agreements.where((a) => (a as Map<String, dynamic>)['status'] == 'completed').length;
  int get customersCount => _customers.length;
  int get localCount => _customers.where((c) => (c as Map)['customer_type'] == 'local').length;
  int get foreignerCount => _customers.where((c) => (c as Map)['customer_type'] == 'foreigner').length;
  double get totalRevenue => _agreements.fold<double>(0, (s, a) => s + toDoubleOr((a as Map)['total_amount']));

  double get totalCollected => toDoubleOr(_paymentSummary['total_collected']);
  double get totalOutstanding => toDoubleOr(_paymentSummary['total_outstanding']);
  double get totalInvoices => toDoubleOr(_paymentSummary['total_invoices']);
  int get paymentCount => toIntOr(_paymentSummary['payment_count']);
  int get collectionRate {
    final inv = totalInvoices;
    if (inv == 0) return 0;
    return ((totalCollected / inv) * 100).round();
  }

  // ── Agreement status groupings (for board view) ────────────
  List<dynamic> get draftAgreements => _agreements.where((a) => effectiveStatus(a as Map<String, dynamic>) == 'draft').toList();
  List<dynamic> get activeAgreements => _agreements.where((a) => effectiveStatus(a as Map<String, dynamic>) == 'active').toList();
  List<dynamic> get overdueAgreements => _agreements.where((a) => effectiveStatus(a as Map<String, dynamic>) == 'overdue').toList();
  List<dynamic> get completedAgreements => _agreements.where((a) => (a as Map<String, dynamic>)['status'] == 'completed').toList();
  List<dynamic> get cancelledAgreements => _agreements.where((a) => (a as Map<String, dynamic>)['status'] == 'cancelled').toList();

  // ── Fetch all ───────────────────────────────────────────────
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchRentalAgreements(),
        _api.fetchCustomers(),
        _api.fetchRentalPayments(),
        _api.fetchRentalPricing(),
        _api.fetchRentalPaymentSummary(),
      ]);
      _agreements = results[0] as List<dynamic>;
      _customers = results[1] as List<dynamic>;
      _payments = results[2] as List<dynamic>;
      _pricing = results[3] as List<dynamic>;
      _paymentSummary = results[4] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAgreements() async {
    try {
      _agreements = await _api.fetchRentalAgreements();
      _paymentSummary = await _api.fetchRentalPaymentSummary();
      notifyListeners();
    } catch (e) {
      debugPrint('refreshAgreements failed: $e');
    }
  }

  Future<void> refreshPayments() async {
    _paymentsLoading = true;
    notifyListeners();
    try {
      _payments = await _api.fetchRentalPayments();
      _paymentSummary = await _api.fetchRentalPaymentSummary();
    } catch (e) {
      debugPrint('refreshPayments failed: $e');
    } finally {
      _paymentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCustomers() async {
    _customersLoading = true;
    notifyListeners();
    try {
      _customers = await _api.fetchCustomers();
    } catch (e) {
      debugPrint('refreshCustomers failed: $e');
    } finally {
      _customersLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPricing() async {
    _pricingLoading = true;
    notifyListeners();
    try {
      _pricing = await _api.fetchRentalPricing();
    } catch (e) {
      debugPrint('refreshPricing failed: $e');
    } finally {
      _pricingLoading = false;
      notifyListeners();
    }
  }

  // ── Agreement actions ──────────────────────────────────────
  Future<void> deleteAgreement(int id) async {
    await _api.deleteRentalAgreement(id);
    await refreshAgreements();
  }

  Future<void> activateAgreement(int id) async {
    await _api.activateRentalAgreement(id);
    await refreshAgreements();
  }

  Future<void> completeAgreement(int id) async {
    await _api.completeRentalAgreement(id);
    await refreshAgreements();
  }

  Future<void> generateInvoiceFromAgreement(int id) async {
    await _api.createInvoiceFromAgreement(id);
  }

  // ── Payment actions ─────────────────────────────────────────
  Future<void> recordPayment(Map<String, dynamic> data) async {
    await _api.createRentalPayment(data);
    await refreshPayments();
    await refreshAgreements();
  }

  Future<void> deletePayment(int id) async {
    await _api.deleteRentalPayment(id);
    await refreshPayments();
    await refreshAgreements();
  }

  // ── Customer actions ────────────────────────────────────────
  Future<void> saveCustomer(Map<String, dynamic> data, [int? id]) async {
    if (id != null) {
      await _api.updateCustomer(id, data);
    } else {
      await _api.createCustomer(data);
    }
    await refreshCustomers();
  }

  Future<void> deleteCustomer(int id, {bool cascade = false}) async {
    await _api.deleteCustomer(id, cascade: cascade);
    await refreshCustomers();
  }

  Future<Map<String, dynamic>?> checkCustomerLinks(int id) async {
    try {
      return await _api.checkCustomerLinks(id);
    } catch (e) {
      debugPrint('checkCustomerLinks failed: $e');
      return null;
    }
  }

  // ── Pricing actions ─────────────────────────────────────────
  Future<void> savePricing(Map<String, dynamic> data, [int? id]) async {
    if (id != null) {
      await _api.updateRentalPricing(id, data);
    } else {
      await _api.createRentalPricing(data);
    }
    await refreshPricing();
  }

  Future<void> deletePricing(int id) async {
    await _api.deleteRentalPricing(id);
    await refreshPricing();
  }
}

/// Issues list provider.
// IssuesProvider moved to issues_provider.dart
