"""Vehicle Financing Monitor — manages fleet vehicles under bank/institution financing.

Models:
  - FinancingLoan: One active or historical loan per vehicle (bank, principal, interest, tenor, status)
  - FinancingPayment: Scheduled or actual instalment payments against a loan
"""

from decimal import Decimal

from django.db import models
from django.utils import timezone


class FinancingLoan(models.Model):
    """A vehicle financing/loan record linked to a specific vehicle."""

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        CLOSED = 'closed', 'Closed'
        DEFAULTED = 'defaulted', 'Defaulted'
        RESTRUCTURED = 'restructured', 'Restructured'
        PENDING = 'pending', 'Pending Disbursement'

    class InterestType(models.TextChoices):
        FIXED = 'fixed', 'Fixed'
        FLOATING = 'floating', 'Floating'
        REDUCING = 'reducing', 'Reducing Balance'

    loan_no = models.CharField(max_length=40, unique=True, editable=False)
    vehicle = models.ForeignKey(
        'vehicles.Vehicle', on_delete=models.PROTECT,
        related_name='financing_loans',
        help_text='The vehicle financed under this loan.',
    )
    bank_name = models.CharField(max_length=200, help_text='Financial institution / bank name')
    branch = models.CharField(max_length=200, blank=True, default='')
    account_no = models.CharField(max_length=100, blank=True, default='', help_text='Bank account/loan account number')

    # Dates
    disbursement_date = models.DateField(null=True, blank=True, help_text='Date funds were disbursed')
    first_payment_date = models.DateField(null=True, blank=True, help_text='First instalment due date')
    maturity_date = models.DateField(null=True, blank=True, help_text='Expected loan completion date')
    closed_date = models.DateField(null=True, blank=True, help_text='Date loan was fully settled')

    # Amounts
    principal_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0, help_text='Total loan principal')
    interest_rate = models.DecimalField(max_digits=8, decimal_places=4, default=0, help_text='Annual interest rate (%)')
    interest_type = models.CharField(max_length=20, choices=InterestType.choices, default=InterestType.FIXED)
    tenor_months = models.IntegerField(default=0, help_text='Loan tenor in months')
    monthly_instalment = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='EMI amount')

    # Additional costs
    processing_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    insurance_premium = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Loan-linked insurance')
    down_payment = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Initial down payment')
    collateral_value = models.DecimalField(max_digits=14, decimal_places=2, default=0, help_text='Vehicle/collateral value at disbursement')

    # Status & flags
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    remarks = models.TextField(blank=True, default='')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-disbursement_date', '-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['bank_name']),
            models.Index(fields=['disbursement_date']),
        ]
        verbose_name = 'Financing Loan'
        verbose_name_plural = 'Financing Loans'

    def __str__(self) -> str:
        return f'{self.loan_no} — {self.vehicle} ({self.bank_name})'

    def save(self, *args, **kwargs):
        if not self.loan_no:
            ts = self.created_at or timezone.now()
            date_prefix = f'FIN-{ts.strftime("%Y%m%d")}-'
            import re as _re
            existing_nos = FinancingLoan.objects.filter(loan_no__startswith=date_prefix)
            max_seq = 0
            for no in existing_nos.values_list('loan_no', flat=True):
                m = _re.match(r'FIN-\d{8}-(\d{4})', no or '')
                if m:
                    max_seq = max(max_seq, int(m.group(1)))
            seq = max_seq + 1
            if self.pk:
                seq = max(seq, self.pk)
            self.loan_no = f'{date_prefix}{seq:04d}'
        super().save(*args, **kwargs)

    # ── Computed properties ──

    @property
    def total_paid(self) -> Decimal:
        """Sum of all completed payments."""
        total = self.payments.filter(status=FinancingPayment.Status.PAID).aggregate(
            t=models.Sum('amount')
        )['t']
        return total or Decimal('0')

    @property
    def total_interest_paid(self) -> Decimal:
        """Sum of interest component of paid payments."""
        total = self.payments.filter(status=FinancingPayment.Status.PAID).aggregate(
            t=models.Sum('interest_component')
        )['t']
        return total or Decimal('0')

    @property
    def outstanding_balance(self) -> Decimal:
        """Principal + estimated total interest — total paid."""
        total_interest = self._estimated_total_interest()
        total_payable = self.principal_amount + total_interest
        return total_payable - self.total_paid

    @property
    def principal_paid(self) -> Decimal:
        return self.total_paid - self.total_interest_paid

    @property
    def outstanding_principal(self) -> Decimal:
        return self.principal_amount - self.principal_paid

    @property
    def progress_pct(self) -> Decimal:
        """Loan repayment progress as percentage."""
        total_payable = self.principal_amount + self._estimated_total_interest()
        if total_payable <= 0:
            return Decimal('0')
        return (self.total_paid / total_payable * Decimal('100')).quantize(Decimal('0.01'))

    @property
    def total_payable(self) -> Decimal:
        return self.principal_amount + self._estimated_total_interest()

    @property
    def ltv_ratio(self) -> Decimal:
        """Loan-to-value ratio (principal / collateral)."""
        if not self.collateral_value or self.collateral_value <= 0:
            return Decimal('0')
        return (self.principal_amount / self.collateral_value * Decimal('100')).quantize(Decimal('0.01'))

    @property
    def next_due_date(self):
        """Next unpaid or partially-paid payment due date."""
        next_pmt = self.payments.filter(
            status__in=[FinancingPayment.Status.UPCOMING, FinancingPayment.Status.OVERDUE, FinancingPayment.Status.PARTIALLY_PAID]
        ).order_by('due_date').first()
        return next_pmt.due_date if next_pmt else None

    @property
    def next_due_amount(self) -> Decimal:
        """Next instalment amount due."""
        next_pmt = self.payments.filter(
            status__in=[FinancingPayment.Status.UPCOMING, FinancingPayment.Status.OVERDUE, FinancingPayment.Status.PARTIALLY_PAID]
        ).order_by('due_date').first()
        return next_pmt.outstanding if next_pmt else Decimal('0')

    @property
    def is_overdue(self) -> bool:
        """Any payment past due date and not paid?"""
        return self.payments.filter(
            status=FinancingPayment.Status.OVERDUE
        ).exists()

    @property
    def days_past_due(self) -> int:
        """Days since the earliest overdue payment's due date."""
        from datetime import date
        earliest_overdue = self.payments.filter(
            status=FinancingPayment.Status.OVERDUE
        ).order_by('due_date').first()
        if not earliest_overdue:
            return 0
        return (date.today() - earliest_overdue.due_date).days

    @property
    def payment_count_total(self) -> int:
        return self.payments.count()

    @property
    def payment_count_paid(self) -> int:
        return self.payments.filter(status=FinancingPayment.Status.PAID).count()

    @property
    def payment_count_pending(self) -> int:
        return self.payments.exclude(status=FinancingPayment.Status.PAID).count()

    def _estimated_total_interest(self) -> Decimal:
        """Estimate total interest using simple or reducing method."""
        if self.interest_type == self.InterestType.REDUCING:
            # Reducing balance: approximate with formula for EMI
            r = self.interest_rate / Decimal('100') / Decimal('12')
            n = Decimal(str(self.tenor_months or 0))
            if r > 0 and n > 0:
                # Total = EMI * n
                return (self.monthly_instalment * n - self.principal_amount).quantize(Decimal('0.01'))
            return Decimal('0')
        else:
            # Fixed/floating: simple interest
            years = Decimal(str(self.tenor_months or 0)) / Decimal('12')
            return (self.principal_amount * self.interest_rate / Decimal('100') * years).quantize(Decimal('0.01'))


