from rest_framework import serializers

from apps.vehicles.models import Vehicle as VehicleModel

from .models import (
    Customer,
    DigitalSignature,
    DriverHireRate,
    InspectionCheck,
    Invoice,
    RentalAgreement,
    RentalCharge,
    RentalPayment,
    VehicleDamage,
    VehicleCheck,
    VehiclePricing,
)


class CustomerSerializer(serializers.ModelSerializer):
    agreements_count = serializers.IntegerField(source='agreements.count', read_only=True)

    class Meta:
        model = Customer
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class RentalChargeSerializer(serializers.ModelSerializer):
    class Meta:
        model = RentalCharge
        fields = '__all__'
        read_only_fields = ['created_at']


class VehicleDamageSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleDamage
        fields = '__all__'
        read_only_fields = ['recorded_at']


class DigitalSignatureSerializer(serializers.ModelSerializer):
    class Meta:
        model = DigitalSignature
        fields = '__all__'
        read_only_fields = ['signed_at']


class VehicleCheckSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleCheck
        fields = '__all__'
        read_only_fields = ['checked_at']


class InspectionCheckSerializer(serializers.ModelSerializer):
    class Meta:
        model = InspectionCheck
        fields = '__all__'
        read_only_fields = ['checked_at']


class InvoiceSerializer(serializers.ModelSerializer):
    agreement_no = serializers.SerializerMethodField()
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_type = serializers.CharField(source='customer.customer_type', read_only=True)
    customer_email = serializers.CharField(source='customer.email', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    invoice_to_name = serializers.SerializerMethodField()
    vehicle_display = serializers.SerializerMethodField()
    vehicle_license_plate = serializers.SerializerMethodField()
    damages = serializers.SerializerMethodField()

    class Meta:
        model = Invoice
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'invoice_no', 'balance_due']

    def get_invoice_to_name(self, obj):
        if obj.invoice_to:
            return obj.invoice_to.get('name') or ''
        return ''

    def get_agreement_no(self, obj):
        if obj.agreement_id:
            return obj.agreement.agreement_no
        return obj.agreements[0].get('agreement_no') if obj.agreements else None

    def get_vehicle_display(self, obj):
        if obj.agreement_id and obj.agreement.vehicle_id:
            return obj.agreement.vehicle.display_name
        return None

    def get_vehicle_license_plate(self, obj):
        if obj.agreement_id and obj.agreement.vehicle_id:
            return obj.agreement.vehicle.license_plate
        return None

    def get_damages(self, obj):
        from .models import VehicleDamage
        agreement_ids = []
        if obj.agreement_id:
            agreement_ids.append(obj.agreement_id)
        if obj.agreements:
            agreement_ids.extend(a.get('id') for a in obj.agreements if a.get('id'))
        if not agreement_ids:
            return []
        return [
            {
                'location': d.location,
                'description': d.description,
                'severity': d.severity,
                'severity_display': d.get_severity_display(),
                'repair_cost': float(d.repair_cost or 0),
                'agreement_no': d.agreement.agreement_no if d.agreement_id else None,
            }
            for d in VehicleDamage.objects.filter(agreement_id__in=agreement_ids).select_related('agreement')
        ]


class RentalPaymentSerializer(serializers.ModelSerializer):
    agreement_no = serializers.CharField(source='agreement.agreement_no', read_only=True)
    customer_name = serializers.CharField(source='agreement.customer.full_name', read_only=True)
    vehicle_display = serializers.CharField(source='agreement.vehicle.display_name', read_only=True)

    class Meta:
        model = RentalPayment
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


def _payment_summary(agreement):
    """Return (paid, balance, status) for an agreement."""
    from decimal import Decimal as D
    total = D(agreement.total_amount or 0)
    completed = agreement.payments.filter(status='completed')
    paid = sum((D(p.amount or 0) for p in completed), D(0))
    balance = total - paid
    if balance <= 0:
        pay_status = 'paid'
    elif paid > 0:
        pay_status = 'partial'
    else:
        pay_status = 'unpaid'
    return paid, balance, pay_status


class RentalAgreementSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_type = serializers.CharField(source='customer.customer_type', read_only=True)
    customer_email = serializers.CharField(source='customer.email', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    customer_address = serializers.CharField(source='customer.address', read_only=True)
    customer_id_number = serializers.CharField(source='customer.id_number', read_only=True)
    customer_driving_license = serializers.CharField(source='customer.driving_license_no', read_only=True)
    vehicle_display = serializers.CharField(source='vehicle.display_name', read_only=True)
    vehicle_license_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    vehicle_type = serializers.CharField(source='vehicle.vehicle_type', read_only=True)
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    charges = RentalChargeSerializer(many=True, read_only=True)
    damages = VehicleDamageSerializer(many=True, read_only=True)
    signatures = DigitalSignatureSerializer(many=True, read_only=True)
    vehicle_checks = VehicleCheckSerializer(many=True, read_only=True)
    inspection_checks = InspectionCheckSerializer(many=True, read_only=True)
    payments = RentalPaymentSerializer(many=True, read_only=True)
    amount_paid = serializers.SerializerMethodField()
    balance_due = serializers.SerializerMethodField()
    payment_status = serializers.SerializerMethodField()

    class Meta:
        model = RentalAgreement
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'agreement_no']

    def get_amount_paid(self, obj):
        return str(_payment_summary(obj)[0])

    def get_balance_due(self, obj):
        return str(_payment_summary(obj)[1])

    def get_payment_status(self, obj):
        return _payment_summary(obj)[2]


class RentalAgreementListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list view."""
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_type = serializers.CharField(source='customer.customer_type', read_only=True)
    vehicle_display = serializers.CharField(source='vehicle.display_name', read_only=True)
    vehicle_license_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    vehicle_type = serializers.CharField(source='vehicle.vehicle_type', read_only=True)
    amount_paid = serializers.SerializerMethodField()
    balance_due = serializers.SerializerMethodField()
    payment_status = serializers.SerializerMethodField()

    class Meta:
        model = RentalAgreement
        fields = [
            'id', 'agreement_no', 'customer', 'customer_name', 'customer_type',
            'vehicle', 'vehicle_display', 'vehicle_license_plate', 'vehicle_type',
            'status', 'rate_period', 'start_datetime', 'end_datetime',
            'actual_return_datetime', 'total_amount', 'pickup_location', 'dropoff_location',
            'amount_paid', 'balance_due', 'payment_status',
            'created_at',
        ]
        read_only_fields = ['created_at', 'agreement_no']

    def get_amount_paid(self, obj):
        return str(_payment_summary(obj)[0])

    def get_balance_due(self, obj):
        return str(_payment_summary(obj)[1])

    def get_payment_status(self, obj):
        return _payment_summary(obj)[2]


class VehiclePricingSerializer(serializers.ModelSerializer):
    """Serializer for reusable vehicle pricing plans."""
    vehicle_group_name = serializers.CharField(source='vehicle_group.name', read_only=True)
    vehicle_type_name = serializers.CharField(source='vehicle_type.name', read_only=True)
    vehicle_type_icon = serializers.CharField(source='vehicle_type.icon', read_only=True)
    vehicle_type_color = serializers.CharField(source='vehicle_type.color', read_only=True)
    vehicle_ids = serializers.PrimaryKeyRelatedField(
        source='vehicles', many=True, queryset=VehicleModel.objects.all(),
        required=False,
    )
    vehicle_list = serializers.SerializerMethodField()

    class Meta:
        model = VehiclePricing
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def get_vehicle_list(self, obj):
        return [{'id': v.id, 'display_name': v.display_name} for v in obj.vehicles.all()]

    def create(self, validated_data):
        vehicle_ids = validated_data.pop('vehicles', None)
        instance = super().create(validated_data)
        if vehicle_ids is not None:
            instance.vehicles.set(vehicle_ids)
        return instance

    def update(self, instance, validated_data):
        vehicle_ids = validated_data.pop('vehicles', None)
        instance = super().update(instance, validated_data)
        if vehicle_ids is not None:
            instance.vehicles.set(vehicle_ids)
        return instance


class DriverHireRateSerializer(serializers.ModelSerializer):
    """Serializer for global driver hire rate plans."""
    driver_name = serializers.CharField(source='driver.full_name', read_only=True, default='')
    is_currently_active = serializers.BooleanField(source='is_active', read_only=True)

    class Meta:
        model = DriverHireRate
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
