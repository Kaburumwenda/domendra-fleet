from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import models
from django.utils import timezone as dj_timezone

User = get_user_model()

# USD 0.077 per 1,000 API requests (base billing rate).
USD_RATE_PER_1000 = Decimal('0.077')


class BillingPlan(models.Model):
    """Legacy plan tier — retained for historical bills only.  New billing
    is purely usage-based at ``USD_RATE_PER_1000`` per 1,000 requests."""

    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    included_requests = models.BigIntegerField(default=10000)
    rate_per_1000_requests = models.DecimalField(
        max_digits=10, decimal_places=4, default=Decimal('0.077')
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['price']

    def __str__(self):
        return self.name.title()


class TenantSubscription(models.Model):
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        PAST_DUE = 'past_due', 'Past Due'
        CANCELLED = 'cancelled', 'Cancelled'
        TRIALING = 'trialing', 'Trialing'

    tenant = models.OneToOneField(
        'tenants.Tenant', on_delete=models.CASCADE, related_name='subscription',
    )
    plan = models.ForeignKey(
        BillingPlan, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='subscriptions',
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    request_count = models.BigIntegerField(default=0)
    overage_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Billing is purely usage-based: USD 0.077 per 1,000 requests.
    rate_per_1000_requests = models.DecimalField(
        max_digits=10, decimal_places=4, default=USD_RATE_PER_1000,
    )
    billing_currency = models.CharField(max_length=3, default='USD')

    # Monthly cycle: resets at the start of each billing month.
    current_period_start = models.DateTimeField(auto_now_add=True)
    current_period_end = models.DateTimeField(null=True, blank=True)
    cycle_day = models.PositiveSmallIntegerField(default=1)

    billing_email = models.EmailField(blank=True)
    auto_close = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.tenant.short_name} – {self.plan.name}'

    # ── Helpers ──────────────────────────────────────────────
    @property
    def rate(self):
        """Effective per-1k-request rate in USD."""
        r = self.rate_per_1000_requests
        return Decimal(r) if r is not None else USD_RATE_PER_1000

    @property
    def local_rate(self):
        """Rate per-1k in the tenant's billing currency."""
        return self.usd_to_local(self.rate, self.billing_currency)

    @classmethod
    def usd_to_local(cls, amount, currency=None):
        """Convert a USD Decimal to the tenant's currency via ExchangeRate."""
        if not currency or currency == 'USD':
            return Decimal(amount or 0)
        rate = ExchangeRate.get_rate(currency)
        return (Decimal(amount or 0) * rate).quantize(Decimal('0.01'))

    def _compute_cost_usd(self, requests):
        requests = int(requests or 0)
        if requests <= 0:
            return Decimal('0')
        return (Decimal(requests) * self.rate) / Decimal('1000')

    def compute_cost_local(self, requests):
        usd = self._compute_cost_usd(requests)
        return self.usd_to_local(usd, self.billing_currency)

    @property
    def included_remaining(self):
        # Pure usage billing — no included tier.
        return None

    @property
    def is_over_limit(self):
        # No fixed cap on usage.
        return False

    @property
    def estimated_cost_usd(self):
        """Live cost for all requests in the current cycle (USD)."""
        return self._compute_cost_usd(self.request_count)

    @property
    def estimated_cost_local(self):
        """Live cost in the tenant's billing currency."""
        return self.compute_cost_local(self.request_count)

    @property
    def monthly_average(self):
        """Avg requests/day so far in the current period."""
        span = dj_timezone.now() - self.current_period_start
        days = max(span.days, 1)
        return round(self.request_count / days)

    @property
    def end_of_month_projection(self):
        """Requests projected by ``current_period_end`` using linear avg."""
        if not self.current_period_end:
            return self.request_count
        total_span = self.current_period_end - self.current_period_start
        total_days = max(total_span.days, 1)
        span_so_far = dj_timezone.now() - self.current_period_start
        elapsed = max(span_so_far.total_seconds() / 86400, 1)
        daily_rate = self.request_count / elapsed
        return int(daily_rate * total_days)

    @property
    def projected_cost_usd(self):
        return self._compute_cost_usd(self.end_of_month_projection)

    @property
    def projected_cost_local(self):
        return self.usd_to_local(self.projected_cost_usd, self.billing_currency)


class APIUsageLog(models.Model):
    tenant = models.ForeignKey(
        'tenants.Tenant', on_delete=models.CASCADE, related_name='api_logs',
    )
    endpoint = models.CharField(max_length=255, blank=True)
    method = models.CharField(max_length=10, blank=True)
    status_code = models.IntegerField(null=True, blank=True)
    response_time_ms = models.IntegerField(default=0)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['timestamp']),
            models.Index(fields=['endpoint']),
            models.Index(fields=['status_code']),
        ]

    def __str__(self):
        return f'{self.tenant.short_name} – {self.method} {self.endpoint}'


