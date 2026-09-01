from django.urls import path

from .views import DashboardView, RentalTrendView

app_name = 'dashboard'

urlpatterns = [
    path('', DashboardView.as_view(), name='dashboard'),
    path('rental-trend/', RentalTrendView.as_view(), name='rental-trend'),
]
