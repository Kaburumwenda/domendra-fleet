from django.db import models


class ReportTemplate(models.Model):
    class ReportType(models.TextChoices):
        COST_PER_MILE = 'cost_per_mile', 'Cost per Mile/Hour'
        FUEL_EFFICIENCY = 'fuel_efficiency', 'Fuel Efficiency Trends'
        MECHANIC_UTILIZATION = 'mechanic_utilization', 'Mechanic Utilization'
        FLEET_AGING = 'fleet_aging', 'Fleet Aging & Replacement'
        COST_SUMMARY = 'cost_summary', 'Cost Summary'
        CUSTOM = 'custom', 'Custom Report'

    name = models.CharField(max_length=200)
    report_type = models.CharField(max_length=30, choices=ReportType.choices, default=ReportType.COST_SUMMARY)
    description = models.TextField(blank=True)
    configuration = models.JSONField(default=dict, blank=True, help_text='Metrics, dimensions, filters')
    created_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='report_templates')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class ScheduledReport(models.Model):
    class Frequency(models.TextChoices):
        DAILY = 'daily', 'Daily'
        WEEKLY = 'weekly', 'Weekly'
        MONTHLY = 'monthly', 'Monthly'
        QUARTERLY = 'quarterly', 'Quarterly'

    class Format(models.TextChoices):
        PDF = 'pdf', 'PDF'
        EXCEL = 'excel', 'Excel'
        CSV = 'csv', 'CSV'

    template = models.ForeignKey(ReportTemplate, on_delete=models.CASCADE, related_name='schedules')
    frequency = models.CharField(max_length=20, choices=Frequency.choices, default=Frequency.MONTHLY)
    format = models.CharField(max_length=10, choices=Format.choices, default=Format.PDF)
    recipients = models.TextField(blank=True, help_text='Comma-separated email addresses')
    is_active = models.BooleanField(default=True)
    last_run = models.DateTimeField(null=True, blank=True)
    next_run = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['next_run']


class ReportExecution(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        COMPLETED = 'completed', 'Completed'
        FAILED = 'failed', 'Failed'

    scheduled_report = models.ForeignKey(ScheduledReport, null=True, blank=True, on_delete=models.SET_NULL, related_name='executions')
    template = models.ForeignKey(ReportTemplate, on_delete=models.CASCADE, related_name='executions')
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    file = models.FileField(upload_to='reports/', blank=True, null=True)
    file_format = models.CharField(max_length=10, default='pdf')
    error_message = models.TextField(blank=True)
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-started_at']
