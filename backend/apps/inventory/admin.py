from django.contrib import admin

from .models import InventoryItem, InventoryLocation, PurchaseOrder, PurchaseOrderItem, StockTransaction


class PurchaseOrderItemInline(admin.TabularInline):
    model = PurchaseOrderItem
    extra = 1


@admin.register(InventoryLocation)
class InventoryLocationAdmin(admin.ModelAdmin):
    list_display = ('name', 'is_active', 'created_at')
    search_fields = ('name', 'address')


@admin.register(InventoryItem)
class InventoryItemAdmin(admin.ModelAdmin):
    list_display = ('sku', 'name', 'category', 'quantity_on_hand', 'reorder_point', 'unit_cost', 'location', 'needs_reorder')
    list_filter = ('category', 'location', 'is_active')
    search_fields = ('sku', 'name', 'barcode')


@admin.register(StockTransaction)
class StockTransactionAdmin(admin.ModelAdmin):
    list_display = ('item', 'transaction_type', 'quantity', 'unit_cost', 'created_at')
    list_filter = ('transaction_type',)
    raw_id_fields = ('item',)


@admin.register(PurchaseOrder)
class PurchaseOrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'vendor', 'status', 'total_cost', 'created_at')
    list_filter = ('status',)
    inlines = [PurchaseOrderItemInline]
    raw_id_fields = ('vendor', 'location')
