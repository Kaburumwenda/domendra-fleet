import random
from datetime import timedelta

from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Recall, RecallVehicle
from .serializers import RecallSerializer, RecallVehicleSerializer


class RecallViewSet(viewsets.ModelViewSet):
    queryset = Recall.objects.prefetch_related('vehicles')
    serializer_class = RecallSerializer
    filterset_fields = ['status', 'recall_type', 'is_critical', 'oem']
    search_fields = ['title', 'nhtsa_campaign_number', 'manufacturer_campaign_number', 'component', 'oem']
    ordering_fields = ['issue_date', 'created_at']

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate recall statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        by_status = {}
        for choice in Recall.Status.choices:
            by_status[choice[0]] = qs.filter(status=choice[0]).count()
        by_type = {}
        for choice in Recall.RecallType.choices:
            by_type[choice[0]] = qs.filter(recall_type=choice[0]).count()
        critical = qs.filter(is_critical=True).count()
        affected_total = RecallVehicle.objects.count()
        resolved_total = RecallVehicle.objects.filter(status=RecallVehicle.ResolutionStatus.RESOLVED).count()
        by_vehicle = {}
        for rv in RecallVehicle.objects.select_related('vehicle', 'recall'):
            vid = rv.vehicle_id
            if vid not in by_vehicle:
                by_vehicle[vid] = {'vehicle_name': rv.vehicle.display_name, 'total': 0, 'resolved': 0, 'critical': 0}
            by_vehicle[vid]['total'] += 1
            if rv.status == RecallVehicle.ResolutionStatus.RESOLVED:
                by_vehicle[vid]['resolved'] += 1
            if rv.recall.is_critical:
                by_vehicle[vid]['critical'] += 1
        return Response({
            'total': total,
            'critical': critical,
            'by_status': by_status,
            'by_type': by_type,
            'affected_vehicles': affected_total,
            'resolved_vehicles': resolved_total,
            'resolution_rate': round(resolved_total / affected_total * 100, 1) if affected_total else 0,
            'by_vehicle': list(by_vehicle.values())[:20],
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo recalls and affected vehicles for the current tenant."""
        from apps.vehicles.models import Vehicle

        vehicles = list(Vehicle.objects.all()[:15])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        now = timezone.now()

        templates = [
            {
                'title': 'Airbag Inflator Rupture Risk',
                'recall_type': 'safety_recall',
                'nhtsa': '23V-401', 'oem': 'Toyota', 'component': 'Airbag',
                'description': 'Driver airbag inflator may rupture during deployment, propelling metal fragments.',
                'remedy': 'Replace driver airbag inflator with updated propellant design.',
                'risk': 'Inflator rupture can cause serious injury or death.',
                'is_critical': True,
            },
            {
                'title': 'Brake Master Cylinder Leak',
                'recall_type': 'safety_recall',
                'nhtsa': '23V-552', 'oem': 'Ford', 'component': 'Brakes',
                'description': 'Brake master cylinder may leak fluid, reducing braking performance.',
                'remedy': 'Replace brake master cylinder and flush system.',
                'risk': 'Extended stopping distance increases crash risk.',
                'is_critical': True,
            },
            {
                'title': 'Fuel Pump Impeller Failure',
                'recall_type': 'safety_recall',
                'nhtsa': '22V-877', 'oem': 'Honda', 'component': 'Fuel System',
                'description': 'Fuel pump impeller may deform, causing engine stall.',
                'remedy': 'Replace low-pressure fuel pump.',
                'risk': 'Engine stall while driving increases crash risk.',
                'is_critical': True,
            },
            {
                'title': 'Transmission Control Unit Software Update',
                'recall_type': 'campaign',
                'nhtsa': '23V-123', 'oem': 'Chevrolet', 'component': 'Transmission',
                'description': 'TCU software may cause hesitation during gear changes under certain conditions.',
                'remedy': 'Reflash TCU with updated software.',
                'risk': 'Unintended gear disengagement may occur.',
                'is_critical': False,
            },
            {
                'title': 'Rear Suspension Toe Link Corrosion',
                'recall_type': 'safety_recall',
                'nhtsa': '22V-309', 'oem': 'Toyota', 'component': 'Suspension',
                'description': 'Rear toe link may corrode and separate, affecting vehicle handling.',
                'remedy': 'Inspect and replace rear toe links as needed.',
                'risk': 'Loss of vehicle control increases crash risk.',
                'is_critical': True,
            },
            {
                'title': 'Battery Junction Box Overheating',
                'recall_type': 'field_notice',
                'nhtsa': '', 'oem': 'Tesla', 'component': 'Electrical System',
                'description': 'Battery junction box may overheat during high-current charging.',
                'remedy': 'Replace junction box and apply thermal pad.',
                'risk': 'Overheating may cause thermal event.',
                'is_critical': False,
            },
            {
                'title': 'NOx Sensor Calibration Error',
                'recall_type': 'emission',
                'nhtsa': '23V-789', 'oem': 'Freightliner', 'component': 'Emissions',
                'description': 'NOx sensor may report inaccurate readings leading to excess emissions.',
                'remedy': 'Replace NOx sensor and recalibrate ECU.',
                'risk': 'Exceeds emission standards; no safety risk.',
                'is_critical': False,
            },
            {
                'title': 'Windshield Wiper Motor Failure',
                'recall_type': 'safety_recall',
                'nhtsa': '23V-210', 'oem': 'Ford', 'component': 'Wipers',
                'description': 'Wiper motor may fail due to water ingress, reducing visibility.',
                'remedy': 'Replace wiper motor assembly.',
                'risk': 'Reduced visibility in adverse weather.',
                'is_critical': False,
            },
            {
                'title': 'Seatbelt Pretensioner Deployment',
                'recall_type': 'safety_recall',
                'nhtsa': '23V-456', 'oem': 'Honda', 'component': 'Seatbelts',
                'description': 'Seatbelt pretensioner may not deploy correctly during a crash.',
                'remedy': 'Replace seatbelt pretensioner assembly.',
                'risk': 'Reduced restraint effectiveness in a crash.',
                'is_critical': True,
            },
            {
                'title': 'Coolant Pump Bearing Wear',
                'recall_type': 'campaign',
                'nhtsa': '23V-321', 'oem': 'Chevrolet', 'component': 'Engine Cooling',
                'description': 'Coolant pump bearing may wear prematurely causing coolant leak.',
                'remedy': 'Replace coolant pump and inspect seals.',
                'risk': 'Engine overheating may occur if unaddressed.',
                'is_critical': False,
            },
        ]

        statuses = ['open', 'in_progress', 'completed', 'closed']
        res_statuses = ['affected', 'scheduled', 'in_progress', 'resolved', 'not_affected']
        created = 0

        for i, tpl in enumerate(templates):
            issue = now - timedelta(days=random.randint(10, 120))
            recall = Recall.objects.create(
                title=tpl['title'],
                recall_type=tpl['recall_type'],
                nhtsa_campaign_number=tpl['nhtsa'],
                manufacturer_campaign_number=f'MFR-{1000+i}',
                oem=tpl['oem'],
                component=tpl['component'],
                description=tpl['description'],
                remedy=tpl['remedy'],
                risk=tpl['risk'],
                issue_date=issue.date(),
                status=random.choice(statuses),
                is_critical=tpl['is_critical'],
                affected_make=tpl['oem'],
                affected_models='',
            )
            count = random.randint(1, min(4, len(vehicles)))
            picked = random.sample(vehicles, count)
            for v in picked:
                rv_status = random.choice(res_statuses)
                days_ago = random.randint(0, 30)
                resolved_at = (now - timedelta(days=days_ago)).date() if rv_status == 'resolved' else None
                scheduled_date = (now + timedelta(days=random.randint(1, 30))).date() if rv_status == 'scheduled' else None
                RecallVehicle.objects.create(
                    recall=recall, vehicle=v, status=rv_status,
                    resolved_at=resolved_at, scheduled_date=scheduled_date,
                    notes='',
                )
            created += 1

        return Response({'detail': f'Seeded {created} recalls with affected vehicles.'})

    @action(detail=True, methods=['post'])
    def apply_to_vehicles(self, request, pk=None):
        """Attach a recall to a list of vehicle IDs."""
        recall = self.get_object()
        vehicle_ids = request.data.get('vehicle_ids', [])
        if not vehicle_ids:
            return Response({'detail': 'vehicle_ids list required.'}, status=status.HTTP_400_BAD_REQUEST)
        created = []
        for vid in vehicle_ids:
            obj, created_flag = RecallVehicle.objects.get_or_create(
                recall=recall, vehicle_id=vid,
                defaults={'status': RecallVehicle.ResolutionStatus.AFFECTED},
            )
            created.append(RecallVehicleSerializer(obj).data)
        return Response(created, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def auto_match(self, request, pk=None):
        """Auto-match affected vehicles based on make/model/year criteria."""
        recall = self.get_object()
        from apps.vehicles.models import Vehicle
        qs = Vehicle.objects.all()
        if recall.affected_make:
            qs = qs.filter(make__iexact=recall.affected_make)
        models = [m.strip() for m in recall.affected_models.split(',') if m.strip()]
        if models:
            qs = qs.filter(model__in=models)
        if recall.affected_year_from:
            qs = qs.filter(year__gte=recall.affected_year_from)
        if recall.affected_year_to:
            qs = qs.filter(year__lte=recall.affected_year_to)
        matched = []
        for v in qs:
            obj, _ = RecallVehicle.objects.get_or_create(
                recall=recall, vehicle=v,
                defaults={'status': RecallVehicle.ResolutionStatus.AFFECTED},
            )
            matched.append(RecallVehicleSerializer(obj).data)
        return Response(matched)


class RecallVehicleViewSet(viewsets.ModelViewSet):
    queryset = RecallVehicle.objects.select_related('recall', 'vehicle', 'work_order')
    serializer_class = RecallVehicleSerializer
    filterset_fields = ['recall', 'vehicle', 'status']
    ordering_fields = ['created_at', 'scheduled_date', 'resolved_at']

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        rv = self.get_object()
        rv.status = RecallVehicle.ResolutionStatus.RESOLVED
        rv.resolved_at = request.data.get('resolved_at') or rv.resolved_at
        rv.save(update_fields=['status', 'resolved_at', 'updated_at'])
        return Response(RecallVehicleSerializer(rv).data)
