from django.contrib import admin

from .models import (
    Contact,
    DriverProfile,
    DriverViolation,
    DriverDrugTest,
    DriverTraining,
    DriverHoursOfService,
    DriverAssignment,
    DriverNote,
    VendorProfile,
)


@admin.register(Contact)
class ContactAdmin(admin.ModelAdmin):
    list_display = ('full_name', 'contact_type', 'email', 'phone', 'is_active')
    list_filter = ('contact_type', 'is_active')
    search_fields = ('first_name', 'last_name', 'email', 'company_name')


class DriverViolationInline(admin.TabularInline):
    model = DriverViolation
    extra = 0


class DriverDrugTestInline(admin.TabularInline):
    model = DriverDrugTest
    extra = 0


class DriverTrainingInline(admin.TabularInline):
    model = DriverTraining
    extra = 0


class DriverHoursOfServiceInline(admin.TabularInline):
    model = DriverHoursOfService
    extra = 0


class DriverAssignmentInline(admin.TabularInline):
    model = DriverAssignment
    extra = 0


class DriverNoteInline(admin.TabularInline):
    model = DriverNote
    extra = 0


@admin.register(DriverProfile)
class DriverProfileAdmin(admin.ModelAdmin):
    list_display = ('contact', 'license_number', 'license_class', 'license_expiry', 'mvr_status', 'employment_status')
    list_filter = ('license_class', 'mvr_status', 'employment_status')
    search_fields = ('license_number', 'contact__first_name', 'contact__last_name')
    inlines = [
        DriverViolationInline, DriverDrugTestInline, DriverTrainingInline,
        DriverHoursOfServiceInline, DriverAssignmentInline, DriverNoteInline,
    ]


admin.site.register(DriverViolation)
admin.site.register(DriverDrugTest)
admin.site.register(DriverTraining)
admin.site.register(DriverHoursOfService)
admin.site.register(DriverAssignment)
admin.site.register(DriverNote)


@admin.register(VendorProfile)
class VendorProfileAdmin(admin.ModelAdmin):
    list_display = ('contact', 'service_type', 'rating', 'payment_terms')
    search_fields = ('contact__company_name', 'service_type')
