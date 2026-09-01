from datetime import timedelta

from django.db.models import Count, Q, Sum
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Lessor, LessorContract, LessorDocument, LessorPayment
from .serializers import (
    LessorContractSerializer,
    LessorDocumentSerializer,
    LessorPaymentSerializer,
    LessorSerializer,
)


class LessorViewSet(viewsets.ModelViewSet):
    queryset = Lessor.objects.all()
    serializer_class = LessorSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['lessor_type', 'is_active', 'country']
    search_fields = ['first_name', 'last_name', 'company_name', 'email', 'phone',
                     'national_id', 'registration_number', 'tax_id']
    ordering_fields = ['company_name', 'first_name', 'last_name', 'created_at']

    @action(detail=True, methods=['get'])
    def vehicles(self, request, pk=None):
        """List all vehicles leased from this lessor."""
        lessor = self.get_object()
        from apps.vehicles.models import Vehicle
        from apps.vehicles.serializers import VehicleSerializer
        vehicles = Vehicle.objects.filter(lessor=lessor, ownership='lease').order_by('-created_at')
        ser = VehicleSerializer(vehicles, many=True)
        return Response(ser.data)

    @action(detail=True, methods=['get'])
    def summary(self, request, pk=None):
        """Summary stats for a single lessor."""
        lessor = self.get_object()
        contracts = lessor.contracts.all()
        payments = lessor.payments.all()
        from apps.vehicles.models import Vehicle
        from decimal import Decimal

        vehicles = Vehicle.objects.filter(lessor=lessor).select_related('lessor')
        leased = vehicles.filter(ownership='lease')

        # Vehicle financials
        monthly_earnings = Decimal('0')
        total_deposit = Decimal('0')
        for v in leased:
            if v.lease_monthly_rate:
                monthly_earnings += v.lease_monthly_rate
            if v.deposit:
                total_deposit += v.deposit

        # Vehicle status breakdown
        status_breakdown = {}
        for v in leased:
            status_breakdown[v.status] = status_breakdown.get(v.status, 0) + 1

        # Contract monthly rate total
        contract_monthly = Decimal('0')
        for c in contracts.filter(status='active'):
            if c.monthly_rate:
                contract_monthly += c.monthly_rate

        return Response({
            'vehicle_count': leased.count(),
            'active_vehicles': leased.filter(status='active').count(),
            'inactive_vehicles': leased.exclude(status='active').count(),
            'total_lease_value': lessor.total_lease_value,
            'monthly_earnings': monthly_earnings,
            'total_deposit_held': total_deposit,
            'contract_monthly_total': contract_monthly,
            'contract_count': contracts.count(),
            'active_contracts': contracts.filter(status='active').count(),
            'payment_total': payments.aggregate(t=Sum('amount'))['t'] or 0,
            'payment_paid': payments.filter(status='paid').aggregate(t=Sum('amount'))['t'] or 0,
            'payment_pending': payments.filter(status__in=['pending', 'overdue']).aggregate(t=Sum('amount'))['t'] or 0,
            'payment_overdue': payments.filter(status='overdue').aggregate(t=Sum('amount'))['t'] or 0,
            'document_count': lessor.documents.count(),
            'vehicle_status_breakdown': status_breakdown,
            'vehicles': [
                {
                    'id': v.id,
                    'display_name': v.display_name,
                    'vin': v.vin,
                    'license_plate': v.license_plate,
                    'make': v.make,
                    'model': v.model,
                    'year': v.year,
                    'status': v.status,
                    'ownership': v.ownership,
                    'lease_start_date': v.lease_start_date,
                    'lease_end_date': v.lease_end_date,
                    'lease_monthly_rate': v.lease_monthly_rate or Decimal('0'),
                    'deposit': v.deposit or Decimal('0'),
                }
                for v in leased.order_by('-created_at')
            ],
            'paid_payments_count': payments.filter(status='paid').count(),
            'pending_payments_count': payments.filter(status='pending').count(),
            'overdue_payments_count': payments.filter(status='overdue').count(),
        })


class LessorContractViewSet(viewsets.ModelViewSet):
    queryset = LessorContract.objects.select_related('lessor')
    serializer_class = LessorContractSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['lessor', 'status', 'payment_frequency']
    ordering_fields = ['start_date', 'end_date', 'created_at', 'monthly_rate']

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        contract = self.get_object()
        contract.status = LessorContract.Status.ACTIVE
        contract.save(update_fields=['status', 'updated_at'])
        return Response(LessorContractSerializer(contract).data)

    @action(detail=True, methods=['post'])
    def terminate(self, request, pk=None):
        contract = self.get_object()
        contract.status = LessorContract.Status.TERMINATED
        contract.save(update_fields=['status', 'updated_at'])
        return Response(LessorContractSerializer(contract).data)


