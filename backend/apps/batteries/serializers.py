from rest_framework import serializers

from .models import Battery, BatteryReading, BatteryMovement, ChargeCycle, BatteryReplacement


class BatteryReadingSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    battery_serial = serializers.CharField(source='battery.serial_number', read_only=True)
    health_pct = serializers.FloatField(read_only=True)

    class Meta:
        model = BatteryReading
        fields = '__all__'
        read_only_fields = ['created_at']


class BatteryMovementSerializer(serializers.ModelSerializer):
    from_vehicle_name = serializers.CharField(source='from_vehicle.display_name', read_only=True)
    to_vehicle_name = serializers.CharField(source='to_vehicle.display_name', read_only=True)
    battery_serial = serializers.CharField(source='battery.serial_number', read_only=True)

    class Meta:
        model = BatteryMovement
        fields = '__all__'
        read_only_fields = ['created_at']


class ChargeCycleSerializer(serializers.ModelSerializer):
    battery_serial = serializers.CharField(source='battery.serial_number', read_only=True)

    class Meta:
        model = ChargeCycle
        fields = '__all__'
        read_only_fields = ['created_at']


class BatteryReplacementSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    battery_serial = serializers.CharField(source='battery.serial_number', read_only=True)
    old_battery_serial = serializers.CharField(source='old_battery.serial_number', read_only=True)

    class Meta:
        model = BatteryReplacement
        fields = '__all__'
        read_only_fields = ['created_at']


class BatterySerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    vehicle_license_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    vehicle_type = serializers.CharField(source='vehicle.vehicle_type', read_only=True)
    warranty_expired = serializers.BooleanField(read_only=True)
    warranty_days_left = serializers.IntegerField(read_only=True)
    age_months = serializers.IntegerField(read_only=True)
    needs_replacement = serializers.BooleanField(read_only=True)
    health_pct = serializers.FloatField(read_only=True)
    last_voltage = serializers.FloatField(read_only=True)
    last_voltage_date = serializers.DateField(read_only=True)
    cycle_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Battery
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
