from django.urls import path

from .views import ServiceViewSet, VendorRatingViewSet

app_name = 'services'

urlpatterns = [
    path('', ServiceViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='service-list'),
    path('<int:pk>/', ServiceViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='service-detail'),
    path('<int:pk>/rate-vendor/', ServiceViewSet.as_view({'post': 'rate_vendor'}), name='service-rate-vendor'),
    path('seed-demo/', ServiceViewSet.as_view({'post': 'seed_demo'}), name='service-seed-demo'),
    path('ratings/', VendorRatingViewSet.as_view({'get': 'list'}), name='rating-list'),
    path('ratings/<int:pk>/', VendorRatingViewSet.as_view({'get': 'retrieve'}), name='rating-detail'),
]
