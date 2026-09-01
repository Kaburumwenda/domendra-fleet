from django.urls import path

from .views import InspectionFormViewSet, InspectionItemViewSet, InspectionReportViewSet

app_name = 'inspections'

urlpatterns = [
    path('forms/', InspectionFormViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='form-list'),
    path('forms/<int:pk>/', InspectionFormViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='form-detail'),
    path('items/', InspectionItemViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='item-list'),
    path('items/<int:pk>/', InspectionItemViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='item-detail'),
    path('reports/', InspectionReportViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='report-list'),
    path('reports/<int:pk>/', InspectionReportViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='report-detail'),
    path('reports/summary/', InspectionReportViewSet.as_view({'get': 'summary'}), name='report-summary'),
    path('reports/stats/', InspectionReportViewSet.as_view({'get': 'stats'}), name='report-stats'),
    path('reports/seed-demo/', InspectionReportViewSet.as_view({'post': 'seed_demo'}), name='report-seed-demo'),
]
