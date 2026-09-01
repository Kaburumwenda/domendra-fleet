import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/telematics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/num_cast.dart';
import '../../widgets/app_drawer.dart';

String _currencySymbol = 'KSh';

const _providerLabels = {
  'geotab': 'Geotab',
  'samsara': 'Samsara',
  'keeptruckin': 'KeepTruckin',
  'verizon': 'Verizon Connect',
  'generic': 'Generic',
};

const _alertTypeLabels = {
  'speeding': 'Speeding',
  'idle': 'Excessive Idle',
  'harsh_braking': 'Harsh Braking',
  'harsh_acceleration': 'Harsh Acceleration',
  'geofence_violation': 'Geofence Violation',
  'device_offline': 'Device Offline',
  'low_battery': 'Low Battery',
  'odometer_tamper': 'Odometer Tamper',
  'ignition_off': 'Ignition Off',
  'low_fuel': 'Low Fuel',
};

Color _severityColor(String s) => switch (s) {
  'critical' => const Color(0xFFEF4444),
  'warning' => const Color(0xFFF59E0B),
  _ => const Color(0xFF3B82F6),
};

Color _statusColor(String s) => switch (s) {
  'active' => const Color(0xFF10B981),
  'offline' => const Color(0xFFEF4444),
  _ => const Color(0xFF94A3B8),
};

/// Telematics & GPS screen — mirrors web `/app/telematics`.
/// 6 tabs: Live Map, Devices, Trips, Alerts, Geofences, Analytics.
class TelematicsScreen extends StatefulWidget {
  const TelematicsScreen({super.key});

  @override
  State<TelematicsScreen> createState() => _TelematicsScreenState();
}

