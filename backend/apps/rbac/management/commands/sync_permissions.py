"""
Management command to seed/sync RBAC permissions and system roles.

Usage::

    # Sync permissions and roles in the current tenant schema
    python manage.py sync_permissions

    # Sync across all tenant schemas
    python manage.py sync_permissions --all-tenants

This command is idempotent — it can be run safely at any time. New
permissions added to ``permissions_registry.py`` will be created; existing
ones are left untouched. Roles are created if missing; existing roles have
their permission sets reconciled with the registry.
"""

from django.core.management.base import BaseCommand
from django.db import connection

from apps.rbac.models import Permission, Role, RoleAssignment
from apps.rbac.permissions_registry import PERMISSIONS_REGISTRY, SYSTEM_ROLES
from apps.tenants.models import Tenant
from apps.users.models import User


class Command(BaseCommand):
    help = 'Seed or sync RBAC permissions and system roles for the current (or all) tenant schema(s).'

    def add_arguments(self, parser):
        parser.add_argument(
            '--all-tenants',
            action='store_true',
            help='Sync across all tenant schemas in addition to public.',
        )
        parser.add_argument(
            '--reset-roles',
            action='store_true',
            help='Reset system role permissions to match the registry exactly (overrides manual edits).',
        )

    def handle(self, *args, **options):
        if options['all_tenants']:
            # Sync public schema first (superadmin)
            connection.set_schema_to_public()
            self._sync_schema(reset=options['reset_roles'])

            # Sync all tenant schemas
            for tenant in Tenant.objects.all():
                connection.set_tenant(tenant)
                self._sync_schema(reset=options['reset_roles'])

            connection.set_schema_to_public()
            self.stdout.write(self.style.SUCCESS(
                f'RBAC sync complete across all {Tenant.objects.count() + 1} schemas.'
            ))
        else:
            self._sync_schema(reset=options['reset_roles'])
            self.stdout.write(self.style.SUCCESS(
                f'RBAC sync complete for schema: {connection.schema_name}'
            ))

    def _sync_schema(self, reset=False):
        schema = connection.schema_name
        self.stdout.write(f'  Syncing schema: {schema}')

        # 1. Sync permissions from registry
        perm_map = {}  # (module, action) -> Permission
        for module, label, icon, actions in PERMISSIONS_REGISTRY:
            for action, action_label, desc in actions:
                perm, created = Permission.objects.update_or_create(
                    module=module,
                    action=action,
                    defaults={'label': action_label, 'description': desc},
                )
                perm_map[(module, action)] = perm
                if created:
                    self.stdout.write(f'    + Permission: {perm.code}')

        self.stdout.write(f'    Permissions: {Permission.objects.count()} total')

        # 2. Sync system roles
        for role_data in SYSTEM_ROLES:
            role, created = Role.objects.get_or_create(
                key=role_data['key'],
                defaults={
                    'name': role_data['name'],
                    'description': role_data['description'],
                    'color': role_data['color'],
                    'icon': role_data['icon'],
                    'is_system': role_data['is_system'],
                    'is_default': role_data['is_default'],
                },
            )

            if not created:
                # Update metadata but keep permissions unless --reset
                role.name = role_data['name']
                role.description = role_data['description']
                role.color = role_data['color']
                role.icon = role_data['icon']
                role.is_system = role_data['is_system']
                role.is_default = role_data['is_default']
                role.save()

            if created or reset:
                # Set permissions for the role
                perm_objs = []
                for module, action in role_data['permissions']:
                    perm = perm_map.get((module, action))
                    if perm:
                        perm_objs.append(perm)
                role.permissions.set(perm_objs)
                self.stdout.write(
                    f'    {"+" if created else "↻"} Role: {role.name} ({len(perm_objs)} permissions)'
                )
            else:
                # Ensure any NEW permissions from the registry are added
                # (don't remove existing ones — admin may have customized)
                existing_perm_ids = set(role.permissions.values_list('id', flat=True))
                for module, action in role_data['permissions']:
                    perm = perm_map.get((module, action))
                    if perm and perm.id not in existing_perm_ids:
                        role.permissions.add(perm)
                self.stdout.write(
                    f'    = Role: {role.name} ({role.permissions.count()} permissions)'
                )

        # 3. Migrate existing users from flat role to RoleAssignment
        self._migrate_legacy_roles(perm_map)

    def _migrate_legacy_roles(self, perm_map):
        """Create RoleAssignment records for existing users based on User.role."""
        existing_users = User.objects.exclude(role_assignments__isnull=False).distinct()
        # Actually, we need users who don't have ANY role assignment yet
        migrated = 0
        for user in User.objects.all():
            if user.role_assignments.exists():
                continue
            # Find the system role matching the user's flat role
            try:
                role = Role.objects.get(key=user.role)
            except Role.DoesNotExist:
                continue
            RoleAssignment.objects.create(
                user=user,
                role=role,
                is_primary=True,
            )
            migrated += 1

        if migrated:
            self.stdout.write(f'    Migrated {migrated} users to role assignments')

        # Update user counts on all roles
        for role in Role.objects.all():
            role.user_count = role.assignments.count()
            role.save(update_fields=['user_count'])
