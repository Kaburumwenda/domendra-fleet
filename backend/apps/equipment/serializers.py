from rest_framework import serializers

from .models import CalibrationRecord, Equipment, EquipmentCategory, EquipmentCheckout, EquipmentMeterEntry


class EquipmentCategorySerializer(serializers.ModelSerializer):
    item_count = serializers.IntegerField(source='items.count', read_only=True, required=False)

    class Meta:
        model = EquipmentCategory
        fields = '__all__'
        read_only_fields = ['created_at']


class EquipmentMeterEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = EquipmentMeterEntry
        fields = '__all__'
        read_only_fields = ['recorded_at']


class CalibrationRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = CalibrationRecord
        fields = '__all__'
        read_only_fields = ['created_at']


class EquipmentCheckoutSerializer(serializers.ModelSerializer):
    checked_out_to_name = serializers.CharField(source='checked_out_to.full_name', read_only=True)
    equipment_name = serializers.CharField(source='equipment.display_name', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    duration_hours = serializers.FloatField(read_only=True)

    class Meta:
        model = EquipmentCheckout
        fields = '__all__'


class EquipmentSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    assigned_to_name = serializers.SerializerMethodField()
    assigned_vehicle_name = serializers.CharField(source='assigned_vehicle.display_name', read_only=True)
    display_name = serializers.CharField(read_only=True)
    is_checked_out = serializers.BooleanField(read_only=True)
    calibration_overdue = serializers.BooleanField(read_only=True)
    calibration_due_soon = serializers.BooleanField(read_only=True)

    class Meta:
        model = Equipment
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def get_assigned_to_name(self, obj):
        if obj.assigned_to:
            return f'{obj.assigned_to.first_name} {obj.assigned_to.last_name}'
        return None


class EquipmentCheckoutCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = EquipmentCheckout
        fields = ['equipment', 'checked_out_to', 'expected_return_at', 'notes']
