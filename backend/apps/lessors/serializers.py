from decimal import Decimal

from django.db.models import Sum
from rest_framework import serializers

from .models import Lessor, LessorContract, LessorDocument, LessorPayment


class LessorSerializer(serializers.ModelSerializer):
    display_name = serializers.CharField(read_only=True)
    active_lease_count = serializers.IntegerField(read_only=True)
    vehicle_count = serializers.IntegerField(read_only=True)
    total_lease_value = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    monthly_earnings = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    total_deposit_held = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True,
    )
    contract_count = serializers.SerializerMethodField()
    unpaid_amount = serializers.SerializerMethodField()

    class Meta:
        model = Lessor
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def validate(self, attrs):
        lessor_type = attrs.get('lessor_type', getattr(self.instance, 'lessor_type', None))
        if lessor_type == Lessor.LessorType.INDIVIDUAL:
            instance = self.instance
            first = attrs.get('first_name', getattr(instance, 'first_name', '') if instance else '')
            last = attrs.get('last_name', getattr(instance, 'last_name', '') if instance else '')
            if not first and not last:
                raise serializers.ValidationError('Individual lessors require at least a first or last name.')
        elif lessor_type == Lessor.LessorType.COMPANY:
            instance = self.instance
            company = attrs.get('company_name', getattr(instance, 'company_name', '') if instance else '')
            if not company:
                raise serializers.ValidationError('Company lessors require a company name.')
        return attrs

    def get_contract_count(self, obj):
        return obj.contracts.count()

    def get_unpaid_amount(self, obj):
        total = obj.payments.filter(status__in=['pending', 'overdue']).aggregate(
            t=Sum('amount')
        )['t']
        return total or Decimal('0')


class LessorContractSerializer(serializers.ModelSerializer):
    lessor_name = serializers.CharField(source='lessor.display_name', read_only=True)
    is_active_now = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True, allow_null=True)
    total_value = serializers.DecimalField(
        max_digits=14, decimal_places=2, read_only=True,
    )

    class Meta:
        model = LessorContract
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class LessorPaymentSerializer(serializers.ModelSerializer):
    lessor_name = serializers.CharField(source='lessor.display_name', read_only=True)
    contract_title = serializers.CharField(source='contract.title', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)

    class Meta:
        model = LessorPayment
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class LessorDocumentSerializer(serializers.ModelSerializer):
    lessor_name = serializers.CharField(source='lessor.display_name', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)

    class Meta:
        model = LessorDocument
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
