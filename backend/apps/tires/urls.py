from django.urls import path

from .views import TireInspectionViewSet, TireMovementViewSet, TireRotationViewSet, TireViewSet

app_name = 'tires'

urlpatterns = [
    path('', TireViewSet.as_view({'get': 'list', 'post': 'create'}), name='tire-list'),
    path('catalog/', TireViewSet.as_view({'get': 'catalog'}), name='tire-catalog'),
    path('needs-replacement/', TireViewSet.as_view({'get': 'needs_replacement'}), name='tire-needs-replacement'),
    path('<int:pk>/', TireViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='tire-detail'),
    path('<int:pk>/mount/', TireViewSet.as_view({'post': 'mount'}), name='tire-mount'),
    path('<int:pk>/unmount/', TireViewSet.as_view({'post': 'unmount'}), name='tire-unmount'),
    path('<int:pk>/retire/', TireViewSet.as_view({'post': 'retire'}), name='tire-retire'),
    path('rotate/', TireViewSet.as_view({'post': 'rotate'}), name='tire-rotate'),
    path('inspections/', TireInspectionViewSet.as_view({'get': 'list', 'post': 'create'}), name='inspection-list'),
    path('inspections/<int:pk>/', TireInspectionViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='inspection-detail'),
    path('rotations/', TireRotationViewSet.as_view({'get': 'list', 'post': 'create'}), name='rotation-list'),
    path('rotations/<int:pk>/', TireRotationViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='rotation-detail'),
    path('movements/', TireMovementViewSet.as_view({'get': 'list'}), name='movement-list'),
    path('movements/<int:pk>/', TireMovementViewSet.as_view({'get': 'retrieve'}), name='movement-detail'),
]
