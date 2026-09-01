from datetime import timedelta

from django.db import models


class Job(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ASSIGNED = 'assigned', 'Assigned'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    class Priority(models.TextChoices):
        LOW = 'low', 'Low'
        MEDIUM = 'medium', 'Medium'
        HIGH = 'high', 'High'
        URGENT = 'urgent', 'Urgent'

    title = models.CharField(max_length=300)
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='jobs')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='jobs', limit_choices_to={'contact_type': 'driver'})
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    priority = models.CharField(max_length=10, choices=Priority.choices, default=Priority.MEDIUM)
    pickup_address = models.CharField(max_length=300, blank=True)
    dropoff_address = models.CharField(max_length=300, blank=True)
    pickup_lat = models.FloatField(null=True, blank=True)
    pickup_lng = models.FloatField(null=True, blank=True)
    dropoff_lat = models.FloatField(null=True, blank=True)
    dropoff_lng = models.FloatField(null=True, blank=True)
    scheduled_start = models.DateTimeField(null=True, blank=True)
    scheduled_end = models.DateTimeField(null=True, blank=True)
    actual_start = models.DateTimeField(null=True, blank=True)
    actual_end = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['status'])]

    def __str__(self):
        return self.title

    @property
    def eta_minutes(self):
        """Estimated time of arrival in minutes from scheduled_start to dropoff."""
        if self.scheduled_end and self.scheduled_start:
            return round((self.scheduled_end - self.scheduled_start).total_seconds() / 60)
        return None

    @property
    def is_on_schedule(self):
        """Check if job is adhering to schedule.

        For completed jobs: on-time if actual_end <= scheduled_end.
        For in-progress jobs: on-time if actual_start <= scheduled_start + 25% of the
        scheduled window (a small grace period so running a bit late still counts as ok).
        Returns None when insufficient data is available.
        """
        from django.utils import timezone

        if self.status == 'completed' and self.actual_end and self.scheduled_end:
            return self.actual_end <= self.scheduled_end
        if self.status == 'in_progress' and self.actual_start:
            if not self.scheduled_end or not self.scheduled_start:
                return None
            window = (self.scheduled_end - self.scheduled_start)
            grace = timedelta(seconds=window.total_seconds() * 0.25)
            return self.actual_start <= (self.scheduled_start + grace)
        if self.actual_start and self.scheduled_end:
            return self.actual_start <= self.scheduled_end
        return None


class RouteStop(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ARRIVED = 'arrived', 'Arrived'
        DEPARTED = 'departed', 'Departed'
        SKIPPED = 'skipped', 'Skipped'

    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='stops')
    sequence = models.IntegerField(default=0)
    address = models.CharField(max_length=300)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    scheduled_arrival = models.DateTimeField(null=True, blank=True)
    actual_arrival = models.DateTimeField(null=True, blank=True)
    scheduled_departure = models.DateTimeField(null=True, blank=True)
    actual_departure = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    notes = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['sequence']


class VehicleAssignment(models.Model):
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='assignments')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='assignments', limit_choices_to={'contact_type': 'driver'})
    job = models.OneToOneField(Job, null=True, blank=True, on_delete=models.SET_NULL, related_name='assignment')
    assigned_at = models.DateTimeField(auto_now_add=True)
    unassigned_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-assigned_at']
