import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reports_provider.dart';
import '../../utils/date_presets.dart';
import '../../widgets/app_drawer.dart';
import 'tabs/financial_overview_tab.dart';
import 'tabs/report_helpers.dart';
import 'tabs/revenue_analysis_tab.dart';
import 'tabs/cost_analysis_tab.dart';
import 'tabs/vehicle_roi_tab.dart';
import 'tabs/cash_flow_tab.dart';
import 'tabs/profit_loss_tab.dart';
import 'tabs/locations_report_tab.dart';
import 'tabs/cost_of_ownership_tab.dart';
import 'tabs/general_ledger_tab.dart';
import 'tabs/standard_reports_tab.dart';

/// Reports screen — mirrors the web route `/app/reports`.
///
/// 10-tab hub: dashboard, revenue, costs, ROI, cash flow, P&L,
/// locations, ownership, general ledger, standard reports.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DatePreset _preset = DatePreset.thisYear;
  DateTime? _customStart;
  DateTime? _customEnd;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Dashboard'),
    Tab(icon: Icon(Icons.trending_up, size: 18), text: 'Revenue'),
    Tab(icon: Icon(Icons.trending_down, size: 18), text: 'Costs'),
    Tab(icon: Icon(Icons.percent, size: 18), text: 'ROI'),
    Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 18), text: 'Cash Flow'),
    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'P&L'),
    Tab(icon: Icon(Icons.place_outlined, size: 18), text: 'Locations'),
    Tab(icon: Icon(Icons.directions_car_outlined, size: 18), text: 'Ownership'),
    Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Ledger'),
    Tab(icon: Icon(Icons.assessment_outlined, size: 18), text: 'Standard'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reportCurrencySymbol = context.read<DashboardProvider>().currencySymbol;
      _fetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetch() {
    final range = resolvePreset(_preset, customStart: _customStart, customEnd: _customEnd);
    context.read<ReportsProvider>().refreshAll(
          start: '${range.startDateStr}T00:00:00',
          end: '${range.endDateStr}T23:59:59',
        );
  }

  void _onPresetChanged(DatePreset? p) {
    if (p == null) return;
    setState(() => _preset = p);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportsProvider>();

    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Financial Reports'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: reports.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: DomendraTheme.primary))
                : const Icon(Icons.refresh, color: DomendraTheme.onSurfaceMuted),
            onPressed: reports.loading ? null : _fetch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: DomendraTheme.onSurfaceMuted),
            onSelected: (value) async {
              if (value == 'seed') {
                final provider = context.read<ReportsProvider>();
                final ok = await provider.seedDemo();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Demo data seeded' : 'Seed failed — data may already exist')),
                  );
                  if (ok) _fetch();
                }
              } else if (value == 'refresh') {
                _fetch();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh All')),
              const PopupMenuItem(value: 'seed', child: Text('Seed Demo Data')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date filter bar
              _DateFilterBar(
                preset: _preset,
                onPresetChanged: _onPresetChanged,
                customStart: _customStart,
                customEnd: _customEnd,
                onCustomStart: (d) => setState(() => _customStart = d),
                onCustomEnd: (d) => setState(() => _customEnd = d),
                onApply: _fetch,
              ),
              TabBar(
                controller: _tabController,
                tabs: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: DomendraTheme.primary,
                unselectedLabelColor: DomendraTheme.onSurfaceMuted,
                indicatorColor: DomendraTheme.primary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                dividerColor: DomendraTheme.outline,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: reports.loading && reports.overview == null
          ? const Center(child: CircularProgressIndicator())
          : reports.error != null && reports.overview == null
              ? _ErrorState(error: reports.error!, onRetry: _fetch)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    FinancialOverviewTab(data: reports.overview),
                    RevenueAnalysisTab(data: reports.revenue),
                    CostAnalysisTab(data: reports.costs),
                    VehicleRoiTab(vehicles: reports.vehicleRoi),
                    CashFlowTab(data: reports.cashFlow),
                    ProfitLossTab(data: reports.profitLoss),
                    LocationsReportTab(data: reports.locations),
                    CostOfOwnershipTab(data: reports.ownership),
                    GeneralLedgerTab(data: reports.generalLedger),
                    StandardReportsTab(),
                  ],
                ),
    );
  }
}

// ── Date filter bar ──────────────────────────────────────────

class _DateFilterBar extends StatelessWidget {
  final DatePreset preset;
  final ValueChanged<DatePreset?> onPresetChanged;
  final DateTime? customStart;
  final DateTime? customEnd;
  final ValueChanged<DateTime> onCustomStart;
  final ValueChanged<DateTime> onCustomEnd;
  final VoidCallback onApply;

  const _DateFilterBar({
    required this.preset,
    required this.onPresetChanged,
    required this.customStart,
    required this.customEnd,
    required this.onCustomStart,
    required this.onCustomEnd,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final p in DatePreset.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(p.label),
                  selected: preset == p,
                  onSelected: (_) => onPresetChanged(p),
                  selectedColor: DomendraTheme.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: preset == p ? FontWeight.w700 : FontWeight.w500,
                    color: preset == p ? DomendraTheme.primary : DomendraTheme.onSurfaceMuted,
                  ),
                  side: BorderSide(
                    color: preset == p ? DomendraTheme.primary : DomendraTheme.outline,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            if (preset == DatePreset.custom) ...[
              const SizedBox(width: 4),
              _DatePickerChip(
                label: customStart != null ? _fmtDate(customStart!) : 'Start',
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: customStart ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) onCustomStart(d);
                },
              ),
              const SizedBox(width: 4),
              _DatePickerChip(
                label: customEnd != null ? _fmtDate(customEnd!) : 'End',
                icon: Icons.calendar_today_outlined,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: customEnd ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) onCustomEnd(d);
                },
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: onApply,
                style: TextButton.styleFrom(
                  backgroundColor: DomendraTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

class _DatePickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DatePickerChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurface)),
      avatar: Icon(icon, size: 14, color: DomendraTheme.primary),
      onPressed: onTap,
      side: const BorderSide(color: DomendraTheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Error state ───────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: DomendraTheme.danger),
            const SizedBox(height: 16),
            const Text('Failed to load reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: DomendraTheme.onSurfaceMuted)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
