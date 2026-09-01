import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/fuel_model.dart';
import '../../../providers/fuel_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/app_drawer.dart';
import 'fuel_dialogs.dart';

/// Currency symbol from [DashboardProvider].
String _currencySymbol = 'KSh';

/// Fuel & Energy screen — mirrors the web `pages/app/fuel/index.vue` (8 tabs).
class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Transactions'),
    Tab(icon: Icon(Icons.credit_card_outlined, size: 18), text: 'Cards'),
    Tab(icon: Icon(Icons.electric_car_outlined, size: 18), text: 'EV Charging'),
    Tab(icon: Icon(Icons.engineering_outlined, size: 18), text: 'Idling'),
    Tab(icon: Icon(Icons.gpp_maybe_outlined, size: 18), text: 'Fraud'),
    Tab(icon: Icon(Icons.schedule_outlined, size: 18), text: 'Budgets'),
    Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Analytics'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currencySymbol = context.read<DashboardProvider>().currencySymbol;
      context.read<FuelProvider>().refreshAll();
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
        title: const Text('Fuel & Energy'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<FuelProvider>().refreshAll(),
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
      drawer: const AppDrawer(currentRoute: '/fuel'),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _TransactionsTab(),
          _CardsTab(),
          _ChargingTab(),
          _IdlingTab(),
          _FraudTab(),
          _BudgetsTab(),
          _AnalyticsTab(),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildFab(BuildContext context) {
    final index = _tabController.index;
    switch (index) {
      case 1: // Transactions
        return FloatingActionButton(
          heroTag: 'fab_fuel_txn',
          onPressed: () => showFuelTransactionFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 2: // Cards
        return FloatingActionButton(
          heroTag: 'fab_fuel_card',
          onPressed: () => showFuelCardFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 3: // Charging
        return FloatingActionButton(
          heroTag: 'fab_fuel_charging',
          onPressed: () => showChargingFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 4: // Idling
        return FloatingActionButton(
          heroTag: 'fab_fuel_idling',
          onPressed: () => showIdlingFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      case 6: // Budgets
        return FloatingActionButton(
          heroTag: 'fab_fuel_budget',
          onPressed: () => showFuelBudgetFormDialog(context, null),
          backgroundColor: DomendraTheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ════════════════════════════════════════════════════════════
// 1. OVERVIEW TAB
// ════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.analyticsLoading && p.analytics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPI Row 1
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Total Fuel Cost',
              value: _fmtMoney(p.totalFuelCost),
              subtitle: 'All transactions',
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              icon: Icons.payments_outlined,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Total Volume',
              value: '${p.totalVolume.toStringAsFixed(1)} gal',
              subtitle: 'Across all vehicles',
              gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
              icon: Icons.local_gas_station_outlined,
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Avg Price/Unit',
              value: _fmtMoney(p.avgPricePerUnit),
              subtitle: 'Per gallon',
              gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF34d399)]),
              icon: Icons.trending_up,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Fraud Alerts',
              value: '${p.fraudAlertCount}',
              subtitle: 'Total alerts',
              gradient: LinearGradient(colors: [Color(0xFFef4444), Color(0xFFf87171).withOpacity(0.8)]),
              icon: Icons.gpp_maybe_outlined,
            )),
          ],
        ),
        const SizedBox(height: 20),
        // EV mini stats
        _MiniStatCard(
          title: 'EV Charging',
          icon: Icons.electric_car_outlined,
          color: const Color(0xFF10B981),
          stats: [
            {'Sessions': '${p.chargingSessionCount}'},
            {'Total kWh': p.chargingTotalKwh.toStringAsFixed(1)},
            {'Cost': _fmtMoney(p.chargingTotalCost)},
            {'Avg/kWh': _fmtMoney(p.chargingAvgPerKwh)},
          ],
        ),
        const SizedBox(height: 8),
        // Idling mini stats
        _MiniStatCard(
          title: 'Idling Events',
          icon: Icons.engineering_outlined,
          color: const Color(0xFFf59e0b),
          stats: [
            {'Events': '${p.idlingEventCount}'},
            {'Hours': p.idlingTotalHours.toStringAsFixed(1)},
            {'Fuel Burned': '${p.idlingTotalFuelBurned.toStringAsFixed(1)} gal'},
            {'Wasted': _fmtMoney(p.idlingTotalWastedCost)},
          ],
        ),
        const SizedBox(height: 20),
        // Daily trend (simple list)
        if (p.dailyTrend.isNotEmpty) ...[
          const Text('Daily Fuel Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...p.dailyTrend.take(7).map((d) {
            final day = d is Map ? (d['date'] ?? d['day'] ?? '')?.toString() : '';
            final cost = d is Map ? _parseDouble(d['cost'] ?? d['total_cost']) : 0.0;
            return _SimpleBarRow(label: day.toString(), value: cost, max: _maxDouble(p.dailyTrend.map((e) => e is Map ? _parseDouble(e['cost'] ?? e['total_cost']) : 0.0)));
          }),
        ],
        const SizedBox(height: 20),
        // By fuel type
        if (p.byFuelType.isNotEmpty) ...[
          const Text('By Fuel Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...p.byFuelType.take(10).map((d) {
            final label = d is Map ? (d['fuel_type'] ?? d['name'] ?? '')?.toString() ?? '' : '';
            final count = d is Map ? _parseInt(d['count'] ?? d['total']) : 0;
            return _FuelTypeRow(label: label, count: count);
          }),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. TRANSACTIONS TAB
