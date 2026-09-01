from rest_framework import serializers

from .models import InventoryItem, InventoryLocation, PurchaseOrder, PurchaseOrderItem, StockTransaction


class InventoryLocationSerializer(serializers.ModelSerializer):
    item_count = serializers.IntegerField(source='items.count', read_only=True, required=False)

    class Meta:
        model = InventoryLocation
        fields = '__all__'
        read_only_fields = ['created_at']


class InventoryItemSerializer(serializers.ModelSerializer):
    location_name = serializers.CharField(source='location.name', read_only=True)
    needs_reorder = serializers.BooleanField(read_only=True)
    total_value = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)

    class Meta:
        model = InventoryItem
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class StockTransactionSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source='item.name', read_only=True)
    item_sku = serializers.CharField(source='item.sku', read_only=True)

    class Meta:
        model = StockTransaction
        fields = '__all__'
        read_only_fields = ['created_at', 'created_by']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['created_by'] = request.user
        return super().create(validated_data)


class PurchaseOrderItemSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source='inventory_item.name', read_only=True)
    line_total = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)

    class Meta:
        model = PurchaseOrderItem
        fields = '__all__'


class PurchaseOrderSerializer(serializers.ModelSerializer):
    vendor_name = serializers.CharField(source='vendor.full_name', read_only=True)
    items = PurchaseOrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = PurchaseOrder
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
