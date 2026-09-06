from django.urls import path

from .views import (
    TransferViewSet,
    TransferStopViewSet,
    TransferDriverOfferViewSet,
)

app_name = 'transfers'

urlpatterns = [
    path('bookings/', TransferViewSet.as_view({'get': 'list', 'post': 'create'}), name='booking-list'),
    path('bookings/stats/', TransferViewSet.as_view({'get': 'stats'}), name='booking-stats'),

    # Lifecycle actions on individual bookings
    path('bookings/<int:pk>/', TransferViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='booking-detail'),
    path('bookings/<int:pk>/assign/', TransferViewSet.as_view({'post': 'assign'}), name='booking-assign'),
    path('bookings/<int:pk>/start/', TransferViewSet.as_view({'post': 'start'}), name='booking-start'),
    path('bookings/<int:pk>/pickup/', TransferViewSet.as_view({'post': 'pickup'}), name='booking-pickup'),
    path('bookings/<int:pk>/complete/', TransferViewSet.as_view({'post': 'complete'}), name='booking-complete'),
    path('bookings/<int:pk>/cancel/', TransferViewSet.as_view({'post': 'cancel'}), name='booking-cancel'),
    path('bookings/<int:pk>/no-show/', TransferViewSet.as_view({'post': 'no_show'}), name='booking-no-show'),
    path('bookings/<int:pk>/update-location/', TransferViewSet.as_view({'post': 'update_location'}), name='booking-update-location'),
    path('bookings/<int:pk>/record-payment/', TransferViewSet.as_view({'post': 'record_payment'}), name='booking-record-payment'),
    path('bookings/<int:pk>/rate/', TransferViewSet.as_view({'post': 'rate'}), name='booking-rate'),

    # Stops
    path('stops/', TransferStopViewSet.as_view({'get': 'list', 'post': 'create'}), name='stop-list'),
    path('stops/<int:pk>/', TransferStopViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='stop-detail'),

    # Driver offers / bids
    path('offers/', TransferDriverOfferViewSet.as_view({'get': 'list', 'post': 'create'}), name='offer-list'),
    path('offers/<int:pk>/', TransferDriverOfferViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='offer-detail'),
]
