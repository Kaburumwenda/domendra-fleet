import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Shared helpers for report tabs — currency formatting, section titles,
/// KPI cards, and data-table builders.

/// Currency symbol — updated from DashboardProvider when the reports screen
/// loads so all `fmtMoney` calls use the tenant's configured currency.
String _currencySymbol = 'KSh';

/// Set the currency symbol used by [fmtMoney].  Called once from the
/// reports screen's `initState` via `DashboardProvider.currencySymbol`.
set reportCurrencySymbol(String symbol) => _currencySymbol = symbol;

/// Formats a number as currency with symbol.
String fmtMoney(dynamic value, {int decimals = 2}) {
  if (value == null) return '$_currencySymbol$_zeroStr(decimals)';
  final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
  if (n.abs() >= 1000000) {
    return '$_currencySymbol${(n / 1000000).toStringAsFixed(2)}M';
  }
  if (n.abs() >= 1000) {
    return '$_currencySymbol${(n / 1000).toStringAsFixed(1)}K';
  }
  return '$_currencySymbol${n.toStringAsFixed(decimals)}';
}

String _zeroStr(int decimals) => (0).toStringAsFixed(decimals);

/// Formats a number as percentage.
String fmtPct(dynamic value, {int decimals = 1}) {
  if (value == null) return '0%';
  final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
  return '${n.toStringAsFixed(decimals)}%';
}

/// Formats a plain number.
String fmtNum(dynamic value, {int decimals = 0}) {
  if (value == null) return '0';
  final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
  return n.toStringAsFixed(decimals);
}

/// Section title row with colored left bar.
Widget sectionTitle(String text) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: DomendraTheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: DomendraTheme.onSurface,
      )),
    ],
  );
}

/// KPI card for report tabs.
class ReportKpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;
  final double? trend;

  const ReportKpiCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.subtitle,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DomendraTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DomendraTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              if (trend != null) _trendChip(trend!),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DomendraTheme.onSurface,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: DomendraTheme.onSurfaceMuted,
          )),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
          ],
        ],
      ),
    );
  }

  Widget _trendChip(double t) {
    final positive = t >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (positive ? DomendraTheme.success : DomendraTheme.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.arrow_upward : Icons.arrow_downward, size: 10,
              color: positive ? DomendraTheme.success : DomendraTheme.danger),
          const SizedBox(width: 2),
          Text('${positive ? "+" : ""}${t.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: positive ? DomendraTheme.success : DomendraTheme.danger,
              )),
        ],
      ),
    );
  }
}

/// Builds a 2-column KPI grid.
Widget kpiGrid(List<ReportKpiCard> cards) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: cards.length,
    itemBuilder: (_, i) => cards[i],
  );
}

/// Report card container.
Widget reportCard({required Widget child, EdgeInsets? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DomendraTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: DomendraTheme.outline),
    ),
    child: child,
  );
}

/// Builds a data row for a list/table inside a card.
Widget dataRow(String label, String value, {Color? valueColor, bool isHeader = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
            color: isHeader ? DomendraTheme.onSurface : DomendraTheme.onSurfaceMuted,
          )),
        ),
        Text(value, style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: valueColor ?? DomendraTheme.onSurface,
        )),
      ],
    ),
  );
}

/// Loading indicator for tab content.
Widget tabLoading() =>
    const Center(child: CircularProgressIndicator(color: DomendraTheme.primary));

/// Empty state for tab content.
Widget tabEmpty({String message = 'No data available'}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: DomendraTheme.onSurfaceMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, color: DomendraTheme.onSurfaceMuted)),
        ],
      ),
    ),
  );
}

/// Parses a num from dynamic JSON value.
double toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

/// Parses an int from dynamic JSON value.
int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Divider between rows.
Widget thinDivider() =>
    const Divider(height: 1, color: DomendraTheme.outline);

/// Status chip.
Widget statusChip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: color,
    )),
  );
}
