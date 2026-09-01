from django.contrib import admin

from .models import (
    Expense, ExpenseAttachment, ExpenseBudget,
    ExpenseCategory, ExpenseComment, RecurringExpense,
)


class ExpenseAttachmentInline(admin.TabularInline):
    model = ExpenseAttachment
    extra = 0
    readonly_fields = ('filename', 'file_size', 'mime_type', 'uploaded_by', 'created_at')


class ExpenseCommentInline(admin.TabularInline):
    model = ExpenseComment
    extra = 0
    readonly_fields = ('author', 'created_at', 'updated_at')


@admin.register(ExpenseCategory)
class ExpenseCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'code', 'type', 'color', 'is_active', 'created_at')
    list_filter = ('type', 'is_active')
    search_fields = ('name', 'code', 'description')
    list_editable = ('is_active',)


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = (
        'expense_number', 'title', 'category', 'amount', 'currency',
        'expense_date', 'status', 'vehicle', 'is_billable',
    )
    list_filter = ('status', 'currency', 'payment_method', 'is_billable', 'category')
    search_fields = ('title', 'expense_number', 'vendor_name', 'payment_reference', 'description')
    date_hierarchy = 'expense_date'
    readonly_fields = (
        'expense_number', 'total_amount', 'created_by', 'created_at',
        'updated_at', 'submitted_by', 'submitted_at',
        'approved_by', 'approved_at', 'recurring_rule',
    )
    inlines = [ExpenseAttachmentInline, ExpenseCommentInline]


@admin.register(RecurringExpense)
class RecurringExpenseAdmin(admin.ModelAdmin):
    list_display = ('title', 'amount', 'frequency', 'interval', 'next_date', 'is_active')
    list_filter = ('frequency', 'is_active')
    search_fields = ('title', 'vendor_name')
    readonly_fields = ('last_run_at', 'created_by', 'created_at', 'updated_at')


@admin.register(ExpenseBudget)
class ExpenseBudgetAdmin(admin.ModelAdmin):
    list_display = ('scope', 'target_ref', 'month', 'budget_amount', 'currency')
    list_filter = ('scope', 'currency')
    search_fields = ('target_ref', 'notes')
    date_hierarchy = 'month'


@admin.register(ExpenseAttachment)
class ExpenseAttachmentAdmin(admin.ModelAdmin):
    list_display = ('expense', 'filename', 'file_size', 'uploaded_by', 'created_at')
    search_fields = ('filename',)
    readonly_fields = ('filename', 'file_size', 'mime_type', 'uploaded_by', 'created_at')


@admin.register(ExpenseComment)
class ExpenseCommentAdmin(admin.ModelAdmin):
    list_display = ('expense', 'author', 'created_at')
    search_fields = ('body',)
    readonly_fields = ('author', 'created_at', 'updated_at')
