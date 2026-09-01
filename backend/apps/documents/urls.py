from django.urls import path

from .views import DocumentViewSet

app_name = 'documents'

urlpatterns = [
    path('', DocumentViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='document-list'),
    path('stats/', DocumentViewSet.as_view({
        'get': 'stats',
    }), name='document-stats'),
    path('seed-demo/', DocumentViewSet.as_view({
        'post': 'seed_demo',
    }), name='document-seed-demo'),
    path('<int:pk>/', DocumentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='document-detail'),
]
