from rest_framework import serializers

from .models import Job, RouteStop, VehicleAssignment


class RouteStopSerializer(serializers.ModelSerializer):
    class Meta:
        model = RouteStop
        fields = '__all__'
        read_only_fields = ['created_at']


class JobSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    stops = RouteStopSerializer(many=True, read_only=True)
    eta_minutes = serializers.IntegerField(read_only=True)
    is_on_schedule = serializers.BooleanField(read_only=True)

    class Meta:
        model = Job
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'actual_start', 'actual_end']


class VehicleAssignmentSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)

    class Meta:
        model = VehicleAssignment
        fields = '__all__'
        read_only_fields = ['assigned_at']
