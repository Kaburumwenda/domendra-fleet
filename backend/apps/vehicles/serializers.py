import requests
from django.conf import settings
from rest_framework import serializers

from .models import (
    CustomField, CustomFieldValue, FleetGroup, MeterEntry, Vehicle,
    VehicleBodyType, VehicleMake, VehicleModel, VehicleType,
)


class FleetGroupSerializer(serializers.ModelSerializer):
    vehicle_count = serializers.IntegerField(read_only=True, required=False)

    class Meta:
        model = FleetGroup
        fields = '__all__'


class VehicleMakeSerializer(serializers.ModelSerializer):
    model_count = serializers.SerializerMethodField()

    class Meta:
        model = VehicleMake
        fields = ['id', 'name', 'model_count', 'created_at', 'updated_at']

    def get_model_count(self, obj):
        return obj.models.count()


class VehicleBodyTypeSerializer(serializers.ModelSerializer):
    model_count = serializers.SerializerMethodField()

    class Meta:
        model = VehicleBodyType
        fields = ['id', 'label', 'value', 'icon', 'model_count', 'created_at', 'updated_at']

    def get_model_count(self, obj):
        return obj.models.count()


class VehicleModelSerializer(serializers.ModelSerializer):
    make_name = serializers.CharField(source='make.name', read_only=True)
    body_type_label = serializers.CharField(source='body_type.label', read_only=True)
    body_type_value = serializers.CharField(source='body_type.value', read_only=True)

    class Meta:
        model = VehicleModel
        fields = ['id', 'make', 'body_type', 'name', 'make_name', 'body_type_label', 'body_type_value', 'created_at', 'updated_at']


class VehicleTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleType
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class VehicleSerializer(serializers.ModelSerializer):
    group_name = serializers.CharField(source='group.name', read_only=True)
    assigned_driver_name = serializers.SerializerMethodField()
    lessor_name = serializers.CharField(source='lessor.display_name', read_only=True)
    display_name = serializers.CharField(read_only=True)
    annual_depreciation = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)
    current_book_value = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)
    rental_status = serializers.SerializerMethodField()
    rental_agreement_no = serializers.SerializerMethodField()
    rental_customer_name = serializers.SerializerMethodField()

    class Meta:
        model = Vehicle
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def get_assigned_driver_name(self, obj):
        if obj.assigned_driver:
            return f'{obj.assigned_driver.first_name} {obj.assigned_driver.last_name}'
        return None

    def get_rental_status(self, obj):
        """Return 'on_rent' if the vehicle has an active or overdue rental agreement."""
        active = obj.rental_agreements.filter(status__in=['active', 'overdue']).first()
        return 'on_rent' if active else 'available'

    def get_rental_agreement_no(self, obj):
        """Return the agreement number of the active/overdue rental, if any."""
        active = obj.rental_agreements.filter(status__in=['active', 'overdue']).first()
        return active.agreement_no if active else None

    def get_rental_customer_name(self, obj):
        """Return the customer name of the active/overdue rental, if any."""
        active = obj.rental_agreements.filter(status__in=['active', 'overdue']).first()
        return active.customer.full_name if active else None


class MeterEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = MeterEntry
        fields = '__all__'
        read_only_fields = ['recorded_at']


class CustomFieldSerializer(serializers.ModelSerializer):
    display_label = serializers.CharField(read_only=True)

    class Meta:
        model = CustomField
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def validate_choices(self, value):
        if self.initial_data.get('field_type') == 'select' and not value:
            raise serializers.ValidationError('Select fields require at least one choice.')
        return value


class CustomFieldValueSerializer(serializers.ModelSerializer):
    field_name = serializers.CharField(source='field.name', read_only=True)
    field_label = serializers.CharField(source='field.display_label', read_only=True)
    field_type = serializers.CharField(source='field.field_type', read_only=True)

    class Meta:
        model = CustomFieldValue
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def validate(self, attrs):
        field = attrs.get('field') or getattr(self.instance, 'field', None)
        value = attrs.get('value', getattr(self.instance, 'value', ''))
        if field and field.is_required and not value:
            raise serializers.ValidationError({'value': f'{field.display_label} is required.'})
        if field and field.field_type == 'boolean' and value not in ('', 'true', 'false', 'True', 'False'):
            raise serializers.ValidationError({'value': 'Boolean fields accept true/false only.'})
        return attrs


class VinDecodeSerializer(serializers.Serializer):
    vin = serializers.CharField(max_length=17)

    def validate_vin(self, value):
        value = value.upper().strip()
        if len(value) != 17:
            raise serializers.ValidationError('VIN must be exactly 17 characters.')
        return value

    def save(self):
        vin = self.validated_data['vin']
        url = f'{settings.VIN_API_BASE_URL}/vehicles/DecodeVin/{vin}'
        resp = requests.get(url, params={'format': 'json'}, timeout=10)
        resp.raise_for_status()
        results = resp.json().get('Results', [])
        decoded = {}
        for item in results:
            key = item.get('Variable', '')
            val = item.get('Value', '')
            if val and val != 'Not Applicable':
                decoded[key] = val
        return {
            'vin': vin,
            'make': decoded.get('Make', ''),
            'model': decoded.get('Model', ''),
            'year': decoded.get('Model Year', ''),
            'engine': decoded.get('Engine Model', ''),
            'transmission': decoded.get('Transmission Style', ''),
            'fuel_type': decoded.get('Fuel Type - Primary', ''),
            'weight_rating': decoded.get('GVWR', ''),
        }
