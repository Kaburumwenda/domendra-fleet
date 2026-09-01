from django.contrib import admin

from .models import ChargeSchedule, ChargingSession, FuelCard, FuelFraudAlert, FuelTransaction, IdlingEvent


@admin.register(FuelCard)
class FuelCardAdmin(admin.ModelAdmin):
    list_display = ('card_number', 'provider', 'vehicle', 'driver', 'is_active')
    list_filter = ('provider', 'is_active')
    search_fields = ('card_number', 'card_holder_name')


@admin.register(FuelTransaction)
class FuelTransactionAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'date', 'fuel_type', 'quantity', 'total_cost', 'station_name')
    list_filter = ('fuel_type', 'date')
    search_fields = ('station_name', 'notes')
    raw_id_fields = ('vehicle', 'fuel_card')


@admin.register(ChargingSession)
class ChargingSessionAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'start_time', 'energy_kwh', 'cost', 'station_network')
    list_filter = ('station_network',)
    raw_id_fields = ('vehicle',)


@admin.register(FuelFraudAlert)
class FuelFraudAlertAdmin(admin.ModelAdmin):
    list_display = ('transaction', 'alert_type', 'severity', 'is_resolved', 'created_at')
    list_filter = ('alert_type', 'severity', 'is_resolved')
    readonly_fields = ('created_at',)


@admin.register(IdlingEvent)
class IdlingEventAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'start_time', 'duration_minutes', 'fuel_burned', 'cost')
    raw_id_fields = ('vehicle',)


@admin.register(ChargeSchedule)
class ChargeScheduleAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'start_time', 'end_time', 'target_soc', 'is_active')
    list_filter = ('is_active',)
    raw_id_fields = ('vehicle',)
