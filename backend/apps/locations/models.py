from django.db import models


class Location(models.Model):
    class LocationType(models.TextChoices):
        DEPOT = 'depot', 'Depot / Yard'
        FUEL_STATION = 'fuel_station', 'Fuel Station'
        CHARGING_STATION = 'charging_station', 'Charging Station'
        WAREHOUSE = 'warehouse', 'Warehouse'
        CUSTOMER_SITE = 'customer_site', 'Customer Site'
        GEOPOINT = 'geopoint', 'Geofence Point'
        SERVICE_CENTER = 'service_center', 'Service Center'
        PARKING_LOT = 'parking_lot', 'Parking Lot'
        REST_STOP = 'rest_stop', 'Rest Stop'
        BORDER_CROSSING = 'border_crossing', 'Border Crossing'
        PORT_TERMINAL = 'port_terminal', 'Port / Terminal'
        AIRPORT = 'airport', 'Airport'
        RAIL_TERMINAL = 'rail_terminal', 'Rail Terminal'
        DISTRIBUTION_CENTER = 'distribution_center', 'Distribution Center'
        DROPOFF = 'dropoff', 'Drop-off Point'
        PICKUP = 'pickup', 'Pick-up Point'
        OFFICE = 'office', 'Office'
        HQ = 'hq', 'HQ'
        MAINTENANCE_BAY = 'maintenance_bay', 'Maintenance Bay'
        TOLL_PLAZA = 'toll_plaza', 'Toll Plaza'
        OTHER = 'other', 'Other'

    class GeofenceShape(models.TextChoices):
        CIRCLE = 'circle', 'Circle'
        POLYGON = 'polygon', 'Polygon'

    name = models.CharField(max_length=200)
    type = models.CharField(max_length=50, default=LocationType.OTHER)
    address = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    # Geofence definition
    is_geofence = models.BooleanField(default=False)
    shape = models.CharField(max_length=20, choices=GeofenceShape.choices, default=GeofenceShape.CIRCLE)
    radius_meters = models.FloatField(null=True, blank=True, help_text='Radius for circle geofences')
    polygon = models.JSONField(default=list, blank=True, help_text='List of [lat, lng] coordinates for polygon geofences')

    color = models.CharField(max_length=7, default='#6366f1')
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def vehicle_count(self):
        # Vehicle.location is a CharField (text), not a FK — match by name
        from apps.vehicles.models import Vehicle
        return Vehicle.objects.filter(location__iexact=self.name).count()
