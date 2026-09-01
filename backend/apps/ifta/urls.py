from django.urls import path

from .views import FuelPurchaseViewSet, IftaQuarterViewSet, JurisdictionViewSet, TripLogViewSet

app_name = 'ifta'

urlpatterns = [
    path('jurisdictions/', JurisdictionViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='jurisdiction-list'),
    path('jurisdictions/<int:pk>/', JurisdictionViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='jurisdiction-detail'),
    path('trip-logs/', TripLogViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='triplog-list'),
    path('trip-logs/<int:pk>/', TripLogViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='triplog-detail'),
    path('fuel-purchases/', FuelPurchaseViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='fuelpurchase-list'),
    path('fuel-purchases/<int:pk>/', FuelPurchaseViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='fuelpurchase-detail'),
    path('quarters/', IftaQuarterViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='quarter-list'),
    path('quarters/stats/', IftaQuarterViewSet.as_view({'get': 'stats'}), name='quarter-stats'),
    path('quarters/seed-demo/', IftaQuarterViewSet.as_view({'post': 'seed_demo'}), name='quarter-seed-demo'),
    path('quarters/generate/', IftaQuarterViewSet.as_view({'post': 'generate'}), name='quarter-generate'),
    path('quarters/<int:pk>/', IftaQuarterViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='quarter-detail'),
    path('quarters/<int:pk>/breakdown/', IftaQuarterViewSet.as_view({'get': 'breakdown'}), name='quarter-breakdown'),
]
