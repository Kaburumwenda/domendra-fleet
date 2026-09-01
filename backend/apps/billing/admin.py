from django.contrib import admin

from .models import (
    APIUsageLog, ApiUsageSnapshot, BillingPlan,
    EndpointUsageStat, ExchangeRate, MonthlyBill, Payment, TenantSubscription,
)


@admin.register(BillingPlan)
class BillingPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'included_requests', 'rate_per_1000_requests', 'is_active')
    list_editable = ('is_active',)


@admin.register(TenantSubscription)
class TenantSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('tenant', 'plan', 'status', 'request_count', 'overage_cost',
                    'current_period_start', 'current_period_end')
    list_filter = ('status', 'plan')
    readonly_fields = ('request_count', 'overage_cost', 'created_at', 'updated_at')


@admin.register(APIUsageLog)
class APIUsageLogAdmin(admin.ModelAdmin):
    list_display = ('tenant', 'method', 'endpoint', 'status_code', 'response_time_ms', 'timestamp')
    list_filter = ('method', 'status_code')
    search_fields = ('endpoint',)
    date_hierarchy = 'timestamp'


@admin.register(ApiUsageSnapshot)
class ApiUsageSnapshotAdmin(admin.ModelAdmin):
    list_display = ('tenant', 'date', 'total_requests', 'total_errors',
                    'avg_response_ms', 'top_endpoint')
    list_filter = ('tenant',)
    date_hierarchy = 'date'


@admin.register(EndpointUsageStat)
class EndpointUsageStatAdmin(admin.ModelAdmin):
    list_display = ('tenant', 'date', 'endpoint', 'method', 'count')
    list_filter = ('method',)
    search_fields = ('endpoint',)
    date_hierarchy = 'date'


@admin.register(ExchangeRate)
class ExchangeRateAdmin(admin.ModelAdmin):
    list_display = ('currency', 'rate', 'updated_at')
    search_fields = ('currency',)
    ordering = ('currency',)


class PaymentInline(admin.TabularInline):
    model = Payment
    extra = 0
    readonly_fields = ('created_at',)


@admin.register(MonthlyBill)
class MonthlyBillAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'tenant', 'billing_month',
                   'total_requests', 'grand_total_usd',
                   'billing_currency', 'grand_total_local',
                   'status', 'due_date')
    list_filter = ('status', 'billing_currency', 'billing_month')
    search_fields = ('invoice_number', 'tenant__short_name')
    date_hierarchy = 'billing_month'
    readonly_fields = ('invoice_number', 'rate_per_1000_usd',
                       'usage_cost_usd', 'tax_amount_usd', 'grand_total_usd',
                       'exchange_rate', 'usage_cost', 'tax_amount_local',
                       'grand_total_local',
                       'plan_price', 'rate_per_1000', 'overage_cost',
                       'total_amount', 'tax_amount', 'grand_total',
                       'created_at', 'updated_at', 'paid_at')
    inlines = [PaymentInline]


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('bill', 'amount', 'method', 'reference', 'paid_by', 'created_at')
    list_filter = ('method',)
    search_fields = ('reference', 'bill__invoice_number')
