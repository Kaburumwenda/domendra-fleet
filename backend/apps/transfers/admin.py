from django.contrib import admin

from .models import Transfer, TransferStop, TransferDriverOffer


@admin.register(Transfer)
class TransferAdmin(admin.ModelAdmin):
    list_display = ('reference', 'passenger_name', 'pickup_name', 'dropoff_name', 'pickup_datetime', 'status', 'service_class', 'total_amount')
    list_filter = ('status', 'service_class', 'trip_type', 'payment_status')
    search_fields = ('reference', 'passenger_name', 'passenger_phone', 'pickup_name', 'dropoff_name')
    readonly_fields = ('reference', 'created_at', 'updated_at')
    date_hierarchy = 'pickup_datetime'


@admin.register(TransferStop)
class TransferStopAdmin(admin.ModelAdmin):
    list_display = ('transfer', 'sequence', 'place_name', 'address')
    list_filter = ('transfer',)
    search_fields = ('place_name', 'address')


@admin.register(TransferDriverOffer)
class TransferDriverOfferAdmin(admin.ModelAdmin):
    list_display = ('transfer', 'driver', 'quoted_amount', 'quoted_eta_min', 'status')
    list_filter = ('status',)
