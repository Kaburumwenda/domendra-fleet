from django.contrib import admin

from .models import Tenant, Domain


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ('short_name', 'schema_name', 'email', 'country', 'is_active', 'created_at')
    list_filter = ('is_active', 'country')
    search_fields = ('short_name', 'full_name', 'email', 'schema_name')


@admin.register(Domain)
class DomainAdmin(admin.ModelAdmin):
    list_display = ('domain', 'tenant', 'is_primary')
    search_fields = ('domain',)
