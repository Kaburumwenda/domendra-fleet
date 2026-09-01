from decimal import Decimal

from django.db import models
from django.utils import timezone


class FleetGroup(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=7, default='#6366f1')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class Vehicle(models.Model):
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

    class VehicleType(models.TextChoices):
        VEHICLE = 'vehicle', 'Vehicle'
        TRAILER = 'trailer', 'Trailer'
        EQUIPMENT = 'equipment', 'Equipment'
        NON_POWERED = 'non_powered', 'Non-powered Asset'

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        OUT_OF_SERVICE = 'out_of_service', 'Out of Service'
        IN_MAINTENANCE = 'in_maintenance', 'In Maintenance'
        RETIRED = 'retired', 'Retired'

    class Ownership(models.TextChoices):
        SELF = 'self', 'Owned (Self)'
        LEASE = 'lease', 'Leased'

    class MileageUnit(models.TextChoices):
        MILES = 'miles', 'Miles'
        KILOMETERS = 'km', 'Kilometers'

    class Steering(models.TextChoices):
        LEFT = 'left', 'Left Hand'
        RIGHT = 'right', 'Right Hand'

    class Drivetrain(models.TextChoices):
        TWO_WD = '2WD', '2WD'
        FOUR_WD = '4WD', '4WD'
        FOUR_TWO = '4-2', '4x2'
        FOUR_FOUR = '4-4', '4x4'
        SIX_TWO = '6-2', '6x2'
        SIX_FOUR = '6-4', '6x4'
        EIGHT_FOUR = '8-4', '8x4'

    vin = models.CharField(max_length=17, unique=True)
    license_plate = models.CharField(max_length=20, blank=True)
    make = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    year = models.IntegerField(null=True, blank=True)
    body_type = models.CharField(max_length=50, blank=True, default='')
    vehicle_type = models.CharField(max_length=100, blank=True, default='', help_text='Fleet vehicle category (e.g. SUV, Mini-van, Truck) — managed in the Vehicle Types tab')
    image = models.ImageField(upload_to='vehicles/', null=True, blank=True, help_text='Vehicle photo')
    fuel_type = models.CharField(max_length=50, default=FuelType.PETROL)
    color = models.CharField(max_length=50, blank=True)
    current_mileage = models.BigIntegerField(default=0, help_text='Odometer reading in the selected mileage unit')
    mileage_unit = models.CharField(max_length=10, choices=MileageUnit.choices, default=MileageUnit.KILOMETERS)
    engine_hours = models.FloatField(default=0)
    group = models.ForeignKey(FleetGroup, null=True, blank=True, on_delete=models.SET_NULL, related_name='vehicles')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    location = models.CharField(max_length=200, blank=True)
    assigned_driver = models.ForeignKey(
        'contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='assigned_vehicles', limit_choices_to={'contact_type': 'driver'},
    )

    # Ownership / leasing
    ownership = models.CharField(max_length=10, choices=Ownership.choices, default=Ownership.SELF)
    lessor = models.ForeignKey(
        'lessors.Lessor', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='vehicles',
    )
    lease_start_date = models.DateField(null=True, blank=True)
    lease_end_date = models.DateField(null=True, blank=True)
    lease_monthly_rate = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    deposit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, help_text='Lease security deposit')

    # EV fields
    battery_capacity_kwh = models.FloatField(null=True, blank=True)
    state_of_charge = models.FloatField(null=True, blank=True, help_text='Percentage 0-100')
    state_of_health = models.FloatField(null=True, blank=True, help_text='Percentage 0-100')

    # Purchase & depreciation
    purchase_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    purchase_date = models.DateField(null=True, blank=True)
    salvage_value = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    useful_life_years = models.IntegerField(null=True, blank=True)

    # Specs
    engine = models.CharField(max_length=100, blank=True)
    engine_size = models.CharField(max_length=20, blank=True, default='', help_text='Engine displacement in cc, e.g. 2000cc')
    motors = models.CharField(max_length=100, blank=True, default='', help_text='Electric motor configuration, e.g. Dual Motor')
    transmission = models.CharField(max_length=100, blank=True)
    steering = models.CharField(max_length=10, choices=Steering.choices, blank=True, default='')
    drivetrain = models.CharField(max_length=10, choices=Drivetrain.choices, blank=True, default='')
    weight_rating = models.CharField(max_length=50, blank=True)
    tank_capacity = models.FloatField(null=True, blank=True, help_text='Fuel tank capacity in gallons')
    trim = models.CharField(max_length=100, blank=True)
    gross_vehicle_weight = models.FloatField(null=True, blank=True, help_text='GVWR in lbs')

    # Exterior color (name chip) and a custom hex when 'other' is chosen
    exterior_color_custom = models.CharField(max_length=7, blank=True, default='', help_text='Custom hex color when exterior color is "other"')

    # Feature & option groups (multi-select stored as arrays)
    comfort_convenience = models.JSONField(default=list, blank=True, help_text='Comfort & Convenience options')
    dress_up = models.JSONField(default=list, blank=True, help_text='Dress-up / styling options')
    exterior_features = models.JSONField(default=list, blank=True, help_text='Exterior feature options')
    safety_features = models.JSONField(default=list, blank=True, help_text='Safety & assistance options')

    # Lifecycle
    in_service_date = models.DateField(null=True, blank=True, help_text='Date the vehicle entered service')
    out_of_service_date = models.DateField(null=True, blank=True)
    retired_date = models.DateField(null=True, blank=True)

    # Financials
    class DepreciationMethod(models.TextChoices):
        STRAIGHT_LINE = 'straight_line', 'Straight-Line'
        DECLINING_BALANCE = 'declining_balance', 'Declining Balance'
        NONE = 'none', 'None'

    depreciation_method = models.CharField(
        max_length=30, choices=DepreciationMethod.choices, default=DepreciationMethod.STRAIGHT_LINE,
    )
    residual_value = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, help_text='Residual / salvage value')
    monthly_payment = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, help_text='Financing monthly payment')
    insurance_premium = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, help_text='Annual insurance premium')
    insurance_type = models.CharField(max_length=50, blank=True, default='', help_text='Insurance coverage type')
    insurance_start_date = models.DateField(null=True, blank=True)
    insurance_end_date = models.DateField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['status']), models.Index(fields=['group'])]

    def __str__(self):
        return f'{self.year} {self.make} {self.model} ({self.license_plate or self.vin[-6:]})'

    @property
    def display_name(self):
        return f'{self.year or ""} {self.make} {self.model}'.strip() or self.vin

    @property
    def annual_depreciation(self):
        if not self.purchase_price or not self.useful_life_years:
            return Decimal('0')
        return (self.purchase_price - (self.salvage_value or 0)) / self.useful_life_years

    @property
    def current_book_value(self):
        if not self.purchase_price or not self.purchase_date or not self.useful_life_years:
            return self.purchase_price or Decimal('0')
        years_elapsed = (timezone.now().date() - self.purchase_date).days / 365.25
        if years_elapsed >= self.useful_life_years:
            return self.salvage_value or Decimal('0')
        return self.purchase_price - (self.annual_depreciation * Decimal(str(years_elapsed)))


