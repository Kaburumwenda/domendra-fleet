import 'package:flutter/foundation.dart';
import '../models/lessor_model.dart';
import '../services/api_service.dart';

export '../models/lessor_model.dart';

/// Lessors provider — mirrors the web `pages/app/lessors/index.vue`.
///
/// Manages:
///   - Lessors list (search + filter by type/active)
///   - Contracts list (filter by status)
///   - Payments list (filter by status)
///   - Documents list
///   - Analytics (with date range)
///   - Profit & Loss
///   - Locations analysis
///   - CRUD for all entities
class LessorProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  // ── Lessors ──────────────────────────────────────────────────
  List<Lessor> _lessors = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  String? _typeFilter;
  bool? _activeFilter;

  // ── Contracts ───────────────────────────────────────────────
  List<LessorContract> _contracts = [];
  bool _contractsLoading = false;
  String _contractSearch = '';
  String? _contractStatusFilter;

  // ── Payments ────────────────────────────────────────────────
  List<LessorPayment> _payments = [];
  bool _paymentsLoading = false;
  String _paymentSearch = '';
  String? _paymentStatusFilter;

  // ── Documents ───────────────────────────────────────────────
  List<LessorDocument> _documents = [];
  bool _documentsLoading = false;

  // ── Analytics ───────────────────────────────────────────────
  Map<String, dynamic>? _analytics;
  bool _analyticsLoading = false;
  String? _analyticsStartDate;
  String? _analyticsEndDate;

  // ── P&L ─────────────────────────────────────────────────────
  Map<String, dynamic>? _profitLoss;
  bool _profitLossLoading = false;
  String? _pnlStartDate;
  String? _pnlEndDate;

  // ── Locations ───────────────────────────────────────────────
  Map<String, dynamic>? _locationsData;
  bool _locationsLoading = false;
  String? _locStartDate;
  String? _locEndDate;

  // ═══ Getters ════════════════════════════════════════════════
  List<Lessor> get lessors => _lessors;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  String? get typeFilter => _typeFilter;
  bool? get activeFilter => _activeFilter;

  List<LessorContract> get contracts => _contracts;
  bool get contractsLoading => _contractsLoading;
  String get contractSearch => _contractSearch;
  String? get contractStatusFilter => _contractStatusFilter;

  List<LessorPayment> get payments => _payments;
  bool get paymentsLoading => _paymentsLoading;
  String get paymentSearch => _paymentSearch;
  String? get paymentStatusFilter => _paymentStatusFilter;

  List<LessorDocument> get documents => _documents;
  bool get documentsLoading => _documentsLoading;

  Map<String, dynamic>? get analytics => _analytics;
  bool get analyticsLoading => _analyticsLoading;

  Map<String, dynamic>? get profitLoss => _profitLoss;
  bool get profitLossLoading => _profitLossLoading;

  Map<String, dynamic>? get locationsData => _locationsData;
  bool get locationsLoading => _locationsLoading;

  /// Filtered lessors (client-side text + type + active).
  List<Lessor> get filteredLessors {
    if (_search.isEmpty && _typeFilter == null && _activeFilter == null) {
      return _lessors;
    }
    return _lessors.where((l) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hay = '${l.displayName} ${l.email} ${l.phone} ${l.companyName} ${l.firstName} ${l.lastName}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_typeFilter != null) {
        if (l.lessorType.name != _typeFilter) return false;
      }
      if (_activeFilter != null) {
        if (l.isActive != _activeFilter) return false;
      }
      return true;
    }).toList();
  }

  /// Filtered contracts (client-side search + status).
  List<LessorContract> get filteredContracts {
    if (_contractSearch.isEmpty && _contractStatusFilter == null) return _contracts;
    return _contracts.where((c) {
      if (_contractSearch.isNotEmpty) {
        final q = _contractSearch.toLowerCase();
        final hay = '${c.title} ${c.contractNumber} ${c.lessorName}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_contractStatusFilter != null && c.status.name != _contractStatusFilter) return false;
      return true;
    }).toList();
  }

  /// Filtered payments (client-side search + status).
  List<LessorPayment> get filteredPayments {
    if (_paymentSearch.isEmpty && _paymentStatusFilter == null) return _payments;
    return _payments.where((p) {
      if (_paymentSearch.isNotEmpty) {
        final q = _paymentSearch.toLowerCase();
        final hay = '${p.invoiceNumber} ${p.lessorName} ${p.reference}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_paymentStatusFilter != null && p.status.name != _paymentStatusFilter) return false;
      return true;
    }).toList();
  }

  // ═══ Setters ════════════════════════════════════════════════
  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setTypeFilter(String? value) {
    _typeFilter = value;
    notifyListeners();
  }

  void setActiveFilter(bool? value) {
    _activeFilter = value;
    notifyListeners();
  }

  void setContractSearch(String value) {
    _contractSearch = value;
    notifyListeners();
  }

  void setContractStatusFilter(String? value) {
    _contractStatusFilter = value;
    notifyListeners();
  }

  void setPaymentSearch(String value) {
    _paymentSearch = value;
    notifyListeners();
  }

  void setPaymentStatusFilter(String? value) {
    _paymentStatusFilter = value;
    notifyListeners();
  }

  void setAnalyticsDateRange({String? start, String? end}) {
    _analyticsStartDate = start;
    _analyticsEndDate = end;
    notifyListeners();
  }

  void setProfitLossDateRange({String? start, String? end}) {
    _pnlStartDate = start;
    _pnlEndDate = end;
    notifyListeners();
  }

  void setLocationsDateRange({String? start, String? end}) {
    _locStartDate = start;
    _locEndDate = end;
    notifyListeners();
  }

  // ═══ Fetch operations ════════════════════════════════════════
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchLessors();
      _lessors = raw.map((e) => Lessor(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshContracts() async {
    _contractsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchLessorContracts();
      _contracts = raw.map((c) => LessorContract(c as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _contractsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPayments() async {
    _paymentsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchLessorPayments();
      _payments = raw.map((p) => LessorPayment(p as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _paymentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDocuments() async {
    _documentsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchLessorDocuments();
      _documents = raw.map((d) => LessorDocument(d as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _documentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAnalytics() async {
    _analyticsLoading = true;
    notifyListeners();
    try {
      _analytics = await _api.fetchLessorAnalytics(
        startDate: _analyticsStartDate,
        endDate: _analyticsEndDate,
      );
    } catch (_) {}
    finally {
      _analyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfitLoss() async {
    _profitLossLoading = true;
    notifyListeners();
    try {
      _profitLoss = await _api.fetchLessorProfitLoss(
        startDate: _pnlStartDate,
        endDate: _pnlEndDate,
      );
    } catch (_) {}
    finally {
      _profitLossLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocations() async {
    _locationsLoading = true;
    notifyListeners();
    try {
      _locationsData = await _api.fetchLessorLocationsAnalysis(
        startDate: _locStartDate,
        endDate: _locEndDate,
      );
    } catch (_) {}
    finally {
      _locationsLoading = false;
      notifyListeners();
    }
  }

  // ═══ CRUD ═══════════════════════════════════════════════════

  // -- Lessors --
  Future<Lessor?> createLessor(Map<String, dynamic> data) async {
    try {
      final created = await _api.createLessor(data);
      final item = Lessor(created);
      _lessors.insert(0, item);
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Lessor?> updateLessor(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateLessor(id, data);
      final item = Lessor(updated);
      final idx = _lessors.indexWhere((l) => l.id == id);
      if (idx >= 0) _lessors[idx] = item;
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteLessor(int id) async {
    try {
      await _api.deleteLessor(id);
      _lessors.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // -- Contracts --
  Future<bool> createContract(Map<String, dynamic> data) async {
    try {
      await _api.createLessorContract(data);
      await refreshContracts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContract(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateLessorContract(id, data);
      await refreshContracts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContract(int id) async {
    try {
      await _api.deleteLessorContract(id);
      _contracts.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateContract(int id) async {
    try {
      await _api.activateLessorContract(id);
      await refreshContracts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> terminateContract(int id) async {
    try {
      await _api.terminateLessorContract(id);
      await refreshContracts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // -- Payments --
  Future<bool> createPayment(Map<String, dynamic> data) async {
    try {
      await _api.createLessorPayment(data);
      await refreshPayments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePayment(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateLessorPayment(id, data);
      await refreshPayments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayment(int id) async {
    try {
      await _api.deleteLessorPayment(id);
      _payments.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markPaymentPaid(int id, {String? paymentMethod, String? reference}) async {
    try {
      await _api.markLessorPaymentPaid(id, paymentMethod: paymentMethod, reference: reference);
      await refreshPayments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> markAllOverdue() async {
    try {
      final res = await _api.markLessorPaymentsOverdue();
      final updated = (res['updated'] as num?)?.toInt() ?? 0;
      await refreshPayments();
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // -- Documents --
  Future<bool> deleteDocument(int id) async {
    try {
      await _api.deleteLessorDocument(id);
      _documents.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
