from django.db import models
from django_tenants.models import TenantMixin, DomainMixin


class Tenant(TenantMixin):
    class Currency(models.TextChoices):
        USD = 'USD', 'USD ($)'
        EUR = 'EUR', 'EUR (€)'
        GBP = 'GBP', 'GBP (£)'
        KES = 'KES', 'KES (KSh)'
        NGN = 'NGN', 'NGN (₦)'
        ZAR = 'ZAR', 'ZAR (R)'
        AED = 'AED', 'AED (د.إ)'
        SAR = 'SAR', 'SAR (﷼)'
        INR = 'INR', 'INR (₹)'
        CAD = 'CAD', 'CAD (C$)'
        AUD = 'AUD', 'AUD (A$)'
        JPY = 'JPY', 'JPY (¥)'
        CNY = 'CNY', 'CNY (¥)'
        BRL = 'BRL', 'BRL (R$)'
        GHS = 'GHS', 'GHS (₵)'
        TZS = 'TZS', 'TZS (TSh)'
        UGX = 'UGX', 'UGX (USh)'
        RWF = 'RWF', 'RWF (FRw)'
        ETB = 'ETB', 'ETB (Br)'

    short_name = models.CharField(max_length=80)
    full_name = models.CharField(max_length=200, blank=True)
    email = models.EmailField()
    country = models.CharField(max_length=100, blank=True)
    mobile_number = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    logo = models.ImageField(upload_to='tenant-logos/', blank=True, null=True)
    currency = models.CharField(
        max_length=3,
        choices=Currency.choices,
        default=Currency.USD,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    auto_create_schema = True

    class Meta:
        verbose_name = 'Tenant'
        verbose_name_plural = 'Tenants'

    def __str__(self):
        return self.short_name


class Domain(DomainMixin):
    pass
