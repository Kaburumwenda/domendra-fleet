import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Dispatch provider — drives the Dispatch screen (Board, List, Assignments).
class DispatchProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _jobs = [];
  List<dynamic> _assignments = [];
  List<dynamic> _stops = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get jobs => _jobs;
  List<dynamic> get assignments => _assignments;
  List<dynamic> get stops => _stops;
  bool get loading => _loading;
  String? get error => _error;

  // Status groupings for Kanban board
  List<dynamic> get pendingJobs => _jobs.where((j) => (j as Map)['status'] == 'pending').toList();
  List<dynamic> get assignedJobs => _jobs.where((j) => (j as Map)['status'] == 'assigned').toList();
  List<dynamic> get inProgressJobs => _jobs.where((j) => (j as Map)['status'] == 'in_progress').toList();
  List<dynamic> get completedJobs => _jobs.where((j) => (j as Map)['status'] == 'completed').toList();
  List<dynamic> get cancelledJobs => _jobs.where((j) => (j as Map)['status'] == 'cancelled').toList();

  int get totalJobs => _jobs.length;
  int get activeJobs => _jobs.where((j) => (j as Map)['status'] == 'in_progress').length;
  int get pendingCount => pendingJobs.length;
  int get completedCount => completedJobs.length;

  Future<void> fetchAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchDispatchJobs(),
        _api.fetchDispatchAssignments(),
      ]);
      _jobs = results[0] as List;
      _assignments = results[1] as List;
    } catch (e) {
      _error = e.toString();
      debugPrint('Dispatch fetch failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchJobs() async {
    try {
      _jobs = await _api.fetchDispatchJobs();
      notifyListeners();
    } catch (e) {
      debugPrint('Jobs fetch failed: $e');
    }
  }

  Future<void> createJob(Map<String, dynamic> data) async {
    await _api.createDispatchJob(data);
    await fetchAll();
  }

  Future<void> updateJob(int id, Map<String, dynamic> data) async {
    await _api.updateDispatchJob(id, data);
    await fetchJobs();
  }

  Future<void> deleteJob(int id) async {
    await _api.deleteDispatchJob(id);
    await fetchJobs();
  }

  Future<void> assignJob(int id, Map<String, dynamic> data) async {
    await _api.assignDispatchJob(id, data);
    await fetchJobs();
  }

  Future<void> startJob(int id) async {
    await _api.startDispatchJob(id);
    await fetchJobs();
  }

  Future<void> completeJob(int id) async {
    await _api.completeDispatchJob(id);
    await fetchJobs();
  }

  Future<void> cancelJob(int id) async {
    await _api.cancelDispatchJob(id);
    await fetchJobs();
  }

  Future<void> fetchStops(int jobId) async {
    try {
      _stops = await _api.fetchStopsForJob(jobId);
      notifyListeners();
    } catch (e) {
      debugPrint('Stops fetch failed: $e');
    }
  }
}
