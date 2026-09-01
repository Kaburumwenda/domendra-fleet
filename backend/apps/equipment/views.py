from datetime import timedelta

from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import CalibrationRecord, Equipment, EquipmentCategory, EquipmentCheckout, EquipmentMeterEntry
from .serializers import (
    CalibrationRecordSerializer,
    EquipmentCategorySerializer,
    EquipmentCheckoutCreateSerializer,
    EquipmentCheckoutSerializer,
    EquipmentMeterEntrySerializer,
    EquipmentSerializer,
)


class EquipmentCategoryViewSet(viewsets.ModelViewSet):
    queryset = EquipmentCategory.objects.all()
    serializer_class = EquipmentCategorySerializer
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']


class EquipmentViewSet(viewsets.ModelViewSet):
    queryset = Equipment.objects.select_related('category', 'assigned_to', 'assigned_vehicle')
    serializer_class = EquipmentSerializer
    filterset_fields = ['status', 'category', 'assigned_to', 'assigned_vehicle', 'requires_calibration']
    search_fields = ['name', 'asset_number', 'serial_number', 'barcode']
    ordering_fields = ['name', 'current_hours', 'purchase_date', 'created_at']

    @action(detail=True, methods=['post'])
    def meter_entry(self, request, pk=None):
        equipment = self.get_object()
        serializer = EquipmentMeterEntrySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(equipment=equipment)
        equipment.refresh_from_db()
        return Response(EquipmentSerializer(equipment).data)

    @action(detail=True, methods=['post'])
    def check_out(self, request, pk=None):
        equipment = self.get_object()
        if equipment.is_checked_out:
            return Response({'detail': 'Equipment is already checked out.'}, status=status.HTTP_400_BAD_REQUEST)
        serializer = EquipmentCheckoutCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        checkout = serializer.save(equipment=equipment, checked_out_by=request.user if request.user.is_authenticated else None)
        equipment.status = Equipment.Status.IN_USE
        equipment.assigned_to = checkout.checked_out_to
        equipment.save(update_fields=['status', 'assigned_to', 'updated_at'])
        return Response(EquipmentCheckoutSerializer(checkout).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def check_in(self, request, pk=None):
        equipment = self.get_object()
        open_checkout = equipment.checkouts.filter(returned_at__isnull=True).first()
        if not open_checkout:
            return Response({'detail': 'No open checkout for this equipment.'}, status=status.HTTP_400_BAD_REQUEST)
        open_checkout.returned_at = timezone.now()
        open_checkout.returned_to = request.user if request.user.is_authenticated else None
        open_checkout.save(update_fields=['returned_at', 'returned_to'])
        equipment.status = Equipment.Status.AVAILABLE
        equipment.assigned_to = None
        equipment.save(update_fields=['status', 'assigned_to', 'updated_at'])
        return Response(EquipmentCheckoutSerializer(open_checkout).data)

    @action(detail=False, methods=['get'])
    def calibration_due(self, request):
        qs = self.get_queryset().filter(
            requires_calibration=True, next_calibration_due__lte=timezone.now().date() + timedelta(days=30)
        )
        return Response(EquipmentSerializer(qs, many=True).data)

    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Equipment analytics: status breakdown, utilization, calibration, value."""
        from decimal import Decimal
        from django.db.models import Count, Q, Sum

        qs = self.get_queryset()
        total = qs.count()
        by_status = list(qs.values('status').annotate(count=Count('id')).order_by('-count'))
        by_category = list(
            qs.values('category__name').annotate(count=Count('id')).order_by('-count')
        )
        by_category = [{'category': c['category__name'] or 'Uncategorized', 'count': c['count']} for c in by_category]

        available = qs.filter(status='available').count()
        in_use = qs.filter(status='in_use').count()
        in_maintenance = qs.filter(status='in_maintenance').count()
        retired = qs.filter(status='retired').count()

        calibration_overdue = qs.filter(
            requires_calibration=True, next_calibration_due__lt=timezone.now().date()
        ).count()
        calibration_due_soon = qs.filter(
            requires_calibration=True,
            next_calibration_due__gte=timezone.now().date(),
            next_calibration_due__lte=timezone.now().date() + timedelta(days=30),
        ).count()

        checked_out = EquipmentCheckout.objects.filter(
            returned_at__isnull=True
        ).values('equipment_id').distinct().count()
        utilization_pct = round((in_use / total * 100), 1) if total else 0

        total_value = float(qs.aggregate(t=Sum('purchase_price'))['t'] or Decimal('0'))

        # Active checkouts
        active_checkouts = EquipmentCheckout.objects.filter(returned_at__isnull=True).count()
        overdue_checkouts = EquipmentCheckout.objects.filter(
            returned_at__isnull=True, expected_return_at__lt=timezone.now()
        ).count()

        # Recent checkouts (last 30 days)
        since = timezone.now() - timedelta(days=30)
        recent_checkouts = EquipmentCheckout.objects.filter(checked_out_at__gte=since).count()
        recent_meter = EquipmentMeterEntry.objects.filter(recorded_at__gte=since).count()
        recent_calibrations = CalibrationRecord.objects.filter(created_at__gte=since).count()

        # Status distribution for chart
        status_colors = {
            'available': '#16a34a', 'in_use': '#2563eb',
            'in_maintenance': '#f59e0b', 'retired': '#64748b',
        }
        status_chart = [{
            'name': s['status'].replace('_', ' ').title(),
            'value': s['count'],
            'color': status_colors.get(s['status'], '#94a3b8'),
        } for s in by_status]

        return Response({
            'summary': {
                'total': total,
                'available': available,
                'in_use': in_use,
                'in_maintenance': in_maintenance,
                'retired': retired,
                'checked_out': checked_out,
                'utilization_pct': utilization_pct,
                'calibration_overdue': calibration_overdue,
                'calibration_due_soon': calibration_due_soon,
                'total_value': total_value,
                'active_checkouts': active_checkouts,
                'overdue_checkouts': overdue_checkouts,
            },
            'by_status': by_status,
            'by_category': by_category,
            'status_chart': status_chart,
            'recent_activity': {
                'checkouts': recent_checkouts,
                'meter_entries': recent_meter,
                'calibrations': recent_calibrations,
            },
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request):
        """Seed demo equipment data for this tenant.
        POST body: {"clear": true} to wipe existing data first.
        """
        clear = bool(request.data.get('clear', False))
        already_has = Equipment.objects.exists()

        from .demo_data import seed_equipment_demo_data
        result = seed_equipment_demo_data(clear=clear)

        if clear and already_has:
            detail = f"Replaced with {result['equipment']} equipment items."
        elif already_has:
            detail = f"Demo data ensured ({result['equipment']} total items)."
        else:
            detail = f"Seeded {result['equipment']} equipment items successfully."

        return Response({'detail': detail, 'summary': result})


class EquipmentCheckoutViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EquipmentCheckout.objects.select_related('equipment', 'checked_out_to', 'checked_out_by')
    serializer_class = EquipmentCheckoutSerializer
    filterset_fields = ['equipment', 'checked_out_to', 'returned_at']
    ordering_fields = ['checked_out_at', 'returned_at']


class EquipmentMeterEntryViewSet(viewsets.ModelViewSet):
    queryset = EquipmentMeterEntry.objects.select_related('equipment')
    serializer_class = EquipmentMeterEntrySerializer
    filterset_fields = ['equipment']
    ordering_fields = ['recorded_at']


class CalibrationRecordViewSet(viewsets.ModelViewSet):
    queryset = CalibrationRecord.objects.select_related('equipment')
    serializer_class = CalibrationRecordSerializer
    filterset_fields = ['equipment', 'result']
    ordering_fields = ['calibrated_at', 'created_at']
