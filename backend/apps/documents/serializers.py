from rest_framework import serializers

from .models import Document


class DocumentSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.CharField(source='uploaded_by.full_name', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_expiring_soon = serializers.BooleanField(read_only=True)
    days_to_expiry = serializers.IntegerField(read_only=True)
    file_extension = serializers.CharField(read_only=True)
    file_type_icon = serializers.CharField(read_only=True)
    file_size_display = serializers.CharField(read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True, default='')
    contact_name = serializers.CharField(source='contact.full_name', read_only=True, default='')

    class Meta:
        model = Document
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'file_size', 'uploaded_by']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['uploaded_by'] = request.user
        file = validated_data.get('file')
        if file:
            validated_data['file_size'] = file.size
        return super().create(validated_data)
