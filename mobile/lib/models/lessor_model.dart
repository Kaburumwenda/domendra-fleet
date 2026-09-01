/// Lessors data models mirroring the backend serializers.
library;

/// Lessor type — individual or company.
enum LessorType { individual, company }

/// Contract status enum.
enum ContractStatus { draft, pending, active, expired, terminated }

/// Payment status enum.
enum PaymentStatus { pending, paid, overdue, cancelled }

/// Lessor wrapper — mirrors `LessorSerializer`.
class Lessor {
  final Map<String, dynamic> _raw;
  Lessor(this._raw);

  Map<String, dynamic> get raw => _raw;

  int? get id => _raw['id'] as int?;
  LessorType get lessorType =>
      _raw['lessor_type'] == 'company' ? LessorType.company : LessorType.individual;
  String get firstName => _str('first_name');
  String get middleName => _str('middle_name');
  String get lastName => _str('last_name');
  String get nationalId => _str('national_id');
  String get companyName => _str('company_name');
  String get representativeName => _str('representative_name');
  String get registrationNumber => _str('registration_number');
  String get email => _str('email');
  String get phone => _str('phone');
  String get country => _str('country');
  String get address => _str('address');
  String get taxId => _str('tax_id');
  String get bankAccount => _str('bank_account');
  String get paymentTerms => _str('payment_terms');
  DateTime? get contractStartDate => _date('contract_start_date');
  DateTime? get contractEndDate => _date('contract_end_date');
  String get notes => _str('notes');
  bool get isActive => _raw['is_active'] == true;

  // Computed
  String get displayName => _str('display_name');
  int get vehicleCount => _int('vehicle_count') ?? 0;
  int get activeLeaseCount => _int('active_lease_count') ?? 0;
  double get totalLeaseValue => _double('total_lease_value') ?? 0;
  double get monthlyEarnings => _double('monthly_earnings') ?? 0;
  double get totalDepositHeld => _double('total_deposit_held') ?? 0;
  int? get contractCount => _int('contract_count');
  double get unpaidAmount => _double('unpaid_amount') ?? 0;

  String get typeLabel => lessorType == LessorType.company ? 'Company' : 'Individual';

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  int? _int(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _double(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _date(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// Lessor contract wrapper — mirrors `LessorContractSerializer`.
class LessorContract {
  final Map<String, dynamic> _raw;
  LessorContract(this._raw);

  Map<String, dynamic> get raw => _raw;

  int? get id => _raw['id'] as int?;
  int? get lessorId => _raw['lessor'] as int?;
  String get lessorName => _str('lessor_name');
  String get contractNumber => _str('contract_number');
  String get title => _str('title');
  DateTime? get startDate => _date('start_date');
  DateTime? get endDate => _date('end_date');
  ContractStatus get status => ContractStatus.values.firstWhere(
      (s) => s.name == _str('status'),
      orElse: () => ContractStatus.draft);
  double get monthlyRate => _double('monthly_rate') ?? 0;
  double get depositAmount => _double('deposit_amount') ?? 0;
  String get paymentFrequency => _str('payment_frequency');
  String get currency => _str('currency');
  String get terms => _str('terms');
  int? get mileageLimit => _int('mileage_limit');
  double? get excessMileageRate => _double('excess_mileage_rate');
  bool get insuranceRequired => _raw['insurance_required'] == true;
  String get maintenanceResponsibility => _str('maintenance_responsibility');
  DateTime? get signedDate => _date('signed_date');
  bool get autoRenew => _raw['auto_renew'] == true;

  // Computed
  bool get isActiveNow => _raw['is_active_now'] == true;
  int? get daysRemaining => _int('days_remaining');
  double get totalValue => _double('total_value') ?? 0;

  String get statusLabel => status.name[0].toUpperCase() + status.name.substring(1);

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  int? _int(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _double(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _date(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// Lessor payment wrapper — mirrors `LessorPaymentSerializer`.
class LessorPayment {
  final Map<String, dynamic> _raw;
  LessorPayment(this._raw);

  Map<String, dynamic> get raw => _raw;

  int? get id => _raw['id'] as int?;
  int? get lessorId => _raw['lessor'] as int?;
  String get lessorName => _str('lessor_name');
  int? get contractId => _raw['contract'] as int?;
  String get contractNumber => _str('contract_number');
  String get invoiceNumber => _str('invoice_number');
  double get amount => _double('amount') ?? 0;
  String get currency => _str('currency');
  PaymentStatus get status => PaymentStatus.values.firstWhere(
      (s) => s.name == _str('status'),
      orElse: () => PaymentStatus.pending);
  DateTime? get dueDate => _date('due_date');
  DateTime? get paidDate => _date('paid_date');
  String get paymentMethod => _str('payment_method');
  String get reference => _str('reference');
  String get notes => _str('notes');

  bool get isOverdue => _raw['is_overdue'] == true;

  String get statusLabel => status.name[0].toUpperCase() + status.name.substring(1);

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  double? _double(String key) {
    final v = _raw[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  DateTime? _date(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// Lessor document wrapper — mirrors `LessorDocumentSerializer`.
class LessorDocument {
  final Map<String, dynamic> _raw;
  LessorDocument(this._raw);

  Map<String, dynamic> get raw => _raw;

  int? get id => _raw['id'] as int?;
  int? get lessorId => _raw['lessor'] as int?;
  String get lessorName => _str('lessor_name');
  String get documentType => _str('document_type');
  String get name => _str('name');
  String get description => _str('description');
  String get file => _str('file');
  String get fileUrl => _str('file_url');
  DateTime? get expiresAt => _date('expires_at');

  bool get isExpired => _raw['is_expired'] == true;

  String get typeLabel {
    switch (documentType) {
      case 'contract': return 'Contract';
      case 'insurance': return 'Insurance';
      case 'registration': return 'Registration';
      case 'license': return 'License';
      case 'tax': return 'Tax';
      case 'bank': return 'Bank';
      default: return 'Other';
    }
  }

  String _str(String key) {
    final v = _raw[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  DateTime? _date(String key) {
    final v = _str(key);
    if (v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}
