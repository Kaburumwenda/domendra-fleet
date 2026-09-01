from django.urls import path

from .views import (
    APIUsageLogViewSet,
    BillingPlanViewSet,
    ExchangeRateViewSet,
    MonthlyBillViewSet,
    PaymentViewSet,
    TenantSubscriptionViewSet,
    UsageAnalyticsView,
)

app_name = 'billing'

urlpatterns = [
    path('plans/', BillingPlanViewSet.as_view({'get': 'list'}), name='plans'),
    path('plans/<int:pk>/', BillingPlanViewSet.as_view({'get': 'retrieve'}), name='plan-detail'),
    path('exchange-rate/', ExchangeRateViewSet.as_view({'get': 'list'}), name='exchange-rate'),
    path('subscription/', TenantSubscriptionViewSet.as_view({'get': 'list'}), name='subscription'),
    path('subscription/<int:pk>/', TenantSubscriptionViewSet.as_view({'get': 'retrieve'}), name='subscription-detail'),
    path('usage/', APIUsageLogViewSet.as_view({'get': 'list'}), name='usage'),
    path('analytics/', UsageAnalyticsView.as_view(), name='analytics'),
    path('bills/', MonthlyBillViewSet.as_view({'get': 'list'}), name='bills'),
    path('bills/<int:pk>/', MonthlyBillViewSet.as_view({'get': 'retrieve'}), name='bill-detail'),
    path('bills/<int:pk>/pay/', MonthlyBillViewSet.as_view({'post': 'pay'}), name='bill-pay'),
    path('payments/', PaymentViewSet.as_view({'get': 'list'}), name='payments'),
]
