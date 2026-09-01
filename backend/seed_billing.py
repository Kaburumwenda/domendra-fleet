"""
Seed exchange rates and ensure every active tenant has a subscription.

Billing is purely usage-based: USD 0.077 per 1,000 API requests.
Exchange rates convert USD amounts to the tenant's billing currency.

Usage:
    python seed_billing.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from decimal import Decimal
from django_tenants.utils import schema_context

from apps.billing.models import ExchangeRate, TenantSubscription
from apps.tenants.models import Tenant


# 1 USD = rate <currency> (approximate; update periodically)
EXCHANGE_RATES = {
    'USD': Decimal('1'),
    'EUR': Decimal('0.92'),
    'GBP': Decimal('0.79'),
    'KES': Decimal('129'),
    'NGN': Decimal('1600'),
    'ZAR': Decimal('18.5'),
    'AED': Decimal('3.67'),
    'SAR': Decimal('3.75'),
    'INR': Decimal('83.5'),
    'CAD': Decimal('1.36'),
    'AUD': Decimal('1.52'),
    'JPY': Decimal('155'),
    'CNY': Decimal('7.25'),
    'BRL': Decimal('5.68'),
    'GHS': Decimal('15.5'),
    'TZS': Decimal('2650'),
    'UGX': Decimal('3780'),
    'RWF': Decimal(1290),
    'ETB': Decimal('138'),
}


def run():
    with schema_context('public'):
        # Seed exchange rates
        created_rates = 0
        for currency, rate in EXCHANGE_RATES.items():
            obj, created = ExchangeRate.objects.update_or_create(
                currency=currency, defaults={'rate': rate},
            )
            if created:
                created_rates += 1
            print(f'  rate: USD→{obj.currency} = {obj.rate} (created={created})')

        # Ensure every tenant has a usage-based subscription
        import calendar
        from datetime import datetime, time as dtime
        from django.utils import timezone
        now = timezone.now()
        year = now.year + (1 if now.month == 12 else 0)
        month = (now.month % 12) + 1
        last_day = calendar.monthrange(year, month)[1]
        period_end = datetime.combine(
            datetime(year, month, last_day).date(), dtime.max,
            tzinfo=timezone.get_current_timezone(),
        )

        tenant_count = 0
        created_subs = 0
        for tenant in Tenant.objects.filter(is_active=True):
            tenant_count += 1
            currency = getattr(tenant, 'currency', 'USD') or 'USD'
            _, created = TenantSubscription.objects.get_or_create(
                tenant=tenant,
                defaults={
                    'status': TenantSubscription.Status.ACTIVE,
                    'rate_per_1000_requests': Decimal('0.077'),
                    'billing_currency': currency,
                    'current_period_end': period_end,
                },
            )
            if created:
                created_subs += 1
            else:
                # Update existing subs to usage-based billing
                TenantSubscription.objects.filter(tenant=tenant).update(
                    rate_per_1000_requests=Decimal('0.077'),
                    billing_currency=currency,
                )

        print(f'\nSeeded {created_rates} exchange rates, '
              f'ensured subscriptions for {tenant_count} tenants '
              f'({created_subs} new).')


if __name__ == '__main__':
    run()
