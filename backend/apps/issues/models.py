from decimal import Decimal
from django.db import models


class Issue(models.Model):
    class Status(models.TextChoices):
        OPEN = 'open', 'Open'
        ASSIGNED = 'assigned', 'Assigned'
        PARTS_ORDERED = 'parts_ordered', 'Parts Ordered'
        IN_PROGRESS = 'in_progress', 'In Progress'
        RESOLVED = 'resolved', 'Resolved'
        CLOSED = 'closed', 'Closed'

    class Priority(models.TextChoices):
        LOW = 'low', 'Low'
        MEDIUM = 'medium', 'Medium'
        HIGH = 'high', 'High'
        CRITICAL = 'critical', 'Critical'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='issues')
    vendor = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='issues')
    reported_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='reported_issues')
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    priority = models.CharField(max_length=10, choices=Priority.choices, default=Priority.MEDIUM)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['status']), models.Index(fields=['priority'])]

    def __str__(self):
        return self.title

    @property
    def has_work_order(self):
        return hasattr(self, 'work_order')

    @property
    def work_order_id(self):
        return self.work_order.id if hasattr(self, 'work_order') else None


class IssuePhoto(models.Model):
    """Photos attached to an issue (e.g. damage photos, diagnostic snapshots)."""
    issue = models.ForeignKey(Issue, on_delete=models.CASCADE, related_name='issue_photos')
    image = models.ImageField(upload_to='issue-photos/')
    caption = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class WorkOrder(models.Model):
    class Status(models.TextChoices):
        OPEN = 'open', 'Open'
        ASSIGNED = 'assigned', 'Assigned'
        PARTS_ORDERED = 'parts_ordered', 'Parts Ordered'
        IN_PROGRESS = 'in_progress', 'In Progress'
        ON_HOLD = 'on_hold', 'On Hold'
        COMPLETED = 'completed', 'Completed'
        CLOSED = 'closed', 'Closed'

    class AssignmentType(models.TextChoices):
        INTERNAL = 'internal', 'Internal Mechanic'
        EXTERNAL = 'external', 'External Shop'

    issue = models.OneToOneField(Issue, on_delete=models.CASCADE, related_name='work_order')
    assigned_to = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='work_orders')
    assignment_type = models.CharField(max_length=10, choices=AssignmentType.choices, default=AssignmentType.INTERNAL)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    actual_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    parts_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    labor_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    downtime_hours = models.FloatField(default=0)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    internal_notes = models.TextField(blank=True, help_text='Visible to mechanics only')
    external_notes = models.TextField(blank=True, help_text='Visible to driver and manager')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    @property
    def total_cost(self):
        return self.actual_cost + self.parts_cost + self.labor_cost


class WorkOrderNote(models.Model):
    class Visibility(models.TextChoices):
        INTERNAL = 'internal', 'Internal (mechanic only)'
        EXTERNAL = 'external', 'External (visible to driver/manager)'

    work_order = models.ForeignKey(WorkOrder, on_delete=models.CASCADE, related_name='notes')
    author = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL)
    visibility = models.CharField(max_length=10, choices=Visibility.choices, default=Visibility.INTERNAL)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)


class TimeLog(models.Model):
    work_order = models.ForeignKey(WorkOrder, on_delete=models.CASCADE, related_name='time_logs')
    mechanic = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='time_logs')
    clock_in = models.DateTimeField()
    clock_out = models.DateTimeField(null=True, blank=True)
    hours = models.FloatField(default=0)

    def save(self, *args, **kwargs):
        if self.clock_out and self.clock_in:
            from datetime import timedelta
            diff = self.clock_out - self.clock_in
            self.hours = round(diff.total_seconds() / 3600, 2)
        super().save(*args, **kwargs)


class PartUsage(models.Model):
    work_order = models.ForeignKey(WorkOrder, on_delete=models.CASCADE, related_name='parts_used')
    inventory_item = models.ForeignKey('inventory.InventoryItem', on_delete=models.PROTECT, related_name='usages')
    quantity = models.FloatField(default=1)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    @property
    def total_cost(self):
        return Decimal(str(self.quantity)) * self.unit_cost
