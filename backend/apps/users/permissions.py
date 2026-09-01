from rest_framework import permissions


class IsAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.role == 'admin')


class IsManagerOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.role in ('admin', 'manager')
        )


class IsDriver(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.role == 'driver')


class IsMechanic(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.role == 'mechanic')


class ReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.method in permissions.SAFE_METHODS)
