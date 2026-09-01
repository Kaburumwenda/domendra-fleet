from decimal import Decimal

from rest_framework import serializers

from .models import FinancingLoan, FinancingPayment


class FinancingPaymentSerializer(serializers.ModelSerializer):
    loan_no = serializers.CharField(source='loan.loan_no', read_only=True)
    vehicle_name = serializers.CharField(source='loan.vehicle.display_name', read_only=True)
    outstanding = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    evidence_file_url = serializers.SerializerMethodField()

    class Meta:
        model = FinancingPayment
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

    def get_evidence_file_url(self, obj):
        if obj.evidence_file:
            return obj.evidence_file.url
        return None


class FinancingLoanSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    vehicle_license_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    interest_type_display = serializers.CharField(source='get_interest_type_display', read_only=True)
    payment_count_total = serializers.IntegerField(read_only=True)
    payment_count_paid = serializers.IntegerField(read_only=True)
    payment_count_pending = serializers.IntegerField(read_only=True)
    total_paid = serializers.DecimalField(read_only=True, max_digits=14, decimal_places=2)
    total_interest_paid = serializers.DecimalField(read_only=True, max_digits=14, decimal_places=2)
    principal_paid = serializers.DecimalField(read_only=True, max_digits=14, decimal_places=2)
    outstanding_principal = serializers.DecimalField(read_only=True, max_digits=14, decimal_places=2)
    outstanding_balance = serializers.DecimalField(read_only=True, max_digits=14, decimal_places=2)
    total_payable = serializers.DecimalField(read_only=True, max_digits=14, decimal_places=2)
    progress_pct = serializers.DecimalField(read_only=True, max_digits=5, decimal_places=2)
    ltv_ratio = serializers.DecimalField(read_only=True, max_digits=6, decimal_places=2)
    next_due_date = serializers.DateField(read_only=True, allow_null=True)
    next_due_amount = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)
    is_overdue = serializers.BooleanField(read_only=True)
    days_past_due = serializers.IntegerField(read_only=True)

    class Meta:
        model = FinancingLoan
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'loan_no', 'balance_due']

    def validate(self, data):
        # On create, vehicle is required; on partial update it may be absent
        vehicle = data.get('vehicle') or (self.instance.vehicle if self.instance else None)
        if not vehicle:
            raise serializers.ValidationError({'vehicle': 'Vehicle is required.'})
        if data.get('principal_amount', 0) is not None and Decimal(str(data.get('principal_amount', 0))) <= 0:
            if not self.instance:
                raise serializers.ValidationError({'principal_amount': 'Principal amount must be greater than zero.'})
        if data.get('tenor_months', 0) is not None and int(data.get('tenor_months', 0) or 0) <= 0:
            if not self.instance:
                raise serializers.ValidationError({'tenor_months': 'Tenor must be greater than zero months.'})
        return data
