from django.urls import path

from .views import (
    LessorAnalyticsView,
    LessorContractViewSet,
    LessorDocumentViewSet,
    LessorLocationsAnalysisView,
    LessorPaymentViewSet,
    LessorProfitLossView,
    LessorViewSet,
)

app_name = 'lessors'

urlpatterns = [
    # Lessors
    path('', LessorViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='lessor-list'),
    path('<int:pk>/', LessorViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='lessor-detail'),
    path('<int:pk>/vehicles/', LessorViewSet.as_view({'get': 'vehicles'}),
         name='lessor-vehicles'),
    path('<int:pk>/summary/', LessorViewSet.as_view({'get': 'summary'}),
         name='lessor-summary'),

    # Contracts
    path('contracts/', LessorContractViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='contract-list'),
    path('contracts/<int:pk>/', LessorContractViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='contract-detail'),
    path('contracts/<int:pk>/activate/', LessorContractViewSet.as_view({'post': 'activate'}),
         name='contract-activate'),
    path('contracts/<int:pk>/terminate/', LessorContractViewSet.as_view({'post': 'terminate'}),
         name='contract-terminate'),

    # Payments
    path('payments/', LessorPaymentViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='payment-list'),
    path('payments/<int:pk>/', LessorPaymentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='payment-detail'),
    path('payments/<int:pk>/mark-paid/', LessorPaymentViewSet.as_view({'post': 'mark_paid'}),
         name='payment-mark-paid'),
    path('payments/mark-overdue/', LessorPaymentViewSet.as_view({'post': 'mark_overdue'}),
         name='payment-mark-overdue'),

    # Documents
    path('documents/', LessorDocumentViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='document-list'),
    path('documents/<int:pk>/', LessorDocumentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='document-detail'),

    # Analytics
    path('analytics/', LessorAnalyticsView.as_view({'get': 'list'}), name='analytics'),

    # Profit & Loss
    path('profit-loss/', LessorProfitLossView.as_view({'get': 'list'}), name='profit-loss'),

    # Locations Analysis
    path('locations-analysis/', LessorLocationsAnalysisView.as_view({'get': 'list'}),
         name='locations-analysis'),
]
