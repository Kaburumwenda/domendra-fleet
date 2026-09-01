import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../providers/expenses_provider.dart';
import '../../utils/num_cast.dart';

/// Dialogs for the Expenses screen — mirrors web ExpenseDetailDrawer
/// and reject dialog.

/// Status color mapping (shared).
Color expenseStatusColor(String s) => switch (s) {
      'draft' => const Color(0xFF64748B),
      'submitted' => const Color(0xFFF59E0B),
      'approved' => const Color(0xFF3B82F6),
      'rejected' => const Color(0xFFEF4444),
      'paid' => const Color(0xFF10B981),
      _ => const Color(0xFF64748B),
    };

String _fmtMoney(dynamic v) => toDoubleOr(v).toStringAsFixed(2);
String _fmtInt(dynamic v) => toIntOr(v).toString();

String _fmtDate(dynamic d) {
  if (d == null || d is! String || d.isEmpty) return '—';
  try {
    final dt = DateTime.parse(d);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return d;
  }
}

String _fmtDateTime(dynamic d) {
  if (d == null || d is! String || d.isEmpty) return '—';
  try {
    final dt = DateTime.parse(d);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return d;
  }
}

// ════════════════════════════════════════════════════════════
// Expense Detail Dialog
// ════════════════════════════════════════════════════════════

/// Shows a full expense detail dialog with key facts, description,
/// audit trail, attachments, and action buttons.
Future<void> showExpenseDetail(
  BuildContext context,
  Map<String, dynamic> expense,
  ExpensesProvider provider,
) async {
  final status = expense['status'] as String? ?? 'draft';
  final sColor = expenseStatusColor(status);
  final amount = toDoubleOr(expense['amount']);
  final taxAmount = toDoubleOr(expense['tax_amount']);
  final total = toDoubleOr(expense['total_amount'] ?? expense['amount']);

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.receipt, size: 18, color: sColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(expense['title'] as String? ?? 'Expense Detail',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, size: 8, color: sColor),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(expense['expense_number'] as String? ?? '',
                      style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
                ],
              ),
              const SizedBox(height: 12),

              // Key facts
              _DetailRow('Amount', '\$${_fmtMoney(amount)}'),
              if (taxAmount > 0) _DetailRow('Tax', '\$${_fmtMoney(taxAmount)}'),
              _DetailRow('Total', '\$${_fmtMoney(total)}', bold: true),
              _DetailRow('Date', _fmtDate(expense['expense_date'])),
              _DetailRow('Category', expense['category_name'] as String? ?? '—'),
              _DetailRow('Vendor', expense['vendor_name'] as String? ?? '—'),
              _DetailRow('Payment Method', expense['payment_method_display'] as String? ?? expense['payment_method'] as String? ?? '—'),
              if (expense['payment_reference'] != null)
                _DetailRow('Reference', expense['payment_reference'] as String),
              if (expense['vehicle_name'] != null)
                _DetailRow('Vehicle', expense['vehicle_name'] as String),
              if (expense['contact_name'] != null)
                _DetailRow('Contact', expense['contact_name'] as String),

              // Rejection reason
              if (status == 'rejected' && expense['rejection_reason'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DomendraTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DomendraTheme.danger.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: DomendraTheme.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Rejected: ${expense['rejection_reason']}',
                            style: const TextStyle(fontSize: 11, color: DomendraTheme.danger)),
                      ),
                    ],
                  ),
                ),
              ],

              // Description
              if (expense['description'] != null && (expense['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
                const SizedBox(height: 4),
                Text(expense['description'] as String, style: const TextStyle(fontSize: 12)),
              ],

              // Tags
              if (expense['tags'] != null && (expense['tags'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: (expense['tags'] as String)
                      .split(',')
                      .map((t) => Chip(label: Text(t.trim(), style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact))
                      .toList(),
                ),
              ],

              // Audit trail
              ..._buildAuditTrail(expense),

              // Attachments
              if (expense['attachments'] != null) ...[
                const SizedBox(height: 12),
                const Text('Attachments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
                const SizedBox(height: 4),
                ...(expense['attachments'] as List).map((a) {
                  final att = a as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: DomendraTheme.scaffoldBg, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 14, color: DomendraTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(att['filename'] as String? ?? 'File', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }),
              ],

              // Comments
              if (expense['comments'] != null && (expense['comments'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Comments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)),
                const SizedBox(height: 4),
                ...(expense['comments'] as List).map((c) {
                  final cm = c as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: DomendraTheme.scaffoldBg, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: DomendraTheme.primary.withOpacity(0.12),
                          child: Text(cm['author_initials'] as String? ?? '?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: DomendraTheme.primary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cm['author_name'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              Text(cm['body'] as String? ?? '', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(_fmtDateTime(cm['created_at']), style: const TextStyle(fontSize: 9, color: DomendraTheme.onSurfaceMuted)),
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
        // Workflow actions
        if (status == 'draft')
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              provider.submitExpense(expense['id'] as int);
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Submit'),
          ),
        if (status == 'submitted') ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: DomendraTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              showRejectDialog(context, expense, provider);
            },
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: DomendraTheme.success),
            onPressed: () {
              Navigator.pop(ctx);
              provider.approveExpense(expense['id'] as int);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Approve'),
          ),
        ],
        if (status == 'approved')
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: DomendraTheme.success),
            onPressed: () {
              Navigator.pop(ctx);
              provider.markPaidExpense(expense['id'] as int);
            },
            icon: const Icon(Icons.paid, size: 16),
            label: const Text('Mark Paid'),
          ),
      ],
    ),
  );
}

