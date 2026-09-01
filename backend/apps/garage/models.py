from django.db import models


class GarageBay(models.Model):
    class BayType(models.TextChoices):
        LIFT = 'lift', 'Lift Bay'
        FLAT = 'flat', 'Flat Bay'
        PAINT = 'paint', 'Paint Bay'
        WASH = 'wash', 'Wash Bay'
        INSPECTION = 'inspection', 'Inspection Bay'
        GENERAL = 'general', 'General Bay'

    name = models.CharField(max_length=100, unique=True)
    bay_type = models.CharField(max_length=20, choices=BayType.choices, default=BayType.GENERAL)
    capacity = models.IntegerField(default=1, help_text='Number of vehicles per bay')
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def is_occupied(self):
        now = timezone.now()
        return self.reservations.filter(status='active', start_time__lte=now, end_time__gte=now).exists()


class BayReservation(models.Model):
    class Status(models.TextChoices):
        SCHEDULED = 'scheduled', 'Scheduled'
        ACTIVE = 'active', 'Active'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    bay = models.ForeignKey(GarageBay, on_delete=models.CASCADE, related_name='reservations')
    work_order = models.ForeignKey('issues.WorkOrder', null=True, blank=True, on_delete=models.SET_NULL, related_name='bay_reservations')
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='bay_reservations')
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SCHEDULED)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['start_time']

    @property
    def duration_hours(self):
        return round((self.end_time - self.start_time).total_seconds() / 3600, 1)


from django.utils import timezone  # noqa: E402
