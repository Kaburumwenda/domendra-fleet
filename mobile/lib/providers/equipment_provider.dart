import 'package:flutter/foundation.dart';
import '../models/equipment_model.dart';
import '../services/api_service.dart';

export '../models/equipment_model.dart';

/// Equipment provider — mirrors the web `pages/app/equipment/index.vue`.
///
/// Features:
///   - Equipment list with search + client-side filtering (status, category, calibration)
///   - Checkouts (active/overdue/returned)
///   - Meter entries
///   - Calibration records
///   - Analytics (KPIs, status breakdown, category breakdown)
///   - CRUD (create, update, delete, check-out/in, meter entry, calibration)
///   - Categories list
class EquipmentProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  // ── Equipment list ──────────────────────────────────────────
  List<EquipmentItem> _items = [];
  bool _loading = false;
  String? _error;

  // ── Search & filters ────────────────────────────────────────
  String _search = '';
  String? _statusFilter;
  String? _categoryFilter;
  String? _calibrationFilter; // overdue, due_soon, ok, not_required

  // ── Checkouts ───────────────────────────────────────────────
  List<EquipmentCheckout> _checkouts = [];
  String _checkoutFilter = ''; // '', 'active', 'overdue', 'returned'

  // ── Meter entries ───────────────────────────────────────────
  List<EquipmentMeterEntry> _meterEntries = [];

  // ── Calibrations ───────────────────────────────────────────
  List<CalibrationRecord> _calibrations = [];

  // ── Analytics ──────────────────────────────────────────────
  Map<String, dynamic>? _analytics;
  bool _analyticsLoading = false;

  // ── Categories ──────────────────────────────────────────────
  List<dynamic> _categories = [];

  // ── Contacts (for checkout "check out to" dropdown) ──────
  List<dynamic> _contacts = [];

  // ── Vehicles (for assigned_vehicle dropdown) ──────────────
  List<dynamic> _vehicles = [];

  // ═══ Getters ════════════════════════════════════════════════
  List<EquipmentItem> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  String? get statusFilter => _statusFilter;
  String? get categoryFilter => _categoryFilter;
  String? get calibrationFilter => _calibrationFilter;

  List<EquipmentCheckout> get checkouts => _checkouts;
  String get checkoutFilter => _checkoutFilter;

  List<EquipmentMeterEntry> get meterEntries => _meterEntries;
  List<CalibrationRecord> get calibrations => _calibrations;

  Map<String, dynamic>? get analytics => _analytics;
  bool get analyticsLoading => _analyticsLoading;
  List<dynamic> get categories => _categories;
  List<dynamic> get contacts => _contacts;
  List<dynamic> get vehiclesList => _vehicles;

  /// Client-side filtered items.
  List<EquipmentItem> get filtered {
    if (_search.isEmpty &&
        _statusFilter == null &&
        _categoryFilter == null &&
        _calibrationFilter == null) {
      return _items;
    }

    return _items.where((item) {
      // Text search
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hay = '${item.name} ${item.assetNumber} ${item.serialNumber} ${item.barcode}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      // Status filter
      if (_statusFilter != null && item.status.api != _statusFilter) return false;
      // Category filter
      if (_categoryFilter != null && item.categoryId?.toString() != _categoryFilter) return false;
      // Calibration filter
      if (_calibrationFilter != null) {
        final cal = item.calibrationStatus;
        switch (_calibrationFilter) {
          case 'overdue':
            if (cal != CalibrationStatus.overdue) return false;
            break;
          case 'due_soon':
            if (cal != CalibrationStatus.dueSoon) return false;
            break;
          case 'ok':
            if (cal != CalibrationStatus.ok) return false;
            break;
          case 'not_required':
            if (cal != CalibrationStatus.notRequired) return false;
            break;
        }
      }
      return true;
    }).toList();
  }

  // ═══ Setters ════════════════════════════════════════════════
  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setCategoryFilter(String? value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setCalibrationFilter(String? value) {
    _calibrationFilter = value;
    notifyListeners();
  }

  void setCheckoutFilter(String value) {
    _checkoutFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _statusFilter = null;
    _categoryFilter = null;
    _calibrationFilter = null;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _search.isNotEmpty ||
      _statusFilter != null ||
      _categoryFilter != null ||
      _calibrationFilter != null;

  // ═══ Fetch operations ════════════════════════════════════════
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchEquipment();
      _items = raw.map((e) => EquipmentItem(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCheckouts() async {
    try {
      final raw = await _api.fetchEquipmentCheckouts(filter: _checkoutFilter.isEmpty ? null : _checkoutFilter);
      _checkouts = raw.map((c) => EquipmentCheckout(c as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshMeterEntries() async {
    try {
      final raw = await _api.fetchEquipmentMeterEntries();
      _meterEntries = raw.map((m) => EquipmentMeterEntry(m as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshCalibrations() async {
    try {
      final raw = await _api.fetchEquipmentCalibrations();
      _calibrations = raw.map((c) => CalibrationRecord(c as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshAnalytics() async {
    _analyticsLoading = true;
    notifyListeners();
    try {
      _analytics = await _api.fetchEquipmentAnalytics();
    } catch (_) {}
    finally {
      _analyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSupportingData() async {
    try {
      final results = await Future.wait([
        _api.fetchEquipmentCategories().catchError((_) => <dynamic>[]),
        _api.fetchContacts().catchError((_) => <dynamic>[]),
        _api.fetchVehicles().catchError((_) => <dynamic>[]),
      ]);
      _categories = results[0];
      _contacts = results[1];
      _vehicles = results[2];
      notifyListeners();
    } catch (_) {}
  }

  // ═══ CRUD ═══════════════════════════════════════════════════
  Future<bool> deleteItem(int id) async {
    try {
      await _api.deleteEquipment(id);
      _items.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<EquipmentItem?> createItem(Map<String, dynamic> data) async {
    try {
      final created = await _api.createEquipment(data);
      final item = EquipmentItem(created);
      _items.insert(0, item);
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<EquipmentItem?> updateItem(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateEquipment(id, data);
      final item = EquipmentItem(updated);
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx >= 0) _items[idx] = item;
      notifyListeners();
      return item;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> checkOut(int id, {required int checkedOutTo, String? expectedReturnAt, String? notes}) async {
    try {
      await _api.equipmentCheckOut(id, checkedOutTo: checkedOutTo, expectedReturnAt: expectedReturnAt, notes: notes);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkIn(int id) async {
    try {
      await _api.equipmentCheckIn(id);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMeterEntry(int id, {required double hours, String? notes}) async {
    try {
      await _api.equipmentMeterEntry(id, hours: hours, notes: notes);
      await refresh();
      await refreshMeterEntries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCalibration(Map<String, dynamic> data) async {
    try {
      await _api.createCalibration(data);
      await refresh();
      await refreshCalibrations();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> seedDemoData({bool clear = false}) async {
    try {
      await _api.seedDemoEquipment(clear: clear);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

/// Status options for the filter dropdown.
const List<String> equipmentStatuses = [
  'available',
  'in_use',
  'in_maintenance',
  'retired',
];
