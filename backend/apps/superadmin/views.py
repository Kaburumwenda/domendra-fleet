from collections import defaultdict
from datetime import timedelta

from django.db import connection
from django.db.models import Sum, Count, Q, Avg
from django.shortcuts import get_object_or_404
from django.utils import timezone as dj_timezone
from django_tenants.utils import schema_context

from apps.users.models import User

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.billing.models import (
    BillingPlan,
    TenantSubscription,
    MonthlyBill,
    Payment,
    APIUsageLog,
    ApiUsageSnapshot,
    EndpointUsageStat,
    ExchangeRate,
)
from apps.tenants.models import Tenant, Domain

from .permissions import IsSuperAdmin
from .serializers import (
    SuperAdminTenantSerializer,
    SuperAdminSubscriptionSerializer,
    SuperAdminBillSerializer,
    SuperAdminPaymentSerializer,
    SuperAdminUsageSnapshotSerializer,
    SuperAdminBillingPlanSerializer,
    SuperAdminUserSerializer,
    SuperAdminExchangeRateSerializer,
    SuperAdminDomainSerializer,
)


# ── Helpers ────────────────────────────────────────────────

def _ensure_public():
    """Make sure all cross-tenant queries run on the public schema."""
    connection.set_schema_to_public()


def _user_count_for(schema_name):
    try:
        from apps.users.models import User
        with schema_context(schema_name):
            return User.objects.count()
    except Exception:
        return 0


# ── Tenant ViewSet ──────────────────────────────────────────

