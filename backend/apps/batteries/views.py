from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Battery, BatteryReading, BatteryMovement, ChargeCycle, BatteryReplacement
from .serializers import (
    BatterySerializer,
    BatteryReadingSerializer,
    BatteryMovementSerializer,
    ChargeCycleSerializer,
    BatteryReplacementSerializer,
)


class BatteryViewSet(viewsets.ModelViewSet):
    queryset = Battery.objects.select_related('vehicle')
    serializer_class = BatterySerializer
    filterset_fields = ['status', 'vehicle', 'brand', 'chemistry', 'condition']
    search_fields = ['serial_number', 'brand', 'model', 'part_number', 'group_code']
    ordering_fields = ['created_at', 'purchase_date', 'voltage']

    @action(detail=False, methods=['get'])
    def catalog(self, request):
        curated_brands = [
            'Optima', 'ACDelco', 'DieHard', 'Interstate', 'Exide',
            'Duralast', 'EverStart', 'Bosch', 'Motorcraft', 'NAPA',
            'Odyssey', 'Lifeline', 'Trojan', 'Crown', 'US Battery',
            'Fullriver', 'Battle Born', 'RELiON', 'Victron', 'Mighty Max',
            'Yuasa', 'Leoch', 'Duracell', 'AutoCraft', 'Super Start',
        ]
        grouped_brands_by_chemistry = {
            'Lead-Acid': ['Optima', 'ACDelco', 'DieHard', 'Interstate', 'Exide', 'Duralast', 'EverStart', 'Bosch', 'Motorcraft'],
            'AGM': ['Optima', 'Odyssey', 'DieHard', 'Duralast', 'Interstate', 'ACDelco'],
            'Gel': ['Exide', 'Trojan', 'Crown', 'US Battery'],
            'Lithium-Ion': ['Bosch', 'Battle Born', 'RELiON', 'Victron'],
            'LiFePO4': ['Battle Born', 'RELiON', 'Fullriver', 'Mighty Max'],
        }
        voltage_options = [6, 8, 12, 24, 36, 48]
        capacity_options = [20, 35, 50, 60, 70, 75, 80, 100, 125, 150, 200, 250, 300, 400]
        cca_options = [300, 400, 500, 600, 650, 700, 750, 800, 850, 900, 1000, 1100, 1200]
        group_codes = ['U1', '24', '27', '31', '34', '34R', '35', '47', '48', '49', '65', '75', '78', '85', '94R', '95R', 'GC2', 'T6', 'T8', 'L16']
        chemistry_choices = [c[0] for c in Battery.Chemistry.choices]
        position_options = ['Starter', 'Auxiliary', 'House', 'Traction', 'Deep Cycle', 'Marine']
        condition_choices = [{'value': c[0], 'label': c[1]} for c in Battery.Condition.choices]

        qs = self.get_queryset()
        used_brands = list(qs.exclude(brand='').values_list('brand', flat=True).distinct().order_by('brand'))
        brands = sorted(set(curated_brands + used_brands), key=str.lower)

        return Response({
            'brands': brands,
            'chem_by_brand': grouped_brands_by_chemistry,
            'voltage_options': voltage_options,
            'capacity_options': capacity_options,
            'cca_options': cca_options,
            'group_codes': group_codes,
            'position_options': position_options,
            'chemistry_choices': chemistry_choices,
            'condition_choices': condition_choices,
        })

    @action(detail=False, methods=['get'])
    def needs_replacement(self, request):
        qs = self.get_queryset()
        result = [BatterySerializer(b).data for b in qs if b.needs_replacement]
        return Response(result)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Battery.objects.all()
        total = qs.count()
        installed = qs.filter(status=Battery.Status.INSTALLED).count()
        in_stock = qs.filter(status=Battery.Status.IN_STOCK).count()
        spare = qs.filter(status=Battery.Status.SPARE).count()
        charging = qs.filter(status=Battery.Status.CHARGING).count()
        retired = qs.filter(status__in=[Battery.Status.RETIRED, Battery.Status.SCRAPPED]).count()
        needs_repl = sum(1 for b in qs if b.needs_replacement)
        by_chemistry = {}
        for b in qs:
            label = b.get_chemistry_display() or b.chemistry
            by_chemistry[label] = by_chemistry.get(label, 0) + 1
        by_condition = {}
        for c in Battery.Condition.choices:
            by_condition[c[1]] = qs.filter(condition=c[0]).count()
        from django.db.models import Sum
        inv_val = qs.exclude(status='retired').exclude(status='scrapped').aggregate(
            v=Sum('purchase_price')
        )['v'] or 0
        avg_health = 0
        active = [b for b in qs.filter(status__in=['installed', 'spare']) if b.health_pct is not None]
        if active:
            avg_health = round(sum(b.health_pct for b in active) / len(active), 1)
        return Response({
            'total': total,
            'installed': installed,
            'in_stock': in_stock,
            'spare': spare,
            'charging': charging,
            'retired': retired,
            'needs_replacement': needs_repl,
            'avg_health': avg_health,
            'inventory_value': float(inv_val),
            'by_chemistry': by_chemistry,
            'by_condition': by_condition,
        })

    @action(detail=True, methods=['post'])
    def install(self, request, pk=None):
        battery = self.get_object()
        if battery.status not in (Battery.Status.IN_STOCK, Battery.Status.SPARE, Battery.Status.CHARGING):
            return Response(
                {'detail': 'Battery cannot be installed in current status.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        vehicle_id = request.data.get('vehicle')
        position = request.data.get('position', '')
        performed_at = request.data.get('performed_at') or timezone.now().date()

        old_battery_id = request.data.get('replaced_battery')
        if old_battery_id:
            try:
                old = Battery.objects.get(id=old_battery_id)
                if old.vehicle_id:
                    BatteryMovement.objects.create(
                        battery=old, movement_type=BatteryMovement.MovementType.SWAP,
                        from_vehicle=old.vehicle, to_vehicle_id=vehicle_id,
                        from_position=old.position, to_position=position,
                        replaced_by=battery,
                        notes=f'Swapped out for {battery.serial_number}',
                        performed_at=performed_at,
                    )
                    old.vehicle = None
                    old.position = ''
                    old.status = Battery.Status.IN_STOCK
                    old.save(update_fields=['vehicle', 'position', 'status', 'updated_at'])
            except Battery.DoesNotExist:
                pass

        BatteryMovement.objects.create(
            battery=battery, movement_type=BatteryMovement.MovementType.INSTALL,
            from_vehicle=battery.vehicle, to_vehicle_id=vehicle_id,
            from_position=battery.position, to_position=position,
            notes=request.data.get('notes', ''),
            performed_at=performed_at,
        )
        battery.vehicle_id = vehicle_id
        battery.position = position
        battery.status = Battery.Status.INSTALLED
        if not battery.install_date:
            battery.install_date = performed_at
        battery.save(update_fields=['vehicle', 'position', 'status', 'install_date', 'updated_at'])
        return Response(BatterySerializer(battery).data)

    @action(detail=True, methods=['post'])
    def uninstall(self, request, pk=None):
        battery = self.get_object()
        BatteryMovement.objects.create(
            battery=battery, movement_type=BatteryMovement.MovementType.UNINSTALL,
            from_vehicle=battery.vehicle, from_position=battery.position,
            notes=request.data.get('notes', ''),
            performed_at=request.data.get('performed_at') or timezone.now().date(),
        )
        battery.vehicle = None
        battery.position = ''
        battery.status = Battery.Status.IN_STOCK
        battery.save(update_fields=['vehicle', 'position', 'status', 'updated_at'])
        return Response(BatterySerializer(battery).data)

    @action(detail=True, methods=['post'])
    def charge(self, request, pk=None):
        battery = self.get_object()
        BatteryMovement.objects.create(
            battery=battery, movement_type=BatteryMovement.MovementType.CHARGE,
            notes=request.data.get('notes', ''),
            performed_at=request.data.get('performed_at') or timezone.now().date(),
        )
        prev_status = battery.status
        battery.status = Battery.Status.CHARGING
        battery.save(update_fields=['status', 'updated_at'])
        return Response(BatterySerializer(battery).data)

    @action(detail=True, methods=['post'])
    def retire(self, request, pk=None):
        battery = self.get_object()
        BatteryMovement.objects.create(
            battery=battery, movement_type=BatteryMovement.MovementType.RETIRE,
            from_vehicle=battery.vehicle, from_position=battery.position,
            notes=request.data.get('notes', ''),
            performed_at=request.data.get('performed_at') or timezone.now().date(),
        )
        battery.status = Battery.Status.RETIRED
        battery.vehicle = None
        battery.position = ''
        battery.save(update_fields=['status', 'vehicle', 'position', 'updated_at'])
        return Response(BatterySerializer(battery).data)


class BatteryReadingViewSet(viewsets.ModelViewSet):
    queryset = BatteryReading.objects.select_related('battery', 'vehicle')
    serializer_class = BatteryReadingSerializer
    filterset_fields = ['battery', 'vehicle', 'test_result']
    ordering_fields = ['measured_at', 'created_at']


class BatteryMovementViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = BatteryMovement.objects.select_related('battery', 'from_vehicle', 'to_vehicle')
    serializer_class = BatteryMovementSerializer
    filterset_fields = ['battery', 'movement_type', 'from_vehicle', 'to_vehicle']
    ordering_fields = ['performed_at']


class ChargeCycleViewSet(viewsets.ModelViewSet):
    queryset = ChargeCycle.objects.select_related('battery')
    serializer_class = ChargeCycleSerializer
    filterset_fields = ['battery', 'charge_method']
    ordering_fields = ['created_at']


class BatteryReplacementViewSet(viewsets.ModelViewSet):
    queryset = BatteryReplacement.objects.select_related('battery', 'old_battery', 'vehicle')
    serializer_class = BatteryReplacementSerializer
    filterset_fields = ['battery', 'vehicle', 'status']
    ordering_fields = ['created_at', 'scheduled_date']
