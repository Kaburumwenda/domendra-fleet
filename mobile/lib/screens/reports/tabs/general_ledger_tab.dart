import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'report_helpers.dart';

/// General Ledger tab — mirrors web `GeneralLedger.vue`.
///
/// Data from `GET /reports/general-ledger/`.
class GeneralLedgerTab extends StatelessWidget {
  final Map<String, dynamic>? data;

  const GeneralLedgerTab({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return tabLoading();

    final summary = (data!['summary'] as Map<String, dynamic>?) ?? {};
    final entries = (data!['entries'] as List?) ?? [];
    final trialBalance = (data!['trial_balance'] as List?) ?? [];
    final monthly = (data!['monthly'] as List?) ?? [];
    final sourceBreakdown = (data!['source_breakdown'] as List?) ?? [];
    final arAging = (data!['ar_aging'] as Map<String, dynamic>?) ?? {};
    final apAging = (data!['ap_aging'] as Map<String, dynamic>?) ?? {};

    final entryCount = toInt(summary['entry_count']);
    final totalDebits = toDouble(summary['total_debits']);
    final totalCredits = toDouble(summary['total_credits']);
    final arOutstanding = toDouble(summary['ar_outstanding']);
    final balanced = summary['balanced'] as bool? ?? false;
    final period = (data!['period'] as Map<String, dynamic>?) ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period + balance chips
        if (period.isNotEmpty || summary.isNotEmpty) ...[
          Row(
            children: [
              if (period['start'] != null && period['end'] != null)
                Expanded(child: statusChip('${period['start'].toString().substring(0, 10)} → ${period['end'].toString().substring(0, 10)}', DomendraTheme.info)),
              const SizedBox(width: 8),
              if (summary.isNotEmpty)
                statusChip(balanced ? 'Balanced' : 'Unbalanced', balanced ? DomendraTheme.success : DomendraTheme.warning),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // KPIs
        kpiGrid([
          ReportKpiCard(icon: Icons.receipt, color: DomendraTheme.primary, label: 'Journal Entries', value: fmtNum(entryCount)),
          ReportKpiCard(icon: Icons.north_east, color: DomendraTheme.success, label: 'Total Debits', value: fmtMoney(totalDebits)),
        ]),
        const SizedBox(height: 10),
        kpiGrid([
          ReportKpiCard(icon: Icons.south_west, color: DomendraTheme.danger, label: 'Total Credits', value: fmtMoney(totalCredits)),
          ReportKpiCard(icon: Icons.outbound, color: DomendraTheme.warning, label: 'A/R Outstanding', value: fmtMoney(arOutstanding)),
        ]),
        const SizedBox(height: 20),

        // Monthly debits vs credits
        if (monthly.isNotEmpty) ...[
          sectionTitle('Monthly Debits vs Credits'),
          const SizedBox(height: 10),
          reportCard(child: _MonthlyBars(data: monthly.cast<Map<String, dynamic>>())),
          const SizedBox(height: 20),
        ],

        // Source breakdown
        if (sourceBreakdown.isNotEmpty) ...[
          sectionTitle('Entry Sources'),
          const SizedBox(height: 10),
          reportCard(child: Column(
            children: sourceBreakdown.map((s) {
              final m = s as Map<String, dynamic>;
              return dataRow(
                _sourceLabel(m['source'] as String? ?? 'unknown'),
                '${fmtNum(toInt(m["count"]))} (${fmtMoney(toDouble(m["total"]))})',
                valueColor: DomendraTheme.primary,
              );
            }).toList(),
          )),
          const SizedBox(height: 20),
        ],

        // A/R & A/P Aging
        if (arAging.isNotEmpty || apAging.isNotEmpty) ...[
          sectionTitle('Aging'),
          const SizedBox(height: 10),
          if (arAging.isNotEmpty) ...[
            reportCard(child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_in_talk, size: 16, color: DomendraTheme.warning),
                    SizedBox(width: 8),
                    Text('A/R Aging', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
                    Spacer(),
                    Text('Outstanding', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                ..._agingBuckets(arAging),
              ],
            )),
            const SizedBox(height: 12),
          ],
          if (apAging.isNotEmpty) ...[
            reportCard(child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: DomendraTheme.danger),
                    SizedBox(width: 8),
                    Text('A/P Aging', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface)),
                    Spacer(),
                    Text('Outstanding', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                ..._agingBuckets(apAging),
              ],
            )),
            const SizedBox(height: 20),
          ],
        ],

        // Trial balance
        if (trialBalance.isNotEmpty) ...[
          sectionTitle('Trial Balance'),
          const SizedBox(height: 10),
          reportCard(child: Column(
            children: [
              for (int i = 0; i < trialBalance.take(20).length; i++) ...[
                _trialBalanceRow(trialBalance[i] as Map<String, dynamic>),
                if (i < 19 && i < trialBalance.length - 1) thinDivider(),
              ],
            ],
          )),
          const SizedBox(height: 20),
        ],

        // Journal entries
        if (entries.isNotEmpty) ...[
          sectionTitle('Journal Entries (${entries.length})'),
          const SizedBox(height: 10),
          reportCard(child: Column(
            children: [
              for (int i = 0; i < entries.take(30).length; i++) ...[
                _journalEntryRow(entries[i] as Map<String, dynamic>),
                if (i < 29 && i < entries.length - 1) thinDivider(),
              ],
            ],
          )),
        ],
      ],
    );
  }

  Widget _trialBalanceRow(Map<String, dynamic> tb) {
    final name = tb['name'] as String? ?? '?';
    final type = tb['type'] as String? ?? '';
    final debit = toDouble(tb['debit']);
    final credit = toDouble(tb['credit']);
    final balance = toDouble(tb['balance']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text(type, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(fmtMoney(debit), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.success), textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(fmtMoney(credit), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.danger), textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(fmtMoney(balance), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DomendraTheme.onSurface), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _journalEntryRow(Map<String, dynamic> e) {
    final date = (e['date'] as String? ?? '').substring(0, 10);
    final account = e['account_name'] as String? ?? '?';
    final debit = toDouble(e['debit']);
    final credit = toDouble(e['credit']);
    final source = e['source'] as String? ?? '';
    final reference = e['reference'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.onSurface)),
                Text('$date · ${_sourceLabel(source)}${reference.isNotEmpty ? ' · #$reference' : ''}',
                    style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
              ],
            ),
          ),
          if (debit > 0)
            Text(fmtMoney(debit), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.success)),
          if (credit > 0) ...[
            if (debit > 0) const SizedBox(width: 8),
            Text(fmtMoney(credit), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DomendraTheme.danger)),
          ],
        ],
      ),
    );
  }

  List<Widget> _agingBuckets(Map<String, dynamic> aging) {
    final buckets = (aging['buckets'] as Map<String, dynamic>?) ?? {};
    final labels = ['current', '1_30', '31_60', '61_90', '90_plus'];
    final displayLabels = {
      'current': 'Current',
      '1_30': '1-30 days',
      '31_60': '31-60 days',
      '61_90': '61-90 days',
      '90_plus': '90+ days',
    };
    final colors = {
      'current': DomendraTheme.success,
      '1_30': DomendraTheme.info,
      '31_60': DomendraTheme.warning,
      '61_90': DomendraTheme.danger,
    };

    return labels.map((key) {
      final value = toDouble(buckets[key]);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (colors[key] ?? DomendraTheme.danger).withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(displayLabels[key] ?? key, style: const TextStyle(fontSize: 12, color: DomendraTheme.onSurface))),
            Text(fmtMoney(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: value > 0 ? DomendraTheme.onSurface : DomendraTheme.onSurfaceMuted)),
          ],
        ),
      );
    }).toList();
  }

  String _sourceLabel(String source) {
    const labels = {
      'rental': 'Rental',
      'payment': 'Payment',
      'charge': 'Charge',
      'fuel': 'Fuel',
      'charging': 'EV Charge',
      'idling': 'Idling',
      'service': 'Service',
      'accident': 'Accident',
      'damage': 'Damage',
      'insurance': 'Insurance',
      'depreciation': 'Depreciation',
      'lease': 'Lease',
      'financing': 'Financing',
      'purchase': 'Purchase',
      'expense': 'Expense',
    };
    return labels[source] ?? source.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}

class _MonthlyBars extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _MonthlyBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (max, m) {
      final d = toDouble(m['debit']);
      final c = toDouble(m['credit']);
      final v = d > c ? d : c;
      return v > max ? v : max;
    });

    return SizedBox(
      height: 160,
      child: data.isEmpty
          ? tabEmpty(message: 'No monthly data')
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.take(12).map((m) {
                final debit = toDouble(m['debit']);
                final credit = toDouble(m['credit']);
                final dH = maxVal > 0 ? (debit / maxVal * 120) : 0.0;
                final cH = maxVal > 0 ? (credit / maxVal * 120) : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: Container(height: dH, color: DomendraTheme.success.withValues(alpha: 0.7))),
                            const SizedBox(width: 2),
                            Expanded(child: Container(height: cH, color: DomendraTheme.danger.withValues(alpha: 0.7))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(m['month'] as String? ?? '', style: const TextStyle(fontSize: 7, color: DomendraTheme.onSurfaceMuted), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
