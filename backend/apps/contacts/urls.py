from django.urls import path

from .views import (
    ContactViewSet,
    DriverViewSet,
    DriverProfileViewSet,
    DriverViolationViewSet,
    DriverDrugTestViewSet,
    DriverTrainingViewSet,
    DriverHoursOfServiceViewSet,
    DriverAssignmentViewSet,
    DriverNoteViewSet,
)

app_name = 'contacts'

urlpatterns = [
    path('', ContactViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='contact-list'),
    path('stats/', ContactViewSet.as_view({'get': 'stats'}), name='contact-stats'),
    path('seed_demo/', ContactViewSet.as_view({'post': 'seed_demo'}), name='contact-seed-demo'),
    path('<int:pk>/', ContactViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='contact-detail'),

    # Driver management endpoints
    path('drivers/', DriverViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='driver-list'),
    path('drivers/stats/', DriverViewSet.as_view({'get': 'stats'}), name='driver-stats'),
    path('drivers/seed_demo/', DriverViewSet.as_view({'post': 'seed_demo'}), name='driver-seed-demo'),
    path('drivers/<int:pk>/', DriverViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='driver-detail'),

    path('profiles/', DriverProfileViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='driverprofile-list'),
    path('profiles/<int:pk>/', DriverProfileViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='driverprofile-detail'),

    path('violations/', DriverViolationViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='violation-list'),
    path('violations/<int:pk>/', DriverViolationViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='violation-detail'),

    path('drug-tests/', DriverDrugTestViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='drugtest-list'),
    path('drug-tests/<int:pk>/', DriverDrugTestViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='drugtest-detail'),

    path('trainings/', DriverTrainingViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='training-list'),
    path('trainings/<int:pk>/', DriverTrainingViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='training-detail'),

    path('hos/', DriverHoursOfServiceViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='hos-list'),
    path('hos/<int:pk>/', DriverHoursOfServiceViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='hos-detail'),

    path('assignments/', DriverAssignmentViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='assignment-list'),
    path('assignments/<int:pk>/', DriverAssignmentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='assignment-detail'),
    path('assignments/<int:pk>/release/', DriverAssignmentViewSet.as_view({'post': 'release'}), name='assignment-release'),

    path('notes/', DriverNoteViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='note-list'),
    path('notes/<int:pk>/', DriverNoteViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='note-detail'),
]