class _TelematicsScreenState extends State<TelematicsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _timer;

  static const _tabs = [
    Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Live Map'),
    Tab(icon: Icon(Icons.gps_fixed, size: 18), text: 'Devices'),
    Tab(icon: Icon(Icons.route_outlined, size: 18), text: 'Trips'),
    Tab(icon: Icon(Icons.notifications_active_outlined, size: 18), text: 'Alerts'),
    Tab(icon: Icon(Icons.shield_outlined, size: 18), text: 'Geofences'),
    Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<TelematicsProvider>().fetchAll();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _tabController.index == 0) {
        context.read<TelematicsProvider>().fetchLive();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Telematics & GPS'),
        leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<TelematicsProvider>().fetchAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
          tabAlignment: TabAlignment.start,
          labelColor: DomendraTheme.primary,
          unselectedLabelColor: DomendraTheme.onSurfaceMuted,
          indicatorColor: DomendraTheme.primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/telematics'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = context.watch<TelematicsProvider>();
    if (p.loading && p.analytics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _KpiBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LiveMapTab(),
              _DevicesTab(),
              _TripsTab(),
              _AlertsTab(),
              _GeofencesTab(),
              _AnalyticsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// KPI BAR
// ════════════════════════════════════════════════════════════
class _KpiBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: DomendraTheme.surface,
      child: Row(
        children: [
          Expanded(child: _MiniKpi(label: 'Active', value: '${p.activeDevices}', subtitle: '${p.totalDevices} total', color: const Color(0xFF10B981), icon: Icons.gps_fixed)),
          const SizedBox(width: 4),
          Expanded(child: _MiniKpi(label: 'Moving', value: '${p.movingDevices}', subtitle: '${p.staleDevices} stale', color: DomendraTheme.primary, icon: Icons.directions_car)),
          const SizedBox(width: 4),
          Expanded(child: _MiniKpi(label: 'Trips', value: '${p.activeTrips}', subtitle: '${p.completedTrips} done', color: const Color(0xFFF59E0B), icon: Icons.route)),
          const SizedBox(width: 4),
          Expanded(child: _MiniKpi(label: 'Alerts', value: '${p.unackAlerts}', subtitle: '${p.criticalAlerts} critical', color: const Color(0xFFEF4444), icon: Icons.notifications_active)),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _MiniKpi({required this.label, required this.value, required this.subtitle, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis))]),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(subtitle, style: const TextStyle(fontSize: 8, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 1: LIVE MAP (device cards)
// ════════════════════════════════════════════════════════════
class _LiveMapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    final devices = p.liveDevices;
    if (devices.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.gps_fixed, size: 56, color: DomendraTheme.onSurfaceMuted),
          const SizedBox(height: 12),
          const Text('No active devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Add and activate telematics devices to see live GPS tracking.', style: TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: devices.length,
      itemBuilder: (_, i) {
        final d = devices[i] as Map<String, dynamic>;
        final name = d['vehicle_name'] as String? ?? d['serial_number'] as String? ?? 'Unknown';
        final provider = _providerLabels[d['provider'] as String?] ?? d['provider'] ?? '';
        final isStale = d['is_stale'] as bool? ?? false;
        final speed = toDoubleOr(d['last_speed']);
        final statusLabel = isStale ? 'Stale' : (speed > 0 ? '${speed.round()} km/h' : 'Idle');
        final statusColor = isStale ? const Color(0xFFEF4444) : (speed > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B));
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.directions_car, size: 18, color: statusColor)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(provider, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor))),
            ]),
            if (d['last_reported_at'] != null) ...[
              const SizedBox(height: 6),
              Row(children: [const Icon(Icons.access_time, size: 11, color: DomendraTheme.onSurfaceMuted), const SizedBox(width: 4), Text(_fmtTimeAgo(d['last_reported_at'] as String), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))]),
            ],
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 2: DEVICES
// ════════════════════════════════════════════════════════════
class _DevicesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    final devices = p.devices;
    if (devices.isEmpty) return const Center(child: Text('No devices', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: devices.length,
      itemBuilder: (_, i) {
        final d = devices[i] as Map<String, dynamic>;
        return _DeviceCard(d: d);
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _DeviceCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final p = context.read<TelematicsProvider>();
    final serial = d['serial_number'] as String? ?? '—';
    final provider = _providerLabels[d['provider'] as String?] ?? d['provider'] ?? '—';
    final vehicleName = d['vehicle_name'] as String? ?? 'Unassigned';
    final status = d['status'] as String? ?? 'inactive';
    final isStale = d['is_stale'] as bool? ?? false;
    final speed = toDouble(d['last_speed']);
    final speedLimit = toDouble(d['speed_limit']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.gps_fixed, size: 16, color: _statusColor(status))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(serial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(vehicleName, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor(status)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Provider: $provider', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))),
          if (speed != null) Text('${speed.round()} km/h', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          if (speedLimit != null) ...[const SizedBox(width: 8), Text('Limit: ${speedLimit.round()} km/h', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))],
          const SizedBox(width: 8),
          Icon(isStale ? Icons.warning : Icons.check_circle, size: 14, color: isStale ? DomendraTheme.danger : DomendraTheme.success),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: DomendraTheme.danger), onPressed: () async => p.deleteDevice(toIntOr(d['id']))),
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 3: TRIPS
// ════════════════════════════════════════════════════════════
class _TripsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    final trips = p.trips;
    if (trips.isEmpty) return const Center(child: Text('No trips', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: trips.length,
      itemBuilder: (_, i) {
        final t = trips[i] as Map<String, dynamic>;
        return _TripCard(trip: t);
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final p = context.read<TelematicsProvider>();
    final vehicle = trip['vehicle_name'] as String? ?? 'Unknown';
    final driver = trip['driver_name'] as String? ?? '—';
    final status = trip['status'] as String? ?? 'unknown';
    final distance = toDouble(trip['distance']);
    final duration = toInt(trip['duration_minutes']);
    final startedAt = trip['started_at'] as String?;
    final statusColor = switch (status) {
      'active' => DomendraTheme.primary,
      'completed' => DomendraTheme.success,
      _ => const Color(0xFF94A3B8),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vehicle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(driver, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          if (startedAt != null) Expanded(child: Text(_fmtDateTime(startedAt), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))),
          if (distance != null) Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          if (duration != null) ...[const SizedBox(width: 8), Text('${duration}m', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))],
        ]),
        if (status == 'active') ...[
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () async => p.endTrip(toIntOr(trip['id'])), icon: const Icon(Icons.flag, size: 16), label: const Text('End Trip', style: TextStyle(fontSize: 12)))),
        ],
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 4: ALERTS
// ════════════════════════════════════════════════════════════
class _AlertsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    final alerts = p.alerts;
    if (alerts.isEmpty) return const Center(child: Text('No alerts', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return Column(
      children: [
        if (alerts.any((a) => !((a as Map)['acknowledged'] as bool? ?? false)))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(onPressed: () => p.acknowledgeAllAlerts(), icon: const Icon(Icons.done_all, size: 18), label: const Text('Acknowledge All')),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
            itemCount: alerts.length,
            itemBuilder: (_, i) {
              final a = alerts[i] as Map<String, dynamic>;
              return _AlertCard(alert: a);
            },
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final p = context.read<TelematicsProvider>();
    final type = alert['alert_type'] as String? ?? 'unknown';
    final severity = alert['severity'] as String? ?? 'info';
    final vehicle = alert['vehicle_name'] as String? ?? '—';
    final message = alert['message'] as String? ?? '';
    final acked = alert['acknowledged'] as bool? ?? false;
    final triggered = alert['triggered_at'] as String?;
    final typeLabel = _alertTypeLabels[type] ?? type;
    final sevColor = _severityColor(severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sevColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(severity, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: sevColor))),
          const SizedBox(width: 8),
          Expanded(child: Text(typeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          if (!acked) IconButton(icon: const Icon(Icons.check, size: 18, color: DomendraTheme.success), onPressed: () => p.acknowledgeAlert(toIntOr(alert['id']))),
        ]),
        const SizedBox(height: 4),
        Text(vehicle, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
        if (message.isNotEmpty) Text(message, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (triggered != null) ...[const SizedBox(height: 4), Text(_fmtDateTime(triggered), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted))],
        if (acked) ...[const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text('Acknowledged', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: DomendraTheme.success)))],
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 5: GEOFENCES
// ════════════════════════════════════════════════════════════
class _GeofencesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    final events = p.geofenceEvents;
    if (events.isEmpty) return const Center(child: Text('No geofence events', style: TextStyle(color: DomendraTheme.onSurfaceMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i] as Map<String, dynamic>;
        final type = e['event_type'] as String? ?? 'unknown';
        final vehicle = e['vehicle_name'] as String? ?? '—';
        final geofence = e['geofence_name'] as String? ?? '—';
        final triggered = e['triggered_at'] as String?;
        final isEnter = type == 'enter';
        final color = isEnter ? DomendraTheme.success : DomendraTheme.danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(isEnter ? Icons.login : Icons.logout, size: 16, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isEnter ? 'Entered: $geofence' : 'Exited: $geofence', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(vehicle, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              if (triggered != null) Text(_fmtDateTime(triggered), style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
            ])),
          ]),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// TAB 6: ANALYTICS
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<TelematicsProvider>();
    final summary = p.analytics['summary'] as Map<String, dynamic>? ?? {};
    final monthDistance = toNum(summary['month_total_distance']) ?? 0;
    final monthDuration = toNum(summary['month_total_duration']) ?? 0;
    final geoEnter = toIntOr(summary['geofence_enter']);
    final geoExit = toIntOr(summary['geofence_exit']);
    final dailySeries = p.dailySeries;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      children: [
        Row(children: [
          Expanded(child: _StatCard(label: 'km this month', value: '${monthDistance.round()}', color: DomendraTheme.primary)),
          const SizedBox(width: 4),
          Expanded(child: _StatCard(label: 'total minutes', value: '${monthDuration.round()}', color: DomendraTheme.success)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: _StatCard(label: 'geofence entries', value: '$geoEnter', color: const Color(0xFFF59E0B))),
          const SizedBox(width: 4),
          Expanded(child: _StatCard(label: 'geofence exits', value: '$geoExit', color: const Color(0xFFEF4444))),
        ]),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Daily Trips (Last 7 Days)', icon: Icons.bar_chart),
        if (dailySeries.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No data', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)))
        else
          ...dailySeries.take(7).map((d) {
            final m = d as Map<String, dynamic>;
            final date = m['date'] as String? ?? '';
            final trips = toNum(m['trips']) ?? 0;
            final distance = toDoubleOr(m['distance']);
            return _BarRow(label: date.length >= 5 ? date.substring(5) : date, value: trips.toDouble(), max: _maxDouble(dailySeries.map((e) => toNum((e as Map)['trips']) ?? 0)), color: DomendraTheme.primary, format: _fmtNumInt);
          }),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'Alert Distribution', icon: Icons.donut_small),
        ...p.alertDistribution.map((a) {
          final m = a as Map<String, dynamic>;
          final type = m['alert_type'] as String? ?? 'unknown';
          final count = toNum(m['count']) ?? 0;
          final label = _alertTypeLabels[type] ?? type;
          return _BarRow(label: label, value: count.toDouble(), max: _maxDouble(p.alertDistribution.map((e) => toNum((e as Map)['count']) ?? 0)), color: DomendraTheme.danger, format: _fmtNumInt);
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: DomendraTheme.outline)),
      child: Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)), Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center)]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [Icon(icon, size: 16, color: DomendraTheme.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))]),
  );
}

class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String Function(double) format;
  const _BarRow({required this.label, required this.value, required this.max, required this.color, required this.format});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, color: color, backgroundColor: color.withOpacity(0.1), minHeight: 8))), const SizedBox(width: 8), SizedBox(width: 40, child: Text(format(value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.end))]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

double _maxDouble(Iterable<num> vals) {
  final list = vals.toList();
  if (list.isEmpty) return 0;
  return list.map((e) => e.toDouble()).reduce((a, b) => a > b ? a : b);
}

String _fmtNumInt(double v) => v.round().toString();

String _fmtDateTime(String d) {
  try {
    final dt = DateTime.parse(d);
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) { return d; }
}

String _fmtTimeAgo(String d) {
  try {
    final diff = DateTime.now().difference(DateTime.parse(d));
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) { return d; }
}
