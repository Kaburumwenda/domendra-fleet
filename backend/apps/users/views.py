from django.db import connection
from django.utils.text import slugify
from django_tenants.utils import schema_context
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.billing.models import BillingPlan, TenantSubscription
from apps.tenants.models import Domain, Tenant

from .models import User
from .serializers import (
    RegisterSerializer,
    TenantTokenObtainPairSerializer,
    UserSerializer,
)


class LoginView(TokenObtainPairView):
    """Issues JWT pair with ``tenant_schema`` claim."""
    serializer_class = TenantTokenObtainPairSerializer


class RegisterView(APIView):
    """Creates a new tenant (schema + domain) and the first admin user."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        base = slugify(data['short_name'])[:50] or 'tenant'
        schema_name = base
        i = 2
        while Tenant.objects.filter(schema_name=schema_name).exists():
            schema_name = f'{base}{i}'
            i += 1

        tenant = Tenant.objects.create(
            schema_name=schema_name,
            short_name=data['short_name'],
            full_name=data['full_name'],
            email=data['email'],
            country=data['country'],
            mobile_number=data['mobile_number'],
            address=data['address'],
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
        )

        Domain.objects.create(
            domain=f'{schema_name}.localhost',
            tenant=tenant,
            is_primary=True,
        )

        with schema_context(tenant.schema_name):
            user = User.objects.create_user(
                email=data['email'],
                password=data['password'],
                first_name=data['first_name'],
                last_name=data['last_name'],
                role=User.Role.ADMIN,
            )

            free_plan = BillingPlan.objects.get_or_create(
                name='free',
                defaults={
                    'description': 'Free Tier',
                    'price': 0,
                    'included_requests': 10000,
                    'rate_per_1000_requests': 0.007,
                },
            )[0]
            connection.set_schema_to_public()
            TenantSubscription.objects.create(
                tenant=tenant,
                plan=free_plan,
                status='active',
            )
            connection.set_tenant(tenant)

            refresh = TenantTokenObtainPairSerializer.get_token(user)

        return Response(
            {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserSerializer(user).data,
                'tenant_schema': tenant.schema_name,
            },
            status=status.HTTP_201_CREATED,
        )


class CustomTokenRefreshView(TokenRefreshView):
    """Sets the tenant schema from the refresh-token claim before rotating."""

    def post(self, request, *args, **kwargs):
        raw = request.data.get('refresh')
        if raw:
            try:
                token = RefreshToken(raw)
                schema = token.get('tenant_schema')
                if schema:
                    connection.set_schema(schema)
            except Exception:
                pass
        return super().post(request, *args, **kwargs)


class LogoutView(APIView):
    """Blacklists the supplied refresh token."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh = RefreshToken(request.data.get('refresh'))
            refresh.blacklist()
            return Response(status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response(status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    """Current authenticated user profile."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class UserListView(APIView):
    """List all users in the current tenant (admin/manager only)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from apps.rbac.permissions import HasPermission
        checker = HasPermission('users:view')
        if not checker.has_permission(request, self) and not request.user.is_superuser:
            return Response({'detail': 'You do not have permission to view users.'}, status=status.HTTP_403_FORBIDDEN)

        users = User.objects.all().order_by('-date_joined')
        return Response(UserSerializer(users, many=True).data)


class UserCreateView(APIView):
    """Create a new user in the current tenant (admin only)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from apps.rbac.permissions import HasPermission
        checker = HasPermission('users:create')
        if not checker.has_permission(request, self) and not request.user.is_superuser:
            return Response({'detail': 'You do not have permission to create users.'}, status=status.HTTP_403_FORBIDDEN)

        # Guard: never create a tenant user in the public schema.
        if connection.schema_name == 'public':
            return Response(
                {'detail': 'Users cannot be created in the public schema. '
                 'Use the super-admin panel to manage tenant users.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        from .serializers import UserCreateSerializer
        serializer = UserCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


class UserDetailView(APIView):
    """Retrieve, update, or deactivate a user (admin only)."""
    permission_classes = [IsAuthenticated]

    def _get_object(self, pk):
        try:
            return User.objects.get(pk=pk)
        except User.DoesNotExist:
            return None

    def get(self, request, pk):
        from apps.rbac.permissions import HasPermission
        checker = HasPermission('users:view')
        if not checker.has_permission(request, self) and not request.user.is_superuser:
            return Response({'detail': 'You do not have permission to view users.'}, status=status.HTTP_403_FORBIDDEN)
        user = self._get_object(pk)
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(UserSerializer(user).data)

    def patch(self, request, pk):
        from apps.rbac.permissions import HasPermission
        checker = HasPermission('users:update')
        if not checker.has_permission(request, self) and not request.user.is_superuser:
            return Response({'detail': 'You do not have permission to edit users.'}, status=status.HTTP_403_FORBIDDEN)
        user = self._get_object(pk)
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = UserSerializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, pk):
        from apps.rbac.permissions import HasPermission
        checker = HasPermission('users:delete')
        if not checker.has_permission(request, self) and not request.user.is_superuser:
            return Response({'detail': 'You do not have permission to deactivate users.'}, status=status.HTTP_403_FORBIDDEN)
        user = self._get_object(pk)
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        if user.id == request.user.id:
            return Response({'detail': 'You cannot deactivate yourself.'}, status=status.HTTP_400_BAD_REQUEST)
        user.is_active = not user.is_active
        user.save(update_fields=['is_active'])
        return Response({'detail': f'User {"activated" if user.is_active else "deactivated"}.', 'is_active': user.is_active})


class UserPasswordResetView(APIView):
    """Admin-initiated password reset for a user (users:update required)."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from apps.rbac.permissions import HasPermission
        checker = HasPermission('users:update')
        if not checker.has_permission(request, self) and not request.user.is_superuser:
            return Response({'detail': 'You do not have permission to reset passwords.'}, status=status.HTTP_403_FORBIDDEN)
        user = User.objects.filter(pk=pk).first()
        if not user:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        new_password = request.data.get('password')
        if not new_password or len(new_password) < 8:
            return Response({'detail': 'Password must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)
        user.set_password(new_password)
        user.save(update_fields=['password'])
        return Response({'detail': 'Password updated successfully.'})
