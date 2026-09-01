from django.contrib import admin

from .models import Battery, BatteryReading, BatteryMovement, ChargeCycle, BatteryReplacement


@admin.register(Battery)
class BatteryAdmin(admin.ModelAdmin):
    list_display = ('serial_number', 'brand', 'model', 'chemistry', 'status', 'vehicle', 'position')
    list_filter = ('status', 'chemistry', 'condition', 'brand')
    search_fields = ('serial_number', 'brand', 'model', 'part_number')
    raw_id_fields = ('vehicle',)


@admin.register(BatteryReading)
class BatteryReadingAdmin(admin.ModelAdmin):
    list_display = ('battery', 'vehicle', 'measured_at', 'voltage', 'test_result')
    list_filter = ('test_result',)
    raw_id_fields = ('battery', 'vehicle')


@admin.register(BatteryMovement)
class BatteryMovementAdmin(admin.ModelAdmin):
    list_display = ('battery', 'movement_type', 'from_vehicle', 'to_vehicle', 'performed_at')
    list_filter = ('movement_type',)
    raw_id_fields = ('battery', 'from_vehicle', 'to_vehicle')


@admin.register(ChargeCycle)
class ChargeCycleAdmin(admin.ModelAdmin):
    list_display = ('battery', 'completed_at', 'start_voltage', 'end_voltage', 'energy_kwh', 'charge_method')
    list_filter = ('charge_method',)
    raw_id_fields = ('battery',)


@admin.register(BatteryReplacement)
class BatteryReplacementAdmin(admin.ModelAdmin):
    list_display = ('battery', 'vehicle', 'scheduled_date', 'completed_date', 'status', 'reason')
    list_filter = ('status',)
    raw_id_fields = ('battery', 'old_battery', 'vehicle')
