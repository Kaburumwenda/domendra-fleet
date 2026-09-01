import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Driver hire rates provider — drives the Driver Hire Rates screen.
class DriverHireRatesProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _rates = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get rates => _rates;
  bool get loading => _loading;
  String? get error => _error;

  int get totalRates => _rates.length;
  int get activeRates => _rates.where((r) => (r as Map)['is_active'] == true).length;
  int get activeCount => activeRates;

  double get avgDaily {
    if (_rates.isEmpty) return 0;
    final vals = _rates.map((r) => _num((r as Map)['daily_rate'])).toList();
    return vals.fold<double>(0, (s, v) => s + v) / vals.length;
  }

  double get avgWeekly {
    if (_rates.isEmpty) return 0;
    final vals = _rates.map((r) => _num((r as Map)['weekly_rate'])).toList();
    return vals.fold<double>(0, (s, v) => s + v) / vals.length;
  }

  static double _num(dynamic v) {
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
      _rates = await _api.fetchDriverHireRates();
    } catch (e) {
      _error = e.toString();
      debugPrint('Driver hire rates fetch failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.createDriverHireRate(data);
    await fetchAll();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.updateDriverHireRate(id, data);
    await fetchAll();
  }

  Future<void> delete(int id) async {
    await _api.deleteDriverHireRate(id);
    await fetchAll();
  }

  Future<Map<String, dynamic>?> compute(int id, Map<String, dynamic> data) async {
    try {
      return await _api.computeDriverHireRate(id, data);
    } catch (e) {
      debugPrint('Compute failed: $e');
      return null;
    }
  }
}
