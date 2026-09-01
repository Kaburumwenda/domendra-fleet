from rest_framework import serializers

from .models import InspectionForm, InspectionItem, InspectionReport, InspectionResponse


class InspectionItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = InspectionItem
        fields = '__all__'


class InspectionFormSerializer(serializers.ModelSerializer):
    items = InspectionItemSerializer(many=True, read_only=True)
    item_count = serializers.IntegerField(source='items.count', read_only=True)

    class Meta:
        model = InspectionForm
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class InspectionResponseSerializer(serializers.ModelSerializer):
    item_label = serializers.CharField(source='item.label', read_only=True)
    item_type = serializers.CharField(source='item.item_type', read_only=True)
    is_critical = serializers.BooleanField(source='item.is_critical', read_only=True)

    class Meta:
        model = InspectionResponse
        fields = '__all__'


class InspectionReportSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    form_name = serializers.CharField(source='form.name', read_only=True, default='')
    responses = InspectionResponseSerializer(many=True, read_only=True)

    class Meta:
        model = InspectionReport
        fields = '__all__'
        read_only_fields = ['submitted_at', 'updated_at', 'driver']


class InspectionReportCreateSerializer(serializers.ModelSerializer):
    responses = InspectionResponseSerializer(many=True, write_only=True, required=False)

    class Meta:
        model = InspectionReport
        fields = ['vehicle', 'form', 'status', 'notes', 'latitude', 'longitude', 'odometer_reading', 'responses']

    def create(self, validated_data):
        responses_data = validated_data.pop('responses', [])
        request = self.context.get('request')
        if request and request.user:
            validated_data['driver'] = request.user
        report = InspectionReport.objects.create(**validated_data)
        has_critical_fail = False
        for resp_data in responses_data:
            resp = InspectionResponse.objects.create(report=report, **resp_data)
            if resp.is_fail and resp.item.is_critical:
                has_critical_fail = True
        if has_critical_fail and report.status != InspectionReport.Status.FAIL:
            report.status = InspectionReport.Status.FAIL
            report.save(update_fields=['status'])
        return report