class ApiUsageSnapshot(models.Model):
    """
    Daily roll-up to speed up charts/analytics without scanning the
    full APIUsageLog table.  Populated by the billing middleware.
    """

    tenant = models.ForeignKey(
        'tenants.Tenant', on_delete=models.CASCADE, related_name='daily_usage'
    )
    date = models.DateField()
    total_requests = models.BigIntegerField(default=0)
    total_errors = models.BigIntegerField(default=0)
    avg_response_ms = models.IntegerField(default=0)
    top_endpoint = models.CharField(max_length=255, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date']
        unique_together = [('tenant', 'date')]
        indexes = [models.Index(fields=['date'])]

    def __str__(self):
        return f'{self.tenant.short_name} – {self.date}'


class EndpointUsageStat(models.Model):
    """
    Per-endpoint aggregated daily counters for breakdown charts.
    """

    tenant = models.ForeignKey(
        'tenants.Tenant', on_delete=models.CASCADE, related_name='endpoint_stats'
    )
    date = models.DateField()
    endpoint = models.CharField(max_length=255)
    method = models.CharField(max_length=10, default='GET')
    count = models.BigIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-count']
        unique_together = [('tenant', 'date', 'endpoint', 'method')]
        indexes = [models.Index(fields=['endpoint'])]

    def __str__(self):
        return f'{self.tenant.short_name} – {self.date} – {self.method} {self.endpoint}'


class MonthlyBill(models.Model):
    """
    A closed invoice covering a calendar month of API usage.

    Created automatically by the ``close_monthly_billing`` Celery task
    on the 1st of every month.  A bill is ``unpaid`` until marked ``paid``.
    """

    class Status(models.TextChoices):
        PAID = 'paid', 'Paid'
        UNPAID = 'unpaid', 'Unpaid'
        OVERDUE = 'overdue', 'Overdue'
        VOID = 'void', 'Void'

    tenant = models.ForeignKey(
        'tenants.Tenant', on_delete=models.CASCADE, related_name='monthly_bills',
    )
    subscription = models.ForeignKey(
        TenantSubscription, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='bills',
    )
    plan = models.ForeignKey(
        BillingPlan, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='bills',
    )
    billing_month = models.DateField()  # first day of billing month
    period_start = models.DateTimeField()
    period_end = models.DateTimeField()

    included_requests = models.BigIntegerField(default=0)
    total_requests = models.BigIntegerField(default=0)
    overage_requests = models.BigIntegerField(default=0)

    # USD amounts (base billing currency)
    rate_per_1000_usd = models.DecimalField(max_digits=10, decimal_places=4, default=USD_RATE_PER_1000)
    usage_cost_usd = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount_usd = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    grand_total_usd = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Legacy fields (retained for compatibility with historical bills)
    plan_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    rate_per_1000 = models.DecimalField(max_digits=10, decimal_places=4, default=0)
    overage_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    grand_total = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Tenant billing currency & exchange rate at invoice time
    billing_currency = models.CharField(max_length=3, default='USD')
    exchange_rate = models.DecimalField(max_digits=12, decimal_places=6, default=Decimal('1'))
    # Local-currency equivalents of the USD amounts above
    usage_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount_local = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    grand_total_local = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.UNPAID,
    )
    paid_at = models.DateTimeField(null=True, blank=True)
    due_date = models.DateField(null=True, blank=True)

    notes = models.TextField(blank=True)
    invoice_number = models.CharField(max_length=50, unique=True, blank=True)

    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='closed_bills',
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-billing_month']
        unique_together = [('tenant', 'billing_month')]
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['billing_month']),
        ]

    def __str__(self):
        return f'{self.tenant.short_name} – {self.billing_month.strftime("%b %Y")}'

    @property
    def is_overdue(self):
        if self.status != self.Status.UNPAID:
            return False
        if not self.due_date:
            return False
        return dj_timezone.now().date() > self.due_date


class Payment(models.Model):
    """Records a payment applied to a MonthlyBill (supports partial)."""

    bill = models.ForeignKey(
        MonthlyBill, on_delete=models.CASCADE, related_name='payments'
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    method = models.CharField(
        max_length=30,
        choices=[
            ('card', 'Card'), ('bank', 'Bank Transfer'),
            ('cash', 'Cash'), ('wallet', 'Wallet'), ('other', 'Other'),
        ],
        default='card',
    )
    reference = models.CharField(max_length=100, blank=True)
    paid_by = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='bill_payments',
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.bill} – {self.amount}'


class ExchangeRate(models.Model):
    """
    Static USD→<currency> exchange rates used for billing conversion.
    Rates are stored as ``1 USD = rate <currency>``.  Updated periodically
    via the admin or a future sync task.
    """

    currency = models.CharField(max_length=3, unique=True)
    rate = models.DecimalField(max_digits=12, decimal_places=6, default=Decimal('1'))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['currency']

    def __str__(self):
        return f'USD → {self.currency} ({self.rate})'

    @classmethod
    def get_rate(cls, currency):
        """Return the USD→currency rate as Decimal (1.0 if missing)."""
        if not currency or currency == 'USD':
            return Decimal('1')
        obj = cls.objects.filter(currency=currency).first()
        return Decimal(obj.rate) if obj else Decimal('1')

    @classmethod
    def convert_from_usd(cls, amount, currency):
        """Convert a USD amount to ``currency`` using stored rates."""
        if not currency or currency == 'USD':
            return Decimal(amount or 0)
        rate = cls.get_rate(currency)
        return (Decimal(amount or 0) * rate).quantize(Decimal('0.01'))

    @classmethod
    def convert_to_usd(cls, amount, currency):
        """Convert an amount in ``currency`` back to USD."""
        if not currency or currency == 'USD':
            return Decimal(amount or 0)
        rate = cls.get_rate(currency)
        if rate == 0:
            return Decimal('0')
        return (Decimal(amount or 0) / rate).quantize(Decimal('0.01'))
