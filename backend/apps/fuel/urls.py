from django.urls import path

from .views import (
    ChargeScheduleViewSet,
    ChargingSessionViewSet,
    FuelBudgetViewSet,
    FuelCardViewSet,
    FuelFraudAlertViewSet,
    FuelTransactionViewSet,
    IdlingEventViewSet,
)

app_name = 'fuel'

urlpatterns = [
    path('transactions/', FuelTransactionViewSet.as_view({'get': 'list', 'post': 'create'}), name='tx-list'),
    path('transactions/<int:pk>/', FuelTransactionViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='tx-detail'),
    path('transactions/analytics/', FuelTransactionViewSet.as_view({'get': 'analytics'}), name='tx-analytics'),
    path('transactions/vehicle-pdf/', FuelTransactionViewSet.as_view({'get': 'vehicle_fuel_pdf'}), name='tx-vehicle-pdf'),
    path('transactions/fleet-pdf/', FuelTransactionViewSet.as_view({'get': 'fleet_fuel_pdf'}), name='tx-fleet-pdf'),
    path('cards/', FuelCardViewSet.as_view({'get': 'list', 'post': 'create'}), name='card-list'),
    path('cards/sync-all/', FuelCardViewSet.as_view({'post': 'sync_all'}), name='card-sync-all'),
    path('cards/<int:pk>/', FuelCardViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='card-detail'),
    path('cards/<int:pk>/sync/', FuelCardViewSet.as_view({'post': 'sync'}), name='card-sync'),
    path('charging/', ChargingSessionViewSet.as_view({'get': 'list', 'post': 'create'}), name='charging-list'),
    path('charging/<int:pk>/', ChargingSessionViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='charging-detail'),
    path('charging/summary/', ChargingSessionViewSet.as_view({'get': 'summary'}), name='charging-summary'),
    path('fraud/', FuelFraudAlertViewSet.as_view({'get': 'list', 'post': 'create'}), name='fraud-list'),
    path('fraud/<int:pk>/', FuelFraudAlertViewSet.as_view({'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy'}), name='fraud-detail'),
    path('fraud/<int:pk>/resolve/', FuelFraudAlertViewSet.as_view({'post': 'resolve'}), name='fraud-resolve'),
    path('fraud/<int:pk>/dismiss/', FuelFraudAlertViewSet.as_view({'post': 'dismiss'}), name='fraud-dismiss'),
    path('fraud/<int:pk>/review/', FuelFraudAlertViewSet.as_view({'post': 'review'}), name='fraud-review'),
    path('fraud/<int:pk>/reopen/', FuelFraudAlertViewSet.as_view({'post': 'reopen'}), name='fraud-reopen'),
    path('fraud/summary/', FuelFraudAlertViewSet.as_view({'get': 'summary'}), name='fraud-summary'),
    path('idling/', IdlingEventViewSet.as_view({'get': 'list', 'post': 'create'}), name='idling-list'),
    path('idling/<int:pk>/', IdlingEventViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='idling-detail'),
    path('idling/summary/', IdlingEventViewSet.as_view({'get': 'summary'}), name='idling-summary'),
    path('charge-schedules/', ChargeScheduleViewSet.as_view({'get': 'list', 'post': 'create'}), name='schedule-list'),
    path('charge-schedules/<int:pk>/', ChargeScheduleViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='schedule-detail'),
    path('budgets/', FuelBudgetViewSet.as_view({'get': 'list', 'post': 'create'}), name='budget-list'),
    path('budgets/<int:pk>/', FuelBudgetViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='budget-detail'),
    path('budgets/summary/', FuelBudgetViewSet.as_view({'get': 'summary'}), name='budget-summary'),
]
