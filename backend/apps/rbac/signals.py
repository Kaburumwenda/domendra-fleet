"""
Signals for the RBAC app.

Keeps denormalized ``role.user_count`` accurate and invalidates the
permission cache for a user whenever their role assignments change.
"""

from django.db.models.signals import post_save, post_delete, m2m_changed
from django.dispatch import receiver

from .models import Role, RoleAssignment


def _invalidate_user(user):
    """Invalidate the cached permission set for ``user`` (no-op if unavailable)."""
    from .permissions import invalidate_user_permissions
    invalidate_user_permissions(user)


def _recalc_role_user_count(role):
    if role is None:
        return
    role.user_count = role.assignments.count()
    role.save(update_fields=['user_count'])


@receiver(post_save, sender=RoleAssignment)
def _on_assignment_saved(sender, instance, created, **kwargs):
    _recalc_role_user_count(instance.role)
    _invalidate_user(instance.user)


@receiver(post_delete, sender=RoleAssignment)
def _on_assignment_deleted(sender, instance, **kwargs):
    _recalc_role_user_count(instance.role)
    _invalidate_user(instance.user)


@receiver(m2m_changed, sender=Role.permissions.through)
def _on_role_permissions_changed(sender, instance, action, pk_set, **kwargs):
    # ``instance`` is the Role whose permission set changed.
    # Invalidate the cache for every user holding this role so the new
    # permission set is picked up on their next request.
    if action in ('post_add', 'post_remove', 'post_clear'):
        for assignment in instance.assignments.select_related('user').all():
            _invalidate_user(assignment.user)
