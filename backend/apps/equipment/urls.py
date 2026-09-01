from django.urls import path

from .views import (
    CalibrationRecordViewSet,
    EquipmentCategoryViewSet,
    EquipmentCheckoutViewSet,
    EquipmentMeterEntryViewSet,
    EquipmentViewSet,
)

app_name = 'equipment'

urlpatterns = [
    path('categories/', EquipmentCategoryViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='category-list'),
    path('categories/<int:pk>/', EquipmentCategoryViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='category-detail'),
    path('items/', EquipmentViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='item-list'),
    path('items/<int:pk>/', EquipmentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='item-detail'),
    path('items/<int:pk>/meter-entry/', EquipmentViewSet.as_view({'post': 'meter_entry'}), name='item-meter-entry'),
    path('items/<int:pk>/check-out/', EquipmentViewSet.as_view({'post': 'check_out'}), name='item-check-out'),
    path('items/<int:pk>/check-in/', EquipmentViewSet.as_view({'post': 'check_in'}), name='item-check-in'),
    path('items/calibration-due/', EquipmentViewSet.as_view({'get': 'calibration_due'}), name='item-calibration-due'),
    path('items/analytics/', EquipmentViewSet.as_view({'get': 'analytics'}), name='item-analytics'),
    path('items/seed-demo/', EquipmentViewSet.as_view({'post': 'seed_demo'}), name='item-seed-demo'),
    path('checkouts/', EquipmentCheckoutViewSet.as_view({'get': 'list'}), name='checkout-list'),
    path('checkouts/<int:pk>/', EquipmentCheckoutViewSet.as_view({'get': 'retrieve'}), name='checkout-detail'),
    path('meter-entries/', EquipmentMeterEntryViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='meterentry-list'),
    path('meter-entries/<int:pk>/', EquipmentMeterEntryViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='meterentry-detail'),
    path('calibrations/', CalibrationRecordViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='calibration-list'),
    path('calibrations/<int:pk>/', CalibrationRecordViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='calibration-detail'),
]