class LessorPaymentViewSet(viewsets.ModelViewSet):
    queryset = LessorPayment.objects.select_related('lessor', 'contract')
    serializer_class = LessorPaymentSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['lessor', 'status', 'payment_method', 'contract']
    ordering_fields = ['due_date', 'paid_date', 'created_at', 'amount']

    @action(detail=True, methods=['post'])
    def mark_paid(self, request, pk=None):
        payment = self.get_object()
        if payment.status == LessorPayment.PaymentStatus.PAID:
            return Response({'detail': 'Already paid.'}, status=status.HTTP_400_BAD_REQUEST)
        payment.status = LessorPayment.PaymentStatus.PAID
        payment.paid_date = timezone.now().date()
        payment.payment_method = request.data.get('payment_method', payment.payment_method)
        payment.reference = request.data.get('reference', payment.reference)
        payment.save(update_fields=['status', 'paid_date', 'payment_method', 'reference', 'updated_at'])
        return Response(LessorPaymentSerializer(payment).data)

    @action(detail=False, methods=['post'])
    def mark_overdue(self, request):
        """Mark all pending payments past their due_date as overdue."""
        today = timezone.now().date()
        count = LessorPayment.objects.filter(
            status=LessorPayment.PaymentStatus.PENDING,
            due_date__lt=today,
        ).update(status=LessorPayment.PaymentStatus.OVERDUE)
        return Response({'updated': count})


class LessorDocumentViewSet(viewsets.ModelViewSet):
    queryset = LessorDocument.objects.select_related('lessor')
    serializer_class = LessorDocumentSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['lessor', 'document_type']
    ordering_fields = ['created_at', 'expires_at']


