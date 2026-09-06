from django.db import connection
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import authenticate as django_authenticate

from .models import User


def _resolve_schema_for_email(email):
    """Return the (schema_name, Tenant) that owns *email*, or (None, None).

    Searches every registered tenant schema first.  Only if no match is
    found in any tenant does it fall back to the public schema, where the
    global super-admin lives.  This prevents a stray tenant user created
    accidentally in the public schema from shadowing the real tenant user.
    """
    from apps.tenants.models import Tenant
    from django_tenants.utils import schema_context

    # 1 — tenant schemas (preferred)
    for tenant in Tenant.objects.all().iterator():
        with schema_context(tenant.schema_name):
            if User.objects.filter(email__iexact=email).exists():
                return tenant.schema_name, tenant

    # 2 — public schema (super-admin only)
    with schema_context('public'):
        pub_user = User.objects.filter(email__iexact=email).first()
        if pub_user:
            # Only allow public-schema login for actual super-admins/staff.
            # A regular tenant user sitting in public is a data error —
            # refuse it so the operator notices and runs fix_user_schema.
            if pub_user.is_superuser or pub_user.is_staff:
                return 'public', None

    return None, None


class TenantTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Adds ``tenant_schema`` and ``role`` claims to every issued JWT pair.

    Login uses only email + password. The serializer searches all schemas
    (public first, then every tenant) for the email, switches to the
    matching schema, and authenticates there.
    """

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['tenant_schema'] = connection.schema_name
        token['role'] = user.role
        token['full_name'] = user.full_name
        token['is_staff'] = user.is_staff
        token['is_superuser'] = user.is_superuser
        return token

    def validate(self, attrs):
        email = (attrs.get(self.username_field) or '').lower()
        password = attrs.get('password', '')

        schema, tenant = _resolve_schema_for_email(email)
        if schema is None:
            from rest_framework.exceptions import AuthenticationFailed
            raise AuthenticationFailed('No account found with that email.')

        # Switch to the resolved schema so authenticate() queries the right table
        if tenant:
            connection.set_tenant(tenant)
        else:
            connection.set_schema_to_public()

        # Use the parent validate which calls authenticate() + sets self.user
        data = super().validate(attrs)

        # Override the tenant_schema in the token claim with the resolved schema
        data['user'] = UserSerializer(self.user).data
        data['tenant_schema'] = schema
        data['tenant_name'] = tenant.short_name if tenant else None
        return data


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'role', 'phone', 'avatar', 'is_active', 'date_joined',
            'is_staff', 'is_superuser',
        ]
        read_only_fields = ['id', 'date_joined', 'full_name', 'is_staff', 'is_superuser', 'role', 'is_active']


class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'role', 'phone', 'password']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class RegisterSerializer(serializers.Serializer):
    """Tenant self-registration payload."""
    short_name = serializers.CharField(max_length=80)
    full_name = serializers.CharField(max_length=200)
    country = serializers.CharField(max_length=100)
    mobile_number = serializers.CharField(max_length=20)
    address = serializers.CharField(max_length=500)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)

    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, write_only=True)
