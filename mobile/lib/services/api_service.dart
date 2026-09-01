import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Centralised Dio-based HTTP client that auto-attaches JWT and tenant headers.
///
/// Mirrors the web app's `plugins/api.ts`:
///   - `Authorization: Bearer <access>`
///   - `x-tenant-schema: <schema>`
///   - On 401 → clear session and let the caller redirect to login
class ApiService {
  static ApiService? _instance;
  late final Dio dio;
  String? _accessToken;
  String? _refreshToken;
  String? _tenantSchema;
  Map<String, dynamic>? _user;

  ApiService._() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null && _accessToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        if (_tenantSchema != null && _tenantSchema!.isNotEmpty) {
          options.headers['x-tenant-schema'] = _tenantSchema;
        }
        handler.next(options);
      },
      onError: (e, handler) {
        // Auto-logout on 401
        if (e.response?.statusCode == 401) {
          clearSession();
        }
        handler.next(e);
      },
    ));
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  // ── Session management ─────────────────────────────────────

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  String? get tenantSchema => _tenantSchema;
  Map<String, dynamic>? get user => _user;

  void setSession({
    required String access,
    required String refresh,
    required String tenantSchema,
    Map<String, dynamic>? user,
  }) {
    _accessToken = access;
    _refreshToken = refresh;
    _tenantSchema = tenantSchema;
    _user = user;
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString('fc_access', _accessToken!);
    if (_refreshToken != null) await prefs.setString('fc_refresh', _refreshToken!);
    if (_tenantSchema != null) await prefs.setString('fc_tenant', _tenantSchema!);
    if (_user != null) await prefs.setString('fc_user', jsonEncode(_user!));
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('fc_access');
    _refreshToken = prefs.getString('fc_refresh');
    _tenantSchema = prefs.getString('fc_tenant');
    final userStr = prefs.getString('fc_user');
    _user = userStr != null ? jsonDecode(userStr) as Map<String, dynamic> : null;
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _tenantSchema = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fc_access');
    await prefs.remove('fc_refresh');
    await prefs.remove('fc_tenant');
    await prefs.remove('fc_user');
  }

  // ── Auth API ───────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    setSession(
      access: data['access'],
      refresh: data['refresh'],
      tenantSchema: data['tenant_schema'] ?? AppConfig.defaultTenant,
      user: data['user'] as Map<String, dynamic>?,
    );
    return data;
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await dio.get('/auth/me/');
    _user = response.data as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fc_user', jsonEncode(_user!));
    return _user!;
  }

  // ── Tenant settings ───────────────────────────────────────

  Future<Map<String, dynamic>> fetchTenantSettings() async {
    final response = await dio.get('/tenant/');
    return response.data as Map<String, dynamic>;
  }

  // ── Dashboard API ───────────────────────────────────────────

  Future<Map<String, dynamic>> fetchDashboard({String? startDate, String? endDate}) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    final response = await dio.get('/dashboard/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  // ── Vehicles API ────────────────────────────────────────────

  Future<List<dynamic>> fetchVehicles({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? fuelType,
    String? vehicleType,
    String? ownership,
    String? groupId,
    String? locationId,
    String? ordering,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (fuelType != null && fuelType.isNotEmpty) query['fuel_type'] = fuelType;
    if (vehicleType != null && vehicleType.isNotEmpty) query['vehicle_type'] = vehicleType;
    if (ownership != null && ownership.isNotEmpty) query['ownership'] = ownership;
    if (groupId != null && groupId.isNotEmpty) query['group'] = groupId;
    if (locationId != null && locationId.isNotEmpty) query['location'] = locationId;
    if (ordering != null && ordering.isNotEmpty) query['ordering'] = ordering;
    final response = await dio.get('/vehicles/vehicles/', queryParameters: query);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<int> fetchVehicleCount() async {
    try {
      final response = await dio.get('/vehicles/vehicles/', queryParameters: {'page': 1, 'page_size': 1});
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final count = data['count'];
        if (count is int) return count;
        if (count is num) return count.toInt();
      }
    } catch (_) {}
    return 0;
  }

  Future<Map<String, dynamic>> fetchVehicle(int id) async {
    final response = await dio.get('/vehicles/vehicles/$id/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    final response = await dio.post('/vehicles/vehicles/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVehicle(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/vehicles/vehicles/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteVehicle(int id) async {
    await dio.delete('/vehicles/vehicles/$id/');
  }

  Future<Map<String, dynamic>> fetchVehicleAnalytics({
    String? revStart,
    String? revEnd,
    String? dateGte,
    String? dateLte,
    String? abcStart,
    String? abcEnd,
  }) async {
    final query = <String, dynamic>{};
    if (revStart != null) query['rev_start'] = revStart;
    if (revEnd != null) query['rev_end'] = revEnd;
    if (dateGte != null) query['date__gte'] = dateGte;
    if (dateLte != null) query['date__lte'] = dateLte;
    if (abcStart != null) query['abc_start'] = abcStart;
    if (abcEnd != null) query['abc_end'] = abcEnd;
    final response = await dio.get('/vehicles/vehicles/analytics/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchVehicleProfitLoss(int id, {
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    final response = await dio.get('/vehicles/vehicles/$id/profit-loss/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchVehicleCostOfOwnership(int id, {
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['start_date'] = startDate;
    if (endDate != null) query['end_date'] = endDate;
    final response = await dio.get('/vehicles/vehicles/$id/cost-of-ownership/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vinDecode(String vin) async {
    final response = await dio.post('/vehicles/vin-decode/', data: {'vin': vin});
    return response.data as Map<String, dynamic>;
  }

  // ── Fleet Groups ────────────────────────────────────────────

  Future<List<dynamic>> fetchGroups() async {
    final response = await dio.get('/vehicles/groups/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<int> fetchGroupCount() async {
    try {
      final response = await dio.get('/vehicles/groups/', queryParameters: {'page': 1, 'page_size': 1});
      final data = response.data;
      if (data is Map<String, dynamic>) return (data['count'] as num?)?.toInt() ?? 0;
    } catch (_) {}
    return 0;
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await dio.post('/vehicles/groups/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Vehicle Types ───────────────────────────────────────────

  Future<List<dynamic>> fetchVehicleTypes() async {
    final response = await dio.get('/vehicles/vehicle-types/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createVehicleType(Map<String, dynamic> data) async {
    final response = await dio.post('/vehicles/vehicle-types/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Catalog ─────────────────────────────────────────────────

  Future<List<dynamic>> fetchMakes() async {
    final response = await dio.get('/vehicles/catalog/makes/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createMake(Map<String, dynamic> data) async {
    final response = await dio.post('/vehicles/catalog/makes/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchBodyTypes() async {
    final response = await dio.get('/vehicles/catalog/body-types/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createBodyType(Map<String, dynamic> data) async {
    final response = await dio.post('/vehicles/catalog/body-types/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchModels({String? makeId}) async {
    final query = <String, dynamic>{};
    if (makeId != null) query['make'] = makeId;
    final response = await dio.get('/vehicles/catalog/models/', queryParameters: query);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createModel(Map<String, dynamic> data) async {
    final response = await dio.post('/vehicles/catalog/models/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Locations ───────────────────────────────────────────────

  Future<List<dynamic>> fetchLocationsList() async {
    final response = await dio.get('/locations/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createLocation(Map<String, dynamic> data) async {
    final response = await dio.post('/locations/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLocation(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/locations/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteLocation(int id) async {
    await dio.delete('/locations/$id/');
  }

  Future<List<dynamic>> fetchGeofences() async {
    final response = await dio.get('/locations/geofences/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ── Telematics API ──────────────────────────────────────────

  Future<Map<String, dynamic>> fetchTelematicsAnalytics() async {
    final response = await dio.get('/telematics/analytics/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchTelematicsLiveDevices() async {
    final response = await dio.get('/telematics/devices/live/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchTelematicsDevices() async {
    final response = await dio.get('/telematics/devices/', queryParameters: {'page_size': 100});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createTelematicsDevice(Map<String, dynamic> data) async {
    final response = await dio.post('/telematics/devices/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTelematicsDevice(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/telematics/devices/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTelematicsDevice(int id) async {
    await dio.delete('/telematics/devices/$id/');
  }

  Future<List<dynamic>> fetchTelematicsTrips() async {
    final response = await dio.get('/telematics/trips/', queryParameters: {'page_size': 100});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createTelematicsTrip(Map<String, dynamic> data) async {
    final response = await dio.post('/telematics/trips/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> endTelematicsTrip(int id) async {
    await dio.post('/telematics/trips/$id/end/', data: {});
  }

  Future<List<dynamic>> fetchTelematicsAlerts() async {
    final response = await dio.get('/telematics/alerts/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<void> acknowledgeAlert(int id) async {
    await dio.post('/telematics/alerts/$id/acknowledge/', data: {});
  }

  Future<void> acknowledgeAllAlerts() async {
    await dio.post('/telematics/alerts/acknowledge-all/', data: {});
  }

  Future<List<dynamic>> fetchGeofenceEvents() async {
    final response = await dio.get('/telematics/geofence-events/', queryParameters: {'page_size': 100});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ── Dispatch API ────────────────────────────────────────────

  Future<List<dynamic>> fetchDispatchJobs() async {
    final response = await dio.get('/dispatch/jobs/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createDispatchJob(Map<String, dynamic> data) async {
    final response = await dio.post('/dispatch/jobs/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDispatchJob(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/dispatch/jobs/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDispatchJob(int id) async {
    await dio.delete('/dispatch/jobs/$id/');
  }

  Future<Map<String, dynamic>> assignDispatchJob(int id, Map<String, dynamic> data) async {
    final response = await dio.post('/dispatch/jobs/$id/assign/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startDispatchJob(int id) async {
    final response = await dio.post('/dispatch/jobs/$id/start/', data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeDispatchJob(int id) async {
    final response = await dio.post('/dispatch/jobs/$id/complete/', data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelDispatchJob(int id) async {
    final response = await dio.post('/dispatch/jobs/$id/cancel/', data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchDispatchAssignments() async {
    final response = await dio.get('/dispatch/assignments/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchStopsForJob(int jobId) async {
    final response = await dio.get('/dispatch/stops/for_job/$jobId/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createDispatchStop(Map<String, dynamic> data) async {
    final response = await dio.post('/dispatch/stops/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDispatchStop(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/dispatch/stops/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDispatchStop(int id) async {
    await dio.delete('/dispatch/stops/$id/');
  }

  // ── Accidents API ───────────────────────────────────────────

  Future<List<dynamic>> fetchAccidentReports() async {
    final response = await dio.get('/accidents/reports/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchAccidentStats() async {
    final response = await dio.get('/accidents/reports/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAccidentReport(Map<String, dynamic> data) async {
    final response = await dio.post('/accidents/reports/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAccidentReport(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/accidents/reports/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAccidentReport(int id) async {
    await dio.delete('/accidents/reports/$id/');
  }

  Future<List<dynamic>> fetchAccidentWitnesses() async {
    final response = await dio.get('/accidents/witnesses/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchInsuranceClaims() async {
    final response = await dio.get('/accidents/claims/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ── Driver Hire Rates API ───────────────────────────────────

  Future<List<dynamic>> fetchDriverHireRates() async {
    final response = await dio.get('/rentals/driver-hire-rates/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createDriverHireRate(Map<String, dynamic> data) async {
    final response = await dio.post('/rentals/driver-hire-rates/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDriverHireRate(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/rentals/driver-hire-rates/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDriverHireRate(int id) async {
    await dio.delete('/rentals/driver-hire-rates/$id/');
  }

  Future<Map<String, dynamic>> computeDriverHireRate(int id, Map<String, dynamic> data) async {
    final response = await dio.post('/rentals/driver-hire-rates/$id/compute/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Invoices API ────────────────────────────────────────────

  Future<List<dynamic>> fetchInvoices() async {
    final response = await dio.get('/rentals/invoices/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final response = await dio.post('/rentals/invoices/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateInvoice(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/rentals/invoices/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteInvoice(int id) async {
    await dio.delete('/rentals/invoices/$id/');
  }

  Future<Map<String, dynamic>> createInvoiceFromAgreement(int agreementId) async {
    final response = await dio.post('/rentals/invoices/from-agreement/', data: {'agreement_id': agreementId});
    return response.data as Map<String, dynamic>;
  }

  // ── Tires API ────────────────────────────────────────────────

  Future<List<dynamic>> fetchTires({String? search, String? status, String? brand}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (brand != null && brand.isNotEmpty) q['brand'] = brand;
    final response = await dio.get('/tires/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchTire(int id) async {
    final response = await dio.get('/tires/$id/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTire(Map<String, dynamic> data) async {
    final response = await dio.post('/tires/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTire(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/tires/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTire(int id) async {
    await dio.delete('/tires/$id/');
  }

  Future<Map<String, dynamic>> fetchTireCatalog() async {
    final response = await dio.get('/tires/catalog/');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'brands': [], 'sizes': [], 'models': []};
  }

  Future<List<dynamic>> fetchTiresNeedingReplacement() async {
    final response = await dio.get('/tires/needs-replacement/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> mountTire(int id, {required int vehicleId, required String position, String? performedAt, double? odometer, String? notes}) async {
    final body = <String, dynamic>{
      'vehicle': vehicleId,
      'position': position,
      if (performedAt != null) 'performed_at': performedAt,
      if (odometer != null) 'odometer': odometer,
      if (notes != null) 'notes': notes,
    };
    final response = await dio.post('/tires/$id/mount/', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unmountTire(int id, {String? notes}) async {
    final response = await dio.post('/tires/$id/unmount/', data: {if (notes != null) 'notes': notes});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> retireTire(int id, {String? notes}) async {
    final response = await dio.post('/tires/$id/retire/', data: {if (notes != null) 'notes': notes});
    return response.data as Map<String, dynamic>;
  }

  // -- Tire Inspections --

  Future<List<dynamic>> fetchTireInspections() async {
    final response = await dio.get('/tires/inspections/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createTireInspection(Map<String, dynamic> data) async {
    final response = await dio.post('/tires/inspections/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTireInspection(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/tires/inspections/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTireInspection(int id) async {
    await dio.delete('/tires/inspections/$id/');
  }

  // -- Tire Rotations --

  Future<List<dynamic>> fetchTireRotations() async {
    final response = await dio.get('/tires/rotations/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createTireRotation(Map<String, dynamic> data) async {
    final response = await dio.post('/tires/rotate/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTireRotation(int id) async {
    await dio.delete('/tires/rotations/$id/');
  }

  // -- Tire Movements --

  Future<List<dynamic>> fetchTireMovements() async {
    final response = await dio.get('/tires/movements/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ── Batteries API ──────────────────────────────────────────

  // ── Issues API ──────────────────────────────────────────────
  Future<List<dynamic>> fetchIssues({String? search, String? status, String? priority, int? vehicle}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (priority != null && priority.isNotEmpty) q['priority'] = priority;
    if (vehicle != null) q['vehicle'] = vehicle;
    final response = await dio.get('/issues/issues/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createIssue(Map<String, dynamic> data) async {
    final response = await dio.post('/issues/issues/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateIssue(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/issues/issues/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteIssue(int id) async {
    await dio.delete('/issues/issues/$id/');
  }

  Future<Map<String, dynamic>> fetchIssueStats() async {
    final response = await dio.get('/issues/issues/stats/');
    return response.data as Map<String, dynamic>;
  }

  // -- Work Orders --

  Future<List<dynamic>> fetchWorkOrders({String? search, String? status, String? assignmentType, int? assignedTo}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (assignmentType != null && assignmentType.isNotEmpty) q['assignment_type'] = assignmentType;
    if (assignedTo != null) q['assigned_to'] = assignedTo;
    final response = await dio.get('/issues/work-orders/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createWorkOrder(Map<String, dynamic> data) async {
    final response = await dio.post('/issues/work-orders/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateWorkOrder(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/issues/work-orders/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteWorkOrder(int id) async {
    await dio.delete('/issues/work-orders/$id/');
  }

  Future<Map<String, dynamic>> startWorkOrder(int id) async {
    final response = await dio.post('/issues/work-orders/$id/start-work/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeWorkOrder(int id) async {
    final response = await dio.post('/issues/work-orders/$id/complete/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchWorkOrderStats() async {
    final response = await dio.get('/issues/work-orders/stats/');
    return response.data as Map<String, dynamic>;
  }

  // ── Services API ────────────────────────────────────────────
  Future<List<dynamic>> fetchServices({String? search, String? serviceType, int? vehicle, int? vendor}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (serviceType != null && serviceType.isNotEmpty) q['service_type'] = serviceType;
    if (vehicle != null) q['vehicle'] = vehicle;
    if (vendor != null) q['vendor'] = vendor;
    final response = await dio.get('/services/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final response = await dio.post('/services/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateService(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/services/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteService(int id) async {
    await dio.delete('/services/$id/');
  }

  // ── Reminders API ──────────────────────────────────────────
  Future<List<dynamic>> fetchReminders({String? search, String? triggerType, bool? isActive}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (triggerType != null && triggerType.isNotEmpty) q['trigger_type'] = triggerType;
    if (isActive != null) q['is_active'] = isActive;
    final response = await dio.get('/reminders/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    final response = await dio.post('/reminders/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateReminder(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/reminders/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteReminder(int id) async {
    await dio.delete('/reminders/$id/');
  }

  Future<Map<String, dynamic>> fetchReminderStats() async {
    final response = await dio.get('/reminders/stats/');
    return response.data as Map<String, dynamic>;
  }

  // ── Inspections API ────────────────────────────────────────
  Future<List<dynamic>> fetchInspectionForms() async {
    final response = await dio.get('/inspections/forms/', queryParameters: {'page_size': 1000});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<List<dynamic>> fetchInspectionReports({String? search, String? status, int? vehicle, int? form}) async {
    final q = <String, dynamic>{'page_size': 1000};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (vehicle != null) q['vehicle'] = vehicle;
    if (form != null) q['form'] = form;
    final response = await dio.get('/inspections/reports/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createInspectionReport(Map<String, dynamic> data) async {
    final response = await dio.post('/inspections/reports/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateInspectionReport(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/inspections/reports/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteInspectionReport(int id) async {
    await dio.delete('/inspections/reports/$id/');
  }

  Future<Map<String, dynamic>> fetchInspectionStats() async {
    final response = await dio.get('/inspections/reports/stats/');
    return response.data as Map<String, dynamic>;
  }

  // ── Garage API ─────────────────────────────────────────────
  Future<List<dynamic>> fetchGarageBays({String? bayType, bool? isActive}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (bayType != null) q['bay_type'] = bayType;
    if (isActive != null) q['is_active'] = isActive;
    final response = await dio.get('/garage/bays/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createGarageBay(Map<String, dynamic> data) async {
    final response = await dio.post('/garage/bays/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGarageBay(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/garage/bays/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteGarageBay(int id) async {
    await dio.delete('/garage/bays/$id/');
  }

  Future<Map<String, dynamic>> fetchGarageBayStats() async {
    final response = await dio.get('/garage/bays/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchBayReservations({String? status, int? bay, int? vehicle}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (bay != null) q['bay'] = bay;
    if (vehicle != null) q['vehicle'] = vehicle;
    final response = await dio.get('/garage/reservations/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createBayReservation(Map<String, dynamic> data) async {
    final response = await dio.post('/garage/reservations/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBayReservation(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/garage/reservations/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBayReservation(int id) async {
    await dio.delete('/garage/reservations/$id/');
  }

  // ── Recalls API ────────────────────────────────────────────
  Future<List<dynamic>> fetchRecalls({String? search, String? status, String? recallType, bool? isCritical, String? oem}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (recallType != null && recallType.isNotEmpty) q['recall_type'] = recallType;
    if (isCritical != null) q['is_critical'] = isCritical;
    if (oem != null && oem.isNotEmpty) q['oem'] = oem;
    final response = await dio.get('/recalls/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) return data['results'] as List;
    return [];
  }

  Future<Map<String, dynamic>> createRecall(Map<String, dynamic> data) async {
    final response = await dio.post('/recalls/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRecall(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/recalls/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRecall(int id) async {
    await dio.delete('/recalls/$id/');
  }

  Future<Map<String, dynamic>> fetchRecallStats() async {
    final response = await dio.get('/recalls/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> autoMatchRecall(int id) async {
    final response = await dio.post('/recalls/$id/auto-match/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyRecallToVehicles(int id, List<int> vehicleIds) async {
    final response = await dio.post('/recalls/$id/apply-to-vehicles/', data: {'vehicle_ids': vehicleIds});
    return response.data as Map<String, dynamic>;
  }

  // ── Batteries API ──────────────────────────────────────────

  Future<List<dynamic>> fetchBatteries({String? search, String? status, String? brand, String? chemistry, String? condition}) async {
    final q = <String, dynamic>{'page_size': 500};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (brand != null && brand.isNotEmpty) q['brand'] = brand;
    if (chemistry != null && chemistry.isNotEmpty) q['chemistry'] = chemistry;
    if (condition != null && condition.isNotEmpty) q['condition'] = condition;
    final response = await dio.get('/batteries/', queryParameters: q);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchBattery(int id) async {
    final response = await dio.get('/batteries/$id/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBattery(Map<String, dynamic> data) async {
    final response = await dio.post('/batteries/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBattery(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/batteries/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBattery(int id) async {
    await dio.delete('/batteries/$id/');
  }

  Future<Map<String, dynamic>> fetchBatteryCatalog() async {
    final response = await dio.get('/batteries/catalog/');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'brands': [], 'voltage_options': [], 'capacity_options': [], 'cca_options': [], 'group_codes': [], 'position_options': [], 'chemistry_choices': [], 'condition_choices': []};
  }

  Future<Map<String, dynamic>> fetchBatteryStats() async {
    final response = await dio.get('/batteries/stats/');
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<List<dynamic>> fetchBatteriesNeedingReplacement() async {
    final response = await dio.get('/batteries/needs-replacement/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> installBattery(int id, {required int vehicleId, String? position, String? performedAt, String? notes}) async {
    final body = <String, dynamic>{
      'vehicle': vehicleId,
      'position': position ?? '',
      if (performedAt != null) 'performed_at': performedAt,
      if (notes != null) 'notes': notes,
    };
    final response = await dio.post('/batteries/$id/install/', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uninstallBattery(int id, {String? notes}) async {
    final response = await dio.post('/batteries/$id/uninstall/', data: {if (notes != null) 'notes': notes});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> chargeBattery(int id, {String? notes}) async {
    final response = await dio.post('/batteries/$id/charge/', data: {if (notes != null) 'notes': notes});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> retireBattery(int id, {String? notes}) async {
    final response = await dio.post('/batteries/$id/retire/', data: {if (notes != null) 'notes': notes});
    return response.data as Map<String, dynamic>;
  }

  // -- Battery Readings --

  Future<List<dynamic>> fetchBatteryReadings() async {
    final response = await dio.get('/batteries/readings/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createBatteryReading(Map<String, dynamic> data) async {
    final response = await dio.post('/batteries/readings/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBatteryReading(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/batteries/readings/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBatteryReading(int id) async {
    await dio.delete('/batteries/readings/$id/');
  }

  // -- Battery Movements --

  Future<List<dynamic>> fetchBatteryMovements() async {
    final response = await dio.get('/batteries/movements/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // -- Charge Cycles --

  Future<List<dynamic>> fetchChargeCycles() async {
    final response = await dio.get('/batteries/cycles/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createChargeCycle(Map<String, dynamic> data) async {
    final response = await dio.post('/batteries/cycles/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateChargeCycle(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/batteries/cycles/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteChargeCycle(int id) async {
    await dio.delete('/batteries/cycles/$id/');
  }

  // -- Battery Replacements --

  Future<List<dynamic>> fetchBatteryReplacements() async {
    final response = await dio.get('/batteries/replacements/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createBatteryReplacement(Map<String, dynamic> data) async {
    final response = await dio.post('/batteries/replacements/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBatteryReplacement(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/batteries/replacements/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBatteryReplacement(int id) async {
    await dio.delete('/batteries/replacements/$id/');
  }

  // ── Rentals / Agreements API ───────────────────────────────

  Future<List<dynamic>> fetchRentalAgreements() async {
    final response = await dio.get('/rentals/agreements/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchCustomers() async {
    final response = await dio.get('/rentals/customers/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchRentalPayments() async {
    final response = await dio.get('/rentals/payments/', queryParameters: {'page_size': 1000});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchRentalPaymentSummary() async {
    final response = await dio.get('/rentals/payments/summary/');
    return response.data as Map<String, dynamic>;
  }

  // ── Rental Pricing ─────────────────────────────────────────
  Future<List<dynamic>> fetchRentalPricing() async {
    final response = await dio.get('/rentals/pricing/', queryParameters: {'page_size': 200});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createRentalPricing(Map<String, dynamic> data) async {
    final response = await dio.post('/rentals/pricing/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRentalPricing(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/rentals/pricing/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRentalPricing(int id) async {
    await dio.delete('/rentals/pricing/$id/');
  }

  // ── Rental Customers ──────────────────────────────────────
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final response = await dio.post('/rentals/customers/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/rentals/customers/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteCustomer(int id, {bool cascade = false}) async {
    await dio.delete('/rentals/customers/$id/', queryParameters: cascade ? {'cascade': 'true'} : null);
  }

  Future<Map<String, dynamic>> checkCustomerLinks(int id) async {
    final response = await dio.get('/rentals/customers/$id/check-links/');
    return response.data as Map<String, dynamic>;
  }

  // ── Rental Agreement Actions ──────────────────────────────
  Future<void> deleteRentalAgreement(int id) async {
    await dio.delete('/rentals/agreements/$id/');
  }

  Future<Map<String, dynamic>> activateRentalAgreement(int id) async {
    final response = await dio.post('/rentals/agreements/$id/activate/', data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeRentalAgreement(int id) async {
    final response = await dio.post('/rentals/agreements/$id/complete/', data: {});
    return response.data as Map<String, dynamic>;
  }

  // ── Rental Payment CRUD ──────────────────────────────────
  Future<Map<String, dynamic>> createRentalPayment(Map<String, dynamic> data) async {
    final response = await dio.post('/rentals/payments/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRentalPayment(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/rentals/payments/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRentalPayment(int id) async {
    await dio.delete('/rentals/payments/$id/');
  }

  // ── Contacts / Drivers ─────────────────────────────────────

  Future<List<dynamic>> fetchContacts() async {
    final response = await dio.get('/contacts/', queryParameters: {'page_size': 1000});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchContactStats() async {
    final response = await dio.get('/contacts/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createContact(Map<String, dynamic> data) async {
    final response = await dio.post('/contacts/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateContact(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/contacts/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteContact(int id) async {
    await dio.delete('/contacts/$id/');
  }

  Future<void> seedContactsDemo() async {
    await dio.post('/contacts/seed_demo/', data: {});
  }

  // ── Drivers (subset of contacts) ──────────────────────────
  Future<List<dynamic>> fetchDrivers() async {
    final response = await dio.get('/contacts/drivers/', queryParameters: {'page_size': 1000});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchDriverStats() async {
    final response = await dio.get('/contacts/drivers/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> data) async {
    final response = await dio.post('/contacts/drivers/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDriver(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/contacts/drivers/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDriver(int id) async {
    await dio.delete('/contacts/drivers/$id/');
  }

  Future<void> seedDriversDemo() async {
    await dio.post('/contacts/drivers/seed_demo/', data: {});
  }

  // ══════════════════════════════════════════════════════════
  // FUEL & ENERGY API  (all prefixed /fuel/)
  // ══════════════════════════════════════════════════════════

  List<dynamic> _drToList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ── Transactions ──────────────────────────────────────────

  Future<List<dynamic>> fetchFuelTransactions({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/transactions/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> fetchFuelAnalytics({
    int days = 30,
    String? fuelType,
    int? vehicleGroup,
    String? vehicleLocation,
    String? dateGte,
    String? dateLte,
  }) async {
    final params = <String, dynamic>{'days': days};
    if (fuelType != null) params['fuel_type'] = fuelType;
    if (vehicleGroup != null) params['vehicle_group'] = vehicleGroup;
    if (vehicleLocation != null) params['vehicle_location'] = vehicleLocation;
    if (dateGte != null) params['date__gte'] = dateGte;
    if (dateLte != null) params['date__lte'] = dateLte;
    final r = await dio.get('/fuel/transactions/analytics/', queryParameters: params);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveFuelTransaction(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/fuel/transactions/$id/', data: payload);
    } else {
      r = await dio.post('/fuel/transactions/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteFuelTransaction(int id) async {
    await dio.delete('/fuel/transactions/$id/');
  }

  // ── Cards ──────────────────────────────────────────────────

  Future<List<dynamic>> fetchFuelCards({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/cards/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> saveFuelCard(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/fuel/cards/$id/', data: payload);
    } else {
      r = await dio.post('/fuel/cards/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteFuelCard(int id) async {
    await dio.delete('/fuel/cards/$id/');
  }

  Future<Map<String, dynamic>> syncFuelCard(int id) async {
    final r = await dio.post('/fuel/cards/$id/sync/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> syncAllFuelCards() async {
    final r = await dio.post('/fuel/cards/sync-all/');
    return r.data as Map<String, dynamic>;
  }

  // ── Charging Sessions ─────────────────────────────────────

  Future<List<dynamic>> fetchChargingSessions({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/charging/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> fetchChargingSummary({int days = 30}) async {
    final r = await dio.get('/fuel/charging/summary/', queryParameters: {'days': days});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveChargingSession(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/fuel/charging/$id/', data: payload);
    } else {
      r = await dio.post('/fuel/charging/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteChargingSession(int id) async {
    await dio.delete('/fuel/charging/$id/');
  }

  // ── Idling Events ─────────────────────────────────────────

  Future<List<dynamic>> fetchIdlingEvents({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/idling/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> fetchIdlingSummary({int days = 30}) async {
    final r = await dio.get('/fuel/idling/summary/', queryParameters: {'days': days});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveIdlingEvent(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/fuel/idling/$id/', data: payload);
    } else {
      r = await dio.post('/fuel/idling/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteIdlingEvent(int id) async {
    await dio.delete('/fuel/idling/$id/');
  }

  // ── Charge Schedules ──────────────────────────────────────

  Future<List<dynamic>> fetchChargeSchedules({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/charge-schedules/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> saveChargeSchedule(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/fuel/charge-schedules/$id/', data: payload);
    } else {
      r = await dio.post('/fuel/charge-schedules/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteChargeSchedule(int id) async {
    await dio.delete('/fuel/charge-schedules/$id/');
  }

  // ── Budgets ───────────────────────────────────────────────

  Future<List<dynamic>> fetchFuelBudgets({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/budgets/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> fetchFuelBudgetSummary() async {
    final r = await dio.get('/fuel/budgets/summary/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveFuelBudget(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/fuel/budgets/$id/', data: payload);
    } else {
      r = await dio.post('/fuel/budgets/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteFuelBudget(int id) async {
    await dio.delete('/fuel/budgets/$id/');
  }

  // ── Fraud Alerts ──────────────────────────────────────────

  Future<List<dynamic>> fetchFraudAlerts({Map<String, dynamic>? params}) async {
    final r = await dio.get('/fuel/fraud/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> fetchFraudSummary() async {
    final r = await dio.get('/fuel/fraud/summary/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resolveFraud(int id, {String note = ''}) async {
    final r = await dio.post('/fuel/fraud/$id/resolve/', data: {'note': note});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dismissFraud(int id, {String note = ''}) async {
    final r = await dio.post('/fuel/fraud/$id/dismiss/', data: {'note': note});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reviewFraud(int id, {String note = ''}) async {
    final r = await dio.post('/fuel/fraud/$id/review/', data: {'note': note});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reopenFraud(int id, {String note = ''}) async {
    final r = await dio.post('/fuel/fraud/$id/reopen/', data: {'note': note});
    return r.data as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════════════════
  // IFTA & FUEL TAX API  (all prefixed /ifta/)
  // ══════════════════════════════════════════════════════════

  // ── Jurisdictions ─────────────────────────────────────────

  Future<List<dynamic>> fetchJurisdictions({Map<String, dynamic>? params}) async {
    final r = await dio.get('/ifta/jurisdictions/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> saveJurisdiction(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/ifta/jurisdictions/$id/', data: payload);
    } else {
      r = await dio.post('/ifta/jurisdictions/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteJurisdiction(int id) async {
    await dio.delete('/ifta/jurisdictions/$id/');
  }

  // ── Trip Logs ─────────────────────────────────────────────

  Future<List<dynamic>> fetchTripLogs({Map<String, dynamic>? params}) async {
    final r = await dio.get('/ifta/trip-logs/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> saveTripLog(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/ifta/trip-logs/$id/', data: payload);
    } else {
      r = await dio.post('/ifta/trip-logs/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteTripLog(int id) async {
    await dio.delete('/ifta/trip-logs/$id/');
  }

  // ── Fuel Purchases ────────────────────────────────────────

  Future<List<dynamic>> fetchFuelPurchases({Map<String, dynamic>? params}) async {
    final r = await dio.get('/ifta/fuel-purchases/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> saveFuelPurchase(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/ifta/fuel-purchases/$id/', data: payload);
    } else {
      r = await dio.post('/ifta/fuel-purchases/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteFuelPurchase(int id) async {
    await dio.delete('/ifta/fuel-purchases/$id/');
  }

  // ── Quarterly Reports ─────────────────────────────────────

  Future<List<dynamic>> fetchIftaQuarters({Map<String, dynamic>? params}) async {
    final r = await dio.get('/ifta/quarters/', queryParameters: params);
    return _drToList(r.data);
  }

  Future<Map<String, dynamic>> fetchIftaStats() async {
    final r = await dio.get('/ifta/quarters/stats/');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveIftaQuarter(Map<String, dynamic> payload, {int? id}) async {
    final Response r;
    if (id != null) {
      r = await dio.patch('/ifta/quarters/$id/', data: payload);
    } else {
      r = await dio.post('/ifta/quarters/', data: payload);
    }
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteIftaQuarter(int id) async {
    await dio.delete('/ifta/quarters/$id/');
  }

  Future<Map<String, dynamic>> generateIftaQuarter(Map<String, dynamic> payload) async {
    final r = await dio.post('/ifta/quarters/generate/', data: payload);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> seedIftaDemo() async {
    final r = await dio.post('/ifta/quarters/seed-demo/');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchQuarterBreakdown(int id) async {
    final r = await dio.get('/ifta/quarters/$id/breakdown/');
    return _drToList(r.data);
  }

  // ── Services (old stub removed — see ── Services API ── section above) ──

  // ── Generic CRUD helper ────────────────────────────────────

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return dio.delete<T>(path);
  }

  // ── Reports API ────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchReportOverview({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/overview/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportRevenue({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/revenue/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportCosts({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/costs/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchReportVehicleRoi({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/vehicle-roi/', queryParameters: query);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchReportCashFlow({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/cash-flow/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportProfitLoss({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/profit-loss/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportLocations({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/locations/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportOwnership({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/financial/ownership/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchReportGeneralLedger({String? start, String? end}) async {
    final query = <String, dynamic>{};
    if (start != null) query['start'] = start;
    if (end != null) query['end'] = end;
    final response = await dio.get('/reports/general-ledger/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchStandardReport(String type, {int? days}) async {
    final query = <String, dynamic>{};
    if (days != null) query['days'] = days;
    final response = await dio.get('/reports/standard/$type/', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchReportTemplates() async {
    final response = await dio.get('/reports/templates/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchReportSchedules() async {
    final response = await dio.get('/reports/schedules/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<List<dynamic>> fetchReportExecutions() async {
    final response = await dio.get('/reports/executions/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createReportSchedule(Map<String, dynamic> data) async {
    final response = await dio.post('/reports/schedules/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateReportSchedule(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/reports/schedules/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteReportSchedule(int id) async {
    await dio.delete('/reports/schedules/$id/');
  }

  Future<Map<String, dynamic>> createReportTemplate(Map<String, dynamic> data) async {
    final response = await dio.post('/reports/templates/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> seedReportDemo() async {
    await dio.get('/reports/seed-demo/');
  }

  // ── Equipment API ───────────────────────────────────────────

  Future<List<dynamic>> fetchEquipment({
    String? search,
    String? status,
    String? category,
    bool? requiresCalibration,
  }) async {
    final query = <String, dynamic>{'page_size': 100};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (requiresCalibration != null) query['requires_calibration'] = requiresCalibration;
    final response = await dio.get('/equipment/items/', queryParameters: query);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchEquipmentItem(int id) async {
    final response = await dio.get('/equipment/items/$id/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createEquipment(Map<String, dynamic> data) async {
    final response = await dio.post('/equipment/items/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateEquipment(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/equipment/items/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteEquipment(int id) async {
    await dio.delete('/equipment/items/$id/');
  }

  Future<Map<String, dynamic>> equipmentMeterEntry(int id, {required double hours, String? notes}) async {
    final response = await dio.post('/equipment/items/$id/meter-entry/', data: {
      'hours': hours,
      if (notes != null) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> equipmentCheckOut(int id, {
    required int checkedOutTo,
    String? expectedReturnAt,
    String? notes,
  }) async {
    final response = await dio.post('/equipment/items/$id/check-out/', data: {
      'checked_out_to': checkedOutTo,
      if (expectedReturnAt != null) 'expected_return_at': expectedReturnAt,
      if (notes != null) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> equipmentCheckIn(int id) async {
    final response = await dio.post('/equipment/items/$id/check-in/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchCalibrationDue() async {
    final response = await dio.get('/equipment/items/calibration-due/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchEquipmentAnalytics() async {
    final response = await dio.get('/equipment/items/analytics/');
    return response.data as Map<String, dynamic>;
  }

  Future<void> seedDemoEquipment({bool clear = false}) async {
    await dio.post('/equipment/items/seed-demo/', data: {'clear': clear});
  }

  // ── Equipment Categories ─────────────────────────────────────

  Future<List<dynamic>> fetchEquipmentCategories() async {
    final response = await dio.get('/equipment/categories/');
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ── Equipment Checkouts (read-only) ──────────────────────────

  Future<List<dynamic>> fetchEquipmentCheckouts({
    String? search,
    String? filter, // 'active', 'overdue', 'returned'
  }) async {
    final query = <String, dynamic>{'page_size': 100};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await dio.get('/equipment/checkouts/', queryParameters: query);
    var data = response.data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      data = data['results'];
    }
    if (data is! List) return [];
    // Client-side filter for active/overdue/returned
    if (filter == null || filter.isEmpty) return data;
    return data.where((item) {
      final m = item as Map<String, dynamic>;
      final returnedAt = m['returned_at'];
      final isOverdue = m['is_overdue'] == true;
      if (filter == 'active') return returnedAt == null && !isOverdue;
      if (filter == 'overdue') return isOverdue;
      if (filter == 'returned') return returnedAt != null;
      return true;
    }).toList();
  }

  // ── Equipment Meter Entries ─────────────────────────────────

  Future<List<dynamic>> fetchEquipmentMeterEntries({String? search}) async {
    final query = <String, dynamic>{'page_size': 100};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await dio.get('/equipment/meter-entries/', queryParameters: query);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createMeterEntry(Map<String, dynamic> data) async {
    final response = await dio.post('/equipment/meter-entries/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Equipment Calibrations ───────────────────────────────────

  Future<List<dynamic>> fetchEquipmentCalibrations({String? search}) async {
    final query = <String, dynamic>{'page_size': 100};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await dio.get('/equipment/calibrations/', queryParameters: query);
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createCalibration(Map<String, dynamic> data) async {
    final response = await dio.post('/equipment/calibrations/', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Lessors API ──────────────────────────────────────────────

  /// Fetch lessors list (paginated on the backend).
  Future<List<dynamic>> fetchLessors({
    String? search,
    String? lessorType,
    bool? isActive,
    String? country,
    int pageSize = 500,
  }) async {
    final q = <String, dynamic>{'page_size': pageSize};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (lessorType != null && lessorType.isNotEmpty) q['lessor_type'] = lessorType;
    if (isActive != null) q['is_active'] = isActive;
    if (country != null && country.isNotEmpty) q['country'] = country;
    final res = await dio.get('/lessors/', queryParameters: q);
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchLessor(int id) async {
    final res = await dio.get('/lessors/$id/');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createLessor(Map<String, dynamic> data) async {
    final res = await dio.post('/lessors/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLessor(int id, Map<String, dynamic> data) async {
    final res = await dio.patch('/lessors/$id/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteLessor(int id) async {
    await dio.delete('/lessors/$id/');
  }

  Future<Map<String, dynamic>> fetchLessorSummary(int id) async {
    final res = await dio.get('/lessors/$id/summary/');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchLessorVehicles(int id) async {
    final res = await dio.get('/lessors/$id/vehicles/');
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // -- Contracts --
  Future<List<dynamic>> fetchLessorContracts({
    String? search,
    int? lessor,
    String? status,
  }) async {
    final q = <String, dynamic>{};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (lessor != null) q['lessor'] = lessor;
    if (status != null && status.isNotEmpty) q['status'] = status;
    final res = await dio.get('/lessors/contracts/', queryParameters: q);
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createLessorContract(Map<String, dynamic> data) async {
    final res = await dio.post('/lessors/contracts/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLessorContract(int id, Map<String, dynamic> data) async {
    final res = await dio.patch('/lessors/contracts/$id/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteLessorContract(int id) async {
    await dio.delete('/lessors/contracts/$id/');
  }

  Future<Map<String, dynamic>> activateLessorContract(int id) async {
    final res = await dio.post('/lessors/contracts/$id/activate/');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> terminateLessorContract(int id) async {
    final res = await dio.post('/lessors/contracts/$id/terminate/');
    return res.data as Map<String, dynamic>;
  }

  // -- Payments --
  Future<List<dynamic>> fetchLessorPayments({
    String? search,
    int? lessor,
    String? status,
  }) async {
    final q = <String, dynamic>{};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (lessor != null) q['lessor'] = lessor;
    if (status != null && status.isNotEmpty) q['status'] = status;
    final res = await dio.get('/lessors/payments/', queryParameters: q);
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createLessorPayment(Map<String, dynamic> data) async {
    final res = await dio.post('/lessors/payments/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLessorPayment(int id, Map<String, dynamic> data) async {
    final res = await dio.patch('/lessors/payments/$id/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteLessorPayment(int id) async {
    await dio.delete('/lessors/payments/$id/');
  }

  Future<Map<String, dynamic>> markLessorPaymentPaid(int id, {String? paymentMethod, String? reference}) async {
    final body = <String, dynamic>{};
    if (paymentMethod != null) body['payment_method'] = paymentMethod;
    if (reference != null) body['reference'] = reference;
    final res = await dio.post('/lessors/payments/$id/mark-paid/', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markLessorPaymentsOverdue() async {
    final res = await dio.post('/lessors/payments/mark-overdue/');
    return res.data as Map<String, dynamic>;
  }

  // -- Documents --
  Future<List<dynamic>> fetchLessorDocuments({
    String? search,
    int? lessor,
    String? documentType,
  }) async {
    final q = <String, dynamic>{};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (lessor != null) q['lessor'] = lessor;
    if (documentType != null && documentType.isNotEmpty) q['document_type'] = documentType;
    final res = await dio.get('/lessors/documents/', queryParameters: q);
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createLessorDocument(FormData data) async {
    final res = await dio.post('/lessors/documents/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLessorDocument(int id, FormData data) async {
    final res = await dio.patch('/lessors/documents/$id/', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteLessorDocument(int id) async {
    await dio.delete('/lessors/documents/$id/');
  }

  // -- Analytics & P&L --
  Future<Map<String, dynamic>> fetchLessorAnalytics({String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (startDate != null) q['start_date'] = startDate;
    if (endDate != null) q['end_date'] = endDate;
    final res = await dio.get('/lessors/analytics/', queryParameters: q);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchLessorProfitLoss({String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (startDate != null) q['start_date'] = startDate;
    if (endDate != null) q['end_date'] = endDate;
    final res = await dio.get('/lessors/profit-loss/', queryParameters: q);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchLessorLocationsAnalysis({String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (startDate != null) q['start_date'] = startDate;
    if (endDate != null) q['end_date'] = endDate;
    final res = await dio.get('/lessors/locations-analysis/', queryParameters: q);
    return res.data as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════════════════
  // DOCUMENTS API  (all prefixed /documents/)
  // ══════════════════════════════════════════════════════════

  Future<List<dynamic>> fetchDocuments() async {
    final response = await dio.get('/documents/', queryParameters: {'page_size': 1000});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchDocumentStats() async {
    final response = await dio.get('/documents/stats/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDocument(FormData formData) async {
    final response = await dio.post('/documents/', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDocument(int id, Map<String, dynamic> data) async {
    final response = await dio.patch('/documents/$id/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDocument(int id) async {
    await dio.delete('/documents/$id/');
  }

  Future<void> seedDocumentsDemo() async {
    await dio.post('/documents/seed-demo/', data: {});
  }

  // ── Vehicles & Contacts helpers for document forms ────────
  Future<List<dynamic>> fetchVehiclesList() async {
    final response = await dio.get('/vehicles/vehicles/', queryParameters: {'page_size': 1000});
    final data = response.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  // ══════════════════════════════════════════════════════════
  // EXPENSES API  (all prefixed /expenses/)
  // ══════════════════════════════════════════════════════════

  // ── Expenses ──────────────────────────────────────────────
  Future<List<dynamic>> fetchExpenses({Map<String, dynamic>? params}) async {
    final r = await dio.get('/expenses/', queryParameters: {'page_size': 1000, ...?params});
    final data = r.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchExpenseSummary({int months = 12}) async {
    final r = await dio.get('/expenses/summary/', queryParameters: {'months': months});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    final r = await dio.post('/expenses/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateExpense(int id, Map<String, dynamic> data) async {
    final r = await dio.patch('/expenses/$id/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteExpense(int id) async {
    await dio.delete('/expenses/$id/');
  }

  Future<void> seedExpensesDemo() async {
    await dio.post('/expenses/seed-demo/', data: {});
  }

  // ── Workflow actions ──────────────────────────────────────
  Future<void> submitExpense(int id) async {
    await dio.post('/expenses/$id/submit/', data: {});
  }

  Future<void> approveExpense(int id) async {
    await dio.post('/expenses/$id/approve/', data: {});
  }

  Future<void> rejectExpense(int id, String reason) async {
    await dio.post('/expenses/$id/reject/', data: {'reason': reason});
  }

  Future<void> markPaidExpense(int id, {String? paymentReference}) async {
    final data = <String, dynamic>{};
    if (paymentReference != null) data['payment_reference'] = paymentReference;
    await dio.post('/expenses/$id/mark-paid/', data: data);
  }

  // ── Attachments ───────────────────────────────────────────
  Future<void> uploadExpenseAttachment(int id, FormData formData) async {
    await dio.post('/expenses/$id/upload-attachment/', data: formData);
  }

  Future<void> deleteExpenseAttachment(int id, int attachmentId) async {
    await dio.delete('/expenses/$id/attachments/$attachmentId/');
  }

  // ── Comments ──────────────────────────────────────────────
  Future<void> addExpenseComment(int id, String body) async {
    await dio.post('/expenses/$id/add-comment/', data: {'body': body});
  }

  // ── Categories ────────────────────────────────────────────
  Future<List<dynamic>> fetchExpenseCategories() async {
    final r = await dio.get('/expenses/categories/', queryParameters: {'page_size': 1000});
    final data = r.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createExpenseCategory(Map<String, dynamic> data) async {
    final r = await dio.post('/expenses/categories/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateExpenseCategory(int id, Map<String, dynamic> data) async {
    final r = await dio.patch('/expenses/categories/$id/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteExpenseCategory(int id) async {
    await dio.delete('/expenses/categories/$id/');
  }

  // ── Recurring ──────────────────────────────────────────────
  Future<List<dynamic>> fetchExpenseRecurring() async {
    final r = await dio.get('/expenses/recurring/', queryParameters: {'page_size': 1000});
    final data = r.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> createExpenseRecurring(Map<String, dynamic> data) async {
    final r = await dio.post('/expenses/recurring/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateExpenseRecurring(int id, Map<String, dynamic> data) async {
    final r = await dio.patch('/expenses/recurring/$id/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteExpenseRecurring(int id) async {
    await dio.delete('/expenses/recurring/$id/');
  }

  Future<void> materializeExpenseRecurring() async {
    await dio.post('/expenses/recurring/materialize/', data: {});
  }

  // ── Budgets ────────────────────────────────────────────────
  Future<List<dynamic>> fetchExpenseBudgets() async {
    final r = await dio.get('/expenses/budgets/', queryParameters: {'page_size': 1000});
    final data = r.data;
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['results'] != null) {
      return data['results'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchExpenseBudgetSummary({String? month}) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    final r = await dio.get('/expenses/budgets/summary/', queryParameters: params);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createExpenseBudget(Map<String, dynamic> data) async {
    final r = await dio.post('/expenses/budgets/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteExpenseBudget(int id) async {
    await dio.delete('/expenses/budgets/$id/');
  }

  // ══════════════════════════════════════════════════════════
  // BILLING API  (all prefixed /billing/)
  // ══════════════════════════════════════════════════════════

  /// Fetch billing analytics (subscription, summary, daily_series, distributions).
  /// Pass a [preset] (today, this_week, last_week, this_month, etc.) or
  /// a custom [start]/[end] date pair in `YYYY-MM-DD` format.
  Future<Map<String, dynamic>> fetchBillingAnalytics({String? preset, String? start, String? end}) async {
    final q = <String, dynamic>{};
    if (start != null && end != null) {
      q['start'] = start;
      q['end'] = end;
    } else if (preset != null && preset.isNotEmpty) {
      q['preset'] = preset;
    }
    final r = await dio.get('/billing/analytics/', queryParameters: q);
    return r.data as Map<String, dynamic>;
  }

  /// Fetch the tenant's subscription (request_count, estimated cost, projections).
  Future<Map<String, dynamic>> fetchBillingSubscription() async {
    final r = await dio.get('/billing/subscription/');
    final data = r.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  /// Fetch exchange-rate info for the tenant's billing currency.
  /// Returns `{ currency, rate, rate_per_1000_usd }`.
  Future<Map<String, dynamic>> fetchBillingExchangeRate() async {
    final r = await dio.get('/billing/exchange-rate/');
    return r.data as Map<String, dynamic>;
  }

  /// Fetch monthly bills (invoices).  Pass [preset] or [start]/[end].
  Future<List<dynamic>> fetchBillingBills({String? preset, String? start, String? end}) async {
    final q = <String, dynamic>{'page_size': 100};
    if (start != null && end != null) {
      q['start'] = start;
      q['end'] = end;
    } else if (preset != null && preset.isNotEmpty) {
      q['preset'] = preset;
    }
    final r = await dio.get('/billing/bills/', queryParameters: q);
    return _drToList(r.data);
  }

  /// Fetch a single bill detail (includes `payments` array).
  Future<Map<String, dynamic>> fetchBillingBill(int id) async {
    final r = await dio.get('/billing/bills/$id/');
    return r.data as Map<String, dynamic>;
  }

  /// Record a payment against a bill.
  Future<Map<String, dynamic>> payBillingBill(int id, {required double amount, required String method, String? reference}) async {
    final body = <String, dynamic>{
      'amount': amount,
      'method': method,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      'currency': 'USD',
    };
    final r = await dio.post('/billing/bills/$id/pay/', data: body);
    return r.data as Map<String, dynamic>;
  }
}
