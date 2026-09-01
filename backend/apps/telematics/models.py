from django.db import models
from django.utils import timezone


class TelematicsDevice(models.Model):
    class Provider(models.TextChoices):
        GEOTAB = 'geotab', 'Geotab'
        SAMSARA = 'samsara', 'Samsara'
        KEEPTRUCKIN = 'keeptruckin', 'KeepTruckin (Motive)'
        VERIZON = 'verizon', 'Verizon Connect'
        GENERIC = 'generic', 'Generic / Custom'

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        INACTIVE = 'inactive', 'Inactive'
        OFFLINE = 'offline', 'Offline'

    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='telematics_devices')
    serial_number = models.CharField(max_length=100, unique=True)
    provider = models.CharField(max_length=20, choices=Provider.choices, default=Provider.GENERIC)
    imei = models.CharField(max_length=20, blank=True, db_index=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    installed_at = models.DateField(null=True, blank=True)

    last_latitude = models.FloatField(null=True, blank=True)
    last_longitude = models.FloatField(null=True, blank=True)
    last_heading = models.FloatField(null=True, blank=True, help_text='Degrees 0-360')
    last_speed = models.FloatField(null=True, blank=True, help_text='Speed in vehicle.mileage_unit per hour')
    last_ignition_on = models.BooleanField(default=True)
    last_reported_at = models.DateTimeField(null=True, blank=True)

    # Alert thresholds for this device
    speed_limit = models.FloatField(null=True, blank=True, help_text='Speed limit in vehicle.mileage_unit per hour')
    idle_threshold_minutes = models.FloatField(default=10, help_text='Minutes of inactivity before idle alert')
    low_fuel_threshold = models.FloatField(null=True, blank=True, help_text='Fuel % threshold for low-fuel alert')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['provider', 'status'])]

    def __str__(self):
        return f'{self.get_provider_display()} – {self.serial_number}'

    @property
    def is_stale(self):
        if not self.last_reported_at:
            return True
        return (timezone.now() - self.last_reported_at).total_seconds() > 30 * 60


class VehicleLocation(models.Model):
    """Historical position pings used for live tracking and trip reconstruction."""
    device = models.ForeignKey(TelematicsDevice, on_delete=models.CASCADE, related_name='locations')
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='locations')
    latitude = models.FloatField()
    longitude = models.FloatField()
    heading = models.FloatField(null=True, blank=True)
    speed = models.FloatField(null=True, blank=True)
    ignition_on = models.BooleanField(default=True)
    odometer = models.FloatField(null=True, blank=True)
    recorded_at = models.DateTimeField(db_index=True)

    class Meta:
        ordering = ['-recorded_at']
        indexes = [models.Index(fields=['vehicle', 'recorded_at'])]


class Trip(models.Model):
    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='trips')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='trips')
    device = models.ForeignKey(TelematicsDevice, null=True, blank=True, on_delete=models.SET_NULL, related_name='trips')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)

    start_latitude = models.FloatField(null=True, blank=True)
    start_longitude = models.FloatField(null=True, blank=True)
    start_address = models.CharField(max_length=300, blank=True)
    start_odometer = models.FloatField(null=True, blank=True)
    started_at = models.DateTimeField(db_index=True)

    end_latitude = models.FloatField(null=True, blank=True)
    end_longitude = models.FloatField(null=True, blank=True)
    end_address = models.CharField(max_length=300, blank=True)
    end_odometer = models.FloatField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    distance = models.FloatField(default=0, help_text='Distance traveled in the vehicle mileage unit')
    duration_minutes = models.FloatField(default=0)
    max_speed = models.FloatField(null=True, blank=True)
    idle_minutes = models.FloatField(default=0)
    harsh_braking_events = models.IntegerField(default=0)
    harsh_acceleration_events = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-started_at']
        indexes = [models.Index(fields=['vehicle', 'started_at'])]

    def __str__(self):
        return f'Trip {self.pk} – {self.vehicle} – {self.started_at:%Y-%m-%d %H:%M}'

    @property
    def is_completed(self):
        return self.status == self.Status.COMPLETED

    @property
    def average_speed(self):
        if not self.distance or not self.duration_minutes:
            return None
        return round(self.distance / (self.duration_minutes / 60), 2)


class GeofenceEvent(models.Model):
    class EventType(models.TextChoices):
        ENTER = 'enter', 'Enter'
        EXIT = 'exit', 'Exit'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='geofence_events')
    location = models.ForeignKey('locations.Location', null=True, blank=True, on_delete=models.SET_NULL, related_name='events')
    event_type = models.CharField(max_length=10, choices=EventType.choices)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    occurred_at = models.DateTimeField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-occurred_at']

    def __str__(self):
        return f'{self.get_event_type_display()} {self.location or "geofence"} – {self.vehicle}'


class TelematicsAlert(models.Model):
    class AlertType(models.TextChoices):
        SPEEDING = 'speeding', 'Speeding'
        IDLE = 'idle', 'Excessive Idle'
        HARSH_BRAKING = 'harsh_braking', 'Harsh Braking'
        HARSH_ACCELERATION = 'harsh_acceleration', 'Harsh Acceleration'
        GEOFENCE_VIOLATION = 'geofence_violation', 'Geofence Violation'
        DEVICE_OFFLINE = 'device_offline', 'Device Offline'
        LOW_BATTERY = 'low_battery', 'Low Battery'
        ODOMETER_TAMPER = 'odometer_tamper', 'Odometer Tamper'
        IGNITION_OFF = 'ignition_off', 'Unexpected Ignition Off'
        LOW_FUEL = 'low_fuel', 'Low Fuel'

    class Severity(models.TextChoices):
        INFO = 'info', 'Info'
        WARNING = 'warning', 'Warning'
        CRITICAL = 'critical', 'Critical'

    device = models.ForeignKey(TelematicsDevice, null=True, blank=True, on_delete=models.SET_NULL, related_name='alerts')
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='telematics_alerts')
    alert_type = models.CharField(max_length=30, choices=AlertType.choices, db_index=True)
    severity = models.CharField(max_length=10, choices=Severity.choices, default=Severity.WARNING)
    message = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    speed = models.FloatField(null=True, blank=True)
    threshold = models.FloatField(null=True, blank=True, help_text='Threshold value that was exceeded')
    acknowledged = models.BooleanField(default=False)
    acknowledged_at = models.DateTimeField(null=True, blank=True)
    acknowledged_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='acknowledged_alerts')
    triggered_at = models.DateTimeField(db_index=True, default=timezone.now)
    resolved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-triggered_at']
        indexes = [
            models.Index(fields=['alert_type', 'severity']),
            models.Index(fields=['acknowledged', 'triggered_at']),
        ]

    def __str__(self):
        return f'{self.get_alert_type_display()} – {self.vehicle or self.device} – {self.triggered_at:%Y-%m-%d %H:%M}'
