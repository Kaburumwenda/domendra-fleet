"""
Celery tasks for the billing app.

* ``close_monthly_billing`` — runs on the 1st of every month (scheduled
  via django-celery-beat DatabaseScheduler).  For every active
  ``TenantSubscription`` it:

    1. Snapshots the current month's usage into a ``MonthlyBill``.
    2. Marks any unpaid bills from prior months as ``overdue``.
    3. Resets the subscription's request counter & period for the new cycle.

* ``mark_overdue_bills`` — daily housekeeping that flips unpaid bills past
  their due date to ``overdue``.
"""
import calendar
import logging
from datetime import datetime, time as dtime, timedelta
from decimal import Decimal

from celery import shared_task
from django.db import transaction
from django.db.models import F, Sum
from django.utils import timezone as dj_timezone
from django_tenants.utils import schema_context

from .models import (
    MonthlyBill, TenantSubscription, BillingPlan, ApiUsageSnapshot,
)

logger = logging.getLogger(__name__)


def _month_ends(reference=None):
    """Return (start_dt, end_dt, billing_month_date) for the month that just
    closed relative to *reference* (defaults to now)."""
    now = reference or dj_timezone.now()
    # First day of current month
    first_this = now.date().replace(day=1)
    # End of last month = day before first of this month
    last_day_prev_month = first_this - timedelta(days=1)
    start = datetime.combine(
        last_day_prev_month.replace(day=1), dtime.min,
        tzinfo=dj_timezone.get_current_timezone(),
    )
    end = datetime.combine(
        last_day_prev_month, dtime.max,
        tzinfo=dj_timezone.get_current_timezone(),
    )
    return start, end, last_day_prev_month.replace(day=1)


def _generate_invoice_number(tenant_name, billing_month):
    slug = (tenant_name or 'TENANT')[:4].upper().replace(' ', '')
    return f'INV-{slug}-{billing_month.strftime("%Y%m")}'


@shared_task(name='billing.close_monthly_billing')
def close_monthly_billing():
    """
    Close the previous month's billing for every active subscription and
    reset their counters for the new cycle.
    """
    now = dj_timezone.now()
    start, end, billing_month = _month_ends(now)
    new_cycle_start = datetime.combine(
        now.date(), dtime.min, tzinfo=dj_timezone.get_current_timezone(),
    )
    # Compute next period end (one month from now)
    year = now.year + (1 if now.month == 12 else 0)
    month = (now.month % 12) + 1
    last_day = calendar.monthrange(year, month)[1]
    new_period_end = datetime.combine(
        datetime(year, month, last_day).date(), dtime.max,
        tzinfo=dj_timezone.get_current_timezone(),
    )

    closed = 0
    skipped = 0

    with schema_context('public'):
        subs = TenantSubscription.objects.select_related('tenant', 'plan').filter(
            status__in=[TenantSubscription.Status.ACTIVE,
                        TenantSubscription.Status.PAST_DUE],
        )

        for sub in subs:
            try:
                with transaction.atomic():
                    # Avoid duplicate billing for the same month
                    existing = MonthlyBill.objects.filter(
                        tenant=sub.tenant, billing_month=billing_month,
                    ).first()
                    if existing:
                        skipped += 1
                        continue

                    total = sub.request_count
                    # Pure usage billing: every request is billable.
                    rate_usd = Decimal('0.077')
                    usage_cost_usd = (
                        Decimal(total) * rate_usd / Decimal('1000')
                    ).quantize(Decimal('0.01'))
                    tax_usd = Decimal('0')
                    grand_usd = usage_cost_usd + tax_usd

                    # Resolve tenant currency & exchange rate
                    tenant_currency = getattr(sub.tenant, 'currency', 'USD') or 'USD'
                    try:
                        from apps.billing.models import ExchangeRate
                        ex_rate = ExchangeRate.get_rate(tenant_currency)
                    except Exception:
                        ex_rate = Decimal('1')
                    usage_cost_local = (
                        usage_cost_usd * ex_rate
                    ).quantize(Decimal('0.01'))
                    tax_local = (tax_usd * ex_rate).quantize(Decimal('0.01'))
                    grand_local = usage_cost_local + tax_local

                    due = billing_month + timedelta(days=15)

                    bill = MonthlyBill.objects.create(
                        tenant=sub.tenant,
                        subscription=sub,
                        plan=sub.plan,
                        billing_month=billing_month,
                        period_start=sub.current_period_start or start,
                        period_end=end,
                        included_requests=0,
                        total_requests=total,
                        overage_requests=0,
                        rate_per_1000_usd=rate_usd,
                        usage_cost_usd=usage_cost_usd,
                        tax_amount_usd=tax_usd,
                        grand_total_usd=grand_usd,
                        billing_currency=tenant_currency,
                        exchange_rate=ex_rate,
                        usage_cost=usage_cost_local,
                        tax_amount_local=tax_local,
                        grand_total_local=grand_local,
                        # legacy fields (mirror USD for backward compat)
                        plan_price=Decimal('0'),
                        rate_per_1000=rate_usd,
                        overage_cost=Decimal('0'),
                        total_amount=grand_usd,
                        tax_amount=tax_usd,
                        grand_total=grand_usd,
                        status=MonthlyBill.Status.UNPAID,
                        due_date=due,
                        invoice_number=_generate_invoice_number(
                            sub.tenant.short_name,
                            billing_month,
                        ),
                    )

                    # Reset the counter for the new cycle
                    sub.request_count = 0
                    sub.overage_cost = Decimal('0')
                    sub.current_period_start = new_cycle_start
                    sub.current_period_end = new_period_end
                    sub.save(update_fields=[
                        'request_count', 'overage_cost',
                        'current_period_start', 'current_period_end',
                    ])

                    # Mark subscription past_due if there are unpaid bills
                    unpaid = MonthlyBill.objects.filter(
                        tenant=sub.tenant,
                        status=MonthlyBill.Status.UNPAID,
                    ).exclude(id=bill.id).exists()
                    if unpaid:
                        sub.status = TenantSubscription.Status.PAST_DUE
                        sub.save(update_fields=['status'])

                    closed += 1
            except Exception as exc:
                logger.exception(
                    'Failed to close billing for %s: %s',
                    getattr(sub.tenant, 'short_name', '?'), exc,
                )

    # Mark overdue bills (best-effort; skip if broker unavailable)
    try:
        mark_overdue_bills.apply_async(countdown=60)
    except Exception as exc:
        logger.warning('Could not queue mark_overdue_bills: %s', exc)
        try:
            mark_overdue_bills()
        except Exception as exc2:
            logger.warning('mark_overdue_bills inline failed: %s', exc2)

    logger.info(
        'Monthly billing close complete: %d bills created, %d skipped.',
        closed, skipped,
    )
    return {'closed': closed, 'skipped': skipped, 'billing_month': billing_month.isoformat()}


