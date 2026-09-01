import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/maintenance_model.dart';

class IssuesProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<Issue> _issues = [];
  List<WorkOrder> _workOrders = [];
  Map<String, dynamic> _issueStats = {};
  Map<String, dynamic> _woStats = {};
  bool _loading = false;
  bool _loadingWO = false;
  String _search = '';
  String? _statusFilter;
  String? _priorityFilter;

  List<Issue> get issues => _issues;
  List<WorkOrder> get workOrders => _workOrders;
  Map<String, dynamic> get issueStats => _issueStats;
  Map<String, dynamic> get woStats => _woStats;
  bool get loading => _loading;
  bool get loadingWO => _loadingWO;
  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;

  ApiService get api => _api;

  List<Issue> get filteredIssues {
    if (_search.isEmpty && _statusFilter == null && _priorityFilter == null) return _issues;
    return _issues.where((i) {
      if (_search.isNotEmpty && !i.title.toLowerCase().contains(_search) && !i.vehicleName.toLowerCase().contains(_search) && !i.description.toLowerCase().contains(_search)) return false;
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_priorityFilter != null && i.priority != _priorityFilter) return false;
      return true;
    }).toList();
  }

  int get totalOpen {
    final byStatus = _issueStats['by_status'] as Map?;
    if (byStatus != null) return byStatus['open'] as int? ?? 0;
    return _issues.where((i) => i.status == 'open').length;
  }
  int get totalInProgress {
    final byStatus = _issueStats['by_status'] as Map?;
    if (byStatus != null) return byStatus['in_progress'] as int? ?? 0;
    return _issues.where((i) => i.status == 'in_progress').length;
  }
  int get totalResolved {
    final byStatus = _issueStats['by_status'] as Map?;
    if (byStatus != null) return (byStatus['resolved'] as int? ?? 0) + (byStatus['closed'] as int? ?? 0);
    return _issues.where((i) => i.status == 'resolved' || i.status == 'closed').length;
  }
  int get totalWorkOrders => _issueStats['work_orders'] as int? ?? _workOrders.length;
  int get totalCritical => _issueStats['open_critical'] as int? ?? _issues.where((i) => i.priority == 'critical' && i.status != 'closed').length;
  int get totalIssues => _issueStats['total'] as int? ?? _issues.length;

  // Work order stats
  int get woTotal => _woStats['total'] as int? ?? _workOrders.length;
  int get woActive => _woStats['active'] as int? ?? _workOrders.where((w) => w.status == 'assigned' || w.status == 'in_progress').length;
  int get woCompleted => _woStats['completed'] as int? ?? _workOrders.where((w) => w.status == 'completed' || w.status == 'closed').length;
  double get woTotalCost => (_woStats['total_actual'] as num?)?.toDouble() ?? _workOrders.fold(0.0, (s, w) => s + w.totalCost);
  double get woTotalDowntime => (_woStats['total_downtime'] as num?)?.toDouble() ?? _workOrders.fold(0.0, (s, w) => s + w.downtimeHours);

  void setSearch(String v) { _search = v; notifyListeners(); }
  void setStatusFilter(String? v) { _statusFilter = v; notifyListeners(); }
  void setPriorityFilter(String? v) { _priorityFilter = v; notifyListeners(); }

  Future<void> init() async {
    _loading = true;
    _loadingWO = true;
    notifyListeners();
    // Fetch independently so one failure doesn't kill the other
    try {
      final list = await _api.fetchIssues();
      _issues = list.map((e) => Issue(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    try {
      final list = await _api.fetchWorkOrders();
      _workOrders = list.map((e) => WorkOrder(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    try { _issueStats = await _api.fetchIssueStats(); } catch (_) {}
    try { _woStats = await _api.fetchWorkOrderStats(); } catch (_) {}
    _loading = false;
    _loadingWO = false;
    notifyListeners();
  }

  Future<void> refreshIssues() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.fetchIssues();
      _issues = list.map((e) => Issue(e as Map<String, dynamic>)).toList();
      _issueStats = await _api.fetchIssueStats().catchError((_) => <String, dynamic>{});
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshWorkOrders() async {
    _loadingWO = true;
    notifyListeners();
    try {
      final list = await _api.fetchWorkOrders();
      _workOrders = list.map((e) => WorkOrder(e as Map<String, dynamic>)).toList();
      _woStats = await _api.fetchWorkOrderStats().catchError((_) => <String, dynamic>{});
    } catch (_) {}
    _loadingWO = false;
    notifyListeners();
  }

  Future<void> createIssue(Map<String, dynamic> data) async {
    final r = await _api.createIssue(data);
    _issues.insert(0, Issue(r));
    notifyListeners();
  }

  Future<void> updateIssue(int id, Map<String, dynamic> data) async {
    final r = await _api.updateIssue(id, data);
    final idx = _issues.indexWhere((e) => e.id == id);
    if (idx >= 0) _issues[idx] = Issue(r);
    notifyListeners();
  }

  Future<void> deleteIssue(int id) async {
    await _api.deleteIssue(id);
    _issues.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> createWorkOrder(Map<String, dynamic> data) async {
    final r = await _api.createWorkOrder(data);
    _workOrders.insert(0, WorkOrder(r));
    notifyListeners();
  }

  Future<void> updateWorkOrder(int id, Map<String, dynamic> data) async {
    final r = await _api.updateWorkOrder(id, data);
    final idx = _workOrders.indexWhere((e) => e.id == id);
    if (idx >= 0) _workOrders[idx] = WorkOrder(r);
    notifyListeners();
  }

  Future<void> deleteWorkOrder(int id) async {
    await _api.deleteWorkOrder(id);
    _workOrders.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> startWorkOrder(int id) async {
    await _api.startWorkOrder(id);
    await refreshWorkOrders();
  }

  Future<void> completeWorkOrder(int id) async {
    await _api.completeWorkOrder(id);
    await refreshWorkOrders();
  }
}
