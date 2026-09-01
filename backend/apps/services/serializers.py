from rest_framework import serializers

from .models import Service, VendorRating


class VendorRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendorRating
        fields = '__all__'
        read_only_fields = ['overall_rating', 'created_at']


class ServiceSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    vendor_name = serializers.CharField(source='vendor.full_name', read_only=True)
    technician_name = serializers.CharField(source='technician.full_name', read_only=True)
    rating = VendorRatingSerializer(read_only=True)

    class Meta:
        model = Service
        fields = '__all__'
        read_only_fields = ['created_at', 'technician']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['technician'] = request.user
        return super().create(validated_data)
