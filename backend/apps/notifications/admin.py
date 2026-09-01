from django.contrib import admin

from .models import Notification, NotificationPreference, NotificationTemplate


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'channel', 'event', 'is_active')
    list_filter = ('channel', 'is_active')
    search_fields = ('name', 'event')


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('event', 'channel', 'recipient_user', 'recipient_email', 'status', 'is_read', 'created_at')
    list_filter = ('channel', 'status', 'is_read')
    search_fields = ('event', 'subject', 'body')
    raw_id_fields = ('recipient_user',)


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'email_enabled', 'sms_enabled', 'in_app_enabled', 'push_enabled')
    raw_id_fields = ('user',)
