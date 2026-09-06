from django.contrib import admin, messages
from django.db import connection
from django.shortcuts import redirect

from .models import User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('email', 'first_name', 'last_name', 'role', 'is_active', 'date_joined')
    list_filter = ('role', 'is_active')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('-date_joined',)

    def has_add_permission(self, request):
        """
        Prevent adding users via Django admin when the connection is on the
        public schema (the default for /admin/ without a subdomain).

        Tenant users must be created through the super-admin API or the
        Django admin accessed via a tenant subdomain (e.g.
        ``acme.localhost/admin/``).  Only super-admin users are allowed to
        be added in the public schema, and only by a superuser.
        """
        if connection.schema_name == 'public':
            return request.user.is_superuser is True
        return True

    def save_model(self, request, obj, form, change):
        """
        Guard against accidentally saving a tenant user into the public schema.
        The public schema should only contain super-admins (is_staff/is_superuser).
        """
        if (
            connection.schema_name == 'public'
            and not obj.is_superuser
            and not obj.is_staff
        ):
            messages.error(
                request,
                'Tenant users cannot be created in the public schema. '
                'Access the admin via a tenant subdomain (e.g. '
                'acme.localhost:8000/admin/) or use the super-admin panel.',
            )
            return redirect('admin:users_user_changelist')
        super().save_model(request, obj, form, change)
