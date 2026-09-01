import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Invoices provider — drives the Invoices screen.
class InvoicesProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _invoices = [];
  bool _loading = false;
  String? _error;

  List<dynamic> get invoices => _invoices;
  bool get loading => _loading;
  String? get error => _error;

  int get total => _invoices.length;

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  double get totalAmount => _invoices.fold<double>(0, (s, inv) => s + _num((inv as Map)['total_amount']));
  double get totalPaid => _invoices.fold<double>(0, (s, inv) => s + _num((inv as Map)['amount_paid']));
  double get totalOutstanding => _invoices.fold<double>(0, (s, inv) => s + _num((inv as Map)['balance']));
  int get pendingCount => _invoices.where((i) => (i as Map)['status'] == 'pending' || (i as Map)['status'] == 'sent').length;
  int get paidCount => _invoices.where((i) => (i as Map)['status'] == 'paid').length;
  int get overdueCount => _invoices.where((i) => (i as Map)['status'] == 'overdue').length;

  Future<void> fetchAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _invoices = await _api.fetchInvoices();
    } catch (e) {
      _error = e.toString();
      debugPrint('Invoices fetch failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.createInvoice(data);
    await fetchAll();
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await _api.updateInvoice(id, data);
    await fetchAll();
  }

  Future<void> delete(int id) async {
    await _api.deleteInvoice(id);
    await fetchAll();
  }

  Future<void> createFromAgreement(int agreementId) async {
    await _api.createInvoiceFromAgreement(agreementId);
    await fetchAll();
  }
}
