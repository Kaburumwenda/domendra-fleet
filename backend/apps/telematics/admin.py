from django.contrib import admin

from .models import GeofenceEvent, TelematicsAlert, TelematicsDevice, Trip, VehicleLocation


@admin.register(TelematicsDevice)
class TelematicsDeviceAdmin(admin.ModelAdmin):
    list_display = ('serial_number', 'provider', 'vehicle', 'status', 'last_reported_at')
    list_filter = ('provider', 'status')
    search_fields = ('serial_number', 'imei')
    raw_id_fields = ('vehicle',)


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'driver', 'status', 'started_at', 'ended_at', 'distance', 'duration_minutes')
    list_filter = ('status',)
    raw_id_fields = ('vehicle', 'driver', 'device')


@admin.register(VehicleLocation)
class VehicleLocationAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'latitude', 'longitude', 'speed', 'recorded_at')
    raw_id_fields = ('vehicle', 'device')


@admin.register(GeofenceEvent)
class GeofenceEventAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'location', 'event_type', 'occurred_at')
    list_filter = ('event_type',)
    raw_id_fields = ('vehicle', 'location')


@admin.register(TelematicsAlert)
class TelematicsAlertAdmin(admin.ModelAdmin):
    list_display = ('alert_type', 'severity', 'vehicle', 'device', 'triggered_at', 'acknowledged')
    list_filter = ('alert_type', 'severity', 'acknowledged')
    search_fields = ('message',)
    raw_id_fields = ('device', 'vehicle', 'acknowledged_by')
