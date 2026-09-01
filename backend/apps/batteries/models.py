from django.db import models
from django.utils import timezone


class Battery(models.Model):
    """A battery asset — in stock, installed in a vehicle, or retired."""

    class Status(models.TextChoices):
        IN_STOCK = 'in_stock', 'In Stock'
        INSTALLED = 'installed', 'Installed'
        SPARE = 'spare', 'Spare'
        CHARGING = 'charging', 'Charging'
        RETIRED = 'retired', 'Retired'
        SCRAPPED = 'scrapped', 'Scrapped'

    class Condition(models.TextChoices):
        NEW = 'new', 'New'
        EXCELLENT = 'excellent', 'Excellent'
        GOOD = 'good', 'Good'
        FAIR = 'fair', 'Fair'
        POOR = 'poor', 'Poor'
        DAMAGED = 'damaged', 'Damaged'

    class Chemistry(models.TextChoices):
        LEAD_ACID = 'lead_acid', 'Lead-Acid'
        AGM = 'agm', 'AGM'
        GEL = 'gel', 'Gel'
        LI_ION = 'li_ion', 'Lithium-Ion'
        LiFEPO4 = 'lifepo4', 'LiFePO4'
        NICD = 'nicd', 'NiCd'
        NIMH = 'nimh', 'NiMH'

    serial_number = models.CharField(max_length=100, unique=True)
    brand = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    part_number = models.CharField(max_length=100, blank=True, help_text='Manufacturer part/SKU number')

    chemistry = models.CharField(max_length=20, choices=Chemistry.choices, default=Chemistry.LEAD_ACID)
    voltage = models.FloatField(default=12, help_text='Nominal voltage (V)')
    capacity_ah = models.FloatField(null=True, blank=True, help_text='Capacity in Amp-hours (Ah)')
    cca = models.FloatField(null=True, blank=True, help_text='Cold Cranking Amps (CCA)')
    rc_minutes = models.FloatField(null=True, blank=True, help_text='Reserve Capacity in minutes')

    condition = models.CharField(max_length=20, choices=Condition.choices, default=Condition.NEW)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.IN_STOCK)
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='batteries')
    position = models.CharField(max_length=50, blank=True, help_text='e.g. Starter, Aux-1, House, Traction')

    purchase_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    purchase_date = models.DateField(null=True, blank=True)
    warranty_months = models.PositiveIntegerField(null=True, blank=True, help_text='Warranty period in months')
    warranty_expiry = models.DateField(null=True, blank=True)

    install_date = models.DateField(null=True, blank=True, help_text='Date first installed in a vehicle')
    last_tested = models.DateField(null=True, blank=True, help_text='Date of last load / conductance test')
    expected_lifespan_months = models.PositiveIntegerField(null=True, blank=True, help_text='Expected service life in months')

    group_code = models.CharField(max_length=30, blank=True, help_text='BCI group code, e.g. 24, 27, 31, 34, 65')
    weight_kg = models.FloatField(null=True, blank=True, help_text='Battery weight in kilograms')
    notes = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Batteries'
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['vehicle']),
            models.Index(fields=['chemistry']),
            models.Index(fields=['condition']),
        ]

    def __str__(self):
        return f'{self.serial_number} – {self.brand} {self.model}'

    # ── Computed properties ──

    @property
    def warranty_expired(self):
        if not self.warranty_expiry:
            return False
        return self.warranty_expiry < timezone.now().date()

    @property
    def warranty_days_left(self):
        if not self.warranty_expiry:
            return None
        delta = self.warranty_expiry - timezone.now().date()
        return max(0, delta.days)

    @property
    def age_months(self):
        """Age of battery in months (from purchase date)."""
        if not self.purchase_date:
            return None
        today = timezone.now().date()
        return (today.year - self.purchase_date.year) * 12 + (today.month - self.purchase_date.month)

    @property
    def needs_replacement(self):
        """True if battery is in poor/damaged condition or past warranty or past expected lifespan."""
        if self.condition in (self.Condition.POOR, self.Condition.DAMAGED):
            return True
        if self.warranty_expired:
            return True
        if self.expected_lifespan_months and self.age_months:
            if self.age_months >= self.expected_lifespan_months:
                return True
        return False

    @property
    def health_pct(self):
        """Computed health percentage (0–100) based on latest reading."""
        latest_read = self.readings.order_by('-measured_at').first()
        if latest_read:
            return latest_read.health_pct
        # estimate from condition
        condition_map = {
            self.Condition.NEW: 100,
            self.Condition.EXCELLENT: 90,
            self.Condition.GOOD: 75,
            self.Condition.FAIR: 55,
            self.Condition.POOR: 30,
            self.Condition.DAMAGED: 10,
        }
        return condition_map.get(self.condition, 80)

    @property
    def last_voltage(self):
        latest = self.readings.order_by('-measured_at').first()
        return latest.voltage if latest else None

    @property
    def last_voltage_date(self):
        latest = self.readings.order_by('-measured_at').first()
        return latest.measured_at if latest else None

    @property
    def cycle_count(self):
        """Total charge cycles recorded."""
        return self.cycles.count()


