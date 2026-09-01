from django.contrib import admin

from .models import FuelPurchase, IftaQuarter, Jurisdiction, TripLog


@admin.register(Jurisdiction)
class JurisdictionAdmin(admin.ModelAdmin):
    list_display = ('code', 'name', 'country', 'is_ifta', 'fuel_tax_rate')
    list_filter = ('is_ifta', 'country')
    search_fields = ('code', 'name')


@admin.register(TripLog)
class TripLogAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'jurisdiction', 'date', 'distance', 'distance_unit', 'source')
    list_filter = ('source', 'distance_unit', 'trip_type')
    raw_id_fields = ('vehicle', 'driver', 'jurisdiction')


@admin.register(FuelPurchase)
class FuelPurchaseAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'jurisdiction', 'date', 'gallons', 'total_cost', 'tax_paid', 'source')
    list_filter = ('source',)
    raw_id_fields = ('vehicle', 'jurisdiction', 'fuel_transaction')


@admin.register(IftaQuarter)
class IftaQuarterAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'year', 'quarter', 'status', 'total_miles', 'total_gallons', 'net_tax')
    list_filter = ('year', 'quarter', 'status')
    raw_id_fields = ('vehicle',)
