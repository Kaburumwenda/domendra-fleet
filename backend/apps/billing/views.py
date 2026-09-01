from collections import defaultdict
import calendar
from datetime import datetime, date, time as dtime, timedelta
from decimal import Decimal

from django.db import connection
from django.db.models import Count, Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone as dj_timezone
from django_tenants.utils import schema_context
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    APIUsageLog, ApiUsageSnapshot, BillingPlan, EndpointUsageStat,
    ExchangeRate, MonthlyBill, Payment, TenantSubscription,
)
from .serializers import (
    APIUsageLogSerializer, ApiUsageSnapshotSerializer,
    BillingPlanSerializer, EndpointUsageStatSerializer,
    ExchangeRateSerializer, MonthlyBillSerializer, PaymentSerializer,
    TenantSubscriptionSerializer,
)


def _resolve_tenant(user):
    """Return the Tenant object for the authenticated request.

    django-tenants sets ``connection.tenant`` during request resolution; this
    is the authoritative source regardless of which schema billing lives in.
    """
    if not user or not user.is_authenticated:
        return None
    tenant = getattr(connection, 'tenant', None)
    if tenant and getattr(tenant, 'schema_name', None) and tenant.schema_name != 'public':
        return tenant
    # Fallback: users may carry a tenant FK on some installations
    return getattr(user, 'tenant', None)


class BillingPlanViewSet(viewsets.ReadOnlyModelViewSet):
    """Legacy endpoint — plans are no longer used for billing."""
    queryset = BillingPlan.objects.filter(is_active=True)
    serializer_class = BillingPlanSerializer
    permission_classes = [IsAuthenticated]


class ExchangeRateViewSet(viewsets.GenericViewSet):
    """Returns the tenant's billing currency and current USD→local rate."""

    permission_classes = [IsAuthenticated]
    serializer_class = ExchangeRateSerializer

    def list(self, request):
        tenant = _resolve_tenant(request.user)
        currency = 'USD'
        if tenant:
            currency = getattr(tenant, 'currency', 'USD') or 'USD'
        rate = ExchangeRate.get_rate(currency)
        return Response({
            'currency': currency,
            'rate': str(rate),
            'rate_per_1000_usd': str(Decimal('0.077')),
        })


