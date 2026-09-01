import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/maintenance_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/garage_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'garage_dialogs.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});
  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.home_repair_service, size: 18), text: 'Bays Board'),
    Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Schedule'),
    Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Records'),
    Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GarageProvider>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Garage'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<GarageProvider>().init(),
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
      drawer: const AppDrawer(currentRoute: '/garage'),
      body: TabBarView(
        controller: _tabController,
        children: [_BaysTab(), _ScheduleTab(), _RecordsTab(), _TimelineTab()],
      ),
      floatingActionButton: Builder(builder: (context) {
        final index = _tabController.index;
        return FloatingActionButton(
          heroTag: 'fab_garage_$index',
          onPressed: () {
            if (index == 0) showGarageBayFormDialog(context, null);
            else if (index == 2) showGarageBayFormDialog(context, null);
            else if (index == 1) showBayReservationFormDialog(context, null);
            else if (index == 3) showBayReservationFormDialog(context, null);
          },
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════════
// BAYS BOARD TAB
// ════════════════════════════════════════════════════════════
class _BaysTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<GarageProvider>();
    if (p.loading && p.bays.isEmpty) return const Center(child: CircularProgressIndicator());

    final bays = p.filteredBays;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row
        Row(children: [
          Expanded(child: _KpiCard('Total Bays', '${p.totalBays}', Icons.home_repair_service, const [Color(0xFF6366f1), Color(0xFF818cf8)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Occupied', '${p.occupiedBays}', Icons.engineering, const [Color(0xFFf59e0b), Color(0xFFfbbf24)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Available', '${p.availableBays}', Icons.check_circle, const [Color(0xFF10b981), Color(0xFF34d399)])),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _KpiCard('Reservations', '${p.totalReservations}', Icons.calendar_month, const [Color(0xFF3b82f6), Color(0xFF60a5fa)])),
          const SizedBox(width: 6),
          Expanded(child: _KpiCard('Active', '${p.activeReservations}', Icons.play_arrow, const [Color(0xFF8b5cf6), Color(0xFFa78bfa)])),
        ]),
        const SizedBox(height: 16),
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: 'Search bays...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true, fillColor: DomendraTheme.surface, isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DomendraTheme.outline)),
          ),
          onChanged: p.setSearch,
        ),
        const SizedBox(height: 12),
        if (bays.isEmpty) _EmptyState(icon: Icons.home_repair_service, message: 'No bays found. Tap + to add one.')
        else ...bays.map((b) => _BayCard(bay: b)),
      ],
    );
  }
}

class _BayCard extends StatelessWidget {
  final GarageBay bay;
  const _BayCard({required this.bay});
  @override
  Widget build(BuildContext context) {
    final color = bay.isOccupied ? Colors.orange : (bay.isActive ? Colors.green : Colors.grey);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_bayTypeIcon(bay.bayType), size: 24, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bay.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text('${bay.bayTypeLabel} · Cap. ${bay.capacity}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(bay.isOccupied ? 'Occupied' : (bay.isActive ? 'Available' : 'Inactive'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color))),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (action) {
            switch (action) {
              case 'edit': showGarageBayFormDialog(context, bay); break;
              case 'delete': _confirmDeleteBay(context, bay); break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
// SCHEDULE TAB
// ════════════════════════════════════════════════════════════
class _ScheduleTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<GarageProvider>();
    if (p.loading && p.reservations.isEmpty) return const Center(child: CircularProgressIndicator());

    final now = DateTime.now();
    final upcoming = p.reservations.where((r) => r.startTime != null && r.startTime!.isAfter(now.subtract(const Duration(hours: 1)))).toList();
    final sorted = List<BayReservation>.from(upcoming)..sort((a, b) {
      final ad = a.startTime; final bd = b.startTime;
      if (ad == null && bd == null) return 0; if (ad == null) return 1; if (bd == null) return -1;
      return ad.compareTo(bd);
    });

    if (sorted.isEmpty) return _EmptyState(icon: Icons.calendar_month, message: 'No upcoming reservations. Tap + to schedule one.');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: sorted.map((r) => _ReservationCard(reservation: r)).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// RECORDS TAB
// ════════════════════════════════════════════════════════════
class _RecordsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<GarageProvider>();
    if (p.loading && p.reservations.isEmpty) return const Center(child: CircularProgressIndicator());

    final reservations = p.reservations;
    if (reservations.isEmpty) return _EmptyState(icon: Icons.list_alt, message: 'No reservations found. Tap + to create one.');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: reservations.map((r) => _ReservationCard(reservation: r)).toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TIMELINE TAB
// ════════════════════════════════════════════════════════════
class _TimelineTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<GarageProvider>();
    if (p.loading && p.reservations.isEmpty) return const Center(child: CircularProgressIndicator());

    final sorted = List<BayReservation>.from(p.reservations)..sort((a, b) {
      final ad = a.startTime; final bd = b.startTime;
      if (ad == null && bd == null) return 0; if (ad == null) return 1; if (bd == null) return -1;
      return bd.compareTo(ad);
    });

    if (sorted.isEmpty) return _EmptyState(icon: Icons.timeline, message: 'No reservations yet');

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: List.generate(sorted.length, (i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _reservationColor(sorted[i].status), shape: BoxShape.circle), child: const Icon(Icons.calendar_month, color: Colors.white, size: 14)),
          if (i < sorted.length - 1) Container(width: 2, height: 40, color: DomendraTheme.outline),
        ]),
        const SizedBox(width: 10),
        Expanded(child: _ReservationCard(reservation: sorted[i])),
      ])),
    );
  }
}

