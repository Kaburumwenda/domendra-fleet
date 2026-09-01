from decimal import Decimal

from django.db.models import Sum, Count, Q
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import JSONParser, FormParser, MultiPartParser

from .models import FinancingLoan, FinancingPayment
from .serializers import FinancingLoanSerializer, FinancingPaymentSerializer


class FinancingLoanViewSet(viewsets.ModelViewSet):
    """CRUD + analytics for vehicle financing loans."""

    queryset = FinancingLoan.objects.select_related('vehicle').all()
    serializer_class = FinancingLoanSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status', 'bank_name', 'interest_type', 'vehicle']
    search_fields = ['loan_no', 'bank_name', 'account_no', 'vehicle__display_name', 'vehicle__license_plate']
    ordering_fields = ['disbursement_date', 'maturity_date', 'principal_amount', 'monthly_instalment', 'created_at']

    def perform_create(self, serializer):
        loan = serializer.save()
        # Auto-generate payment schedule if monthly_instalment and tenor are provided
        if loan.monthly_instalment and loan.tenor_months and loan.first_payment_date:
            _generate_payment_schedule(loan)

    @action(detail=True, methods=['get'])
    def summary(self, request, pk=None):
        """Loan-level summary: totals, payment progress, next due."""
        loan = self.get_object()
        payments = loan.payments.all()
        return Response({
            'loan_no': loan.loan_no,
            'vehicle': loan.vehicle.display_name if loan.vehicle else None,
            'status': loan.status,
            'principal_amount': str(loan.principal_amount),
            'total_payable': str(loan.total_payable),
            'total_paid': str(loan.total_paid),
            'outstanding_balance': str(loan.outstanding_balance),
            'progress_pct': str(loan.progress_pct),
            'payment_count_total': loan.payment_count_total,
            'payment_count_paid': loan.payment_count_paid,
            'payment_count_pending': loan.payment_count_pending,
            'next_due_date': loan.next_due_date,
            'next_due_amount': str(loan.next_due_amount),
            'is_overdue': loan.is_overdue,
            'days_past_due': loan.days_past_due,
            'ltv_ratio': str(loan.ltv_ratio),
            'payments': FinancingPaymentSerializer(payments, many=True).data,
        })

    @action(detail=True, methods=['post'])
    def generate_schedule(self, request, pk=None):
        """Generate or regenerate the payment schedule for a loan."""
        loan = self.get_object()
        loan.payments.all().delete()
        _generate_payment_schedule(loan)
        payments = loan.payments.all()
        return Response(
            FinancingPaymentSerializer(payments, many=True).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['patch'])
    def mark_closed(self, request, pk=None):
        """Mark a loan as fully closed/settled."""
        loan = self.get_object()
        loan.status = FinancingLoan.Status.CLOSED
        from django.utils import timezone as _tz
        loan.closed_date = _tz.now().date()
        loan.save()
        return Response(FinancingLoanSerializer(loan).data)

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Portfolio-level dashboard analytics across all loans."""
        qs = self.get_queryset()
        active = qs.filter(status='active')
        total_principal = qs.aggregate(t=Sum('principal_amount'))['t'] or Decimal('0')
        active_principal = active.aggregate(t=Sum('principal_amount'))['t'] or Decimal('0')
        total_outstanding = sum(
            loan.outstanding_balance for loan in active
        )

        # Payments due this month
        from datetime import date
        today = date.today()
        month_start = date(today.year, today.month, 1)
        if today.month == 12:
            month_end = date(today.year, 12, 31)
        else:
            month_end = date(today.year, today.month + 1, 1)
        month_end = month_end.replace(day=1) if today.month != 12 else month_end

        from django.db.models import F
        payments_this_month = FinancingPayment.objects.filter(
            loan__in=active,
            due_date__gte=month_start,
            due_date__lt=month_end,
        )
        due_this_month = payments_this_month.aggregate(t=Sum('amount'))['t'] or Decimal('0')
        paid_this_month = payments_this_month.filter(status='paid').aggregate(t=Sum('paid_amount'))['t'] or Decimal('0')

        overdue_loans = active.filter(
            payments__status='overdue'
        ).distinct()
        overdue_amount = sum(p.outstanding for p in FinancingPayment.objects.filter(loan__in=overdue_loans, status='overdue'))

        return Response({
            'total_loans': qs.count(),
            'active_loans': active.count(),
            'closed_loans': qs.filter(status='closed').count(),
            'defaulted_loans': qs.filter(status='defaulted').count(),
            'pending_loans': qs.filter(status='pending').count(),
            'total_principal': str(total_principal),
            'active_principal': str(active_principal),
            'total_outstanding': str(total_outstanding),
            'due_this_month': str(due_this_month),
            'paid_this_month': str(paid_this_month),
            'overdue_count': overdue_loans.count(),
            'overdue_amount': str(overdue_amount),
            'vehicles_financed': active.values('vehicle').distinct().count(),
        })


class FinancingPaymentViewSet(viewsets.ModelViewSet):
    """CRUD for individual financing payments / instalments."""

    queryset = FinancingPayment.objects.select_related('loan', 'loan__vehicle').all()
    serializer_class = FinancingPaymentSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]
    filterset_fields = ['status', 'payment_method', 'loan']
    search_fields = ['reference_no', 'loan__loan_no', 'loan__bank_name']
    ordering_fields = ['due_date', 'instalment_no', 'amount', 'paid_date']

    @action(detail=True, methods=['patch'], url_path='mark-paid')
    def mark_paid(self, request, pk=None):
        """Mark a payment as fully paid, optionally with evidence file upload."""
        payment = self.get_object()
        paid_amount = request.data.get('paid_amount', str(payment.amount))
        payment.paid_amount = Decimal(str(paid_amount))
        payment.status = FinancingPayment.Status.PAID
        if request.data.get('paid_date'):
            payment.paid_date = request.data.get('paid_date')
        else:
            from django.utils import timezone as _tz
            payment.paid_date = _tz.now().date()
        if request.data.get('payment_method'):
            payment.payment_method = request.data.get('payment_method')
        if request.data.get('reference_no'):
            payment.reference_no = request.data.get('reference_no')
        if request.data.get('remarks'):
            payment.remarks = request.data.get('remarks')
        # Handle evidence file upload
        if 'evidence_file' in request.FILES:
            # Delete old evidence if replacing
            if payment.evidence_file:
                payment.evidence_file.delete(save=False)
            payment.evidence_file = request.FILES['evidence_file']
        payment.save()
        return Response(FinancingPaymentSerializer(payment).data)

    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get upcoming payments (due within the next 30 days)."""
        from datetime import date, timedelta
        today = date.today()
        cutoff = today + timedelta(days=30)
        qs = self.get_queryset().filter(
            due_date__gte=today,
            due_date__lte=cutoff,
        ).exclude(status='paid').order_by('due_date')
        return Response(FinancingPaymentSerializer(qs, many=True).data)

    @action(detail=False, methods=['get'])
    def overdue(self, request):
        """Get all overdue payments."""
        qs = self.get_queryset().filter(status='overdue').order_by('due_date')
        return Response(FinancingPaymentSerializer(qs, many=True).data)


def _generate_payment_schedule(loan: FinancingLoan):
    """Generate monthly payment schedule for a loan."""
    import calendar
    from datetime import date
    from datetime import timedelta as _td

    if not loan.first_payment_date or not loan.tenor_months or not loan.monthly_instalment:
        return

    # Determine principal/interest split per instalment (simple approach)
    total_interest = loan._estimated_total_interest()
    per_instalment_interest = total_interest / Decimal(str(loan.tenor_months)) if loan.tenor_months else Decimal('0')
    per_instalment_principal = (loan.principal_amount) / Decimal(str(loan.tenor_months)) if loan.tenor_months else Decimal('0')

    current_date = loan.first_payment_date
    for i in range(1, loan.tenor_months + 1):
        FinancingPayment.objects.create(
            loan=loan,
            instalment_no=i,
            due_date=current_date,
            amount=loan.monthly_instalment,
            principal_component=per_instalment_principal.quantize(Decimal('0.01')),
            interest_component=per_instalment_interest.quantize(Decimal('0.01')),
        )
        # Next month
        year = current_date.year + (current_date.month // 12)
        month = (current_date.month % 12) + 1
        day = min(current_date.day, calendar.monthrange(year, month)[1])
        current_date = date(year, month, day)
