import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../providers/billing_provider.dart';
import '../../utils/num_cast.dart';

/// Dialogs for the Billing screen — mirrors web payment dialog and
/// bill-detail dialog.

const Map<String, String> _currencySymbols = {
  'USD': r'$', 'EUR': '€', 'GBP': '£', 'KES': 'KSh', 'NGN': '₦', 'ZAR': 'R',
  'AED': 'AED', 'SAR': 'SAR', 'INR': '₹', 'CAD': r'C$', 'AUD': r'A$',
  'JPY': '¥', 'CNY': '¥', 'BRL': r'R$', 'GHS': '₵', 'TZS': 'TSh',
  'UGX': 'USh', 'RWF': 'FRw', 'ETB': 'Br',
};

String symbolFor(String? code) {
  if (code == null || code.isEmpty) return r'$';
  return _currencySymbols[code.toUpperCase()] ?? code.toUpperCase();
}

/// Bill status → color (mirrors web `billStatusColor`).
Color billStatusColor(String s) => switch (s) {
      'paid' => const Color(0xFF10B981),
      'unpaid' => const Color(0xFFF59E0B),
      'overdue' => const Color(0xFFEF4444),
      'void' => const Color(0xFF94A3B8),
      _ => const Color(0xFF94A3B8),
    };

/// Bill status → icon (mirrors web `billStatusIcon`).
IconData billStatusIcon(String s) => switch (s) {
      'paid' => Icons.check_circle,
      'unpaid' => Icons.access_time,
      'overdue' => Icons.error,
      'void' => Icons.cancel,
      _ => Icons.help_outline,
    };

String fmtMoney(dynamic v) {
  final n = toDoubleOr(v);
  return n.toStringAsFixed(2);
}

String fmtInt(dynamic v) {
  final n = toIntOr(v);
  return n.toString();
}

String fmtDate(dynamic d) {
  if (d == null || d is! String || d.isEmpty) return '—';
  try {
    final dt = DateTime.parse(d);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return d;
  }
}

String fmtMonth(dynamic d) {
  if (d == null || d is! String || d.isEmpty) return '—';
  try {
    final dt = DateTime.parse(d);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return d;
  }
}

String fmtRate(dynamic v) {
  final n = toDoubleOr(v);
  return n.toStringAsFixed(2);
}

// ════════════════════════════════════════════════════════════
// Payment dialog
// ════════════════════════════════════════════════════════════

