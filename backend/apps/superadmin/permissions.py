from rest_framework import permissions


class IsSuperAdmin(permissions.BasePermission):
    """Only allows Django superusers (is_staff + is_superuser)."""

    def has_permission(self, request, view):
        u = request.user
        return bool(
            u
            and u.is_authenticated
            and u.is_staff
            and u.is_superuser
        )
