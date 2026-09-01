from django.urls import path

from .views import JobViewSet, RouteStopViewSet, VehicleAssignmentViewSet, RouteOptimizationViewSet, TrafficWeatherViewSet

app_name = 'dispatch'

urlpatterns = [
    path('jobs/', JobViewSet.as_view({'get': 'list', 'post': 'create'}), name='job-list'),
    path('jobs/<int:pk>/', JobViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='job-detail'),
    path('jobs/<int:pk>/assign/', JobViewSet.as_view({'post': 'assign'}), name='job-assign'),
    path('jobs/<int:pk>/start/', JobViewSet.as_view({'post': 'start'}), name='job-start'),
    path('jobs/<int:pk>/complete/', JobViewSet.as_view({'post': 'complete'}), name='job-complete'),
    path('jobs/<int:pk>/cancel/', JobViewSet.as_view({'post': 'cancel'}), name='job-cancel'),
    path('jobs/<int:pk>/update-location/', JobViewSet.as_view({'post': 'update_location'}), name='job-update-location'),
    path('stops/', RouteStopViewSet.as_view({'get': 'list', 'post': 'create'}), name='stop-list'),
    path('stops/<int:pk>/', RouteStopViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='stop-detail'),
    path('stops/for_job/<int:job_id>/', RouteStopViewSet.as_view({'get': 'list_for_job'}), name='stop-for-job'),
    path('jobs/for_driver/<int:driver_id>/', JobViewSet.as_view({'get': 'jobs_for_driver'}), name='job-for-driver'),
    path('assignments/', VehicleAssignmentViewSet.as_view({'get': 'list', 'post': 'create'}), name='assignment-list'),
    path('assignments/<int:pk>/', VehicleAssignmentViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='assignment-detail'),
    # Route optimization
    path('route/optimize/', RouteOptimizationViewSet.as_view({'post': 'optimize'}), name='route-optimize'),
    # Traffic and weather
    path('traffic/', TrafficWeatherViewSet.as_view({'post': 'traffic'}), name='traffic'),
    path('weather/', TrafficWeatherViewSet.as_view({'post': 'weather'}), name='weather'),
]
