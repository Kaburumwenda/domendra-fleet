from rest_framework import serializers

from .models import Location


class LocationSerializer(serializers.ModelSerializer):
    vehicle_count = serializers.IntegerField(read_only=True, required=False)

    class Meta:
        model = Location
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def validate(self, attrs):
        shape = attrs.get('shape', getattr(self.instance, 'shape', Location.GeofenceShape.CIRCLE))
        is_geofence = attrs.get('is_geofence', getattr(self.instance, 'is_geofence', False))
        if is_geofence and shape == Location.GeofenceShape.CIRCLE:
            radius = attrs.get('radius_meters', getattr(self.instance, 'radius_meters', None))
            if not radius:
                raise serializers.ValidationError({'radius_meters': 'Radius is required for circle geofences.'})
        if is_geofence and shape == Location.GeofenceShape.POLYGON:
            polygon = attrs.get('polygon', getattr(self.instance, 'polygon', []))
            if not polygon or len(polygon) < 3:
                raise serializers.ValidationError({'polygon': 'Polygon geofences require at least 3 points.'})
        return attrs
