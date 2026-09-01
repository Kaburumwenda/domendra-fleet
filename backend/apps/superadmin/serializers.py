from rest_framework import serializers

from apps.tenants.models import Tenant, Domain
from apps.users.models import User
from apps.billing.models import (
    TenantSubscription,
    MonthlyBill,
    Payment,
    APIUsageLog,
    ApiUsageSnapshot,
    BillingPlan,
    ExchangeRate,
)


# ── Tenant ──────────────────────────────────────────────────

class SuperAdminTenantSerializer(serializers.ModelSerializer):
    subscription_status = serializers.SerializerMethodField()
    request_count = serializers.SerializerMethodField()
    current_cost_usd = serializers.SerializerMethodField()
    user_count = serializers.SerializerMethodField()
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)

    # Extra write-only fields for creating the tenant's first admin user
    admin_first_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    admin_last_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    admin_email = serializers.EmailField(write_only=True, required=False)
    admin_password = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = Tenant
        fields = [
            'id', 'schema_name', 'short_name', 'full_name', 'email',
            'country', 'mobile_number', 'address', 'logo',
            'currency', 'is_active', 'created_at', 'updated_at',
            'subscription_status', 'request_count', 'current_cost_usd',
            'user_count',
            'admin_first_name', 'admin_last_name', 'admin_email', 'admin_password',
        ]
        read_only_fields = ['id', 'schema_name', 'created_at', 'updated_at']

    def get_subscription_status(self, obj):
        sub = getattr(obj, 'subscription', None)
        return sub.status if sub else 'none'

    def get_request_count(self, obj):
        sub = getattr(obj, 'subscription', None)
        return sub.request_count if sub else 0

    def get_current_cost_usd(self, obj):
        sub = getattr(obj, 'subscription', None)
        if sub:
            return float(sub.estimated_cost_usd)
        return '0.00'

    def get_user_count(self, obj):
        """Count users in this tenant's schema (best-effort)."""
        try:
            from django.db import connection
            from django_tenants.utils import schema_context
            from apps.users.models import User
            with schema_context(obj.schema_name):
                return User.objects.count()
        except Exception:
            return 0


# ── Billing ─────────────────────────────────────────────────

class SuperAdminSubscriptionSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='tenant.short_name', read_only=True)
    tenant_schema = serializers.CharField(source='tenant.schema_name', read_only=True)
    estimated_cost_usd = serializers.SerializerMethodField()
    projected_cost_usd = serializers.SerializerMethodField()
    monthly_average = serializers.SerializerMethodField()

    class Meta:
        model = TenantSubscription
        fields = [
            'id', 'tenant', 'tenant_name', 'tenant_schema', 'status',
            'request_count', 'rate_per_1000_requests', 'billing_currency',
            'current_period_start', 'current_period_end', 'cycle_day',
            'billing_email', 'auto_close',
            'estimated_cost_usd', 'projected_cost_usd', 'monthly_average',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['tenant', 'created_at', 'updated_at']

    def get_estimated_cost_usd(self, obj):
        return float(obj.estimated_cost_usd)

    def get_projected_cost_usd(self, obj):
        return float(obj.projected_cost_usd)

    def get_monthly_average(self, obj):
        return obj.monthly_average


class SuperAdminBillSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='tenant.short_name', read_only=True)
    tenant_schema = serializers.CharField(source='tenant.schema_name', read_only=True)

    class Meta:
        model = MonthlyBill
        fields = [
            'id', 'tenant', 'tenant_name', 'tenant_schema',
            'billing_month', 'period_start', 'period_end',
            'total_requests', 'usage_cost_usd', 'tax_amount_usd',
            'grand_total_usd', 'billing_currency',
            'usage_cost', 'grand_total_local',
            'status', 'paid_at', 'due_date',
            'invoice_number', 'created_at',
        ]
        read_only_fields = fields


class SuperAdminPaymentSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='bill.tenant.short_name', read_only=True)
    tenant_schema = serializers.CharField(source='bill.tenant.schema_name', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'bill', 'tenant_name', 'tenant_schema',
            'amount', 'method', 'reference',
            'notes', 'created_at',
        ]
        read_only_fields = fields


# ── Usage / Analytics ──────────────────────────────────────

class SuperAdminUsageSnapshotSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='tenant.short_name', read_only=True)
    tenant_schema = serializers.CharField(source='tenant.schema_name', read_only=True)

    class Meta:
        model = ApiUsageSnapshot
        fields = [
            'id', 'tenant', 'tenant_name', 'tenant_schema',
            'date', 'total_requests', 'total_errors',
            'avg_response_ms', 'top_endpoint',
        ]
        read_only_fields = fields


class SuperAdminBillingPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = BillingPlan
        fields = [
            'id', 'name', 'description', 'price',
            'included_requests', 'rate_per_1000_requests',
            'is_active', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']


# ── Cross-tenant User (scoped to a tenant schema) ────────────

class SuperAdminUserSerializer(serializers.ModelSerializer):
    """Serializer for users *within* a particular tenant schema.

    Returned together with the ``tenant_schema`` / ``tenant_name`` context
    set by the view.
    """
    tenant_schema = serializers.SerializerMethodField()
    tenant_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'role', 'phone', 'avatar', 'is_active', 'is_staff',
            'is_superuser', 'date_joined', 'updated_at',
            'tenant_schema', 'tenant_name',
        ]
        read_only_fields = ['id', 'date_joined', 'full_name', 'avatar', 'is_superuser']

    def get_tenant_schema(self, obj):
        return self.context.get('tenant_schema', '')

    def get_tenant_name(self, obj):
        return self.context.get('tenant_name', '')


# ── Exchange Rates ──────────────────────────────────────────

class SuperAdminExchangeRateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExchangeRate
        fields = ['currency', 'rate', 'updated_at']
        read_only_fields = ['updated_at']


# ── Domain ──────────────────────────────────────────────────

class SuperAdminDomainSerializer(serializers.ModelSerializer):
    class Meta:
        model = Domain
        fields = ['id', 'domain', 'is_primary', 'tenant']
        read_only_fields = ['id', 'tenant']