// ════════════════════════════════════════════════════════════
class _TransactionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.transactionsLoading && p.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.filteredTransactions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        TextField(
          onChanged: p.setTxnSearch,
          decoration: InputDecoration(
            hintText: 'Search transactions…',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            suffixIcon: p.txnSearch.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => p.setTxnSearch(''))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text('${list.length} transaction${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.receipt_long_outlined, message: 'No transactions. Tap + to add one.')
        else
          ...list.map((t) => _TransactionCard(transaction: t)),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final FuelTransaction transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final t = transaction;
    final color = Color(fuelTypeColor(t.fuelType));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.local_gas_station, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.vehicleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      t.date != null ? _fmtDate(t.date!) : '—',
                      style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtMoney(t.totalCost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${t.quantity.toStringAsFixed(1)} ${t.unitSymbol}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      if (context.mounted) showFuelTransactionFormDialog(context, t);
                      break;
                    case 'delete':
                      final ok = await _confirmDelete(context, 'Delete transaction?');
                      if (ok == true && t.id != null) await p.deleteTransaction(t.id!);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Chip(label: t.fuelType, color: color),
              _DetailPill(icon: Icons.attach_money, label: '${_fmtMoney(t.pricePerUnit)}/${t.unitSymbol}'),
              if (t.mpg > 0) _DetailPill(icon: Icons.speed, label: '${t.mpg.toStringAsFixed(1)} MPG'),
              if (t.stationName.isNotEmpty) _DetailPill(icon: Icons.store_outlined, label: t.stationName),
              if (t.hasReceipt) _DetailPill(icon: Icons.receipt, label: 'Receipt'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. CARDS TAB
// ════════════════════════════════════════════════════════════
class _CardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.cardsLoading && p.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.cards;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Total Cards', value: '${list.length}',
              subtitle: '${list.where((c) => c.isActive).length} active',
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
              icon: Icons.credit_card,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Synced', value: '${list.where((c) => c.lastSyncedAt != null).length}',
              subtitle: 'Recently synced',
              gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF34d399)]),
              icon: Icons.sync,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(),
            TextButton.icon(
              onPressed: () => p.syncAllCards(),
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Sync All'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (list.isEmpty)
          _EmptyState(icon: Icons.credit_card_outlined, message: 'No fuel cards. Tap + to add one.')
        else
          ...list.map((c) => _FuelCardCard(card: c)),
      ],
    );
  }
}

