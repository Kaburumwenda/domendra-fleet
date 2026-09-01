from django.db import models


class Service(models.Model):
    class ServiceType(models.TextChoices):
        OIL_CHANGE = 'oil_change', 'Oil Change'
        TIRE_ROTATION = 'tire_rotation', 'Tire Rotation'
        BRAKE_SERVICE = 'brake_service', 'Brake Service'
        INSPECTION = 'inspection', 'Inspection'
        REPAIR = 'repair', 'Repair'
        PREVENTIVE = 'preventive', 'Preventive Maintenance'
        OTHER = 'other', 'Other'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='services')
    work_order = models.ForeignKey('issues.WorkOrder', null=True, blank=True, on_delete=models.SET_NULL, related_name='services')
    service_type = models.CharField(max_length=30, choices=ServiceType.choices, default=ServiceType.PREVENTIVE)
    description = models.TextField(blank=True)
    performed_at = models.DateTimeField()
    cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    vendor = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='services_performed')
    technician = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='services_performed')
    odometer_reading = models.BigIntegerField(null=True, blank=True)
    downtime_hours = models.FloatField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-performed_at']

    def __str__(self):
        return f'{self.get_service_type_display()} – {self.vehicle.display_name}'


class VendorRating(models.Model):
    service = models.OneToOneField(Service, on_delete=models.CASCADE, related_name='rating')
    cost_rating = models.FloatField(default=0, help_text='0-5')
    quality_rating = models.FloatField(default=0, help_text='0-5')
    turnaround_rating = models.FloatField(default=0, help_text='0-5')
    overall_rating = models.FloatField(default=0)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        self.overall_rating = round((self.cost_rating + self.quality_rating + self.turnaround_rating) / 3, 2)
        super().save(*args, **kwargs)
