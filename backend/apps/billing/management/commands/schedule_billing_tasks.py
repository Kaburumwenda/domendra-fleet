"""
Management command to schedule the monthly billing close Celery task.

Usage:
    python manage.py schedule_billing_tasks

Sets up django-celery-beat PeriodicTask entries:
  * ``close_monthly_billing``   — runs at 00:30 on the 1st of every month
  * ``mark_overdue_bills``      — runs daily at 01:00
"""
from django.core.management.base import BaseCommand
from django_celery_beat.models import CrontabSchedule, PeriodicTask


class Command(BaseCommand):
    help = 'Create / update Celery Beat schedules for billing tasks'

    def handle(self, *args, **options):
        # Monthly close on the 1st at 00:30
        monthly, _ = CrontabSchedule.objects.get_or_create(
            minute='30', hour='0', day_of_month='1',
            month_of_year='*', day_of_week='*',
        )
        PeriodicTask.objects.update_or_create(
            name='billing.close_monthly_billing',
            defaults={
                'task': 'billing.close_monthly_billing',
                'crontab': monthly,
                'enabled': True,
            },
        )

        # Daily overdue check at 01:00
        daily, _ = CrontabSchedule.objects.get_or_create(
            minute='0', hour='1', day_of_month='*',
            month_of_year='*', day_of_week='*',
        )
        PeriodicTask.objects.update_or_create(
            name='billing.mark_overdue_bills',
            defaults={
                'task': 'billing.mark_overdue_bills',
                'crontab': daily,
                'enabled': True,
            },
        )

        self.stdout.write(self.style.SUCCESS(
            'Billing tasks scheduled: monthly close (1st at 00:30), '
            'daily overdue check (01:00).'
        ))
