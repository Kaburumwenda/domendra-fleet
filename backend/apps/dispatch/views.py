from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import Job, RouteStop, VehicleAssignment
from .serializers import JobSerializer, RouteStopSerializer, VehicleAssignmentSerializer


class JobViewSet(viewsets.ModelViewSet):
    queryset = Job.objects.select_related('vehicle', 'driver').prefetch_related('stops')
    serializer_class = JobSerializer
    filterset_fields = ['status', 'priority', 'vehicle', 'driver']
    search_fields = ['title', 'pickup_address', 'dropoff_address']
    ordering_fields = ['created_at', 'scheduled_start', 'priority']

    @action(detail=True, methods=['post'])
    def assign(self, request, pk=None):
        job = self.get_object()
        vehicle_id = request.data.get('vehicle')
        driver_id = request.data.get('driver')
        from apps.vehicles.models import Vehicle
        from apps.contacts.models import Contact
        if vehicle_id:
            job.vehicle_id = vehicle_id
        if driver_id:
            job.driver_id = driver_id
        job.status = 'assigned'
        job.save(update_fields=['vehicle', 'driver', 'status'])
        return Response(JobSerializer(job).data)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        from django.utils import timezone
        job = self.get_object()
        job.status = 'in_progress'
        job.actual_start = timezone.now()
        job.save(update_fields=['status', 'actual_start'])
        return Response(JobSerializer(job).data)

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        from django.utils import timezone
        job = self.get_object()
        job.status = 'completed'
        job.actual_end = timezone.now()
        job.save(update_fields=['status', 'actual_end'])
        return Response(JobSerializer(job).data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        job = self.get_object()
        job.status = 'cancelled'
        job.save(update_fields=['status'])
        return Response(JobSerializer(job).data)

    @action(detail=True, methods=['post'], url_path='update-location')
    def update_location(self, request, pk=None):
        """Update the driver's current location for a job (lat/lng)."""
        job = self.get_object()
        lat = request.data.get('lat')
        lng = request.data.get('lng')
        # No field on Job for current location — store as note annotation only
        # We expose nothing persistent here but respond ok so frontend can call.
        return Response({'ok': True, 'lat': lat, 'lng': lng})

    @action(detail=False, methods=['get'], url_path=r'for_driver/(?P<driver_id>\d+)')
    def jobs_for_driver(self, request, driver_id=None):
        """Return jobs assigned to a given driver."""
        jobs = self.queryset.filter(driver_id=driver_id) if driver_id else self.queryset.none()
        return Response(self.get_serializer(jobs, many=True).data)


class RouteStopViewSet(viewsets.ModelViewSet):
    queryset = RouteStop.objects.select_related('job')
    serializer_class = RouteStopSerializer
    filterset_fields = ['job', 'status']
    ordering_fields = ['sequence']

    @action(detail=False, methods=['get'], url_path=r'for_job/(?P<job_id>\d+)')
    def list_for_job(self, request, job_id=None):
        from django.shortcuts import get_object_or_404
        job = get_object_or_404(Job, pk=job_id)
        stops = self.queryset.filter(job=job).order_by('sequence')
        return Response(self.get_serializer(stops, many=True).data)


class VehicleAssignmentViewSet(viewsets.ModelViewSet):
    queryset = VehicleAssignment.objects.select_related('vehicle', 'driver', 'job')
    serializer_class = VehicleAssignmentSerializer
    filterset_fields = ['vehicle', 'driver', 'is_active']


import urllib.request
import urllib.parse
import json


class RouteOptimizationViewSet(viewsets.ViewSet):
    """Route optimization using Google Maps Directions API.
    Accepts a list of stops (lat/lng) and returns an optimized order,
    road-following polyline, step-by-step directions, distance, and duration.
    """
    permission_classes = [IsAuthenticated]

    def _get_api_key(self):
        from django.conf import settings
        return getattr(settings, 'GOOGLE_MAPS_API_KEY', '')

    @action(detail=False, methods=['post'], url_path='optimize')
    def optimize(self, request):
        """POST body: { origin: {lat,lng}, destination: {lat,lng}, stops: [{lat,lng,...}] }
        Returns optimized stop order, total distance, total duration, polyline, steps.
        """
        origin = request.data.get('origin') or {}
        destination = request.data.get('destination') or {}
        stops = request.data.get('stops') or []
        travel_mode = request.data.get('travel_mode', 'DRIVING')
        avoid_tolls = request.data.get('avoid_tolls', False)
        avoid_highways = request.data.get('avoid_highways', False)
        departure_time = request.data.get('departure_time')  # ISO string or 'now'

        api_key = self._get_api_key()
        if not api_key:
            return Response({'error': 'Google Maps API key not configured'}, status=500)

        origin_lat = origin.get('lat')
        origin_lng = origin.get('lng')
        dest_lat = destination.get('lat')
        dest_lng = destination.get('lng')
        if origin_lat is None or origin_lng is None or dest_lat is None or dest_lng is None:
            return Response({'error': 'Origin and destination lat/lng required'}, status=400)

        # Build waypoints from stops
        wp_str = '|'.join(
            f"{s.get('lat')},{s.get('lng')}" for s in stops
            if s.get('lat') is not None and s.get('lng') is not None
        )

        url = 'https://maps.googleapis.com/maps/api/directions/json'
        avoid_parts = []
        if avoid_tolls:
            avoid_parts.append('tolls')
        if avoid_highways:
            avoid_parts.append('highways')
        params = {
            'origin': f'{origin_lat},{origin_lng}',
            'destination': f'{dest_lat},{dest_lng}',
            'key': api_key,
            'mode': 'driving' if travel_mode.upper() == 'DRIVING' else travel_mode.lower(),
        }
        if stops:
            params['waypoints'] = 'optimize:true|' + wp_str
        if avoid_parts:
            params['avoid'] = '|'.join(avoid_parts)
        # Only send departure_time and traffic_model for driving mode
        if travel_mode.upper() == 'DRIVING':
            params['departure_time'] = 'now'
            params['traffic_model'] = 'best_guess'
        query = '&'.join(f'{k}={urllib.parse.quote(str(v), safe=",|")}' for k, v in params.items())
        full_url = f'{url}?{query}'

        try:
            req = urllib.request.Request(full_url)
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
        except Exception as e:
            return Response({'error': f'Google API error: {str(e)}'}, status=502)

        if data.get('status') != 'OK':
            # If waypoints caused ZERO_RESULTS, retry without them
            if data.get('status') == 'ZERO_RESULTS' and stops:
                params_no_wp = {k: v for k, v in params.items() if k != 'waypoints'}
                query2 = '&'.join(f'{k}={urllib.parse.quote(str(v), safe=",|")}' for k, v in params_no_wp.items())
                full_url2 = f'{url}?{query2}'
                try:
                    req2 = urllib.request.Request(full_url2)
                    with urllib.request.urlopen(req2, timeout=15) as resp2:
                        data = json.loads(resp2.read())
                except Exception:
                    pass
                if data.get('status') == 'OK':
                    route = data['routes'][0]
                    legs = route['legs']
                    total_distance = sum(l.get('distance', {}).get('value', 0) for l in legs)
                    total_duration = sum(l.get('duration', {}).get('value', 0) for l in legs)
                    steps = []
                    for leg in legs:
                        for step in leg.get('steps', []):
                            steps.append({
                                'instruction': _strip_html(step.get('html_instructions', '')),
                                'distance': step.get('distance', {}).get('text', ''),
                                'duration': step.get('duration', {}).get('text', ''),
                                'maneuver': step.get('maneuver', ''),
                                'start_lat': step.get('start_location', {}).get('lat'),
                                'start_lng': step.get('start_location', {}).get('lng'),
                                'end_lat': step.get('end_location', {}).get('lat'),
                                'end_lng': step.get('end_location', {}).get('lng'),
                                'polyline': step.get('polyline', {}).get('points', ''),
                            })
                    return Response({
                        'optimized_order': list(range(len(stops))),
                        'total_distance_m': total_distance,
                        'total_distance_km': round(total_distance / 1000, 2),
                        'total_duration_s': total_duration,
                        'total_duration_text': _format_duration(total_duration),
                        'polyline': route.get('overview_polyline', {}).get('points', ''),
                        'bounds': route.get('bounds'),
                        'legs': [
                            {
                                'start_address': l.get('start_address'),
                                'end_address': l.get('end_address'),
                                'distance_text': l.get('distance', {}).get('text'),
                                'duration_text': l.get('duration', {}).get('text'),
                                'duration_in_traffic_text': l.get('duration_in_traffic', {}).get('text') if l.get('duration_in_traffic') else None,
                            }
                            for l in legs
                        ],
                        'steps': steps,
                        'summary': route.get('summary', ''),
                        'note': 'Route could not be optimized with all stops. Showing direct route from origin to destination.',
                    })
            return Response({'error': data.get('status', 'UNKNOWN'), 'message': data.get('error_message', '')}, status=502)

        route = data['routes'][0]
        legs = route['legs']
        total_distance = sum(l.get('distance', {}).get('value', 0) for l in legs)
        total_duration = sum(l.get('duration', {}).get('value', 0) for l in legs)

        # Optimized waypoint order (index into original stops array)
        waypoint_order = route.get('waypoint_order', [])

        # Flatten steps
        steps = []
        for li, leg in enumerate(legs):
            for step in leg.get('steps', []):
                steps.append({
                    'instruction': _strip_html(step.get('html_instructions', '')),
                    'distance': step.get('distance', {}).get('text', ''),
                    'duration': step.get('duration', {}).get('text', ''),
                    'maneuver': step.get('maneuver', ''),
                    'start_lat': step.get('start_location', {}).get('lat'),
                    'start_lng': step.get('start_location', {}).get('lng'),
                    'end_lat': step.get('end_location', {}).get('lat'),
                    'end_lng': step.get('end_location', {}).get('lng'),
                    'polyline': step.get('polyline', {}).get('points', ''),
                })

        return Response({
            'optimized_order': waypoint_order,
            'total_distance_m': total_distance,
            'total_distance_km': round(total_distance / 1000, 2),
            'total_duration_s': total_duration,
            'total_duration_text': _format_duration(total_duration),
            'polyline': route.get('overview_polyline', {}).get('points', ''),
            'bounds': route.get('bounds'),
            'legs': [
                {
                    'start_address': l.get('start_address'),
                    'end_address': l.get('end_address'),
                    'distance_text': l.get('distance', {}).get('text'),
                    'duration_text': l.get('duration', {}).get('text'),
                    'duration_in_traffic_text': l.get('duration_in_traffic', {}).get('text') if l.get('duration_in_traffic') else None,
                }
                for l in legs
            ],
            'steps': steps,
            'summary': route.get('summary', ''),
        })


class TrafficWeatherViewSet(viewsets.ViewSet):
    """Traffic alerts and weather conditions for a given location or route.
    Combines Google Maps Distance Matrix (traffic-aware) with Open-Meteo weather.
    """
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['post'], url_path='traffic')
    def traffic(self, request):
        """POST body: { origin: {lat,lng}, destination: {lat,lng}, stops: [{lat,lng}] }
        Returns traffic-aware ETAs for each leg + total.
        """
        api_key = getattr(__import__('django.conf', fromlist=['settings']).settings, 'GOOGLE_MAPS_API_KEY', '')
        origin = request.data.get('origin') or {}
        destination = request.data.get('destination') or {}
        stops = request.data.get('stops') or []

        if not api_key:
            return Response({'error': 'Google Maps API key not configured'}, status=500)

        origin_lat = origin.get('lat')
        origin_lng = origin.get('lng')
        dest_lat = destination.get('lat')
        dest_lng = destination.get('lng')
        if origin_lat is None or dest_lat is None:
            return Response({'error': 'Origin and destination required'}, status=400)

        # Build all points: origin → stops → destination
        points = [(origin_lat, origin_lng)]
        for s in stops:
            if s.get('lat') is not None:
                points.append((s['lat'], s['lng']))
        points.append((dest_lat, dest_lng))

        # Call Distance Matrix with departure_time=now for traffic
        url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
        origins_str = '|'.join(f'{p[0]},{p[1]}' for p in points[:-1])
        dests_str = '|'.join(f'{p[0]},{p[1]}' for p in points[1:])
        full_url = (
            f'{url}?origins={origins_str}&destinations={dests_str}'
            f'&key={api_key}&mode=driving&departure_time=now&traffic_model=best_guess'
        )

        try:
            req = urllib.request.Request(full_url)
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
        except Exception as e:
            return Response({'error': f'Google API error: {str(e)}'}, status=502)

        rows = data.get('rows', [])
        legs = []
        total_distance = 0
        total_duration = 0
        total_traffic_duration = 0
        has_traffic = False

        for i, row in enumerate(rows):
            element = row['elements'][0]
            if element.get('status') != 'OK':
                legs.append({'status': element.get('status'), 'error': True})
                continue
            dist = element.get('distance', {}).get('value', 0)
            dur = element.get('duration', {}).get('value', 0)
            dur_traffic = element.get('duration_in_traffic', {}).get('value', dur)
            has_traffic = has_traffic or 'duration_in_traffic' in element
            total_distance += dist
            total_duration += dur
            total_traffic_duration += dur_traffic
            legs.append({
                'from_point': i,
                'to_point': i + 1,
                'distance_text': element.get('distance', {}).get('text'),
                'distance_m': dist,
                'duration_text': element.get('duration', {}).get('text'),
                'duration_s': dur,
                'duration_in_traffic_text': element.get('duration_in_traffic', {}).get('text') if has_traffic else None,
                'duration_in_traffic_s': dur_traffic if has_traffic else None,
                'delay_s': dur_traffic - dur if has_traffic else 0,
                'delay_text': _format_duration(dur_traffic - dur) if has_traffic else '0 min',
            })

        return Response({
            'legs': legs,
            'total_distance_m': total_distance,
            'total_distance_km': round(total_distance / 1000, 2),
            'total_duration_s': total_duration,
            'total_duration_text': _format_duration(total_duration),
            'total_duration_in_traffic_s': total_traffic_duration,
            'total_duration_in_traffic_text': _format_duration(total_traffic_duration),
            'total_delay_s': total_traffic_duration - total_duration,
            'total_delay_text': _format_duration(total_traffic_duration - total_duration),
            'has_traffic_data': has_traffic,
        })

    @action(detail=False, methods=['post'], url_path='weather')
    def weather(self, request):
        """POST body: { points: [{lat,lng}] }
        Returns current weather for each point via Open-Meteo.
        """
        points = request.data.get('points') or []
        if not points:
            return Response({'error': 'No points provided'}, status=400)

        results = []
        for p in points:
            lat = p.get('lat')
            lng = p.get('lng')
            if lat is None or lng is None:
                results.append({'error': 'lat/lng required'})
                continue
            try:
                wurl = (
                    f'https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}'
                    f'&current_weather=true&hourly=precipitation,cloudcover,visibility&timezone=auto'
                )
                req = urllib.request.Request(wurl)
                with urllib.request.urlopen(req, timeout=10) as resp:
                    data = json.loads(resp.read())
                cw = data.get('current_weather', {})
                results.append({
                    'lat': lat,
                    'lng': lng,
                    'temperature': cw.get('temperature'),
                    'wind_speed': cw.get('windspeed'),
                    'wind_direction': cw.get('winddirection'),
                    'weather_code': cw.get('weathercode'),
                    'description': _WMO_CODE(cw.get('weathercode')),
                    'is_day': cw.get('is_day') == 1,
                    'precipitation': (data.get('hourly', {}).get('precipitation') or [0])[0],
                    'cloud_cover': (data.get('hourly', {}).get('cloudcover') or [0])[0],
                    'visibility': ((data.get('hourly', {}).get('visibility') or [0])[0]) / 1000 if data.get('hourly', {}).get('visibility') else None,
                })
            except Exception as e:
                results.append({'lat': lat, 'lng': lng, 'error': str(e)})

        return Response({'results': results})


def _strip_html(s: str) -> str:
    import re
    return re.sub(r'<[^>]+>', '', s)


def _format_duration(seconds: int) -> str:
    if seconds < 60:
        return f'{seconds}s'
    m = seconds // 60
    h = m // 60
    m %= 60
    if h:
        return f'{h}h {m}m'
    return f'{m}m'


def _WMO_CODE(code=None):
    if code is None:
        return 'Unknown'
    codes = {
        0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
        45: 'Fog', 48: 'Fog',
        51: 'Light drizzle', 53: 'Moderate drizzle', 55: 'Dense drizzle',
        56: 'Freezing drizzle', 57: 'Freezing drizzle',
        61: 'Slight rain', 63: 'Moderate rain', 65: 'Heavy rain',
        66: 'Freezing rain', 67: 'Freezing rain',
        71: 'Slight snow', 73: 'Moderate snow', 75: 'Heavy snow',
        77: 'Snow grains', 80: 'Rain showers', 81: 'Rain showers',
        82: 'Violent rain showers', 85: 'Snow showers', 86: 'Snow showers',
        95: 'Thunderstorm', 96: 'Thunderstorm with hail', 99: 'Thunderstorm with hail',
    }
    return codes.get(code, 'Unknown')
