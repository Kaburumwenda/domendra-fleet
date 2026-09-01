from django.db import connection
from django_tenants.utils import get_tenant_model

from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import TokenError, InvalidToken


class TenantResolutionMiddleware:
    """
    Resolves the tenant for every request and sets the PostgreSQL search_path
    to the tenant's schema.

    Resolution order:
      1. JWT ``tenant_schema`` claim (authenticated API calls)
      2. ``x-tenant-schema`` request header (login / register)
      3. Subdomain from Host header (hosted multi-tenant)
      4. Falls back to the public schema
    """

    PUBLIC_ENDPOINTS = frozenset({
        '/api/auth/register/',
        '/api/auth/login/',
        '/api/auth/refresh/',
    })

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tenant_schema = self._resolve_tenant_schema(request)

        if tenant_schema and tenant_schema != 'public':
            self._set_tenant(tenant_schema)
        else:
            connection.set_schema_to_public()

        try:
            response = self.get_response(request)
        finally:
            connection.set_schema_to_public()

        return response

    # ------------------------------------------------------------------
    def _resolve_tenant_schema(self, request):
        # 1 — JWT claim
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if auth_header.startswith('Bearer '):
            raw = auth_header.split(' ', 1)[1]
            try:
                token = AccessToken(raw)
                schema = token.get('tenant_schema')
                if schema:
                    return schema
            except (TokenError, InvalidToken, KeyError):
                pass

        # 2 — explicit header (for pre-auth requests like login)
        header_schema = request.META.get('HTTP_X_TENANT_SCHEMA')
        if header_schema:
            return header_schema

        # 3 — subdomain
        host = request.META.get('HTTP_HOST', '').split(':')[0]
        parts = host.split('.')
        if len(parts) > 2:
            sub = parts[0]
            if sub not in ('www', 'api', 'admin', 'app'):
                return sub

        return None

    def _set_tenant(self, schema_name):
        TenantModel = get_tenant_model()
        try:
            tenant = TenantModel.objects.get(schema_name=schema_name)
            connection.set_tenant(tenant)
        except TenantModel.DoesNotExist:
            connection.set_schema_to_public()
