from django.urls import path

from .views import (
    AuditLogView,
    BillViewSet,
    BillingPlanViewSet,
    DashboardOverviewView,
    ExchangeRateViewSet,
    PaymentViewSet,
    RevenueAnalyticsView,
    StrayUserView,
    SubscriptionViewSet,
    SystemHealthView,
    TenantTogglesView,
    TenantUsageDetailView,
    TenantUserViewSet,
    TenantViewSet,
    UsageSnapshotViewSet,
)

app_name = 'superadmin'

urlpatterns = [
    # Dashboard / analytics
    path('dashboard/', DashboardOverviewView.as_view(), name='dashboard'),
    path('revenue/', RevenueAnalyticsView.as_view(), name='revenue'),
    path('audit/', AuditLogView.as_view(), name='audit'),
    path('system-health/', SystemHealthView.as_view(), name='system-health'),

    # Tenants
    path('tenants/', TenantViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='tenants'),
    path('tenants/<int:pk>/', TenantViewSet.as_view({
        'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='tenant-detail'),
    path('tenants/<int:pk>/suspend/', TenantViewSet.as_view({
        'post': 'suspend',
    }), name='tenant-suspend'),
    path('tenants/<int:pk>/activate/', TenantViewSet.as_view({
        'post': 'activate',
    }), name='tenant-activate'),
    path('tenants/<int:pk>/stats/', TenantViewSet.as_view({
        'get': 'stats',
    }), name='tenant-stats'),
    path('tenants/<int:pk>/domains/', TenantViewSet.as_view({
        'get': 'domains', 'post': 'domains'}), name='tenant-domains'),
    path('tenants/<int:pk>/login-as/', TenantViewSet.as_view({
        'post': 'login_as'}), name='tenant-login-as'),
    path('tenants/<int:pk>/reset/', TenantViewSet.as_view({
        'post': 'reset'}), name='tenant-reset'),
    path('tenants/<str:schema_name>/toggles/', TenantTogglesView.as_view(), name='tenant-toggles'),
    path('tenants/<str:schema_name>/users/', TenantUserViewSet.as_view({
        'get': 'list', 'post': 'create'}), name='tenant-users'),
    path('tenants/<str:schema_name>/users/<int:pk>/login-as/', TenantUserViewSet.as_view({
        'post': 'login_as'}), name='tenant-user-login-as'),
    path('tenants/<str:schema_name>/users/<int:pk>/', TenantUserViewSet.as_view({
        'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy'}), name='tenant-user-detail'),
    path('tenants/<str:schema_name>/usage/', TenantUsageDetailView.as_view(), name='tenant-usage'),

    # Billing
    path('subscriptions/', SubscriptionViewSet.as_view({
        'get': 'list',
    }), name='subscriptions'),
    path('subscriptions/<int:pk>/', SubscriptionViewSet.as_view({
        'get': 'retrieve', 'patch': 'partial_update',
    }), name='subscription-detail'),
    path('bills/', BillViewSet.as_view({'get': 'list'}), name='bills'),
    path('bills/<int:pk>/', BillViewSet.as_view({'get': 'retrieve'}), name='bill-detail'),
    path('payments/', PaymentViewSet.as_view({'get': 'list'}), name='payments'),
    path('payments/<int:pk>/', PaymentViewSet.as_view({'get': 'retrieve'}), name='payment-detail'),

    # Usage
    path('usage/', UsageSnapshotViewSet.as_view({'get': 'list'}), name='usage'),

    # Plans
    path('plans/', BillingPlanViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='plans'),
    path('plans/<int:pk>/', BillingPlanViewSet.as_view({
        'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='plan-detail'),

    # Exchange rates
    path('exchange-rates/', ExchangeRateViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='exchange-rates'),
    path('exchange-rates/<str:currency>/', ExchangeRateViewSet.as_view({
        'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='exchange-rate-detail'),

    # Stray users (public-schema cleanup)
    path('stray-users/', StrayUserView.as_view(), name='stray-users'),
    path('stray-users/<str:email>/', StrayUserView.as_view(), name='stray-user-detail'),
]
