import logging
import time

from django.db import connection, transaction
from django.db.models import F
from django.utils import timezone as dj_timezone
from django_tenants.utils import schema_context

from .models import (
    APIUsageLog, ApiUsageSnapshot, EndpointUsageStat, TenantSubscription,
)

logger = logging.getLogger(__name__)

SKIP_PATHS = ('/api/auth/', '/api/schema/', '/api/docs/', '/api/redoc/')


class ApiUsageBillingMiddleware:
    """
    Counts every tenant API request:
      * Increments TenantSubscription.request_count in the public schema.
      * Creates an APIUsageLog row for full-event analytics.
      * Updates ApiUsageSnapshot & EndpointUsageStat daily roll-ups.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tenant = connection.tenant
        schema = getattr(tenant, 'schema_name', None) if tenant else None
        start = time.time()

        response = self.get_response(request)

        elapsed_ms = int((time.time() - start) * 1000)

        if (
            schema and schema != 'public'
            and request.path.startswith('/api/')
            and not request.path.startswith(SKIP_PATHS)
        ):
            try:
                self._record_usage(tenant, request, response, elapsed_ms)
            except Exception as exc:
                logger.warning('Billing usage update failed: %s', exc)

        return response

    # ── core recording ------------------------------------------------
    def _record_usage(self, tenant, request, response, elapsed_ms):
        status = getattr(response, 'status_code', 200) or 200
        now = dj_timezone.now()
        today = now.date()
        endpoint = request.path
        method = request.method or 'GET'

        with schema_context('public'):
            with transaction.atomic():
                # 1) Raw event log
                APIUsageLog.objects.create(
                    tenant=tenant, endpoint=endpoint, method=method,
                    status_code=status, response_time_ms=elapsed_ms,
                )

                # 2) Increment subscription counter atomically
                sub = TenantSubscription.objects.filter(tenant=tenant).first()
                if sub:
                    sub.request_count = F('request_count') + 1
                    sub.save(update_fields=['request_count'])

                # 3) Daily snapshot roll-up
                snap, _ = ApiUsageSnapshot.objects.get_or_create(
                    tenant=tenant, date=today,
                )
                snap.total_requests = F('total_requests') + 1
                if status >= 400:
                    snap.total_errors = F('total_errors') + 1
                snap.avg_response_ms = elapsed_ms
                snap.top_endpoint = endpoint
                snap.save(update_fields=[
                    'total_requests', 'total_errors',
                    'avg_response_ms', 'top_endpoint',
                ])

                # 4) Per-endpoint daily stat
                ep, _ = EndpointUsageStat.objects.get_or_create(
                    tenant=tenant, date=today,
                    endpoint=endpoint, method=method,
                )
                ep.count = F('count') + 1
                ep.save(update_fields=['count'])
