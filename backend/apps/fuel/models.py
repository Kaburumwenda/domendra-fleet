from django.db import models


class FuelCard(models.Model):
    class Provider(models.TextChoices):
        WEX = 'WEX', 'WEX'
        COMDATA = 'Comdata', 'Comdata'
        FLEETCOR = 'Fleetcor', 'Fleetcor'
        BP = 'BP', 'BP'
        OTHER = 'other', 'Other'

    card_number = models.CharField(max_length=50, unique=True)
    provider = models.CharField(max_length=20, choices=Provider.choices, default=Provider.OTHER)
    card_holder_name = models.CharField(max_length=200, blank=True)
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='fuel_cards')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='fuel_cards')
    expiry_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    provider_account_id = models.CharField(max_length=100, blank=True, help_text='Account ID at the card provider used for API sync')
    api_key = models.CharField(max_length=300, blank=True, help_text='Encrypted/stored API credential for provider sync')
    last_synced_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        masked = self.card_number[:4] + '****' if len(self.card_number) > 4 else self.card_number
        return f'{self.provider} {masked}'


class FuelTransaction(models.Model):
    # Fuel-type choices intentionally mirror vehicles.Vehicle.FuelType so fuel
    # transactions use the same taxonomy as the vehicle wizard (Petrol, Diesel,
    # Hybrid (Petrol), Electric, etc.).
    class FuelType(models.TextChoices):
        PETROL = 'Petrol', 'Petrol'
        DIESEL = 'Diesel', 'Diesel'
        HYBRID_PETROL = 'Hybrid (Petrol)', 'Hybrid (Petrol)'
        HYBRID_DIESEL = 'Hybrid (Diesel)', 'Hybrid (Diesel)'
        PLUG_IN_HYBRID_PETROL = 'Plug-in Hybrid (Petrol)', 'Plug-in Hybrid (Petrol)'
        PLUG_IN_HYBRID_DIESEL = 'Plug-in Hybrid (Diesel)', 'Plug-in Hybrid (Diesel)'
        MILD_HYBRID = 'Mild Hybrid', 'Mild Hybrid'
        ELECTRIC = 'Electric', 'Electric'
        FUEL_CELL_HYDROGEN = 'Fuel Cell (Hydrogen)', 'Fuel Cell (Hydrogen)'
        LPG = 'LPG', 'LPG'
        CNG = 'CNG', 'CNG'
        LNG = 'LNG', 'LNG'
        ETHANOL = 'Ethanol (E85)', 'Ethanol (E85)'
        FLEX_FUEL = 'Flex Fuel', 'Flex Fuel'
        BIODIESEL = 'Biodiesel', 'Biodiesel'

    class Unit(models.TextChoices):
        GALLONS = 'gallons', 'Gallons'
        LITERS = 'liters', 'Liters'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='fuel_transactions')
    fuel_card = models.ForeignKey(FuelCard, null=True, blank=True, on_delete=models.SET_NULL, related_name='transactions')
    date = models.DateTimeField()
    fuel_type = models.CharField(max_length=50, choices=FuelType.choices, default=FuelType.PETROL)
    quantity = models.FloatField()
    unit = models.CharField(max_length=10, choices=Unit.choices, default=Unit.GALLONS)
    total_cost = models.DecimalField(max_digits=12, decimal_places=2)
    odometer_reading = models.BigIntegerField(null=True, blank=True)
    station_name = models.CharField(max_length=200, blank=True)
    station_location = models.CharField(max_length=300, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    receipt_image = models.ImageField(upload_to='fuel-receipts/', blank=True, null=True)
    notes = models.TextField(blank=True)
    provider_transaction_id = models.CharField(max_length=100, blank=True, db_index=True, help_text='External ID from fuel-card provider for dedup')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        indexes = [models.Index(fields=['date']), models.Index(fields=['fuel_type'])]
        unique_together = ('fuel_card', 'provider_transaction_id')

    def __str__(self):
        return f'{self.vehicle.display_name} – {self.date.strftime("%Y-%m-%d")}'

    @property
    def price_per_unit(self):
        if self.quantity > 0:
            return round(float(self.total_cost) / self.quantity, 3)
        return 0

    @property
    def mpg(self):
        """Miles per gallon for this fill-up (requires previous odometer reading)."""
        if not self.odometer_reading:
            return None
        prev = FuelTransaction.objects.filter(
            vehicle=self.vehicle, date__lt=self.date, odometer_reading__isnull=False
        ).order_by('-date').first()
        if prev and prev.odometer_reading:
            miles = self.odometer_reading - prev.odometer_reading
            if miles > 0 and self.quantity > 0:
                return round(miles / self.quantity, 1)
        return None


class ChargingSession(models.Model):
    class Network(models.TextChoices):
        CHARGEPOINT = 'chargepoint', 'ChargePoint'
        TESLA = 'tesla', 'Tesla Supercharger'
        EVGO = 'evgo', 'EVgo'
        ELECTRIFY_AMERICA = 'electrify_america', 'Electrify America'
        OTHER = 'other', 'Other'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='charging_sessions')
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(null=True, blank=True)
    energy_kwh = models.FloatField(default=0)
    cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    station_name = models.CharField(max_length=200, blank=True)
    station_network = models.CharField(max_length=30, choices=Network.choices, default=Network.OTHER)
    start_soc = models.FloatField(null=True, blank=True, help_text='Battery % at start')
    end_soc = models.FloatField(null=True, blank=True, help_text='Battery % at end')
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_time']

    @property
    def duration_hours(self):
        if self.end_time and self.start_time:
            return round((self.end_time - self.start_time).total_seconds() / 3600, 2)
        return None

    @property
    def kwh_per_hour(self):
        if self.duration_hours and self.duration_hours > 0:
            return round(self.energy_kwh / self.duration_hours, 2)
        return None


