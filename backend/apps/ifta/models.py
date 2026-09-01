from django.db import models


class Jurisdiction(models.Model):
    """A US state, Canadian province, or Mexican entity used for IFTA reporting."""
    code = models.CharField(max_length=4, unique=True, help_text='IFTA jurisdiction code, e.g. CA, TX, ON')
    name = models.CharField(max_length=100)
    country = models.CharField(max_length=50, blank=True)
    fuel_tax_rate = models.DecimalField(max_digits=8, decimal_places=4, default=0, help_text='Tax rate per gallon')
    is_ifta = models.BooleanField(default=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f'{self.code} – {self.name}'


class TripLog(models.Model):
    """Per-jurisdiction trip mileage entry (manually logged or derived from telematics trips)."""
    class DistanceUnit(models.TextChoices):
        MILES = 'miles', 'Miles'
        KILOMETERS = 'km', 'Kilometers'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='ifta_trip_logs')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='ifta_trip_logs')
    jurisdiction = models.ForeignKey(Jurisdiction, on_delete=models.PROTECT, related_name='trip_logs')

    date = models.DateField(db_index=True)
    start_odometer = models.FloatField(null=True, blank=True)
    end_odometer = models.FloatField(null=True, blank=True)
    distance = models.FloatField(default=0, help_text='Distance traveled in this jurisdiction')
    distance_unit = models.CharField(max_length=10, choices=DistanceUnit.choices, default=DistanceUnit.MILES)

    trip_type = models.CharField(max_length=20, choices=[('loaded', 'Loaded'), ('empty', 'Empty'), ('bobtail', 'Bobtail')], default='loaded')
    route = models.CharField(max_length=200, blank=True, help_text='From / To description')
    notes = models.TextField(blank=True)
    source = models.CharField(max_length=20, choices=[('manual', 'Manual'), ('telematics', 'Telematics')], default='manual')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        indexes = [models.Index(fields=['vehicle', 'date'])]

    def __str__(self):
        return f'{self.vehicle} – {self.jurisdiction.code} – {self.date}'

    @property
    def distance_miles(self):
        if self.distance_unit == self.DistanceUnit.MILES:
            return self.distance
        return round(self.distance * 0.621371, 2)


class FuelPurchase(models.Model):
    """Fuel purchases attributed to a jurisdiction for IFTA credit calculation."""
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='ifta_fuel_purchases')
    jurisdiction = models.ForeignKey(Jurisdiction, on_delete=models.PROTECT, related_name='fuel_purchases')
    date = models.DateField(db_index=True)
    gallons = models.FloatField()
    total_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_paid = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Fuel tax already paid at the pump')
    vendor = models.CharField(max_length=200, blank=True)
    source = models.CharField(max_length=20, choices=[('manual', 'Manual'), ('fuel_card', 'Fuel Card')], default='manual')
    fuel_transaction = models.ForeignKey('fuel.FuelTransaction', null=True, blank=True, on_delete=models.SET_NULL, related_name='ifta_purchases')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        indexes = [models.Index(fields=['vehicle', 'date'])]

    @property
    def price_per_gallon(self):
        if not self.gallons:
            return 0
        return float(self.total_cost) / self.gallons


class IftaQuarter(models.Model):
    """Aggregated quarterly IFTA report per vehicle."""
    class Quarter(models.TextChoices):
        Q1 = 'Q1', 'Q1 (Jan–Mar)'
        Q2 = 'Q2', 'Q2 (Apr–Jun)'
        Q3 = 'Q3', 'Q3 (Jul–Sep)'
        Q4 = 'Q4', 'Q4 (Oct–Dec)'

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        SUBMITTED = 'submitted', 'Submitted'
        FILED = 'filed', 'Filed'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='ifta_quarters')
    year = models.IntegerField()
    quarter = models.CharField(max_length=2, choices=Quarter.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    total_miles = models.FloatField(default=0)
    total_gallons = models.FloatField(default=0)
    total_tax_due = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_tax_credit = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    net_tax = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('vehicle', 'year', 'quarter')
        ordering = ['-year', '-quarter']

    def __str__(self):
        return f'{self.vehicle} – {self.year} {self.quarter}'

    @property
    def label(self):
        return f'{self.year} {self.quarter}'
