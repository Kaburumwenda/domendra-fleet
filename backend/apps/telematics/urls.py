from django.urls import path

from .views import (
    GeofenceEventViewSet,
    TelematicsAlertViewSet,
    TelematicsAnalyticsView,
    TelematicsDeviceViewSet,
    TripViewSet,
    VehicleLocationViewSet,
)

app_name = 'telematics'

urlpatterns = [
    # Devices
    path('devices/', TelematicsDeviceViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='device-list'),
    path('devices/live/', TelematicsDeviceViewSet.as_view({'get': 'live'}), name='device-live'),
    path('devices/<int:pk>/', TelematicsDeviceViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='device-detail'),
    path('devices/<int:pk>/ping/', TelematicsDeviceViewSet.as_view({'post': 'ping'}), name='device-ping'),

    # Trips
    path('trips/', TripViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='trip-list'),
    path('trips/<int:pk>/', TripViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='trip-detail'),
    path('trips/<int:pk>/start/', TripViewSet.as_view({'post': 'start'}), name='trip-start'),
    path('trips/<int:pk>/end/', TripViewSet.as_view({'post': 'end'}), name='trip-end'),
    path('trips/<int:pk>/path/', TripViewSet.as_view({'get': 'path'}), name='trip-path'),

    # Vehicle locations
    path('locations/', VehicleLocationViewSet.as_view({'get': 'list'}), name='location-list'),
    path('locations/recent/', VehicleLocationViewSet.as_view({'get': 'recent'}), name='location-recent'),
    path('locations/<int:pk>/', VehicleLocationViewSet.as_view({'get': 'retrieve'}), name='location-detail'),

    # Geofence events
    path('geofence-events/', GeofenceEventViewSet.as_view({'get': 'list'}), name='geofenceevent-list'),
    path('geofence-events/<int:pk>/', GeofenceEventViewSet.as_view({'get': 'retrieve'}), name='geofenceevent-detail'),

    # Alerts
    path('alerts/', TelematicsAlertViewSet.as_view({'get': 'list'}), name='alert-list'),
    path('alerts/<int:pk>/', TelematicsAlertViewSet.as_view({'get': 'retrieve'}), name='alert-detail'),
    path('alerts/<int:pk>/acknowledge/', TelematicsAlertViewSet.as_view({'post': 'acknowledge'}),
         name='alert-acknowledge'),
    path('alerts/acknowledge-all/', TelematicsAlertViewSet.as_view({'post': 'acknowledge_all'}),
         name='alert-acknowledge-all'),

    # Analytics
    path('analytics/', TelematicsAnalyticsView.as_view({'get': 'list'}), name='analytics'),
]
