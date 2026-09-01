"""
Celery tasks for the expenses app.

  • ``materialize_recurring_expenses`` — runs daily (beat), generates
    ``Expense`` rows for every active recurring rule whose next_date is due.
  • ``auto_close_monthly_budgets`` — optional monthly snapshot of budgets.
"""
from datetime import date, timedelta

from celery import shared_task
from django.utils import timezone as dj_timezone

from .models import Expense, RecurringExpense


@shared_task
def materialize_recurring_expenses():
    """Generate expense rows for all due recurring rules.

    Returns the number of expenses created.
    """
    today = date.today()
    qs = RecurringExpense.objects.filter(is_active=True, next_date__lte=today)
    created = 0
    now = dj_timezone.now()
    for rule in qs:
        # honor end_date
        if rule.end_date and rule.next_date > rule.end_date:
            rule.is_active = False
            rule.save(update_fields=['is_active', 'updated_at'])
            continue

        exp = Expense.objects.create(
            title=f'{rule.title} (recurring)',
            description=rule.description,
            category=rule.category,
            amount=rule.amount,
            currency=rule.currency,
            tax_rate=rule.tax_rate,
            expense_date=rule.next_date,
            vendor_name=rule.vendor_name,
            vehicle=rule.vehicle,
            contact=rule.contact,
            payment_method=rule.payment_method,
            status=Expense.Status.PAID if rule.auto_approve else Expense.Status.DRAFT,
            paid_at=now if rule.auto_approve else None,
            recurring_rule=rule,
            created_by=rule.created_by,
        )
        if rule.auto_approve:
            exp.approved_by = rule.created_by
            exp.approved_at = now
            exp.save(update_fields=['approved_by', 'approved_at', 'updated_at'])
        created += 1

        # advance next_date past today
        rule.last_run_at = now
        new_next = rule.compute_next_date(rule.next_date)
        if rule.end_date and new_next > rule.end_date:
            rule.is_active = False
        rule.next_date = new_next
        rule.save(update_fields=['next_date', 'last_run_at', 'is_active', 'updated_at'])

    return created


@shared_task
def auto_close_monthly_budgets():
    """Snapshot / mark budgets as closed at month start (placeholder)."""
    # Kept as an extension point; make_recurring does the heavy lifting daily.
    return 0
