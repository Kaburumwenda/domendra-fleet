from django.urls import path

from .views import (
    CustomerViewSet,
    DigitalSignatureViewSet,
    DriverHireRateViewSet,
    InvoiceViewSet,
    RentalAgreementViewSet,
    RentalChargeViewSet,
    RentalPaymentViewSet,
    VehicleCheckViewSet,
    VehicleDamageViewSet,
    VehiclePricingViewSet,
)

app_name = 'rentals'

urlpatterns = [
    path('customers/', CustomerViewSet.as_view({'get': 'list', 'post': 'create'}), name='customer-list'),
    path('customers/<int:pk>/', CustomerViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='customer-detail'),
    path('customers/<int:pk>/check-links/', CustomerViewSet.as_view({'get': 'check_links'}), name='customer-check-links'),
    path('customers/<int:pk>/agreements/', CustomerViewSet.as_view({'get': 'agreements'}), name='customer-agreements'),

    path('agreements/', RentalAgreementViewSet.as_view({'get': 'list', 'post': 'create'}), name='agreement-list'),
    path('agreements/<int:pk>/', RentalAgreementViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='agreement-detail'),
    path('agreements/<int:pk>/sign/', RentalAgreementViewSet.as_view({'post': 'sign'}), name='agreement-sign'),
    path('agreements/<int:pk>/activate/', RentalAgreementViewSet.as_view({'post': 'activate'}), name='agreement-activate'),
    path('agreements/<int:pk>/complete/', RentalAgreementViewSet.as_view({'post': 'complete'}), name='agreement-complete'),

    path('charges/', RentalChargeViewSet.as_view({'get': 'list', 'post': 'create'}), name='charge-list'),
    path('charges/<int:pk>/', RentalChargeViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='charge-detail'),

    path('damages/', VehicleDamageViewSet.as_view({'get': 'list', 'post': 'create'}), name='damage-list'),
    path('damages/<int:pk>/', VehicleDamageViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='damage-detail'),

    path('signatures/', DigitalSignatureViewSet.as_view({'get': 'list', 'post': 'create'}), name='signature-list'),
    path('signatures/<int:pk>/', DigitalSignatureViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='signature-detail'),

    path('vehicle-checks/', VehicleCheckViewSet.as_view({'get': 'list', 'post': 'create'}), name='vehiclecheck-list'),
    path('vehicle-checks/<int:pk>/', VehicleCheckViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='vehiclecheck-detail'),

    path('pricing/', VehiclePricingViewSet.as_view({'get': 'list', 'post': 'create'}), name='pricing-list'),
    path('pricing/<int:pk>/', VehiclePricingViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='pricing-detail'),

    path('payments/', RentalPaymentViewSet.as_view({'get': 'list', 'post': 'create'}), name='payment-list'),
    path('payments/summary/', RentalPaymentViewSet.as_view({'get': 'summary'}), name='payment-summary'),
    path('payments/<int:pk>/', RentalPaymentViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='payment-detail'),

    path('driver-hire-rates/', DriverHireRateViewSet.as_view({'get': 'list', 'post': 'create'}), name='driverhirerate-list'),
    path('driver-hire-rates/<int:pk>/', DriverHireRateViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='driverhirerate-detail'),
    path('driver-hire-rates/<int:pk>/compute/', DriverHireRateViewSet.as_view({'post': 'compute'}), name='driverhirerate-compute'),

    path('invoices/', InvoiceViewSet.as_view({'get': 'list', 'post': 'create'}), name='invoice-list'),
    path('invoices/from-agreement/', InvoiceViewSet.as_view({'post': 'from_agreement'}), name='invoice-from-agreement'),
    path('invoices/from-agreements/', InvoiceViewSet.as_view({'post': 'from_agreements'}), name='invoice-from-agreements'),
    path('invoices/custom/', InvoiceViewSet.as_view({'post': 'custom_invoice'}), name='invoice-custom'),
    path('invoices/<int:pk>/update-custom/', InvoiceViewSet.as_view({'patch': 'update_custom'}), name='invoice-update-custom'),
    path('invoices/<int:pk>/', InvoiceViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='invoice-detail'),
]
