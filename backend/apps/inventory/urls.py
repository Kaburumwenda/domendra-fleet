from django.urls import path

from .views import (
    InventoryItemViewSet,
    InventoryLocationViewSet,
    PurchaseOrderViewSet,
    StockTransactionViewSet,
)

app_name = 'inventory'

urlpatterns = [
    path('locations/', InventoryLocationViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='location-list'),
    path('locations/<int:pk>/', InventoryLocationViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='location-detail'),
    path('items/', InventoryItemViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='item-list'),
    path('items/low-stock/', InventoryItemViewSet.as_view({'get': 'low_stock'}), name='item-low-stock'),
    path('items/stats/', InventoryItemViewSet.as_view({'get': 'stats'}), name='item-stats'),
    path('items/seed-demo/', InventoryItemViewSet.as_view({'post': 'seed_demo'}), name='item-seed-demo'),
    path('items/<int:pk>/', InventoryItemViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='item-detail'),
    path('transactions/', StockTransactionViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='transaction-list'),
    path('transactions/<int:pk>/', StockTransactionViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='transaction-detail'),
    path('purchase-orders/', PurchaseOrderViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='po-list'),
    path('purchase-orders/stats/', PurchaseOrderViewSet.as_view({'get': 'stats'}), name='po-stats'),
    path('purchase-orders/<int:pk>/', PurchaseOrderViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='po-detail'),
    path('purchase-orders/<int:pk>/add-item/', PurchaseOrderViewSet.as_view({'post': 'add_item'}), name='po-add-item'),
    path('purchase-orders/<int:pk>/submit/', PurchaseOrderViewSet.as_view({'post': 'submit'}), name='po-submit'),
    path('purchase-orders/<int:pk>/receive/', PurchaseOrderViewSet.as_view({'post': 'receive'}), name='po-receive'),
]
