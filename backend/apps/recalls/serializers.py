from rest_framework import serializers

from .models import Recall, RecallVehicle


class RecallVehicleSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    is_resolved = serializers.BooleanField(read_only=True)
    days_open = serializers.IntegerField(read_only=True)

    class Meta:
        model = RecallVehicle
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class RecallSerializer(serializers.ModelSerializer):
    vehicles = RecallVehicleSerializer(many=True, read_only=True)
    affected_count = serializers.IntegerField(source='vehicles.count', read_only=True, required=False)
    resolved_count = serializers.SerializerMethodField()

    class Meta:
        model = Recall
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def get_resolved_count(self, obj):
        return obj.vehicles.filter(status=RecallVehicle.ResolutionStatus.RESOLVED).count()
