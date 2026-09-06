"""
Fix users that were accidentally created in the **public** schema when
they should live inside a tenant's schema.

This typically happens when:
  * A tenant admin user is created via Django admin (/admin/) without
    a subdomain — the middleware falls back to the public schema.
  * A super-admin (public schema JWT) uses ``UserCreateView`` which has
    no explicit ``schema_context`` wrapper.

The command:
  1. Scans the public schema for non-superuser, non-staff users that
     don't belong there.
  2. For each, tries to find the correct tenant by matching the tenant's
     ``email`` field to the user email, or accepts an explicit
     ``--schema`` argument.
  3. Moves the user row into the target tenant schema and deletes the
     stray public-schema copy.

Usage (interactive scan)::

    python manage.py fix_user_schema

Usage (targeted)::

    python manage.py fix_user_schema \\
        --email info@sareicarrentals.com \\
        --schema sareicarrentals \\
        --password Samuel@2026

The ``--password`` flag is optional — if omitted, the user's existing
password hash is copied.  If the source user can't be found by email in
the target schema, a fresh user is created.
"""

from django.core.management.base import BaseCommand, CommandError
from django_tenants.utils import schema_context

from apps.tenants.models import Tenant
from apps.users.models import User


PUBLIC_SCHEMA = 'public'


class Command(BaseCommand):
    help = 'Move a user from the public schema to the correct tenant schema.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            help='Email of the user to move (required for targeted mode).',
        )
        parser.add_argument(
            '--schema',
            help='Target tenant schema_name (required for targeted mode).',
        )
        parser.add_argument(
            '--password',
            help='New password for the user (optional; preserves hash if omitted).',
        )
        parser.add_argument(
            '--list',
            action='store_true',
            help='List all non-superuser users found in the public schema.',
        )

    def handle(self, *args, **opts):
        if opts.get('list'):
            self._list_stray_users()
            return

        email = (opts.get('email') or '').lower().strip()
        schema = opts.get('schema')
        password = opts.get('password')

        if not email or not schema:
            raise CommandError(
                'Both --email and --schema are required (or use --list to scan).'
            )

        # Validate tenant
        try:
            tenant = Tenant.objects.get(schema_name=schema)
        except Tenant.DoesNotExist:
            raise CommandError(f'Tenant schema "{schema}" does not exist.')

        # Find user in public schema
        with schema_context(PUBLIC_SCHEMA):
            src_user = User.objects.filter(email__iexact=email).first()
            if not src_user:
                raise CommandError(
                    f'User "{email}" not found in the public schema.'
                )
            if src_user.is_superuser or src_user.is_staff:
                raise CommandError(
                    f'User "{email}" is a super-admin/staff in the public schema. '
                    'Moving super-admins is not allowed.'
                )

            # Snapshot all fields
            user_data = {
                'email': src_user.email,
                'first_name': src_user.first_name,
                'last_name': src_user.last_name,
                'role': src_user.role,
                'phone': src_user.phone,
                'avatar': src_user.avatar,
                'is_active': src_user.is_active,
                'is_staff': src_user.is_staff,
                'is_superuser': src_user.is_superuser,
                'password': src_user.password,  # hashed
                'date_joined': src_user.date_joined,
            }

        # Check if user already exists in the target schema
        with schema_context(schema):
            existing = User.objects.filter(email__iexact=email).first()

            if existing:
                # Update existing user in tenant schema
                if password:
                    existing.set_password(password)
                else:
                    existing.password = user_data['password']
                existing.first_name = user_data['first_name']
                existing.last_name = user_data['last_name']
                existing.role = user_data['role']
                existing.phone = user_data['phone']
                existing.is_active = user_data['is_active']
                existing.save(update_fields=[
                    'password', 'first_name', 'last_name', 'role', 'phone',
                    'is_active',
                ])
                self.stdout.write(self.style.SUCCESS(
                    f'Updated existing user "{email}" in schema "{schema}".'
                ))
            else:
                # Create fresh user in tenant schema
                new_user = User(
                    email=user_data['email'],
                    first_name=user_data['first_name'],
                    last_name=user_data['last_name'],
                    role=user_data['role'],
                    phone=user_data['phone'],
                    avatar=user_data['avatar'],
                    is_active=user_data['is_active'],
                    is_staff=user_data['is_staff'],
                    is_superuser=user_data['is_superuser'],
                    date_joined=user_data['date_joined'],
                )
                if password:
                    new_user.set_password(password)
                else:
                    new_user.password = user_data['password']
                new_user.save()
                self.stdout.write(self.style.SUCCESS(
                    f'Created user "{email}" in schema "{schema}".'
                ))

        # Delete stray user from public schema
        with schema_context(PUBLIC_SCHEMA):
            User.objects.filter(email__iexact=email).delete()
        self.stdout.write(self.style.SUCCESS(
            f'Deleted stray user "{email}" from the public schema.'
        ))

        self.stdout.write(self.style.WARNING(
            '\n  The user can now log in normally:\n'
            f'    Email:    {email}\n'
            f'    Schema:   {schema}\n'
            f'    Tenant:   {tenant.short_name}\n'
        ))

    def _list_stray_users(self):
        """List non-superuser, non-staff users in the public schema."""
        with schema_context(PUBLIC_SCHEMA):
            strays = User.objects.filter(
                is_superuser=False, is_staff=False
            ).order_by('-date_joined')

            if not strays.exists():
                self.stdout.write(self.style.SUCCESS(
                    'No stray users found in the public schema.'
                ))
                return

            self.stdout.write(self.style.WARNING(
                f'\n  Found {strays.count()} stray user(s) in the public schema:\n'
            ))
            for u in strays:
                # Try to match a tenant by email
                matched = Tenant.objects.filter(
                    email__iexact=u.email
                ).first()
                match_info = (
                    f'  → likely belongs to tenant: {matched.schema_name} '
                    f'({matched.short_name})'
                    if matched
                    else '  → no matching tenant found by email'
                )
                self.stdout.write(
                    f'    {u.email:40s}  role={u.role:10s}  '
                    f'joined={u.date_joined:%Y-%m-%d %H:%M}\n'
                    f'    {match_info}\n'
                )
            self.stdout.write(self.style.WARNING(
                '\n  Run: python manage.py fix_user_schema '
                '--email <email> --schema <schema_name>\n'
            ))
