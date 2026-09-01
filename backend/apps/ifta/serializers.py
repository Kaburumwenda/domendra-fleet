from rest_framework import serializers

from .models import FuelPurchase, IftaQuarter, Jurisdiction, TripLog


class JurisdictionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Jurisdiction
        fields = '__all__'


class TripLogSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    driver_name = serializers.SerializerMethodField()
    jurisdiction_code = serializers.CharField(source='jurisdiction.code', read_only=True)
    jurisdiction_name = serializers.CharField(source='jurisdiction.name', read_only=True)
    distance_miles = serializers.FloatField(read_only=True)

    class Meta:
        model = TripLog
        fields = '__all__'
        read_only_fields = ['created_at']

    def get_driver_name(self, obj):
        if obj.driver:
            return f'{obj.driver.first_name} {obj.driver.last_name}'
        return None


class FuelPurchaseSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    jurisdiction_code = serializers.CharField(source='jurisdiction.code', read_only=True)
    price_per_gallon = serializers.FloatField(read_only=True)

    class Meta:
        model = FuelPurchase
        fields = '__all__'
        read_only_fields = ['created_at']


class IftaQuarterSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    label = serializers.CharField(read_only=True)

    class Meta:
        model = IftaQuarter
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
