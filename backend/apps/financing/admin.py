from django.contrib import admin

from .models import FinancingLoan, FinancingPayment


@admin.register(FinancingLoan)
class FinancingLoanAdmin(admin.ModelAdmin):
    list_display = ['loan_no', 'vehicle', 'bank_name', 'principal_amount', 'monthly_instalment', 'status', 'disbursement_date', 'progress_pct']
    list_filter = ['status', 'interest_type', 'bank_name', 'created_at']
    search_fields = ['loan_no', 'bank_name', 'account_no', 'vehicle__display_name', 'vehicle__license_plate']
    raw_id_fields = ['vehicle']
    readonly_fields = ['loan_no', 'created_at', 'updated_at']
    date_hierarchy = 'disbursement_date'


@admin.register(FinancingPayment)
class FinancingPaymentAdmin(admin.ModelAdmin):
    list_display = ['loan', 'instalment_no', 'due_date', 'amount', 'paid_amount', 'status', 'paid_date']
    list_filter = ['status', 'payment_method', 'due_date']
    search_fields = ['loan__loan_no', 'reference_no']
    raw_id_fields = ['loan']
    readonly_fields = ['created_at', 'updated_at']
    date_hierarchy = 'due_date'
