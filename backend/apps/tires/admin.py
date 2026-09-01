from django.contrib import admin

from .models import Tire, TireInspection, TireMovement, TireRotation


@admin.register(Tire)
class TireAdmin(admin.ModelAdmin):
    list_display = ('serial_number', 'brand', 'size', 'status', 'vehicle', 'position')
    list_filter = ('status', 'type', 'brand')
    search_fields = ('serial_number', 'brand', 'model')
    raw_id_fields = ('vehicle',)


@admin.register(TireInspection)
class TireInspectionAdmin(admin.ModelAdmin):
    list_display = ('tire', 'vehicle', 'measured_at', 'tread_depth', 'pressure_psi', 'condition')
    list_filter = ('condition',)
    raw_id_fields = ('tire', 'vehicle')


@admin.register(TireRotation)
class TireRotationAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'performed_at', 'rotation_pattern', 'odometer')
    raw_id_fields = ('vehicle',)


@admin.register(TireMovement)
class TireMovementAdmin(admin.ModelAdmin):
    list_display = ('tire', 'movement_type', 'from_vehicle', 'to_vehicle', 'performed_at')
    list_filter = ('movement_type',)
    raw_id_fields = ('tire', 'from_vehicle', 'to_vehicle')
