from decimal import Decimal

from rest_framework import serializers

from .models import (
    Expense,
    ExpenseAttachment,
    ExpenseBudget,
    ExpenseCategory,
    ExpenseComment,
    RecurringExpense,
)


class ExpenseCategorySerializer(serializers.ModelSerializer):
    expense_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = ExpenseCategory
        fields = [
            'id', 'name', 'description', 'code', 'type',
            'color', 'icon', 'is_active',
            'expense_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class ExpenseAttachmentSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.CharField(
        source='uploaded_by.full_name', read_only=True
    )
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = ExpenseAttachment
        fields = [
            'id', 'expense', 'file', 'file_url', 'filename',
            'file_size', 'mime_type',
            'uploaded_by', 'uploaded_by_name',
            'created_at',
        ]
        read_only_fields = ['filename', 'file_size', 'mime_type', 'uploaded_by', 'created_at']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file:
            url = obj.file.url
            return request.build_absolute_uri(url) if request else url
        return None


class ExpenseCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.full_name', read_only=True)
    author_initials = serializers.SerializerMethodField()

    class Meta:
        model = ExpenseComment
        fields = [
            'id', 'expense', 'author', 'author_name', 'author_initials',
            'body', 'created_at', 'updated_at',
        ]
        read_only_fields = ['author', 'created_at', 'updated_at']

    def get_author_initials(self, obj):
        name = getattr(obj.author, 'full_name', None) or ''
        if not name:
            initials = '??'
        else:
            parts = [p for p in name.split() if p]
            initials = ''.join(p[0] for p in parts[:2]).upper() or name[:2]
        return initials


class ExpenseSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)
    category_icon = serializers.CharField(source='category.icon', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    contact_name = serializers.CharField(source='contact.full_name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    submitted_by_name = serializers.CharField(source='submitted_by.full_name', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.full_name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_method_display = serializers.CharField(
        source='get_payment_method_display', read_only=True
    )
    total_amount = serializers.DecimalField(
        max_digits=14, decimal_places=2, read_only=True,
    )
    attachments = ExpenseAttachmentSerializer(many=True, read_only=True)
    comments = ExpenseCommentSerializer(many=True, read_only=True)
    attachment_count = serializers.IntegerField(read_only=True, required=False)

    class Meta:
        model = Expense
        fields = [
            'id', 'expense_number', 'title', 'description',
            'category', 'category_name', 'category_color', 'category_icon',
            'amount', 'currency', 'tax_amount', 'tax_rate', 'total_amount',
            'expense_date', 'vendor_name',
            'vehicle', 'vehicle_name',
            'contact', 'contact_name',
            'work_order', 'service',
            'payment_method', 'payment_method_display',
            'payment_reference', 'status', 'status_display',
            'paid_at',
            'submitted_by', 'submitted_by_name', 'submitted_at',
            'approved_by', 'approved_by_name', 'approved_at',
            'rejection_reason', 'recurring_rule',
            'tags', 'is_billable', 'notes',
            'created_by', 'created_by_name',
            'attachments', 'comments', 'attachment_count',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'expense_number', 'paid_at',
            'submitted_by', 'submitted_at',
            'approved_by', 'approved_at',
            'rejection_reason', 'recurring_rule',
            'created_by', 'created_at', 'updated_at',
            'total_amount', 'attachment_count',
        ]

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            validated_data.setdefault('created_by', request.user)
        # Calculate tax_amount from tax_rate if not explicitly provided
        if 'tax_amount' not in validated_data and validated_data.get('tax_rate'):
            rate = Decimal(str(validated_data['tax_rate']))
            amount = Decimal(str(validated_data.get('amount', 0)))
            validated_data['tax_amount'] = (amount * rate).quantize(Decimal('0.01'))
        return super().create(validated_data)

    def update(self, instance, validated_data):
        # Recompute tax_amount when tax_rate or amount changes
        if 'tax_rate' in validated_data or 'amount' in validated_data:
            rate = Decimal(str(validated_data.get('tax_rate', instance.tax_rate or 0)))
            amount = Decimal(str(validated_data.get('amount', instance.amount or 0)))
            if 'tax_amount' not in validated_data:
                validated_data['tax_amount'] = (amount * rate).quantize(Decimal('0.01'))
        return super().update(instance, validated_data)


class RecurringExpenseSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    contact_name = serializers.CharField(source='contact.full_name', read_only=True)
    frequency_display = serializers.CharField(source='get_frequency_display', read_only=True)
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)

    class Meta:
        model = RecurringExpense
        fields = [
            'id', 'title', 'description',
            'category', 'category_name',
            'vehicle', 'vehicle_name',
            'contact', 'contact_name',
            'vendor_name',
            'amount', 'currency', 'tax_rate',
            'payment_method',
            'frequency', 'frequency_display', 'interval',
            'day_of_month', 'start_date', 'end_date',
            'next_date', 'last_run_at', 'is_active',
            'auto_approve',
            'created_by', 'created_by_name',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'next_date', 'last_run_at',
            'created_by', 'created_at', 'updated_at',
        ]

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            validated_data.setdefault('created_by', request.user)
        if not validated_data.get('next_date'):
            validated_data['next_date'] = validated_data.get('start_date')
        return super().create(validated_data)


class ExpenseBudgetSerializer(serializers.ModelSerializer):
    budget_label = serializers.SerializerMethodField()
    actual_amount = serializers.DecimalField(
        max_digits=14, decimal_places=2, read_only=True, required=False,
    )
    variance = serializers.DecimalField(
        max_digits=14, decimal_places=2, read_only=True, required=False,
    )
    pct_used = serializers.FloatField(read_only=True, required=False)
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)

    class Meta:
        model = ExpenseBudget
        fields = [
            'id', 'scope', 'target_ref', 'budget_label',
            'vehicle', 'category',
            'month', 'budget_amount', 'currency', 'notes',
            'actual_amount', 'variance', 'pct_used',
            'created_by', 'created_by_name',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def get_budget_label(self, obj):
        return obj.label

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user and request.user.is_authenticated:
            validated_data.setdefault('created_by', request.user)
        return super().create(validated_data)
