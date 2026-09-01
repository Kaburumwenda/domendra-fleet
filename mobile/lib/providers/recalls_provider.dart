import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/maintenance_model.dart';

class RecallsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<Recall> _recalls = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String _search = '';
  String? _statusFilter;
  String? _typeFilter;
  bool? _criticalOnly;

  List<Recall> get recalls => _recalls;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  ApiService get api => _api;
  String? get statusFilter => _statusFilter;
  String? get typeFilter => _typeFilter;
  bool? get criticalOnly => _criticalOnly;

  List<Recall> get filteredRecalls {
    return _recalls.where((r) {
      if (_search.isNotEmpty && !r.title.toLowerCase().contains(_search) && !r.oem.toLowerCase().contains(_search) && !r.component.toLowerCase().contains(_search)) return false;
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_typeFilter != null && r.recallType != _typeFilter) return false;
      if (_criticalOnly == true && !r.isCritical) return false;
      return true;
    }).toList();
  }

  int get totalRecalls => _recalls.length;
  int get totalOpen => _recalls.where((r) => r.status == 'open').length;
  int get totalInProgress => _recalls.where((r) => r.status == 'in_progress').length;
  int get totalCritical => _recalls.where((r) => r.isCritical).length;
  int get totalAffected => _recalls.fold(0, (sum, r) => sum + r.affectedCount);
  int get totalResolved => _recalls.fold(0, (sum, r) => sum + r.resolvedCount);

  void setSearch(String v) { _search = v; notifyListeners(); }
  void setStatusFilter(String? v) { _statusFilter = v; notifyListeners(); }
  void setTypeFilter(String? v) { _typeFilter = v; notifyListeners(); }
  void setCriticalOnly(bool? v) { _criticalOnly = v; notifyListeners(); }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchRecalls(),
        _api.fetchRecallStats().catchError((_) => <String, dynamic>{}),
      ]);
      _recalls = (results[0] as List).map((e) => Recall(e as Map<String, dynamic>)).toList();
      _stats = (results[1] as Map).cast<String, dynamic>();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> createRecall(Map<String, dynamic> data) async {
    final r = await _api.createRecall(data);
    _recalls.insert(0, Recall(r));
    notifyListeners();
  }

  Future<void> updateRecall(int id, Map<String, dynamic> data) async {
    final r = await _api.updateRecall(id, data);
    final idx = _recalls.indexWhere((e) => e.id == id);
    if (idx >= 0) _recalls[idx] = Recall(r);
    notifyListeners();
  }

  Future<void> deleteRecall(int id) async {
    await _api.deleteRecall(id);
    _recalls.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> autoMatchRecall(int id) async {
    await _api.autoMatchRecall(id);
    await init();
  }

  Future<void> applyToVehicles(int id, List<int> vehicleIds) async {
    await _api.applyRecallToVehicles(id, vehicleIds);
    await init();
  }
}
