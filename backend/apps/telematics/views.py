from datetime import timedelta

from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import GeofenceEvent, TelematicsAlert, TelematicsDevice, Trip, VehicleLocation
from .serializers import (
    GeofenceEventSerializer,
    TelematicsAlertSerializer,
    TelematicsDeviceSerializer,
    TripSerializer,
    VehicleLocationSerializer,
)


class TelematicsDeviceViewSet(viewsets.ModelViewSet):
    queryset = TelematicsDevice.objects.select_related('vehicle')
    serializer_class = TelematicsDeviceSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['provider', 'status', 'vehicle']
    search_fields = ['serial_number', 'imei']
    ordering_fields = ['created_at', 'last_reported_at']

    @action(detail=True, methods=['post'])
    def ping(self, request, pk=None):
        """Ingest a live location ping from a device."""
        device = self.get_object()
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        if lat is None or lng is None:
            return Response({'detail': 'latitude and longitude are required.'}, status=status.HTTP_400_BAD_REQUEST)
        device.last_latitude = float(lat)
        device.last_longitude = float(lng)
        device.last_heading = request.data.get('heading')
        device.last_speed = request.data.get('speed')
        device.last_ignition_on = request.data.get('ignition_on', True)
        device.last_reported_at = timezone.now()
        device.save(update_fields=[
            'last_latitude', 'last_longitude', 'last_heading', 'last_speed',
            'last_ignition_on', 'last_reported_at', 'updated_at',
        ])
        if device.vehicle:
            VehicleLocation.objects.create(
                device=device, vehicle=device.vehicle,
                latitude=float(lat), longitude=float(lng),
                heading=device.last_heading, speed=device.last_speed,
                ignition_on=device.last_ignition_on,
                odometer=request.data.get('odometer'),
                recorded_at=device.last_reported_at,
            )
            # Check for speeding alert
            speed = device.last_speed
            speed_limit = device.speed_limit
            if speed_limit and speed and speed > speed_limit:
                TelematicsAlert.objects.create(
                    device=device, vehicle=device.vehicle,
                    alert_type=TelematicsAlert.AlertType.SPEEDING,
                    severity=TelematicsAlert.Severity.WARNING,
                    message=f'Speed {round(speed)} exceeds limit {round(speed_limit)}',
                    latitude=lat, longitude=lng,
                    speed=speed, threshold=speed_limit,
                )
        return Response(TelematicsDeviceSerializer(device).data)

    @action(detail=False, methods=['get'])
    def live(self, request):
        """Snapshot of all devices' last known positions for the live map."""
        qs = self.get_queryset().filter(status=TelematicsDevice.Status.ACTIVE)
        return Response(TelematicsDeviceSerializer(qs, many=True).data)


class TripViewSet(viewsets.ModelViewSet):
    queryset = Trip.objects.select_related('vehicle', 'driver', 'device')
    serializer_class = TripSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status', 'vehicle', 'driver']
    ordering_fields = ['started_at', 'distance', 'duration_minutes']

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Activate a trip and set start position."""
        trip = self.get_object()
        if trip.status != Trip.Status.ACTIVE:
            trip.status = Trip.Status.ACTIVE
        trip.start_latitude = request.data.get('start_latitude', trip.start_latitude)
        trip.start_longitude = request.data.get('start_longitude', trip.start_longitude)
        trip.start_address = request.data.get('start_address', trip.start_address)
        if request.data.get('start_odometer') is not None:
            trip.start_odometer = float(request.data['start_odometer'])
        if not trip.started_at:
            trip.started_at = timezone.now()
        trip.save()
        return Response(TripSerializer(trip).data)

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        trip = self.get_object()
        if trip.status != Trip.Status.ACTIVE:
            return Response({'detail': 'Trip is not active.'}, status=status.HTTP_400_BAD_REQUEST)
        trip.status = Trip.Status.COMPLETED
        trip.ended_at = timezone.now()
        end_odo = request.data.get('end_odometer')
        if end_odo is not None and trip.start_odometer is not None:
            trip.end_odometer = float(end_odo)
            trip.distance = max(0, trip.end_odometer - trip.start_odometer)
        if trip.ended_at and trip.started_at:
            trip.duration_minutes = round((trip.ended_at - trip.started_at).total_seconds() / 60, 2)
        trip.end_latitude = request.data.get('end_latitude')
        trip.end_longitude = request.data.get('end_longitude')
        trip.end_address = request.data.get('end_address', '')
        trip.max_speed = request.data.get('max_speed')
        trip.idle_minutes = request.data.get('idle_minutes', 0)
        trip.harsh_braking_events = request.data.get('harsh_braking_events', 0)
        trip.harsh_acceleration_events = request.data.get('harsh_acceleration_events', 0)
        trip.save()
        return Response(TripSerializer(trip).data)

    @action(detail=True, methods=['get'])
    def path(self, request, pk=None):
        """Return location pings recorded during this trip for map replay."""
        trip = self.get_object()
        qs = VehicleLocation.objects.filter(
            vehicle=trip.vehicle, recorded_at__gte=trip.started_at,
        )
        if trip.ended_at:
            qs = qs.filter(recorded_at__lte=trip.ended_at)
        qs = qs.order_by('recorded_at')
        return Response(VehicleLocationSerializer(qs, many=True).data)


class VehicleLocationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VehicleLocation.objects.select_related('vehicle', 'device')
    serializer_class = VehicleLocationSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['vehicle', 'device']
    ordering_fields = ['recorded_at']

    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Recent pings for a vehicle (last 24h), for trail rendering."""
        vehicle_id = request.query_params.get('vehicle')
        qs = self.get_queryset()
        if vehicle_id:
            qs = qs.filter(vehicle_id=vehicle_id)
        qs = qs.filter(recorded_at__gte=timezone.now() - timedelta(hours=24)).order_by('recorded_at')
        return Response(VehicleLocationSerializer(qs, many=True).data)


class GeofenceEventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = GeofenceEvent.objects.select_related('vehicle', 'location')
    serializer_class = GeofenceEventSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['event_type', 'vehicle', 'location']
    ordering_fields = ['occurred_at']


class TelematicsAlertViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TelematicsAlert.objects.select_related('device', 'vehicle', 'acknowledged_by')
    serializer_class = TelematicsAlertSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['alert_type', 'severity', 'acknowledged', 'vehicle', 'device']
    ordering_fields = ['triggered_at']

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Acknowledge a single alert."""
        alert = self.get_object()
        if alert.acknowledged:
            return Response({'detail': 'Alert already acknowledged.'}, status=status.HTTP_400_BAD_REQUEST)
        alert.acknowledged = True
        alert.acknowledged_at = timezone.now()
        alert.acknowledged_by = request.user
        alert.save(update_fields=['acknowledged', 'acknowledged_at', 'acknowledged_by'])
        return Response(TelematicsAlertSerializer(alert).data)

    @action(detail=False, methods=['post'])
    def acknowledge_all(self, request):
        """Acknowledge all unacknowledged alerts (optionally filtered by alert_type)."""
        qs = self.get_queryset().filter(acknowledged=False)
        alert_type = request.data.get('alert_type')
        if alert_type:
            qs = qs.filter(alert_type=alert_type)
        count = qs.update(
            acknowledged=True,
            acknowledged_at=timezone.now(),
            acknowledged_by_id=request.user.id,
        )
        return Response({'acknowledged': count})


class TelematicsAnalyticsView(viewsets.ViewSet):
    """Analytics dashboard for telematics overview."""
    permission_classes = [IsAuthenticated]

    def list(self, request):
        now = timezone.now()
        devices = TelematicsDevice.objects.all()
        active_devices = devices.filter(status=TelematicsDevice.Status.ACTIVE)
        moving_devices = active_devices.filter(last_speed__gt=0)
        stale_count = sum(1 for d in active_devices if d.is_stale)

        # Trips
        trips = Trip.objects.all()
        active_trips = trips.filter(status=Trip.Status.ACTIVE)
        completed_trips = trips.filter(status=Trip.Status.COMPLETED)

        # This month
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        month_trips = trips.filter(started_at__gte=month_start)
        total_distance = month_trips.aggregate(d=Sum('distance'))['d'] or 0
        total_duration = month_trips.aggregate(d=Sum('duration_minutes'))['d'] or 0

        # Alerts
        alerts = TelematicsAlert.objects.all()
        unack_alerts = alerts.filter(acknowledged=False)
        critical_alerts = alerts.filter(severity=TelematicsAlert.Severity.CRITICAL, acknowledged=False)

        # Geofence events this month
        geofence_events = GeofenceEvent.objects.filter(occurred_at__gte=month_start)
        geofence_enter = geofence_events.filter(event_type=GeofenceEvent.EventType.ENTER).count()
        geofence_exit = geofence_events.filter(event_type=GeofenceEvent.EventType.EXIT).count()

        # Daily trip series (last 7 days)
        daily_series = []
        for i in range(6, -1, -1):
            day_start = (now - timedelta(days=i)).replace(hour=0, minute=0, second=0, microsecond=0)
            day_end = day_start + timedelta(days=1)
            day_trips = trips.filter(started_at__gte=day_start, started_at__lt=day_end)
            daily_series.append({
                'date': day_start.date().isoformat(),
                'trips': day_trips.count(),
                'distance': round(sum(t.distance or 0 for t in day_trips), 1),
            })

        # Alert distribution by type
        alert_dist = list(
            alerts.values('alert_type').annotate(count=Count('id')).order_by('-count')
        )

        return Response({
            'summary': {
                'total_devices': devices.count(),
                'active_devices': active_devices.count(),
                'moving_devices': moving_devices.count(),
                'stale_devices': stale_count,
                'active_trips': active_trips.count(),
                'completed_trips': completed_trips.count(),
                'month_total_distance': round(float(total_distance), 1),
                'month_total_duration': round(float(total_duration), 1),
                'unack_alerts': unack_alerts.count(),
                'critical_alerts': critical_alerts.count(),
                'geofence_enter': geofence_enter,
                'geofence_exit': geofence_exit,
            },
            'daily_series': daily_series,
            'alert_distribution': alert_dist,
        })
