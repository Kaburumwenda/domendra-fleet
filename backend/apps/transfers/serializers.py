from rest_framework import serializers

from .models import Transfer, TransferStop, TransferDriverOffer


class TransferStopSerializer(serializers.ModelSerializer):
    class Meta:
        model = TransferStop
        fields = '__all__'
        read_only_fields = ['created_at']


class TransferDriverOfferSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source='driver.full_name', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True, default='')

    class Meta:
        model = TransferDriverOffer
        fields = '__all__'
        read_only_fields = ['created_at']


class TransferSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views."""
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True, default='')
    driver_name = serializers.CharField(source='driver.full_name', read_only=True, default='')
    remaining_balance = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    is_upcoming = serializers.BooleanField(read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    stops = TransferStopSerializer(many=True, read_only=True)

    class Meta:
        model = Transfer
        fields = '__all__'
        read_only_fields = [
            'created_at', 'updated_at', 'actual_pickup_time', 'actual_dropoff_time',
            'driver_current_lat', 'driver_current_lng',
        ]


class TransferDetailSerializer(TransferSerializer):
    """Extended serializer with driver offers for detail view."""
    driver_offers = TransferDriverOfferSerializer(many=True, read_only=True)


class TransferStopNestedSerializer(serializers.ModelSerializer):
    """Serializer used when receiving stops as part of the transfer create payload."""

    class Meta:
        model = TransferStop
        fields = '__all__'
        read_only_fields = ['created_at', 'transfer']


class TransferCreateSerializer(serializers.ModelSerializer):
    """Serializer that supports creating a transfer with nested stops in one request."""
    stops = TransferStopNestedSerializer(many=True, required=False)

    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True, default='')
    driver_name = serializers.CharField(source='driver.full_name', read_only=True, default='')
    remaining_balance = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    is_upcoming = serializers.BooleanField(read_only=True)
    is_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = Transfer
        fields = '__all__'
        read_only_fields = [
            'created_at', 'updated_at', 'actual_pickup_time', 'actual_dropoff_time',
            'driver_current_lat', 'driver_current_lng',
        ]

    def create(self, validated_data):
        stops_data = validated_data.pop('stops', [])
        transfer = Transfer.objects.create(**validated_data)
        for stop_data in stops_data:
            TransferStop.objects.create(transfer=transfer, **stop_data)
        return transfer

    def update(self, instance, validated_data):
        stops_data = validated_data.pop('stops', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if stops_data is not None:
            instance.stops.all().delete()
            for stop_data in stops_data:
                TransferStop.objects.create(transfer=instance, **stop_data)
        return instance
