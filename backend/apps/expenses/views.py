"""
Expense management API views.
"""
from datetime import date, datetime, timedelta
from decimal import Decimal

import django_filters
from django.db import connection
from django.db.models import Count, Q, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone as dj_timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response

from .models import (
    Expense,
    ExpenseAttachment,
    ExpenseBudget,
    ExpenseCategory,
    ExpenseComment,
    RecurringExpense,
)
from .serializers import (
    ExpenseAttachmentSerializer,
    ExpenseBudgetSerializer,
    ExpenseCategorySerializer,
    ExpenseCommentSerializer,
    ExpenseSerializer,
    RecurringExpenseSerializer,
)


# ── Expense Category ───────────────────────────────────────────────
class ExpenseCategoryViewSet(viewsets.ModelViewSet):
    queryset = ExpenseCategory.objects.all()
    serializer_class = ExpenseCategorySerializer
    filterset_fields = ['type', 'is_active']
    search_fields = ['name', 'code', 'description']
    ordering_fields = ['name', 'created_at']

    def get_queryset(self):
        qs = super().get_queryset()
        qs = qs.annotate(
            expense_count=Count('expenses', filter=Q(expenses__isnull=False))
        )
        return qs


# ── Expense Filters ─────────────────────────────────────────────────
class ExpenseFilter(django_filters.FilterSet):
    expense_date__gte = django_filters.DateFilter(field_name='expense_date', lookup_expr='gte')
    expense_date__lte = django_filters.DateFilter(field_name='expense_date', lookup_expr='lte')
    min_amount = django_filters.NumberFilter(field_name='amount', lookup_expr='gte')
    max_amount = django_filters.NumberFilter(field_name='amount', lookup_expr='lte')

    class Meta:
        model = Expense
        fields = [
            'status', 'category', 'vehicle', 'contact',
            'payment_method', 'currency', 'is_billable',
            'expense_date__gte', 'expense_date__lte',
            'min_amount', 'max_amount',
        ]


