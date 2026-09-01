import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/vehicle_model.dart';
import '../services/api_service.dart';

/// Vehicle Location Map — mirrors the web `VehicleLocationMap.vue` component.
///
/// Plots all vehicles on a Google Map using geocoded lat/lng from their
/// `location` field. Supports search, marker selection, and fit-to-bounds.
class VehicleLocationMap extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<dynamic> locations;
  final void Function(Vehicle)? onVehicleSelected;

  const VehicleLocationMap({
    super.key,
    required this.vehicles,
    this.locations = const [],
    this.onVehicleSelected,
  });

  @override
  State<VehicleLocationMap> createState() => _VehicleLocationMapState();
}

class _VehicleLocationMapState extends State<VehicleLocationMap> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Map<String, LatLng> _geocodeCache = {};
  bool _mapReady = false;
  Vehicle? _selectedVehicle;
  String _search = '';
  static const _maxGeocode = 30;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(covariant VehicleLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicles != widget.vehicles || oldWidget.locations != widget.locations) {
      _buildMarkers();
    }
  }

  // ── Geocoding via Google Maps Geocoding HTTP API ────────
  Future<LatLng?> _geocode(String address) async {
    if (address.isEmpty) return null;
    final cacheKey = 'addr:$address';
    if (_geocodeCache.containsKey(cacheKey)) {
      final cached = _geocodeCache[cacheKey]!;
      if (cached.latitude == 0 && cached.longitude == 0) return null;
      return cached;
    }

    final encoded = Uri.encodeComponent(address);
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=${AppConfig.googleMapsApiKey}';
    try {
      final response = await ApiService.instance.dio.get(url);
      // Dio returns JSON-decoded by default
      final data = response.data;
      final results = data is Map<String, dynamic>
          ? data['results'] as List?
          : <dynamic>[];
      if (results != null && results.isNotEmpty) {
        final geometry = (results[0] as Map<String, dynamic>)['geometry']
            as Map<String, dynamic>;
        final location = geometry['location'] as Map<String, dynamic>;
        final lat = (location['lat'] as num).toDouble();
        final lng = (location['lng'] as num).toDouble();
        final coords = LatLng(lat, lng);
        _geocodeCache[cacheKey] = coords;
        return coords;
      }
    } catch (_) {}
    _geocodeCache[cacheKey] = const LatLng(0, 0);
    return null;
  }

  // ── Build markers from vehicles ─────────────────────────────
  Future<void> _buildMarkers() async {
    final markers = <Marker>{};
    final locationMap = <String, Map<String, dynamic>>{};
    for (final loc in widget.locations) {
      final m = loc as Map<String, dynamic>;
      final name = m['name']?.toString();
      if (name != null) locationMap[name] = m;
    }

    int geocoded = 0;
    for (final v in widget.vehicles) {
      if (v.location.isEmpty) continue;

      LatLng? coords;
      final locData = locationMap[v.location];
      if (locData != null) {
        final lat = (locData['latitude'] as num?)?.toDouble();
        final lng = (locData['longitude'] as num?)?.toDouble();
        if (lat != null && lat != 0 && lng != null && lng != 0) {
          coords = LatLng(lat, lng);
        } else if (geocoded < _maxGeocode) {
          final addr = locData['address']?.toString() ?? v.location;
          coords = await _geocode(addr);
          geocoded++;
        }
      } else if (geocoded < _maxGeocode) {
        coords = await _geocode(v.location);
        geocoded++;
      }

      if (coords == null || (coords.latitude == 0 && coords.longitude == 0)) continue;

      markers.add(Marker(
        markerId: MarkerId('vehicle_${v.id ?? v.vin}'),
        position: coords,
        infoWindow: InfoWindow(
          title: v.displayName.isNotEmpty ? v.displayName : v.licensePlate,
          snippet: v.licensePlate.isNotEmpty
              ? 'Plate: ${v.licensePlate}'
              : 'VIN: ${v.vin}',
          onTap: () {
            setState(() => _selectedVehicle = v);
            widget.onVehicleSelected?.call(v);
          },
        ),
        onTap: () {
          setState(() => _selectedVehicle = v);
          widget.onVehicleSelected?.call(v);
        },
      ));
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });
      if (_mapReady) _fitBounds();
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty || !_mapReady) return;
    if (_markers.length == 1) {
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(
        _markers.first.position,
        13,
      ));
      return;
    }
    final bounds = _boundsFromMarkers(_markers);
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _boundsFromMarkers(Set<Marker> markers) {
    final latitudes = markers.map((m) => m.position.latitude).toList();
    final longitudes = markers.map((m) => m.position.longitude).toList();
    return LatLngBounds(
      southwest: LatLng(latitudes.reduce(min), longitudes.reduce(min)),
      northeast: LatLng(latitudes.reduce(max), longitudes.reduce(max)),
    );
  }

  void _searchVehicle() {
    if (_search.isEmpty || _markers.isEmpty) return;
    final q = _search.toLowerCase();
    Vehicle? match;
    try {
      match = widget.vehicles.firstWhere(
        (v) =>
            v.displayName.toLowerCase().contains(q) ||
            v.licensePlate.toLowerCase().contains(q) ||
            v.vin.toLowerCase().contains(q) ||
            v.location.toLowerCase().contains(q),
      );
    } catch (_) {}

    if (match != null) {
      final marker = _markers.firstWhere(
        (m) => m.markerId.value == 'vehicle_${match!.id ?? match.vin}',
        orElse: () => _markers.first,
      );
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(marker.position, 13));
      setState(() => _selectedVehicle = match);
      widget.onVehicleSelected?.call(match);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicle found'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  onSubmitted: (_) => _searchVehicle(),
                  decoration: InputDecoration(
                    hintText: 'Find vehicle on map...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _searchVehicle,
                icon: const Icon(Icons.my_location, size: 18),
                style: IconButton.styleFrom(backgroundColor: DomendraTheme.primary),
              ),
              IconButton.outlined(
                onPressed: _fitBounds,
                icon: const Icon(Icons.crop_free, size: 18),
              ),
            ],
          ),
        ),
        // Map
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                setState(() => _mapReady = true);
                _fitBounds();
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                zoom: 3,
              ),
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
              compassEnabled: true,
            ),
          ),
        ),
        // Selected vehicle info bar
        if (_selectedVehicle != null)
          _SelectedVehicleBar(
            vehicle: _selectedVehicle!,
            onClose: () => setState(() => _selectedVehicle = null),
          ),
      ],
    );
  }
}

class _SelectedVehicleBar extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onClose;

  const _SelectedVehicleBar({required this.vehicle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: DomendraTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              vehicle.isElectric ? Icons.electric_car : Icons.directions_car,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle.displayName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    if (vehicle.licensePlate.isNotEmpty) vehicle.licensePlate,
                    if (vehicle.location.isNotEmpty) vehicle.location,
                  ].join(' • '),
                  style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
