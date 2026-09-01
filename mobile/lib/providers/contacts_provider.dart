import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Contacts provider — drives the Contacts screen (All / Vendors / Staff).
class ContactsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _contacts = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String? _error;

  List<dynamic> get contacts => _contacts;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  // ── Contact type filters ───────────────────────────────────
  List<dynamic> get vendorContacts => _contacts.where((c) => (c as Map<String, dynamic>)['contact_type'] == 'vendor').toList();
  List<dynamic> get staffContacts => _contacts.where((c) {
    final t = (c as Map<String, dynamic>)['contact_type'] as String?;
    return t == 'mechanic' || t == 'manager';
  }).toList();

  // ── Stats getters ──────────────────────────────────────────
  int get total => _stats['total'] as int? ?? _contacts.length;
  int get active => _stats['active'] as int? ?? 0;
  int get inactive => _stats['inactive'] as int? ?? 0;
  int get vendorCount => _stats['vendors'] as int? ?? 0;
  int get driverCount => _stats['drivers'] as int? ?? 0;
  int get mechanicCount => _stats['mechanics'] as int? ?? 0;
  int get managerCount => _stats['managers'] as int? ?? 0;
  int get insuranceCount => _stats['insurance_agents'] as int? ?? 0;
  int get towingCount => _stats['towing_companies'] as int? ?? 0;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchContacts(),
        _api.fetchContactStats(),
      ]);
      _contacts = results[0] as List<dynamic>;
      _stats = results[1] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Map<String, dynamic> data, [int? id]) async {
    if (id != null) {
      await _api.updateContact(id, data);
    } else {
      await _api.createContact(data);
    }
    await refresh();
  }

  Future<void> delete(int id) async {
    await _api.deleteContact(id);
    await refresh();
  }

  Future<void> seedDemo() async {
    await _api.seedContactsDemo();
    await refresh();
  }
}
