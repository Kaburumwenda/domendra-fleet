from django.db import models
from django.utils import timezone


class Recall(models.Model):
    class RecallType(models.TextChoices):
        SAFETY_RECALL = 'safety_recall', 'Safety Recall'
        CAMPAIGN = 'campaign', 'Service Campaign'
        FIELD_NOTICE = 'field_notice', 'Field Notice'
        EMISSION = 'emission', 'Emission Recall'

    class Status(models.TextChoices):
        OPEN = 'open', 'Open'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        CLOSED = 'closed', 'Closed'

    title = models.CharField(max_length=300)
    recall_type = models.CharField(max_length=20, choices=RecallType.choices, default=RecallType.SAFETY_RECALL)
    nhtsa_campaign_number = models.CharField(max_length=50, blank=True, help_text='NHTSA recall campaign number')
    manufacturer_campaign_number = models.CharField(max_length=50, blank=True)
    oem = models.CharField(max_length=100, blank=True, help_text='Manufacturer / OEM issuing the recall')
    component = models.CharField(max_length=200, blank=True, help_text='Affected component, e.g. Brakes, Fuel System')
    description = models.TextField(blank=True)
    remedy = models.TextField(blank=True)
    risk = models.TextField(blank=True, help_text='Safety risk if not addressed')
    issue_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    is_critical = models.BooleanField(default=False)

    affected_make = models.CharField(max_length=100, blank=True, help_text='Applies to vehicles of this make')
    affected_models = models.TextField(blank=True, help_text='Comma-separated models')
    affected_year_from = models.IntegerField(null=True, blank=True)
    affected_year_to = models.IntegerField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-issue_date', '-created_at']
        indexes = [models.Index(fields=['status']), models.Index(fields=['recall_type'])]

    def __str__(self):
        return f'{self.title} ({self.get_recall_type_display()})'


class RecallVehicle(models.Model):
    """Links a recall to specific affected vehicles with tracking of resolution."""
    class ResolutionStatus(models.TextChoices):
        AFFECTED = 'affected', 'Affected'
        SCHEDULED = 'scheduled', 'Repair Scheduled'
        IN_PROGRESS = 'in_progress', 'In Progress'
        RESOLVED = 'resolved', 'Resolved'
        NOT_AFFECTED = 'not_affected', 'Not Affected'

    recall = models.ForeignKey(Recall, on_delete=models.CASCADE, related_name='vehicles')
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='recalls')
    status = models.CharField(max_length=20, choices=ResolutionStatus.choices, default=ResolutionStatus.AFFECTED)
    scheduled_date = models.DateField(null=True, blank=True)
    resolved_at = models.DateField(null=True, blank=True)
    work_order = models.ForeignKey('issues.WorkOrder', null=True, blank=True, on_delete=models.SET_NULL, related_name='recall_vehicles')
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('recall', 'vehicle')
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.recall.title} – {self.vehicle}'

    @property
    def is_resolved(self):
        return self.status == self.ResolutionStatus.RESOLVED

    @property
    def days_open(self):
        end = self.resolved_at or timezone.now().date()
        return (end - self.created_at.date()).days
