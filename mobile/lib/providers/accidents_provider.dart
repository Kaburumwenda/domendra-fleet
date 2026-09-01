import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/num_cast.dart';

/// Accidents provider — drives the Accidents screen.
class AccidentsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _reports = [];
  Map<String, dynamic> _stats = {};
  List<dynamic> _witnesses = [];
  List<dynamic> _claims = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get reports => _reports;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get witnesses => _witnesses;
  List<dynamic> get claims => _claims;
  bool get loading => _loading;
  String? get error => _error;

  int get totalAccidents => toIntOr(_stats['total_accidents'], _reports.length);
  int get openAccidents => _reports.where((r) => (r as Map)['status'] == 'open' || (r as Map)['status'] == 'reported').length;
  int get resolvedAccidents => _reports.where((r) => (r as Map)['status'] == 'resolved' || (r as Map)['status'] == 'closed').length;
  double get totalDamageCost => _reports.fold<double>(0, (s, r) => s + _num((r as Map)['estimated_damage_cost']));
  int get pendingClaims => _claims.where((c) => (c as Map)['status'] == 'pending' || (c as Map)['status'] == 'submitted').length;

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> fetchAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchAccidentReports(),
        _api.fetchAccidentStats(),
        _api.fetchAccidentWitnesses(),
        _api.fetchInsuranceClaims(),
      ]);
      _reports = results[0] as List;
      _stats = results[1] as Map<String, dynamic>;
      _witnesses = results[2] as List;
      _claims = results[3] as List;
    } catch (e) {
      _error = e.toString();
      debugPrint('Accidents fetch failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createReport(Map<String, dynamic> data) async {
    await _api.createAccidentReport(data);
    await fetchAll();
  }

  Future<void> updateReport(int id, Map<String, dynamic> data) async {
    await _api.updateAccidentReport(id, data);
    await fetchAll();
  }

  Future<void> deleteReport(int id) async {
    await _api.deleteAccidentReport(id);
    await fetchAll();
  }
}