List<Widget> _buildAuditTrail(Map<String, dynamic> expense) {
  final trail = <Widget>[];
  final events = <_AuditEvent>[];

  if (expense['created_at'] != null) {
    events.add(_AuditEvent('Created', _fmtDateTime(expense['created_at']), expense['created_by_name'] as String?));
  }
  if (expense['submitted_at'] != null) {
    events.add(_AuditEvent('Submitted', _fmtDateTime(expense['submitted_at']), expense['submitted_by_name'] as String?));
  }
  if (expense['approved_at'] != null) {
    events.add(_AuditEvent(expense['status'] == 'rejected' ? 'Rejected' : 'Approved', _fmtDateTime(expense['approved_at']), expense['approved_by_name'] as String?));
  }
  if (expense['paid_at'] != null) {
    events.add(_AuditEvent('Paid', _fmtDateTime(expense['paid_at']), null));
  }

  if (events.isEmpty) return trail;

  trail.add(const SizedBox(height: 12));
  trail.add(const Text('Audit Trail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DomendraTheme.onSurfaceMuted)));
  trail.add(const SizedBox(height: 4));

  for (final e in events) {
    trail.add(Row(
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: DomendraTheme.primary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('${e.label}: ${e.date}${e.by != null ? ' • ${e.by}' : ''}', style: const TextStyle(fontSize: 10, color: DomendraTheme.onSurfaceMuted)),
        ),
      ],
    ));
  }
  return trail;
}

class _AuditEvent {
  final String label, date;
  final String? by;
  _AuditEvent(this.label, this.date, this.by);
}

// ════════════════════════════════════════════════════════════
// Reject Dialog
// ════════════════════════════════════════════════════════════

/// Shows a reject dialog asking for a reason, then calls provider.rejectExpense.
Future<void> showRejectDialog(
  BuildContext context,
  Map<String, dynamic> expense,
  ExpensesProvider provider,
) async {
  final reasonCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: DomendraTheme.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.cancel, size: 18, color: DomendraTheme.danger),
        ),
        const SizedBox(width: 10),
        const Text('Reject Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expense: ${expense['title']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              hintText: 'Enter the reason for rejection…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: DomendraTheme.danger),
          onPressed: () {
            final reason = reasonCtrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(ctx);
            provider.rejectExpense(expense['id'] as int, reason);
          },
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Reject'),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
// Expense Form Dialog
// ════════════════════════════════════════════════════════════

