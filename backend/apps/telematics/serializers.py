from rest_framework import serializers

from .models import GeofenceEvent, TelematicsAlert, TelematicsDevice, Trip, VehicleLocation


class TelematicsDeviceSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    is_stale = serializers.BooleanField(read_only=True)

    class Meta:
        model = TelematicsDevice
        fields = '__all__'
        read_only_fields = ['last_latitude', 'last_longitude', 'last_heading', 'last_speed', 'last_ignition_on', 'last_reported_at', 'created_at', 'updated_at']


class VehicleLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleLocation
        fields = '__all__'


class TripSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    driver_name = serializers.SerializerMethodField()
    average_speed = serializers.FloatField(read_only=True)

    class Meta:
        model = Trip
        fields = '__all__'
        read_only_fields = ['created_at']

    def get_driver_name(self, obj):
        if obj.driver:
            return f'{obj.driver.first_name} {obj.driver.last_name}'
        return None


class GeofenceEventSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    location_name = serializers.CharField(source='location.name', read_only=True)

    class Meta:
        model = GeofenceEvent
        fields = '__all__'
        read_only_fields = ['created_at']


class TelematicsAlertSerializer(serializers.ModelSerializer):
    device_name = serializers.CharField(source='device.serial_number', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    acknowledged_by_name = serializers.CharField(source='acknowledged_by.get_full_name', read_only=True)

    class Meta:
        model = TelematicsAlert
        fields = '__all__'
        read_only_fields = ['created_at', 'acknowledged_at', 'acknowledged_by']
