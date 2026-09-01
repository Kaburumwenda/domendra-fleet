import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Auth provider that mirrors `stores/auth.ts` from the web app.
///
/// Exposes [isAuthenticated], [user], [login] and [logout] methods.
/// Widgets rebuild when auth state changes.
class AuthProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  bool get isAuthenticated => _api.isAuthenticated;
  Map<String, dynamic>? get user => _api.user;

  String get fullName => user?['full_name'] as String? ?? user?['first_name'] as String? ?? '';
  String get role => user?['role'] as String? ?? '';
  String get email => user?['email'] as String? ?? '';
  String get initials {
    final fn = user?['first_name'] as String? ?? '';
    final ln = user?['last_name'] as String? ?? '';
    return '${fn.isNotEmpty ? fn[0] : ''}${ln.isNotEmpty ? ln[0] : ''}';
  }

  Future<void> login(String email, String password) async {
    await _api.login(email, password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearSession();
    notifyListeners();
  }

  /// Called on app startup to restore session from prefs.
  Future<void> restore() async {
    await _api.loadFromPrefs();
    notifyListeners();
  }
}