# ── Expense ─────────────────────────────────────────────────────────
class ExpenseViewSet(viewsets.ModelViewSet):
    queryset = Expense.objects.select_related(
        'category', 'vehicle', 'contact', 'created_by', 'submitted_by', 'approved_by',
        'recurring_rule',
    )
    serializer_class = ExpenseSerializer
    filterset_class = ExpenseFilter
    search_fields = ['title', 'description', 'vendor_name', 'expense_number', 'payment_reference', 'notes']
    ordering_fields = ['expense_date', 'amount', 'total_amount', 'created_at', 'status']
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def perform_create(self, serializer):
        request = self.request
        if request.user and request.user.is_authenticated:
            serializer.save(created_by=request.user)
        else:
            serializer.save()

    # ── Workflow actions ─────────────────────────────────────────
    @action(detail=True, methods=['post'])
    def submit(self, request, pk=None):
        """Move a draft to submitted_awaiting_approval."""
        exp = self.get_object()
        if exp.status not in (Expense.Status.DRAFT, Expense.Status.SUBMITTED):
            return Response(
                {'detail': f'Cannot submit expense in "{exp.get_status_display()}" status.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        exp.status = Expense.Status.SUBMITTED
        exp.submitted_by = request.user
        exp.submitted_at = dj_timezone.now()
        exp.save(update_fields=['status', 'submitted_by', 'submitted_at', 'updated_at'])
        return Response(ExpenseSerializer(exp, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        exp = self.get_object()
        if exp.status != Expense.Status.SUBMITTED:
            return Response(
                {'detail': f'Cannot approve expense in "{exp.get_status_display()}" status.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        exp.status = Expense.Status.PAID  # approve + mark paid in one step
        exp.approved_by = request.user
        exp.approved_at = dj_timezone.now()
        exp.paid_at = dj_timezone.now()
        exp.rejection_reason = ''
        exp.save(update_fields=['status', 'approved_by', 'approved_at', 'paid_at', 'rejection_reason', 'updated_at'])
        return Response(ExpenseSerializer(exp, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        exp = self.get_object()
        if exp.status != Expense.Status.SUBMITTED:
            return Response(
                {'detail': f'Cannot reject an expense in "{exp.get_status_display()}" status.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        exp.status = Expense.Status.REJECTED
        exp.approved_by = request.user
        exp.approved_at = dj_timezone.now()
        exp.rejection_reason = request.data.get('reason', '')
        exp.save(update_fields=['status', 'approved_by', 'approved_at', 'rejection_reason', 'updated_at'])
        return Response(ExpenseSerializer(exp, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def mark_paid(self, request, pk=None):
        exp = self.get_object()
        if exp.status not in (Expense.Status.SUBMITTED, Expense.Status.PAID):
            return Response(
                {'detail': 'Only submitted or approved expenses can be marked paid.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        exp.status = Expense.Status.PAID
        exp.paid_at = dj_timezone.now()
        if request.data.get('payment_reference'):
            exp.payment_reference = request.data['payment_reference']
        exp.save(update_fields=['status', 'paid_at', 'payment_reference', 'updated_at'])
        return Response(ExpenseSerializer(exp, context={'request': request}).data)

    # ── Attachments ─────────────────────────────────────────────
    @action(detail=True, methods=['post'], parser_classes=[MultiPartParser])
    def upload_attachment(self, request, pk=None):
        exp = self.get_object()
        files = request.FILES.getlist('files') or ([request.FILES.get('file')] if request.FILES.get('file') else [])
        if not files:
            return Response({'detail': 'No file provided.'}, status=status.HTTP_400_BAD_REQUEST)
        created = []
        for f in files:
            att = ExpenseAttachment.objects.create(
                expense=exp, file=f,
                filename=f.name,
                file_size=f.size,
                mime_type=f.content_type or '',
                uploaded_by=request.user,
            )
            created.append(att)
        return Response(
            ExpenseAttachmentSerializer(created, many=True, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['delete'], url_path='attachments/(?P<attachment_id>[0-9]+)')
    def delete_attachment(self, request, pk=None, attachment_id=None):
        exp = self.get_object()
        att = exp.attachments.filter(pk=attachment_id).first()
        if not att:
            return Response({'detail': 'Attachment not found.'}, status=status.HTTP_404_NOT_FOUND)
        att.file.delete(save=False)
        att.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    # ── Comments ────────────────────────────────────────────────
    @action(detail=True, methods=['post'])
    def add_comment(self, request, pk=None):
        exp = self.get_object()
        body = (request.data.get('body') or '').strip()
        if not body:
            return Response({'detail': 'Comment body is required.'}, status=status.HTTP_400_BAD_REQUEST)
        comment = ExpenseComment.objects.create(
            expense=exp, author=request.user, body=body,
        )
        return Response(
            ExpenseCommentSerializer(comment, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    # ── Summary / Analytics ─────────────────────────────────────
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """High-level stats + breakdown charts for the dashboard tab."""
        qs = self.filter_queryset(self.get_queryset())

        total_amount = qs.aggregate(t=Sum('amount'))['t'] or Decimal('0')
        total_count = qs.count()
        pending = qs.filter(status__in=[Expense.Status.DRAFT, Expense.Status.SUBMITTED]).count()
        rejected = qs.filter(status=Expense.Status.REJECTED).count()
        paid = qs.filter(status=Expense.Status.PAID).count()
        billable_total = qs.filter(is_billable=True).aggregate(t=Sum('amount'))['t'] or Decimal('0')

        # category breakdown
        by_category = list(
            qs.values('category__name', 'category__color', 'category__icon')
            .annotate(total=Sum('amount'), count=Count('id'))
            .order_by('-total')
        )
        for row in by_category:
            row['category__name'] = row.get('category__name') or 'Uncategorized'

        # status breakdown
        by_status = list(
            qs.values('status').annotate(total=Sum('amount'), count=Count('id')).order_by('-total')
        )

        # spend over last 12 months
        months_back = int(request.query_params.get('months', 12))
        since = dj_timezone.now().date() - timedelta(days=months_back * 31)
        monthly = list(
            qs.filter(expense_date__gte=since)
            .annotate(month=TruncMonth('expense_date'))
            .values('month')
            .annotate(total=Sum('amount'), count=Count('id'))
            .order_by('month')
        )
        for row in monthly:
            m = row.get('month')
            row['month'] = m.strftime('%Y-%m') if m else ''

        # top vendors (free-text)
        top_vendors = list(
            qs.exclude(vendor_name='')
            .values('vendor_name')
            .annotate(total=Sum('amount'), count=Count('id'))
            .order_by('-total')[:10]
        )

        return Response({
            'total_amount': str(total_amount),
            'total_count': total_count,
            'pending': pending,
            'rejected': rejected,
            'paid': paid,
            'billable_total': str(billable_total),
            'by_category': by_category,
            'by_status': by_status,
            'monthly': monthly,
            'top_vendors': top_vendors,
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo expense records for the current tenant."""
        import random
        from apps.vehicles.models import Vehicle
        from apps.contacts.models import Contact
        categories, _ = ExpenseCategory.objects.get_or_create(name='Fuel', defaults={'code': 'FUEL', 'color': '#0ea5e9', 'icon': 'mdi-gas-station'})
        ExpenseCategory.objects.get_or_create(name='Maintenance', defaults={'code': 'MAINT', 'color': '#f59e0b', 'icon': 'mdi-wrench'})
        ExpenseCategory.objects.get_or_create(name='Permits', defaults={'code': 'PERM', 'color': '#8b5cf6', 'icon': 'mdi-file-certificate'})
        ExpenseCategory.objects.get_or_create(name='Insurance', defaults={'code': 'INS', 'color': '#10b981', 'icon': 'mdi-shield-account'})
        ExpenseCategory.objects.get_or_create(name='Software', defaults={'code': 'SaaS', 'color': '#6366f1', 'icon': 'mdi-application'})
        ExpenseCategory.objects.get_or_create(name='Rent', defaults={'code': 'RENT', 'color': '#ef4444', 'icon': 'mdi-home'})
        ExpenseCategory.objects.get_or_create(name='Tolls', defaults={'code': 'TOLL', 'color': '#14b8a6', 'icon': 'mdi-road-variant'})
        ExpenseCategory.objects.get_or_create(name='Office', defaults={'code': 'OFFICE', 'color': '#64748b', 'icon': 'mdi-domain'})
        all_cats = list(ExpenseCategory.objects.all())
        vehicles = list(Vehicle.objects.all()[:10])
        vendors = list(Contact.objects.filter(contact_type='vendor')[:5])
        drivers = list(Contact.objects.filter(contact_type='driver')[:5])
        titles = ['Shell truck stop', 'Gate toll', 'Office supplies', 'Annual insurance', 'Fleet SaaS', 'Workshop repair',
                  'Permit renewal', 'Fuel top-up', 'Parking fees', 'Tyre replacement']
        statuses = ['paid', 'paid', 'paid', 'submitted', 'draft', 'rejected', 'paid']
        methods = ['card', 'cash', 'bank', 'mobile', 'check']
        now = dj_timezone.now()
        created = 0
        for _ in range(36):
            cat = random.choice(all_cats)
            amt = round(random.uniform(15, 4500), 2)
            t = random.choice(titles)
            st = random.choice(statuses)
            d = now.date() - timedelta(days=random.randint(0, 180))
            kwargs = dict(
                title=f'{t} #{created + 1}',
                description=f'Demo {t.lower()} entry',
                category=cat,
                amount=amt,
                currency='USD',
                expense_date=d,
                vendor_name=random.choice(vendors).full_name if vendors and random.random() > 0.4 else random.choice(['Shell', 'BP', 'Chevron', 'Office Mart', 'Fleet Software Co', 'City Toll Authority']),
                vehicle=random.choice(vehicles) if vehicles and random.random() > 0.5 else None,
                contact=random.choice(vendors) if vendors and random.random() > 0.6 else None,
                payment_method=random.choice(methods),
                status=st,
                is_billable=random.random() > 0.7,
                created_by=request.user,
            )
            if st == 'paid':
                kwargs['paid_at'] = dj_timezone.now()
            if st == 'submitted':
                kwargs['submitted_by'] = request.user
                kwargs['submitted_at'] = dj_timezone.now()
            Expense.objects.create(**kwargs)
            created += 1
        return Response({'detail': f'Seeded {created} demo expense records.'})


# ── Recurring Expense ───────────────────────────────────────────────
class RecurringExpenseViewSet(viewsets.ModelViewSet):
    queryset = RecurringExpense.objects.select_related(
        'category', 'vehicle', 'contact', 'created_by',
    )
    serializer_class = RecurringExpenseSerializer
    filterset_fields = ['frequency', 'is_active', 'category', 'vehicle', 'contact']
    search_fields = ['title', 'vendor_name', 'description']
    ordering_fields = ['next_date', 'created_at', 'amount']

    def perform_create(self, serializer):
        request = self.request
        if request.user and request.user.is_authenticated:
            serializer.save(created_by=request.user)
        else:
            serializer.save()

    @action(detail=False, methods=['post'])
    def materialize(self, request):
        """Manually trigger generation for any due recurring rules."""
        from .tasks import materialize_recurring_expenses
        count = materialize_recurring_expenses()
        return Response({'detail': f'Generated {count} recurring expense(s).'})


# ── Expense Budget ──────────────────────────────────────────────────
class ExpenseBudgetViewSet(viewsets.ModelViewSet):
    queryset = ExpenseBudget.objects.select_related('vehicle', 'category', 'created_by')
    serializer_class = ExpenseBudgetSerializer
    filterset_fields = ['scope', 'month', 'category', 'vehicle']
    search_fields = ['notes', 'target_ref']
    ordering_fields = ['month', 'budget_amount']

    def perform_create(self, serializer):
        request = self.request
        if request.user and request.user.is_authenticated:
            serializer.save(created_by=request.user)
        else:
            serializer.save()

    def get_queryset(self):
        qs = super().get_queryset()
        # attach computed actual/variance/pct_used via annotate for summary use
        return qs

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Return budget vs actual for a given month (default current)."""
        month_param = request.query_params.get('month')
        if month_param:
            try:
                month = datetime.strptime(month_param, '%Y-%m-%d').date()
            except ValueError:
                month = date.today().replace(day=1)
        else:
            month = date.today().replace(day=1)
        next_month = (month.replace(day=28) + timedelta(days=4)).replace(day=1)
        budgets = self.get_queryset().filter(month=month)

        rows = []
        for b in budgets:
            actual = Decimal('0')
            exp_qs = Expense.objects.filter(
                expense_date__gte=month, expense_date__lt=next_month,
            )
            if b.scope == ExpenseBudget.Scope.FLEET:
                pass
            elif b.scope == ExpenseBudget.Scope.VEHICLE_TYPE:
                exp_qs = exp_qs.filter(vehicle__vehicle_type=b.target_ref)
            elif b.scope == ExpenseBudget.Scope.LOCATION:
                exp_qs = exp_qs.filter(vehicle__location=b.target_ref)
            elif b.scope == ExpenseBudget.Scope.CATEGORY and b.category:
                exp_qs = exp_qs.filter(category=b.category)
            elif b.scope == ExpenseBudget.Scope.VEHICLE and b.vehicle:
                exp_qs = exp_qs.filter(vehicle=b.vehicle)
            actual = exp_qs.aggregate(t=Sum('amount'))['t'] or Decimal('0')
            actual = Decimal(actual)
            budget_amt = Decimal(b.budget_amount)
            variance = budget_amt - actual
            pct_used = float((actual / budget_amt * Decimal('100'))) if budget_amt > 0 else 0
            rows.append({
                'id': b.id,
                'scope': b.scope,
                'scope_display': b.get_scope_display(),
                'target_ref': b.target_ref,
                'budget_label': b.label,
                'month': b.month.isoformat(),
                'budget_amount': str(budget_amt),
                'currency': b.currency,
                'actual_amount': str(actual),
                'variance': str(variance),
                'pct_used': round(pct_used, 1),
            })
        return Response({'rows': rows, 'month': month.isoformat()})


# ── Expense Attachment (stand-alone read) ────────────────────────────
class ExpenseAttachmentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ExpenseAttachment.objects.select_related('expense', 'uploaded_by')
    serializer_class = ExpenseAttachmentSerializer
    filterset_fields = ['expense']
    search_fields = ['filename']
