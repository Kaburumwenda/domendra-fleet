import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../models/lessor_model.dart';
import '../../../providers/lessor_provider.dart';
import '../../../services/api_service.dart';

/// Lessors dialogs — mirrors the web page's 4 dialogs:
///  1. Lessor Form (create/edit)
///  2. Contract Form (create/edit)
///  3. Payment Form (create/edit)
///  4. Document Form (upload)

// ════════════════════════════════════════════════════════════
// 1. LESSOR FORM DIALOG
// ════════════════════════════════════════════════════════════
void showLessorFormDialog(BuildContext context, Lessor? lessor) {
  showDialog(
    context: context,
    builder: (ctx) => _LessorFormDialog(lessor: lessor),
  );
}

class _LessorFormDialog extends StatefulWidget {
  final Lessor? lessor;
  const _LessorFormDialog({this.lessor});

  @override
  State<_LessorFormDialog> createState() => _LessorFormDialogState();
}

class _LessorFormDialogState extends State<_LessorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{};
  bool _saving = false;
  String _lessorType = 'individual';

  @override
  void initState() {
    super.initState();
    if (widget.lessor != null) {
      _data.addAll(widget.lessor!.raw);
      _lessorType = widget.lessor!.lessorType == LessorType.company ? 'company' : 'individual';
    } else {
      _data['is_active'] = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _data['lessor_type'] = _lessorType;
    setState(() => _saving = true);
    try {
      final provider = context.read<LessorProvider>();
      if (widget.lessor != null && widget.lessor!.id != null) {
        await provider.updateLessor(widget.lessor!.id!, _data);
      } else {
        await provider.createLessor(_data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.lessor != null ? 'Lessor updated' : 'Lessor created'), backgroundColor: DomendraTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lessor != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Lessor' : 'Add Lessor'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'individual', label: Text('Individual'), icon: Icon(Icons.person)),
                    ButtonSegment(value: 'company', label: Text('Company'), icon: Icon(Icons.business)),
                  ],
                  selected: {_lessorType},
                  onSelectionChanged: (s) => setState(() => _lessorType = s.first),
                ),
                const SizedBox(height: 12),
                if (_lessorType == 'individual') ...[
                  TextFormField(
                    initialValue: _data['first_name']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'First Name *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => _data['first_name'] = v,
                  ),
                  TextFormField(
                    initialValue: _data['middle_name']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Middle Name'),
                    onChanged: (v) => _data['middle_name'] = v,
                  ),
                  TextFormField(
                    initialValue: _data['last_name']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    onChanged: (v) => _data['last_name'] = v,
                  ),
                  TextFormField(
                    initialValue: _data['national_id']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'National ID'),
                    onChanged: (v) => _data['national_id'] = v,
                  ),
                ] else ...[
                  TextFormField(
                    initialValue: _data['company_name']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Company Name *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    onChanged: (v) => _data['company_name'] = v,
                  ),
                  TextFormField(
                    initialValue: _data['representative_name']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Representative Name'),
                    onChanged: (v) => _data['representative_name'] = v,
                  ),
                  TextFormField(
                    initialValue: _data['registration_number']?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Registration Number'),
                    onChanged: (v) => _data['registration_number'] = v,
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _data['email']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => _data['email'] = v,
                ),
                TextFormField(
                  initialValue: _data['phone']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => _data['phone'] = v,
                ),
                TextFormField(
                  initialValue: _data['country']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Country'),
                  onChanged: (v) => _data['country'] = v,
                ),
                TextFormField(
                  initialValue: _data['tax_id']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Tax ID'),
                  onChanged: (v) => _data['tax_id'] = v,
                ),
                TextFormField(
                  initialValue: _data['address']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                  onChanged: (v) => _data['address'] = v,
                ),
                TextFormField(
                  initialValue: _data['bank_account']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Bank Account'),
                  onChanged: (v) => _data['bank_account'] = v,
                ),
                TextFormField(
                  initialValue: _data['payment_terms']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Payment Terms'),
                  onChanged: (v) => _data['payment_terms'] = v,
                ),
                TextFormField(
                  initialValue: _data['contract_start_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Contract Start (YYYY-MM-DD)'),
                  onChanged: (v) => _data['contract_start_date'] = v,
                ),
                TextFormField(
                  initialValue: _data['contract_end_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Contract End (YYYY-MM-DD)'),
                  onChanged: (v) => _data['contract_end_date'] = v,
                ),
                TextFormField(
                  initialValue: _data['notes']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  onChanged: (v) => _data['notes'] = v,
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _data['is_active'] == true,
                  onChanged: (v) => setState(() => _data['is_active'] = v),
                  activeColor: DomendraTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 2. CONTRACT FORM DIALOG
// ════════════════════════════════════════════════════════════
void showContractFormDialog(BuildContext context, LessorContract? contract) {
  showDialog(
    context: context,
    builder: (ctx) => _ContractFormDialog(contract: contract),
  );
}

class _ContractFormDialog extends StatefulWidget {
  final LessorContract? contract;
  const _ContractFormDialog({this.contract});

  @override
  State<_ContractFormDialog> createState() => _ContractFormDialogState();
}

class _ContractFormDialogState extends State<_ContractFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{};
  bool _saving = false;
  int? _lessorId;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      _data.addAll(widget.contract!.raw);
      _lessorId = widget.contract!.lessorId;
    } else {
      _data['status'] = 'draft';
      _data['monthly_rate'] = 0;
      _data['deposit_amount'] = 0;
      _data['payment_frequency'] = 'monthly';
      _data['currency'] = 'USD';
      _data['insurance_required'] = true;
      _data['auto_renew'] = false;
      _data['title'] = 'Lease Agreement';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lessorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a lessor'), backgroundColor: DomendraTheme.warning));
      return;
    }
    _data['lessor'] = _lessorId;
    setState(() => _saving = true);
    try {
      final provider = context.read<LessorProvider>();
      if (widget.contract != null && widget.contract!.id != null) {
        await provider.updateContract(widget.contract!.id!, _data);
      } else {
        await provider.createContract(_data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.contract != null ? 'Contract updated' : 'Contract created'), backgroundColor: DomendraTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<LessorProvider>();
    final isEdit = widget.contract != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Contract' : 'New Contract'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _lessorId,
                  decoration: const InputDecoration(labelText: 'Lessor *'),
                  items: p.lessors.map((l) {
                    return DropdownMenuItem(value: l.id, child: Text(l.displayName));
                  }).toList(),
                  onChanged: (v) => setState(() => _lessorId = v),
                ),
                TextFormField(
                  initialValue: _data['title']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (v) => _data['title'] = v,
                ),
                TextFormField(
                  initialValue: _data['contract_number']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Contract Number'),
                  onChanged: (v) => _data['contract_number'] = v,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _data['status']?.toString() ?? 'draft',
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    DropdownMenuItem(value: 'terminated', child: Text('Terminated')),
                  ],
                  onChanged: (v) => _data['status'] = v,
                ),
                TextFormField(
                  initialValue: _data['start_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
                  onChanged: (v) => _data['start_date'] = v,
                ),
                TextFormField(
                  initialValue: _data['end_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
                  onChanged: (v) => _data['end_date'] = v,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _data['payment_frequency']?.toString() ?? 'monthly',
                  decoration: const InputDecoration(labelText: 'Payment Frequency'),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(value: 'annually', child: Text('Annually')),
                  ],
                  onChanged: (v) => _data['payment_frequency'] = v,
                ),
                TextFormField(
                  initialValue: _data['monthly_rate']?.toString() ?? '0',
                  decoration: const InputDecoration(labelText: 'Monthly Rate'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['monthly_rate'] = double.tryParse(v) ?? 0,
                ),
                TextFormField(
                  initialValue: _data['deposit_amount']?.toString() ?? '0',
                  decoration: const InputDecoration(labelText: 'Deposit Amount'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['deposit_amount'] = double.tryParse(v) ?? 0,
                ),
                TextFormField(
                  initialValue: _data['mileage_limit']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Mileage Limit (monthly)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['mileage_limit'] = int.tryParse(v),
                ),
                TextFormField(
                  initialValue: _data['maintenance_responsibility']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Maintenance Responsibility'),
                  onChanged: (v) => _data['maintenance_responsibility'] = v,
                ),
                TextFormField(
                  initialValue: _data['signed_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Signed Date'),
                  onChanged: (v) => _data['signed_date'] = v,
                ),
                SwitchListTile(
                  title: const Text('Insurance Required'),
                  value: _data['insurance_required'] == true,
                  onChanged: (v) => setState(() => _data['insurance_required'] = v),
                  activeColor: DomendraTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Auto Renew'),
                  value: _data['auto_renew'] == true,
                  onChanged: (v) => setState(() => _data['auto_renew'] = v),
                  activeColor: DomendraTheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                TextFormField(
                  initialValue: _data['terms']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Terms'),
                  maxLines: 3,
                  onChanged: (v) => _data['terms'] = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 3. PAYMENT FORM DIALOG
// ════════════════════════════════════════════════════════════
/// [paymentOrLessor]: can be a LessorPayment (edit mode), Lessor (pre-fill lessor), or null (create new).
void showPaymentFormDialog(BuildContext context, dynamic paymentOrLessor) {
  showDialog(
    context: context,
    builder: (ctx) => _PaymentFormDialog(item: paymentOrLessor),
  );
}

class _PaymentFormDialog extends StatefulWidget {
  final dynamic item;
  const _PaymentFormDialog({this.item});

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _data = <String, dynamic>{};
  bool _saving = false;
  int? _lessorId;

  @override
  void initState() {
    super.initState();
    if (widget.item is LessorPayment) {
      final p = widget.item as LessorPayment;
      _data.addAll(p.raw);
      _lessorId = p.lessorId;
    } else if (widget.item is Lessor) {
      _lessorId = (widget.item as Lessor).id;
      _data['status'] = 'pending';
      _data['currency'] = 'USD';
      _data['payment_method'] = 'bank_transfer';
    } else {
      _data['status'] = 'pending';
      _data['currency'] = 'USD';
      _data['payment_method'] = 'bank_transfer';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lessorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a lessor'), backgroundColor: DomendraTheme.warning));
      return;
    }
    _data['lessor'] = _lessorId;
    setState(() => _saving = true);
    try {
      final provider = context.read<LessorProvider>();
      final isEdit = widget.item is LessorPayment && (widget.item as LessorPayment).id != null;
      if (isEdit) {
        await provider.updatePayment((widget.item as LessorPayment).id!, _data);
      } else {
        await provider.createPayment(_data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Payment updated' : 'Payment recorded'), backgroundColor: DomendraTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<LessorProvider>();
    final isEdit = widget.item is LessorPayment && (widget.item as LessorPayment).id != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Payment' : 'Record Payment'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _lessorId,
                  decoration: const InputDecoration(labelText: 'Lessor *'),
                  items: p.lessors.map((l) {
                    return DropdownMenuItem(value: l.id, child: Text(l.displayName));
                  }).toList(),
                  onChanged: (v) => setState(() => _lessorId = v),
                ),
                TextFormField(
                  initialValue: _data['invoice_number']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Invoice Number'),
                  onChanged: (v) => _data['invoice_number'] = v,
                ),
                TextFormField(
                  initialValue: _data['amount']?.toString() ?? '0',
                  decoration: const InputDecoration(labelText: 'Amount *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Required' : null,
                  onChanged: (v) => _data['amount'] = double.tryParse(v) ?? 0,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _data['status']?.toString() ?? 'pending',
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (v) => _data['status'] = v,
                ),
                TextFormField(
                  initialValue: _data['due_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
                  onChanged: (v) => _data['due_date'] = v,
                ),
                TextFormField(
                  initialValue: _data['paid_date']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Paid Date (YYYY-MM-DD)'),
                  onChanged: (v) => _data['paid_date'] = v,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _data['payment_method']?.toString() ?? 'bank_transfer',
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'check', child: Text('Check')),
                    DropdownMenuItem(value: 'wire', child: Text('Wire')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => _data['payment_method'] = v,
                ),
                TextFormField(
                  initialValue: _data['reference']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Reference'),
                  onChanged: (v) => _data['reference'] = v,
                ),
                TextFormField(
                  initialValue: _data['notes']?.toString() ?? '',
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  onChanged: (v) => _data['notes'] = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? 'Update' : 'Record'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// 4. DOCUMENT FORM DIALOG
// ════════════════════════════════════════════════════════════
void showDocumentFormDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _DocumentFormDialog(),
  );
}

class _DocumentFormDialog extends StatefulWidget {
  const _DocumentFormDialog();

  @override
  State<_DocumentFormDialog> createState() => _DocumentFormDialogState();
}

class _DocumentFormDialogState extends State<_DocumentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _lessorId;
  String _docType = 'other';
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _expiresController = TextEditingController();
  final _fileUrlController = TextEditingController();
  String? _filePath;
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lessorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a lessor'), backgroundColor: DomendraTheme.warning));
      return;
    }
    setState(() => _saving = true);
    try {
      final formData = FormData.fromMap({
        'lessor': _lessorId,
        'document_type': _docType,
        'name': _nameController.text,
        'description': _descController.text,
        'expires_at': _expiresController.text.isNotEmpty ? _expiresController.text : null,
        'file_url': _fileUrlController.text.isNotEmpty ? _fileUrlController.text : null,
        if (_filePath != null) 'file': await MultipartFile.fromFile(_filePath!),
      });
      // Submit formData to API — requires createDocument endpoint
      final api = ApiService.instance;
      await api.createLessorDocument(formData);
      if (mounted) {
        await context.read<LessorProvider>().refreshDocuments();
      }
      // Use api directly since provider doesn't have createDocument
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded'), backgroundColor: DomendraTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: DomendraTheme.danger));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<LessorProvider>();
    return AlertDialog(
      title: const Text('Upload Document'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _lessorId,
                  decoration: const InputDecoration(labelText: 'Lessor *'),
                  items: p.lessors.map((l) {
                    return DropdownMenuItem(value: l.id, child: Text(l.displayName));
                  }).toList(),
                  onChanged: (v) => setState(() => _lessorId = v),
                ),
                DropdownButtonFormField<String>(
                  value: _docType,
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: const [
                    DropdownMenuItem(value: 'contract', child: Text('Contract')),
                    DropdownMenuItem(value: 'insurance', child: Text('Insurance')),
                    DropdownMenuItem(value: 'registration', child: Text('Registration')),
                    DropdownMenuItem(value: 'license', child: Text('License')),
                    DropdownMenuItem(value: 'tax', child: Text('Tax')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _docType = v ?? 'other'),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _expiresController,
                  decoration: const InputDecoration(labelText: 'Expires At (YYYY-MM-DD)'),
                ),
                TextFormField(
                  controller: _fileUrlController,
                  decoration: const InputDecoration(labelText: 'File URL (external)'),
                ),
                const SizedBox(height: 8),
                if (_filePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('File: ${_filePath!.split('/').last}', style: const TextStyle(fontSize: 12, color: DomendraTheme.success)),
                  ),
                // File picker would require a plugin; for now, file_url is the primary input.
                // If file upload is needed, image_picker or file_picker can be added.
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Upload'),
        ),
      ],
    );
  }
}
