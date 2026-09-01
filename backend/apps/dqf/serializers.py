from rest_framework import serializers

from .models import DqfCheck, DriverQualificationFile


class DqfCheckSerializer(serializers.ModelSerializer):
    is_expired = serializers.BooleanField(read_only=True)
    is_complete = serializers.BooleanField(read_only=True)
    check_type_label = serializers.CharField(source='get_check_type_display', read_only=True)
    status_label = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DqfCheck
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class DriverQualificationFileSerializer(serializers.ModelSerializer):
    driver_name = serializers.SerializerMethodField()
    completion_pct = serializers.IntegerField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    checks = DqfCheckSerializer(many=True, read_only=True)

    class Meta:
        model = DriverQualificationFile
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def get_driver_name(self, obj):
        return f'{obj.driver.first_name} {obj.driver.last_name}'