class _FuelCardCard extends StatelessWidget {
  final FuelCard card;
  const _FuelCardCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final isWex = card.provider == 'WEX';
    final gradient = isWex
        ? const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)])
        : const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: card.isActive ? DomendraTheme.outline : DomendraTheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Card visual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(card.providerLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    Icon(Icons.credit_card, color: Colors.white.withOpacity(0.7), size: 24),
                  ],
                ),
                const SizedBox(height: 20),
                Text(card.maskedNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 2, fontFamily: 'monospace')),
                const SizedBox(height: 8),
                Text(card.cardHolderName, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          // Details + actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (card.expiryDate != null) Text('Expires: ${_fmtDate(card.expiryDate!)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      if (card.lastSyncedAt != null) Text('Synced: ${_fmtDate(card.lastSyncedAt!)}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (card.isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          card.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: card.isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) async {
                    switch (action) {
                      case 'sync':
                        if (card.id != null) await p.syncCard(card.id!);
                        break;
                      case 'edit':
                        if (context.mounted) showFuelCardFormDialog(context, card);
                        break;
                      case 'delete':
                        final ok = await _confirmDelete(context, 'Delete this fuel card?');
                        if (ok == true && card.id != null) await p.deleteCard(card.id!);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'sync', child: Text('Sync')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. EV CHARGING TAB
// ════════════════════════════════════════════════════════════
class _ChargingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.chargingLoading && p.charging.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.charging;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPIs
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Sessions', value: '${p.chargingSessionCount}',
              gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF34d399)]),
              icon: Icons.electric_car,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Total kWh', value: p.chargingTotalKwh.toStringAsFixed(1),
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
              icon: Icons.bolt,
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Total Cost', value: _fmtMoney(p.chargingTotalCost),
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              icon: Icons.payments,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Avg / kWh', value: _fmtMoney(p.chargingAvgPerKwh),
              gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
              icon: Icons.trending_up,
            )),
          ],
        ),
        const SizedBox(height: 16),
        Text('${list.length} session${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.electric_car_outlined, message: 'No charging sessions. Tap + to add one.')
        else
          ...list.map((s) => _ChargingCard(session: s)),
      ],
    );
  }
}

class _ChargingCard extends StatelessWidget {
  final ChargingSession session;
  const _ChargingCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final s = session;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.electric_car, size: 22, color: DomendraTheme.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.vehicleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(s.startTime != null ? _fmtDateTime(s.startTime!) : '—', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtMoney(s.cost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${s.energyKwh.toStringAsFixed(1)} kWh', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      if (context.mounted) showChargingFormDialog(context, s);
                      break;
                    case 'delete':
                      final ok = await _confirmDelete(context, 'Delete charging session?');
                      if (ok == true && s.id != null) await p.deleteCharging(s.id!);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Chip(label: s.networkLabel, color: DomendraTheme.info),
              if (s.durationHours > 0) _DetailPill(icon: Icons.schedule, label: '${s.durationHours.toStringAsFixed(1)}h'),
              if (s.stationName.isNotEmpty) _DetailPill(icon: Icons.location_on_outlined, label: s.stationName),
              if (s.startSoc != null && s.endSoc != null) _DetailPill(icon: Icons.battery_charging_full, label: '${s.startSoc!.toStringAsFixed(0)}% → ${s.endSoc!.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 5. IDLING TAB
// ════════════════════════════════════════════════════════════
class _IdlingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.idlingLoading && p.idling.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.idling;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Events', value: '${p.idlingEventCount}',
              gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
              icon: Icons.engineering,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Hours', value: p.idlingTotalHours.toStringAsFixed(1),
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
              icon: Icons.schedule,
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Fuel Burned', value: '${p.idlingTotalFuelBurned.toStringAsFixed(1)} gal',
              gradient: const LinearGradient(colors: [Color(0xFFef4444), Color(0xFFf87171)]),
              icon: Icons.local_gas_station,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Wasted Cost', value: _fmtMoney(p.idlingTotalWastedCost),
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              icon: Icons.payments,
            )),
          ],
        ),
        const SizedBox(height: 16),
        Text('${list.length} event${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.engineering_outlined, message: 'No idling events. Tap + to add one.')
        else
          ...list.map((e) => _IdlingCard(event: e)),
      ],
    );
  }
}

