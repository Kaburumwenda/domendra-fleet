from rest_framework import serializers

from .models import Tire, TireInspection, TireMovement, TireRotation


class TireInspectionSerializer(serializers.ModelSerializer):
    tire_serial = serializers.CharField(source='tire.serial_number', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)

    class Meta:
        model = TireInspection
        fields = '__all__'
        read_only_fields = ['created_at']


class TireRotationSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    vehicle_drivetrain = serializers.CharField(source='vehicle.drivetrain', read_only=True)
    vehicle_type = serializers.CharField(source='vehicle.vehicle_type', read_only=True)
    vehicle_steering = serializers.CharField(source='vehicle.steering', read_only=True)
    vehicle_license_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    swaps_detail = serializers.SerializerMethodField()

    class Meta:
        model = TireRotation
        fields = '__all__'
        read_only_fields = ['created_at']

    def get_swaps_detail(self, obj):
        swaps = obj.swaps or []
        if not swaps:
            return []
        tire_ids = {s.get('tire') for s in swaps if s.get('tire')}
        tire_map = {}
        if tire_ids:
            tire_map = {t.id: t for t in Tire.objects.filter(id__in=tire_ids)}
        result = []
        for s in swaps:
            t = tire_map.get(s.get('tire'))
            result.append({
                'tire': s.get('tire'),
                'tire_serial': t.serial_number if t else None,
                'tire_brand': t.brand if t else None,
                'tire_size': t.size if t else None,
                'from_position': s.get('from_position', ''),
                'to_position': s.get('to_position', ''),
            })
        return result


class TireMovementSerializer(serializers.ModelSerializer):
    from_vehicle_name = serializers.CharField(source='from_vehicle.display_name', read_only=True)
    to_vehicle_name = serializers.CharField(source='to_vehicle.display_name', read_only=True)
    tire_serial = serializers.CharField(source='tire.serial_number', read_only=True)

    class Meta:
        model = TireMovement
        fields = '__all__'
        read_only_fields = ['created_at']


class TireSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    vehicle_license_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    vehicle_drivetrain = serializers.CharField(source='vehicle.drivetrain', read_only=True)
    vehicle_type = serializers.CharField(source='vehicle.vehicle_type', read_only=True)
    vehicle_steering = serializers.CharField(source='vehicle.steering', read_only=True)
    latest_tread_depth = serializers.FloatField(read_only=True)
    total_miles = serializers.FloatField(read_only=True)
    needs_replacement = serializers.BooleanField(read_only=True)
    last_mount_date = serializers.DateField(read_only=True)
    retired_date = serializers.DateField(read_only=True)

    class Meta:
        model = Tire
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
