import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/equipment_model.dart';
import '../../../providers/equipment_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'equipment_dialogs.dart';

/// Equipment screen — mirrors the web `pages/app/equipment/index.vue`.
///
/// Tabbed hub for equipment & tools management:
///  1. Inventory    — searchable/filterable card list with check-out/in, meter, edit, delete
///  2. Checkouts     — read-only list of active/overdue/returned checkouts
///  3. Meter Entries — log of all meter readings
///  4. Calibrations  — calibration records with result chips
///  5. Analytics     — KPIs, status breakdown, category breakdown charts
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.inventory_outlined, size: 18), text: 'Inventory'),
    Tab(icon: Icon(Icons.swap_horiz, size: 18), text: 'Checkouts'),
    Tab(icon: Icon(Icons.speed, size: 18), text: 'Meter'),
    Tab(icon: Icon(Icons.tune, size: 18), text: 'Calibrations'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<EquipmentProvider>();
      p.refresh();
      p.loadSupportingData();
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
        title: const Text('Equipment'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, size: 20),
            tooltip: 'Seed Demo Data',
            onPressed: () => _showSeedMenu(context),
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
      drawer: const AppDrawer(currentRoute: '/equipment'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InventoryTab(),
          _CheckoutsTab(),
          _MeterTab(),
          _CalibrationsTab(),
          _AnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: DomendraTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final tabIndex = _tabController.index;
    // Different FAB action per tab
    switch (tabIndex) {
      case 0:
        showEquipmentFormDialog(context, null);
        break;
      case 2:
        showMeterEntryDialog(context, null);
        break;
      case 3:
        showCalibrationDialog(context);
        break;
      default:
        showEquipmentFormDialog(context, null);
    }
  }

  void _showSeedMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Seed Demo Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: DomendraTheme.success),
                title: const Text('Add demo data'),
                subtitle: const Text('Keep existing items'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<EquipmentProvider>().seedDemoData(clear: false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Demo data added'), backgroundColor: DomendraTheme.success),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: DomendraTheme.danger),
                title: const Text('Replace all with demo data'),
                subtitle: const Text('Delete existing first'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmReplace(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmReplace(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace All Data?'),
        content: const Text('This will delete all existing equipment and replace it with demo data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<EquipmentProvider>().seedDemoData(clear: true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo data replaced'), backgroundColor: DomendraTheme.success),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 1. INVENTORY TAB
// ════════════════════════════════════════════════════════════
class _InventoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EquipmentProvider>();
    final list = p.filtered;

    // KPI cards
    final total = p.items.length;
    final available = p.items.where((e) => e.status == EquipmentStatus.available).length;
    final checkedOut = p.items.where((e) => e.isCheckedOut).length;
    final calibDue = p.items.where((e) => e.calibrationOverdue).length;

    return Column(
      children: [
        // KPI row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(child: _KpiCard(label: 'Total', value: total, color: DomendraTheme.primary)),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(label: 'Available', value: available, color: DomendraTheme.success)),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(label: 'Checked Out', value: checkedOut, color: DomendraTheme.info)),
              const SizedBox(width: 6),
              Expanded(child: _KpiCard(label: 'Calib Due', value: calibDue, color: DomendraTheme.warning)),
            ],
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: TextField(
            onChanged: p.setSearch,
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: p.search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => p.setSearch(''))
                  : null,
              isDense: true,
            ),
          ),
        ),
        // Filter chips
        _FilterBar(),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${list.length} item${list.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted),
              ),
              const Spacer(),
              if (p.hasActiveFilters)
                TextButton(
                  onPressed: p.clearFilters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.refresh,
            child: p.loading && p.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : p.error != null && p.items.isEmpty
                    ? _ErrorState(error: p.error!, onRetry: p.refresh)
                    : list.isEmpty
                        ? _EmptyState(onAdd: () => showEquipmentFormDialog(context, null))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                            itemCount: list.length,
                            itemBuilder: (context, i) => _EquipmentCard(item: list[i]),
                          ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Filter bar
// ════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EquipmentProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterChip(
            label: 'Status',
            value: p.statusFilter,
            options: const [
              ('available', 'Available'),
              ('in_use', 'In Use'),
              ('in_maintenance', 'In Maintenance'),
              ('retired', 'Retired'),
            ],
            onSelect: p.setStatusFilter,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Category',
            value: p.categoryFilter,
            options: p.categories.map((c) {
              final m = c as Map<String, dynamic>;
              return (m['id']?.toString() ?? '', m['name']?.toString() ?? '');
            }).toList(),
            onSelect: p.setCategoryFilter,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Calibration',
            value: p.calibrationFilter,
            options: const [
              ('overdue', 'Overdue'),
              ('due_soon', 'Due Soon'),
              ('ok', 'OK'),
              ('not_required', 'Not Required'),
            ],
            onSelect: p.setCalibrationFilter,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onSelect;

  const _FilterChip({required this.label, required this.value, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return ActionChip(
      label: Text(
        hasValue ? options.where((o) => o.$1 == value).first.$2 : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: hasValue ? Colors.white : DomendraTheme.onSurfaceMuted,
        ),
      ),
      avatar: hasValue ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      onPressed: () => _showOptions(context),
      backgroundColor: hasValue ? DomendraTheme.primary : DomendraTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Filter by $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('All'),
                onTap: () {
                  onSelect(null);
                  Navigator.pop(ctx);
                },
              ),
              ...options.map((o) => ListTile(
                    leading: Icon(o.$1 == value ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 20, color: DomendraTheme.primary),
                    title: Text(o.$2),
                    onTap: () {
                      onSelect(o.$1);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
// Equipment Card
// ════════════════════════════════════════════════════════════
class _EquipmentCard extends StatelessWidget {
  final EquipmentItem item;
  const _EquipmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: DomendraTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: DomendraTheme.danger),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: DomendraTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.edit, color: DomendraTheme.primary),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          showEquipmentFormDialog(context, item);
          return false;
        }
        return showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Equipment'),
            content: Text('Delete "${item.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd && item.id != null) {
          await context.read<EquipmentProvider>().deleteItem(item.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Equipment deleted'), backgroundColor: DomendraTheme.danger),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DomendraTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DomendraTheme.outline),
        ),
        child: Column(
          children: [
            // Top row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DomendraTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build, color: DomendraTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName.isNotEmpty ? item.displayName : item.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.assetNumber.isNotEmpty)
                        Text(
                          '# ${item.assetNumber}',
                          style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                        ),
                    ],
                  ),
                ),
                _StatusChip(status: item.status),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Detail pills
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (item.categoryName.isNotEmpty)
                  _DetailPill(icon: Icons.category_outlined, label: item.categoryName),
                if (item.assignedToName.isNotEmpty)
                  _DetailPill(icon: Icons.person_outlined, label: item.assignedToName),
                if (item.assignedVehicleName.isNotEmpty)
                  _DetailPill(icon: Icons.directions_car_outlined, label: item.assignedVehicleName),
                if (item.currentHours > 0)
                  _DetailPill(icon: Icons.speed, label: '${item.currentHours.toStringAsFixed(1)} h'),
                if (item.location.isNotEmpty)
                  _DetailPill(icon: Icons.location_on_outlined, label: item.location),
              ],
            ),
            // Calibration chip
            if (item.requiresCalibration) ...[
              const SizedBox(height: 8),
              _CalibrationChip(status: item.calibrationStatus),
            ],
            // Action buttons
            const SizedBox(height: 10),
            Row(
              children: [
                // Check out / in
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (item.isCheckedOut) {
                        context.read<EquipmentProvider>().checkIn(item.id!);
                      } else {
                        showCheckoutDialog(context, item);
                      }
                    },
                    icon: Icon(item.isCheckedOut ? Icons.logout : Icons.login, size: 16),
                    label: Text(item.isCheckedOut ? 'Check In' : 'Check Out', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Meter entry
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showMeterEntryDialog(context, item),
                    icon: const Icon(Icons.speed, size: 16),
                    label: const Text('Meter', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit
                SizedBox(
                  width: 36,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => showEquipmentFormDialog(context, item),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final EquipmentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      EquipmentStatus.available => (DomendraTheme.success, 'Available'),
      EquipmentStatus.inUse => (DomendraTheme.info, 'In Use'),
      EquipmentStatus.inMaintenance => (DomendraTheme.warning, 'Maint'),
      EquipmentStatus.retired => (DomendraTheme.onSurfaceMuted, 'Retired'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _CalibrationChip extends StatelessWidget {
  final CalibrationStatus status;
  const _CalibrationChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CalibrationStatus.notRequired => (DomendraTheme.onSurfaceMuted, 'Cal: N/A'),
      CalibrationStatus.overdue => (DomendraTheme.danger, 'Cal: Overdue'),
      CalibrationStatus.dueSoon => (DomendraTheme.warning, 'Cal: Due Soon'),
      CalibrationStatus.ok => (DomendraTheme.success, 'Cal: OK'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DomendraTheme.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. CHECKOUTS TAB
// ════════════════════════════════════════════════════════════
class _CheckoutsTab extends StatefulWidget {
  @override
  State<_CheckoutsTab> createState() => _CheckoutsTabState();
}

class _CheckoutsTabState extends State<_CheckoutsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().refreshCheckouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<EquipmentProvider>();

    final active = p.checkouts.where((c) => c.returnedAt == null && !c.isOverdue).length;
    final overdue = p.checkouts.where((c) => c.isOverdue).length;

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _CheckoutFilterChip(label: 'All', value: '', activeCount: null),
              const SizedBox(width: 8),
              _CheckoutFilterChip(label: 'Active', value: 'active', activeCount: active),
              const SizedBox(width: 8),
              _CheckoutFilterChip(label: 'Overdue', value: 'overdue', activeCount: overdue),
              const SizedBox(width: 8),
              _CheckoutFilterChip(label: 'Returned', value: 'returned', activeCount: null),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => p.refreshCheckouts(),
            child: p.checkouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No checkouts', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: p.checkouts.length,
                    itemBuilder: (context, i) => _CheckoutCard(checkout: p.checkouts[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final int? activeCount;

  const _CheckoutFilterChip({required this.label, required this.value, this.activeCount});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EquipmentProvider>();
    final selected = p.checkoutFilter == value;

    return FilterChip(
      label: Text(
        activeCount != null ? '$label ($activeCount)' : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : DomendraTheme.onSurfaceMuted,
        ),
      ),
      selected: selected,
      onSelected: (_) {
        p.setCheckoutFilter(value);
        p.refreshCheckouts();
      },
      selectedColor: DomendraTheme.primary,
      backgroundColor: DomendraTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final EquipmentCheckout checkout;
  const _CheckoutCard({required this.checkout});

  @override
  Widget build(BuildContext context) {
    final isReturned = checkout.returnedAt != null;
    final isOverdue = checkout.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOverdue ? DomendraTheme.danger.withOpacity(0.3) : DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isReturned ? DomendraTheme.success : isOverdue ? DomendraTheme.danger : DomendraTheme.info).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isReturned ? Icons.check_circle : isOverdue ? Icons.warning : Icons.logout,
                  size: 18,
                  color: isReturned ? DomendraTheme.success : isOverdue ? DomendraTheme.danger : DomendraTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(checkout.equipmentName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('To: ${checkout.checkedOutToName}', style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Text('OVERDUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DomendraTheme.danger)),
                )
              else if (isReturned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Text('RETURNED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DomendraTheme.success)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: DomendraTheme.info.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: DomendraTheme.info)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _DetailPill(icon: Icons.access_time, label: 'Out: ${_fmtDate(checkout.checkedOutAt)}'),
              _DetailPill(icon: Icons.schedule, label: 'Return: ${_fmtDate(checkout.expectedReturnAt)}'),
              if (checkout.durationHours > 0)
                _DetailPill(icon: Icons.timer, label: '${checkout.durationHours.toStringAsFixed(1)}h'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. METER ENTRIES TAB
// ════════════════════════════════════════════════════════════
class _MeterTab extends StatefulWidget {
  @override
  State<_MeterTab> createState() => _MeterTabState();
}

class _MeterTabState extends State<_MeterTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().refreshMeterEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<EquipmentProvider>();

    return RefreshIndicator(
      onRefresh: p.refreshMeterEntries,
      child: p.meterEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text('No meter entries', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: p.meterEntries.length,
              itemBuilder: (context, i) {
                final entry = p.meterEntries[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DomendraTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DomendraTheme.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.speed, size: 18, color: DomendraTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.hours.toStringAsFixed(1)} h', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(_fmtDate(entry.recordedAt), style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                            if (entry.notes.isNotEmpty)
                              Text(entry.notes, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. CALIBRATIONS TAB
// ════════════════════════════════════════════════════════════
class _CalibrationsTab extends StatefulWidget {
  @override
  State<_CalibrationsTab> createState() => _CalibrationsTabState();
}

class _CalibrationsTabState extends State<_CalibrationsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().refreshCalibrations();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<EquipmentProvider>();

    return RefreshIndicator(
      onRefresh: p.refreshCalibrations,
      child: p.calibrations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text('No calibration records', style: TextStyle(color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: p.calibrations.length,
              itemBuilder: (context, i) {
                final cal = p.calibrations[i];
                final (color, label) = _resultInfo(cal.result);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DomendraTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DomendraTheme.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.verified, size: 18, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_fmtDate(cal.calibratedAt), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            if (cal.calibratedBy.isNotEmpty)
                              Text('By: ${cal.calibratedBy}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                            if (cal.certificateNumber.isNotEmpty)
                              Text('Cert: ${cal.certificateNumber}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  (Color, String) _resultInfo(String result) {
    switch (result.toLowerCase()) {
      case 'pass':
        return (DomendraTheme.success, 'PASS');
      case 'fail':
        return (DomendraTheme.danger, 'FAIL');
      case 'adjusted':
        return (DomendraTheme.warning, 'ADJUSTED');
      default:
        return (DomendraTheme.onSurfaceMuted, result.toUpperCase());
    }
  }
}

// ════════════════════════════════════════════════════════════
// 5. ANALYTICS TAB
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatefulWidget {
  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>().refreshAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EquipmentProvider>();
    final a = p.analytics;

    if (p.analyticsLoading && a == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (a == null) {
      return _AnalyticsEmptyState(onRetry: () => p.refreshAnalytics());
    }

    final summary = a['summary'] as Map<String, dynamic>? ?? {};
    final byStatus = a['by_status'] as List? ?? [];
    final byCategory = a['by_category'] as List? ?? [];
    final recent = a['recent_activity'] as Map<String, dynamic>? ?? {};

    final utilization = (summary['utilization_pct'] as num?)?.toDouble() ?? 0;
    final assetValue = (summary['total_value'] as num?)?.toDouble() ?? 0;
    final inMaintenance = (summary['in_maintenance'] as num?)?.toInt() ?? 0;
    final retired = (summary['retired'] as num?)?.toInt() ?? 0;
    final checkouts30 = (recent['checkouts'] as num?)?.toInt() ?? 0;
    final meter30 = (recent['meter_entries'] as num?)?.toInt() ?? 0;
    final calib30 = (recent['calibrations'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Secondary KPIs
        Row(
          children: [
            Expanded(child: _MiniStatCard(label: 'Utilization', value: '${utilization.toStringAsFixed(0)}%', color: DomendraTheme.primary)),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(label: 'Asset Value', value: _fmtMoney(assetValue), color: DomendraTheme.success)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _MiniStatCard(label: 'In Maintenance', value: '$inMaintenance', color: DomendraTheme.warning)),
            const SizedBox(width: 8),
            Expanded(child: _MiniStatCard(label: 'Retired', value: '$retired', color: DomendraTheme.onSurfaceMuted)),
          ],
        ),
        const SizedBox(height: 16),
        // Recent activity
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DomendraTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DomendraTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('30-Day Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _ActivityChip(icon: Icons.swap_horiz, count: checkouts30, label: 'Checkouts')),
                  const SizedBox(width: 8),
                  Expanded(child: _ActivityChip(icon: Icons.speed, count: meter30, label: 'Meter')),
                  const SizedBox(width: 8),
                  Expanded(child: _ActivityChip(icon: Icons.tune, count: calib30, label: 'Calibrations')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Status breakdown — donut pie chart (mirrors web Status pie)
        if (byStatus.isNotEmpty) ...[
          _StatusDonutChart(
            statusColors: {for (final e in byStatus) (e as Map<String, dynamic>)['status'] as String: _statusColor((e as Map<String, dynamic>)['status'] as String)},
            byStatus: byStatus,
            prettify: _prettify,
          ),
        ],
        const SizedBox(height: 16),
        // Category breakdown — horizontal bar chart (mirrors web Category bar)
        if (byCategory.isNotEmpty) ...[
          _CategoryBarChart(
            byCategory: byCategory,
          ),
        ],
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return DomendraTheme.success;
      case 'in_use':
        return DomendraTheme.info;
      case 'in_maintenance':
        return DomendraTheme.warning;
      case 'retired':
        return DomendraTheme.onSurfaceMuted;
      default:
        return DomendraTheme.primary;
    }
  }

  String _prettify(String key) {
    return key.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _ActivityChip({required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DomendraTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: DomendraTheme.primary),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

// ── Status donut pie chart (mirrors web pie) ─────────────────
class _StatusDonutChart extends StatelessWidget {
  final Map<String, Color> statusColors;
  final List byStatus;
  final String Function(String) prettify;

  const _StatusDonutChart({required this.statusColors, required this.byStatus, required this.prettify});

  @override
  Widget build(BuildContext context) {
    final sections = byStatus.map((entry) {
      final m = entry as Map<String, dynamic>;
      final key = m['status'] as String;
      final count = (m['count'] as num?)?.toDouble() ?? 0;
      final color = statusColors[key] ?? DomendraTheme.primary;
      return PieChartSectionData(
        value: count,
        color: color,
        radius: 50,
        title: count > 0 ? count.toInt().toString() : '',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();
    final total = byStatus.fold<double>(0, (s, e) => s + (((e as Map<String, dynamic>)['count'] as num?)?.toDouble() ?? 0));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.donut_small, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Status Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(PieChartData(
                  sections: sections,
                  centerSpaceRadius: 38,
                  sectionsSpace: 2,
                )),
                Positioned(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${total.round()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const Text('Total', style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: byStatus.map((entry) {
              final m = entry as Map<String, dynamic>;
              final key = m['status'] as String;
              final count = (m['count'] as num?)?.toInt() ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: statusColors[key], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text('${prettify(key)} ($count)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Category horizontal bar chart (mirrors web bar) ──────────
class _CategoryBarChart extends StatelessWidget {
  final List byCategory;
  const _CategoryBarChart({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final items = byCategory.map((c) {
      final m = c as Map<String, dynamic>;
      return (label: (m['category'] ?? m['name'])?.toString() ?? 'Unknown', count: (m['count'] as num?)?.toDouble() ?? 0);
    }).toList();
    final maxV = items.fold<double>(0, (a, e) => a > e.count ? a : e.count);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: DomendraTheme.primary),
              SizedBox(width: 6),
              Text('Equipment by Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          // each row as horizontal bar
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text('${e.count.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxV > 0 ? e.count / maxV : 0,
                        minHeight: 8,
                        backgroundColor: DomendraTheme.surfaceVariant,
                        color: DomendraTheme.primary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Shared states
// ════════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.error_outline, size: 48, color: DomendraTheme.danger),
        const SizedBox(height: 16),
        const Text('Failed to load equipment', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DomendraTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Icon(Icons.build_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
        const SizedBox(height: 12),
        const Text('No equipment found', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        const Text('Add equipment or seed demo data to get started.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add Equipment')),
      ],
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _AnalyticsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No analytics data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 18), label: const Text('Load Analytics')),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════════════════
String _fmtDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _fmtMoney(double v) {
  if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
  return '\$${v.toStringAsFixed(0)}';
}
