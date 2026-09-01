import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/maintenance_model.dart';

class GarageProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<GarageBay> _bays = [];
  List<BayReservation> _reservations = [];
  Map<String, dynamic> _bayStats = {};
  bool _loading = false;
  String _search = '';

  List<GarageBay> get bays => _bays;
  List<BayReservation> get reservations => _reservations;
  Map<String, dynamic> get bayStats => _bayStats;
  bool get loading => _loading;
  ApiService get api => _api;

  List<GarageBay> get filteredBays {
    if (_search.isEmpty) return _bays;
    return _bays.where((b) => b.name.toLowerCase().contains(_search)).toList();
  }

  int get totalBays => _bays.length;
  int get occupiedBays => _bays.where((b) => b.isOccupied).length;
  int get availableBays => _bays.where((b) => !b.isOccupied && b.isActive).length;
  int get totalReservations => _reservations.length;
  int get activeReservations => _reservations.where((r) => r.status == 'active').length;

  void setSearch(String v) { _search = v; notifyListeners(); }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchGarageBays(),
        _api.fetchBayReservations(),
        _api.fetchGarageBayStats().catchError((_) => <String, dynamic>{}),
      ]);
      _bays = (results[0] as List).map((e) => GarageBay(e as Map<String, dynamic>)).toList();
      _reservations = (results[1] as List).map((e) => BayReservation(e as Map<String, dynamic>)).toList();
      _bayStats = (results[2] as Map).cast<String, dynamic>();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> createBay(Map<String, dynamic> data) async {
    final r = await _api.createGarageBay(data);
    _bays.insert(0, GarageBay(r));
    notifyListeners();
  }

  Future<void> updateBay(int id, Map<String, dynamic> data) async {
    final r = await _api.updateGarageBay(id, data);
    final idx = _bays.indexWhere((e) => e.id == id);
    if (idx >= 0) _bays[idx] = GarageBay(r);
    notifyListeners();
  }

  Future<void> deleteBay(int id) async {
    await _api.deleteGarageBay(id);
    _bays.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> createReservation(Map<String, dynamic> data) async {
    final r = await _api.createBayReservation(data);
    _reservations.insert(0, BayReservation(r));
    notifyListeners();
  }

  Future<void> updateReservation(int id, Map<String, dynamic> data) async {
    final r = await _api.updateBayReservation(id, data);
    final idx = _reservations.indexWhere((e) => e.id == id);
    if (idx >= 0) _reservations[idx] = BayReservation(r);
    notifyListeners();
  }

  Future<void> deleteReservation(int id) async {
    await _api.deleteBayReservation(id);
    _reservations.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
