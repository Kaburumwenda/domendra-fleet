from django.db import connection
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Tenant
from .serializers import TenantSettingsSerializer
from .utils import country_to_currency


class TenantSettingsView(APIView):
    """Current tenant company profile and currency settings."""

    permission_classes = [IsAuthenticated]

    def get_object(self):
        try:
            return Tenant.objects.get(schema_name=connection.schema_name)
        except Tenant.DoesNotExist:
            raise NotFound('No tenant for the current schema.')

    def get(self, request):
        tenant = self.get_object()
        return Response(TenantSettingsSerializer(tenant).data)

    def patch(self, request):
        tenant = self.get_object()
        serializer = TenantSettingsSerializer(tenant, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class SuggestedCurrencyView(APIView):
    """Returns the default currency for the tenant's current country."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            tenant = Tenant.objects.get(schema_name=connection.schema_name)
        except Tenant.DoesNotExist:
            raise NotFound('No tenant for the current schema.')
        return Response({
            'suggested': country_to_currency(tenant.country),
            'current': tenant.currency,
        })
