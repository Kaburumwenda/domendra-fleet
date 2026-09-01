from rest_framework import serializers

from .models import BayReservation, GarageBay


class GarageBaySerializer(serializers.ModelSerializer):
    is_occupied = serializers.BooleanField(read_only=True)

    class Meta:
        model = GarageBay
        fields = '__all__'
        read_only_fields = ['created_at']


class BayReservationSerializer(serializers.ModelSerializer):
    bay_name = serializers.CharField(source='bay.name', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    duration_hours = serializers.FloatField(read_only=True)

    class Meta:
        model = BayReservation
        fields = '__all__'
        read_only_fields = ['created_at']