class FinancingPayment(models.Model):
    """A scheduled or actual instalment payment for a FinancingLoan."""

    class Status(models.TextChoices):
        UPCOMING = 'upcoming', 'Upcoming'
        PAID = 'paid', 'Paid'
        PARTIALLY_PAID = 'partially_paid', 'Partially Paid'
        OVERDUE = 'overdue', 'Overdue'
        WAIVED = 'waived', 'Waived'

    class PaymentMethod(models.TextChoices):
        BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'
        CHEQUE = 'cheque', 'Cheque'
        CASH = 'cash', 'Cash'
        MOBILE_MONEY = 'mobile_money', 'Mobile Money'
        AUTO_DEBIT = 'auto_debit', 'Auto Debit'
        OTHER = 'other', 'Other'

    loan = models.ForeignKey(
        FinancingLoan, on_delete=models.CASCADE,
        related_name='payments',
    )
    instalment_no = models.IntegerField(default=1, help_text='Instalment sequence number')
    due_date = models.DateField()
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Total instalment amount (principal + interest)')
    principal_component = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Principal portion of this instalment')
    interest_component = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Interest portion of this instalment')

    # Payment tracking
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.UPCOMING)
    paid_date = models.DateField(null=True, blank=True)
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Amount actually paid')
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices, blank=True, default='')
    reference_no = models.CharField(max_length=100, blank=True, default='', help_text='Bank reference/transaction ID')
    evidence_file = models.FileField(upload_to='financing/', null=True, blank=True, help_text='Upload payment evidence (receipt, screenshot, bank confirmation)')
    remarks = models.TextField(blank=True, default='')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['due_date', 'instalment_no']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['due_date']),
            models.Index(fields=['loan', 'instalment_no']),
        ]
        verbose_name = 'Financing Payment'
        verbose_name_plural = 'Financing Payments'
        unique_together = ['loan', 'instalment_no']

    def __str__(self) -> str:
        return f'{self.loan.loan_no} — Instalment #{self.instalment_no} ({self.amount})'

    @property
    def outstanding(self) -> Decimal:
        return self.amount - self.paid_amount

    def save(self, *args, **kwargs):
        # Auto-set status based on paid_amount
        if self.status != self.Status.WAIVED:
            if self.paid_amount >= self.amount and self.amount > 0:
                self.status = self.Status.PAID
            elif self.paid_amount > 0:
                self.status = self.Status.PARTIALLY_PAID
            elif self.due_date and self.status != self.Status.PAID:
                from datetime import date
                if self.due_date < date.today() and self.paid_amount == 0:
                    self.status = self.Status.OVERDUE
        super().save(*args, **kwargs)
