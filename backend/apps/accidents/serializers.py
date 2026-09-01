from rest_framework import serializers

from .models import AccidentReport, AccidentWitness, InsuranceClaim, AccidentPhoto


class AccidentPhotoSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = AccidentPhoto
        fields = '__all__'
        read_only_fields = ['created_at']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image:
            url = obj.image.url
            if request:
                return request.build_absolute_uri(url)
            return url
        return ''


class AccidentWitnessSerializer(serializers.ModelSerializer):
    class Meta:
        model = AccidentWitness
        fields = '__all__'
        read_only_fields = ['created_at']


class InsuranceClaimSerializer(serializers.ModelSerializer):
    accident_rate = serializers.FloatField(read_only=True)

    class Meta:
        model = InsuranceClaim
        fields = '__all__'
        read_only_fields = ['created_at']


class AccidentReportSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    client_name = serializers.CharField(source='client.full_name', read_only=True)
    witnesses = AccidentWitnessSerializer(many=True, read_only=True)
    accident_photos = AccidentPhotoSerializer(many=True, read_only=True)
    insurance_claim = InsuranceClaimSerializer(read_only=True)

    class Meta:
        model = AccidentReport
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'created_by']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['created_by'] = request.user
        return super().create(validated_data)
