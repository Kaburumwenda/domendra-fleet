from django.db import models
from django.db.models import F


class InventoryLocation(models.Model):
    name = models.CharField(max_length=100, unique=True)
    address = models.TextField(blank=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class InventoryItem(models.Model):
    class CostingMethod(models.TextChoices):
        FIFO = 'FIFO', 'FIFO'
        LIFO = 'LIFO', 'LIFO'
        AVERAGE = 'AVERAGE', 'Average Cost'

    location = models.ForeignKey(InventoryLocation, null=True, blank=True, on_delete=models.SET_NULL, related_name='items')
    sku = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=100, blank=True)
    barcode = models.CharField(max_length=100, blank=True, db_index=True)
    quantity_on_hand = models.FloatField(default=0)
    reorder_point = models.FloatField(default=0)
    max_stock = models.FloatField(default=0)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    bin_location = models.CharField(max_length=50, blank=True)
    costing_method = models.CharField(max_length=10, choices=CostingMethod.choices, default=CostingMethod.FIFO)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        indexes = [models.Index(fields=['sku']), models.Index(fields=['category'])]

    def __str__(self):
        return f'{self.sku} – {self.name}'

    @property
    def needs_reorder(self):
        return self.quantity_on_hand <= self.reorder_point

    @property
    def total_value(self):
        return float(self.quantity_on_hand) * float(self.unit_cost)


class StockTransaction(models.Model):
    class TransactionType(models.TextChoices):
        IN = 'in', 'Stock In'
        OUT = 'out', 'Stock Out'
        ADJUST = 'adjust', 'Adjustment'
        TRANSFER = 'transfer', 'Transfer'

    item = models.ForeignKey(InventoryItem, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=10, choices=TransactionType.choices)
    quantity = models.FloatField()
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    reference = models.CharField(max_length=200, blank=True, help_text='PO number, work order, etc.')
    notes = models.TextField(blank=True)
    created_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='stock_transactions')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        super().save(*args, **kwargs)
        if is_new:
            self._update_stock()

    def _update_stock(self):
        item = self.item
        if self.transaction_type in ('in', 'adjust'):
            item.quantity_on_hand = F('quantity_on_hand') + self.quantity
        elif self.transaction_type == 'out':
            item.quantity_on_hand = F('quantity_on_hand') - abs(self.quantity)
        elif self.transaction_type == 'transfer':
            pass  # handled via two transactions
        item.save(update_fields=['quantity_on_hand', 'updated_at'])
        item.refresh_from_db()


class PurchaseOrder(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        SUBMITTED = 'submitted', 'Submitted'
        PARTIALLY_RECEIVED = 'partially_received', 'Partially Received'
        RECEIVED = 'received', 'Received'
        CANCELLED = 'cancelled', 'Cancelled'

    vendor = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='purchase_orders')
    location = models.ForeignKey(InventoryLocation, null=True, blank=True, on_delete=models.SET_NULL)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    total_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'PO #{self.pk} – {self.vendor or "Unknown"}'

    class Meta:
        ordering = ['-created_at']


class PurchaseOrderItem(models.Model):
    purchase_order = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, related_name='items')
    inventory_item = models.ForeignKey(InventoryItem, on_delete=models.PROTECT, related_name='po_lines')
    quantity_ordered = models.FloatField(default=1)
    quantity_received = models.FloatField(default=0)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    @property
    def line_total(self):
        return float(self.quantity_ordered) * float(self.unit_cost)