class TenantSubscriptionViewSet(viewsets.GenericViewSet):
    """Read access for the current tenant's own subscription."""

    permission_classes = [IsAuthenticated]

    def list(self, request):
        tenant = _resolve_tenant(request.user)
        sub = TenantSubscription.objects.filter(tenant=tenant).first()
        if not sub:
            return Response(
                {'detail': 'No subscription found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        ser = TenantSubscriptionSerializer(sub)
        return Response(ser.data)

    def retrieve(self, request, pk=None):
        tenant = _resolve_tenant(request.user)
        sub = get_object_or_404(TenantSubscription, tenant=tenant, pk=pk)
        ser = TenantSubscriptionSerializer(sub)
        return Response(ser.data)


class APIUsageLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = APIUsageLogSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['method', 'status_code']
    search_fields = ['endpoint']
    ordering_fields = ['timestamp', 'response_time_ms']

    def get_queryset(self):
        tenant = _resolve_tenant(self.request.user)
        return (
            APIUsageLog.objects.filter(tenant=tenant)
            .select_related('tenant')
            .order_by('-timestamp')
        )


class MonthlyBillViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = MonthlyBillSerializer
    permission_classes = [IsAuthenticated]
    ordering_fields = ['billing_month', 'grand_total', 'status']

    def get_queryset(self):
        tenant = _resolve_tenant(self.request.user)
        qs = MonthlyBill.objects.filter(tenant=tenant).order_by('-billing_month')
        # Optional date filtering via billing_month
        start = self.request.query_params.get('start')
        end = self.request.query_params.get('end')
        preset = self.request.query_params.get('preset', '').strip().lower()
        if start:
            try:
                start_dt = datetime.strptime(start, '%Y-%m-%d').date()
                qs = qs.filter(billing_month__gte=start_dt)
            except ValueError:
                pass
        if end:
            try:
                end_dt = datetime.strptime(end, '%Y-%m-%d').date()
                qs = qs.filter(billing_month__lte=end_dt)
            except ValueError:
                pass
        if not start and not end and preset:
            # Use the same preset logic as analytics
            range_start, range_end, _ = _parse_date_range(self.request)
            # Only apply if it's not an all_time / empty range
            qs = qs.filter(billing_month__gte=range_start.date(), billing_month__lte=range_end.date())
        return qs

    @action(detail=True, methods=['post'])
    def pay(self, request, pk=None):
        bill = self.get_object()
        # Accept amount in USD (grand_total currency) or local currency.
        # The ``currency`` param indicates which currency the amount is in.
        currency = (request.data.get('currency') or 'USD').upper()
        amount_raw = Decimal(str(request.data.get('amount', 0) or 0))
        if currency != 'USD' and bill.exchange_rate and bill.exchange_rate != 0:
            amount = (amount_raw / Decimal(bill.exchange_rate)).quantize(Decimal('0.01'))
        else:
            amount = amount_raw
        if amount <= 0:
            return Response(
                {'detail': 'Invalid payment amount.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # Record payment in USD (base) and also the local equivalent
        local_amount = amount_raw if currency != 'USD' else (amount * Decimal(bill.exchange_rate or 1)).quantize(Decimal('0.01'))
        note_text = request.data.get('notes', '') or ''
        Payment.objects.create(
            bill=bill, amount=amount,
            method=request.data.get('method', 'card'),
            reference=request.data.get('reference', ''),
            paid_by=None,
            notes=f'{note_text} [{currency} {local_amount}]'.strip(),
        )
        # Update bill status if fully paid
        paid = bill.payments.aggregate(t=Sum('amount'))['t'] or Decimal('0')
        if paid >= bill.grand_total:
            bill.status = MonthlyBill.Status.PAID
            bill.paid_at = dj_timezone.now()
            bill.save(update_fields=['status', 'paid_at'])
            # Also settle subscription overage
            if bill.subscription:
                bill.subscription.overage_cost = Decimal('0')
                bill.subscription.save(update_fields=['overage_cost'])
        else:
            bill.save(update_fields=['updated_at'])
        ser = MonthlyBillSerializer(bill)
        return Response(ser.data)


class PaymentViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        tenant = _resolve_tenant(self.request.user)
        return Payment.objects.filter(bill__tenant=tenant).order_by('-created_at')


# ── Usage analytics endpoint ────────────────────────────────────────
def _parse_date_range(request):
    """Resolve start/end datetimes from query params or preset keyword."""
    now = dj_timezone.now()
    preset = request.query_params.get('preset', '').strip().lower()
    custom_start = request.query_params.get('start')
    custom_end = request.query_params.get('end')

    if custom_start and custom_end:
        start = datetime.strptime(custom_start, '%Y-%m-%d').date()
        end = datetime.strptime(custom_end, '%Y-%m-%d').date()
        start_dt = datetime.combine(start, dtime.min, tzinfo=dj_timezone.get_current_timezone())
        end_dt = datetime.combine(end, dtime.max, tzinfo=dj_timezone.get_current_timezone())
        return start_dt, end_dt, 'custom'

    today = now.date()

    # Calculate quarter boundaries
    q_month = ((today.month - 1) // 3) * 3 + 1  # 1, 4, 7, or 10
    q_start = today.replace(month=q_month, day=1)
    q_end_month = q_month + 2
    q_end_year = today.year
    if q_end_month > 12:
        q_end_month -= 12
        q_end_year += 1
    q_end_last = calendar.monthrange(q_end_year, q_end_month)[1]

    presets = {
        'today': (today, today),
        'this_week': (
            today - timedelta(days=today.weekday()), today,
        ),
        'last_week': (
            today - timedelta(days=today.weekday() + 7),
            today - timedelta(days=today.weekday() + 1),
        ),
        'this_month': (today.replace(day=1), today),
        'last_month': (
            (today.replace(day=1) - timedelta(days=1)).replace(day=1),
            today.replace(day=1) - timedelta(days=1),
        ),
        'this_quarter': (q_start, today),
        'this_year': (today.replace(month=1, day=1), today),
        'last_year': (
            today.replace(year=today.year - 1, month=1, day=1),
            today.replace(year=today.year - 1, month=12, day=31),
        ),
        'all_time': None,
    }

    if preset == 'all_time':
        # No date filtering — return very early date to encompass all data
        start_dt = datetime.combine(date(2020, 1, 1), dtime.min, tzinfo=dj_timezone.get_current_timezone())
        end_dt = now
        return start_dt, end_dt, 'all_time'

    start_d, end_d = presets.get(preset, (today.replace(day=1), today))
    start_dt = datetime.combine(start_d, dtime.min, tzinfo=dj_timezone.get_current_timezone())
    end_dt = datetime.combine(end_d, dtime.max, tzinfo=dj_timezone.get_current_timezone())
    return start_dt, end_dt, preset or 'this_month'


class UsageAnalyticsView(APIView):
    """Aggregate API-usage analytics for the current tenant."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        tenant = _resolve_tenant(request.user)
        start_dt, end_dt, preset = _parse_date_range(request)

        # Build the daily series from snapshots
        snapshots = ApiUsageSnapshot.objects.filter(
            tenant=tenant, date__gte=start_dt.date(), date__lte=end_dt.date(),
        ).order_by('date')

        daily_series = []
        for s in snapshots:
            daily_series.append({
                'date': s.date.isoformat(),
                'requests': s.total_requests,
                'errors': s.total_errors,
                'avg_response_ms': s.avg_response_ms,
            })

        # If no snapshots exist yet, fall back to raw logs
        if not daily_series:
            logs = APIUsageLog.objects.filter(
                tenant=tenant,
                timestamp__gte=start_dt, timestamp__lte=end_dt,
            )
            buckets = defaultdict(lambda: {'requests': 0, 'errors': 0, 'rt_sum': 0})
            for log in logs:
                day = log.timestamp.date().isoformat()
                buckets[day]['requests'] += 1
                if log.status_code and log.status_code >= 400:
                    buckets[day]['errors'] += 1
                buckets[day]['rt_sum'] += log.response_time_ms
            for day, v in sorted(buckets.items()):
                avg_rt = v['rt_sum'] / v['requests'] if v['requests'] else 0
                daily_series.append({
                    'date': day,
                    'requests': v['requests'],
                    'errors': v['errors'],
                    'avg_response_ms': int(avg_rt),
                })

        # Top endpoints
        top_endpoints = list(
            EndpointUsageStat.objects.filter(
                tenant=tenant, date__gte=start_dt.date(), date__lte=end_dt.date(),
            )
            .values('endpoint', 'method')
            .annotate(total=Count('id'), requests=Sum('count'))
            .order_by('-requests')[:15]
        )

        # Method distribution
        method_dist = list(
            APIUsageLog.objects.filter(
                tenant=tenant,
                timestamp__gte=start_dt, timestamp__lte=end_dt,
            )
            .values('method')
            .annotate(count=Count('id'))
            .order_by('-count')
        )

        # Status distribution
        status_dist = list(
            APIUsageLog.objects.filter(
                tenant=tenant,
                timestamp__gte=start_dt, timestamp__lte=end_dt,
            )
            .values('status_code')
            .annotate(count=Count('id'))
            .order_by('status_code')
        )

        total_requests = sum(d['requests'] for d in daily_series)
        total_errors = sum(d['errors'] for d in daily_series)
        avg_response = (
            sum(d['avg_response_ms'] for d in daily_series) / len(daily_series)
            if daily_series else 0
        )

        # Subscription summary with projections
        sub = TenantSubscription.objects.filter(tenant=tenant).first()
        sub_data = TenantSubscriptionSerializer(sub).data if sub else None

        # Previous period for trend comparison
        span = end_dt - start_dt
        prev_start = start_dt - span - timedelta(days=1)
        prev_end = start_dt - timedelta(seconds=1)
        prev_snapshots = ApiUsageSnapshot.objects.filter(
            tenant=tenant,
            date__gte=prev_start.date(), date__lte=prev_end.date(),
        )
        prev_requests = sum(s.total_requests for s in prev_snapshots)
        # Fallback to logs if no snapshots
        if prev_requests == 0:
            prev_requests = APIUsageLog.objects.filter(
                tenant=tenant,
                timestamp__gte=prev_start, timestamp__lte=prev_end,
            ).count()

        request_trend = (
            round(((total_requests - prev_requests) / prev_requests) * 100, 1)
            if prev_requests > 0 else 0
        )

        # Top usage hour distribution (0-23)
        hour_dist = [0] * 24
        for log in APIUsageLog.objects.filter(
            tenant=tenant,
            timestamp__gte=start_dt, timestamp__lte=end_dt,
            timestamp__isnull=False,
        ).values('timestamp'):
            hour = log['timestamp'].hour
            if 0 <= hour < 24:
                hour_dist[hour] += 1

        return Response({
            'preset': preset,
            'start': start_dt.date().isoformat(),
            'end': end_dt.date().isoformat(),
            'summary': {
                'total_requests': total_requests,
                'total_errors': total_errors,
                'error_rate': (
                    round((total_errors / total_requests) * 100, 2)
                    if total_requests > 0 else 0
                ),
                'avg_response_ms': int(avg_response),
                'request_trend': request_trend,
                'prev_requests': prev_requests,
                'unique_endpoints': len({e['endpoint'] for e in top_endpoints}),
            },
            'daily_series': daily_series,
            'top_endpoints': top_endpoints,
            'method_distribution': method_dist,
            'status_distribution': status_dist,
            'hour_distribution': hour_dist,
            'subscription': sub_data,
        })
