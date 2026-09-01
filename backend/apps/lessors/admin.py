from django.contrib import admin

from .models import Lessor, LessorContract, LessorDocument, LessorPayment


@admin.register(Lessor)
class LessorAdmin(admin.ModelAdmin):
    list_display = ('display_name', 'lessor_type', 'email', 'phone', 'country', 'is_active')
    list_filter = ('lessor_type', 'is_active')
    search_fields = ('first_name', 'last_name', 'company_name', 'email', 'phone', 'national_id')


@admin.register(LessorContract)
class LessorContractAdmin(admin.ModelAdmin):
    list_display = ('title', 'lessor', 'status', 'start_date', 'end_date', 'monthly_rate')
    list_filter = ('status', 'payment_frequency')
    search_fields = ('title', 'contract_number', 'lessor__company_name', 'lessor__first_name')
    raw_id_fields = ('lessor',)


@admin.register(LessorPayment)
class LessorPaymentAdmin(admin.ModelAdmin):
    list_display = ('lessor', 'amount', 'status', 'due_date', 'paid_date', 'payment_method')
    list_filter = ('status', 'payment_method')
    search_fields = ('lessor__company_name', 'lessor__first_name', 'invoice_number', 'reference')
    raw_id_fields = ('lessor', 'contract')


@admin.register(LessorDocument)
class LessorDocumentAdmin(admin.ModelAdmin):
    list_display = ('name', 'lessor', 'document_type', 'expires_at')
    list_filter = ('document_type',)
    search_fields = ('name', 'lessor__company_name', 'lessor__first_name')
    raw_id_fields = ('lessor',)
