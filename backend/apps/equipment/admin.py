from django.contrib import admin

from .models import CalibrationRecord, Equipment, EquipmentCategory, EquipmentCheckout, EquipmentMeterEntry


@admin.register(EquipmentCategory)
class EquipmentCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'color', 'created_at')
    search_fields = ('name',)


@admin.register(Equipment)
class EquipmentAdmin(admin.ModelAdmin):
    list_display = ('display_name', 'asset_number', 'category', 'status', 'current_hours', 'requires_calibration', 'next_calibration_due')
    list_filter = ('status', 'category', 'requires_calibration')
    search_fields = ('name', 'asset_number', 'serial_number', 'barcode')
    raw_id_fields = ('assigned_to', 'assigned_vehicle', 'category')


@admin.register(EquipmentCheckout)
class EquipmentCheckoutAdmin(admin.ModelAdmin):
    list_display = ('equipment', 'checked_out_to', 'checked_out_at', 'returned_at')
    list_filter = ('returned_at',)
    raw_id_fields = ('equipment', 'checked_out_to', 'checked_out_by', 'returned_to')


@admin.register(EquipmentMeterEntry)
class EquipmentMeterEntryAdmin(admin.ModelAdmin):
    list_display = ('equipment', 'hours', 'recorded_at')
    raw_id_fields = ('equipment',)


@admin.register(CalibrationRecord)
class CalibrationRecordAdmin(admin.ModelAdmin):
    list_display = ('equipment', 'calibrated_at', 'calibrated_by', 'result', 'certificate_number')
    list_filter = ('result',)
    raw_id_fields = ('equipment',)
