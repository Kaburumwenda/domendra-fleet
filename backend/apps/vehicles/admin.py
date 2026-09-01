from django.contrib import admin

from .models import CustomField, CustomFieldValue, FleetGroup, MeterEntry, Vehicle, VehicleType


@admin.register(FleetGroup)
class FleetGroupAdmin(admin.ModelAdmin):
    list_display = ('name', 'color', 'created_at')
    search_fields = ('name',)


@admin.register(VehicleType)
class VehicleTypeAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon', 'color', 'passenger_capacity', 'cargo_capacity_kg', 'sort_order', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('name', 'description')


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('display_name', 'vin', 'license_plate', 'vehicle_type', 'fuel_type', 'status', 'current_mileage')
    list_filter = ('status', 'fuel_type', 'vehicle_type', 'group')
    search_fields = ('vin', 'license_plate', 'make', 'model')
    raw_id_fields = ('assigned_driver',)


@admin.register(MeterEntry)
class MeterEntryAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'meter_type', 'value', 'recorded_at')
    list_filter = ('meter_type',)
    raw_id_fields = ('vehicle',)


@admin.register(CustomField)
class CustomFieldAdmin(admin.ModelAdmin):
    list_display = ('name', 'label', 'field_type', 'is_required', 'is_active')
    list_filter = ('field_type', 'is_active')
    search_fields = ('name', 'label')


@admin.register(CustomFieldValue)
class CustomFieldValueAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'field', 'value')
    list_filter = ('field',)
    search_fields = ('value',)
    raw_id_fields = ('vehicle', 'field')
