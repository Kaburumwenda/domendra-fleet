from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
import django_filters

from .models import Transfer, TransferStop, TransferDriverOffer
from .serializers import (
    TransferSerializer,
    TransferDetailSerializer,
    TransferCreateSerializer,
    TransferStopSerializer,
    TransferDriverOfferSerializer,
)


class TransferFilter(django_filters.FilterSet):
    """Date-range + existing field filters for transfers."""
    pickup_date_from = django_filters.DateFilter(field_name='pickup_datetime', lookup_expr='date__gte')
    pickup_date_to = django_filters.DateFilter(field_name='pickup_datetime', lookup_expr='date__lte')

    class Meta:
        model = Transfer
        fields = [
            'status', 'service_class', 'trip_type', 'payment_status',
            'vehicle', 'driver',
        ]


class TransferViewSet(viewsets.ModelViewSet):
    """Full CRUD for transfer bookings with lifecycle actions."""

    queryset = Transfer.objects.select_related('vehicle', 'driver').prefetch_related('stops', 'driver_offers')
    filterset_class = TransferFilter
    search_fields = [
        'reference', 'passenger_name', 'passenger_phone', 'passenger_email',
        'pickup_name', 'dropoff_name', 'pickup_flight_no',
    ]
    ordering_fields = ['pickup_datetime', 'created_at', 'total_amount', 'status']

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return TransferDetailSerializer
        if self.action in ('create', 'update', 'partial_update'):
            return TransferCreateSerializer
        return TransferSerializer

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """KPI stats for the transfer dashboard."""
        qs = self.get_queryset()
        today = timezone.now().date()
        total = qs.count()
        upcoming = qs.filter(
            status__in=['draft', 'scheduled', 'assigned'],
            pickup_datetime__gte=timezone.now(),
        ).count()
        completed = qs.filter(status='completed').count()
        en_route = qs.filter(status__in=['en_route', 'picked_up']).count()
        revenue = sum(t.total_amount for t in qs.filter(status='completed'))
        outstanding = sum(t.remaining_balance for t in qs.filter(status__in=['completed', 'en_route', 'picked_up']))
        # Today's transfers
        today_count = qs.filter(pickup_datetime__date=today).count()
        return Response({
            'total': total,
            'upcoming': upcoming,
            'completed': completed,
            'en_route': en_route,
            'revenue': float(revenue),
            'outstanding': float(outstanding),
            'today_count': today_count,
        })

    @action(detail=True, methods=['post'])
    def assign(self, request, pk=None):
        """Assign a vehicle and/or driver to this transfer."""
        transfer = self.get_object()
        vehicle_id = request.data.get('vehicle')
        driver_id = request.data.get('driver')
        if vehicle_id:
            transfer.vehicle_id = vehicle_id
        if driver_id:
            transfer.driver_id = driver_id
        if transfer.status == 'scheduled':
            transfer.status = 'assigned'
        transfer.save()
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Mark the transfer as en route (driver heading to pickup)."""
        transfer = self.get_object()
        transfer.status = 'en_route'
        transfer.save(update_fields=['status'])
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def pickup(self, request, pk=None):
        """Confirm passenger picked up."""
        transfer = self.get_object()
        transfer.status = 'picked_up'
        transfer.actual_pickup_time = timezone.now()
        transfer.save(update_fields=['status', 'actual_pickup_time'])
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Complete the transfer and record drop-off time."""
        transfer = self.get_object()
        transfer.status = 'completed'
        transfer.actual_dropoff_time = timezone.now()
        transfer.save(update_fields=['status', 'actual_dropoff_time'])
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel this transfer with optional reason."""
        transfer = self.get_object()
        reason = request.data.get('reason', '')
        transfer.status = 'cancelled'
        if reason:
            transfer.notes = f'{transfer.notes}\n[CANCELLED: {reason}]'.strip()
        transfer.save()
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'])
    def no_show(self, request, pk=None):
        """Mark passenger as no-show."""
        transfer = self.get_object()
        transfer.status = 'no_show'
        transfer.save(update_fields=['status'])
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'], url_path='update-location')
    def update_location(self, request, pk=None):
        """Update driver's current GPS position for live tracking."""
        transfer = self.get_object()
        lat = request.data.get('lat')
        lng = request.data.get('lng')
        if lat is not None:
            transfer.driver_current_lat = lat
        if lng is not None:
            transfer.driver_current_lng = lng
        transfer.save(update_fields=['driver_current_lat', 'driver_current_lng'])
        return Response({'ok': True})

    @action(detail=True, methods=['post'], url_path='record-payment')
    def record_payment(self, request, pk=None):
        """Record a payment against this transfer."""
        transfer = self.get_object()
        amount = request.data.get('amount', 0)
        method = request.data.get('method', '')
        reference = request.data.get('reference', '')
        transfer.amount_paid = (transfer.amount_paid or 0) + float(amount)
        if method:
            transfer.payment_method = method
        if reference:
            transfer.payment_reference = reference
        transfer.save()
        return Response(TransferDetailSerializer(transfer).data)

    @action(detail=True, methods=['post'], url_path='rate')
    def rate(self, request, pk=None):
        """Record passenger rating and feedback."""
        transfer = self.get_object()
        transfer.rating = request.data.get('rating')
        transfer.feedback = request.data.get('feedback', '')
        transfer.save()
        return Response(TransferDetailSerializer(transfer).data)


class TransferStopViewSet(viewsets.ModelViewSet):
    queryset = TransferStop.objects.select_related('transfer')
    serializer_class = TransferStopSerializer
    filterset_fields = ['transfer']
    ordering_fields = ['sequence']


class TransferDriverOfferViewSet(viewsets.ModelViewSet):
    queryset = TransferDriverOffer.objects.select_related('transfer', 'driver', 'vehicle')
    serializer_class = TransferDriverOfferSerializer
    filterset_fields = ['transfer', 'driver', 'status']
    ordering_fields = ['quoted_eta_min', 'created_at']
