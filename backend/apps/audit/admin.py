from django.contrib import admin

from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('user', 'action', 'priority', 'resource_type', 'method', 'status_code', 'timestamp')
    list_filter = ('action', 'priority', 'method', 'status_code')
    search_fields = ('path', 'resource_type', 'user__email')
    readonly_fields = [f.name for f in AuditLog._meta.get_fields() if f.name != 'id']
