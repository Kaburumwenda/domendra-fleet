import 'package:flutter/foundation.dart';
import '../models/tire_model.dart';
import '../services/api_service.dart';

export '../models/tire_model.dart';

/// Tire provider — mirrors the web `pages/app/tires/index.vue`.
///
/// Manages:
///   - Tire inventory (search + filter by status/condition/brand)
///   - Inspections list
///   - Rotations list
///   - Movements list
///   - Catalog (brands, sizes, models)
///   - CRUD + mount/unmount/retire
class TireProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  ApiService get api => _api;

  // ── Tires ────────────────────────────────────────────────────
  List<Tire> _tires = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  List<String> _statusFilter = [];
  List<String> _conditionFilter = [];
  String? _brandFilter;

  // ── Inspections ─────────────────────────────────────────────
  List<TireInspection> _inspections = [];
  bool _inspectionsLoading = false;

  // ── Rotations ───────────────────────────────────────────────
  List<TireRotation> _rotations = [];
  bool _rotationsLoading = false;

  // ── Movements ───────────────────────────────────────────────
  List<TireMovement> _movements = [];
  bool _movementsLoading = false;

  // ── Catalog ─────────────────────────────────────────────────
  Map<String, dynamic> _catalog = {};
  bool _catalogLoading = false;

  // ── Vehicles (for dropdowns) ──────────────────────────────
  List<dynamic> _vehicles = [];

  // ═══ Getters ════════════════════════════════════════════════
  List<Tire> get tires => _tires;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  List<String> get statusFilter => _statusFilter;
  List<String> get conditionFilter => _conditionFilter;
  String? get brandFilter => _brandFilter;

  List<TireInspection> get inspections => _inspections;
  bool get inspectionsLoading => _inspectionsLoading;

  List<TireRotation> get rotations => _rotations;
  bool get rotationsLoading => _rotationsLoading;

  List<TireMovement> get movements => _movements;
  bool get movementsLoading => _movementsLoading;

  Map<String, dynamic> get catalog => _catalog;
  bool get catalogLoading => _catalogLoading;

  List<dynamic> get vehicles => _vehicles;
  List<String> get brandOptions => (_catalog['brands'] as List?)?.cast<String>() ?? [];
  List<String> get sizeOptions => (_catalog['sizes'] as List?)?.cast<String>() ?? [];
  List<String> get modelOptions {
    final models = _catalog['models'] as List? ?? [];
    return models.map((m) => (m as Map<String, dynamic>)['model'] as String? ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// Filtered tires (client-side).
  List<Tire> get filteredTires {
    if (_search.isEmpty && _statusFilter.isEmpty && _conditionFilter.isEmpty && _brandFilter == null) {
      return _tires;
    }
    return _tires.where((t) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hay = '${t.serialNumber} ${t.brand} ${t.model} ${t.size} ${t.vehicleName} ${t.vehicleLicensePlate}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_statusFilter.isNotEmpty) {
        final statusName = t.status.name;
        // Map enum names to backend values
        const statusMap = {
          'inStock': 'in_stock', 'mounted': 'mounted', 'spare': 'spare',
          'retired': 'retired', 'scrapped': 'scrapped',
        };
        final statusValue = statusMap[statusName] ?? statusName;
        if (!_statusFilter.contains(statusValue)) return false;
      }
      if (_conditionFilter.isNotEmpty) {
        const condMap = {
          'newTire': 'new', 'secondHand': 'second_hand', 'retreaded': 'retreaded',
          'reclaimed': 'reclaimed', 'used': 'used',
        };
        final condValue = condMap[t.condition.name] ?? t.condition.name;
        if (!_conditionFilter.contains(condValue)) return false;
      }
      if (_brandFilter != null && t.brand != _brandFilter) return false;
      return true;
    }).toList();
  }

  /// Stats computed from the tire list (mirrors web `stats` computed).
  Map<String, dynamic> get stats {
    final list = _tires;
    final brands = <String>{};
    final sizes = <String>{};
    for (final t in list) {
      if (t.brand.isNotEmpty) brands.add(t.brand);
      if (t.size.isNotEmpty) sizes.add(t.size);
    }
    int countOf(TireStatus s) => list.where((t) => t.status == s).length;
    return {
      'total': list.length,
      'mounted': countOf(TireStatus.mounted),
      'inStock': countOf(TireStatus.inStock),
      'spare': countOf(TireStatus.spare),
      'needsReplacement': list.where((t) => t.needsReplacement).length,
      'retired': countOf(TireStatus.retired) + countOf(TireStatus.scrapped),
      'brands': brands.length,
      'sizes': sizes.length,
      'inventoryValue': list.fold<double>(0, (s, t) => s + (t.purchasePrice ?? 0)),
    };
  }

  /// Tires needing replacement.
  List<Tire> get needsReplacementTires => _tires.where((t) => t.needsReplacement).toList();

  // ═══ Setters ════════════════════════════════════════════════
  void setSearch(String value) { _search = value; notifyListeners(); }
  void setStatusFilter(List<String> value) { _statusFilter = value; notifyListeners(); }
  void setConditionFilter(List<String> value) { _conditionFilter = value; notifyListeners(); }
  void setBrandFilter(String? value) { _brandFilter = value; notifyListeners(); }

  void clearFilters() {
    _statusFilter = [];
    _conditionFilter = [];
    _brandFilter = null;
    notifyListeners();
  }

  int get activeFilterCount => _statusFilter.length + _conditionFilter.length + (_brandFilter != null ? 1 : 0);

  // ═══ Fetch operations ════════════════════════════════════════
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchTires();
      _tires = raw.map((e) => Tire(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshInspections() async {
    _inspectionsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchTireInspections();
      _inspections = raw.map((e) => TireInspection(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _inspectionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRotations() async {
    _rotationsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchTireRotations();
      _rotations = raw.map((e) => TireRotation(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _rotationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMovements() async {
    _movementsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchTireMovements();
      _movements = raw.map((e) => TireMovement(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _movementsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCatalog() async {
    _catalogLoading = true;
    notifyListeners();
    try {
      _catalog = await _api.fetchTireCatalog();
    } catch (_) {
      _catalog = {'brands': [], 'sizes': [], 'models': []};
    } finally {
      _catalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshVehicles() async {
    try {
      final raw = await _api.fetchVehicles(pageSize: 500);
      _vehicles = raw;
      notifyListeners();
    } catch (_) {}
  }

  /// Initial load — fetch everything the screen needs.
  Future<void> init() async {
    await Future.wait([
      refresh(),
      refreshInspections(),
      refreshRotations(),
      refreshMovements(),
      refreshCatalog(),
      refreshVehicles(),
    ]);
  }

  // ═══ CRUD ═══════════════════════════════════════════════════

  Future<Tire?> createTire(Map<String, dynamic> data) async {
    try {
      final created = await _api.createTire(data);
      final tire = Tire(created);
      _tires.insert(0, tire);
      notifyListeners();
      return tire;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Tire?> updateTire(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateTire(id, data);
      final tire = Tire(updated);
      final idx = _tires.indexWhere((t) => t.id == id);
      if (idx >= 0) _tires[idx] = tire;
      notifyListeners();
      return tire;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteTire(int id) async {
    try {
      await _api.deleteTire(id);
      _tires.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> mountTire(int id, {required int vehicleId, required String position, String? performedAt, double? odometer, String? notes}) async {
    try {
      await _api.mountTire(id, vehicleId: vehicleId, position: position, performedAt: performedAt, odometer: odometer, notes: notes);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unmountTire(int id, {String? notes}) async {
    try {
      await _api.unmountTire(id, notes: notes);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> retireTire(int id, {String? notes}) async {
    try {
      await _api.retireTire(id, notes: notes);
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createInspection(Map<String, dynamic> data) async {
    try {
      await _api.createTireInspection(data);
      await refreshInspections();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInspection(int id) async {
    try {
      await _api.deleteTireInspection(id);
      _inspections.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createRotation(Map<String, dynamic> data) async {
    try {
      await _api.createTireRotation(data);
      await refreshRotations();
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRotation(int id) async {
    try {
      await _api.deleteTireRotation(id);
      _rotations.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
