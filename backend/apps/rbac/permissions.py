"""
DRF permission classes for RBAC enforcement.

Usage in views::

    from apps.rbac.permissions import HasPermission

    # Option A — declarative on the view class:
    class VehicleViewSet(...):
        permission_classes = [IsAuthenticated]
        required_permission = 'vehicles:view'

    # Option B — factory form for action-specific checks:
    class VehicleViewSet(...):
        def get_permissions(self):
            if self.action == 'destroy':
                return [IsAuthenticated(), HasPermission('vehicles:delete')]
            return [IsAuthenticated()]

The ``HasPermission`` class works both ways:
  - ``HasPermission('vehicles:view')`` — constructor with code (used in
    ``get_permissions()`` return values or in ``permission_classes`` list as
    an instance).
  - ``HasPermission`` — bare class (DRF will instantiate with no args;
    the code is resolved from ``view.required_permission`` at runtime).

Admins (``user.role == 'admin'`` or ``is_superuser``) always pass.

Permission hierarchy
--------------------
Granting a higher-impact action implicitly grants lower-impact ones:
  - ``delete`` implies ``update``, ``create``, ``view``
  - ``update`` implies ``view``
  - ``create`` implies ``view``
  - ``approve`` implies ``view``
  - ``assign`` implies ``view``
  - ``export`` implies ``view``
This means a role with ``vehicles:delete`` is automatically considered to
have ``vehicles:view`` even if that permission was not explicitly granted.
"""

from django.core.cache import cache
from rest_framework import permissions


# ---------------------------------------------------------------------
# Permission hierarchy — higher-impact actions imply lower-impact ones.
# ---------------------------------------------------------------------
_IMPLIES = {
    'delete':   {'update', 'create', 'view'},
    'update':   {'view'},
    'create':   {'view'},
    'approve':  {'view'},
    'assign':  {'view'},
    'export':  {'view'},
}


def _expand_codes(codes):
    """Expand a set of ``module:action`` codes to include implied actions.

    For example ``{'vehicles:delete'}`` becomes ``{'vehicles:delete',
    'vehicles:update', 'vehicles:create', 'vehicles:view'}``.
    """
    expanded_result = set(codes)
    for code in codes:
        try:
            module, action = code.split(':', 1)
        except ValueError:
            continue
        for implied_action in _IMPLIES.get(action, ()):
            expanded_result.add(f'{module}:{implied_action}')
    return expanded_result


def _get_user_permissions(user):
    """Return the set of permission codes granted to ``user``.

    Results are cached on the request-scoped attribute cache (``_rbac_perm_cache``)
    so repeated ``has_permission`` checks within the same request only hit the
    DB once. A Django-cache backfill is used for anonymous/first-hit warm-up
    keyed by ``user.pk``.
    """
    # Per-request cache (avoids re-querying within a single request)
    if not hasattr(user, '_rbac_perm_cache'):
        if user.is_superuser or user.role == 'admin':
            cached = {'__admin__': True, 'codes': set()}
            setattr(user, '_rbac_perm_cache', cached)
            return cached

        cache_key = f'rbac:perms:{user.pk}'
        cached_codes = cache.get(cache_key)
        if cached_codes is None:
            perm_codes = set()
            for assignment in user.role_assignments.select_related('role').prefetch_related('role__permissions').all():
                for perm in assignment.role.permissions.all():
                    perm_codes.add(perm.code)
            # Fall back to the legacy flat role if no assignments exist (yet)
            if not perm_codes:
                perm_codes = _legacy_role_permissions(user.role)
            # Store the *expanded* set so hierarchy is precomputed
            cached_codes = _expand_codes(perm_codes)
            cache.set(cache_key, cached_codes, timeout=300)  # 5-minute TTL
        setattr(user, '_rbac_perm_cache', {'__admin__': False, 'codes': cached_codes})
    return user._rbac_perm_cache


def invalidate_user_permissions(user):
    """Clear the cached permission set for ``user``.

    Call this whenever a user's role assignments change (handled
    automatically via ``apps.rbac.signals``).
    """
    cache.delete(f'rbac:perms:{user.pk}')
    if hasattr(user, '_rbac_perm_cache'):
        try:
            delattr(user, '_rbac_perm_cache')
        except AttributeError:
            pass


def _legacy_role_permissions(role):
    """Fallback: derive permission codes from the flat ``User.role`` field."""
    from apps.rbac.permissions_registry import SYSTEM_ROLES
    for sys_role in SYSTEM_ROLES:
        if sys_role['key'] == role:
            return {f'{m}:{a}' for m, a in sys_role['permissions']}
    return set()


class HasPermission(permissions.BasePermission):
    """Check that the user has a specific RBAC permission.

    ``permission_code`` can be passed to the constructor
    (``HasPermission('vehicles:delete')``) or resolved from the view's
    ``required_permission`` attribute at runtime.
    """

    def __init__(self, permission_code=None):
        self.permission_code = permission_code
        super().__init__()

    def __call__(self, *args, **kwargs):
        """Make instances callable so DRF can reuse a pre-constructed instance."""
        if not args and not kwargs:
            return self
        if len(args) == 2:
            return self.has_permission(args[0], args[1])
        return self

    def has_permission(self, request, view):
        code = self.permission_code or getattr(view, 'required_permission', None)
        if not code:
            return True

        user = request.user
        if not user or not user.is_authenticated:
            return False

        if user.is_superuser or user.role == 'admin':
            return True

        perm_data = _get_user_permissions(user)
        if perm_data.get('__admin__'):
            return True
        return code in perm_data['codes']

    def has_object_permission(self, request, view, obj):
        # Object-level checks delegate to the same module:action logic.
        # Subclass or override in views for per-row ownership checks.
        return self.has_permission(request, view)
