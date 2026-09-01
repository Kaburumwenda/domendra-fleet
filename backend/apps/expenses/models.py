"""
Expense management models for a premium, modern expenses system.

Covers:
  • Expense categories (tenant-managed, hierarchical-ready)
  • Expenses — vehicle-, driver/vendor-, or generic with rich metadata
  • Recurring expense rules → materializes scheduled expenses via Celery
  • Expense budgets — fleet-wide, per vehicle type, per vehicle, or per category
  • Expense approvals — multi-level lightweight workflow on submit/approve/reject
  • Expense attachments (receipts / documents)
  • Expense comments (audit-trail / discussion thread)
"""

import calendar


from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import models

User = get_user_model()


class ExpenseCategory(models.Model):
    """
    Tenant-managed expense categories such as Fuel, Maintenance, Tolls,
    Permits, Salaries, Software, Insurance, Rent, etc.
    """

    class Type(models.TextChoices):
        OPERATING = 'operating', 'Operating'
        CAPITAL = 'capital', 'Capital'
        COGS = 'cogs', 'Cost of Goods Sold'
        OTHER = 'other', 'Other'

    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    code = models.CharField(max_length=20, blank=True, help_text='Short unique code, e.g. FUEL, MAINT')
    type = models.CharField(max_length=20, choices=Type.choices, default=Type.OPERATING)
    color = models.CharField(max_length=7, default='#6366f1', help_text='Hex colour for UI chips')
    icon = models.CharField(max_length=50, default='mdi-cash', help_text='Material Design Icon name')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Expense categories'

    def __str__(self):
        return self.name

    @property
    def vehicle_count(self):
        return self.expenses.filter(vehicle__isnull=False).values('vehicle').distinct().count()


class Expense(models.Model):
    """
    A single expense record — can optionally link to a vehicle, a
    contact (driver / vendor), or stand on its own.
    """

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        SUBMITTED = 'submitted', 'Submitted'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'
        PAID = 'paid', 'Paid'

    class PaymentMethod(models.TextChoices):
        CASH = 'cash', 'Cash'
        CARD = 'card', 'Card'
        BANK = 'bank', 'Bank Transfer'
        MOBILE = 'mobile', 'Mobile Money'
        CHECK = 'check', 'Check'
        OTHER = 'other', 'Other'

    # ── Core ────────────────────────────────────────────
    expense_number = models.CharField(max_length=50, unique=True, blank=True, db_index=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    category = models.ForeignKey(
        ExpenseCategory, on_delete=models.PROTECT,
        related_name='expenses', null=True, blank=True,
    )
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    expense_date = models.DateField()
    vendor_name = models.CharField(max_length=200, blank=True, help_text='Free-text vendor / merchant')

    # ── Linkages (all optional) ──────────────────────────
    vehicle = models.ForeignKey(
        'vehicles.Vehicle', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses',
    )
    contact = models.ForeignKey(
        'contacts.Contact', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses',
        help_text='Driver or vendor contact',
    )
    work_order = models.ForeignKey(
        'issues.WorkOrder', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses',
    )
    service = models.ForeignKey(
        'services.Service', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses',
    )

    # ── Payment & status ─────────────────────────────────
    payment_method = models.CharField(
        max_length=20, choices=PaymentMethod.choices,
        default=PaymentMethod.OTHER,
    )
    payment_reference = models.CharField(max_length=100, blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices,
        default=Status.DRAFT,
    )
    paid_at = models.DateTimeField(null=True, blank=True)

    # ── Approvals ───────────────────────────────────────
    submitted_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses_submitted',
    )
    submitted_at = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses_approved',
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.TextField(blank=True)

    # ── Recurring ────────────────────────────────────────
    recurring_rule = models.ForeignKey(
        'RecurringExpense', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='generated_expenses',
    )

    # ── Tax (optional) ───────────────────────────────────
    tax_amount = models.DecimalField(
        max_digits=14, decimal_places=2, default=Decimal('0'),
    )
    tax_rate = models.DecimalField(
        max_digits=6, decimal_places=4, default=Decimal('0'),
        help_text='Tax rate as a fraction, e.g. 0.0825 for 8.25%',
    )

    # ── Misc ────────────────────────────────────────────
    tags = models.CharField(max_length=200, blank=True, help_text='Comma-separated tags')
    is_billable = models.BooleanField(default=False, help_text='Can this expense be invoiced to a customer?')
    notes = models.TextField(blank=True)

    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expenses_created',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-expense_date', '-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['expense_date']),
            models.Index(fields=['category']),
            models.Index(fields=['vehicle']),
            models.Index(fields=['is_billable']),
        ]

    def __str__(self):
        return f'{self.expense_number or self.title} — {self.amount} {self.currency}'

    @property
    def total_amount(self):
        """amount + tax_amount."""
        return (self.amount or Decimal('0')) + (self.tax_amount or Decimal('0'))

    def save(self, *args, **kwargs):
        if not self.expense_number:
            # seq-style: EXP-YYYYMM-####
            from django.utils import timezone as dj_timezone
            ym = dj_timezone.now().strftime('%Y%m')
            qs = Expense.objects.filter(expense_number__startswith=f'EXP-{ym}-')
            seq = qs.count() + 1
            self.expense_number = f'EXP-{ym}-{seq:04d}'
        super().save(*args, **kwargs)


class ExpenseAttachment(models.Model):
    """Receipt photos, invoices, or any document linked to an expense."""

    expense = models.ForeignKey(
        Expense, on_delete=models.CASCADE, related_name='attachments'
    )
    file = models.FileField(upload_to='expense-attachments/')
    filename = models.CharField(max_length=255, blank=True)
    file_size = models.BigIntegerField(default=0)
    mime_type = models.CharField(max_length=100, blank=True)
    uploaded_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expense_attachments',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.expense} – {self.filename or self.file.name}'


