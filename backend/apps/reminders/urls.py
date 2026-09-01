from django.urls import path

from .views import ReminderViewSet

app_name = 'reminders'

urlpatterns = [
    path('', ReminderViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='reminder-list'),
    path('<int:pk>/', ReminderViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='reminder-detail'),
    path('stats/', ReminderViewSet.as_view({'get': 'stats'}), name='reminder-stats'),
    path('seed-demo/', ReminderViewSet.as_view({'post': 'seed_demo'}), name='reminder-seed-demo'),
    path('due/', ReminderViewSet.as_view({'get': 'due'}), name='reminder-due'),
]
