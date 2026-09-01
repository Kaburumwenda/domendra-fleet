import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';
import '../services/api_service.dart';

/// Comprehensive vehicles provider mirroring the web `VehiclesTab` / `VehicleAnalytics`.
///
/// Features:
///   - Paginated vehicle list with search + client-side filtering
///   - Fleet analytics data (KPIs, breakdowns, charts)
///   - Fleet groups, vehicle types, locations (for filters + tabs)
///   - CRUD operations (create, update, delete)
///   - VIN decode
export '../models/vehicle_model.dart';

class VehiclesProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  ApiService get api => _api;

  // ── Vehicle list ────────────────────────────────────────────
  List<Vehicle> _vehicles = [];
  bool _loading = false;
  String? _error;
  int _totalCount = 0;

  // ── Search & filters ─────────────────────────────────────────
  String _search = '';
  String? _statusFilter;
  String? _fuelFilter;
  String? _groupFilter;
  String? _locationFilter;
  String? _rentalFilter; // 'on_rent' or 'available'

  // ── Analytics ────────────────────────────────────────────────
  Map<String, dynamic>? _analytics;
  bool _analyticsLoading = false;

  // ── Supporting data ─────────────────────────────────────────
  List<dynamic> _groups = [];
  List<dynamic> _vehicleTypes = [];
  List<dynamic> _locations = [];
  List<dynamic> _makes = [];
  List<dynamic> _bodyTypes = [];
  List<dynamic> _models = [];

  // ── Getters ──────────────────────────────────────────────────
  List<Vehicle> get vehicles => _vehicles;
  bool get loading => _loading;
  String? get error => _error;
  int get totalCount => _totalCount;
  String get search => _search;
  String? get statusFilter => _statusFilter;
  String? get fuelFilter => _fuelFilter;
  String? get groupFilter => _groupFilter;
  String? get locationFilter => _locationFilter;
  String? get rentalFilter => _rentalFilter;

  Map<String, dynamic>? get analytics => _analytics;
  bool get analyticsLoading => _analyticsLoading;
  List<dynamic> get groups => _groups;
  List<dynamic> get vehicleTypes => _vehicleTypes;
  List<dynamic> get locations => _locations;
  List<dynamic> get makes => _makes;
  List<dynamic> get bodyTypes => _bodyTypes;
  List<dynamic> get models => _models;

  /// Client-side filtered list based on search + filters.
  List<Vehicle> get filtered {
    if (_search.isEmpty &&
        _statusFilter == null &&
        _fuelFilter == null &&
        _groupFilter == null &&
        _locationFilter == null &&
        _rentalFilter == null) {
      return _vehicles;
    }

    return _vehicles.where((v) {
      // Text search
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final hay = '${v.displayName} ${v.vin} ${v.licensePlate} ${v.make} ${v.model}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      // Status filter
      if (_statusFilter != null && v.status.api != _statusFilter) return false;
      // Fuel filter
      if (_fuelFilter != null && v.fuelType != _fuelFilter) return false;
      // Group filter
      if (_groupFilter != null) {
        if (v.groupId?.toString() != _groupFilter) return false;
      }
      // Location filter
      if (_locationFilter != null && v.location != _locationFilter) return false;
      // Rental filter
      if (_rentalFilter != null) {
        if (_rentalFilter == 'on_rent' && v.rentalStatus != RentalStatus.assigned) return false;
        if (_rentalFilter == 'available' && v.rentalStatus != RentalStatus.available) return false;
      }
      return true;
    }).toList();
  }

  // ── Setters ──────────────────────────────────────────────────
  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setFuelFilter(String? value) {
    _fuelFilter = value;
    notifyListeners();
  }

  void setGroupFilter(String? value) {
    _groupFilter = value;
    notifyListeners();
  }

  void setLocationFilter(String? value) {
    _locationFilter = value;
    notifyListeners();
  }

  void setRentalFilter(String? value) {
    _rentalFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _statusFilter = null;
    _fuelFilter = null;
    _groupFilter = null;
    _locationFilter = null;
    _rentalFilter = null;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _search.isNotEmpty ||
      _statusFilter != null ||
      _fuelFilter != null ||
      _groupFilter != null ||
      _locationFilter != null ||
      _rentalFilter != null;

  // ── Fetch operations ─────────────────────────────────────────

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchVehicles(pageSize: 100);
      _vehicles = raw.map((v) => Vehicle(v as Map<String, dynamic>)).toList();
      _totalCount = _vehicles.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAnalytics({
    String? revStart,
    String? revEnd,
  }) async {
    _analyticsLoading = true;
    notifyListeners();
    try {
      _analytics = await _api.fetchVehicleAnalytics(revStart: revStart, revEnd: revEnd);
    } catch (_) {
      // Non-fatal — analytics tab just shows empty state
    } finally {
      _analyticsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSupportingData() async {
    try {
      final results = await Future.wait([
        _api.fetchGroups().catchError((_) => <dynamic>[]),
        _api.fetchVehicleTypes().catchError((_) => <dynamic>[]),
        _api.fetchLocationsList().catchError((_) => <dynamic>[]),
        _api.fetchMakes().catchError((_) => <dynamic>[]),
        _api.fetchBodyTypes().catchError((_) => <dynamic>[]),
        _api.fetchModels().catchError((_) => <dynamic>[]),
      ]);
      _groups = results[0];
      _vehicleTypes = results[1];
      _locations = results[2];
      _makes = results[3];
      _bodyTypes = results[4];
      _models = results[5];
      notifyListeners();
    } catch (_) {}
  }

  // ── CRUD ────────────────────────────────────────────────────
  Future<bool> deleteVehicle(int id) async {
    try {
      await _api.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      _totalCount = _vehicles.length;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Vehicle?> createVehicle(Map<String, dynamic> data) async {
    try {
      final created = await _api.createVehicle(data);
      final v = Vehicle(created);
      _vehicles.insert(0, v);
      _totalCount = _vehicles.length;
      notifyListeners();
      return v;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Vehicle?> updateVehicleData(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _api.updateVehicle(id, data);
      final v = Vehicle(updated);
      final idx = _vehicles.indexWhere((e) => e.id == id);
      if (idx >= 0) _vehicles[idx] = v;
      notifyListeners();
      return v;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> vinDecode(String vin) async {
    try {
      return await _api.vinDecode(vin);
    } catch (_) {
      return null;
    }
  }
}

/// Fuel type options matching the web's FuelType enum (15 options).
const List<String> fuelTypes = [
  'Petrol',
  'Diesel',
  'Hybrid (Petrol)',
  'Hybrid (Diesel)',
  'Plug-in Hybrid (Petrol)',
  'Plug-in Hybrid (Diesel)',
  'Mild Hybrid',
  'Electric',
  'Fuel Cell (Hydrogen)',
  'LPG',
  'CNG',
  'LNG',
  'Ethanol (E85)',
  'Flex Fuel',
  'Biodiesel',
];

/// Status options for the filter dropdown.
const List<String> vehicleStatuses = [
  'active',
  'out_of_service',
  'in_maintenance',
  'retired',
];