class BatteryReading(models.Model):
    """Voltage / conductance / health test reading for a battery."""

    battery = models.ForeignKey(Battery, on_delete=models.CASCADE, related_name='readings')
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='battery_readings')
    measured_at = models.DateField(db_index=True)
    voltage = models.FloatField(help_text='Measured voltage (V)')
    specific_gravity = models.FloatField(null=True, blank=True, help_text='Electrolyte specific gravity')
    internal_resistance = models.FloatField(null=True, blank=True, help_text='Internal resistance in milliohms (mΩ)')
    temperature_c = models.FloatField(null=True, blank=True, help_text='Temperature at measurement (°C)')
    soc_pct = models.FloatField(null=True, blank=True, help_text='State of Charge (%)')
    test_result = models.CharField(
        max_length=20,
        choices=[('pass', 'Pass'), ('marginal', 'Marginal'), ('fail', 'Fail'), ('charge', 'Charge & Retest')],
        default='pass',
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-measured_at']
        indexes = [models.Index(fields=['measured_at'])]

    @property
    def health_pct(self):
        """Estimated health percentage (0–100) from voltage."""
        # 12.65V+ = 100%, 12.00V = ~0%
        v = self.voltage or 0
        pct = (v - 11.70) / (12.80 - 11.70) * 100
        return round(max(0, min(100, pct)), 1)


class BatteryMovement(models.Model):
    """Movement log — install, uninstall, swap, charge, retire."""

    class MovementType(models.TextChoices):
        INSTALL = 'install', 'Install'
        UNINSTALL = 'uninstall', 'Uninstall'
        SWAP = 'swap', 'Swap Out'
        CHARGE = 'charge', 'Charge'
        RETIRE = 'retire', 'Retire'

    battery = models.ForeignKey(Battery, on_delete=models.CASCADE, related_name='movements')
    movement_type = models.CharField(max_length=20, choices=MovementType.choices)
    from_vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='battery_movements_from')
    to_vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='battery_movements_to')
    from_position = models.CharField(max_length=50, blank=True)
    to_position = models.CharField(max_length=50, blank=True)
    replaced_by = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL, help_text='If swap, the battery that replaced this one')
    notes = models.TextField(blank=True)
    performed_at = models.DateField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-performed_at']
        indexes = [models.Index(fields=['performed_at'])]


class ChargeCycle(models.Model):
    """Charge cycle history (mainly for Li-ion / LiFePO4 batteries)."""

    battery = models.ForeignKey(Battery, on_delete=models.CASCADE, related_name='cycles')
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    start_voltage = models.FloatField(null=True, blank=True)
    end_voltage = models.FloatField(null=True, blank=True)
    energy_kwh = models.FloatField(null=True, blank=True, help_text='Energy consumed during charge (kWh)')
    charge_method = models.CharField(
        max_length=20,
        choices=[('ac', 'AC'), ('dc', 'DC'), ('regen', 'Regen'), ('alternator', 'Alternator'), ('solar', 'Solar')],
        default='ac',
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class BatteryReplacement(models.Model):
    """Scheduled or ad-hoc replacement record."""

    battery = models.ForeignKey(Battery, on_delete=models.CASCADE, related_name='replacements')
    old_battery = models.ForeignKey(Battery, null=True, blank=True, on_delete=models.SET_NULL, related_name='replaced_by_records')
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='battery_replacements')
    scheduled_date = models.DateField(null=True, blank=True)
    completed_date = models.DateField(null=True, blank=True)
    reason = models.TextField(blank=True, help_text='Reason for replacement (e.g. End of life, Failed load test, Damage)')
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=[('scheduled', 'Scheduled'), ('ordered', 'Ordered'), ('completed', 'Completed'), ('cancelled', 'Cancelled')],
        default='scheduled',
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
