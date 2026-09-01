from datetime import timedelta

from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import BayReservation, GarageBay
from .serializers import BayReservationSerializer, GarageBaySerializer


class GarageBayViewSet(viewsets.ModelViewSet):
    queryset = GarageBay.objects.all()
    serializer_class = GarageBaySerializer
    filterset_fields = ['bay_type', 'is_active']
    search_fields = ['name']

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate garage statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        active = qs.filter(is_active=True).count()
        occupied = sum(1 for b in qs if b.is_occupied)
        available = total - occupied

        by_type = {}
        for choice in GarageBay.BayType.choices:
            by_type[choice[0]] = qs.filter(bay_type=choice[0]).count()

        return Response({
            'total': total,
            'active': active,
            'occupied': occupied,
            'available': available,
            'by_type': by_type,
        })


class BayReservationViewSet(viewsets.ModelViewSet):
    queryset = BayReservation.objects.select_related('bay', 'vehicle', 'work_order')
    serializer_class = BayReservationSerializer
    filterset_fields = ['bay', 'vehicle', 'status']
    ordering_fields = ['start_time', 'end_time']

    @action(detail=False, methods=['get'])
    def schedule(self, request):
        start = request.query_params.get('start')
        end = request.query_params.get('end')
        qs = self.get_queryset()
        if start:
            qs = qs.filter(end_time__gte=start)
        if end:
            qs = qs.filter(start_time__lte=end)
        return Response(BayReservationSerializer(qs, many=True).data)

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate reservation statistics for analytics cards."""
        qs = self.get_queryset()
        now = timezone.now()
        total = qs.count()
        active = qs.filter(status='active').count()
        scheduled = qs.filter(status='scheduled').count()
        completed = qs.filter(status='completed').count()
        cancelled = qs.filter(status='cancelled').count()

        bay_qs = GarageBay.objects.all()
        by_bay = []
        for bay in bay_qs:
            bay_res = qs.filter(bay=bay)
            by_bay.append({
                'bay_name': bay.name,
                'bay_type': bay.bay_type,
                'count': bay_res.count(),
                'active': bay_res.filter(status='active').count(),
            })

        # next 7 days reservations
        upcoming = qs.filter(
            start_time__gte=now,
            start_time__lte=now + timedelta(days=7),
            status__in=['scheduled', 'active'],
        ).count()

        return Response({
            'total': total,
            'active': active,
            'scheduled': scheduled,
            'completed': completed,
            'cancelled': cancelled,
            'upcoming': upcoming,
            'by_bay': by_bay,
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo garage bays and reservations for the current tenant."""
        import random

        from apps.vehicles.models import Vehicle

        vehicles = list(Vehicle.objects.all()[:10])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        bay_templates = [
            ('Bay 1 - Lift A', 'lift'),
            ('Bay 2 - Lift B', 'lift'),
            ('Bay 3 - Flat', 'flat'),
            ('Bay 4 - Paint', 'paint'),
            ('Bay 5 - Wash', 'wash'),
            ('Bay 6 - Inspection', 'inspection'),
            ('Bay 7 - General', 'general'),
            ('Bay 8 - Lift C', 'lift'),
        ]

        created_bays = 0
        bays = []
        for name, btype in bay_templates:
            bay, created = GarageBay.objects.get_or_create(
                name=name,
                defaults={'bay_type': btype, 'capacity': random.choice([1, 1, 2]), 'is_active': True},
            )
            bays.append(bay)
            if created:
                created_bays += 1

        statuses = ['scheduled', 'active', 'completed', 'completed', 'cancelled']
        now = timezone.now()
        created_res = 0
        existing = set(BayReservation.objects.values_list('bay_id', 'vehicle_id', 'start_time'))

        for _ in range(24):
            bay = random.choice(bays)
            vehicle = random.choice(vehicles)
            duration_hrs = random.choice([1, 2, 3, 4, 6, 8])
            # spread over last 14 to next 14 days
            offset_days = random.randint(-14, 10)
            offset_hours = random.randint(0, 12)
            start = now + timedelta(days=offset_days, hours=offset_hours)
            end = start + timedelta(hours=duration_hrs)

            if (bay.id, vehicle.id, start) in existing:
                continue

            # Determine status based on time relation
            if end < now:
                status = random.choice(['completed', 'completed', 'cancelled'])
            elif start <= now <= end:
                status = 'active'
            else:
                status = random.choice(['scheduled', 'scheduled', 'active'])

            BayReservation.objects.create(
                bay=bay,
                vehicle=vehicle,
                start_time=start,
                end_time=end,
                status=status,
                notes=random.choice([
                    'Oil change service.',
                    'Brake pad replacement.',
                    'Tire rotation and balancing.',
                    'Engine diagnostic.',
                    'Annual inspection.',
                    'Body repair and paint.',
                    'Wash and detail.',
                    '',
                ]),
            )
            created_res += 1

        return Response({'detail': f'Seeded {created_bays} bays and {created_res} reservations.'})
