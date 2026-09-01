from django.contrib import admin

from .models import Service, VendorRating


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'service_type', 'performed_at', 'cost', 'vendor')
    list_filter = ('service_type',)
    search_fields = ('description',)
    raw_id_fields = ('vehicle', 'vendor', 'technician', 'work_order')


@admin.register(VendorRating)
class VendorRatingAdmin(admin.ModelAdmin):
    list_display = ('service', 'cost_rating', 'quality_rating', 'turnaround_rating', 'overall_rating')
