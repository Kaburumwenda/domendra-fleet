"""
Create a super-admin user in the **public** schema.

The super-admin is NOT attached to any tenant — it lives in the global
``public`` schema so it can manage all tenants and the entire fleet
ecosystem.

Usage::

    python manage.py create_superadmin \\
        --email admin@domendrafleet.com \\
        --password SuperAdmin@12345

The user will have ``is_staff=True``, ``is_superuser=True``, ``role='admin'``
and can access the /superadmin control plane.
"""

from django.core.management.base import BaseCommand
from django_tenants.utils import schema_context

from apps.users.models import User


PUBLIC_SCHEMA = 'public'


class Command(BaseCommand):
    help = 'Create or promote a super-admin user in the public (global) schema.'

    def add_arguments(self, parser):
        parser.add_argument('--email', required=True, help='User email')
        parser.add_argument('--password', required=True, help='User password')
        parser.add_argument('--first-name', default='Super', help='First name')
        parser.add_argument('--last-name', default='Admin', help='Last name')

    def handle(self, *args, **opts):
        email = opts['email'].lower()
        password = opts['password']
        first_name = opts['first_name']
        last_name = opts['last_name']

        with schema_context(PUBLIC_SCHEMA):
            user = User.objects.filter(email=email).first()
            if user:
                user.is_staff = True
                user.is_superuser = True
                user.role = User.Role.ADMIN
                user.set_password(password)
                user.save(update_fields=[
                    'is_staff', 'is_superuser', 'role', 'password',
                ])
                self.stdout.write(self.style.SUCCESS(
                    f'Promoted existing user {email} to super-admin in the public schema.'
                ))
            else:
                user = User.objects.create_superuser(
                    email=email,
                    password=password,
                    first_name=first_name,
                    last_name=last_name,
                    role=User.Role.ADMIN,
                )
                self.stdout.write(self.style.SUCCESS(
                    f'Created super-admin {email} in the public schema.'
                ))

        self.stdout.write(self.style.WARNING(
            '\n  Login via:\n'
            f'    Email:    {email}\n'
            f'    Password: {password}\n'
            f'    URL:      http://localhost:3000/login\n'
            f'    (No Organization ID needed — use "Super Admin" login mode)\n'
        ))
