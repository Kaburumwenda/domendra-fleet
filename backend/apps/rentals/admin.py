from django.contrib import admin

from .models import Customer, DigitalSignature, InspectionCheck, RentalAgreement, RentalCharge, VehicleCheck, VehicleDamage, VehiclePricing


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ('full_name', 'customer_type', 'phone', 'email', 'id_type', 'id_number', 'created_at')
    list_filter = ('customer_type', 'country')
    search_fields = ('full_name', 'phone', 'email', 'id_number', 'driving_license_no')


class RentalChargeInline(admin.TabularInline):
    model = RentalCharge
    extra = 0


class VehicleDamageInline(admin.TabularInline):
    model = VehicleDamage
    extra = 0


class DigitalSignatureInline(admin.TabularInline):
    model = DigitalSignature
    extra = 0
    readonly_fields = ('signed_at',)


class VehicleCheckInline(admin.TabularInline):
    model = VehicleCheck
    extra = 0
    readonly_fields = ('checked_at',)


class InspectionCheckInline(admin.TabularInline):
    model = InspectionCheck
    extra = 0
    readonly_fields = ('checked_at',)


@admin.register(RentalAgreement)
class RentalAgreementAdmin(admin.ModelAdmin):
    list_display = ('agreement_no', 'customer', 'vehicle', 'status', 'rate_period', 'start_datetime', 'end_datetime', 'total_amount')
    list_filter = ('status', 'rate_period')
    search_fields = ('agreement_no', 'customer__full_name', 'vehicle__license_plate')
    inlines = [RentalChargeInline, VehicleDamageInline, DigitalSignatureInline, VehicleCheckInline, InspectionCheckInline]
    readonly_fields = ('agreement_no', 'subtotal', 'discount_total', 'taxes', 'total_amount')


@admin.register(RentalCharge)
class RentalChargeAdmin(admin.ModelAdmin):
    list_display = ('agreement', 'charge_type', 'description', 'quantity', 'unit_amount', 'total_amount')
    list_filter = ('charge_type',)


@admin.register(VehicleDamage)
class VehicleDamageAdmin(admin.ModelAdmin):
    list_display = ('agreement', 'location', 'severity', 'repair_cost', 'recorded_at')
    list_filter = ('severity',)


@admin.register(DigitalSignature)
class DigitalSignatureAdmin(admin.ModelAdmin):
    list_display = ('agreement', 'party_type', 'signatory_name', 'signed_at')
    list_filter = ('party_type',)


@admin.register(VehicleCheck)
class VehicleCheckAdmin(admin.ModelAdmin):
    list_display = ('agreement', 'item_name', 'status', 'stage', 'checked_at')
    list_filter = ('status', 'stage')
    search_fields = ('item_key', 'item_name', 'notes')


@admin.register(InspectionCheck)
class InspectionCheckAdmin(admin.ModelAdmin):
    list_display = ('agreement', 'item_name', 'status', 'checked_at')
    list_filter = ('status',)
    search_fields = ('item_key', 'item_name', 'notes')


@admin.register(VehiclePricing)
class VehiclePricingAdmin(admin.ModelAdmin):
    list_display = ('name', 'apply_to', 'vehicle_group', 'daily_rate', 'weekly_rate', 'weekend_rate', 'monthly_rate', 'is_active', 'valid_from', 'valid_to')
    list_filter = ('apply_to', 'is_active', 'vehicle_group')
    search_fields = ('name', 'description', 'vehicles__display_name', 'vehicle_group__name')
    filter_horizontal = ('vehicles',)
    readonly_fields = ('created_at', 'updated_at')
    readonly_fields = ('created_at', 'updated_at')
