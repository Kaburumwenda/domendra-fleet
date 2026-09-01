import random
from decimal import Decimal

from django.db import transaction as db_transaction
from django.db.models import Count, F, Sum
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import InventoryItem, InventoryLocation, PurchaseOrder, PurchaseOrderItem, StockTransaction
from .serializers import (
    InventoryItemSerializer,
    InventoryLocationSerializer,
    PurchaseOrderItemSerializer,
    PurchaseOrderSerializer,
    StockTransactionSerializer,
)


class InventoryLocationViewSet(viewsets.ModelViewSet):
    queryset = InventoryLocation.objects.all()
    serializer_class = InventoryLocationSerializer
    search_fields = ['name', 'address']
    ordering_fields = ['name', 'created_at']


class InventoryItemViewSet(viewsets.ModelViewSet):
    queryset = InventoryItem.objects.select_related('location')
    serializer_class = InventoryItemSerializer
    filterset_fields = ['location', 'category', 'is_active']
    search_fields = ['sku', 'name', 'barcode', 'category']
    ordering_fields = ['name', 'quantity_on_hand', 'unit_cost', 'created_at']

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = self.get_queryset()
        active = qs.filter(is_active=True)
        low_stock = qs.filter(quantity_on_hand__lte=F('reorder_point'))
        total_value = sum(float(i.total_value) for i in qs)
        by_category = {}
        for item in qs:
            cat = item.category or 'Uncategorized'
            by_category.setdefault(cat, {'count': 0, 'value': 0.0, 'qty': 0})
            by_category[cat]['count'] += 1
            by_category[cat]['value'] += float(item.total_value)
            by_category[cat]['qty'] += item.quantity_on_hand
        po_qs = PurchaseOrder.objects.all()
        po_by_status = {}
        for s, _ in PurchaseOrder.Status.choices:
            po_by_status[s] = po_qs.filter(status=s).count()
        return Response({
            'total_skus': qs.count(),
            'active_skus': active.count(),
            'total_value': round(total_value, 2),
            'total_on_hand': sum(i.quantity_on_hand for i in qs),
            'low_stock_count': low_stock.count(),
            'location_count': InventoryLocation.objects.count(),
            'by_category': by_category,
            'by_category_top': sorted(
                [{'category': k, 'count': v['count'], 'value': round(v['value'], 2), 'qty': v['qty']}
                 for k, v in by_category.items()],
                key=lambda x: x['value'], reverse=True,
            )[:8],
            'po_count': po_qs.count(),
            'po_by_status': po_by_status,
            'transaction_count': StockTransaction.objects.count(),
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request):
        """Seed demo inventory: locations, items, POs, and transactions."""
        # Locations
        loc_data = [
            ('Main Warehouse', '123 Industrial Blvd, Sacramento, CA'),
            ('North Yard', '4550 Northgate Blvd, Sacramento, CA'),
            ('East Shop', '9800 Folsom Blvd, Rancho Cordova, CA'),
            ('Mobile Van #1', ''),
        ]
        locations = []
        for name, addr in loc_data:
            loc, _ = InventoryLocation.objects.get_or_create(
                name=name, defaults={'address': addr, 'is_active': True})
        locations.append(loc)
        locations = list(InventoryLocation.objects.all())

        # Parts catalog
        parts_catalog = [
            ('OIL-5W30', 'Engine Oil 5W-30 (5gal)', 'Fluids', 3.49, 20, 5, 80),
            ('OIL-15W40', 'Engine Oil 15W-40 (5gal)', 'Fluids', 3.29, 15, 5, 60),
            ('FL-FUEL', 'Diesel Fuel Filter', 'Filters', 18.95, 8, 3, 30),
            ('FL-AIR', 'Air Filter HD', 'Filters', 22.50, 12, 4, 25),
            ('FL-OIL', 'Oil Filter Spin-On', 'Filters', 12.75, 6, 2, 40),
            ('FL-CAB', 'Cabin Air Filter', 'Filters', 14.20, 3, 2, 15),
            ('BR-FRONT', 'Brake Pads Front Set', 'Brakes', 85.00, 4, 2, 12),
            ('BR-ROTOR', 'Brake Rotor', 'Brakes', 120.00, 2, 2, 8),
            ('BR-DRUM', 'Brake Drum', 'Brakes', 95.00, 6, 2, 10),
            ('BR-SHOE', 'Brake Shoe Set', 'Brakes', 65.00, 8, 3, 16),
            ('TR-225R17', 'Tire 225/70R17.5', 'Tires', 180.00, 20, 4, 40),
            ('TR-11R22', 'Tire 11R22.5 Drive', 'Tires', 420.00, 12, 4, 24),
            ('TR-VALVE', 'Tire Valve Stem', 'Tires', 1.20, 50, 20, 200),
            ('BT-GRP31', 'Battery Group 31', 'Electrical', 185.00, 5, 2, 10),
            ('BT-GRP4D', 'Battery Group 4D', 'Electrical', 240.00, 3, 2, 8),
            ('EL-ALT', 'Alternator 160A', 'Electrical', 320.00, 2, 1, 6),
            ('EL-START', 'Starter Motor', 'Electrical', 280.00, 1, 1, 4),
            ('EL-WIRE', 'Wiring Harness', 'Electrical', 45.00, 6, 2, 20),
            ('COOL-50', 'Coolant 50/50 (5gal)', 'Fluids', 14.99, 10, 3, 30),
            ('COOL-FLUSH', 'Coolant System Flush', 'Fluids', 8.50, 4, 2, 12),
            ('SUS-SHOCK', 'Shock Absorber', 'Suspension', 75.00, 8, 3, 16),
            ('SUS-SPRING', 'Leaf Spring', 'Suspension', 150.00, 2, 1, 6),
            ('SUS-BUSH', 'Suspension Bushing Set', 'Suspension', 25.00, 15, 5, 40),
            ('EXH-MUFF', 'Muffler', 'Exhaust', 110.00, 3, 1, 8),
            ('EXH-PIPE', 'Exhaust Pipe Section', 'Exhaust', 38.00, 6, 2, 16),
            ('LIGHT-HAL', 'Headlight Assembly', 'Lighting', 95.00, 4, 2, 12),
            ('LIGHT-TAIL', 'Tail Light LED', 'Lighting', 72.00, 6, 2, 16),
            ('LIGHT-STRB', 'Strobe Light Bar', 'Lighting', 180.00, 2, 1, 6),
            ('GLASS-WSH', 'Windshield Wiper Blade', 'Glass', 12.00, 10, 4, 30),
            ('GLASS-MIR', 'Mirror Assembly', 'Glass', 65.00, 3, 1, 10),
        ]

        created_items = 0
        for sku, name, cat, cost, qty, reorder, max_stock in parts_catalog:
            loc = random.choice(locations)
            item, created = InventoryItem.objects.get_or_create(
                sku=sku,
                defaults={
                    'name': name,
                    'category': cat,
                    'quantity_on_hand': qty,
                    'reorder_point': reorder,
                    'max_stock': max_stock,
                    'unit_cost': Decimal(str(cost)),
                    'bin_location': f'{random.choice("ABCDEF")}-{random.randint(1, 20)}',
                    'costing_method': 'FIFO',
                    'is_active': True,
                    'location': loc,
                })
            if created:
                created_items += 1

        # Generate some stock transactions (in/out/adjust) for existing items
        all_items = list(InventoryItem.objects.all())
        created_txns = 0
        for item in all_items[:20]:
            for _ in range(random.randint(2, 6)):
                ttype = random.choice(['in', 'out', 'adjust'])
                qty = random.randint(1, 10)
                if ttype == 'out':
                    qty = -qty
                StockTransaction.objects.create(
                    item=item,
                    transaction_type=ttype,
                    quantity=qty,
                    unit_cost=item.unit_cost,
                    reference=random.choice(['WO-1023', 'WO-1024', 'WO-1025', 'Manual', 'Stock Count']),
                    notes=random.choice(['Stock adjustment', 'Issued to work order', 'Received from vendor', 'Cycle count']),
                )
                created_txns += 1

        # Create purchase orders
        vendors = []
        from apps.contacts.models import Contact
        vendors = list(Contact.objects.filter(contact_type='vendor') if 'contact_type' in [f.name for f in Contact._meta.get_fields()] else [])
        # Fallback: use any contacts as vendors
        if not vendors:
            vendors = list(Contact.objects.all()[:5])

        po_statuses = ['draft', 'submitted', 'partially_received', 'received']
        created_pos = 0
        for i in range(6):
            st = random.choice(po_statuses)
            po = PurchaseOrder.objects.create(
                vendor=random.choice(vendors) if vendors else None,
                location=random.choice(locations) if locations else None,
                status=st,
                notes=f'Demo purchase order #{i + 1}',
            )
            # Add 2-4 line items
            num_lines = random.randint(2, 4)
            total = Decimal('0')
            for pi in random.sample(all_items, min(num_lines, len(all_items))):
                qty_ordered = random.randint(5, 25)
                qty_recv = qty_ordered if st == 'received' else (random.randint(0, qty_ordered) if st == 'partially_received' else 0)
                PurchaseOrderItem.objects.create(
                    purchase_order=po,
                    inventory_item=pi,
                    quantity_ordered=qty_ordered,
                    quantity_received=qty_recv,
                    unit_cost=pi.unit_cost,
                )
                total += Decimal(str(qty_ordered)) * pi.unit_cost
            po.total_cost = total
            po.save(update_fields=['total_cost'])
            created_pos += 1

        return Response({
            'detail': f'Seeded {created_items} items, {created_txns} transactions, {created_pos} purchase orders across {len(locations)} locations.'
        })

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        qs = self.get_queryset().filter(quantity_on_hand__lte=F('reorder_point'))
        return Response(InventoryItemSerializer(qs, many=True).data)


class StockTransactionViewSet(viewsets.ModelViewSet):
    queryset = StockTransaction.objects.select_related('item', 'created_by')
    serializer_class = StockTransactionSerializer
    filterset_fields = ['item', 'transaction_type']
    ordering_fields = ['created_at']


class PurchaseOrderViewSet(viewsets.ModelViewSet):
    queryset = PurchaseOrder.objects.select_related('vendor', 'location').prefetch_related('items')
    serializer_class = PurchaseOrderSerializer
    filterset_fields = ['status', 'vendor', 'location']
    ordering_fields = ['created_at', 'total_cost']

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = self.get_queryset()
        by_status = {}
        for s, _ in PurchaseOrder.Status.choices:
            by_status[s] = qs.filter(status=s).count()
        total_value = qs.aggregate(v=Sum('total_cost'))['v'] or Decimal('0')
        return Response({
            'po_count': qs.count(),
            'po_by_status': by_status,
            'po_total_value': float(total_value),
        })

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        po = self.get_object()
        serializer = PurchaseOrderItemSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(purchase_order=po)
        return Response(serializer.data, status=201)

    @action(detail=True, methods=['post'])
    def submit(self, request, pk=None):
        po = self.get_object()
        if po.status != PurchaseOrder.Status.DRAFT:
            return Response({'detail': 'Only draft POs can be submitted.'}, status=status.HTTP_400_BAD_REQUEST)
        po.status = PurchaseOrder.Status.SUBMITTED
        po.save(update_fields=['status', 'updated_at'])
        return Response(PurchaseOrderSerializer(po, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def receive(self, request, pk=None):
        """Mark line items as received. Payload: {'lines': [{'id': poItemPk, 'quantity': n}, ...]}.
        Auto-creates stock-in transactions and updates PO status."""
        po = self.get_object()
        if po.status in (PurchaseOrder.Status.RECEIVED, PurchaseOrder.Status.CANCELLED):
            return Response({'detail': 'PO is already closed.'}, status=status.HTTP_400_BAD_REQUEST)
        lines = request.data.get('lines', [])
        if not lines:
            return Response({'detail': 'No line items provided.'}, status=status.HTTP_400_BAD_REQUEST)
        received_items = []
        with db_transaction.atomic():
            for line in lines:
                try:
                    po_item = po.items.get(pk=line.get('id'))
                except PurchaseOrderItem.DoesNotExist:
                    return Response({'detail': f'Line {line.get("id")} not found.'}, status=status.HTTP_400_BAD_REQUEST)
                qty = float(line.get('quantity', 0))
                if qty <= 0:
                    continue
                new_received = po_item.quantity_received + qty
                if new_received > po_item.quantity_ordered:
                    return Response(
                        {'detail': f'Received qty exceeds ordered for {po_item.inventory_item.sku}.'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                po_item.quantity_received = new_received
                po_item.save(update_fields=['quantity_received'])
                StockTransaction.objects.create(
                    item=po_item.inventory_item,
                    transaction_type=StockTransaction.TransactionType.IN,
                    quantity=qty,
                    unit_cost=po_item.unit_cost,
                    reference=f'PO #{po.pk}',
                    notes=f'Received against PO #{po.pk}',
                    created_by=request.user if request.user.is_authenticated else None,
                )
                received_items.append(PurchaseOrderItemSerializer(po_item).data)
        all_received = not po.items.filter(quantity_received__lt=F('quantity_ordered')).exists()
        po.status = PurchaseOrder.Status.RECEIVED if all_received else PurchaseOrder.Status.PARTIALLY_RECEIVED
        po.save(update_fields=['status', 'updated_at'])
        return Response({'lines': received_items, 'status': po.status})
