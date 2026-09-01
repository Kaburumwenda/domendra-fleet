"""
Role-Based Access Control (RBAC) models.

This module implements a flexible, per-tenant RBAC system that augments the
existing flat ``User.role`` field with granular permissions.

Design
------
* ``Permission`` — a single (module, action) capability, e.g.
  ``('vehicles', 'create')``. Permissions are seeded once per tenant from a
  static registry (``rbac.permissions_registry``) and exposed as read-only
  through the API.
* ``Role`` — a named collection of permissions, e.g. "Fleet Manager".
  Five system roles are seeded by default; admins can also create custom
  roles. ``is_system`` roles cannot be deleted (but their permissions can be
  edited). Roles belong to the current tenant (schema isolation).
* ``RolePermission`` — M2M through model linking a Role to its Permissions.
* ``RoleAssignment`` — links a User to a Role with timestamps and assigner
  tracking. This replaces the flat ``User.role`` CharField as the source of
  truth while keeping ``User.role`` as a denormalized "primary role" for
  fast JWT-claim lookups.

Backward compatibility
----------------------
The existing ``User.role`` field and the five ``User.Role`` choices are
preserved. ``User.role`` becomes a denormalized cache of the user's *primary*
role (first role assignment, or the one marked ``is_primary``). This means
existing JWT ``role`` claims and ``request.user.role`` checks continue to
work without any changes.
"""

from django.conf import settings
from django.db import models


class Permission(models.Model):
    """A single granular capability in the system.

    Each permission is identified by a unique ``module`` + ``action`` pair
    (e.g. ``('vehicles', 'delete')``). The ``module`` groups permissions by
    domain area so the UI can render a matrix grid.
    """

    class Action(models.TextChoices):
        VIEW = 'view', 'View'
        CREATE = 'create', 'Create'
        UPDATE = 'update', 'Edit'
        DELETE = 'delete', 'Delete'
        ASSIGN = 'assign', 'Assign'
        APPROVE = 'approve', 'Approve'
        EXPORT = 'export', 'Export'

    module = models.CharField(max_length=50, db_index=True)
    action = models.CharField(max_length=20, choices=Action.choices, db_index=True)
    label = models.CharField(max_length=120, blank=True)  # human-friendly, set during seed
    description = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ['module', 'action']
        unique_together = ['module', 'action']
        verbose_name = 'Permission'
        verbose_name_plural = 'Permissions'

    def __str__(self):
        return f'{self.module}.{self.action}'

    @property
    def code(self):
        """Stable string identifier used by permission checks: ``module:action``."""
        return f'{self.module}:{self.action}'


class Role(models.Model):
    """A named role scoped to the current tenant.

    System roles (``is_system=True``) are seeded once per tenant and cannot
    be deleted — but their permission set **can** be customised by an admin.
    Custom roles created by the tenant admin have ``is_system=False`` and
    can be fully managed (CRUD).
    """

    class RoleType(models.TextChoices):
        ADMIN = 'admin', 'Administrator'
        MANAGER = 'manager', 'Fleet Manager'
        MECHANIC = 'mechanic', 'Mechanic'
        DISPATCHER = 'dispatcher', 'Dispatcher'
        DRIVER = 'driver', 'Driver'
        CUSTOM = 'custom', 'Custom Role'

    name = models.CharField(max_length=80)
    key = models.CharField(max_length=50, unique=True, help_text='Unique identifier (e.g. "fleet_manager").')
    description = models.TextField(blank=True)
    color = models.CharField(max_length=20, default='primary', help_text='Vuetify color name or hex for UI chips/avatars.')
    icon = models.CharField(max_length=50, default='mdi-shield-account', help_text='MDI icon name for UI representation.')
    permissions = models.ManyToManyField(Permission, blank=True, related_name='roles')
    is_system = models.BooleanField(default=False, help_text='System roles are seeded and cannot be deleted.')
    is_default = models.BooleanField(default=False, help_text='Role assigned to new users by default.')
    user_count = models.PositiveIntegerField(default=0)  # denormalized count for fast listing
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['is_system', 'name']
        verbose_name = 'Role'
        verbose_name_plural = 'Roles'

    def __str__(self):
        return self.name


class RoleAssignment(models.Model):
    """Links a user to a role within the current tenant.

    A user may hold multiple roles; the one with ``is_primary=True`` is
    surfaced in ``User.role`` and the JWT ``role`` claim for fast lookups.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='role_assignments',
    )
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='assignments')
    is_primary = models.BooleanField(default=False)
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assignments_made',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['user', 'role']
        verbose_name = 'Role Assignment'
        verbose_name_plural = 'Role Assignments'

    def __str__(self):
        return f'{self.user_id} → {self.role.name}'

    def save(self, *args, **kwargs):
        """Ensure only one primary role per user; sync ``User.role`` on save."""
        super().save(*args, **kwargs)
        if self.is_primary:
            # Demote any other primary assignments for this user
            RoleAssignment.objects.filter(user=self.user, is_primary=True).exclude(pk=self.pk).update(is_primary=False)
            self._sync_user_role()

    def _sync_user_role(self):
        """Denormalize the primary role back to ``User.role`` for JWT / fast checks."""
        from apps.users.models import User

        role_map = {
            'admin': User.Role.ADMIN,
            'manager': User.Role.MANAGER,
            'mechanic': User.Role.MECHANIC,
            'dispatcher': User.Role.DISPATCHER,
            'driver': User.Role.DRIVER,
        }
        user = self.user
        if self.role.key in role_map:
            user.role = role_map[self.role.key]
            user.save(update_fields=['role'])
        # Custom roles don't map to the flat enum; the user's role field
        # stays as-is (or is set to the closest system equivalent by the
        # serializer when creating a custom-role assignment).
