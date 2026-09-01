from datetime import timedelta

from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import InspectionForm, InspectionItem, InspectionReport, InspectionResponse
from .serializers import (
    InspectionFormSerializer,
    InspectionItemSerializer,
    InspectionReportCreateSerializer,
    InspectionReportSerializer,
    InspectionResponseSerializer,
)


class InspectionFormViewSet(viewsets.ModelViewSet):
    queryset = InspectionForm.objects.all()
    serializer_class = InspectionFormSerializer
    filterset_fields = ['is_active']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']


class InspectionItemViewSet(viewsets.ModelViewSet):
    queryset = InspectionItem.objects.select_related('form')
    serializer_class = InspectionItemSerializer
    filterset_fields = ['form', 'item_type', 'is_critical', 'is_required']
    ordering_fields = ['order']


class InspectionReportViewSet(viewsets.ModelViewSet):
    queryset = InspectionReport.objects.select_related('vehicle', 'driver', 'form').prefetch_related('responses')
    filterset_fields = ['status', 'vehicle', 'driver', 'form']
    ordering_fields = ['submitted_at', 'updated_at']

    def get_serializer_class(self):
        if self.action in ('create',):
            return InspectionReportCreateSerializer
        return InspectionReportSerializer

    @action(detail=False, methods=['get'])
    def summary(self, request):
        qs = self.filter_queryset(self.get_queryset())
        data = qs.aggregate(
            total=Count('id'),
            passed=Count('id', filter=Q(status='pass')),
            failed=Count('id', filter=Q(status='fail')),
            conditional=Count('id', filter=Q(status='conditional')),
            drafts=Count('id', filter=Q(status='draft')),
        )
        return Response(data)

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate inspection statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        passed = qs.filter(status='pass').count()
        failed = qs.filter(status='fail').count()
        conditional = qs.filter(status='conditional').count()
        drafts = qs.filter(status='draft').count()
        pass_rate = round(passed / total * 100, 1) if total else 0

        by_form = {}
        for r in qs.select_related('form'):
            fname = r.form.name if r.form else 'Ad-hoc'
            if fname not in by_form:
                by_form[fname] = {'form_name': fname, 'count': 0, 'pass': 0, 'fail': 0, 'conditional': 0}
            by_form[fname]['count'] += 1
            if r.status == 'pass':
                by_form[fname]['pass'] += 1
            elif r.status == 'fail':
                by_form[fname]['fail'] += 1
            elif r.status == 'conditional':
                by_form[fname]['conditional'] += 1

        by_vehicle = {}
        for r in qs.select_related('vehicle'):
            vname = r.vehicle.display_name if r.vehicle else '—'
            if vname not in by_vehicle:
                by_vehicle[vname] = {'vehicle_name': vname, 'count': 0, 'fail': 0}
            by_vehicle[vname]['count'] += 1
            if r.status == 'fail':
                by_vehicle[vname]['fail'] += 1

        critical_fails = InspectionResponse.objects.filter(
            is_fail=True, item__is_critical=True
        ).values('report_id').distinct().count()

        return Response({
            'total': total,
            'passed': passed,
            'failed': failed,
            'conditional': conditional,
            'drafts': drafts,
            'pass_rate': pass_rate,
            'critical_fails': critical_fails,
            'by_form': list(by_form.values()),
            'by_vehicle': list(by_vehicle.values()),
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo inspection forms, items, and reports for the current tenant."""
        import random

        from apps.vehicles.models import Vehicle

        vehicles = list(Vehicle.objects.all()[:10])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        # Ensure at least one default form exists
        default_form, _ = InspectionForm.objects.get_or_create(
            name='Daily Pre-Trip Inspection',
            defaults={'description': 'Standard daily pre-trip vehicle inspection checklist.', 'is_active': True},
        )
        if not default_form.items.exists():
            items = [
                ('Headlights & Taillights', 'pass_fail', True),
                ('Turn Signals & Hazard Lights', 'pass_fail', True),
                ('Brake Lights', 'pass_fail', True),
                ('Tire Condition & Pressure', 'pass_fail', True),
                ('Windshield & Mirrors', 'pass_fail', False),
                ('Wipers & Washers', 'pass_fail', False),
                ('Horn', 'pass_fail', True),
                ('Seatbelts', 'pass_fail', True),
                ('Fire Extinguisher', 'pass_fail', True),
                ('Reflective Triangles', 'pass_fail', False),
                ('Engine Oil Level', 'number', False),
                ('Coolant Level', 'number', False),
                ('Dash Warning Lights', 'text', False),
                ('Exterior Photo', 'photo', False),
                ('Driver Signature', 'signature', False),
            ]
            for idx, (label, itype, critical) in enumerate(items):
                InspectionItem.objects.create(
                    form=default_form, label=label, item_type=itype,
                    is_critical=critical, is_required=True, order=idx,
                    help_text=f'Check {label.lower()} and record result.' if itype == 'pass_fail' else '',
                )

        safety_form, _ = InspectionForm.objects.get_or_create(
            name='Annual Safety Inspection',
            defaults={'description': 'Comprehensive annual safety inspection form.', 'is_active': True},
        )
        if not safety_form.items.exists():
            items = [
                ('Brake System Inspection', 'pass_fail', True),
                ('Suspension & Steering', 'pass_fail', True),
                ('Exhaust System', 'pass_fail', False),
                ('Frame & Undercarriage', 'pass_fail', True),
                ('Fluid Leaks Check', 'pass_fail', True),
                ('Battery & Alternator', 'pass_fail', False),
                ('Emissions Test', 'number', True),
                ('Tire Tread Depth (mm)', 'number', True),
                ('Overall Condition Notes', 'text', False),
            ]
            for idx, (label, itype, critical) in enumerate(items):
                InspectionItem.objects.create(
                    form=safety_form, label=label, item_type=itype,
                    is_critical=critical, is_required=True, order=idx,
                )

        # Create demo reports
        forms = list(InspectionForm.objects.filter(is_active=True))
        if not forms:
            return Response({'detail': 'No active inspection forms found.'}, status=400)

        statuses = ['pass', 'pass', 'pass', 'conditional', 'fail', 'draft']
        now = timezone.now()
        created = 0

        for v in vehicles:
            num_reports = random.randint(2, 4)
            for _ in range(num_reports):
                form = random.choice(forms)
                submitted_at = now - timedelta(days=random.randint(0, 60), hours=random.randint(0, 23))
                status = random.choice(statuses)

                report = InspectionReport.objects.create(
                    vehicle=v,
                    form=form,
                    status=status,
                    notes=random.choice([
                        'Routine inspection completed.',
                        'Minor issues noted, schedule follow-up.',
                        'Vehicle passed all critical checks.',
                        'Critical safety concern identified.',
                        '',
                        'Driver reported no issues during trip.',
                    ]),
                    odometer_reading=random.randint(20000, 200000),
                    submitted_at=submitted_at,
                    updated_at=submitted_at,
                )

                # Create responses for each item
                for item in form.items.all():
                    if item.item_type == 'pass_fail':
                        if status == 'fail':
                            is_fail = random.random() < 0.3 if not item.is_critical else random.random() < 0.6
                        elif status == 'conditional':
                            is_fail = random.random() < 0.15
                        else:
                            is_fail = False
                        value = 'fail' if is_fail else 'pass'
                    elif item.item_type == 'number':
                        value = str(random.randint(30, 100))
                        is_fail = False
                    elif item.item_type == 'text':
                        value = random.choice(['OK', 'Good condition', 'Needs attention', ''])
                        is_fail = False
                    elif item.item_type == 'checklist':
                        value = 'checked' if random.random() < 0.8 else 'unchecked'
                        is_fail = False
                    else:
                        value = ''
                        is_fail = False

                    InspectionResponse.objects.create(
                        report=report,
                        item=item,
                        value=value,
                        notes='' if not is_fail else random.choice(['Failed inspection', 'Needs repair', 'Replace immediately']),
                        is_fail=is_fail,
                    )
                created += 1

        return Response({'detail': f'Seeded {created} inspection reports with {forms.__len__()} forms.'})
