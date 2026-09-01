from django.urls import path

from .views import BayReservationViewSet, GarageBayViewSet

app_name = 'garage'

urlpatterns = [
    path('bays/', GarageBayViewSet.as_view({'get': 'list', 'post': 'create'}), name='bay-list'),
    path('bays/<int:pk>/', GarageBayViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='bay-detail'),
    path('bays/stats/', GarageBayViewSet.as_view({'get': 'stats'}), name='bay-stats'),
    path('reservations/', BayReservationViewSet.as_view({'get': 'list', 'post': 'create'}), name='reservation-list'),
    path('reservations/<int:pk>/', BayReservationViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='reservation-detail'),
    path('reservations/schedule/', BayReservationViewSet.as_view({'get': 'schedule'}), name='reservation-schedule'),
    path('reservations/stats/', BayReservationViewSet.as_view({'get': 'stats'}), name='reservation-stats'),
    path('reservations/seed-demo/', BayReservationViewSet.as_view({'post': 'seed_demo'}), name='reservation-seed-demo'),
]