/// Shows a payment dialog for the given bill. Returns `true` if the
/// payment was recorded successfully.
Future<bool> showBillingPaymentDialog(
  BuildContext context, {
  required Map<String, dynamic> bill,
  required BillingProvider provider,
}) async {
  final currency = bill['billing_currency'] as String? ?? 'USD';
  final curSym = symbolFor(currency);
  final balanceDue = toDoubleOr(
    bill['balance_due'] != null
        ? bill['balance_due']
        : bill['grand_total_usd'] ?? bill['grand_total'],
  );

  final amountCtrl = TextEditingController(text: balanceDue.toStringAsFixed(2));
  final refCtrl = TextEditingController();
  String method = 'card';

  return await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: DomendraTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.payments, size: 18, color: DomendraTheme.primary),
              ),
              const SizedBox(width: 10),
              const Text('Make a Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bill summary
                    _infoRow('Invoice', bill['invoice_number'] as String? ?? '—'),
                    _infoRow('Billing Month', fmtMonth(bill['billing_month'])),
                    _infoRow('Total Requests', fmtInt(bill['total_requests'])),
                    const SizedBox(height: 6),
                    _infoRowBold('Amount Due (USD)', '\$${fmtMoney(balanceDue)}'),
                    if (currency != 'USD') ...[
                      _infoRowBold(
                        'Amount Due ($currency)',
                        '$curSym${fmtMoney(bill['balance_due_local'] ?? bill['grand_total_local'])}',
                      ),
                    ],
                    const Divider(height: 20),

                    // Payment form
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (USD)',
                        prefixText: r'$ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => method = v ?? 'card'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reference (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: provider.paying
                    ? null
                    : () async {
                        final amt = double.tryParse(amountCtrl.text) ?? 0;
                        if (amt <= 0) return;
                        try {
                          await provider.payBill(
                            bill['id'] as int,
                            amount: amt,
                            method: method,
                            reference: refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : null,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (_) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                icon: provider.paying
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(provider.paying ? 'Processing…' : 'Pay \$${fmtMoney(amountCtrl.text)}'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}

// ════════════════════════════════════════════════════════════
// Bill detail dialog
// ════════════════════════════════════════════════════════════

/// Shows a full bill detail dialog, fetched from the backend.
/// If [bill] already contains a `payments` array it is shown directly;
/// otherwise a fresh fetch is made.
Future<void> showBillingBillDetailDialog(
  BuildContext context, {
  required Map<String, dynamic> bill,
  required BillingProvider provider,
}) async {
  Map<String, dynamic> detail = bill;

  // Fetch full detail if payments aren't already loaded
  if (!bill.containsKey('payments')) {
    try {
      detail = await provider.fetchBillDetail(bill['id'] as int);
    } catch (_) {
      detail = bill;
    }
  }

  if (!context.mounted) return;

  final currency = detail['billing_currency'] as String? ?? 'USD';
  final curSym = symbolFor(currency);
  final status = detail['status'] as String? ?? 'unpaid';
  final sColor = billStatusColor(status);
  final payments = detail['payments'] as List<dynamic>? ?? [];
  final balanceDue = toDoubleOr(
    detail['balance_due'] != null ? detail['balance_due'] : detail['grand_total_usd'],
  );

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: DomendraTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.receipt_long, size: 18, color: DomendraTheme.primary),
        ),
        const SizedBox(width: 10),
        const Text('Invoice Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Invoice number + status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice Number',
                            style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                        Text(detail['invoice_number'] as String? ?? '—',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Status', style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: sColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(billStatusIcon(status), size: 12, color: sColor),
                          const SizedBox(width: 4),
                          Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              _infoRow('Billing Month', fmtMonth(detail['billing_month'])),
              _infoRow('Period', '${fmtDate(detail['period_start'])} – ${fmtDate(detail['period_end'])}'),
              _infoRow('Total Requests', fmtInt(detail['total_requests'])),
              const Divider(height: 20),

              // USD breakdown
              Text('Cost Breakdown (USD)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _infoRow('Usage Cost (\$${fmtMoney(detail['rate_per_1000_usd'])}/1k)', '\$${fmtMoney(detail['usage_cost_usd'])}'),
              _infoRow('Tax', '\$${fmtMoney(detail['tax_amount_usd'])}'),
              _infoRowBold('Grand Total (USD)', '\$${fmtMoney(detail['grand_total_usd'] ?? detail['grand_total'])}'),
              _infoRow('Paid', '\$${fmtMoney(detail['paid_amount'])}'),
              _infoRowBold(
                'Balance Due (USD)',
                '\$${fmtMoney(balanceDue)}',
                valueColor: balanceDue > 0 ? DomendraTheme.danger : const Color(0xFF10B981),
              ),

              // Local currency breakdown
              if (currency != 'USD') ...[
                const Divider(height: 20),
                Text('Cost Breakdown ($currency)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('@ rate ${fmtRate(detail['exchange_rate'])}',
                    style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                const SizedBox(height: 8),
                _infoRow('Usage Cost', '$curSym${fmtMoney(detail['usage_cost'] ?? detail['usage_cost_local'])}'),
                _infoRow('Tax', '$curSym${fmtMoney(detail['tax_amount_local'] ?? detail['tax_amount'])}'),
                _infoRowBold('Grand Total ($currency)',
                    '$curSym${fmtMoney(detail['grand_total_local'] ?? detail['grand_total'])}'),
                _infoRow('Paid',
                    '$curSym${fmtMoney(detail['paid_amount_local'] ?? detail['paid_amount'])}'),
                _infoRowBold('Balance Due ($currency)',
                    '$curSym${fmtMoney(detail['balance_due_local'] ?? 0)}',
                    valueColor: toDoubleOr(detail['balance_due_local']) > 0
                        ? DomendraTheme.danger
                        : const Color(0xFF10B981)),
              ],

              // Payment history
              if (payments.isNotEmpty) ...[
                const Divider(height: 20),
                Text('Payment History',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...payments.map((p) {
                  final pmt = p as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DomendraTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('\$${fmtMoney(pmt['amount'])} via ${pmt['method'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(
                                '${fmtDate(pmt['created_at'])}${pmt['reference'] != null ? ' · ${pmt['reference']}' : ''}',
                                style: TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Paid',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        if (status == 'unpaid' || status == 'overdue')
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              showBillingPaymentDialog(context, bill: detail, provider: provider);
            },
            icon: const Icon(Icons.payment),
            label: const Text('Pay Now'),
          ),
      ],
    ),
  );
}

// ── Small helper widgets ───────────────────────────────────

Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: DomendraTheme.onSurfaceMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );

Widget _infoRowBold(String label, String value, {Color? valueColor}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
