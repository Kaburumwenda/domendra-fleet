from django.urls import path

from .views import SuggestedCurrencyView, TenantSettingsView

app_name = 'tenants'

urlpatterns = [
    path('', TenantSettingsView.as_view(), name='tenant-settings'),
    path('suggested-currency/', SuggestedCurrencyView.as_view(), name='suggested-currency'),
]