class RecurringExpense(models.Model):
    """
    A template that generates ``Expense`` rows on a schedule.

    A Celery beat job (``materialize_recurring_expenses``) runs daily and
    creates a new ``Expense`` for every rule whose ``next_date`` is due.
    """

    class Frequency(models.TextChoices):
        DAILY = 'daily', 'Daily'
        WEEKLY = 'weekly', 'Weekly'
        MONTHLY = 'monthly', 'Monthly'
        QUARTERLY = 'quarterly', 'Quarterly'
        YEARLY = 'yearly', 'Yearly'

    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    category = models.ForeignKey(
        ExpenseCategory, on_delete=models.PROTECT,
        null=True, blank=True, related_name='recurring_rules',
    )
    vehicle = models.ForeignKey(
        'vehicles.Vehicle', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='recurring_expenses',
    )
    contact = models.ForeignKey(
        'contacts.Contact', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='recurring_expenses',
    )
    vendor_name = models.CharField(max_length=200, blank=True)

    amount = models.DecimalField(max_digits=14, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    tax_rate = models.DecimalField(
        max_digits=6, decimal_places=4, default=Decimal('0'),
    )
    payment_method = models.CharField(
        max_length=20, choices=Expense.PaymentMethod.choices,
        default=Expense.PaymentMethod.OTHER,
    )

    frequency = models.CharField(
        max_length=20, choices=Frequency.choices, default=Frequency.MONTHLY,
    )
    interval = models.PositiveSmallIntegerField(
        default=1, help_text='Every N periods (e.g. every 2 months).'
    )
    day_of_month = models.PositiveSmallIntegerField(
        default=1, help_text='Day-of-month for monthly/quarterly/yearly (1-31).'
    )
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)

    next_date = models.DateField()
    last_run_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    auto_approve = models.BooleanField(
        default=False, help_text='Auto-approve generated expenses (skip workflow).'
    )

    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='recurring_expense_rules',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-next_date']
        indexes = [
            models.Index(fields=['is_active', 'next_date']),
            models.Index(fields=['frequency']),
        ]

    def __str__(self):
        return f'{self.title} — {self.amount} {self.currency} / {self.frequency}'

    def compute_next_date(self, after_date):
        """Return the next scheduled date strictly after ``after_date``."""
        from datetime import date, timedelta

        base = after_date
        interval = max(int(self.interval or 1), 1)

        if self.frequency == self.Frequency.DAILY:
            return base + timedelta(days=interval)

        if self.frequency == self.Frequency.WEEKLY:
            return base + timedelta(weeks=interval)

        if self.frequency == self.Frequency.MONTHLY:
            # advance N months, clamp to valid day-of-month
            month = base.month - 1 + interval
            year = base.year + month // 12
            month = month % 12 + 1
            last_day = calendar.monthrange(year, month)[1]
            day = min(self.day_of_month or 1, last_day)
            return date(year, month, day)

        if self.frequency == self.Frequency.QUARTERLY:
            month = base.month - 1 + (interval * 3)
            year = base.year + month // 12
            month = month % 12 + 1
            last_day = calendar.monthrange(year, month)[1]
            day = min(self.day_of_month or 1, last_day)
            return date(year, month, day)

        if self.frequency == self.Frequency.YEARLY:
            year = base.year + interval
            month = self.start_date.month if self.start_date else 1
            last_day = calendar.monthrange(year, month)[1]
            day = min(self.day_of_month or 1, last_day)
            return date(year, month, day)

        return base + timedelta(days=1)


class ExpenseBudget(models.Model):
    """
    Budgeted spend for a month. ``scope`` determines what the budget
    applies to (fleet-wide, vehicle type, location, category, or vehicle).
    ``target_ref`` stores the human-readable identifier of the target.
    """

    class Scope(models.TextChoices):
        FLEET = 'fleet', 'Fleet-wide'
        VEHICLE_TYPE = 'vehicle_type', 'Vehicle Type'
        LOCATION = 'location', 'Location'
        CATEGORY = 'category', 'Category'
        VEHICLE = 'vehicle', 'Vehicle'

    scope = models.CharField(max_length=20, choices=Scope.choices, default=Scope.FLEET)
    target_ref = models.CharField(
        max_length=100, blank=True,
        help_text='Vehicle type / location / category name / vehicle id',
    )
    vehicle = models.ForeignKey(
        'vehicles.Vehicle', on_delete=models.CASCADE,
        null=True, blank=True, related_name='expense_budgets',
    )
    category = models.ForeignKey(
        ExpenseCategory, on_delete=models.CASCADE,
        null=True, blank=True, related_name='budgets',
    )
    month = models.DateField(help_text='First day of the budget month')
    budget_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    currency = models.CharField(max_length=3, default='USD')
    notes = models.TextField(blank=True)

    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expense_budgets_created',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-month']
        unique_together = [('scope', 'target_ref', 'month')]
        indexes = [models.Index(fields=['month'])]

    def __str__(self):
        return f'{self.scope} · {self.target_ref or "all"} · {self.month}'

    @property
    def label(self):
        if self.scope == self.Scope.FLEET:
            return 'Fleet-wide'
        if self.scope == self.Scope.VEHICLE:
            return f'Vehicle · {self.target_ref}'
        return f'{self.get_scope_display()} · {self.target_ref or "all"}'


class ExpenseComment(models.Model):
    """Discussion thread / audit trail for an expense."""

    expense = models.ForeignKey(
        Expense, on_delete=models.CASCADE, related_name='comments'
    )
    author = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='expense_comments',
    )
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'{self.expense} – {self.author} – {self.created_at:%Y-%m-%d}'
