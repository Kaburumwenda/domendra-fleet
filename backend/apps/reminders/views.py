import random
from datetime import timedelta

from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Reminder
from .serializers import ReminderSerializer


class ReminderViewSet(viewsets.ModelViewSet):
    queryset = Reminder.objects.select_related('vehicle')
    serializer_class = ReminderSerializer
    filterset_fields = ['vehicle', 'trigger_type', 'is_active']
    search_fields = ['title']
    ordering_fields = ['next_due_date', 'created_at']

    @action(detail=False, methods=['get'])
    def due(self, request):
        qs = self.filter_queryset(self.get_queryset())
        due = [r for r in qs if r.is_due]
        overdue = [r for r in due if r.is_overdue]
        return Response({
            'due_count': len(due),
            'overdue_count': len(overdue),
            'items': ReminderSerializer(due, many=True).data,
        })

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate reminder statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        active = qs.filter(is_active=True).count()
        due_list = [r for r in qs if r.is_due]
        overdue_list = [r for r in due_list if r.is_overdue]
        by_trigger = {}
        for choice in Reminder.TriggerType.choices:
            by_trigger[choice[0]] = qs.filter(trigger_type=choice[0]).count()
        by_escalation = {}
        for choice in Reminder.EscalationLevel.choices:
            by_escalation[str(choice[0])] = qs.filter(escalation_level=choice[0]).count()
        by_vehicle = {}
        for r in qs:
            vid = r.vehicle_id
            if vid not in by_vehicle:
                by_vehicle[vid] = {'vehicle_name': r.vehicle.display_name, 'count': 0, 'due': 0}
            by_vehicle[vid]['count'] += 1
            if r.is_due:
                by_vehicle[vid]['due'] += 1
        return Response({
            'total': total,
            'active': active,
            'inactive': total - active,
            'due_count': len(due_list),
            'overdue_count': len(overdue_list),
            'auto_generate_count': qs.filter(auto_generate_work_order=True).count(),
            'by_trigger_type': by_trigger,
            'by_escalation': by_escalation,
            'by_vehicle': list(by_vehicle.values()),
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo reminders for the current tenant."""
        from apps.vehicles.models import Vehicle

        vehicles = list(Vehicle.objects.all()[:10])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        existing = set(qs for qs in Reminder.objects.values_list('vehicle_id', 'title'))

        templates = [
            ('Oil Change', 'time', 6, None, None, None),
            ('Tire Rotation', 'mileage', 8000, None, 8000, None),
            ('Brake Inspection', 'mileage', 12000, None, 12000, None),
            ('Annual Safety Inspection', 'time', 12, None, None, None),
            ('Coolant Flush', 'time', 24, None, None, None),
            ('Transmission Service', 'mileage', 30000, None, 30000, None),
            ('Air Filter Replacement', 'time', 12, None, None, None),
            ('Battery Health Check', 'time', 6, None, None, None),
            ('DPF Cleaning', 'engine_hours', 500, None, None, 500),
            ('Wheel Alignment', 'time', 12, None, None, None),
            ('Cabin Air Filter', 'time', 12, None, None, None),
            ('Fuel Filter Replacement', 'mileage', 15000, None, 15000, None),
            ('Spark Plug Replacement', 'mileage', 30000, None, 30000, None),
            ('Serpentine Belt Inspection', 'time', 12, None, None, None),
            ('Glow Plug Check', 'engine_hours', 1000, None, None, 1000),
        ]

        now = timezone.now()
        created = 0
        for v in vehicles:
            picks = random.sample(templates, min(random.randint(3, 5), len(templates)))
            for title, trig, interval, _, next_mileage, next_hours in picks:
                if (v.id, title) in existing:
                    continue
                past = random.random() < 0.3
                if trig == 'time':
                    nd = (now + timedelta(days=random.randint(-20, 90))).date() if not past else (now - timedelta(days=random.randint(1, 30))).date()
                    Reminder.objects.create(
                        vehicle=v, title=title, trigger_type=trig, trigger_interval=interval,
                        next_due_date=nd,
                        escalation_level=random.choice([0, 0, 1, 2, 3]),
                        auto_generate_work_order=random.choice([True, False]),
                        is_active=True,
                    )
                elif trig == 'mileage':
                    base_mile = getattr(v, 'current_mileage', 0) or random.randint(20000, 120000)
                    nd_mile = base_mile + random.randint(interval // 2, interval) if not past else base_mile - random.randint(100, 2000)
                    Reminder.objects.create(
                        vehicle=v, title=title, trigger_type=trig, trigger_interval=interval,
                        next_due_mileage=nd_mile,
                        escalation_level=random.choice([0, 0, 1, 2]),
                        auto_generate_work_order=random.choice([True, False]),
                        is_active=True,
                    )
                else:
                    base_hours = getattr(v, 'engine_hours', 0) or random.randint(500, 5000)
                    nd_hours = base_hours + random.randint(100, 500) if not past else base_hours - random.randint(10, 100)
                    Reminder.objects.create(
                        vehicle=v, title=title, trigger_type=trig, trigger_interval=interval,
                        next_due_engine_hours=nd_hours,
                        escalation_level=random.choice([0, 0, 1, 3]),
                        auto_generate_work_order=True,
                        is_active=True,
                    )
                created += 1

        return Response({'detail': f'Seeded {created} reminders across {len(vehicles)} vehicles.'})
