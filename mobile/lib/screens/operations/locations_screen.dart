import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

/// Locations & Geofences screen — mirrors web `/app/locations`.
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});
  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final _api = ApiService.instance;
  List<dynamic> _locations = [];
  List<dynamic> _geofences = [];
  bool _loading = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_api.fetchLocationsList(), _api.fetchGeofences()]);
      _locations = results[0];
      _geofences = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _locations;
    final q = _search.toLowerCase();
    return _locations.where((l) {
      final m = l as Map<String, dynamic>;
      return (m['name'] as String? ?? '').toLowerCase().contains(q) ||
          (m['address'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Locations & Geofences'),
        leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        actions: [IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetch)],
      ),
      drawer: const AppDrawer(currentRoute: '/locations'),
      body: _loading && _locations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats bar
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  color: DomendraTheme.surface,
                  child: Row(children: [
                    Expanded(child: _StatChip(label: 'Locations', value: '${_locations.length}', color: DomendraTheme.primary, icon: Icons.location_on)),
                    const SizedBox(width: 4),
                    Expanded(child: _StatChip(label: 'Geofences', value: '${_geofences.length}', color: const Color(0xFF10B981), icon: Icons.shield)),
                  ]),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 20), hintText: 'Search locations...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No locations', style: TextStyle(color: DomendraTheme.onSurfaceMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _LocationCard(loc: _filtered[i] as Map<String, dynamic>),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _StatChip({required String label, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted))]),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Map<String, dynamic> loc;
  const _LocationCard({required this.loc});

  @override
  Widget build(BuildContext context) {
    final name = loc['name'] as String? ?? 'Unnamed';
    final address = loc['address'] as String? ?? '';
    final lat = toDouble(loc['latitude']);
    final lng = toDouble(loc['longitude']);
    final hasGeofence = loc['geofence_radius'] != null || loc['geofence_polygon'] != null;
    final isActive = loc['is_active'] as bool? ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.location_on, size: 16, color: DomendraTheme.primary)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)), if (address.isNotEmpty) Text(address, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis)])),
          if (hasGeofence) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('Geofence', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
          if (!isActive) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('Inactive', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))))],
        ]),
        if (lat != null && lng != null) ...[const SizedBox(height: 4), Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))],
      ]),
    );
  }
}
