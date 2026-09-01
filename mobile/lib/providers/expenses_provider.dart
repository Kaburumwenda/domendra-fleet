import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/num_cast.dart';

/// Expenses provider — drives the Expenses screen (Overview / Records / Approvals / Recurring / Budgets / Categories).
class ExpensesProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  List<dynamic> _expenses = [];
  Map<String, dynamic> _summary = {};
  List<dynamic> _categories = [];
  List<dynamic> _vehicles = [];
  List<dynamic> _contacts = [];
  List<dynamic> _recurring = [];
  List<dynamic> _budgets = [];
  Map<String, dynamic> _budgetSummary = {};
  bool _loading = false;
  String? _error;

  List<dynamic> get expenses => _expenses;
  Map<String, dynamic> get summary => _summary;
  List<dynamic> get categories => _categories;
  List<dynamic> get vehicles => _vehicles;
  List<dynamic> get contacts => _contacts;
  List<dynamic> get recurring => _recurring;
  List<dynamic> get budgets => _budgets;
  Map<String, dynamic> get budgetSummary => _budgetSummary;
  bool get loading => _loading;
  String? get error => _error;

  // ── Summary getters ───────────────────────────────────────
  String get totalAmount => _summary['total_amount'] as String? ?? '0.00';
  int get totalCount => _summary['total_count'] as int? ?? 0;
  int get pendingCount => _summary['pending'] as int? ?? 0;
  int get rejectedCount => _summary['rejected'] as int? ?? 0;
  int get paidCount => _summary['paid'] as int? ?? 0;
  String get billableTotal => _summary['billable_total'] as String? ?? '0.00';
  List<dynamic> get byCategory => _summary['by_category'] as List<dynamic>? ?? [];
  List<dynamic> get byStatus => _summary['by_status'] as List<dynamic>? ?? [];
  List<dynamic> get monthly => _summary['monthly'] as List<dynamic>? ?? [];
  List<dynamic> get topVendors => _summary['top_vendors'] as List<dynamic>? ?? [];

  // ── Pending approvals: draft or submitted ─────────────────
  List<dynamic> get pendingApprovals => _expenses.where((e) {
    final status = (e as Map<String, dynamic>)['status'] as String? ?? 'draft';
    return status == 'draft' || status == 'submitted';
  }).toList();

  // ── Recent expenses (6 most recent) ────────────────────────
  List<dynamic> get recentExpenses {
    final sorted = List<dynamic>.from(_expenses);
    sorted.sort((a, b) {
      final aDate = (a as Map<String, dynamic>)['created_at'] as String? ?? '';
      final bDate = (b as Map<String, dynamic>)['created_at'] as String? ?? '';
      return bDate.compareTo(aDate);
    });
    return sorted.take(6).toList();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchExpenses(),
        _api.fetchExpenseSummary(),
        _api.fetchExpenseCategories(),
        _api.fetchVehiclesList(),
        _api.fetchContacts(),
        _api.fetchExpenseRecurring(),
        _api.fetchExpenseBudgets(),
      ]);
      _expenses = results[0] as List<dynamic>;
      _summary = results[1] as Map<String, dynamic>;
      _categories = results[2] as List<dynamic>;
      _vehicles = results[3] as List<dynamic>;
      _contacts = results[4] as List<dynamic>;
      _recurring = results[5] as List<dynamic>;
      _budgets = results[6] as List<dynamic>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Expense CRUD ──────────────────────────────────────────
  Future<void> saveExpense(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await _api.updateExpense(id, data);
    } else {
      await _api.createExpense(data);
    }
    await refresh();
  }

  Future<void> deleteExpense(int id) async {
    await _api.deleteExpense(id);
    await refresh();
  }

  Future<void> seedDemo() async {
    await _api.seedExpensesDemo();
    await refresh();
  }

  // ── Workflow ──────────────────────────────────────────────
  Future<void> submitExpense(int id) async {
    await _api.submitExpense(id);
    await refresh();
  }

  Future<void> approveExpense(int id) async {
    await _api.approveExpense(id);
    await refresh();
  }

  Future<void> rejectExpense(int id, String reason) async {
    await _api.rejectExpense(id, reason);
    await refresh();
  }

  Future<void> markPaidExpense(int id, {String? paymentReference}) async {
    await _api.markPaidExpense(id, paymentReference: paymentReference);
    await refresh();
  }

  // ── Categories CRUD ───────────────────────────────────────
  Future<void> saveCategory(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await _api.updateExpenseCategory(id, data);
    } else {
      await _api.createExpenseCategory(data);
    }
    await refresh();
  }

  Future<void> deleteCategory(int id) async {
    await _api.deleteExpenseCategory(id);
    await refresh();
  }

  // ── Recurring CRUD ───────────────────────────────────────
  Future<void> saveRecurring(Map<String, dynamic> data, {int? id}) async {
    if (id != null) {
      await _api.updateExpenseRecurring(id, data);
    } else {
      await _api.createExpenseRecurring(data);
    }
    await refresh();
  }

  Future<void> deleteRecurring(int id) async {
    await _api.deleteExpenseRecurring(id);
    await refresh();
  }

  Future<void> materializeRecurring() async {
    await _api.materializeExpenseRecurring();
    await refresh();
  }

  // ── Budgets CRUD ─────────────────────────────────────────
  Future<void> createBudget(Map<String, dynamic> data) async {
    await _api.createExpenseBudget(data);
    await refresh();
  }

  Future<void> deleteBudget(int id) async {
    await _api.deleteExpenseBudget(id);
    await refresh();
  }
}
