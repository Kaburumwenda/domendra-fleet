from django.contrib import admin

from .models import Location


@admin.register(Location)
class LocationAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'is_geofence', 'shape', 'latitude', 'longitude', 'is_active')
    list_filter = ('type', 'is_geofence', 'is_active')
    search_fields = ('name', 'address')
