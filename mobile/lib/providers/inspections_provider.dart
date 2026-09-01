import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/maintenance_model.dart';

class InspectionsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<InspectionForm> _forms = [];
  List<InspectionReport> _reports = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String _search = '';
  String? _statusFilter;

  List<InspectionForm> get forms => _forms;
  List<InspectionReport> get reports => _reports;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  ApiService get api => _api;
  String? get statusFilter => _statusFilter;

  List<InspectionReport> get filteredReports {
    return _reports.where((r) {
      if (_search.isNotEmpty && !r.vehicleName.toLowerCase().contains(_search) && !r.formName.toLowerCase().contains(_search) && !r.driverName.toLowerCase().contains(_search)) return false;
      if (_statusFilter != null && r.status != _statusFilter) return false;
      return true;
    }).toList();
  }

  int get totalReports => _reports.length;
  int get totalPass => _reports.where((r) => r.status == 'pass').length;
  int get totalFail => _reports.where((r) => r.status == 'fail').length;
  int get totalConditional => _reports.where((r) => r.status == 'conditional').length;
  int get totalDraft => _reports.where((r) => r.status == 'draft').length;
  double get passRate => totalReports > 0 ? (totalPass / totalReports * 100) : 0;

  void setSearch(String v) { _search = v; notifyListeners(); }
  void setStatusFilter(String? v) { _statusFilter = v; notifyListeners(); }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchInspectionForms(),
        _api.fetchInspectionReports(),
        _api.fetchInspectionStats().catchError((_) => <String, dynamic>{}),
      ]);
      _forms = (results[0] as List).map((e) => InspectionForm(e as Map<String, dynamic>)).toList();
      _reports = (results[1] as List).map((e) => InspectionReport(e as Map<String, dynamic>)).toList();
      _stats = (results[2] as Map).cast<String, dynamic>();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> createReport(Map<String, dynamic> data) async {
    final r = await _api.createInspectionReport(data);
    _reports.insert(0, InspectionReport(r));
    notifyListeners();
  }

  Future<void> updateReport(int id, Map<String, dynamic> data) async {
    final r = await _api.updateInspectionReport(id, data);
    final idx = _reports.indexWhere((e) => e.id == id);
    if (idx >= 0) _reports[idx] = InspectionReport(r);
    notifyListeners();
  }

  Future<void> deleteReport(int id) async {
    await _api.deleteInspectionReport(id);
    _reports.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
