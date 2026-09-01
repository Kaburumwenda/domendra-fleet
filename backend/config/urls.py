from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('admin/', admin.site.urls),

    # API v1
    path('api/auth/', include('apps.users.urls')),
    path('api/billing/', include('apps.billing.urls')),
    path('api/vehicles/', include('apps.vehicles.urls')),
    path('api/lessors/', include('apps.lessors.urls')),
    path('api/contacts/', include('apps.contacts.urls')),
    path('api/documents/', include('apps.documents.urls')),
    path('api/inspections/', include('apps.inspections.urls')),
    path('api/issues/', include('apps.issues.urls')),
    path('api/reminders/', include('apps.reminders.urls')),
    path('api/services/', include('apps.services.urls')),
    path('api/inventory/', include('apps.inventory.urls')),
    path('api/dashboard/', include('apps.dashboard.urls')),
    path('api/fuel/', include('apps.fuel.urls')),
    path('api/reports/', include('apps.reports.urls')),
    path('api/garage/', include('apps.garage.urls')),
    path('api/accidents/', include('apps.accidents.urls')),
    path('api/dispatch/', include('apps.dispatch.urls')),
    path('api/audit/', include('apps.audit.urls')),
    path('api/tenant/', include('apps.tenants.urls')),
    path('api/equipment/', include('apps.equipment.urls')),
    path('api/telematics/', include('apps.telematics.urls')),
    path('api/locations/', include('apps.locations.urls')),
    path('api/ifta/', include('apps.ifta.urls')),
    path('api/tires/', include('apps.tires.urls')),
    path('api/batteries/', include('apps.batteries.urls')),
    path('api/recalls/', include('apps.recalls.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
    path('api/dqf/', include('apps.dqf.urls')),
    path('api/rentals/', include('apps.rentals.urls')),
    path('api/rbac/', include('apps.rbac.urls')),
    path('api/expenses/', include('apps.expenses.urls')),
    path('api/financing/', include('apps.financing.urls')),
    path('api/superadmin/', include('apps.superadmin.urls')),

    # API docs
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]


from django.conf import settings
from django.conf.urls.static import static

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
