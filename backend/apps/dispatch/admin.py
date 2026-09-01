from django.contrib import admin

from .models import Job, RouteStop, VehicleAssignment


class RouteStopInline(admin.TabularInline):
    model = RouteStop
    extra = 1
    ordering = ['sequence']


@admin.register(Job)
class JobAdmin(admin.ModelAdmin):
    list_display = ('title', 'vehicle', 'driver', 'status', 'priority', 'scheduled_start')
    list_filter = ('status', 'priority')
    search_fields = ('title', 'pickup_address', 'dropoff_address')
    inlines = [RouteStopInline]
    raw_id_fields = ('vehicle', 'driver')


@admin.register(VehicleAssignment)
class VehicleAssignmentAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'driver', 'job', 'is_active', 'assigned_at')
    list_filter = ('is_active',)
    raw_id_fields = ('vehicle', 'driver', 'job')
