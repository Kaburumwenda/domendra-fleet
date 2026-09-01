import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/num_cast.dart';

/// Telematics provider — drives the Telematics & GPS screen.
class TelematicsProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  Map<String, dynamic> _analytics = {};
  List<dynamic> _liveDevices = [];
  List<dynamic> _devices = [];
  List<dynamic> _trips = [];
  List<dynamic> _alerts = [];
  List<dynamic> _geofenceEvents = [];
  bool _loading = false;
  String? _error;

  Map<String, dynamic> get analytics => _analytics;
  List<dynamic> get liveDevices => _liveDevices;
  List<dynamic> get devices => _devices;
  List<dynamic> get trips => _trips;
  List<dynamic> get alerts => _alerts;
  List<dynamic> get geofenceEvents => _geofenceEvents;
  bool get loading => _loading;
  String? get error => _error;

  int get activeDevices => toIntOr(_analytics['summary']?['active_devices']);
  int get totalDevices => toIntOr(_analytics['summary']?['total_devices']);
  int get movingDevices => toIntOr(_analytics['summary']?['moving_devices']);
  int get staleDevices => toIntOr(_analytics['summary']?['stale_devices']);
  int get activeTrips => toIntOr(_analytics['summary']?['active_trips']);
  int get completedTrips => toIntOr(_analytics['summary']?['completed_trips']);
  int get unackAlerts => toIntOr(_analytics['summary']?['unack_alerts']);
  int get criticalAlerts => toIntOr(_analytics['summary']?['critical_alerts']);
  List<dynamic> get dailySeries => _analytics['daily_series'] as List? ?? [];
  List<dynamic> get alertDistribution => _analytics['alert_distribution'] as List? ?? [];

  Future<void> fetchAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchTelematicsAnalytics(),
        _api.fetchTelematicsLiveDevices(),
        _api.fetchTelematicsDevices(),
        _api.fetchTelematicsTrips(),
        _api.fetchTelematicsAlerts(),
        _api.fetchGeofenceEvents(),
      ]);
      _analytics = results[0] as Map<String, dynamic>;
      _liveDevices = results[1] as List;
      _devices = results[2] as List;
      _trips = results[3] as List;
      _alerts = results[4] as List;
      _geofenceEvents = results[5] as List;
    } catch (e) {
      _error = e.toString();
      debugPrint('Telematics fetch failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLive() async {
    try {
      _liveDevices = await _api.fetchTelematicsLiveDevices();
      notifyListeners();
    } catch (e) {
      debugPrint('Live fetch failed: $e');
    }
  }

  Future<void> createDevice(Map<String, dynamic> data) async {
    await _api.createTelematicsDevice(data);
    await fetchAll();
  }

  Future<void> updateDevice(int id, Map<String, dynamic> data) async {
    await _api.updateTelematicsDevice(id, data);
    await fetchAll();
  }

  Future<void> deleteDevice(int id) async {
    await _api.deleteTelematicsDevice(id);
    await fetchAll();
  }

  Future<void> endTrip(int id) async {
    await _api.endTelematicsTrip(id);
    await fetchAll();
  }

  Future<void> acknowledgeAlert(int id) async {
    await _api.acknowledgeAlert(id);
    await fetchTelematicsAlerts();
  }

  Future<void> acknowledgeAllAlerts() async {
    await _api.acknowledgeAllAlerts();
    await fetchAll();
  }

  Future<void> fetchTelematicsAlerts() async {
    try {
      _alerts = await _api.fetchTelematicsAlerts();
      notifyListeners();
    } catch (e) {
      debugPrint('Alerts fetch failed: $e');
    }
  }
}