class MeterEntry(models.Model):
    """Odometer / engine-hour readings logged by drivers or mechanics."""
    class MeterType(models.TextChoices):
        MILEAGE = 'mileage', 'Mileage'
        ENGINE_HOURS = 'engine_hours', 'Engine Hours'

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='meter_entries')
    meter_type = models.CharField(max_length=20, choices=MeterType.choices, default=MeterType.MILEAGE)
    value = models.BigIntegerField()
    recorded_at = models.DateTimeField(auto_now_add=True)
    notes = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ['-recorded_at']

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.meter_type == self.MeterType.MILEAGE:
            if self.value > self.vehicle.current_mileage:
                self.vehicle.current_mileage = self.value
                self.vehicle.save(update_fields=['current_mileage'])
        elif self.meter_type == self.MeterType.ENGINE_HOURS:
            self.vehicle.engine_hours = self.value
            self.vehicle.save(update_fields=['engine_hours'])


class CustomField(models.Model):
    """User-defined custom field definition that can be attached to vehicles."""

    class FieldType(models.TextChoices):
        TEXT = 'text', 'Text'
        NUMBER = 'number', 'Number'
        DATE = 'date', 'Date'
        BOOLEAN = 'boolean', 'Yes/No'
        SELECT = 'select', 'Dropdown'

    name = models.CharField(max_length=100, unique=True)
    label = models.CharField(max_length=200, blank=True, help_text='Display label (defaults to name)')
    field_type = models.CharField(max_length=20, choices=FieldType.choices, default=FieldType.TEXT)
    choices = models.JSONField(default=list, blank=True, help_text='Allowed values for select fields')
    is_required = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.label or self.name

    @property
    def display_label(self):
        return self.label or self.name


class CustomFieldValue(models.Model):
    """Stores the value of a custom field for a specific vehicle."""

    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name='custom_field_values')
    field = models.ForeignKey(CustomField, on_delete=models.CASCADE, related_name='values')
    value = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('vehicle', 'field')
        ordering = ['field__name']

    def __str__(self):
        return f'{self.field.display_label}: {self.value}'


class VehicleMake(models.Model):
    """Tenant-managed vehicle make in the catalog."""

    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class VehicleBodyType(models.Model):
    """Tenant-managed vehicle body type definition (label + icon)."""

    label = models.CharField(max_length=50)
    value = models.CharField(max_length=50, unique=True)
    icon = models.CharField(max_length=50, default='mdi-car', help_text='Material Design Icon name')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['label']

    def __str__(self):
        return self.label


class VehicleModel(models.Model):
    """Tenant-managed vehicle model linked to a make and body type."""

    make = models.ForeignKey(VehicleMake, on_delete=models.CASCADE, related_name='models')
    body_type = models.ForeignKey(VehicleBodyType, on_delete=models.CASCADE, related_name='models')
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        unique_together = ('make', 'body_type', 'name')

    def __str__(self):
        return f'{self.make.name} {self.name}'


class VehicleType(models.Model):
    """Tenant-managed vehicle type / category (e.g. SUV, Mini-van, Sedan, Pickup).

    A top-level classification used for pricing, dispatch, and fleet segmentation.
    Distinct from the catalog's VehicleBodyType — this is a broader fleet category.
    """

    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=50, default='mdi-car', help_text='Material Design Icon name')
    color = models.CharField(max_length=7, default='#6366f1', help_text='Hex colour for chips / badges')
    passenger_capacity = models.PositiveIntegerField(default=0, help_text='Max passengers (0 = not specified)')
    cargo_capacity_kg = models.FloatField(default=0, help_text='Cargo capacity in kg (0 = not specified)')
    is_active = models.BooleanField(default=True)
    sort_order = models.IntegerField(default=0, help_text='Lower values appear first')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['sort_order', 'name']
        verbose_name = 'Vehicle Type'
        verbose_name_plural = 'Vehicle Types'

    def __str__(self):
        return self.name

