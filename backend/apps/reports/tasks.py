import logging
from datetime import timedelta

from celery import shared_task
from django.db.models import F
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task(bind=True, name='reports.generate_scheduled_reports')
def generate_scheduled_reports(self):
    """Check for due scheduled reports and trigger generation."""
    from .models import ScheduledReport, ReportExecution

    now = timezone.now()
    due = ScheduledReport.objects.filter(is_active=True, next_run__lte=now)
    count = 0
    for schedule in due:
        execution = ReportExecution.objects.create(
            scheduled_report=schedule,
            template=schedule.template,
            status=ReportExecution.Status.PENDING,
            file_format=schedule.format,
        )
        generate_report.delay(execution.id)

        schedule.last_run = now
        if schedule.frequency == 'daily':
            schedule.next_run = now + timedelta(days=1)
        elif schedule.frequency == 'weekly':
            schedule.next_run = now + timedelta(weeks=1)
        elif schedule.frequency == 'monthly':
            schedule.next_run = now + timedelta(days=30)
        elif schedule.frequency == 'quarterly':
            schedule.next_run = now + timedelta(days=90)
        schedule.save(update_fields=['last_run', 'next_run'])
        count += 1

    logger.info('Triggered %d scheduled report(s)', count)
    return count


@shared_task(bind=True, name='reports.generate_report')
def generate_report(self, execution_id):
    """Generate a single report file."""
    from .models import ReportExecution

    try:
        execution = ReportExecution.objects.get(pk=execution_id)
        execution.status = 'pending'
        execution.save(update_fields=['status'])

        template = execution.template
        report_type = template.report_type

        # Collect data based on report type
        from .views import StandardReportsView
        from rest_framework.test import APIRequestFactory

        factory = APIRequestFactory()
        method_map = {
            'cost_per_mile': 'cost_per_mile',
            'fuel_efficiency': 'fuel_efficiency',
            'mechanic_utilization': 'mechanic_utilization',
            'fleet_aging': 'fleet_aging',
        }
        method_name = method_map.get(report_type, 'cost_per_mile')
        view = StandardReportsView()
        request = factory.get('/')
        request.user = template.created_by
        response = getattr(view, method_name)(request)
        data = response.data

        if not data:
            execution.status = 'failed'
            execution.error_message = 'No data to export'
            execution.save()
            return

        # Generate file
        import csv
        import io
        filename = f'{report_type}_{timezone.now().strftime("%Y%m%d")}'

        if execution.file_format == 'csv':
            output = io.StringIO()
            writer = csv.DictWriter(output, fieldnames=data[0].keys())
            writer.writeheader()
            for row in data:
                writer.writerow(row)
            from django.core.files.base import ContentFile
            execution.file.save(f'{filename}.csv', ContentFile(output.getvalue()))
        elif execution.file_format == 'excel':
            from openpyxl import Workbook
            wb = Workbook()
            ws = wb.active
            ws.title = filename[:31]
            ws.append(list(data[0].keys()))
            for row in data:
                ws.append(list(row.values()))
            output = io.BytesIO()
            wb.save(output)
            output.seek(0)
            from django.core.files.base import ContentFile
            execution.file.save(f'{filename}.xlsx', ContentFile(output.getvalue()))

        execution.status = 'completed'
        execution.completed_at = timezone.now()
        execution.save(update_fields=['status', 'completed_at'])
        logger.info('Report %d generated successfully', execution_id)

    except Exception as e:
        logger.exception('Report generation failed: %s', e)
        try:
            execution = ReportExecution.objects.get(pk=execution_id)
            execution.status = 'failed'
            execution.error_message = str(e)
            execution.save(update_fields=['status', 'error_message'])
        except Exception:
            pass


@shared_task(name='fuel.check_fraud')
def check_fraud_on_transaction(transaction_id):
    """Run fraud detection on a newly created fuel transaction."""
    from apps.fuel.models import FuelTransaction
    from apps.fuel.services import run_fraud_checks

    try:
        tx = FuelTransaction.objects.get(pk=transaction_id)
        alerts = run_fraud_checks(tx)
        logger.info('Fraud check on tx %d: %d alert(s)', transaction_id, len(alerts))
        return len(alerts)
    except FuelTransaction.DoesNotExist:
        logger.warning('Transaction %d not found for fraud check', transaction_id)
        return 0


@shared_task(name='reminders.check_escalations')
def check_reminder_escalations():
    """Check overdue reminders and trigger escalations."""
    from apps.reminders.models import Reminder
    from apps.issues.models import Issue, WorkOrder

    now = timezone.now().date()
    overdue = Reminder.objects.filter(is_active=True, next_due_date__lt=now)
    count = 0
    for reminder in overdue:
        if reminder.auto_generate_work_order and not Issue.objects.filter(
            vehicle=reminder.vehicle, title__contains=reminder.title, status__in=['open', 'assigned']
        ).exists():
            issue = Issue.objects.create(
                vehicle=reminder.vehicle,
                title=f'Overdue: {reminder.title}',
                description=f'Auto-generated from reminder. Due date: {reminder.next_due_date}',
                status=Issue.Status.OPEN,
                priority=Issue.Priority.HIGH,
            )
            count += 1
    logger.info('Escalated %d overdue reminder(s)', count)
    return count


@shared_task(name='inventory.check_low_stock')
def check_low_stock():
    """Check for items at or below reorder point and create purchase orders."""
    from apps.inventory.models import InventoryItem, PurchaseOrder, PurchaseOrderItem

    low_items = InventoryItem.objects.filter(quantity_on_hand__lte=F('reorder_point'), is_active=True)
    if not low_items.exists():
        return 0

    po = PurchaseOrder.objects.create(status='draft')
    for item in low_items:
        reorder_qty = max(item.reorder_point * 2 - item.quantity_on_hand, 10)
        PurchaseOrderItem.objects.create(
            purchase_order=po,
            inventory_item=item,
            quantity_ordered=reorder_qty,
            unit_cost=item.unit_cost,
        )
    logger.info('Created auto PO #%d for %d low-stock items', po.id, low_items.count())
    return low_items.count()
