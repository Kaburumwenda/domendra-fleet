from rest_framework import serializers

from .models import ChargeSchedule, ChargingSession, FuelBudget, FuelCard, FuelFraudAlert, FuelTransaction, IdlingEvent


class FuelCardSerializer(serializers.ModelSerializer):
    class Meta:
        model = FuelCard
        fields = '__all__'
        read_only_fields = ['created_at']


class FuelTransactionSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    price_per_unit = serializers.FloatField(read_only=True)
    mpg = serializers.FloatField(read_only=True)
    fraud_alert_count = serializers.IntegerField(read_only=True, required=False)
    # Manual fuel entries (typed in the UI) have no card-provider transaction id.
    # The model's unique_together('fuel_card', 'provider_transaction_id') makes
    # DRF auto-add a UniqueTogetherValidator that marks both fields required; for
    # manual entries we declare them explicitly so the validator doesn't force them.
    fuel_card = serializers.PrimaryKeyRelatedField(
        queryset=FuelCard.objects.all(), required=False, allow_null=True, default=None
    )
    provider_transaction_id = serializers.CharField(required=False, allow_blank=True, default='')

    class Meta:
        model = FuelTransaction
        fields = '__all__'
        read_only_fields = ['created_at']
        extra_kwargs = {
            'odometer_reading': {'required': False, 'allow_null': True},
        }

    def validate(self, attrs):
        # Require station_name and station_location for manual entries.
        station_name = attrs.get('station_name', '')
        if not station_name or not station_name.strip():
            raise serializers.ValidationError({'station_name': 'Station name is required.'})
        station_location = attrs.get('station_location', '')
        if not station_location or not station_location.strip():
            raise serializers.ValidationError({'station_location': 'Station location is required.'})

        # Only enforce the card/provider uniqueness when a fuel card is present.
        # Manual entries without a card should never trip the unique constraint.
        fuel_card = attrs.get('fuel_card')
        provider_tx = attrs.get('provider_transaction_id', '')
        if not fuel_card:
            attrs['fuel_card'] = None
            attrs['provider_transaction_id'] = provider_tx or ''
        return attrs

    def create(self, validated_data):
        tx = super().create(validated_data)
        from .services import run_fraud_checks
        run_fraud_checks(tx)
        return tx


class ChargingSessionSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    duration_hours = serializers.FloatField(read_only=True)
    kwh_per_hour = serializers.FloatField(read_only=True)

    class Meta:
        model = ChargingSession
        fields = '__all__'
        read_only_fields = ['created_at']


class FuelFraudAlertSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='transaction.vehicle.display_name', read_only=True)
    transaction_date = serializers.DateTimeField(source='transaction.date', read_only=True)
    action_status_display = serializers.CharField(source='get_action_status_display', read_only=True)
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)

    class Meta:
        model = FuelFraudAlert
        fields = '__all__'
        read_only_fields = ['created_at', 'transaction', 'resolved_by', 'resolved_at']


class IdlingEventSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    duration_minutes = serializers.IntegerField(read_only=True)
    duration_hours = serializers.FloatField(read_only=True)
    fuel_burned = serializers.FloatField(read_only=True)
    cost = serializers.FloatField(read_only=True)

    class Meta:
        model = IdlingEvent
        fields = '__all__'
        read_only_fields = ['created_at']


class ChargeScheduleSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)

    class Meta:
        model = ChargeSchedule
        fields = '__all__'
        read_only_fields = ['created_at']


class FuelBudgetSerializer(serializers.ModelSerializer):
    class Meta:
        model = FuelBudget
        fields = '__all__'
        read_only_fields = ['created_at']