/// Shows a create/edit expense form dialog. Returns `true` if saved.
Future<bool> showExpenseFormDialog(
  BuildContext context,
  ExpensesProvider provider, {
  Map<String, dynamic>? editing,
}) async {
  final isEdit = editing != null;
  final titleCtrl = TextEditingController(text: editing?['title'] as String? ?? '');
  final amountCtrl = TextEditingController(text: editing?['amount'] != null ? _fmtMoney(editing!['amount']) : '');
  final taxCtrl = TextEditingController(text: editing?['tax_rate'] != null ? _fmtMoney(editing!['tax_rate']) : '0');
  final vendorCtrl = TextEditingController(text: editing?['vendor_name'] as String? ?? '');
  final descCtrl = TextEditingController(text: editing?['description'] as String? ?? '');
  final refCtrl = TextEditingController(text: editing?['payment_reference'] as String? ?? '');
  final tagsCtrl = TextEditingController(text: editing?['tags'] as String? ?? '');

  String? categoryId = editing?['category']?.toString();
  int? vehicleId = editing?['vehicle'] as int?;
  int? contactId = editing?['contact'] as int?;
  String paymentMethod = editing?['payment_method'] as String? ?? 'card';
  var expenseDate = editing?['expense_date'] as String? ?? DateTime.now().toIso8601String().split('T').first;
  bool isBillable = editing?['is_billable'] as bool? ?? false;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: DomendraTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(isEdit ? Icons.edit : Icons.add, size: 18, color: DomendraTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(isEdit ? 'Edit Expense' : 'New Expense', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount *', prefixText: '\$', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: taxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tax Rate', suffixText: '%', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), isDense: true),
                  items: provider.categories.map((c) {
                    final cm = c as Map<String, dynamic>;
                    return DropdownMenuItem(value: '${cm['id']}', child: Text(cm['name'] as String? ?? '', overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vendorCtrl,
                  decoration: const InputDecoration(labelText: 'Vendor Name', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.tryParse(expenseDate) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => expenseDate = picked.toIso8601String().split('T').first);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), isDense: true, suffixIcon: Icon(Icons.calendar_today, size: 16)),
                    child: Text(expenseDate),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'mobile', child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'check', child: Text('Check')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => paymentMethod = v ?? 'card'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: vehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle (optional)', border: OutlineInputBorder(), isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...provider.vehicles.map((v) {
                      final vm = v as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: vm['id'] as int?,
                        child: Text(vm['name'] as String? ?? vm['license_plate'] as String? ?? 'Vehicle #${vm['id']}', overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => vehicleId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: contactId,
                  decoration: const InputDecoration(labelText: 'Contact (optional)', border: OutlineInputBorder(), isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...provider.contacts.map((c) {
                      final cm = c as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: cm['id'] as int?,
                        child: Text(cm['full_name'] as String? ?? cm['name'] as String? ?? 'Contact #${cm['id']}', overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => contactId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'Payment Reference', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(labelText: 'Tags (comma-separated)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  title: const Text('Billable', style: TextStyle(fontSize: 13)),
                  value: isBillable,
                  onChanged: (v) => setState(() => isBillable = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) return;
              final data = <String, dynamic>{
                'title': titleCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0,
                'tax_rate': double.tryParse(taxCtrl.text) ?? 0,
                if (categoryId != null) 'category': int.parse(categoryId!),
                'vendor_name': vendorCtrl.text.trim(),
                'expense_date': expenseDate,
                'payment_method': paymentMethod,
                'payment_reference': refCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'tags': tagsCtrl.text.trim(),
                'is_billable': isBillable,
                if (vehicleId != null) 'vehicle': vehicleId,
                if (contactId != null) 'contact': contactId,
              };
              Navigator.pop(ctx, true);
              provider.saveExpense(data, id: isEdit ? editing!['id'] as int : null);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

// ── Helper widget ──────────────────────────────────────────

Widget _DetailRow(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted)),
          Text(value, style: TextStyle(fontSize: bold ? 13 : 11, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
