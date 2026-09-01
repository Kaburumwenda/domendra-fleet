import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Drivers provider — drives the Drivers screen (All / Compliance / Active).
class DriversProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _drivers = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String? _error;

  List<dynamic> get drivers => _drivers;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  // ── Stats getters ──────────────────────────────────────────
  int get total => _stats['total'] as int? ?? _drivers.length;
  int get activeCount => _stats['active'] as int? ?? 0;
  int get onLeave => _stats['on_leave'] as int? ?? 0;
  int get suspended => _stats['suspended'] as int? ?? 0;
  int get terminated => _stats['terminated'] as int? ?? 0;
  int get probation => _stats['probation'] as int? ?? 0;
  int get licensesExpiring30d => _stats['licenses_expiring_30d'] as int? ?? 0;
  int get licensesExpired => _stats['licenses_expired'] as int? ?? 0;
  int get medCardsExpiring30d => _stats['med_cards_expiring_30d'] as int? ?? 0;
  int get mvrWarning => _stats['mvr_warning'] as int? ?? 0;
  int get mvrSuspended => _stats['mvr_suspended'] as int? ?? 0;

  // ── Compliance issues: drivers who have expiring/expired docs ─
  List<dynamic> get complianceIssues => _drivers.where((d) {
    final p = (d as Map<String, dynamic>)['driver_profile'] as Map<String, dynamic>?;
    if (p == null) return false;
    final licExp = p['license_expiry'] as String?;
    final medExp = p['medical_card_expiry'] as String?;
    final mvr = p['mvr_status'] as String?;
    final now = DateTime.now();
    bool isExpired(String? d) {
      if (d == null) return false;
      try { return DateTime.parse(d).isBefore(now); } catch (_) { return false; }
    }
    bool isExpiring30d(String? d) {
      if (d == null) return false;
      try {
        final exp = DateTime.parse(d);
        return exp.isAfter(now) && exp.difference(now).inDays <= 30;
      } catch (_) { return false; }
    }
    return isExpired(licExp) || isExpiring30d(licExp) ||
        isExpired(medExp) || isExpiring30d(medExp) ||
        mvr == 'warning' || mvr == 'suspended' || mvr == 'expired';
  }).toList();

  // ── Active assignments: drivers with an active vehicle ─────
  List<dynamic> get activeAssignments => _drivers.where((d) {
    final p = (d as Map<String, dynamic>)['driver_profile'] as Map<String, dynamic>?;
    if (p == null) return false;
    final assignment = p['active_assignment'] as Map<String, dynamic>?;
    return assignment != null && (assignment['is_active'] as bool? ?? false);
  }).toList();

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchDrivers(),
        _api.fetchDriverStats(),
      ]);
      _drivers = results[0] as List<dynamic>;
      _stats = results[1] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    await _api.deleteDriver(id);
    await refresh();
  }

  Future<void> seedDemo() async {
    await _api.seedDriversDemo();
    await refresh();
  }
}
