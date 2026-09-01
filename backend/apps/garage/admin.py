from django.contrib import admin

from .models import BayReservation, GarageBay


@admin.register(GarageBay)
class GarageBayAdmin(admin.ModelAdmin):
    list_display = ('name', 'bay_type', 'capacity', 'is_active')


@admin.register(BayReservation)
class BayReservationAdmin(admin.ModelAdmin):
    list_display = ('bay', 'vehicle', 'start_time', 'end_time', 'status')
    list_filter = ('status', 'bay')
    raw_id_fields = ('vehicle', 'work_order')
