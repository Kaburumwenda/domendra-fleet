import json

from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone

from .models import Tire, TireInspection, TireMovement, TireRotation
from .serializers import (
    TireInspectionSerializer,
    TireMovementSerializer,
    TireRotationSerializer,
    TireSerializer,
)


class TireViewSet(viewsets.ModelViewSet):
    queryset = Tire.objects.select_related('vehicle')
    serializer_class = TireSerializer
    filterset_fields = ['status', 'vehicle', 'brand', 'type']
    search_fields = ['serial_number', 'brand', 'model', 'size']
    ordering_fields = ['created_at', 'purchase_date']

    @action(detail=False, methods=['get'])
    def catalog(self, request):
        """Distinct brand / size / model options (curated defaults + values
        already in use by this tenant) for Add-Tire dropdowns."""
        curated_brands = [
            'Michelin', 'Bridgestone', 'Goodyear', 'Continental', 'Pirelli',
            'BFGoodrich', 'Yokohama', 'Hankook', 'Toyo', 'Cooper', 'Firestone',
            'General Tire', 'Kumho', 'Falken', 'Nexen', 'Maxxis', 'Double Coin',
            'Mitas', 'Nokian', 'Giti', 'Sailun', 'Triangle', 'Linglong',
        ]
        curated_sizes = [
            '11R22.5', '11R24.5', '295/75R22.5', '285/75R24.5', '315/80R22.5',
            '12R22.5', '10R22.5', '255/70R22.5', '275/70R22.5', '215/75R17.5',
            '235/80R17.5', '265/70R19.5', '225/70R19.5', 'LT265/75R16', 'LT245/75R16',
            '265/75R16', '275/65R18', '285/65R20', '445/65R22.5', '385/65R22.5',
        ]
        curated_models = {
            'Michelin': ['XZA Energy', 'XZE2', 'X One Line Energy T', 'XDA Energy', 'XFA2', 'X-Line Energy D', 'XZY3', 'X-Incity XZUE2'],
            'Bridgestone': ['R-Steer', 'M-Steer', 'R-Drive', 'M-Drive', 'R-Trac', 'M-720', 'Ecopia H-Steer', 'Ecopia H-Drive 001', 'Duravis R-Steer'],
            'Goodyear': ['Fuel Max S', 'Fuel Max D', 'Marathon LHS', 'Marathon LHT', 'G572', 'G571', 'G661 HSA', 'G314'],
            'Continental': ['Conti Hybrid HD3', 'Conti Hybrid Coach', 'Conti EcoPlus HD3', 'Conti Sport', 'Conti HSL', 'Conti HDC', 'Conti Econet'],
            'Pirelli': ['H89 Plus', 'H88 Plus', 'FR85', 'TR85', 'PSR', 'Bogus D'],
            'BFGoodrich': ['DR444', 'DR452', 'T440', 'S2G', 'XSZ2'],
            'Yokohama': ['RY817', 'RY103', 'RB51', 'RY617', 'TY303', 'BL108'],
            'Hankook': ['e-cube MAX', 'e3 Wide', 'e-smart', 'AH35', 'DL11', 'TL11', 'e-Regional'],
            'Toyo': ['M647', 'M643', 'M577', 'M650', 'M154'],
            'Cooper': ['Roadmaster RM852', 'Roadmaster RM855', 'Roadmaster CSM', 'D-Series', 'Work Series'],
            'Firestone': ['FS592', 'FD692', 'FT455', 'Transforce HT', 'Transforce AT'],
            'General Tire': ['HSS', 'HSD', 'GHD', 'GHS'],
            'Kumho': ['KRS20', 'KRS01', 'KDL1', 'KDL2', 'KL21'],
            'Falken': ['R1', 'R2', 'RI151', 'BI852', 'SN211'],
            'Maxxis': ['MS832', 'MS933', 'ME66', 'MS300'],
            'Double Coin': ['RR680', 'RR675', 'RR150', 'RT606', 'FD405'],
            'Nokian': ['e-Traction', 'e-Line', 'Hakkapeliitta', 'C-Line', 'D-Line'],
            'Giti': ['GDR853', 'GDL677', 'GSR218', 'GAL833'],
            'Sailun': ['S805', 'S905', 'S812', 'S701', 'TR617'],
            'Triangle': ['TR628', 'TR688', 'TR692', 'TR298', 'TR616'],
            'Linglong': ['LLF01', 'LLR01', 'LLD01', 'LSS08'],
        }
        min_tread_depth_options = [2, 3, 4, 5, 6, 8]
        warranty_miles_options = [30000, 50000, 70000, 100000, 125000, 150000, 200000]

        qs = self.get_queryset()
        used_brands = list(qs.exclude(brand='').values_list('brand', flat=True).distinct().order_by('brand'))
        used_sizes = list(qs.exclude(size='').values_list('size', flat=True).distinct().order_by('size'))
        used_models = list(
            qs.exclude(model='').exclude(brand='')
              .values('brand', 'model').order_by('brand', 'model')
        )

        brands = sorted(set(curated_brands + used_brands), key=str.lower)
        sizes = sorted(set(curated_sizes + used_sizes), key=str.lower)

        # Merge curated models with used models (grouped by brand, deduped)
        models_by_brand: dict[str, set] = {}
        for brand, vals in curated_models.items():
            models_by_brand.setdefault(brand, set()).update(vals)
        for row in used_models:
            models_by_brand.setdefault(row['brand'], set()).add(row['model'])
        models = [
            {'brand': brand, 'model': model}
            for brand, model_set in sorted(models_by_brand.items(), key=lambda kv: str.lower(kv[0]))
            for model in sorted(model_set, key=str.lower)
        ]

        return Response({
            'brands': brands,
            'sizes': sizes,
            'models': models,
            'min_tread_depth_options': min_tread_depth_options,
            'warranty_miles_options': warranty_miles_options,
        })

    @action(detail=False, methods=['get'])
    def needs_replacement(self, request):
        qs = self.get_queryset().filter(status__in=[Tire.Status.MOUNTED, Tire.Status.SPARE])
        result = [TireSerializer(t).data for t in qs if t.needs_replacement]
        return Response(result)

    @action(detail=True, methods=['post'])
    def mount(self, request, pk=None):
        tire = self.get_object()
        if tire.quantity <= 0:
            return Response(
                {'detail': 'No stock available to mount for this tire.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        vehicle_id = request.data.get('vehicle')
        position = request.data.get('position', '')
        performed_at = request.data.get('performed_at') or timezone.now().date()
        TireMovement.objects.create(
            tire=tire, movement_type=TireMovement.MovementType.MOUNT,
            from_vehicle=tire.vehicle, to_vehicle_id=vehicle_id,
            from_position=tire.position, to_position=position,
            odometer=request.data.get('odometer'),
            notes=request.data.get('notes', ''),
            performed_at=performed_at,
        )
        tire.vehicle_id = vehicle_id
        tire.position = position
        tire.status = Tire.Status.MOUNTED
        tire.quantity = max(0, tire.quantity - 1)
        tire.save(update_fields=['vehicle', 'position', 'status', 'quantity', 'updated_at'])
        return Response(TireSerializer(tire).data)

    @action(detail=False, methods=['post'])
    def rotate(self, request):
        """Record a tire rotation for a vehicle.

        Payload::
            {
              "vehicle": <id>,
              "performed_at": "YYYY-MM-DD",
              "odometer": 12345,            // optional
              "rotation_pattern": "X-Pattern",  // optional
              "notes": "...",             // optional
              "swaps": [
                 {"tire": <id>, "from_position": "F1_L", "to_position": "D1_L"},
                 ...
              ]
            }

        For each swap the tire's ``position`` is updated and a ``transfer``
        :class:`TireMovement` is logged.  A single :class:`TireRotation` record
        groups the whole operation.
        """
        vehicle_id = request.data.get('vehicle')
        if not vehicle_id:
            return Response(
                {'detail': 'A vehicle is required to record a rotation.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        swaps = request.data.get('swaps') or []
        if not isinstance(swaps, list) or len(swaps) < 2:
            return Response(
                {'detail': 'At least two tyre swaps are required for a rotation.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        performed_at = request.data.get('performed_at') or timezone.now().date()
        odometer = request.data.get('odometer')
        rotation_pattern = request.data.get('rotation_pattern', '')
        notes = request.data.get('notes', '')

        tire_ids = [s.get('tire') for s in swaps if s.get('tire')]

        with transaction.atomic():
            # SELECT … FOR UPDATE must be inside the transaction
            tires = {t.id: t for t in Tire.objects.filter(id__in=tire_ids, vehicle_id=vehicle_id)
                     .select_for_update()}
            if len(tires) != len(tire_ids):
                missing = sorted(set(tire_ids) - set(tires.keys()))
                return Response(
                    {'detail': f'Tyres not found on this vehicle: {missing}'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            rotation = TireRotation.objects.create(
                vehicle_id=vehicle_id,
                performed_at=performed_at,
                rotation_pattern=rotation_pattern,
                odometer=odometer,
                notes=notes,
                swaps=[{'tire': s.get('tire'),
                        'from_position': s.get('from_position', ''),
                        'to_position': s.get('to_position', '')}
                       for s in swaps],
            )

            for s in swaps:
                tire_id = s.get('tire')
                if not tire_id:
                    continue
                tire = tires.get(tire_id)
                if not tire:
                    continue
                from_position = s.get('from_position') or tire.position or ''
                to_position = s.get('to_position') or ''
                TireMovement.objects.create(
                    tire=tire,
                    movement_type=TireMovement.MovementType.TRANSFER,
                    from_vehicle=tire.vehicle,
                    to_vehicle=tire.vehicle,
                    from_position=from_position,
                    to_position=to_position,
                    odometer=odometer,
                    performed_at=performed_at,
                    notes=f'Rotation #{rotation.id}',
                )
                tire.position = to_position
                tire.save(update_fields=['position', 'updated_at'])

            updated = [TireSerializer(tires[tid]).data for tid in sorted(tires)]
            return Response({
                'rotation': TireRotationSerializer(rotation).data,
                'tires': updated,
            }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def unmount(self, request, pk=None):
        tire = self.get_object()
        TireMovement.objects.create(
            tire=tire, movement_type=TireMovement.MovementType.UNMOUNT,
            from_vehicle=tire.vehicle, from_position=tire.position,
            odometer=request.data.get('odometer'),
            notes=request.data.get('notes', ''),
            performed_at=request.data.get('performed_at') or timezone.now().date(),
        )
        tire.vehicle = None
        tire.position = ''
        tire.status = Tire.Status.IN_STOCK
        tire.quantity = tire.quantity + 1
        tire.save(update_fields=['vehicle', 'position', 'status', 'quantity', 'updated_at'])
        return Response(TireSerializer(tire).data)

    @action(detail=True, methods=['post'])
    def retire(self, request, pk=None):
        tire = self.get_object()
        TireMovement.objects.create(
            tire=tire, movement_type=TireMovement.MovementType.UNMOUNT,
            from_vehicle=tire.vehicle, from_position=tire.position,
            odometer=request.data.get('odometer'),
            notes=request.data.get('notes', ''),
            performed_at=request.data.get('performed_at') or timezone.now().date(),
        )
        tire.status = Tire.Status.RETIRED
        tire.vehicle = None
        tire.position = ''
        tire.quantity = 0
        tire.save(update_fields=['status', 'vehicle', 'position', 'quantity', 'updated_at'])
        return Response(TireSerializer(tire).data)


class TireInspectionViewSet(viewsets.ModelViewSet):
    queryset = TireInspection.objects.select_related('tire', 'vehicle')
    serializer_class = TireInspectionSerializer
    filterset_fields = ['tire', 'vehicle', 'condition']
    ordering_fields = ['measured_at', 'created_at']


class TireRotationViewSet(viewsets.ModelViewSet):
    queryset = TireRotation.objects.select_related('vehicle')
    serializer_class = TireRotationSerializer
    filterset_fields = ['vehicle']
    ordering_fields = ['performed_at']


class TireMovementViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TireMovement.objects.select_related('tire', 'from_vehicle', 'to_vehicle')
    serializer_class = TireMovementSerializer
    filterset_fields = ['tire', 'movement_type', 'from_vehicle', 'to_vehicle']
    ordering_fields = ['performed_at']
