import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/maintenance_model.dart';

class RemindersProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<Reminder> _reminders = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String _search = '';
  String? _triggerFilter;
  bool? _activeOnly;

  List<Reminder> get reminders => _reminders;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  ApiService get api => _api;
  String? get triggerFilter => _triggerFilter;
  bool? get activeOnly => _activeOnly;

  List<Reminder> get filteredReminders {
    return _reminders.where((r) {
      if (_search.isNotEmpty && !r.title.toLowerCase().contains(_search) && !r.vehicleName.toLowerCase().contains(_search)) return false;
      if (_triggerFilter != null && r.triggerType != _triggerFilter) return false;
      if (_activeOnly == true && !r.isActive) return false;
      return true;
    }).toList();
  }

  int get totalReminders => _reminders.length;
  int get totalDue => _reminders.where((r) => r.isDue).length;
  int get totalOverdue => _reminders.where((r) => r.isOverdue).length;
  int get totalActive => _reminders.where((r) => r.isActive).length;

  void setSearch(String v) { _search = v; notifyListeners(); }
  void setTriggerFilter(String? v) { _triggerFilter = v; notifyListeners(); }
  void setActiveOnly(bool? v) { _activeOnly = v; notifyListeners(); }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchReminders(),
        _api.fetchReminderStats().catchError((_) => <String, dynamic>{}),
      ]);
      _reminders = (results[0] as List).map((e) => Reminder(e as Map<String, dynamic>)).toList();
      _stats = (results[1] as Map).cast<String, dynamic>();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> createReminder(Map<String, dynamic> data) async {
    final r = await _api.createReminder(data);
    _reminders.insert(0, Reminder(r));
    notifyListeners();
  }

  Future<void> updateReminder(int id, Map<String, dynamic> data) async {
    final r = await _api.updateReminder(id, data);
    final idx = _reminders.indexWhere((e) => e.id == id);
    if (idx >= 0) _reminders[idx] = Reminder(r);
    notifyListeners();
  }

  Future<void> deleteReminder(int id) async {
    await _api.deleteReminder(id);
    _reminders.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
