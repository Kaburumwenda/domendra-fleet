from django.contrib import admin

from .models import Permission, Role, RoleAssignment


@admin.register(Permission)
class PermissionAdmin(admin.ModelAdmin):
    list_display = ('module', 'action', 'label', 'description')
    list_filter = ('module', 'action')
    search_fields = ('module', 'label', 'description')
    ordering = ('module', 'action')


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ('name', 'key', 'color', 'is_system', 'is_default', 'user_count', 'created_at')
    list_filter = ('is_system', 'is_default')
    search_fields = ('name', 'key', 'description')
    filter_horizontal = ('permissions',)
    ordering = ('-is_system', 'name')


@admin.register(RoleAssignment)
class RoleAssignmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'role', 'is_primary', 'assigned_by', 'created_at')
    list_filter = ('is_primary', 'role')
    search_fields = ('user__email', 'user__first_name', 'user__last_name', 'role__name')
    ordering = ('-created_at',)
