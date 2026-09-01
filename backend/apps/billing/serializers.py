from decimal import Decimal

from django.db.models import Sum
from rest_framework import serializers

from .models import (
    APIUsageLog, ApiUsageSnapshot, BillingPlan, EndpointUsageStat,
    ExchangeRate, MonthlyBill, Payment, TenantSubscription,
)


class BillingPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = BillingPlan
        fields = '__all__'


class ExchangeRateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExchangeRate
        fields = ['currency', 'rate', 'updated_at']


class TenantSubscriptionSerializer(serializers.ModelSerializer):
    plan = BillingPlanSerializer(read_only=True)
    included_remaining = serializers.IntegerField(read_only=True, allow_null=True)
    is_over_limit = serializers.BooleanField(read_only=True)
    estimated_cost_usd = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    estimated_cost_local = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    monthly_average = serializers.IntegerField(read_only=True)
    end_of_month_projection = serializers.IntegerField(read_only=True)
    projected_cost_usd = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    projected_cost_local = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    local_rate = serializers.DecimalField(
        max_digits=12, decimal_places=4, read_only=True,
    )
    tenant_name = serializers.CharField(source='tenant.short_name', read_only=True)

    class Meta:
        model = TenantSubscription
        fields = [
            'id', 'tenant_name', 'plan', 'status', 'request_count',
            'overage_cost', 'rate_per_1000_requests', 'billing_currency',
            'local_rate',
            'included_remaining', 'is_over_limit',
            'estimated_cost_usd', 'estimated_cost_local',
            'monthly_average', 'end_of_month_projection',
            'projected_cost_usd', 'projected_cost_local',
            'current_period_start', 'current_period_end', 'cycle_day',
            'billing_email', 'auto_close',
        ]
        read_only_fields = fields


class APIUsageLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = APIUsageLog
        fields = '__all__'


class ApiUsageSnapshotSerializer(serializers.ModelSerializer):
    class Meta:
        model = ApiUsageSnapshot
        fields = '__all__'


class EndpointUsageStatSerializer(serializers.ModelSerializer):
    class Meta:
        model = EndpointUsageStat
        fields = '__all__'


class PaymentSerializer(serializers.ModelSerializer):
    paid_by_name = serializers.CharField(
        source='paid_by.get_full_name', read_only=True
    )

    class Meta:
        model = Payment
        fields = [
            'id', 'bill', 'amount', 'method', 'reference',
            'paid_by', 'paid_by_name', 'notes', 'created_at',
        ]
        read_only_fields = ['created_at']


class MonthlyBillSerializer(serializers.ModelSerializer):
    tenant_name = serializers.CharField(source='tenant.short_name', read_only=True)
    plan_name = serializers.CharField(source='plan.name', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payments = PaymentSerializer(many=True, read_only=True)
    paid_amount = serializers.SerializerMethodField()
    paid_amount_local = serializers.SerializerMethodField()
    balance_due = serializers.SerializerMethodField()
    balance_due_local = serializers.SerializerMethodField()

    class Meta:
        model = MonthlyBill
        fields = [
            'id', 'tenant', 'tenant_name', 'subscription', 'plan', 'plan_name',
            'billing_month', 'period_start', 'period_end',
            'included_requests', 'total_requests', 'overage_requests',
            'rate_per_1000_usd', 'usage_cost_usd', 'tax_amount_usd',
            'grand_total_usd',
            'billing_currency', 'exchange_rate',
            'usage_cost', 'tax_amount_local', 'grand_total_local',
            # legacy
            'plan_price', 'rate_per_1000', 'overage_cost',
            'total_amount', 'tax_amount', 'grand_total',
            'status', 'paid_at', 'due_date', 'is_overdue',
            'notes', 'invoice_number', 'created_by',
            'created_at', 'updated_at',
            'payments', 'paid_amount', 'paid_amount_local',
            'balance_due', 'balance_due_local',
        ]
        read_only_fields = [
            'tenant', 'subscription', 'billing_month', 'period_start',
            'period_end', 'included_requests', 'total_requests',
            'overage_requests', 'rate_per_1000_usd', 'usage_cost_usd',
            'tax_amount_usd', 'grand_total_usd',
            'billing_currency', 'exchange_rate',
            'usage_cost', 'tax_amount_local', 'grand_total_local',
            'plan_price', 'rate_per_1000', 'overage_cost',
            'total_amount', 'tax_amount', 'grand_total',
            'paid_at', 'is_overdue', 'invoice_number', 'created_by',
            'created_at', 'updated_at', 'paid_amount', 'paid_amount_local',
            'balance_due', 'balance_due_local',
        ]

    def get_paid_amount(self, obj):
        total = obj.payments.aggregate(t=Sum('amount'))['t']
        return total or Decimal('0')

    def get_paid_amount_local(self, obj):
        total = self.get_paid_amount(obj)
        if obj.billing_currency and obj.billing_currency != 'USD' and obj.exchange_rate:
            return (total * Decimal(obj.exchange_rate)).quantize(Decimal('0.01'))
        return total

    def get_balance_due(self, obj):
        paid = self.get_paid_amount(obj)
        return max(Decimal('0'), obj.grand_total - paid)

    def get_balance_due_local(self, obj):
        paid_local = self.get_paid_amount_local(obj)
        grand_local = obj.grand_total_local or obj.grand_total
        return max(Decimal('0'), grand_local - paid_local)
