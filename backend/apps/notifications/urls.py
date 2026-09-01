from django.urls import path

from .views import (
    NotificationPreferenceViewSet,
    NotificationTemplateViewSet,
    NotificationViewSet,
)

app_name = 'notifications'

urlpatterns = [
    path('templates/', NotificationTemplateViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='template-list'),
    path('templates/<int:pk>/preview/', NotificationTemplateViewSet.as_view({'post': 'preview'}), name='template-preview'),
    path('templates/<int:pk>/', NotificationTemplateViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='template-detail'),
    path('', NotificationViewSet.as_view({'get': 'list'}), name='notification-list'),
    path('unread/', NotificationViewSet.as_view({'get': 'unread'}), name='notification-unread'),
    path('mark-all-read/', NotificationViewSet.as_view({'post': 'mark_all_read'}), name='notification-mark-all-read'),
    path('<int:pk>/', NotificationViewSet.as_view({'get': 'retrieve'}), name='notification-detail'),
    path('<int:pk>/mark-read/', NotificationViewSet.as_view({'post': 'mark_read'}), name='notification-mark-read'),
    path('preferences/', NotificationPreferenceViewSet.as_view({'get': 'list', 'post': 'create'}), name='preference-list'),
    path('preferences/me/', NotificationPreferenceViewSet.as_view({'get': 'me', 'put': 'me', 'patch': 'me'}), name='preference-me'),
    path('preferences/<int:pk>/', NotificationPreferenceViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='preference-detail'),
]