class _IdlingCard extends StatelessWidget {
  final IdlingEvent event;
  const _IdlingCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final e = event;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: DomendraTheme.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.engineering, size: 22, color: DomendraTheme.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.vehicleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(e.startTime != null ? _fmtDateTime(e.startTime!) : '—', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtMoney(e.cost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DomendraTheme.danger)),
                  Text('${e.durationHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      if (context.mounted) showIdlingFormDialog(context, e);
                      break;
                    case 'delete':
                      final ok = await _confirmDelete(context, 'Delete idling event?');
                      if (ok == true && e.id != null) await p.deleteIdling(e.id!);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _DetailPill(icon: Icons.local_gas_station, label: '${e.fuelBurned.toStringAsFixed(2)} gal burned'),
              _DetailPill(icon: Icons.speed, label: '${e.fuelBurnRate.toStringAsFixed(2)} gal/h'),
              if (e.location.isNotEmpty) _DetailPill(icon: Icons.location_on_outlined, label: e.location),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 6. FRAUD TAB
// ════════════════════════════════════════════════════════════
class _FraudTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.fraudLoading && p.fraud.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = p.fraud;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // Status summary cards
        Row(
          children: [
            Expanded(child: _StatusCard(label: 'Open', value: p.fraudOpenCount, color: const Color(0xFFEF4444))),
            const SizedBox(width: 6),
            Expanded(child: _StatusCard(label: 'Under Review', value: p.fraudReviewCount, color: const Color(0xFF3B82F6))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _StatusCard(label: 'Resolved', value: p.fraudResolvedCount, color: const Color(0xFF10B981))),
            const SizedBox(width: 6),
            Expanded(child: _StatusCard(label: 'Dismissed', value: p.fraudDismissedCount, color: const Color(0xFF6B7280))),
          ],
        ),
        const SizedBox(height: 16),
        Text('${list.length} alert${list.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          _EmptyState(icon: Icons.gpp_maybe_outlined, message: 'No fraud alerts. All clear.')
        else
          ...list.map((a) => _FraudCard(alert: a)),
      ],
    );
  }
}

