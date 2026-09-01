from django.urls import path

from .views import LocationViewSet

app_name = 'locations'

urlpatterns = [
    path('', LocationViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='location-list'),
    path('geofences/', LocationViewSet.as_view({'get': 'geofences'}), name='location-geofences'),
    path('<int:pk>/', LocationViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='location-detail'),
]
