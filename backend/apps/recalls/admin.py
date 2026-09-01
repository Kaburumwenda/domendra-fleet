from django.contrib import admin

from .models import Recall, RecallVehicle


@admin.register(Recall)
class RecallAdmin(admin.ModelAdmin):
    list_display = ('title', 'recall_type', 'oem', 'component', 'status', 'is_critical', 'issue_date')
    list_filter = ('recall_type', 'status', 'is_critical', 'oem')
    search_fields = ('title', 'nhtsa_campaign_number', 'manufacturer_campaign_number', 'component')


@admin.register(RecallVehicle)
class RecallVehicleAdmin(admin.ModelAdmin):
    list_display = ('recall', 'vehicle', 'status', 'scheduled_date', 'resolved_at')
    list_filter = ('status',)
    raw_id_fields = ('recall', 'vehicle', 'work_order')