class _FraudCard extends StatelessWidget {
  final FuelFraudAlert alert;
  const _FraudCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final a = alert;
    final sevColor = Color(severityColor(a.severity));
    final statColor = Color(fraudStatusColor(a.actionStatus));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sevColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: sevColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.gpp_maybe, size: 22, color: sevColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.alertTypeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(a.vehicleName, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(a.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (a.description.isNotEmpty)
            Text(a.description, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _Chip(label: a.severityLabel, color: sevColor),
              if (a.transactionDate != null) _DetailPill(icon: Icons.calendar_today_outlined, label: _fmtDate(a.transactionDate!)),
            ],
          ),
          const SizedBox(height: 8),
          // Action buttons
          if (a.actionStatus == 'open')
            Row(
              children: [
                Expanded(child: TextButton.icon(
                  onPressed: () => p.reviewFraud(a.id!, note: 'Reviewing from mobile'),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text('Review', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: DomendraTheme.info),
                )),
                Expanded(child: TextButton.icon(
                  onPressed: () => p.dismissFraud(a.id!, note: 'Dismissed from mobile'),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: DomendraTheme.onSurfaceMuted),
                )),
              ],
            )
          else if (a.actionStatus == 'under_review')
            Row(
              children: [
                Expanded(child: TextButton.icon(
                  onPressed: () => p.resolveFraud(a.id!, note: 'Resolved from mobile'),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: DomendraTheme.success),
                )),
                Expanded(child: TextButton.icon(
                  onPressed: () => p.dismissFraud(a.id!, note: 'Dismissed from mobile'),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: DomendraTheme.onSurfaceMuted),
                )),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => p.reopenFraud(a.id!, note: 'Reopened from mobile'),
              icon: const Icon(Icons.lock_open, size: 14),
              label: const Text('Reopen', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: DomendraTheme.warning),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 7. BUDGETS TAB
// ════════════════════════════════════════════════════════════
class _BudgetsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.budgetsLoading && p.budgets.isEmpty && p.budgetSummaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = p.budgetRows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        if (p.actualFleet > 0)
          _KpiCard(
            label: 'Fleet Actual Spend',
            value: _fmtMoney(p.actualFleet),
            subtitle: 'This period',
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
            icon: Icons.payments,
          ),
        const SizedBox(height: 16),
        const Text('Budgets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (rows.isEmpty && p.budgets.isEmpty)
          _EmptyState(icon: Icons.schedule_outlined, message: 'No budgets set. Tap + to add one.')
        else
          ...rows.map((r) => _BudgetRow(row: r as Map<String, dynamic>)),
        const SizedBox(height: 20),
        // Charge schedules
        const Text('Charge Schedules', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (p.schedules.isEmpty)
          _EmptyState(icon: Icons.schedule_outlined, message: 'No schedules set.')
        else
          ...p.schedules.map((s) => _ScheduleCard(schedule: s)),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _BudgetRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final id = row['id'] as int?;
    final scope = row['scope']?.toString() ?? '';
    final targetRef = row['target_ref']?.toString() ?? '';
    final month = row['month']?.toString() ?? '';
    final budget = _parseDouble(row['budget']);
    final actual = _parseDouble(row['actual']);
    final pctUsed = budget > 0 ? (actual / budget) : 0.0;
    final overBudget = actual > budget && budget > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${scope[0].toUpperCase()}${scope.substring(1)}: $targetRef', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(month, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
              ),
              Text(_fmtMoney(budget), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (id != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) async {
                    switch (action) {
                      case 'edit':
                        final budget = p.budgets.where((b) => b.id == id).firstOrNull;
                        if (context.mounted) showFuelBudgetFormDialog(context, budget);
                        break;
                      case 'delete':
                        final ok = await _confirmDelete(context, 'Delete this budget?');
                        if (ok == true) await p.deleteBudget(id);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pctUsed.clamp(0.0, 1.0),
                  color: overBudget ? DomendraTheme.danger : (pctUsed > 0.8 ? DomendraTheme.warning : DomendraTheme.success),
                  backgroundColor: (overBudget ? DomendraTheme.danger : DomendraTheme.success).withOpacity(0.1),
                  minHeight: 6,
                ),
              )),
              const SizedBox(width: 8),
              Text('${(pctUsed * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: overBudget ? DomendraTheme.danger : DomendraTheme.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Actual: ${_fmtMoney(actual)}', style: TextStyle(fontSize: 11, color: overBudget ? DomendraTheme.danger : DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ChargeSchedule schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final p = context.read<FuelProvider>();
    final s = schedule;

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
            width: 36, height: 36,
            decoration: BoxDecoration(color: DomendraTheme.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.schedule, size: 20, color: DomendraTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.vehicleName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${s.startTime} - ${s.endTime}', style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
                if (s.recurringDays.isNotEmpty)
                  Text(s.recurringDays, style: const TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${s.targetSoc.toStringAsFixed(0)}% SoC', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (s.isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: s.isActive ? DomendraTheme.success : DomendraTheme.onSurfaceMuted)),
              ),
            ],
          ),
          if (s.id != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (action) async {
                switch (action) {
                  case 'edit':
                    if (context.mounted) showScheduleFormDialog(context, s);
                    break;
                  case 'delete':
                    final ok = await _confirmDelete(context, 'Delete this schedule?');
                    if (ok == true) await p.deleteSchedule(s.id!);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 8. ANALYTICS TAB
// ════════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FuelProvider>();

    if (p.analyticsLoading && p.analytics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final a = p.analytics;
    final maxTxnCost = _parseDouble(a['max_transaction_cost']);
    final maxVehicle = _maxDouble(p.byVehicle.map((v) => v is Map ? _parseDouble(v['cost'] ?? v['total_cost']) : 0.0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      children: [
        // KPIs
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Total Cost', value: _fmtMoney(p.totalFuelCost),
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              icon: Icons.payments,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Total Volume', value: '${p.totalVolume.toStringAsFixed(1)} gal',
              gradient: const LinearGradient(colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
              icon: Icons.local_gas_station,
            )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _KpiCard(
              label: 'Avg Price', value: _fmtMoney(p.avgPricePerUnit),
              gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF34d399)]),
              icon: Icons.trending_up,
            )),
            const SizedBox(width: 6),
            Expanded(child: _KpiCard(
              label: 'Max Txn', value: _fmtMoney(maxTxnCost),
              gradient: const LinearGradient(colors: [Color(0xFFef4444), Color(0xFFf87171)]),
              icon: Icons.warning,
            )),
          ],
        ),
        const SizedBox(height: 20),
        // By vehicle
        if (p.byVehicle.isNotEmpty) ...[
          const Text('Cost by Vehicle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...p.byVehicle.take(10).map((v) {
            final name = v is Map ? (v['vehicle_name'] ?? v['name'])?.toString() ?? '—' : '—';
            final cost = v is Map ? _parseDouble(v['cost'] ?? v['total_cost']) : 0.0;
            return _SimpleBarRow(label: name, value: cost, max: maxVehicle);
          }),
        ],
        const SizedBox(height: 20),
        // By fuel type
        if (p.byFuelType.isNotEmpty) ...[
          const Text('By Fuel Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...p.byFuelType.take(10).map((d) {
            final label = d is Map ? (d['fuel_type'] ?? d['name'] ?? '')?.toString() ?? '' : '';
            final count = d is Map ? _parseInt(d['count'] ?? d['total']) : 0;
            return _FuelTypeRow(label: label, count: count);
          }),
        ],
        const SizedBox(height: 20),
        // By station
        if (a['by_station'] is List) ...[
          const Text('By Station', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...(a['by_station'] as List).take(10).map((d) {
            final name = d is Map ? (d['station_name'] ?? d['name'])?.toString() ?? '—' : '—';
            final cost = d is Map ? _parseDouble(d['cost'] ?? d['total_cost']) : 0.0;
            return _SimpleBarRow(label: name, value: cost, max: _maxDouble((a['by_station'] as List).map((e) => e is Map ? _parseDouble(e['cost'] ?? e['total_cost']) : 0.0)));
          }),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;
  const _KpiCard({required this.label, required this.value, this.subtitle = '', required this.gradient, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: gradient.colors.first.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 16, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatusCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              Icon(Icons.circle, size: 8, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, String>> stats;
  const _MiniStatCard({required this.title, required this.icon, required this.color, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: stats.map((s) {
              final k = s.keys.first;
              final v = s.values.first;
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(k, style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  const _SimpleBarRow({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              color: DomendraTheme.primary,
              backgroundColor: DomendraTheme.primary.withOpacity(0.1),
              minHeight: 8,
            ),
          )),
          const SizedBox(width: 8),
          SizedBox(width: 50, child: Text(_fmtMoney(value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _FuelTypeRow extends StatelessWidget {
  final String label;
  final int count;
  const _FuelTypeRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = Color(fuelTypeColor(label));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _DetailPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: DomendraTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? DomendraTheme.onSurfaceMuted),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color ?? DomendraTheme.onSurfaceMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: DomendraTheme.onSurfaceMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════

String _fmtMoney(double v) => '$_currencySymbol${v.toStringAsFixed(v >= 1000 ? 0 : 2)}';

String _fmtDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _fmtDateTime(DateTime d) {
  final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
  final ampm = d.hour >= 12 ? 'pm' : 'am';
  return '${_fmtDate(d)} $h:${d.minute.toString().padLeft(2, '0')}$ampm';
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _maxDouble(Iterable<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a > b ? a : b);
}

Future<bool?> _confirmDelete(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: DomendraTheme.danger), child: const Text('Delete')),
      ],
    ),
  );
}