@shared_task(name='billing.mark_overdue_bills')
def mark_overdue_bills():
    """Flip unpaid bills past their due date to overdue."""
    today = dj_timezone.now().date()
    updated = 0
    with schema_context('public'):
        bills = MonthlyBill.objects.filter(
            status=MonthlyBill.Status.UNPAID,
            due_date__lt=today,
        )
        updated = bills.update(status=MonthlyBill.Status.OVERDUE)
    logger.info('Marked %d bills as overdue.', updated)
    return {'marked_overdue': updated}


@shared_task(name='billing.ensure_subscriptions')
def ensure_subscriptions():
    """
    Ensure every active tenant has a subscription.
    Billing is purely usage-based — no plan required.
    """
    from apps.tenants.models import Tenant

    created = 0
    with schema_context('public'):
        now = dj_timezone.now()
        year = now.year + (1 if now.month == 12 else 0)
        month = (now.month % 12) + 1
        last_day = calendar.monthrange(year, month)[1]
        period_end = datetime.combine(
            datetime(year, month, last_day).date(), dtime.max,
            tzinfo=dj_timezone.get_current_timezone(),
        )

        for tenant in Tenant.objects.filter(is_active=True):
            obj, created_now = TenantSubscription.objects.get_or_create(
                tenant=tenant,
                defaults={
                    'status': TenantSubscription.Status.ACTIVE,
                    'rate_per_1000_requests': Decimal('0.077'),
                    'billing_currency': getattr(tenant, 'currency', 'USD') or 'USD',
                    'current_period_end': period_end,
                },
            )
            if created_now:
                created += 1

    logger.info('Ensured subscriptions; created %d.', created)
    return {'created': created}


@shared_task(name='billing.recompute_snapshots')
def recompute_snapshots():
    """
    Recompute ApiUsageSnapshot roll-ups from the raw APIUsageLog table
    for the current month.  Helpful after schema changes or when
    snapshots drift.
    """
    from .models import APIUsageLog

    now = dj_timezone.now()
    first = now.date().replace(day=1)

    with schema_context('public'):
        # Wipe current month snapshots and rebuild
        ApiUsageSnapshot.objects.filter(date__gte=first).delete()

        logs = APIUsageLog.objects.filter(timestamp__gte=first)
        buckets = {}
        for log in logs:
            key = (log.tenant_id, log.timestamp.date())
            bucket = buckets.setdefault(key, {
                'tenant': log.tenant, 'date': log.timestamp.date(),
                'total': 0, 'errors': 0, 'rt_sum': 0,
                'endpoints': {},
            })
            bucket['total'] += 1
            if log.status_code and log.status_code >= 400:
                bucket['errors'] += 1
            bucket['rt_sum'] += log.response_time_ms or 0
            ep_key = (log.endpoint, log.method)
            bucket['endpoints'][ep_key] = bucket['endpoints'].get(ep_key, 0) + 1

        for (tid, date), v in buckets.items():
            top_ep = max(v['endpoints'].items(), key=lambda x: x[1])[0][0] if v['endpoints'] else ''
            avg_rt = int(v['rt_sum'] / v['total']) if v['total'] else 0
            ApiUsageSnapshot.objects.update_or_create(
                tenant=v['tenant'], date=date,
                defaults={
                    'total_requests': v['total'],
                    'total_errors': v['errors'],
                    'avg_response_ms': avg_rt,
                    'top_endpoint': top_ep,
                },
            )

    logger.info('Snapshots recomputed for current month.')
    return {'recomputed': len(buckets)}
