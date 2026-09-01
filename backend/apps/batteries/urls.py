from django.urls import path

from .views import (
    BatteryViewSet,
    BatteryReadingViewSet,
    BatteryMovementViewSet,
    ChargeCycleViewSet,
    BatteryReplacementViewSet,
)

app_name = 'batteries'

urlpatterns = [
    path('', BatteryViewSet.as_view({'get': 'list', 'post': 'create'}), name='battery-list'),
    path('catalog/', BatteryViewSet.as_view({'get': 'catalog'}), name='battery-catalog'),
    path('stats/', BatteryViewSet.as_view({'get': 'stats'}), name='battery-stats'),
    path('needs-replacement/', BatteryViewSet.as_view({'get': 'needs_replacement'}), name='battery-needs-replacement'),
    path('<int:pk>/', BatteryViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='battery-detail'),
    path('<int:pk>/install/', BatteryViewSet.as_view({'post': 'install'}), name='battery-install'),
    path('<int:pk>/uninstall/', BatteryViewSet.as_view({'post': 'uninstall'}), name='battery-uninstall'),
    path('<int:pk>/charge/', BatteryViewSet.as_view({'post': 'charge'}), name='battery-charge'),
    path('<int:pk>/retire/', BatteryViewSet.as_view({'post': 'retire'}), name='battery-retire'),
    path('readings/', BatteryReadingViewSet.as_view({'get': 'list', 'post': 'create'}), name='reading-list'),
    path('readings/<int:pk>/', BatteryReadingViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='reading-detail'),
    path('movements/', BatteryMovementViewSet.as_view({'get': 'list'}), name='movement-list'),
    path('movements/<int:pk>/', BatteryMovementViewSet.as_view({'get': 'retrieve'}), name='movement-detail'),
    path('cycles/', ChargeCycleViewSet.as_view({'get': 'list', 'post': 'create'}), name='cycle-list'),
    path('cycles/<int:pk>/', ChargeCycleViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='cycle-detail'),
    path('replacements/', BatteryReplacementViewSet.as_view({'get': 'list', 'post': 'create'}), name='replacement-list'),
    path('replacements/<int:pk>/', BatteryReplacementViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='replacement-detail'),
]
