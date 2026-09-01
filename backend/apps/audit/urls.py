from django.urls import path

from .views import AuditLogViewSet

app_name = 'audit'

urlpatterns = [
    path('', AuditLogViewSet.as_view({'get': 'list'}), name='log-list'),
    path('<int:pk>/', AuditLogViewSet.as_view({'get': 'retrieve'}), name='log-detail'),
]
