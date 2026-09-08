from rest_framework import serializers
from django.http import QueryDict

from .models import (
    Contact,
    DriverProfile,
    DriverViolation,
    DriverDrugTest,
    DriverTraining,
    DriverHoursOfService,
    DriverAssignment,
    DriverNote,
    VendorProfile,
)


class DriverViolationSerializer(serializers.ModelSerializer):
    violation_type_label = serializers.CharField(source='get_violation_type_display', read_only=True)
    severity_label = serializers.CharField(source='get_severity_display', read_only=True)

    class Meta:
        model = DriverViolation
        fields = '__all__'


class DriverDrugTestSerializer(serializers.ModelSerializer):
    test_type_label = serializers.CharField(source='get_test_type_display', read_only=True)
    result_label = serializers.CharField(source='get_result_display', read_only=True)

    class Meta:
        model = DriverDrugTest
        fields = '__all__'


class DriverTrainingSerializer(serializers.ModelSerializer):
    status_label = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = DriverTraining
        fields = '__all__'


class DriverHoursOfServiceSerializer(serializers.ModelSerializer):
    duty_status_label = serializers.CharField(source='get_duty_status_display', read_only=True)

    class Meta:
        model = DriverHoursOfService
        fields = '__all__'


class DriverAssignmentSerializer(serializers.ModelSerializer):
    vehicle_label = serializers.SerializerMethodField()

    class Meta:
        model = DriverAssignment
        fields = '__all__'

    def get_vehicle_label(self, obj):
        if obj.vehicle_id:
            return str(obj.vehicle)
        return None


class DriverNoteSerializer(serializers.ModelSerializer):
    category_label = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = DriverNote
        fields = '__all__'


class DriverProfileSerializer(serializers.ModelSerializer):
    license_class_label = serializers.CharField(source='get_license_class_display', read_only=True)
    mvr_status_label = serializers.CharField(source='get_mvr_status_display', read_only=True)
    employment_status_label = serializers.CharField(source='get_employment_status_display', read_only=True)
    violations = DriverViolationSerializer(many=True, read_only=True)
    drug_tests = DriverDrugTestSerializer(many=True, read_only=True)
    trainings = DriverTrainingSerializer(many=True, read_only=True)
    hos_logs = DriverHoursOfServiceSerializer(many=True, read_only=True)
    assignments = DriverAssignmentSerializer(many=True, read_only=True)
    notes_log = DriverNoteSerializer(many=True, read_only=True)

    class Meta:
        model = DriverProfile
        fields = '__all__'
        read_only_fields = ['contact']


class VendorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendorProfile
        fields = '__all__'


class ContactSerializer(serializers.ModelSerializer):
    driver_profile = DriverProfileSerializer(required=False, allow_null=True)
    vendor_profile = VendorProfileSerializer(required=False, allow_null=True)
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = Contact
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def to_internal_value(self, data):
        # When the request is multipart/form-data (e.g. photo upload), nested
        # objects and JSON fields arrive as JSON-encoded strings.  Parse them
        # back into native types before DRF validation runs.
        import json
        # Work on a mutable copy so we never touch the original request data.
        # If it's a QueryDict, flatten to a plain dict so nested-serializer
        # field.get_value() calls .get() (not .getlist()) and sees a dict
        # rather than a one-element list wrapper.
        if isinstance(data, QueryDict):
            data = {k: data.get(k) for k in data}
        else:
            try:
                data = data.copy() if hasattr(data, 'copy') else dict(data)
            except Exception:
                data = dict(data)
        for key in ('driver_profile', 'vendor_profile'):
            val = data.get(key)
            if isinstance(val, str) and val.strip():
                try:
                    data[key] = json.loads(val)
                except (json.JSONDecodeError, ValueError):
                    pass  # let DRF report the validation error
        return super().to_internal_value(data)

    def create(self, validated_data):
        driver_data = validated_data.pop('driver_profile', None)
        vendor_data = validated_data.pop('vendor_profile', None)
        contact = Contact.objects.create(**validated_data)
        if driver_data:
            DriverProfile.objects.create(contact=contact, **driver_data)
        if vendor_data:
            VendorProfile.objects.create(contact=contact, **vendor_data)
        return contact

    def update(self, instance, validated_data):
        driver_data = validated_data.pop('driver_profile', None)
        vendor_data = validated_data.pop('vendor_profile', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if driver_data is not None:
            DriverProfile.objects.update_or_create(contact=instance, defaults=driver_data)
        if vendor_data is not None:
            VendorProfile.objects.update_or_create(contact=instance, defaults=vendor_data)
        return instance
