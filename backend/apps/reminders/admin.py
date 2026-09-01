from django.contrib import admin

from .models import Reminder


@admin.register(Reminder)
class ReminderAdmin(admin.ModelAdmin):
    list_display = ('title', 'vehicle', 'trigger_type', 'trigger_interval', 'next_due_date', 'is_active')
    list_filter = ('trigger_type', 'is_active')
    search_fields = ('title',)
    raw_id_fields = ('vehicle',)
