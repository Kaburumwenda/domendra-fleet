from django.urls import path

from .views import (
    CatalogSeedView,
    CustomFieldViewSet,
    CustomFieldValueViewSet,
    FleetGroupViewSet,
    VehicleBodyTypeViewSet,
    VehicleMakeViewSet,
    VehicleModelViewSet,
    VehicleTypeViewSet,
    VehicleViewSet,
    VinDecodeView,
)

app_name = 'vehicles'

urlpatterns = [
    path('vehicles/', VehicleViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='vehicle-list'),
    path('vehicles/<int:pk>/', VehicleViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='vehicle-detail'),
    path('vehicles/<int:pk>/meter-entry/', VehicleViewSet.as_view({'post': 'meter_entry'}), name='vehicle-meter-entry'),
    path('vehicles/<int:pk>/profit-loss/', VehicleViewSet.as_view({'get': 'profit_loss'}), name='vehicle-profit-loss'),
    path('vehicles/<int:pk>/cost-of-ownership/', VehicleViewSet.as_view({'get': 'cost_of_ownership'}), name='vehicle-cost-of-ownership'),
    path('vehicles/analytics/', VehicleViewSet.as_view({'get': 'analytics'}), name='vehicle-analytics'),
    path('vehicles/vehicle-monitor/', VehicleViewSet.as_view({'get': 'vehicle_monitor'}), name='vehicle-monitor'),
    path('groups/', FleetGroupViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='group-list'),
    path('groups/<int:pk>/', FleetGroupViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='group-detail'),
    path('vehicle-types/', VehicleTypeViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='vehicletype-list'),
    path('vehicle-types/<int:pk>/', VehicleTypeViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='vehicletype-detail'),
    path('catalog/makes/', VehicleMakeViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='catalog-make-list'),
    path('catalog/makes/<int:pk>/', VehicleMakeViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='catalog-make-detail'),
    path('catalog/body-types/', VehicleBodyTypeViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='catalog-bodytype-list'),
    path('catalog/body-types/<int:pk>/', VehicleBodyTypeViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='catalog-bodytype-detail'),
    path('catalog/models/', VehicleModelViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='catalog-model-list'),
    path('catalog/models/<int:pk>/', VehicleModelViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='catalog-model-detail'),
    path('catalog/seed/', CatalogSeedView.as_view(), name='catalog-seed'),
    path('custom-fields/', CustomFieldViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='customfield-list'),
    path('custom-fields/<int:pk>/', CustomFieldViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='customfield-detail'),
    path('custom-field-values/', CustomFieldValueViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='customfieldvalue-list'),
    path('custom-field-values/<int:pk>/', CustomFieldValueViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='customfieldvalue-detail'),
    path('vin-decode/', VinDecodeView.as_view(), name='vin-decode'),
]