class TenantViewSet(viewsets.ModelViewSet):
    """Full CRUD for tenant organizations (super-admin only)."""
    queryset = Tenant.objects.all().order_by('-created_at')
    serializer_class = SuperAdminTenantSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    filterset_fields = ['is_active', 'country', 'currency']
    search_fields = ['schema_name', 'short_name', 'full_name', 'email']
    ordering_fields = ['created_at', 'short_name', 'updated_at']
    page_size = 20

    def get_queryset(self):
        _ensure_public()
        return Tenant.objects.all().order_by('-created_at')

    def perform_create(self, serializer):
        """Create a new tenant schema + domain from the payload."""
        import re
        from django.utils.text import slugify

        data = serializer.validated_data
        base = slugify(data.get('short_name') or 'tenant')[:50] or 'tenant'
        schema_name = base
        i = 2
        while Tenant.objects.filter(schema_name=schema_name).exists():
            schema_name = f'{base}{i}'
            i += 1

        tenant = Tenant.objects.create(
            schema_name=schema_name,
            short_name=data.get('short_name', ''),
            full_name=data.get('full_name', ''),
            email=data.get('email', ''),
            country=data.get('country', ''),
            mobile_number=data.get('mobile_number', ''),
            address=data.get('address', ''),
            currency=data.get('currency', 'USD'),
            is_active=data.get('is_active', True),
        )
        Domain.objects.create(
            domain=f'{schema_name}.localhost',
            tenant=tenant,
            is_primary=True,
        )

        # Create the tenant's first admin user (if credentials supplied)
        admin_email = data.get('admin_email', '').lower().strip()
        admin_password = data.get('admin_password', '')
        if admin_email and admin_password:
            with schema_context(schema_name):
                from apps.users.models import User
                User.objects.create_user(
                    email=admin_email,
                    password=admin_password,
                    first_name=data.get('admin_first_name', '') or 'Admin',
                    last_name=data.get('admin_last_name', '') or 'User',
                    role=User.Role.ADMIN,
                    phone=data.get('mobile_number', ''),
                )

        # Free subscription
        with schema_context('public'):
            free_plan = BillingPlan.objects.get_or_create(
                name='free',
                defaults={
                    'description': 'Free Tier',
                    'price': 0,
                    'included_requests': 10000,
                    'rate_per_1000_requests': 0.007,
                },
            )[0]
            TenantSubscription.objects.create(
                tenant=tenant,
                plan=free_plan,
                status='active',
            )

        # Re-serialize
        serializer.instance = tenant

    @action(detail=True, methods=['post'])
    def suspend(self, request, pk=None):
        tenant = self.get_object()
        tenant.is_active = False
        tenant.save(update_fields=['is_active'])
        sub = getattr(tenant, 'subscription', None)
        if sub:
            sub.status = 'past_due'
            sub.save(update_fields=['status'])
        return Response({'status': 'suspended'})

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        tenant = self.get_object()
        tenant.is_active = True
        tenant.save(update_fields=['is_active'])
        sub = getattr(tenant, 'subscription', None)
        if sub and sub.status == 'past_due':
            sub.status = 'active'
            sub.save(update_fields=['status'])
        return Response({'status': 'activated'})

    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        tenant = self.get_object()
        with schema_context(tenant.schema_name):
            from apps.users.models import User
            user_count = User.objects.count()
            vehicle_count = _model_count('vehicles', 'Vehicle')
            issue_count = _model_count('issues', 'Issue')
            equipment_count = _model_count('equipment', 'Equipment')
        return Response({
            'users': user_count,
            'vehicles': vehicle_count,
            'issues': issue_count,
            'equipment': equipment_count,
        })

    @action(detail=True, methods=['get', 'post'])
    def domains(self, request, pk=None):
        """List or add a custom domain for a tenant."""
        tenant = self.get_object()
        if request.method == 'GET':
            domains = Domain.objects.filter(tenant=tenant)
            return Response(SuperAdminDomainSerializer(domains, many=True).data)
        data = request.data
        domain = Domain.objects.create(
            domain=data.get('domain', '').strip(),
            tenant=tenant,
            is_primary=data.get('is_primary', False),
        )
        if domain.is_primary:
            Domain.objects.filter(tenant=tenant).exclude(pk=domain.pk).update(is_primary=False)
        return Response(SuperAdminDomainSerializer(domain).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='login-as')
    def login_as(self, request, pk=None):
        """Issue a JWT pair scoped to the first admin user of the tenant.

        Enables support impersonation.  Returns access/refresh tokens plus the
        resolved user object — the super-admin's front-end can then act as
        that tenant's admin.
        """
        tenant = self.get_object()
        with schema_context(tenant.schema_name):
            from apps.users.models import User
            admin = (
                User.objects.filter(is_superuser=True).first()
                or User.objects.filter(role=User.Role.ADMIN).first()
                or User.objects.first()
            )
            if not admin:
                return Response(
                    {'detail': 'No admin user exists in this tenant.'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            from rest_framework_simplejwt.tokens import RefreshToken
            token = RefreshToken.for_user(admin)
            token['tenant_schema'] = tenant.schema_name
            token['role'] = admin.role
            token['full_name'] = admin.full_name
            token['is_staff'] = admin.is_staff
            token['is_superuser'] = admin.is_superuser
            from apps.users.serializers import UserSerializer
            return Response({
                'access': str(token.access_token),
                'refresh': str(token),
                'user': UserSerializer(admin).data,
                'tenant_schema': tenant.schema_name,
                'tenant_name': tenant.short_name,
            })


def _model_exists(app_label, model_name):
    from django.apps import apps
    try:
        return apps.get_model(app_label, model_name) is not None
    except Exception:
        return False


def _model_count(app_label, model_name):
    """Count objects for ``model_name`` in the current schema (best-effort)."""
    from django.apps import apps
    try:
        Model = apps.get_model(app_label, model_name)
        return Model.objects.count()
    except Exception:
        return 0


# ── Subscription ViewSet ────────────────────────────────────

class SubscriptionViewSet(viewsets.mixins.ListModelMixin,
                          viewsets.mixins.RetrieveModelMixin,
                          viewsets.mixins.UpdateModelMixin,
                          viewsets.GenericViewSet):
    queryset = TenantSubscription.objects.all().order_by('-created_at')
    serializer_class = SuperAdminSubscriptionSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    filterset_fields = ['status', 'billing_currency']
    search_fields = ['tenant__short_name', 'tenant__schema_name']
    ordering_fields = ['created_at', 'request_count', 'status']

    def get_queryset(self):
        _ensure_public()
        return TenantSubscription.objects.select_related('tenant').order_by('-created_at')


# ── Bill ViewSet ─────────────────────────────────────────────

class BillViewSet(viewsets.mixins.ListModelMixin,
                  viewsets.mixins.RetrieveModelMixin,
                  viewsets.GenericViewSet):
    queryset = MonthlyBill.objects.all().order_by('-billing_month')
    serializer_class = SuperAdminBillSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    filterset_fields = ['status', 'tenant', 'billing_currency']
    search_fields = ['tenant__short_name', 'invoice_number']
    ordering_fields = ['billing_month', 'grand_total_usd', 'status']

    def get_queryset(self):
        _ensure_public()
        return MonthlyBill.objects.select_related('tenant').order_by('-billing_month')


# ── Payment ViewSet ─────────────────────────────────────────

class PaymentViewSet(viewsets.mixins.ListModelMixin,
                      viewsets.mixins.RetrieveModelMixin,
                      viewsets.GenericViewSet):
    queryset = Payment.objects.all().order_by('-created_at')
    serializer_class = SuperAdminPaymentSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    ordering_fields = ['created_at', 'amount']

    def get_queryset(self):
        _ensure_public()
        return Payment.objects.select_related('bill', 'bill.tenant').order_by('-created_at')


# ── Usage Snapshot ViewSet ─────────────────────────────────–

class UsageSnapshotViewSet(viewsets.mixins.ListModelMixin,
                            viewsets.GenericViewSet):
    queryset = ApiUsageSnapshot.objects.all().order_by('-date')
    serializer_class = SuperAdminUsageSnapshotSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    filterset_fields = ['tenant', 'date']
    ordering_fields = ['date', 'total_requests']

    def get_queryset(self):
        _ensure_public()
        return ApiUsageSnapshot.objects.select_related('tenant').order_by('-date')


# ── Billing Plan ViewSet ───────────────────────────────────–

class BillingPlanViewSet(viewsets.ModelViewSet):
    queryset = BillingPlan.objects.all().order_by('price')
    serializer_class = SuperAdminBillingPlanSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get_queryset(self):
        _ensure_public()
        return BillingPlan.objects.all().order_by('price')


# ── Dashboard Overview ───────────────────────────────────────

class DashboardOverviewView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        _ensure_public()
        now = dj_timezone.now()
        today = now.date()
        last_30 = today - timedelta(days=30)

        # Tenants
        total_tenants = Tenant.objects.count()
        active_tenants = Tenant.objects.filter(is_active=True).count()
        suspended = total_tenants - active_tenants

        # New tenants in last 30 days
        new_tenants_30d = Tenant.objects.filter(created_at__date__gte=last_30).count()

        # Subscriptions
        subs = TenantSubscription.objects.all()
        total_requests = sum(s.request_count for s in subs)
        total_revenue = sum(float(s.estimated_cost_usd) for s in subs)

        sub_by_status = defaultdict(int)
        for s in subs:
            sub_by_status[s.status] += 1

        # Bills
        bills = MonthlyBill.objects.all()
        unpaid_bills = bills.filter(status='unpaid').count()
        overdue_bills = bills.filter(status='overdue').count()
        paid_bills = bills.filter(status='paid').count()
        outstanding_usd = float(
            bills.filter(status__in=['unpaid', 'overdue']).aggregate(
                t=Sum('grand_total_usd')
            )['t'] or 0
        )

        # Usage last 30 days
        snaps = ApiUsageSnapshot.objects.filter(date__gte=last_30)
        requests_30d = sum(s.total_requests for s in snaps)
        errors_30d = sum(s.total_errors for s in snaps)
        avg_response = 0
        if snaps.exists():
            avg_response = int(sum(s.avg_response_ms for s in snaps) / snaps.count())

        # Daily series for chart
        daily_series = self._daily_series(last_30, today)

        # Top tenants by requests
        top_tenants = sorted(
            [{'name': s.tenant.short_name, 'schema': s.tenant.schema_name,
              'requests': s.request_count, 'cost': float(s.estimated_cost_usd)}
             for s in subs],
            key=lambda x: x['requests'], reverse=True
        )[:10]

        # Top endpoints
        top_endpoints = list(
            EndpointUsageStat.objects.filter(date__gte=last_30)
            .values('endpoint', 'method')
            .annotate(total=Sum('count'))
            .order_by('-total')[:10]
        )

        return Response({
            'tenants': {
                'total': total_tenants,
                'active': active_tenants,
                'suspended': suspended,
                'new_30d': new_tenants_30d,
            },
            'subscriptions': {
                'by_status': dict(sub_by_status),
            },
            'billing': {
                'total_requests': total_requests,
                'projected_revenue': total_revenue,
                'outstanding_usd': outstanding_usd,
                'unpaid_bills': unpaid_bills,
                'overdue_bills': overdue_bills,
                'paid_bills': paid_bills,
            },
            'usage_30d': {
                'total_requests': requests_30d,
                'total_errors': errors_30d,
                'avg_response_ms': avg_response,
                'error_rate': round(errors_30d / max(requests_30d, 1) * 100, 2),
            },
            'daily_series': daily_series,
            'top_tenants': top_tenants,
            'top_endpoints': top_endpoints,
        })

    def _daily_series(self, start, end):
        """Return daily total requests + errors across all tenants."""
        snaps = ApiUsageSnapshot.objects.filter(date__gte=start, date__lte=end)
        by_date = defaultdict(lambda: {'requests': 0, 'errors': 0})
        for s in snaps:
            by_date[s.date]['requests'] += s.total_requests
            by_date[s.date]['errors'] += s.total_errors

        series = []
        d = start
        while d <= end:
            entry = by_date.get(d, {'requests': 0, 'errors': 0})
            series.append({
                'date': d.isoformat(),
                'requests': entry['requests'],
                'errors': entry['errors'],
            })
            d += timedelta(days=1)
        return series


# ── Revenue Analytics ──────────────────────────────────────

class RevenueAnalyticsView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        _ensure_public()
        months = int(request.query_params.get('months', 6))
        now = dj_timezone.now()
        start = (now.replace(day=1) - timedelta(days=31 * (months - 1))).date()

        bills = MonthlyBill.objects.filter(
            billing_month__gte=start
        ).order_by('billing_month')

        # Group by month
        by_month = defaultdict(lambda: {
            'revenue': 0, 'requests': 0, 'bills': 0
        })
        for b in bills:
            key = b.billing_month.strftime('%Y-%m')
            by_month[key]['revenue'] += float(b.grand_total_usd)
            by_month[key]['requests'] += b.total_requests
            by_month[key]['bills'] += 1

        series = []
        for key in sorted(by_month.keys()):
            series.append({'month': key, **by_month[key]})

        # MRR = sum of projected costs across active subs
        mrr = sum(
            float(s.projected_cost_usd)
            for s in TenantSubscription.objects.filter(status='active')
        )
        arpu = mrr / max(TenantSubscription.objects.filter(status='active').count(), 1)

        return Response({
            'monthly_series': series,
            'mrr': round(mrr, 2),
            'arpu': round(arpu, 2),
        })


# ── Tenant Usage Detail ─────────────────────────────────────

class TenantUsageDetailView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request, schema_name):
        _ensure_public()
        try:
            tenant = Tenant.objects.get(schema_name=schema_name)
        except Tenant.DoesNotExist:
            return Response({'detail': 'Tenant not found'}, status=status.HTTP_404_NOT_FOUND)

        days = int(request.query_params.get('days', 30))
        today = dj_timezone.now().date()
        start = today - timedelta(days=days)

        snaps = ApiUsageSnapshot.objects.filter(
            tenant=tenant, date__gte=start, date__lte=today
        ).order_by('date')

        daily = [
            {
                'date': s.date.isoformat(),
                'requests': s.total_requests,
                'errors': s.total_errors,
                'avg_response_ms': s.avg_response_ms,
                'top_endpoint': s.top_endpoint,
            }
            for s in snaps
        ]

        # Top endpoints for tenant
        top_eps = list(
            EndpointUsageStat.objects.filter(
                tenant=tenant, date__gte=start
            ).values('endpoint', 'method').annotate(
                total=Sum('count')
            ).order_by('-total')[:15]
        )

        # Subscription summary
        sub = getattr(tenant, 'subscription', None)
        sub_data = None
        if sub:
            sub_data = {
                'status': sub.status,
                'request_count': sub.request_count,
                'estimated_cost_usd': float(sub.estimated_cost_usd),
                'projected_cost_usd': float(sub.projected_cost_usd),
                'monthly_average': sub.monthly_average,
                'billing_currency': sub.billing_currency,
                'current_period_start': sub.current_period_start.isoformat() if sub.current_period_start else None,
                'current_period_end': sub.current_period_end.isoformat() if sub.current_period_end else None,
            }

        return Response({
            'tenant': SuperAdminTenantSerializer(tenant).data,
            'subscription': sub_data,
            'daily': daily,
            'top_endpoints': top_eps,
            'user_count': _user_count_for(tenant.schema_name),
        })


# ── Cross-tenant Users (scoped to a tenant) ─────────────────

class TenantUserViewSet(viewsets.ViewSet):
    """List, retrieve, create, update and delete users *within* a tenant.

    The tenant is addressed by ``schema_name`` in the URL, e.g.::

        /api/superadmin/tenants/<schema>/users/

    All operations run inside ``schema_context(schema_name)``.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def _get_tenant(self, schema_name):
        _ensure_public()
        return get_object_or_404(Tenant, schema_name=schema_name)

    def _ctx(self, tenant):
        return {
            'tenant_schema': tenant.schema_name,
            'tenant_name': tenant.short_name,
        }

    def list(self, request, schema_name):
        tenant = self._get_tenant(schema_name)
        with schema_context(tenant.schema_name):
            qs = User.objects.all().order_by('-date_joined')
            search = request.query_params.get('search')
            if search:
                qs = qs.filter(
                    Q(email__icontains=search)
                    | Q(first_name__icontains=search)
                    | Q(last_name__icontains=search)
                )
            role = request.query_params.get('role')
            if role:
                qs = qs.filter(role=role)
            active = request.query_params.get('is_active')
            if active is not None:
                qs = qs.filter(is_active=active.lower() in ('true', '1', 'yes'))
            qs = self._paginate(qs, request)
            ser = SuperAdminUserSerializer(
                qs, many=True, context=self._ctx(tenant)
            )
            return self._paginated_response(ser.data, request)

    def retrieve(self, request, schema_name, pk=None):
        tenant = self._get_tenant(schema_name)
        with schema_context(tenant.schema_name):
            user = get_object_or_404(User, pk=pk)
            ser = SuperAdminUserSerializer(user, context=self._ctx(tenant))
            return Response(ser.data)

    def create(self, request, schema_name):
        tenant = self._get_tenant(schema_name)
        with schema_context(tenant.schema_name):
            data = request.data
            user = User.objects.create_user(
                email=data.get('email'),
                password=data.get('password', User.objects.make_random_password()),
                first_name=data.get('first_name', ''),
                last_name=data.get('last_name', ''),
                role=data.get('role', User.Role.DRIVER),
                phone=data.get('phone', ''),
                is_active=data.get('is_active', True),
                is_staff=data.get('is_staff', False),
            )
            ser = SuperAdminUserSerializer(user, context=self._ctx(tenant))
            return Response(ser.data, status=status.HTTP_201_CREATED)

    def partial_update(self, request, schema_name, pk=None):
        tenant = self._get_tenant(schema_name)
        with schema_context(tenant.schema_name):
            user = get_object_or_404(User, pk=pk)
            data = request.data
            for f in ('first_name', 'last_name', 'role', 'phone', 'is_active', 'is_staff'):
                if f in data:
                    setattr(user, f, data[f])
            if 'password' in data and data['password']:
                user.set_password(data['password'])
            user.save()
            ser = SuperAdminUserSerializer(user, context=self._ctx(tenant))
            return Response(ser.data)

    def destroy(self, request, schema_name, pk=None):
        tenant = self._get_tenant(schema_name)
        with schema_context(tenant.schema_name):
            user = get_object_or_404(User, pk=pk)
            user.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'], url_path='login-as')
    def login_as(self, request, schema_name, pk=None):
        """Issue a JWT pair scoped to a specific user within a tenant."""
        tenant = self._get_tenant(schema_name)
        with schema_context(tenant.schema_name):
            user = get_object_or_404(User, pk=pk)
            from rest_framework_simplejwt.tokens import RefreshToken
            from apps.users.serializers import UserSerializer
            token = RefreshToken.for_user(user)
            token['tenant_schema'] = tenant.schema_name
            token['role'] = user.role
            token['full_name'] = user.full_name
            token['is_staff'] = user.is_staff
            token['is_superuser'] = user.is_superuser
            return Response({
                'access': str(token.access_token),
                'refresh': str(token),
                'user': UserSerializer(user).data,
                'tenant_schema': tenant.schema_name,
                'tenant_name': tenant.short_name,
            })

    # ── pagination helpers ────────────────────────────────
    @staticmethod
    def _paginate(qs, request):
        try:
            page = int(request.query_params.get('page', 1))
            page_size = int(request.query_params.get('page_size', 25))
        except (TypeError, ValueError):
            page, page_size = 1, 25
        start = (page - 1) * page_size
        return qs[start:start + page_size]

    @staticmethod
    def _paginated_response(data, request):
        return Response({
            'results': data,
            'page': int(request.query_params.get('page', 1)),
            'page_size': int(request.query_params.get('page_size', 25)),
        })


# ── Exchange Rates ─────────────────────────────────────────

class ExchangeRateViewSet(viewsets.ModelViewSet):
    """CRUD for static USD→<currency> exchange rates used by billing."""
    queryset = ExchangeRate.objects.all().order_by('currency')
    serializer_class = SuperAdminExchangeRateSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    filterset_fields = ['currency']
    search_fields = ['currency']
    ordering_fields = ['currency', 'rate', 'updated_at']
    lookup_field = 'currency'

    def get_queryset(self):
        _ensure_public()
        return ExchangeRate.objects.all().order_by('currency')


# ── Cross-tenant Audit Log ─────────────────────────────────

class AuditLogView(APIView):
    """Aggregate recent audit-log entries across all tenant schemas.

    Optional filters: ``action`` (create/update/delete), ``schema``,
    ``search`` (matches user email or path), and ``limit`` (default 200).
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        _ensure_public()
        action = request.query_params.get('action')
        schema = request.query_params.get('schema')
        search = request.query_params.get('search', '').lower()
        try:
            limit = int(request.query_params.get('limit', 200))
        except (TypeError, ValueError):
            limit = 200
        limit = max(1, min(limit, 2000))

        entries = []
        for tenant in Tenant.objects.all().iterator():
            if schema and tenant.schema_name != schema:
                continue
            with schema_context(tenant.schema_name):
                from apps.audit.models import AuditLog
                qs = AuditLog.objects.select_related('user')
                if action:
                    qs = qs.filter(action=action)
                if search:
                    qs = qs.filter(
                        Q(user__email__icontains=search)
                        | Q(path__icontains=search)
                        | Q(resource_type__icontains=search)
                    )
                for log in qs.order_by('-timestamp')[:limit]:
                    entries.append({
                        'id': f'{tenant.schema_name}:{log.pk}',
                        'tenant_name': tenant.short_name,
                        'tenant_schema': tenant.schema_name,
                        'user': log.user_id,
                        'user_name': (
                            getattr(log.user, 'full_name', None)
                            or getattr(log.user, 'email', None)
                            or 'system'
                        ) if log.user else 'system',
                        'action': log.action,
                        'resource_type': log.resource_type,
                        'resource_id': log.resource_id,
                        'method': log.method,
                        'path': log.path,
                        'details': log.details,
                        'ip_address': log.ip_address,
                        'status_code': log.status_code,
                        'timestamp': log.timestamp.isoformat(),
                    })

        entries.sort(key=lambda x: x['timestamp'], reverse=True)
        entries = entries[:limit]

        # Counts by action
        by_action = defaultdict(int)
        for e in entries:
            by_action[e['action']] += 1

        return Response({
            'results': entries,
            'count': len(entries),
            'by_action': dict(by_action),
        })


# ── System Health ──────────────────────────────────────────

class SystemHealthView(APIView):
    """Reports DB, cache, broker and per-tenant health for the control plane."""
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        _ensure_public()
        from django.core.cache import cache
        from django.db import connection as db_conn
        import time

        health = {}
        # Database
        t0 = time.time()
        try:
            db_conn.ensure_connection()
            health['database'] = {'ok': True, 'latency_ms': round((time.time() - t0) * 1000, 2)}
        except Exception as exc:  # pragma: no cover
            health['database'] = {'ok': False, 'error': str(exc)}

        # Cache
        t0 = time.time()
        try:
            cache.set('sa_health_probe', '1', 5)
            ok = cache.get('sa_health_probe') == '1'
            health['cache'] = {'ok': ok, 'latency_ms': round((time.time() - t0) * 1000, 2)}
        except Exception as exc:  # pragma: no cover
            health['cache'] = {'ok': False, 'error': str(exc)}

        # Celery broker
        try:
            from config.celery import app as celery_app
            insp = celery_app.control.inspect(timeout=1)
            ping = insp.ping()
            health['celery'] = {'ok': bool(ping), 'workers': len(ping) if ping else 0}
        except Exception:
            health['celery'] = {'ok': False, 'workers': 0}

        # Per-tenant quick stats
        tenants = []
        for tenant in Tenant.objects.order_by('-created_at')[:50]:
            sub = getattr(tenant, 'subscription', None)
            tenants.append({
                'schema': tenant.schema_name,
                'name': tenant.short_name,
                'is_active': tenant.is_active,
                'subscription_status': sub.status if sub else 'none',
                'requests': sub.request_count if sub else 0,
            })

        # Quick counts
        total_tenants = Tenant.objects.count()
        total_schemas = total_tenants
        return Response({
            'services': health,
            'counts': {
                'tenants': total_tenants,
                'schemas': total_schemas,
                'active_tenants': Tenant.objects.filter(is_active=True).count(),
                'subscriptions': TenantSubscription.objects.count(),
                'plans': BillingPlan.objects.count(),
                'bills': MonthlyBill.objects.count(),
                'payments': Payment.objects.count(),
                'exchange_rates': ExchangeRate.objects.count(),
            },
            'recent_tenants': tenants,
        })


# ── Tenant Toggles ─────────────────────────────────────────

class TenantTogglesView(APIView):
    """Quick toggle of billing/subscription settings for a tenant.

    Supports flipping ``auto_close`` (auto-close overdue bills) and
    ``is_active`` on the underlying tenant.
    """
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request, schema_name):
        _ensure_public()
        try:
            tenant = Tenant.objects.get(schema_name=schema_name)
        except Tenant.DoesNotExist:
            return Response({'detail': 'Tenant not found'}, status=status.HTTP_404_NOT_FOUND)
        sub = getattr(tenant, 'subscription', None)
        return Response({
            'schema': tenant.schema_name,
            'name': tenant.short_name,
            'is_active': tenant.is_active,
            'auto_close': sub.auto_close if sub else False,
            'billing_email': sub.billing_email if sub else '',
            'billing_currency': sub.billing_currency if sub else 'USD',
            'cycle_day': sub.cycle_day if sub else 1,
        })

    def patch(self, request, schema_name):
        _ensure_public()
        try:
            tenant = Tenant.objects.get(schema_name=schema_name)
        except Tenant.DoesNotExist:
            return Response({'detail': 'Tenant not found'}, status=status.HTTP_404_NOT_FOUND)
        data = request.data
        if 'is_active' in data:
            tenant.is_active = bool(data['is_active'])
            tenant.save(update_fields=['is_active'])
        sub = getattr(tenant, 'subscription', None)
        if sub:
            if 'auto_close' in data:
                sub.auto_close = bool(data['auto_close'])
            if 'billing_email' in data:
                sub.billing_email = data['billing_email']
            if 'billing_currency' in data:
                sub.billing_currency = data['billing_currency']
            if 'cycle_day' in data:
                sub.cycle_day = int(data['cycle_day'])
            sub.save()
        return Response({
            'schema': tenant.schema_name,
            'name': tenant.short_name,
            'is_active': tenant.is_active,
            'auto_close': sub.auto_close if sub else False,
            'billing_email': sub.billing_email if sub else '',
            'billing_currency': sub.billing_currency if sub else 'USD',
            'cycle_day': sub.cycle_day if sub else 1,
        })
