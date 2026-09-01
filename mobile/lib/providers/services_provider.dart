import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/maintenance_model.dart';

class ServicesProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<Service> _services = [];
  bool _loading = false;
  String _search = '';
  String? _typeFilter;

  List<Service> get services => _services;
  bool get loading => _loading;
  ApiService get api => _api;
  String? get typeFilter => _typeFilter;

  List<Service> get filteredServices {
    if (_search.isEmpty && _typeFilter == null) return _services;
    return _services.where((s) {
      if (_search.isNotEmpty && !s.vehicleName.toLowerCase().contains(_search) && !s.description.toLowerCase().contains(_search) && !s.vendorName.toLowerCase().contains(_search)) return false;
      if (_typeFilter != null && s.serviceType != _typeFilter) return false;
      return true;
    }).toList();
  }

  int get totalServices => _services.length;
  double get totalCost => _services.fold(0.0, (sum, s) => sum + s.cost);
  int get thisMonthCount {
    final now = DateTime.now();
    return _services.where((s) => s.performedAt != null && s.performedAt!.year == now.year && s.performedAt!.month == now.month).length;
  }
  double get thisMonthCost {
    final now = DateTime.now();
    return _services.where((s) => s.performedAt != null && s.performedAt!.year == now.year && s.performedAt!.month == now.month).fold(0.0, (sum, s) => sum + s.cost);
  }

  void setSearch(String v) { _search = v; notifyListeners(); }
  void setTypeFilter(String? v) { _typeFilter = v; notifyListeners(); }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.fetchServices();
      _services = list.map((e) => Service(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> createService(Map<String, dynamic> data) async {
    final r = await _api.createService(data);
    _services.insert(0, Service(r));
    notifyListeners();
  }

  Future<void> updateService(int id, Map<String, dynamic> data) async {
    final r = await _api.updateService(id, data);
    final idx = _services.indexWhere((e) => e.id == id);
    if (idx >= 0) _services[idx] = Service(r);
    notifyListeners();
  }

  Future<void> deleteService(int id) async {
    await _api.deleteService(id);
    _services.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
