from django.urls import path

from .views import RecallVehicleViewSet, RecallViewSet

app_name = 'recalls'

urlpatterns = [
    path('', RecallViewSet.as_view({'get': 'list', 'post': 'create'}), name='recall-list'),
    path('stats/', RecallViewSet.as_view({'get': 'stats'}), name='recall-stats'),
    path('seed-demo/', RecallViewSet.as_view({'post': 'seed_demo'}), name='recall-seed-demo'),
    path('<int:pk>/', RecallViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='recall-detail'),
    path('<int:pk>/apply-to-vehicles/', RecallViewSet.as_view({'post': 'apply_to_vehicles'}), name='recall-apply'),
    path('<int:pk>/auto-match/', RecallViewSet.as_view({'post': 'auto_match'}), name='recall-automatch'),
    path('vehicles/', RecallVehicleViewSet.as_view({'get': 'list', 'post': 'create'}), name='recallvehicle-list'),
    path('vehicles/<int:pk>/', RecallVehicleViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='recallvehicle-detail'),
    path('vehicles/<int:pk>/resolve/', RecallVehicleViewSet.as_view({'post': 'resolve'}), name='recallvehicle-resolve'),
]