class FuelFraudAlert(models.Model):
    class AlertType(models.TextChoices):
        WRONG_FUEL = 'wrong_fuel', 'Wrong Fuel Type'
        DOUBLE_FUELING = 'double_fueling', 'Double Fueling (1hr)'
        PARKED_FUELING = 'parked_fueling', 'Parked Vehicle Fueling'
        EXCESSIVE_QTY = 'excessive_qty', 'Excessive Quantity'
        OFF_HOURS = 'off_hours', 'Off-Hours Fueling'
        GEOGRAPHIC = 'geographic', 'Geographic Anomaly'

    class Severity(models.TextChoices):
        LOW = 'low', 'Low'
        MEDIUM = 'medium', 'Medium'
        HIGH = 'high', 'High'
        CRITICAL = 'critical', 'Critical'

    class ActionStatus(models.TextChoices):
        OPEN = 'open', 'Open'
        UNDER_REVIEW = 'under_review', 'Under Review'
        RESOLVED = 'resolved', 'Resolved'
        DISMISSED = 'dismissed', 'Dismissed'

    transaction = models.ForeignKey(FuelTransaction, on_delete=models.CASCADE, related_name='fraud_alerts')
    alert_type = models.CharField(max_length=20, choices=AlertType.choices)
    description = models.TextField()
    severity = models.CharField(max_length=10, choices=Severity.choices, default=Severity.MEDIUM)
    action_status = models.CharField(max_length=20, choices=ActionStatus.choices, default=ActionStatus.OPEN)
    is_resolved = models.BooleanField(default=False)
    resolved_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='resolved_fraud_alerts')
    resolved_at = models.DateTimeField(null=True, blank=True)
    status_note = models.TextField(blank=True, help_text='Note explaining the current action status')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['is_resolved']), models.Index(fields=['severity']), models.Index(fields=['action_status'])]


class IdlingEvent(models.Model):
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='idling_events')
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(null=True, blank=True)
    fuel_burn_rate = models.FloatField(default=0.5, help_text='Gallons per hour')
    fuel_price_per_gallon = models.DecimalField(max_digits=8, decimal_places=2, default=3.50)
    location = models.CharField(max_length=300, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_time']

    @property
    def duration_minutes(self):
        if self.end_time and self.start_time:
            return round((self.end_time - self.start_time).total_seconds() / 60)
        return None

    @property
    def duration_hours(self):
        if self.duration_minutes:
            return round(self.duration_minutes / 60, 2)
        return None

    @property
    def fuel_burned(self):
        if self.duration_hours:
            return round(self.duration_hours * self.fuel_burn_rate, 2)
        return None

    @property
    def cost(self):
        if self.fuel_burned:
            return round(self.fuel_burned * float(self.fuel_price_per_gallon), 2)
        return None


class ChargeSchedule(models.Model):
    class RecurringDay(models.TextChoices):
        MON = 'mon', 'Monday'
        TUE = 'tue', 'Tuesday'
        WED = 'wed', 'Wednesday'
        THU = 'thu', 'Thursday'
        FRI = 'fri', 'Friday'
        SAT = 'sat', 'Saturday'
        SUN = 'sun', 'Sunday'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='charge_schedules')
    start_time = models.TimeField()
    end_time = models.TimeField()
    target_soc = models.FloatField(default=80, help_text='Target state of charge %')
    recurring_days = models.CharField(max_length=30, blank=True, help_text='Comma-separated day codes')
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['start_time']


class FuelBudget(models.Model):
    """Monthly fuel budget per vehicle group, location, vehicle type, or whole fleet."""
    class Scope(models.TextChoices):
        FLEET = 'fleet', 'Fleet-wide'
        VEHICLE_TYPE = 'vehicle_type', 'Vehicle Type'
        LOCATION = 'location', 'Location'

    scope = models.CharField(max_length=20, choices=Scope.choices, default=Scope.FLEET)
    target_ref = models.CharField(max_length=100, blank=True, help_text='Vehicle type or location name; blank means all')
    month = models.DateField(help_text='Any day in the target month; only year/month are used')
    budget_amount = models.DecimalField(max_digits=12, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-month']
        unique_together = ('scope', 'target_ref', 'month')

    def __str__(self):
        return f'{self.scope} {self.month.strftime("%Y-%m")} {self.budget_amount}'
