from django.urls import path

from .views import DqfCheckViewSet, DriverQualificationFileViewSet

app_name = 'dqf'

urlpatterns = [
    path('files/', DriverQualificationFileViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='file-list'),
    path('files/expiring/', DriverQualificationFileViewSet.as_view({'get': 'expiring'}), name='file-expiring'),
    path('files/<int:pk>/', DriverQualificationFileViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='file-detail'),
    path('files/<int:pk>/complete-review/', DriverQualificationFileViewSet.as_view({'post': 'complete_review'}), name='file-complete-review'),
    path('checks/', DqfCheckViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='check-list'),
    path('checks/<int:pk>/', DqfCheckViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='check-detail'),
    path('checks/<int:pk>/clear/', DqfCheckViewSet.as_view({'post': 'clear'}), name='check-clear'),
]