// ════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════

class _ReservationCard extends StatelessWidget {
  final BayReservation reservation;
  const _ReservationCard({required this.reservation});
  @override
  Widget build(BuildContext context) {
    final statusColor = _reservationColor(reservation.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DomendraTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DomendraTheme.outline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.calendar_month, size: 20, color: statusColor)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reservation.vehicleName.isEmpty ? 'Bay ${reservation.bayName}' : reservation.vehicleName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Bay: ${reservation.bayName}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (action) {
              switch (action) {
                case 'view': showBayReservationDetailDialog(context, reservation); break;
                case 'edit': showBayReservationFormDialog(context, reservation); break;
                case 'delete': _confirmDeleteReservation(context, reservation); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View')])),
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 4, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text(reservation.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
          if (reservation.durationHours > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)), child: Text('${reservation.durationHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted))),
        ]),
        if (reservation.startTime != null) ...[
          const SizedBox(height: 6),
          Text('Start: ${_fmtDateTime(reservation.startTime!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ],
        if (reservation.endTime != null)
          Text('End: ${_fmtDateTime(reservation.endTime!)}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<Color> colors;
  const _KpiCard(this.label, this.value, this.icon, this.colors);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 4), Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted), const SizedBox(height: 12), Text(message, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13))]),
  ));
}

void _confirmDeleteBay(BuildContext context, GarageBay b) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Bay'),
    content: Text('Delete bay "${b.name}"?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<GarageProvider>().deleteBay(b.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

void _confirmDeleteReservation(BuildContext context, BayReservation r) {
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Delete Reservation'),
    content: Text('Delete reservation for ${r.vehicleName}?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      TextButton(onPressed: () { ctx.read<GarageProvider>().deleteReservation(r.id!); Navigator.pop(ctx); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
    ],
  ));
}

IconData _bayTypeIcon(String t) {
  switch (t) {
    case 'lift': return Icons.elevator;
    case 'flat': return Icons.grid_on;
    case 'paint': return Icons.format_paint;
    case 'wash': return Icons.local_car_wash;
    case 'inspection': return Icons.fact_check;
    default: return Icons.home_repair_service;
  }
}

Color _reservationColor(String s) {
  switch (s) {
    case 'scheduled': return const Color(0xFF3b82f6);
    case 'active': return const Color(0xFF10b981);
    case 'completed': return const Color(0xFF6b7280);
    case 'cancelled': return const Color(0xFFef4444);
    default: return DomendraTheme.onSurfaceMuted;
  }
}

String _fmtDateTime(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
