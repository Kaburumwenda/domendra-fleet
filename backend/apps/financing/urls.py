from django.urls import path

from .views import FinancingLoanViewSet, FinancingPaymentViewSet

app_name = 'financing'

urlpatterns = [
    # ── Loan endpoints ──
    path('', FinancingLoanViewSet.as_view({'get': 'list', 'post': 'create'}), name='financing-loan-list'),
    path('dashboard/', FinancingLoanViewSet.as_view({'get': 'dashboard'}), name='financing-dashboard'),
    path('<int:pk>/', FinancingLoanViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='financing-loan-detail'),
    path('<int:pk>/summary/', FinancingLoanViewSet.as_view({'get': 'summary'}), name='financing-loan-summary'),
    path('<int:pk>/generate-schedule/', FinancingLoanViewSet.as_view({'post': 'generate_schedule'}), name='financing-generate-schedule'),
    path('<int:pk>/mark-closed/', FinancingLoanViewSet.as_view({'patch': 'mark_closed'}), name='financing-mark-closed'),

    # ── Payment endpoints ──
    path('payments/', FinancingPaymentViewSet.as_view({'get': 'list', 'post': 'create'}), name='financing-payment-list'),
    path('payments/upcoming/', FinancingPaymentViewSet.as_view({'get': 'upcoming'}), name='financing-payments-upcoming'),
    path('payments/overdue/', FinancingPaymentViewSet.as_view({'get': 'overdue'}), name='financing-payments-overdue'),
    path('payments/<int:pk>/', FinancingPaymentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='financing-payment-detail'),
    path('payments/<int:pk>/mark-paid/', FinancingPaymentViewSet.as_view({'patch': 'mark_paid'}), name='financing-payment-mark-paid'),
]
