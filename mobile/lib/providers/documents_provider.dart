import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import '../services/api_service.dart';

/// Documents provider — drives the Documents screen (Grid / Table / Expiring).
class DocumentsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _documents = [];
  Map<String, dynamic> _stats = {};
  List<dynamic> _vehicles = [];
  List<dynamic> _contacts = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get documents => _documents;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get vehicles => _vehicles;
  List<dynamic> get contacts => _contacts;
  bool get loading => _loading;
  String? get error => _error;

  // ── Stats getters ──────────────────────────────────────────
  int get total => _stats['total'] as int? ?? _documents.length;
  int get totalExpired => _stats['expired'] as int? ?? 0;
  int get totalExpiringSoon => _stats['expiring_soon'] as int? ?? 0;
  int get totalNoExpiry => _stats['no_expiry'] as int? ?? 0;
  int get totalSize => _stats['total_size'] as int? ?? 0;
  Map<String, dynamic> get byType =>
      (_stats['by_type'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get byVehicle => _stats['by_vehicle'] as List<dynamic>? ?? [];

  // ── Expiring soon list: expired or within 30 days ───────────
  List<dynamic> get expiringSoon {
    final now = DateTime.now();
    return _documents.where((d) {
      final m = d as Map<String, dynamic>;
      final expiryStr = m['expiry_date'] as String?;
      if (expiryStr == null) return false;
      try {
        final exp = DateTime.parse(expiryStr);
        return exp.isBefore(now.add(const Duration(days: 30)));
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        final aDays = (a as Map<String, dynamic>)['days_to_expiry'] as int? ?? 99999;
        final bDays = (b as Map<String, dynamic>)['days_to_expiry'] as int? ?? 99999;
        return aDays.compareTo(bDays);
      });
  }

  // ── File size display ──────────────────────────────────────
  String get totalSizeDisplay {
    final bytes = totalSize;
    if (bytes == 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int size = bytes;
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }
    return '$size ${units[unitIndex]}';
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchDocuments(),
        _api.fetchDocumentStats(),
        _api.fetchVehiclesList(),
        _api.fetchContacts(),
      ]);
      _documents = results[0] as List<dynamic>;
      _stats = results[1] as Map<String, dynamic>;
      _vehicles = results[2] as List<dynamic>;
      _contacts = results[3] as List<dynamic>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(dio.FormData formData) async {
    await _api.createDocument(formData);
    await refresh();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.updateDocument(id, data);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _api.deleteDocument(id);
    await refresh();
  }

  Future<void> seedDemo() async {
    await _api.seedDocumentsDemo();
    await refresh();
  }
}
