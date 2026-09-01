from django.db import models


class AccidentReport(models.Model):
    class Severity(models.TextChoices):
        MINOR = 'minor', 'Minor'
        MODERATE = 'moderate', 'Moderate'
        SERIOUS = 'serious', 'Serious'
        FATAL = 'fatal', 'Fatal'

    class Status(models.TextChoices):
        REPORTED = 'reported', 'Reported'
        UNDER_INVESTIGATION = 'under_investigation', 'Under Investigation'
        RESOLVED = 'resolved', 'Resolved'
        CLOSED = 'closed', 'Closed'

    class Weather(models.TextChoices):
        CLEAR = 'clear', 'Clear'
        RAIN = 'rain', 'Rain'
        SNOW = 'snow', 'Snow'
        FOG = 'fog', 'Fog'
        STORM = 'storm', 'Storm'

    class RoadCondition(models.TextChoices):
        DRY = 'dry', 'Dry'
        WET = 'wet', 'Wet'
        ICY = 'icy', 'Icy'
        SNOW_COVERED = 'snow_covered', 'Snow Covered'
        UNDER_CONSTRUCTION = 'construction', 'Under Construction'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='accidents')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='accidents')
    client = models.ForeignKey('rentals.Customer', null=True, blank=True, on_delete=models.SET_NULL, related_name='accidents')
    date = models.DateTimeField()
    location = models.CharField(max_length=300)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    severity = models.CharField(max_length=10, choices=Severity.choices, default=Severity.MINOR)
    status = models.CharField(max_length=25, choices=Status.choices, default=Status.REPORTED)
    weather = models.CharField(max_length=10, choices=Weather.choices, default=Weather.CLEAR)
    road_condition = models.CharField(max_length=20, choices=RoadCondition.choices, default=RoadCondition.DRY)
    description = models.TextField()
    fault_tree_analysis = models.TextField(blank=True, help_text='Root cause analysis of the accident')
    police_report_number = models.CharField(max_length=100, blank=True)
    photos = models.ImageField(upload_to='accident-photos/', blank=True, null=True)
    estimated_damage_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='reported_accidents')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date']

    def __str__(self):
        return f'Accident – {self.vehicle.display_name} – {self.date.strftime("%Y-%m-%d")}'

    @property
    def driver_name(self):
        return self.driver.full_name if self.driver else ''

    @property
    def client_name(self):
        return self.client.full_name if self.client else ''

    @property
    def vehicle_name(self):
        return self.vehicle.display_name if self.vehicle else ''


class AccidentWitness(models.Model):
    accident = models.ForeignKey(AccidentReport, on_delete=models.CASCADE, related_name='witnesses')
    name = models.CharField(max_length=200)
    contact_info = models.CharField(max_length=200, blank=True)
    statement = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)


class InsuranceClaim(models.Model):
    class Status(models.TextChoices):
        FILED = 'filed', 'Filed'
        UNDER_REVIEW = 'under_review', 'Under Review'
        APPROVED = 'approved', 'Approved'
        DENIED = 'denied', 'Denied'
        SETTLED = 'settled', 'Settled'
        LITIGATION = 'litigation', 'In Litigation'

    accident = models.OneToOneField(AccidentReport, on_delete=models.CASCADE, related_name='insurance_claim')
    claim_number = models.CharField(max_length=100, blank=True)
    insurance_company = models.CharField(max_length=200, blank=True)
    agent = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='insurance_claims')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.FILED)
    claim_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    settled_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    filed_date = models.DateField(null=True, blank=True)
    settled_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def accident_rate(self):
        """Lambda calculation: accidents per 100k miles for this vehicle."""
        from django.db.models import Count
        vehicle_accidents = AccidentReport.objects.filter(vehicle=self.accident.vehicle).count()
        miles = self.accident.vehicle.current_mileage or 1
        return round(vehicle_accidents / miles * 100000, 4)


class AccidentPhoto(models.Model):
    accident = models.ForeignKey(AccidentReport, on_delete=models.CASCADE, related_name='accident_photos')
    image = models.ImageField(upload_to='accident-photos/'); caption = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
