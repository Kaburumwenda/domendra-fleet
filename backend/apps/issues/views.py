import random
from datetime import timedelta

from django.db.models import Count, Q, Sum
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Issue, IssuePhoto, PartUsage, TimeLog, WorkOrder, WorkOrderNote
from .serializers import (
    IssuePhotoSerializer,
    IssueSerializer,
    PartUsageSerializer,
    TimeLogSerializer,
    WorkOrderCreateSerializer,
    WorkOrderNoteSerializer,
    WorkOrderSerializer,
)


class IssueViewSet(viewsets.ModelViewSet):
    queryset = Issue.objects.select_related('vehicle', 'reported_by', 'work_order')
    serializer_class = IssueSerializer
    filterset_fields = ['status', 'priority', 'vehicle', 'reported_by']
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'updated_at', 'priority']

    @action(detail=True, methods=['post'])
    def create_work_order(self, request, pk=None):
        issue = self.get_object()
        if hasattr(issue, 'work_order'):
            return Response({'detail': 'Work order already exists'}, status=status.HTTP_400_BAD_REQUEST)
        wo = WorkOrder.objects.create(issue=issue, status=WorkOrder.Status.ASSIGNED)
        issue.status = Issue.Status.ASSIGNED
        issue.save(update_fields=['status'])
        return Response(WorkOrderSerializer(wo).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def assign(self, request, pk=None):
        """Assign the issue to a mechanic/work order and update status."""
        issue = self.get_object()
        mechanic_id = request.data.get('mechanic')
        assignment_type = request.data.get('assignment_type', 'internal')
        estimated_cost = request.data.get('estimated_cost', 0)
        # Create or update work order
        if hasattr(issue, 'work_order'):
            wo = issue.work_order
            if mechanic_id:
                wo.assigned_to_id = mechanic_id
            wo.assignment_type = assignment_type
            if estimated_cost:
                wo.estimated_cost = estimated_cost
            wo.save()
        else:
            wo = WorkOrder.objects.create(
                issue=issue,
                assigned_to_id=mechanic_id,
                assignment_type=assignment_type,
                estimated_cost=estimated_cost or 0,
                status=WorkOrder.Status.ASSIGNED,
            )
        issue.status = Issue.Status.ASSIGNED
        issue.save(update_fields=['status'])
        return Response(WorkOrderSerializer(wo).data)

    @action(detail=False, methods=['post'])
    def bulk_update_status(self, request, *args, **kwargs):
        """Bulk update status for multiple issues at once."""
        ids = request.data.get('ids', [])
        new_status = request.data.get('status')
        if not ids or not new_status:
            return Response({'detail': 'ids and status are required'}, status=status.HTTP_400_BAD_REQUEST)
        valid = [c[0] for c in Issue.Status.choices]
        if new_status not in valid:
            return Response({'detail': f'Invalid status. Must be one of {valid}'}, status=status.HTTP_400_BAD_REQUEST)
        updated = Issue.objects.filter(id__in=ids).update(status=new_status)
        return Response({'detail': f'Updated {updated} issue(s) to {new_status}'})

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate issue statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        by_status = {c[0]: 0 for c in Issue.Status.choices}
        by_priority = {c[0]: 0 for c in Issue.Priority.choices}
        wo_count = 0
        for i in qs:
            by_status[i.status] = by_status.get(i.status, 0) + 1
            by_priority[i.priority] = by_priority.get(i.priority, 0) + 1
            if i.has_work_order:
                wo_count += 1
        open_critical = qs.filter(priority='critical').exclude(status='closed').count()
        avg_resolve_hours = None
        resolved = qs.filter(status__in=['resolved', 'closed'])
        resolve_diffs = []
        for i in resolved:
            if i.updated_at and i.created_at:
                resolve_diffs.append((i.updated_at - i.created_at).total_seconds() / 3600)
        if resolve_diffs:
            avg_resolve_hours = round(sum(resolve_diffs) / len(resolve_diffs), 1)
        return Response({
            'total': total,
            'by_status': by_status,
            'by_priority': by_priority,
            'work_orders': wo_count,
            'open_critical': open_critical,
            'avg_resolve_hours': avg_resolve_hours,
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo issue records and work orders for the current tenant."""
        from apps.vehicles.models import Vehicle
        from apps.users.models import User
        from apps.contacts.models import Contact

        vehicles = list(Vehicle.objects.all()[:10])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        users = list(User.objects.all()[:3])
        mechanics = list(Contact.objects.filter(contact_type='mechanic')[:5])
        if not mechanics:
            mech_data = [
                ('Joe', 'Martinez'), ('Sarah', 'Chen'), ('Mike', 'OBrien'),
                ('Diana', 'Lopez'), ('Tom', 'Reyes'),
            ]
            for fn, ln in mech_data:
                Contact.objects.create(
                    contact_type='mechanic', first_name=fn, last_name=ln,
                    phone='555-0200', is_active=True,
                )
            mechanics = list(Contact.objects.filter(contact_type='mechanic')[:5])

        titles = [
            ('Engine overheating on highway', 'Vehicle temperature gauge spiked above normal during highway operation. Pulling over and shutting down. Possible coolant leak or thermostat failure.', 'high'),
            ('Brake squeal when cold', 'Brake pads squeal audibly during first stops of the day when brakes are cold. Stops after warming up.', 'medium'),
            ('Check engine light - P0301', 'Cylinder 1 misfire detected. Rough idle and slight power loss under load. Spark plug or coil pack suspected.', 'high'),
            ('ABS warning light intermittent', 'ABS warning lamp illuminates intermittently while driving. Clears on restart. Possible wheel speed sensor issue.', 'medium'),
            ('Transmission slipping in reverse', 'Transmission hesitates and slips when shifting into reverse. Fluid level normal, slight burnt smell.', 'critical'),
            ('AC blowing warm air', 'Air conditioning system not cooling. Compressor clutch engages but no cold air output. Possible refrigerant leak.', 'low'),
            ('Suspension clunk over bumps', 'Audible clunking from front suspension over bumps and rough roads. Possible worn ball joints or control arm bushings.', 'medium'),
            ('Headlight out - driver side', 'Driver side headlight not working. Bulb replacement attempted but still dark. Possible wiring or socket corrosion.', 'low'),
            ('DOT inspection failure - tires', 'Failed DOT inspection due to tire tread depth below 4/32 on steer axle tires. Must replace before return to service.', 'critical'),
            ('Fuel gauge inaccurate', 'Fuel gauge reads empty when tank is at least half full. Sending unit or gauge cluster suspected.', 'low'),
            ('Exhaust leak under cab', 'Exhaust fumes entering cab under acceleration. Visible soot at flex pipe joint. Requires immediate repair.', 'high'),
            ('Power steering whine', 'Power steering pump makes whining noise when turning at low speed. Fluid level normal but dark and contaminated.', 'medium'),
            ('Wiring harness abrasion', 'Wiring harness near frame rail shows signs of abrasion from rubbing against chassis. Intermittent electrical faults.', 'high'),
            ('Clutch pedal soft', 'Clutch pedal feels soft and spongy. Engages very near the floor. Hydraulic leak suspected at slave cylinder.', 'medium'),
            ('Radiator coolant leak', 'Visible coolant drip from radiator bottom tank. Coolant level dropping over 2 days. Pressure test needed.', 'high'),
        ]

        statuses = ['open', 'open', 'open', 'assigned', 'assigned', 'in_progress',
                     'in_progress', 'parts_ordered', 'resolved', 'resolved', 'closed']
        priorities = ['low', 'low', 'medium', 'medium', 'medium', 'high', 'high', 'critical']

        now = timezone.now()
        created = 0
        wo_count = 0
        for i in range(22):
            vw = random.choice(vehicles)
            title, desc, prio = random.choice(titles)
            st = random.choice(statuses)
            has_wo = st in ('assigned', 'in_progress', 'parts_ordered', 'resolved', 'closed') or random.random() > 0.4
            issue = Issue.objects.create(
                vehicle=vw,
                title=title,
                description=desc,
                status=st,
                priority=prio if random.random() > 0.3 else random.choice(priorities),
                reported_by=random.choice(users) if users and random.random() > 0.3 else None,
                created_at=now - timedelta(days=random.randint(0, 60), hours=random.randint(0, 12)),
            )
            created += 1

            if has_wo:
                mech = random.choice(mechanics) if mechanics and random.random() > 0.2 else None
                wo_status = {
                    'open': WorkOrder.Status.OPEN,
                    'assigned': WorkOrder.Status.ASSIGNED,
                    'in_progress': WorkOrder.Status.IN_PROGRESS,
                    'parts_ordered': WorkOrder.Status.PARTS_ORDERED,
                    'resolved': WorkOrder.Status.COMPLETED,
                    'closed': WorkOrder.Status.CLOSED,
                }.get(st, WorkOrder.Status.OPEN)
                wo = WorkOrder.objects.create(
                    issue=issue,
                    assigned_to=mech,
                    assignment_type=random.choice(['internal', 'external']),
                    status=wo_status,
                    estimated_cost=round(random.uniform(50, 2500), 2),
                    actual_cost=round(random.uniform(0, 2000), 2) if st in ('resolved', 'closed') else 0,
                    parts_cost=round(random.uniform(0, 800), 2) if st in ('resolved', 'closed') or random.random() > 0.7 else 0,
                    labor_cost=round(random.uniform(0, 1200), 2) if st in ('resolved', 'closed') else 0,
                    downtime_hours=round(random.uniform(0, 48), 1) if st in ('resolved', 'closed', 'in_progress') else round(random.uniform(0, 8), 1),
                )
                wo_count += 1

                num_notes = random.randint(0, 3)
                for j in range(num_notes):
                    author = random.choice(users) if users and random.random() > 0.3 else None
                    WorkOrderNote.objects.create(
                        work_order=wo,
                        author=author,
                        visibility=random.choice(['internal', 'external']),
                        content=random.choice([
                            'Inspected vehicle, confirmed the issue. Starting diag.',
                            'Ordered replacement parts, ETA 3 business days.',
                            'Parts arrived, proceeding with repair.',
                            'Repair completed, test drove vehicle. All good.',
                            'Waiting on customer approval for additional work.',
                            'Found additional wear on related component, recommending replacement.',
                        ]),
                    )

        return Response({'detail': f'Seeded {created} issues with {wo_count} work orders and notes.'})


class WorkOrderViewSet(viewsets.ModelViewSet):
    queryset = WorkOrder.objects.select_related(
        'issue', 'issue__vehicle', 'assigned_to',
    ).prefetch_related('notes', 'time_logs', 'parts_used')

    def get_serializer_class(self):
        if self.action in ('create',):
            return WorkOrderCreateSerializer
        return WorkOrderSerializer

    filterset_fields = ['status', 'assignment_type', 'assigned_to']
    search_fields = ['issue__title', 'internal_notes', 'external_notes']
    ordering_fields = ['created_at', 'estimated_cost', 'completed_at']

    @action(detail=True, methods=['post'])
    def clock_in(self, request, pk=None):
        wo = self.get_object()
        log = TimeLog.objects.create(
            work_order=wo, clock_in=timezone.now(),
            mechanic_id=request.data.get('mechanic'),
        )
        return Response(TimeLogSerializer(log).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def clock_out(self, request, pk=None):
        wo = self.get_object()
        log = wo.time_logs.filter(clock_out__isnull=True).order_by('-clock_in').first()
        if not log:
            return Response({'detail': 'No active time log'}, status=status.HTTP_400_BAD_REQUEST)
        log.clock_out = timezone.now()
        log.save()
        return Response(TimeLogSerializer(log).data)

    @action(detail=True, methods=['post'])
    def add_note(self, request, pk=None):
        wo = self.get_object()
        serializer = WorkOrderNoteSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save(work_order=wo)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def add_part(self, request, pk=None):
        wo = self.get_object()
        serializer = PartUsageSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(work_order=wo)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        wo = self.get_object()
        wo.status = WorkOrder.Status.COMPLETED
        wo.completed_at = timezone.now()
        wo.save(update_fields=['status', 'completed_at'])
        wo.issue.status = 'resolved'
        wo.issue.save(update_fields=['status'])
        return Response(WorkOrderSerializer(wo).data)

    @action(detail=True, methods=['post'])
    def start_work(self, request, pk=None):
        """Mark a work order as in-progress and set started_at."""
        wo = self.get_object()
        wo.status = WorkOrder.Status.IN_PROGRESS
        if not wo.started_at:
            wo.started_at = timezone.now()
        wo.save(update_fields=['status', 'started_at'])
        wo.issue.status = 'in_progress'
        wo.issue.save(update_fields=['status'])
        return Response(WorkOrderSerializer(wo).data)

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate work order statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        by_status = {c[0]: 0 for c in WorkOrder.Status.choices}
        by_assignment = {c[0]: 0 for c in WorkOrder.AssignmentType.choices}
        total_estimated = 0
        total_actual = 0
        total_parts = 0
        total_labor = 0
        total_downtime = 0
        total_time_hours = 0
        for wo in qs:
            by_status[wo.status] = by_status.get(wo.status, 0) + 1
            by_assignment[wo.assignment_type] = by_assignment.get(wo.assignment_type, 0) + 1
            total_estimated += float(wo.estimated_cost or 0)
            total_actual += float(wo.actual_cost or 0)
            total_parts += float(wo.parts_cost or 0)
            total_labor += float(wo.labor_cost or 0)
            total_downtime += (wo.downtime_hours or 0)
            for tl in wo.time_logs.all():
                total_time_hours += (tl.hours or 0)
        active = by_status.get('assigned', 0) + by_status.get('in_progress', 0)
        completed = by_status.get('completed', 0) + by_status.get('closed', 0)
        return Response({
            'total': total,
            'by_status': by_status,
            'by_assignment': by_assignment,
            'active': active,
            'completed': completed,
            'open_count': by_status.get('open', 0),
            'total_estimated': round(total_estimated, 2),
            'total_actual': round(total_actual, 2),
            'total_parts': round(total_parts, 2),
            'total_labor': round(total_labor, 2),
            'total_downtime': round(total_downtime, 1),
            'total_time_hours': round(total_time_hours, 1),
            'completion_rate': round((completed / total * 100), 1) if total else 0,
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo work orders with time logs, parts, and notes for the current tenant."""
        from apps.vehicles.models import Vehicle
        from apps.users.models import User
        from apps.contacts.models import Contact
        from apps.inventory.models import InventoryItem

        # Need existing issues without work orders to create WOs from, or create issues
        vehicles = list(Vehicle.objects.all()[:10])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        users = list(User.objects.all()[:3])
        mechanics = list(Contact.objects.filter(contact_type='mechanic')[:5])
        if not mechanics:
            mech_data = [
                ('Joe', 'Martinez'), ('Sarah', 'Chen'), ('Mike', 'OBrien'),
                ('Diana', 'Lopez'), ('Tom', 'Reyes'),
            ]
            for fn, ln in mech_data:
                Contact.objects.create(
                    contact_type='mechanic', first_name=fn, last_name=ln,
                    phone='555-0200', is_active=True,
                )
            mechanics = list(Contact.objects.filter(contact_type='mechanic')[:5])

        # Get or create inventory items
        items = list(InventoryItem.objects.all()[:10])
        if not items:
            item_data = [
                ('OIL-001', 'Synthetic Engine Oil 15W-40', 'Fluids', 45.00),
                ('FLT-002', 'Oil Filter', 'Filters', 18.50),
                ('FLT-003', 'Air Filter', 'Filters', 32.00),
                ('BRK-004', 'Brake Pad Set Front', 'Brakes', 145.00),
                ('BRK-005', 'Brake Rotor', 'Brakes', 89.00),
                ('BLT-006', 'Serpentine Belt', 'Engine', 55.00),
                ('COL-007', 'Radiator Coolant 1gal', 'Fluids', 22.00),
                ('SEN-008', 'O2 Sensor', 'Electrical', 95.00),
                ('BAT-009', 'Group 31 Battery', 'Electrical', 185.00),
                ('TIR-010', 'Steer Tire 11R22.5', 'Tires', 425.00),
            ]
            for sku, name, cat, cost in item_data:
                InventoryItem.objects.create(
                    sku=sku, name=name, category=cat, unit_cost=cost,
                    quantity_on_hand=50, reorder_point=10,
                )
            items = list(InventoryItem.objects.all()[:10])

        titles = [
            ('Engine overheating on highway', 'Vehicle temperature gauge spiked above normal during highway operation. Possible coolant leak or thermostat failure.', 'high'),
            ('Brake squeal when cold', 'Brake pads squeal audibly during first stops of the day when brakes are cold.', 'medium'),
            ('Check engine light - P0301', 'Cylinder 1 misfire detected. Rough idle and slight power loss under load. Spark plug or coil pack suspected.', 'high'),
            ('ABS warning light intermittent', 'ABS warning lamp illuminates intermittently while driving. Clears on restart.', 'medium'),
            ('Transmission slipping in reverse', 'Transmission hesitates and slips when shifting into reverse. Fluid level normal, slight burnt smell.', 'critical'),
            ('AC blowing warm air', 'Air conditioning system not cooling. Compressor clutch engages but no cold air output.', 'low'),
            ('Suspension clunk over bumps', 'Audible clunking from front suspension over bumps and rough roads.', 'medium'),
            ('DOT inspection failure - tires', 'Failed DOT inspection due to tire tread depth below 4/32 on steer axle tires.', 'critical'),
            ('Exhaust leak under cab', 'Exhaust fumes entering cab under acceleration. Visible soot at flex pipe joint.', 'high'),
            ('Power steering whine', 'Power steering pump makes whining noise when turning at low speed. Fluid dark and contaminated.', 'medium'),
        ]

        # Find issues without work orders first
        issues_without_wo = list(Issue.objects.filter(work_order__isnull=True)[:15])
        created = 0
        wo_count = 0
        now = timezone.now()

        # Create work orders for existing issues without WOs
        for issue in issues_without_wo:
            st = random.choice(['assigned', 'in_progress', 'parts_ordered', 'completed', 'closed'])
            mech = random.choice(mechanics) if mechanics and random.random() > 0.2 else None
            wo = WorkOrder.objects.create(
                issue=issue,
                assigned_to=mech,
                assignment_type=random.choice(['internal', 'external']),
                status=st,
                estimated_cost=round(random.uniform(50, 2500), 2),
                actual_cost=round(random.uniform(0, 2000), 2) if st in ('completed', 'closed') else 0,
                parts_cost=round(random.uniform(0, 800), 2) if st in ('completed', 'closed') or random.random() > 0.7 else 0,
                labor_cost=round(random.uniform(0, 1200), 2) if st in ('completed', 'closed') else 0,
                downtime_hours=round(random.uniform(0, 48), 1) if st in ('completed', 'closed', 'in_progress') else round(random.uniform(0, 8), 1),
                started_at=now - timedelta(days=random.randint(1, 30)) if st in ('in_progress', 'completed', 'closed') else None,
                completed_at=now - timedelta(days=random.randint(0, 10)) if st in ('completed', 'closed') else None,
            )
            wo_count += 1
            issue.status = 'closed' if st in ('completed', 'closed') else st
            if issue.status not in dict(Issue.Status.choices):
                issue.status = 'resolved'
            issue.save(update_fields=['status'])

            # Add time logs
            if st in ('in_progress', 'completed', 'closed') and mech:
                num_logs = random.randint(1, 3)
                for j in range(num_logs):
                    clock_in = now - timedelta(days=random.randint(0, 20), hours=random.randint(0, 6))
                    clock_out = clock_in + timedelta(hours=random.uniform(1, 8)) if random.random() > 0.2 or st in ('completed', 'closed') else None
                    TimeLog.objects.create(
                        work_order=wo, mechanic=mech,
                        clock_in=clock_in, clock_out=clock_out,
                    )

            # Add parts used
            if st in ('completed', 'closed') or random.random() > 0.6:
                num_parts = random.randint(1, 3)
                for j in range(num_parts):
                    item = random.choice(items)
                    PartUsage.objects.create(
                        work_order=wo, inventory_item=item,
                        quantity=random.randint(1, 4),
                        unit_cost=item.unit_cost,
                    )

            # Add notes
            num_notes = random.randint(0, 3)
            for j in range(num_notes):
                author = random.choice(users) if users and random.random() > 0.3 else None
                WorkOrderNote.objects.create(
                    work_order=wo, author=author,
                    visibility=random.choice(['internal', 'external']),
                    content=random.choice([
                        'Inspected vehicle, confirmed the issue. Starting diag.',
                        'Ordered replacement parts, ETA 3 business days.',
                        'Parts arrived, proceeding with repair.',
                        'Repair completed, test drove vehicle. All good.',
                        'Waiting on customer approval for additional work.',
                        'Found additional wear on related component, recommending replacement.',
                    ]),
                )

        # If not enough issues without WOs, create new issues + WO combos
        if wo_count < 15:
            needed = 15 - wo_count
            for i in range(needed):
                vw = random.choice(vehicles)
                title, desc, prio = random.choice(titles)
                issue = Issue.objects.create(
                    vehicle=vw, title=title, description=desc,
                    status='assigned', priority=prio,
                    reported_by=random.choice(users) if users and random.random() > 0.3 else None,
                )
                mech = random.choice(mechanics) if mechanics and random.random() > 0.2 else None
                st = random.choice(['assigned', 'in_progress', 'completed'])
                wo = WorkOrder.objects.create(
                    issue=issue,
                    assigned_to=mech,
                    assignment_type=random.choice(['internal', 'external']),
                    status=st,
                    estimated_cost=round(random.uniform(50, 2500), 2),
                    actual_cost=round(random.uniform(0, 2000), 2) if st == 'completed' else 0,
                    parts_cost=round(random.uniform(0, 800), 2) if st == 'completed' else 0,
                    labor_cost=round(random.uniform(0, 1200), 2) if st == 'completed' else 0,
                    downtime_hours=round(random.uniform(0, 48), 1) if st != 'assigned' else 0,
                )
                wo_count += 1
                if st == 'completed' and mech:
                    TimeLog.objects.create(
                        work_order=wo, mechanic=mech,
                        clock_in=now - timedelta(days=2, hours=4),
                        clock_out=now - timedelta(days=2),
                    )

        return Response({'detail': f'Seeded {wo_count} work orders with time logs, parts, and notes.'})


class IssuePhotoViewSet(viewsets.ModelViewSet):
    """CRUD for issue photos — accepts multipart uploads."""
    queryset = IssuePhoto.objects.select_related('issue')
    serializer_class = IssuePhotoSerializer
    filterset_fields = ['issue']
    ordering_fields = ['created_at']
