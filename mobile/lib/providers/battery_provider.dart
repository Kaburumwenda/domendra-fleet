import 'package:flutter/foundation.dart';
import '../models/battery_model.dart';
import '../services/api_service.dart';

export '../models/battery_model.dart';

/// Battery provider — mirrors the web `pages/app/batteries/index.vue`.
///
/// Manages:
///   - Battery inventory (search + filter by status/chemistry/brand)
///   - Health readings list
///   - Movements list
///   - Charge cycles list
///   - Replacements list
///   - Catalog (brands, etc.)
///   - Stats
///   - CRUD + install/uninstall/charge/retire
class BatteryProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  ApiService get api => _api;

  // ── Batteries ────────────────────────────────────────────────
  List<Battery> _batteries = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  List<String> _statusFilter = [];
  List<String> _chemistryFilter = [];
  String? _brandFilter;

  // ── Readings ────────────────────────────────────────────────
  List<BatteryReading> _readings = [];
  bool _readingsLoading = false;

  // ── Movements ───────────────────────────────────────────────
  List<BatteryMovement> _movements = [];
  bool _movementsLoading = false;

  // ── Charge Cycles ────────────────────────────────────────────
  List<ChargeCycle> _cycles = [];
  bool _cyclesLoading = false;

  // ── Replacements ────────────────────────────────────────────
  List<BatteryReplacement> _replacements = [];
  bool _replacementsLoading = false;

  // ── Catalog ─────────────────────────────────────────────────
  Map<String, dynamic> _catalog = {};
  bool _catalogLoading = false;

  // ── Stats ────────────────────────────────────────────────────
  Map<String, dynamic> _stats = {};
  bool _statsLoading = false;

  // ── Vehicles (for dropdowns) ──────────────────────────────
  List<dynamic> _vehicles = [];

  // ═══ Getters ════════════════════════════════════════════════
  List<Battery> get batteries => _batteries;
  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;
  List<String> get statusFilter => _statusFilter;
  List<String> get chemistryFilter => _chemistryFilter;
  String? get brandFilter => _brandFilter;

  List<BatteryReading> get readings => _readings;
  bool get readingsLoading => _readingsLoading;

  List<BatteryMovement> get movements => _movements;
  bool get movementsLoading => _movementsLoading;

  List<ChargeCycle> get cycles => _cycles;
  bool get cyclesLoading => _cyclesLoading;

  List<BatteryReplacement> get replacements => _replacements;
  bool get replacementsLoading => _replacementsLoading;

  Map<String, dynamic> get catalog => _catalog;
  bool get catalogLoading => _catalogLoading;

  Map<String, dynamic> get stats => _stats;
  bool get statsLoading => _statsLoading;

  List<dynamic> get vehicles => _vehicles;
  List<String> get brandOptions => (_catalog['brands'] as List?)?.cast<String>() ?? [];
  List<int> get voltageOptions => (_catalog['voltage_options'] as List?)?.cast<int>() ?? [];
  List<int> get capacityOptions => (_catalog['capacity_options'] as List?)?.cast<int>() ?? [];
  List<int> get ccaOptions => (_catalog['cca_options'] as List?)?.cast<int>() ?? [];
  List<String> get groupCodes => (_catalog['group_codes'] as List?)?.cast<String>() ?? [];
  List<String> get positionOptions => (_catalog['position_options'] as List?)?.cast<String>() ?? [];

  /// Filtered batteries (client-side).
  List<Battery> get filteredBatteries {
    if (_search.isEmpty && _statusFilter.isEmpty && _chemistryFilter.isEmpty && _brandFilter == null) {
      return _batteries;
    }
    return _batteries.where((b) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hay = '${b.serialNumber} ${b.brand} ${b.model} ${b.partNumber} ${b.vehicleName}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_statusFilter.isNotEmpty) {
        const statusMap = {
          'inStock': 'in_stock', 'installed': 'installed', 'spare': 'spare',
          'charging': 'charging', 'retired': 'retired', 'scrapped': 'scrapped',
        };
        final statusValue = statusMap[b.status.name] ?? b.status.name;
        if (!_statusFilter.contains(statusValue)) return false;
      }
      if (_chemistryFilter.isNotEmpty) {
        const chemMap = {
          'leadAcid': 'lead_acid', 'agm': 'agm', 'gel': 'gel',
          'liIon': 'li_ion', 'lifepo4': 'lifepo4', 'nicd': 'nicd', 'nimh': 'nimh',
        };
        final chemValue = chemMap[b.chemistry.name] ?? b.chemistry.name;
        if (!_chemistryFilter.contains(chemValue)) return false;
      }
      if (_brandFilter != null && b.brand != _brandFilter) return false;
      return true;
    }).toList();
  }

  /// Batteries needing replacement.
  List<Battery> get needsReplacementBatteries => _batteries.where((b) => b.needsReplacement).toList();

  // ═══ Setters ════════════════════════════════════════════════
  void setSearch(String value) { _search = value; notifyListeners(); }
  void setStatusFilter(List<String> value) { _statusFilter = value; notifyListeners(); }
  void setChemistryFilter(List<String> value) { _chemistryFilter = value; notifyListeners(); }
  void setBrandFilter(String? value) { _brandFilter = value; notifyListeners(); }

  void clearFilters() {
    _statusFilter = [];
    _chemistryFilter = [];
    _brandFilter = null;
    notifyListeners();
  }

  int get activeFilterCount => _statusFilter.length + _chemistryFilter.length + (_brandFilter != null ? 1 : 0);

  // ═══ Fetch operations ════════════════════════════════════════
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchBatteries();
      _batteries = raw.map((e) => Battery(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStats() async {
    _statsLoading = true;
    notifyListeners();
    try {
      _stats = await _api.fetchBatteryStats();
    } catch (_) {
      _stats = {};
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReadings() async {
    _readingsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchBatteryReadings();
      _readings = raw.map((e) => BatteryReading(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _readingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMovements() async {
    _movementsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchBatteryMovements();
      _movements = raw.map((e) => BatteryMovement(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _movementsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCycles() async {
    _cyclesLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchChargeCycles();
      _cycles = raw.map((e) => ChargeCycle(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _cyclesLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReplacements() async {
    _replacementsLoading = true;
    notifyListeners();
    try {
      final raw = await _api.fetchBatteryReplacements();
      _replacements = raw.map((e) => BatteryReplacement(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    finally {
      _replacementsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCatalog() async {
    _catalogLoading = true;
    notifyListeners();
    try {
      _catalog = await _api.fetchBatteryCatalog();
    } catch (_) {
      _catalog = {'brands': [], 'voltage_options': [], 'capacity_options': [], 'cca_options': [], 'group_codes': [], 'position_options': [], 'chemistry_choices': [], 'condition_choices': []};
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
      refreshStats(),
      refreshReadings(),
      refreshMovements(),
      refreshCycles(),
      refreshReplacements(),
      refreshCatalog(),
      refreshVehicles(),
    ]);
  }

  // ═══ CRUD ═══════════════════════════════════════════════════

  Future<Battery?> createBattery(Map<String, dynamic> data) async {
    try {
      final created = await _api.createBattery(data);
      final battery = Battery(created);
      _batteries.insert(0, battery);
      notifyListeners();
      return battery;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Battery?> updateBattery(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateBattery(id, data);
      final battery = Battery(updated);
      final idx = _batteries.indexWhere((b) => b.id == id);
      if (idx >= 0) _batteries[idx] = battery;
      notifyListeners();
      return battery;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteBattery(int id) async {
    try {
      await _api.deleteBattery(id);
      _batteries.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> installBattery(int id, {required int vehicleId, String? position, String? performedAt, String? notes}) async {
    try {
      final updated = await _api.installBattery(id, vehicleId: vehicleId, position: position, performedAt: performedAt, notes: notes);
      final battery = Battery(updated);
      final idx = _batteries.indexWhere((b) => b.id == id);
      if (idx >= 0) _batteries[idx] = battery;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uninstallBattery(int id, {String? notes}) async {
    try {
      final updated = await _api.uninstallBattery(id, notes: notes);
      final battery = Battery(updated);
      final idx = _batteries.indexWhere((b) => b.id == id);
      if (idx >= 0) _batteries[idx] = battery;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> chargeBattery(int id, {String? notes}) async {
    try {
      final updated = await _api.chargeBattery(id, notes: notes);
      final battery = Battery(updated);
      final idx = _batteries.indexWhere((b) => b.id == id);
      if (idx >= 0) _batteries[idx] = battery;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> retireBattery(int id, {String? notes}) async {
    try {
      final updated = await _api.retireBattery(id, notes: notes);
      final battery = Battery(updated);
      final idx = _batteries.indexWhere((b) => b.id == id);
      if (idx >= 0) _batteries[idx] = battery;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Readings CRUD ──

  Future<void> createReading(Map<String, dynamic> data) async {
    try {
      await _api.createBatteryReading(data);
      await refreshReadings();
      await refresh();
      await refreshStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReading(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateBatteryReading(id, data);
      await refreshReadings();
      await refresh();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReading(int id) async {
    try {
      await _api.deleteBatteryReading(id);
      _readings.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Charge Cycles CRUD ──

  Future<void> createCycle(Map<String, dynamic> data) async {
    try {
      await _api.createChargeCycle(data);
      await refreshCycles();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCycle(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateChargeCycle(id, data);
      await refreshCycles();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCycle(int id) async {
    try {
      await _api.deleteChargeCycle(id);
      _cycles.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Replacements CRUD ──

  Future<void> createReplacement(Map<String, dynamic> data) async {
    try {
      await _api.createBatteryReplacement(data);
      await refreshReplacements();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReplacement(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateBatteryReplacement(id, data);
      await refreshReplacements();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReplacement(int id) async {
    try {
      await _api.deleteBatteryReplacement(id);
      _replacements.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