class LessorAnalyticsView(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        lessors = Lessor.objects.all()
        active_lessors = lessors.filter(is_active=True)
        company_lessors = lessors.filter(lessor_type='company')
        individual_lessors = lessors.filter(lessor_type='individual')

        # Contracts
        contracts = LessorContract.objects.all()
        active_contracts = contracts.filter(status='active')
        expiring_30d = contracts.filter(
            status='active',
            end_date__lte=timezone.now().date() + timedelta(days=30),
            end_date__gte=timezone.now().date(),
        ).count()

        # Payments
        payments = LessorPayment.objects.all()
        total_paid = payments.filter(status='paid').aggregate(t=Sum('amount'))['t'] or 0
        total_pending = payments.filter(status__in=['pending', 'overdue']).aggregate(t=Sum('amount'))['t'] or 0
        overdue_count = payments.filter(status='overdue').count()
        overdue_amount = payments.filter(status='overdue').aggregate(t=Sum('amount'))['t'] or 0

        # Vehicles
        from apps.vehicles.models import Vehicle
        leased_vehicles = Vehicle.objects.filter(ownership='lease')
        from decimal import Decimal
        total_monthly_lease = Decimal('0')
        for v in leased_vehicles:
            if v.lease_monthly_rate:
                total_monthly_lease += v.lease_monthly_rate

        # Top lessors by vehicle count
        top_qs = list(
            lessors.annotate(
                vehicle_count=Count('vehicles', filter=Q(vehicles__ownership='lease'))
            ).order_by('-vehicle_count').values('id', 'company_name', 'first_name',
                                                 'last_name', 'vehicle_count')[:5]
        )
        # Build display_name in Python since it's a property, not a DB field
        for t in top_qs:
            l = Lessor(
                id=t['id'], lessor_type='company' if t.get('company_name') else 'individual',
                company_name=t.get('company_name', ''), first_name=t.get('first_name', ''),
                last_name=t.get('last_name', ''),
            )
            t['display_name'] = l.display_name
        top_lessors = top_qs

        # Monthly payments series — supports date filtering via query params
        start_date_str = request.query_params.get('start_date')
        end_date_str = request.query_params.get('end_date')
        months_count = int(request.query_params.get('months', 6))

        import datetime as _dt
        now = timezone.now()
        if start_date_str and end_date_str:
            try:
                d_start = _dt.date.fromisoformat(start_date_str)
                d_end = _dt.date.fromisoformat(end_date_str)
            except ValueError:
                d_start = (now.date().replace(day=1) - timedelta(days=(months_count - 1) * 30)).replace(day=1)
                d_end = now.date()
        else:
            d_start = (now.date().replace(day=1) - timedelta(days=(months_count - 1) * 30)).replace(day=1)
            d_end = now.date()

        monthly_series = []
        cursor = d_start.replace(day=1)
        while cursor <= d_end:
            month_start = cursor
            if cursor.month == 12:
                month_end = cursor.replace(year=cursor.year + 1, month=1, day=1)
            else:
                month_end = cursor.replace(month=cursor.month + 1, day=1)

            # Payments due/collected this month (all non-cancelled)
            month_collected = payments.filter(
                due_date__gte=month_start, due_date__lt=month_end
            ).exclude(status='cancelled')
            # Payments actually paid to lessors this month
            month_paid = payments.filter(
                paid_date__gte=month_start, paid_date__lt=month_end, status='paid'
            )
            monthly_series.append({
                'month': month_start.strftime('%b %Y'),
                'month_key': month_start.strftime('%Y-%m'),
                'collected': float(month_collected.aggregate(t=Sum('amount'))['t'] or 0),
                'paid': float(month_paid.aggregate(t=Sum('amount'))['t'] or 0),
            })
            cursor = month_end

        return Response({
            'summary': {
                'total_lessors': lessors.count(),
                'active_lessors': active_lessors.count(),
                'company_lessors': company_lessors.count(),
                'individual_lessors': individual_lessors.count(),
                'active_contracts': active_contracts.count(),
                'expiring_30d': expiring_30d,
                'leased_vehicles': leased_vehicles.count(),
                'total_monthly_lease': float(total_monthly_lease),
                'total_paid': float(total_paid),
                'total_pending': float(total_pending),
                'overdue_count': overdue_count,
                'overdue_amount': float(overdue_amount),
            },
            'top_lessors': top_lessors,
            'monthly_series': monthly_series,
        })


class LessorProfitLossView(viewsets.ViewSet):
    """Premium Profit & Loss statement endpoint.

    Builds a full P&L statement from across all fleet financial data sources:
      - Revenue: Rental agreements, add-ons, charges, payments
      - Variable Costs (COGS/OpEx): fuel, charging, service, idling, accidents, damage, lessor payments
      - Fixed Costs: lease, insurance, financing, depreciation
      - Gross Profit, Operating Profit, Net Profit
      - Monthly trend series with revenue / cost / profit
      - KPI cards with margins and period-over-period trends
    Supports ?start_date= & ?end_date= query params.
    """
    permission_classes = [IsAuthenticated]

    def list(self, request):
        import datetime as _dt
        from decimal import Decimal
        from apps.vehicles.models import Vehicle
        from apps.rentals.models import RentalAgreement, RentalPayment, RentalCharge, VehicleDamage
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport, InsuranceClaim
        from apps.inventory.models import PurchaseOrder

        # ── Date bounds ──
        start_str = request.query_params.get('start_date')
        end_str = request.query_params.get('end_date')
        now = timezone.now()
        now_date = now.date()

        if start_str and end_str:
            try:
                d_start = _dt.date.fromisoformat(start_str)
                d_end = _dt.date.fromisoformat(end_str)
            except ValueError:
                d_start = now_date.replace(day=1) - timedelta(days=30 * 5)
                d_end = now_date
        else:
            d_start = now_date.replace(day=1) - timedelta(days=30 * 5)
            d_end = now_date

        since = _dt.datetime.combine(d_start, _dt.time.min)
        until = _dt.datetime.combine(d_end + timedelta(days=1), _dt.time.min)
        prev_start = since - (until - since)

        # ── Only leased vehicles ──
        leased_vehicles = Vehicle.objects.filter(ownership='lease')
        leased_ids = list(leased_vehicles.values_list('id', flat=True))

        # ── REVENUE ──
        rentals = RentalAgreement.objects.exclude(status='draft').filter(vehicle_id__in=leased_ids)
        period_rentals = rentals.filter(created_at__gte=since, created_at__lt=until)
        prev_rentals = rentals.filter(created_at__gte=prev_start, created_at__lt=since)

        rental_revenue = float(period_rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))

        # Revenue breakdown: add-ons
        add_on_fields = ['insurance_premium', 'gps_fee', 'child_seat_fee',
                         'additional_driver_fee', 'delivery_fee']
        add_on_agg = period_rentals.aggregate(
            **{f: Sum(f) for f in add_on_fields}
        )
        add_on_lines = {}
        for f in add_on_fields:
            val = float(add_on_agg.get(f) or 0)
            if val:
                add_on_lines[f.replace('_', ' ').title()] = val

        base_rental_revenue = rental_revenue - sum(add_on_lines.values())
        prev_rental_revenue = float(prev_rentals.aggregate(
            t=Sum('total_amount'))['t'] or Decimal('0'))

        # RentalCharges per type (only for leased-vehicle rentals)
        charges_qs = RentalCharge.objects.filter(
            agreement__in=period_rentals, created_at__gte=since, created_at__lt=until)
        charge_by_type = {}
        for ch in charges_qs.values('charge_type').annotate(t=Sum('total_amount')):
            ct = ch['charge_type'] or 'other'
            charge_by_type[ct.replace('_', ' ').title()] = float(ch['t'] or 0)

        # Payments collected (cash inflow — leased vehicles only)
        payments = RentalPayment.objects.filter(
            status='completed', agreement__in=rentals, paid_at__gte=since, paid_at__lt=until)
        cash_collected = float(payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        prev_payments = RentalPayment.objects.filter(
            status='completed', agreement__in=rentals, paid_at__gte=prev_start, paid_at__lt=since)
        prev_cash = float(prev_payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))

        # Outstanding A/R (leased vehicles only)
        all_invoiced = float(rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        all_collected = float(RentalPayment.objects.filter(
            status='completed', agreement__in=rentals)
            .aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        outstanding = all_invoiced - all_collected

        # ── VARIABLE COSTS (Operating Expenses — leased vehicles only) ──
        fuel_cost = float(FuelTransaction.objects.filter(
            vehicle_id__in=leased_ids, date__gte=since, date__lt=until)
            .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
        prev_fuel = float(FuelTransaction.objects.filter(
            vehicle_id__in=leased_ids, date__gte=prev_start, date__lt=since)
            .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        charging_cost = float(ChargingSession.objects.filter(
            vehicle_id__in=leased_ids, start_time__gte=since, start_time__lt=until)
            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))

        service_cost = float(Service.objects.filter(
            vehicle_id__in=leased_ids, performed_at__gte=since, performed_at__lt=until)
            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_service = float(Service.objects.filter(
            vehicle_id__in=leased_ids, performed_at__gte=prev_start, performed_at__lt=since)
            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))

        # Idling waste (leased vehicles only)
        idling_cost = 0.0
        for ev in IdlingEvent.objects.filter(
                vehicle_id__in=leased_ids, start_time__gte=since, start_time__lt=until):
            idling_cost += float(ev.cost or 0)

        # Accident / damage / insurance claims (leased vehicles only)
        accident_cost = float(AccidentReport.objects.filter(
            vehicle_id__in=leased_ids, date__gte=since, date__lt=until)
            .aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
        damage_cost = float(VehicleDamage.objects.filter(
            agreement__in=rentals, recorded_at__gte=since, recorded_at__lt=until)
            .aggregate(t=Sum('repair_cost'))['t'] or Decimal('0'))
        insurance_claim_cost = float(InsuranceClaim.objects.filter(
            accident__vehicle_id__in=leased_ids,
            settled_date__gte=d_start, settled_date__lte=d_end, status='settled'
        ).aggregate(t=Sum('settled_amount'))['t'] or Decimal('0'))

        # Lessor lease payments made in period
        lessor_payments = LessorPayment.objects.filter(
            status='paid', paid_date__gte=d_start, paid_date__lte=d_end)
        lessor_payment_cost = float(lessor_payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))

        # Inventory purchase orders
        po_cost = float(PurchaseOrder.objects.filter(
            created_at__gte=since, created_at__lt=until,
            status__in=['received', 'part_received']).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        # ── FIXED COSTS (monthly allocation — leased vehicles only) ──
        months = max((until - since).days / 30, 1)
        vehicles = leased_vehicles
        lease_cost = float(sum(
            float(v.lease_monthly_rate or 0) for v in vehicles) * months)
        insurance_cost = float(sum(
            float(v.insurance_premium or 0) for v in vehicles) * months / 12.0)
        financing_cost = float(sum(
            float(v.monthly_payment or 0) for v in vehicles) * months)
        depreciation_cost = float(sum(
            float(v.annual_depreciation or 0) / 12.0 * months for v in vehicles))

        # ── Aggregations ──
        cogs = fuel_cost + charging_cost + idling_cost
        opex = service_cost + accident_cost + damage_cost + insurance_claim_cost + po_cost + lessor_payment_cost
        variable_total = cogs + opex
        fixed_total = lease_cost + insurance_cost + financing_cost + depreciation_cost
        total_costs = variable_total + fixed_total

        gross_profit = rental_revenue - variable_total
        operating_profit = gross_profit - fixed_total
        net_profit = rental_revenue - total_costs
        gross_margin = round((gross_profit / rental_revenue * 100), 1) if rental_revenue else 0
        operating_margin = round((operating_profit / rental_revenue * 100), 1) if rental_revenue else 0
        net_margin = round((net_profit / rental_revenue * 100), 1) if rental_revenue else 0

        # Previous-period totals for trend
        prev_variable = (prev_fuel + prev_service + float(ChargingSession.objects.filter(
            vehicle_id__in=leased_ids, start_time__gte=prev_start, start_time__lt=since).aggregate(
            t=Sum('cost'))['t'] or Decimal('0')))
        prev_total_costs = prev_variable  # approximation for trend
        prev_total_revenue = prev_rental_revenue

        revenue_change = round(((rental_revenue - prev_total_revenue) / prev_total_revenue * 100), 1) \
            if prev_total_revenue else 0
        cost_change = round(((total_costs - prev_total_costs) / prev_total_costs * 100), 1) \
            if prev_total_costs else 0
        cash_change = round(((cash_collected - prev_cash) / prev_cash * 100), 1) if prev_cash else 0
        profit_change = round(((net_profit - (prev_total_revenue - prev_total_costs)) /
                               abs(prev_total_revenue - prev_total_costs) * 100), 1) \
            if (prev_total_revenue - prev_total_costs) != 0 else 0

        # ── Build ordered P&L statement ──
        statement = [
            {'section': 'header', 'label': 'Revenue', 'amount': rental_revenue, 'type': 'revenue'},
            {'section': 'revenue', 'label': 'Base Rental Income', 'amount': base_rental_revenue, 'type': 'revenue'},
        ]
        for label, amt in add_on_lines.items():
            statement.append({'section': 'revenue', 'label': label, 'amount': amt, 'type': 'revenue'})
        for label, amt in charge_by_type.items():
            statement.append({'section': 'revenue', 'label': f'Charge — {label}', 'amount': amt, 'type': 'revenue'})
        statement.append({'section': 'subtotal', 'label': 'Total Revenue', 'amount': rental_revenue, 'type': 'revenue'})

        statement.append({'section': 'header', 'label': 'Cost of Goods Sold (COGS)', 'amount': cogs, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Fuel', 'amount': fuel_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'EV Charging', 'amount': charging_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Idling Waste', 'amount': idling_cost, 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total COGS', 'amount': cogs, 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Gross Profit', 'amount': gross_profit, 'type': 'profit'})

        statement.append({'section': 'header', 'label': 'Operating Expenses',
                          'amount': opex, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Maintenance & Service', 'amount': service_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Accident Damage', 'amount': accident_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Rental Vehicle Damage', 'amount': damage_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Insurance Claims (Settled)', 'amount': insurance_claim_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Inventory & Parts (PO)', 'amount': po_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Lessor Payments', 'amount': lessor_payment_cost, 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total Operating Expenses', 'amount': opex, 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Operating Profit', 'amount': operating_profit, 'type': 'profit'})

        statement.append({'section': 'header', 'label': 'Fixed Costs',
                          'amount': fixed_total, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Vehicle Lease Payments', 'amount': lease_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Insurance Premiums', 'amount': insurance_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Financing', 'amount': financing_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Depreciation', 'amount': depreciation_cost, 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total Fixed Costs', 'amount': fixed_total, 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Net Profit / Loss', 'amount': net_profit, 'type': 'profit'})

        # ── Monthly trend series ──
        monthly = []
        cursor = d_start.replace(day=1)
        m_end_limit = d_end.replace(day=1) if d_end.day == 1 else (
            d_end.replace(day=1) + timedelta(days=32)
        ).replace(day=1)
        while cursor <= m_end_limit:
            m_start = cursor
            m_next = cursor.replace(year=cursor.year + 1, month=1, day=1) \
                if cursor.month == 12 \
                else cursor.replace(month=cursor.month + 1, day=1)
            m_rev = float(RentalAgreement.objects.exclude(status='draft').filter(
                vehicle_id__in=leased_ids,
                created_at__gte=_dt.datetime.combine(m_start, _dt.time.min),
                created_at__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
            m_fuel = float(FuelTransaction.objects.filter(
                vehicle_id__in=leased_ids,
                date__gte=_dt.datetime.combine(m_start, _dt.time.min),
                date__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            m_chg = float(ChargingSession.objects.filter(
                vehicle_id__in=leased_ids,
                start_time__gte=_dt.datetime.combine(m_start, _dt.time.min),
                start_time__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_svc = float(Service.objects.filter(
                vehicle_id__in=leased_ids,
                performed_at__gte=_dt.datetime.combine(m_start, _dt.time.min),
                performed_at__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_lease = float(sum(float(v.lease_monthly_rate or 0) for v in vehicles))
            m_fixed = m_lease + float(sum(
                float(v.insurance_premium or 0) / 12.0 for v in vehicles)) + float(sum(
                float(v.monthly_payment or 0) for v in vehicles)) + float(sum(
                float(v.annual_depreciation or 0) / 12.0 for v in vehicles))
            m_cost = m_fuel + m_chg + m_svc + m_fixed
            monthly.append({
                'month': m_start.strftime('%b %Y'),
                'month_key': m_start.strftime('%Y-%m'),
                'revenue': m_rev,
                'costs': m_cost,
                'profit': m_rev - m_cost,
            })
            cursor = m_next

        # Trim series to date range
        keep = [m for m in monthly if
                _dt.date.fromisoformat(m['month_key'] + '-01') >= d_start.replace(day=1) and
                _dt.date.fromisoformat(m['month_key'] + '-01') <= d_end.replace(day=1)]
        monthly = keep or monthly

        # Cost distribution for pie chart
        cost_breakdown = [
            {'name': 'Fuel', 'value': round(fuel_cost, 2)},
            {'name': 'EV Charging', 'value': round(charging_cost, 2)},
            {'name': 'Service/Maintenance', 'value': round(service_cost, 2)},
            {'name': 'Lease Payments', 'value': round(lease_cost, 2)},
            {'name': 'Insurance', 'value': round(insurance_cost + insurance_claim_cost, 2)},
            {'name': 'Financing', 'value': round(financing_cost, 2)},
            {'name': 'Depreciation', 'value': round(depreciation_cost, 2)},
            {'name': 'Accidents/Damage', 'value': round(accident_cost + damage_cost, 2)},
            {'name': 'Lessor Payments', 'value': round(lessor_payment_cost, 2)},
            {'name': 'Inventory/Parts', 'value': round(po_cost, 2)},
            {'name': 'Idling Waste', 'value': round(idling_cost, 2)},
        ]

        return Response({
            'period': {'start': d_start.isoformat(), 'end': d_end.isoformat()},
            'summary': {
                'total_revenue': round(rental_revenue, 2),
                'total_costs': round(total_costs, 2),
                'gross_profit': round(gross_profit, 2),
                'operating_profit': round(operating_profit, 2),
                'net_profit': round(net_profit, 2),
                'gross_margin': gross_margin,
                'operating_margin': operating_margin,
                'net_margin': net_margin,
                'cash_collected': round(cash_collected, 2),
                'outstanding_ar': round(outstanding, 2),
                'cogs': round(cogs, 2),
                'opex': round(opex, 2),
                'fixed_costs': round(fixed_total, 2),
                'variable_costs': round(variable_total, 2),
            },
            'trends': {
                'revenue_change_pct': revenue_change,
                'cost_change_pct': cost_change,
                'cash_change_pct': cash_change,
                'profit_change_pct': profit_change,
                'prev_revenue': round(prev_total_revenue, 2),
                'prev_costs': round(prev_total_costs, 2),
                'prev_cash': round(prev_cash, 2),
            },
            'statement': statement,
            'monthly_series': monthly,
            'cost_breakdown': cost_breakdown,
        })


class LessorLocationsAnalysisView(viewsets.ViewSet):
    """Per-location financial analysis for leased vehicles.

    Groups all leased vehicles (ownership='lease') by their ``location`` text
    field (matched case-insensitively to ``Location.name``) and computes:
      - Vehicle count, active count, status breakdown
      - Monthly lease cost (SUM lease_monthly_rate)
      - Total deposit held (SUM deposit)
      - Revenue from rentals of leased vehicles at that location
      - Variable costs: fuel, charging, service, idling
      - Fixed costs: lease, insurance, financing, depreciation
      - Net profit / loss per location
    Supports ?start_date= & ?end_date= query params.
    """
    permission_classes = [IsAuthenticated]

    def list(self, request):
        import datetime as _dt
        from decimal import Decimal
        from apps.vehicles.models import Vehicle
        from apps.locations.models import Location
        from apps.rentals.models import RentalAgreement, RentalPayment
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service

        start_str = request.query_params.get('start_date')
        end_str = request.query_params.get('end_date')
        now = timezone.now()
        now_date = now.date()

        if start_str and end_str:
            try:
                d_start = _dt.date.fromisoformat(start_str)
                d_end = _dt.date.fromisoformat(end_str)
            except ValueError:
                d_start = now_date.replace(day=1) - timedelta(days=30 * 5)
                d_end = now_date
        else:
            d_start = now_date.replace(day=1) - timedelta(days=30 * 5)
            d_end = now_date

        since = _dt.datetime.combine(d_start, _dt.time.min)
        until = _dt.datetime.combine(d_end + timedelta(days=1), _dt.time.min)
        months = max((until - since).days / 30, 1)

        leased_qs = Vehicle.objects.filter(ownership='lease')

        # Build a distinct set of location names from leased vehicles
        loc_names = list(
            leased_qs.exclude(location__exact='')
            .values_list('location', flat=True)
            .distinct()
        )

        # Also include known Location names that might match by case
        all_locations = list(Location.objects.all().values_list('name', flat=True))

        # Merge unique names (case-insensitive dedup)
        seen = set()
        merged = []
        for n in loc_names + all_locations:
            key = (n or '').strip().lower()
            if key and key not in seen:
                seen.add(key)
                merged.append(n.strip())
        merged.sort()

        # Lookup Location metadata
        loc_meta = {}
        for loc in Location.objects.all():
            loc_meta[loc.name.strip().lower()] = loc

        vehicles_list = list(
            leased_qs.values(
                'id', 'location', 'status', 'lease_monthly_rate', 'deposit',
                'lease_start_date', 'lease_end_date', 'insurance_premium',
                'monthly_payment', 'purchase_price', 'salvage_value',
                'useful_life_years', 'depreciation_method', 'residual_value',
            )
        )

        # Helper: annual depreciation for a vehicle dict
        def ann_dep(v):
            if v.get('depreciation_method') == 'none':
                return 0.0
            pp = float(v.get('purchase_price') or 0)
            sv = float(v.get('salvage_value') or 0)
            ul = v.get('useful_life_years') or 0
            if not pp or not ul:
                return 0.0
            return (pp - sv) / ul

        # Group vehicle IDs by lowercased location name
        loc_vehicle_map = {}
        for v in vehicles_list:
            loc_key = (v.get('location') or '').strip().lower()
            if not loc_key:
                continue
            loc_vehicle_map.setdefault(loc_key, []).append(v)

        # Aggregate revenue/costs per vehicle for the period (leased only)
        leased_ids = [v['id'] for v in vehicles_list]

        # Revenue per vehicle from rentals
        rev_by_vehicle = {}
        for ra in RentalAgreement.objects.exclude(status='draft').filter(
                vehicle_id__in=leased_ids,
                created_at__gte=since, created_at__lt=until).values('vehicle_id', 'total_amount'):
            vid = ra['vehicle_id']
            rev_by_vehicle[vid] = rev_by_vehicle.get(vid, 0) + float(ra['total_amount'] or 0)

        # Cash collected per vehicle
        cash_by_vehicle = {}
        for rp in RentalPayment.objects.filter(
                status='completed',
                agreement__vehicle_id__in=leased_ids,
                paid_at__gte=since, paid_at__lt=until).values('agreement__vehicle_id', 'amount'):
            vid = rp['agreement__vehicle_id']
            cash_by_vehicle[vid] = cash_by_vehicle.get(vid, 0) + float(rp['amount'] or 0)

        # Fuel cost per vehicle
        fuel_by_vehicle = {}
        for ft in FuelTransaction.objects.filter(
                vehicle_id__in=leased_ids,
                date__gte=since, date__lt=until).values('vehicle_id').annotate(t=Sum('total_cost')):
            fuel_by_vehicle[ft['vehicle_id']] = float(ft['t'] or 0)

        # Charging cost per vehicle
        chg_by_vehicle = {}
        for cs in ChargingSession.objects.filter(
                vehicle_id__in=leased_ids,
                start_time__gte=since, start_time__lt=until).values('vehicle_id').annotate(t=Sum('cost')):
            chg_by_vehicle[cs['vehicle_id']] = float(cs['t'] or 0)

        # Service cost per vehicle
        svc_by_vehicle = {}
        for sv_ in Service.objects.filter(
                vehicle_id__in=leased_ids,
                performed_at__gte=since, performed_at__lt=until).values('vehicle_id').annotate(t=Sum('cost')):
            svc_by_vehicle[sv_['vehicle_id']] = float(sv_['t'] or 0)

        # Idling cost per vehicle (cost is a property — must iterate)
        idle_by_vehicle = {}
        for ie in IdlingEvent.objects.filter(
                vehicle_id__in=leased_ids,
                start_time__gte=since, start_time__lt=until):
            vid = ie.vehicle_id
            idle_by_vehicle[vid] = idle_by_vehicle.get(vid, 0) + float(ie.cost or 0)

        # Build per-location rows
        location_rows = []
        for loc_name in merged:
            loc_key = loc_name.lower()
            vs = loc_vehicle_map.get(loc_key, [])
            meta = loc_meta.get(loc_key)

            vehicle_ids = [v['id'] for v in vs]
            vehicle_count = len(vs)
            active_count = sum(1 for v in vs if v['status'] == 'active')
            inactive_count = vehicle_count - active_count

            # Status breakdown
            status_breakdown = {}
            for v in vs:
                s = v['status'] or 'unknown'
                status_breakdown[s] = status_breakdown.get(s, 0) + 1

            # Lease financials
            monthly_lease = sum(float(v.get('lease_monthly_rate') or 0) for v in vs)
            total_deposit = sum(float(v.get('deposit') or 0) for v in vs)

            # Fixed costs for the period
            lease_cost = monthly_lease * months
            insurance_cost = sum(float(v.get('insurance_premium') or 0) for v in vs) * months / 12.0
            financing_cost = sum(float(v.get('monthly_payment') or 0) for v in vs) * months
            depreciation_cost = sum(ann_dep(v) / 12.0 * months for v in vs)
            fixed_costs = lease_cost + insurance_cost + financing_cost + depreciation_cost

            # Revenue and variable costs
            revenue = sum(rev_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            cash = sum(cash_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            fuel = sum(fuel_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            charging = sum(chg_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            service = sum(svc_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            idling = sum(idle_by_vehicle.get(vid, 0) for vid in vehicle_ids)

            cogs = fuel + charging + idling
            opex = service
            variable_costs = cogs + opex
            total_costs = variable_costs + fixed_costs
            gross_profit = revenue - variable_costs
            net_profit = revenue - total_costs

            # Expiring leases (within 30 days)
            expiring_30d = 0
            for v in vs:
                end_d = v.get('lease_end_date')
                if end_d and (end_d - now_date).days <= 30 and (end_d - now_date).days >= 0:
                    expiring_30d += 1

            location_rows.append({
                'name': loc_name,
                'type': getattr(meta, 'type', 'other') if meta else 'other',
                'address': getattr(meta, 'address', '') if meta else '',
                'latitude': getattr(meta, 'latitude', None) if meta else None,
                'longitude': getattr(meta, 'longitude', None) if meta else None,
                'color': getattr(meta, 'color', '#6366f1') if meta else '#6366f1',
                'is_active': getattr(meta, 'is_active', True) if meta else True,
                'vehicle_count': vehicle_count,
                'active_vehicles': active_count,
                'inactive_vehicles': inactive_count,
                'status_breakdown': status_breakdown,
                'monthly_lease': round(monthly_lease, 2),
                'total_deposit': round(total_deposit, 2),
                'revenue': round(revenue, 2),
                'cash_collected': round(cash, 2),
                'fuel_cost': round(fuel, 2),
                'charging_cost': round(charging, 2),
                'service_cost': round(service, 2),
                'idling_cost': round(idling, 2),
                'cogs': round(cogs, 2),
                'opex': round(opex, 2),
                'variable_costs': round(variable_costs, 2),
                'fixed_costs': round(fixed_costs, 2),
                'total_costs': round(total_costs, 2),
                'gross_profit': round(gross_profit, 2),
                'net_profit': round(net_profit, 2),
                'expiring_30d': expiring_30d,
            })

        # Sort by net profit descending
        location_rows.sort(key=lambda r: r['net_profit'], reverse=True)

        # Overall summary
        total_leased = len(vehicles_list)
        total_locations = len(location_rows)
        total_vehicle_count = sum(r['vehicle_count'] for r in location_rows)
        total_monthly_lease = sum(r['monthly_lease'] for r in location_rows)
        total_deposit_held = sum(r['total_deposit'] for r in location_rows)
        total_revenue = sum(r['revenue'] for r in location_rows)
        total_costs = sum(r['total_costs'] for r in location_rows)
        total_net_profit = sum(r['net_profit'] for r in location_rows)

        # Top location by profit
        top_profit = location_rows[0] if location_rows else None
        top_loss = min(location_rows, key=lambda r: r['net_profit']) if location_rows else None

        return Response({
            'period': {'start': d_start.isoformat(), 'end': d_end.isoformat()},
            'summary': {
                'total_locations': total_locations,
                'total_leased_vehicles': total_vehicle_count,
                'active_vehicles': sum(r['active_vehicles'] for r in location_rows),
                'total_monthly_lease': round(total_monthly_lease, 2),
                'total_deposit_held': round(total_deposit_held, 2),
                'total_revenue': round(total_revenue, 2),
                'total_costs': round(total_costs, 2),
                'total_net_profit': round(total_net_profit, 2),
                'expiring_30d': sum(r['expiring_30d'] for r in location_rows),
                'top_profit_location': top_profit['name'] if top_profit else None,
                'top_profit_value': round(top_profit['net_profit'], 2) if top_profit else 0,
                'top_loss_location': top_loss['name'] if top_loss else None,
                'top_loss_value': round(top_loss['net_profit'], 2) if top_loss else 0,
            },
            'locations': location_rows,
        })
