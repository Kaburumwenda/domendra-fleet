from django.db import models
from django.utils import timezone


class Lessor(models.Model):
    class LessorType(models.TextChoices):
        INDIVIDUAL = 'individual', 'Individual'
        COMPANY = 'company', 'Company'

    lessor_type = models.CharField(max_length=20, choices=LessorType.choices, default=LessorType.INDIVIDUAL)

    # Individual fields
    first_name = models.CharField(max_length=100, blank=True)
    middle_name = models.CharField(max_length=100, blank=True)
    last_name = models.CharField(max_length=100, blank=True)
    national_id = models.CharField(max_length=50, blank=True, help_text='National identity / ID number')

    # Company fields
    company_name = models.CharField(max_length=200, blank=True)
    representative_name = models.CharField(max_length=200, blank=True)
    registration_number = models.CharField(max_length=50, blank=True, help_text='Company registration / tax ID')

    # Common contact fields
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    country = models.CharField(max_length=100, blank=True)
    address = models.TextField(blank=True)

    # Business fields
    tax_id = models.CharField(max_length=50, blank=True, help_text='Tax identification number')
    bank_account = models.CharField(max_length=100, blank=True, help_text='Bank account for payments')
    payment_terms = models.CharField(max_length=200, blank=True, help_text='e.g. Net 30, Monthly in advance')
    contract_start_date = models.DateField(null=True, blank=True, help_text='Master contract start')
    contract_end_date = models.DateField(null=True, blank=True, help_text='Master contract end')

    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['company_name', 'first_name', 'last_name']
        indexes = [models.Index(fields=['lessor_type'])]

    def __str__(self):
        return self.display_name

    @property
    def display_name(self):
        if self.lessor_type == self.LessorType.COMPANY:
            return self.company_name or f'Lessor #{self.pk}'
        parts = [self.first_name, self.middle_name, self.last_name]
        return ' '.join(p for p in parts if p).strip() or f'Lessor #{self.pk}'

    @property
    def active_lease_count(self):
        return self.vehicles.filter(ownership='lease', status__in=['active', 'in_maintenance']).count()

    @property
    def vehicle_count(self):
        """Total vehicles leased from this lessor (all statuses)."""
        return self.vehicles.filter(ownership='lease').count()

    @property
    def total_lease_value(self):
        from decimal import Decimal
        total = Decimal('0')
        for v in self.vehicles.filter(ownership='lease'):
            if v.lease_monthly_rate:
                total += v.lease_monthly_rate
        return total

    @property
    def monthly_earnings(self):
        """Monthly earning based on vehicle count × lease monthly rate."""
        from decimal import Decimal
        total = Decimal('0')
        for v in self.vehicles.filter(ownership='lease'):
            if v.lease_monthly_rate:
                total += v.lease_monthly_rate
        return total

    @property
    def total_deposit_held(self):
        """Total security deposits held across all leased vehicles."""
        from decimal import Decimal
        total = Decimal('0')
        for v in self.vehicles.filter(ownership='lease'):
            if v.deposit:
                total += v.deposit
        return total


class LessorContract(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        ACTIVE = 'active', 'Active'
        EXPIRED = 'expired', 'Expired'
        TERMINATED = 'terminated', 'Terminated'
        PENDING = 'pending', 'Pending Signature'

    lessor = models.ForeignKey(Lessor, on_delete=models.CASCADE, related_name='contracts')
    contract_number = models.CharField(max_length=100, blank=True, help_text='Unique contract reference')
    title = models.CharField(max_length=200, default='Lease Agreement')
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)

    # Terms
    monthly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Monthly lease rate in USD')
    deposit_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_frequency = models.CharField(max_length=20, default='monthly',
                                          choices=[('weekly', 'Weekly'), ('biweekly', 'Biweekly'),
                                                   ('monthly', 'Monthly'), ('quarterly', 'Quarterly'),
                                                   ('annually', 'Annually')])
    currency = models.CharField(max_length=10, default='USD')

    # Terms & conditions
    terms = models.TextField(blank=True, help_text='Lease terms and conditions')
    mileage_limit = models.IntegerField(null=True, blank=True, help_text='Monthly mileage limit')
    excess_mileage_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True,
                                              help_text='Rate per unit over mileage limit')
    insurance_required = models.BooleanField(default=True)
    maintenance_responsibility = models.CharField(max_length=50, blank=True,
        help_text='Who handles maintenance: lessor, lessee, or shared')

    # Documents & signatures
    signed_date = models.DateField(null=True, blank=True)
    auto_renew = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['lessor', 'status'])]

    def __str__(self):
        return f'{self.title} – {self.lessor.display_name}'

    @property
    def is_active_now(self):
        if self.status != self.Status.ACTIVE:
            return False
        today = timezone.now().date()
        if self.end_date and self.end_date < today:
            return False
        return True

    @property
    def days_remaining(self):
        if not self.end_date:
            return None
        return (self.end_date - timezone.now().date()).days

    @property
    def total_value(self):
        if not self.end_date or not self.monthly_rate:
            return self.monthly_rate
        # Calculate months between start_date and end_date without dateutil
        months = (self.end_date.year - self.start_date.year) * 12 + (self.end_date.month - self.start_date.month)
        if self.end_date.day >= self.start_date.day:
            months += 1
        if months < 1:
            months = 1
        return self.monthly_rate * months


class LessorPayment(models.Model):
    class PaymentStatus(models.TextChoices):
        PENDING = 'pending', 'Pending'
        PAID = 'paid', 'Paid'
        OVERDUE = 'overdue', 'Overdue'
        CANCELLED = 'cancelled', 'Cancelled'

    class PaymentMethod(models.TextChoices):
        BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'
        CHECK = 'check', 'Check'
        WIRE = 'wire', 'Wire'
        CARD = 'card', 'Card'
        CASH = 'cash', 'Cash'
        OTHER = 'other', 'Other'

    lessor = models.ForeignKey(Lessor, on_delete=models.CASCADE, related_name='payments')
    contract = models.ForeignKey(LessorContract, null=True, blank=True, on_delete=models.SET_NULL, related_name='payments')
    invoice_number = models.CharField(max_length=100, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=10, default='USD')
    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)

    due_date = models.DateField(null=True, blank=True)
    paid_date = models.DateField(null=True, blank=True)
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices, blank=True)
    reference = models.CharField(max_length=200, blank=True, help_text='Payment reference / transaction ID')
    notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-due_date', '-created_at']
        indexes = [models.Index(fields=['lessor', 'status'])]

    def __str__(self):
        return f'{self.lessor.display_name} – {self.amount} ({self.status})'

    @property
    def is_overdue(self):
        if self.status != self.PaymentStatus.PENDING:
            return False
        if not self.due_date:
            return False
        return self.due_date < timezone.now().date()


class LessorDocument(models.Model):
    class DocumentType(models.TextChoices):
        CONTRACT = 'contract', 'Contract'
        INSURANCE = 'insurance', 'Insurance'
        REGISTRATION = 'registration', 'Registration'
        LICENSE = 'license', 'License'
        TAX = 'tax', 'Tax Document'
        BANK = 'bank', 'Bank Document'
        OTHER = 'other', 'Other'

    lessor = models.ForeignKey(Lessor, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=20, choices=DocumentType.choices, default=DocumentType.OTHER)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    file = models.FileField(upload_to='lessor-documents/', blank=True, null=True)
    file_url = models.URLField(blank=True, help_text='External URL if not uploading a file')
    expires_at = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} – {self.lessor.display_name}'

    @property
    def is_expired(self):
        if not self.expires_at:
            return False
        return self.expires_at < timezone.now().date()
