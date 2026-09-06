import csv
import io
from datetime import timedelta
from decimal import Decimal

from django.db.models import Avg, Count, F, Q, Sum
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.vehicles.models import Vehicle
from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
from apps.issues.models import Issue, WorkOrder, TimeLog
from apps.services.models import Service
from apps.rentals.models import RentalAgreement, RentalPayment, RentalCharge, VehicleDamage
from apps.accidents.models import AccidentReport, InsuranceClaim
from apps.inventory.models import InventoryItem, PurchaseOrder
from apps.expenses.models import Expense, ExpenseCategory

from .models import ReportExecution, ReportTemplate, ScheduledReport
from .serializers import ReportExecutionSerializer, ReportTemplateSerializer, ScheduledReportSerializer


class ReportTemplateViewSet(viewsets.ModelViewSet):
    queryset = ReportTemplate.objects.all()
    serializer_class = ReportTemplateSerializer
    filterset_fields = ['report_type']
    search_fields = ['name', 'description']

    def get_queryset(self):
        """Auto-seed default templates if none exist yet."""
        qs = ReportTemplate.objects.all()
        if not qs.exists():
            defaults = [
                ('Cost per Mile Report', 'cost_per_mile', 'Vehicle cost per mile/hour analysis'),
                ('Fuel Efficiency Report', 'fuel_efficiency', 'MPG, fuel volume, and cost trends'),
                ('Mechanic Utilization Report', 'mechanic_utilization', 'Hours, work orders, turnaround'),
                ('Fleet Aging Report', 'fleet_aging', 'Age, book value, replacement forecast'),
                ('Fleet Benchmark Report', 'cost_summary', 'Compare vehicles vs fleet average'),
            ]
            for name, rtype, desc in defaults:
                ReportTemplate.objects.create(name=name, report_type=rtype, description=desc)
        return qs


class ScheduledReportViewSet(viewsets.ModelViewSet):
    queryset = ScheduledReport.objects.select_related('template')
    serializer_class = ScheduledReportSerializer
    filterset_fields = ['frequency', 'format', 'is_active']

    def perform_create(self, serializer):
        from datetime import timedelta
        from dateutil.relativedelta import relativedelta
        now = timezone.now()
        freq = serializer.validated_data.get('frequency', 'monthly')
        delta_map = {
            'daily': timedelta(days=1),
            'weekly': timedelta(weeks=1),
            'monthly': relativedelta(months=1),
            'quarterly': relativedelta(months=3),
        }
        delta = delta_map.get(freq, relativedelta(months=1))
        serializer.save(next_run=now + delta)


class ReportExecutionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ReportExecution.objects.select_related('template', 'scheduled_report')
    serializer_class = ReportExecutionSerializer
    filterset_fields = ['status', 'template']


class StandardReportsView(viewsets.ViewSet):
    """Standard report library endpoints."""

    @action(detail=False, methods=['get'], url_path='cost-per-mile')
    def cost_per_mile(self, request):
        days = int(request.query_params.get('days', 90))
        since = timezone.now() - timedelta(days=days)
        data = []
        for v in Vehicle.objects.all():
            fuel_cost = FuelTransaction.objects.filter(vehicle=v, date__gte=since).aggregate(t=Sum('total_cost'))['t'] or Decimal('0')
            service_cost = Service.objects.filter(vehicle=v, performed_at__gte=since).aggregate(t=Sum('cost'))['t'] or Decimal('0')
            miles = v.current_mileage
            total_cost = float(fuel_cost) + float(service_cost)
            cpm = total_cost / miles if miles > 0 else 0
            data.append({
                'vehicle': v.display_name, 'vin': v.vin, 'group': v.group.name if v.group else '',
                'fuel_cost': float(fuel_cost), 'service_cost': float(service_cost),
                'total_cost': total_cost, 'miles': miles, 'cost_per_mile': round(cpm, 4),
            })
        data.sort(key=lambda x: x['cost_per_mile'], reverse=True)
        return Response(data)

    @action(detail=False, methods=['get'], url_path='fuel-efficiency')
    def fuel_efficiency(self, request):
        days = int(request.query_params.get('days', 90))
        since = timezone.now() - timedelta(days=days)
        data = []
        for v in Vehicle.objects.filter(fuel_type__in=['ICE', 'Hybrid']):
            txs = FuelTransaction.objects.filter(vehicle=v, date__gte=since).order_by('date')
            total_gallons = txs.aggregate(t=Sum('quantity'))['t'] or 0
            total_cost = txs.aggregate(t=Sum('total_cost'))['t'] or Decimal('0')
            avg_price = float(total_cost) / total_gallons if total_gallons > 0 else 0
            # Calculate MPG from consecutive odometer readings
            txs_list = list(txs)
            total_miles = 0
            for i in range(1, len(txs_list)):
                if txs_list[i].odometer_reading and txs_list[i-1].odometer_reading:
                    total_miles += txs_list[i].odometer_reading - txs_list[i-1].odometer_reading
            mpg = total_miles / total_gallons if total_gallons > 0 else 0
            data.append({
                'vehicle': v.display_name, 'vin': v.vin,
                'total_gallons': round(total_gallons, 2),
                'total_cost': float(total_cost),
                'avg_price': round(avg_price, 3),
                'total_miles': total_miles,
                'mpg': round(mpg, 1),
            })
        return Response(data)

    @action(detail=False, methods=['get'], url_path='mechanic-utilization')
    def mechanic_utilization(self, request):
        days = int(request.query_params.get('days', 90))
        since = timezone.now() - timedelta(days=days)
        time_logs = TimeLog.objects.filter(clock_in__gte=since).select_related('mechanic')
        data = {}
        for log in time_logs:
            key = log.mechanic.full_name if log.mechanic else 'Unassigned'
            if key not in data:
                data[key] = {'mechanic': key, 'total_hours': 0, 'work_orders': set(), 'avg_turnaround': 0}
            data[key]['total_hours'] += log.hours or 0
            data[key]['work_orders'].add(log.work_order_id)
        result = []
        for v in data.values():
            wo_ids = v.pop('work_orders')
            wos = WorkOrder.objects.filter(id__in=wo_ids)
            turnaround_times = []
            for wo in wos:
                if wo.completed_at and wo.created_at:
                    turnaround_times.append((wo.completed_at - wo.created_at).total_seconds() / 3600)
            v['work_order_count'] = len(wo_ids)
            v['avg_turnaround_hours'] = round(sum(turnaround_times) / len(turnaround_times), 1) if turnaround_times else 0
            v['total_hours'] = round(v['total_hours'], 1)
            result.append(v)
        result.sort(key=lambda x: x['total_hours'], reverse=True)
        return Response(result)

    @action(detail=False, methods=['get'], url_path='fleet-aging')
    def fleet_aging(self, request):
        current_year = timezone.now().year
        data = []
        for v in Vehicle.objects.all():
            age = current_year - v.year if v.year else 0
            book_value = float(v.current_book_value or 0)
            annual_dep = float(v.annual_depreciation or 0)
            replacement_needed = age >= (v.useful_life_years or 10) if v.useful_life_years else age >= 10
            data.append({
                'vehicle': v.display_name, 'vin': v.vin, 'year': v.year, 'age': age,
                'purchase_price': float(v.purchase_price or 0), 'book_value': book_value,
                'annual_depreciation': annual_dep, 'useful_life_years': v.useful_life_years,
                'replacement_needed': replacement_needed,
                'status': v.status, 'group': v.group.name if v.group else '',
            })
        data.sort(key=lambda x: x['age'], reverse=True)
        return Response(data)

    @action(detail=False, methods=['get'], url_path='benchmark')
    def benchmark(self, request):
        """Compare each vehicle against fleet averages."""
        vehicles = Vehicle.objects.all()
        fuel_data = {}
        for v in vehicles:
            txs = FuelTransaction.objects.filter(vehicle=v)
            total_cost = txs.aggregate(t=Sum('total_cost'))['t'] or Decimal('0')
            total_gallons = txs.aggregate(t=Sum('quantity'))['t'] or 0
            fuel_data[v.id] = {
                'vehicle': v.display_name,
                'fuel_cost': float(total_cost),
                'fuel_gallons': float(total_gallons),
            }
        avg_cost = sum(d['fuel_cost'] for d in fuel_data.values()) / max(len(fuel_data), 1)
        for d in fuel_data.values():
            d['fleet_avg_cost'] = round(avg_cost, 2)
            d['variance_pct'] = round((d['fuel_cost'] - avg_cost) / avg_cost * 100, 1) if avg_cost else 0
        return Response(list(fuel_data.values()))

    # ─────────────────────────────────────────────────────────────────────
    #  FINANCIAL REPORTING — P&L, Revenue, Costs, ROI, Cash-Flow, Trends
    # ─────────────────────────────────────────────────────────────────────

    def _period_bounds(self, request):
        """Return (since, until) based on ?days= or ?start=&end= query params."""
        now = timezone.now()
        days = request.query_params.get('days')
        start = request.query_params.get('start')
        end = request.query_params.get('end')
        if start and end:
            from datetime import datetime
            try:
                from django.utils.dateparse import parse_datetime
                return parse_datetime(start), parse_datetime(end)
            except Exception:
                pass
        d = int(days or 30)
        return now - timedelta(days=d), now

    def _expense_total(self, since, until, status=None):
        """Sum of approved/paid expenses (amount + tax_amount) in [since, until).

        Only expenses that have been submitted (not draft) are counted in
        financial reports.  Pass ``status='paid'`` to restrict to paid only.
        """
        qs = Expense.objects.exclude(status='draft').filter(
            expense_date__gte=since.date() if hasattr(since, 'date') else since,
            expense_date__lt=until.date() if hasattr(until, 'date') else until,
        )
        if status:
            qs = qs.filter(status=status)
        agg = qs.aggregate(
            t=Sum(F('amount') + F('tax_amount')),
        )
        return float(agg['t'] or Decimal('0'))

    def _expense_by_category(self, since, until):
        """Return list of {category, amount, color, icon, type} for expenses."""
        qs = Expense.objects.exclude(status='draft').filter(
            expense_date__gte=since.date() if hasattr(since, 'date') else since,
            expense_date__lt=until.date() if hasattr(until, 'date') else until,
        )
        rows = qs.values('category__name', 'category__color', 'category__icon', 'category__type').annotate(
            t=Sum(F('amount') + F('tax_amount')),
        ).order_by('-t')
        return [
            {
                'category': r['category__name'] or 'Uncategorized',
                'amount': float(r['t'] or 0),
                'color': r['category__color'] or '#6366f1',
                'icon': r['category__icon'] or 'mdi-cash',
                'type': r['category__type'] or 'operating',
            }
            for r in rows
        ]

    @action(detail=False, methods=['get'], url_path='financial-pdf')
    def financial_pdf(self, request):
        """Generate a comprehensive PDF financial report with charts.

        Page 1  — Cover / Business details (tenant name, address, KPIs)
        Page 2+ — Revenue breakdown, cost breakdown, P&L, vehicle ROI table

        Accepts the same ?start=&end= params as other financial endpoints.
        Optional ?sections=business_details,executive_summary,revenue_charts,
            cost_analysis,profit_loss,vehicle_roi to include only specific sections.
        """
        from apps.tenants.models import Tenant
        from django.db import connection
        from .pdf_report import generate_financial_pdf

        since, until = self._period_bounds(request)
        period_str = f'{since.strftime("%Y-%m-%d")} — {until.strftime("%Y-%m-%d")}'

        # Resolve tenant from the current connection schema
        try:
            tenant = Tenant.objects.get(schema_name=connection.schema_name)
        except Tenant.DoesNotExist:
            tenant = None
            period_str = period_str  # fallback

        # Gather data by calling the internal methods
        overview = self.financial_overview(request).data
        revenue = self.revenue_breakdown(request).data
        costs = self.cost_breakdown(request).data
        roi = self.vehicle_roi(request).data

        if tenant is None:
            return Response({'detail': 'Tenant not found for current schema.'}, status=400)

        # Parse optional sections parameter
        sections_param = request.query_params.get('sections', '').strip()
        sections = [s.strip() for s in sections_param.split(',') if s.strip()] if sections_param else None

        return generate_financial_pdf(tenant, overview, revenue, costs, roi, period_str,
                                     sections=sections)

    @action(detail=False, methods=['get'], url_path='financial-overview')
    def financial_overview(self, request):
        """Master financial dashboard: P&L summary, revenue/cost split, margins, trends."""
        since, until = self._period_bounds(request)
        prev_start = since - (until - since)
        vehicles = Vehicle.objects.all()

        # ── REVENUE (Rental) ──
        rentals_qs = RentalAgreement.objects.exclude(status='draft')
        prev_rentals = rentals_qs.filter(created_at__gte=prev_start, created_at__lt=since)
        rentals_qs = rentals_qs.filter(created_at__gte=since, created_at__lt=until)

        rental_revenue = float(rentals_qs.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        prev_rental_revenue = float(prev_rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))

        # Collected payments (cash-flow)
        payments_qs = RentalPayment.objects.filter(status='completed',
                                                    paid_at__gte=since, paid_at__lt=until)
        cash_collected = float(payments_qs.aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        prev_payments = RentalPayment.objects.filter(status='completed',
                                                      paid_at__gte=prev_start, paid_at__lt=since)
        prev_cash = float(prev_payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))

        # Outstanding (AR)
        all_invoiced = float(RentalAgreement.objects.exclude(status='draft')
                             .aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        all_collected = float(RentalPayment.objects.filter(status='completed')
                              .aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        outstanding = all_invoiced - all_collected

        # ── OPERATING COSTS ──
        fuel_cost = float(FuelTransaction.objects.filter(date__gte=since, date__lt=until)
                          .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
        prev_fuel = float(FuelTransaction.objects.filter(date__gte=prev_start, date__lt=since)
                          .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        charging_cost = float(ChargingSession.objects.filter(start_time__gte=since, start_time__lt=until)
                              .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_charging = float(ChargingSession.objects.filter(start_time__gte=prev_start, start_time__lt=since)
                              .aggregate(t=Sum('cost'))['t'] or Decimal('0'))

        service_cost = float(Service.objects.filter(performed_at__gte=since, performed_at__lt=until)
                            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_service = float(Service.objects.filter(performed_at__gte=prev_start, performed_at__lt=since)
                            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))

        # Idling waste
        idling_cost = 0.0
        idling_qs = IdlingEvent.objects.filter(start_time__gte=since, start_time__lt=until)
        for ev in idling_qs:
            idling_cost += float(ev.cost or 0)

        # Accident / damage costs
        accident_cost = float(AccidentReport.objects.filter(date__gte=since, date__lt=until)
                              .aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
        damage_cost = float(VehicleDamage.objects.filter(recorded_at__gte=since, recorded_at__lt=until)
                           .aggregate(t=Sum('repair_cost'))['t'] or Decimal('0'))

        # ── FIXED COSTS (monthly allocations) ──
        months = max((until - since).days / 30, 1)
        lease_cost = float(sum(float(v.lease_monthly_rate or 0) for v in vehicles if v.ownership == 'lease') * months)
        insurance_cost = float(sum(float(v.insurance_premium or 0) for v in vehicles) * months)
        financing_cost = float(sum(float(v.monthly_payment or 0) for v in vehicles) * months)
        depreciation_cost = float(sum(float(v.annual_depreciation or 0) / 12 * months for v in vehicles))

        # ── GENERAL EXPENSES (from Expenses module) ──
        expense_cost = self._expense_total(since, until)
        prev_expense = self._expense_total(prev_start, since)

        total_opex = fuel_cost + charging_cost + service_cost + idling_cost + accident_cost + damage_cost + expense_cost
        total_fixed = lease_cost + insurance_cost + financing_cost + depreciation_cost
        total_cost = total_opex + total_fixed
        prev_total_cost = prev_fuel + prev_charging + prev_service + prev_expense

        # ── P&L ──
        gross_profit = rental_revenue - total_opex
        net_profit = rental_revenue - total_cost
        gross_margin = round((gross_profit / rental_revenue * 100), 1) if rental_revenue else 0
        net_margin = round((net_profit / rental_revenue * 100), 1) if rental_revenue else 0

        # ── EBITDA & EBITDA Margin ──
        # EBITDA = Net Profit + Depreciation + Interest/Financing + Taxes
        # Taxes estimated at 16% of pre-tax profit (adjustable)
        ebitda = net_profit + depreciation_cost + financing_cost
        ebitda_margin = round((ebitda / rental_revenue * 100), 1) if rental_revenue else 0

        # ── Breakeven Analysis ──
        # Breakeven revenue = Fixed Costs / (1 - Variable Cost Ratio)
        variable_ratio = (total_opex / rental_revenue) if rental_revenue else 0
        breakeven_revenue = total_fixed / (1 - variable_ratio) if (rental_revenue and variable_ratio < 1) else total_fixed + total_opex
        breakeven_revenue = round(breakeven_revenue, 2)
        margin_of_safety = rental_revenue - breakeven_revenue
        margin_of_safety_pct = round((margin_of_safety / rental_revenue * 100), 1) if rental_revenue else 0

        # ── Operating Leverage ──
        # % change in profit for a 1% change in revenue
        contribution_margin = rental_revenue - total_opex
        operating_leverage = round((contribution_margin / net_profit), 1) if net_profit and net_profit > 0 else 0

        # ── Financial Ratios ──
        current_ratio = round((cash_collected / total_cost), 2) if total_cost else 0  # Liquidity proxy
        # Days Sales Outstanding (DSO) — how fast we collect
        period_days = max((until - since).days, 1)
        dso = round((outstanding / rental_revenue * period_days), 1) if rental_revenue else 0
        # Quick ratio (same as current here since no inventory liquidation)
        quick_ratio = current_ratio
        # Return on Assets (ROA) using total book value of fleet
        total_book_value = float(sum(float(v.current_book_value or 0) for v in vehicles))
        roa = round((net_profit / total_book_value * 100), 1) if total_book_value else 0

        # ── TRENDS ──
        revenue_change = round(((rental_revenue - prev_rental_revenue) / prev_rental_revenue * 100), 1) if prev_rental_revenue else 0
        cost_change = round(((total_opex - prev_total_cost) / prev_total_cost * 100), 1) if prev_total_cost else 0
        cash_change = round(((cash_collected - prev_cash) / prev_cash * 100), 1) if prev_cash else 0

        return Response({
            'period': {'start': since.isoformat(), 'end': until.isoformat()},
            'summary': {
                'revenue': rental_revenue,
                'cash_collected': cash_collected,
                'outstanding': outstanding,
                'operating_costs': total_opex,
                'fixed_costs': total_fixed,
                'total_costs': total_cost,
                'gross_profit': gross_profit,
                'net_profit': net_profit,
                'gross_margin': gross_margin,
                'net_margin': net_margin,
                'ebitda': round(ebitda, 2),
                'ebitda_margin': ebitda_margin,
                'breakeven_revenue': breakeven_revenue,
                'margin_of_safety': round(margin_of_safety, 2),
                'margin_of_safety_pct': margin_of_safety_pct,
                'operating_leverage': operating_leverage,
                'current_ratio': current_ratio,
                'quick_ratio': quick_ratio,
                'dso': dso,
                'roa': roa,
                'total_book_value': round(total_book_value, 2),
            },
            'trends': {
                'revenue_change_pct': revenue_change,
                'cost_change_pct': cost_change,
                'cash_change_pct': cash_change,
                'prev_revenue': prev_rental_revenue,
                'prev_costs': prev_total_cost,
                'prev_cash': prev_cash,
            },
        })

    @action(detail=False, methods=['get'], url_path='revenue-breakdown')
    def revenue_breakdown(self, request):
        """Detailed revenue analysis by category, customer, vehicle, and period."""
        since, until = self._period_bounds(request)
        rentals = RentalAgreement.objects.exclude(status='draft').filter(created_at__gte=since, created_at__lt=until)

        # By rate period
        by_period = {}
        for r in rentals:
            key = r.rate_period or 'daily'
            if key not in by_period:
                by_period[key] = {'period': key, 'count': 0, 'revenue': 0.0}
            by_period[key]['count'] += 1
            by_period[key]['revenue'] += float(r.total_amount)

        # By customer
        by_customer = {}
        for r in rentals:
            name = r.customer.full_name if r.customer else 'Walk-in'
            if name not in by_customer:
                by_customer[name] = {'customer': name, 'count': 0, 'revenue': 0.0}
            by_customer[name]['count'] += 1
            by_customer[name]['revenue'] += float(r.total_amount)
        by_customer_list = sorted(by_customer.values(), key=lambda x: x['revenue'], reverse=True)[:10]

        # By vehicle
        by_vehicle = {}
        for r in rentals:
            name = r.vehicle.display_name if r.vehicle else 'Unassigned'
            if name not in by_vehicle:
                by_vehicle[name] = {'vehicle': name, 'count': 0, 'revenue': 0.0, 'driver_cost': 0.0, 'net': 0.0}
            by_vehicle[name]['count'] += 1
            by_vehicle[name]['revenue'] += float(r.total_amount)
            by_vehicle[name]['driver_cost'] += float(r.driver_daily_rate or 0)
            by_vehicle[name]['net'] = by_vehicle[name]['revenue'] - by_vehicle[name]['driver_cost']
        by_vehicle_list = sorted(by_vehicle.values(), key=lambda x: x['revenue'], reverse=True)[:10]

        # Add-on revenue
        addons = rentals.aggregate(
            insurance=Sum('insurance_premium'),
            gps=Sum('gps_fee'),
            child_seat=Sum('child_seat_fee'),
            additional_driver=Sum('additional_driver_fee'),
            delivery=Sum('delivery_fee'),
        )
        addon_revenue = {k: float(v or 0) for k, v in addons.items()}

        # Rental charges breakdown
        charges = RentalCharge.objects.filter(agreement__in=rentals)
        by_charge_type = {}
        for ch in charges:
            key = ch.charge_type
            if key not in by_charge_type:
                by_charge_type[key] = {'type': key, 'count': 0, 'total': 0.0}
            by_charge_type[key]['count'] += 1
            by_charge_type[key]['total'] += float(ch.total_amount)

        # Payment methods
        payments = RentalPayment.objects.filter(status='completed', paid_at__gte=since, paid_at__lt=until)
        by_method = {}
        for p in payments:
            key = p.payment_method
            if key not in by_method:
                by_method[key] = {'method': key, 'count': 0, 'amount': 0.0}
            by_method[key]['count'] += 1
            by_method[key]['amount'] += float(p.amount)

        # Revenue trend (daily buckets)
        span_days = (until - since).days
        bucket = 'daily' if span_days <= 31 else 'weekly'
        if bucket == 'daily':
            delta = timedelta(days=1)
        else:
            delta = timedelta(days=7)
        trend = []
        cur = since
        while cur < until:
            nxt = min(cur + delta, until)
            day_revenue = float(RentalAgreement.objects.exclude(status='draft')
                                .filter(created_at__gte=cur, created_at__lt=nxt)
                                .aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
            day_payments = float(RentalPayment.objects.filter(status='completed', paid_at__gte=cur, paid_at__lt=nxt)
                                .aggregate(t=Sum('amount'))['t'] or Decimal('0'))
            trend.append({
                'date': cur.strftime('%Y-%m-%d'),
                'revenue': round(day_revenue, 2),
                'payments': round(day_payments, 2),
            })
            cur = nxt

        return Response({
            'by_period': list(by_period.values()),
            'by_customer': by_customer_list,
            'by_vehicle': by_vehicle_list,
            'addon_revenue': addon_revenue,
            'charge_types': list(by_charge_type.values()),
            'payment_methods': list(by_method.values()),
            'trend': trend,
            'total_revenue': float(rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0')),
            'addon_total': sum(addon_revenue.values()),
        })

    @action(detail=False, methods=['get'], url_path='cost-breakdown')
    def cost_breakdown(self, request):
        """Detailed cost analysis by category, vehicle, and time."""
        since, until = self._period_bounds(request)
        vehicles = Vehicle.objects.all()
        months = max((until - since).days / 30, 1)

        # Operating costs by category
        fuel_cost = float(FuelTransaction.objects.filter(date__gte=since, date__lt=until)
                          .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
        charging_cost = float(ChargingSession.objects.filter(start_time__gte=since, start_time__lt=until)
                              .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        service_cost = float(Service.objects.filter(performed_at__gte=since, performed_at__lt=until)
                            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        accident_cost = float(AccidentReport.objects.filter(date__gte=since, date__lt=until)
                              .aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
        damage_cost = float(VehicleDamage.objects.filter(recorded_at__gte=since, recorded_at__lt=until)
                           .aggregate(t=Sum('repair_cost'))['t'] or Decimal('0'))
        idling_cost = sum(float(ev.cost or 0) for ev in IdlingEvent.objects.filter(start_time__gte=since, start_time__lt=until))

        # Fixed costs (allocated monthly)
        lease = float(sum(float(v.lease_monthly_rate or 0) for v in vehicles if v.ownership == 'lease') * months)
        insurance = float(sum(float(v.insurance_premium or 0) for v in vehicles) * months)
        financing = float(sum(float(v.monthly_payment or 0) for v in vehicles) * months)
        depreciation = float(sum(float(v.annual_depreciation or 0) / 12 * months for v in vehicles))

        # ── General expenses (from Expenses module) ──
        expense_total = self._expense_total(since, until)
        expense_by_cat = self._expense_by_category(since, until)

        by_category = [
            {'category': 'Fuel', 'amount': fuel_cost, 'type': 'variable', 'icon': 'mdi-gas-station', 'color': '#f59e0b'},
            {'category': 'EV Charging', 'amount': charging_cost, 'type': 'variable', 'icon': 'mdi-ev-station', 'color': '#10b981'},
            {'category': 'Service & Maintenance', 'amount': service_cost, 'type': 'variable', 'icon': 'mdi-wrench', 'color': '#3b82f6'},
            {'category': 'Idling Waste', 'amount': idling_cost, 'type': 'variable', 'icon': 'mdi-engine', 'color': '#ef4444'},
            {'category': 'Accident Damage', 'amount': accident_cost, 'type': 'variable', 'icon': 'mdi-car-emergency', 'color': '#dc2626'},
            {'category': 'Vehicle Damage', 'amount': damage_cost, 'type': 'variable', 'icon': 'mdi-car-wrench', 'color': '#f97316'},
        ]
        # Add each expense category as its own line
        for ec in expense_by_cat:
            by_category.append({
                'category': f'Expense — {ec["category"]}',
                'amount': ec['amount'],
                'type': 'variable',
                'icon': ec['icon'],
                'color': ec['color'],
            })
        by_category.extend([
            {'category': 'Lease Payments', 'amount': lease, 'type': 'fixed', 'icon': 'mdi-file-sign', 'color': '#6366f1'},
            {'category': 'Insurance', 'amount': insurance, 'type': 'fixed', 'icon': 'mdi-shield-car', 'color': '#8b5cf6'},
            {'category': 'Financing', 'amount': financing, 'type': 'fixed', 'icon': 'mdi-bank', 'color': '#ec4899'},
            {'category': 'Depreciation', 'amount': depreciation, 'type': 'fixed', 'icon': 'mdi-chart-line-variant', 'color': '#64748b'},
        ])

        # Cost by vehicle
        by_vehicle = []
        for v in vehicles:
            v_fuel = float(FuelTransaction.objects.filter(vehicle=v, date__gte=since, date__lt=until)
                          .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            v_charge = float(ChargingSession.objects.filter(vehicle=v, start_time__gte=since, start_time__lt=until)
                            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            v_service = float(Service.objects.filter(vehicle=v, performed_at__gte=since, performed_at__lt=until)
                              .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            v_fixed = (float(v.lease_monthly_rate or 0) + float(v.insurance_premium or 0) +
                       float(v.monthly_payment or 0)) * months + float(v.annual_depreciation or 0) / 12 * months
            total = v_fuel + v_charge + v_service + v_fixed
            if total > 0:
                by_vehicle.append({
                    'vehicle': v.display_name, 'fuel_cost': v_fuel, 'charging_cost': v_charge,
                    'service_cost': v_service, 'fixed_cost': round(v_fixed, 2), 'total_cost': round(total, 2),
                })
        by_vehicle.sort(key=lambda x: x['total_cost'], reverse=True)

        # Service cost by type
        services = Service.objects.filter(performed_at__gte=since, performed_at__lt=until)
        by_service_type = {}
        for s in services:
            key = s.service_type
            if key not in by_service_type:
                by_service_type[key] = {'type': key, 'count': 0, 'cost': 0.0}
            by_service_type[key]['count'] += 1
            by_service_type[key]['cost'] += float(s.cost)

        total_variable = sum(c['amount'] for c in by_category if c['type'] == 'variable')
        total_fixed = sum(c['amount'] for c in by_category if c['type'] == 'fixed')

        return Response({
            'by_category': by_category,
            'by_vehicle': by_vehicle[:15],
            'by_service_type': list(by_service_type.values()),
            'by_expense_category': expense_by_cat,
            'expense_total': round(expense_total, 2),
            'total_variable': round(total_variable, 2),
            'total_fixed': round(total_fixed, 2),
            'total': round(total_variable + total_fixed, 2),
        })

    @action(detail=False, methods=['get'], url_path='vehicle-roi')
    def vehicle_roi(self, request):
        """Per-vehicle ROI: revenue earned vs total cost of ownership."""
        since, until = self._period_bounds(request)
        months = max((until - since).days / 30, 1)
        data = []

        for v in Vehicle.objects.all().select_related('group'):
            # Revenue from rentals
            agreements_qs = RentalAgreement.objects.filter(
                vehicle=v, status__in=['active', 'completed', 'overdue'],
                created_at__gte=since, created_at__lt=until
            )
            agreement_count = agreements_qs.count()
            revenue = float(agreements_qs.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))

            # Costs
            fuel = float(FuelTransaction.objects.filter(vehicle=v, date__gte=since, date__lt=until)
                         .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            fuel += float(ChargingSession.objects.filter(vehicle=v, start_time__gte=since, start_time__lt=until)
                         .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            service = float(Service.objects.filter(vehicle=v, performed_at__gte=since, performed_at__lt=until)
                           .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            exp = float(Expense.objects.exclude(status='draft').filter(
                vehicle=v,
                expense_date__gte=since.date() if hasattr(since, 'date') else since,
                expense_date__lt=until.date() if hasattr(until, 'date') else until,
            ).aggregate(t=Sum(F('amount') + F('tax_amount')))['t'] or Decimal('0'))
            fixed = (float(v.lease_monthly_rate or 0) + float(v.insurance_premium or 0) +
                     float(v.monthly_payment or 0)) * months + float(v.annual_depreciation or 0) / 12 * months

            total_cost = fuel + service + exp + fixed
            net = revenue - total_cost
            roi = round((net / total_cost * 100), 1) if total_cost > 0 else 0
            cost_per_mile = round(total_cost / (v.current_mileage or 1), 4) if v.current_mileage else 0
            revenue_per_mile = round(revenue / (v.current_mileage or 1), 4) if v.current_mileage else 0

            data.append({
                'vehicle': v.display_name, 'vin': v.vin,
                'group': v.group.name if v.group else '',
                'agreement_count': agreement_count,
                'revenue': round(revenue, 2),
                'fuel_cost': round(fuel, 2),
                'service_cost': round(service, 2),
                'expense_cost': round(exp, 2),
                'fixed_cost': round(fixed, 2),
                'total_cost': round(total_cost, 2),
                'net_profit': round(net, 2),
                'roi_pct': roi,
                'cost_per_mile': cost_per_mile,
                'revenue_per_mile': revenue_per_mile,
                'book_value': float(v.current_book_value or 0),
                'ownership': v.ownership,
            })
        data.sort(key=lambda x: x['net_profit'], reverse=True)
        return Response(data)

    @action(detail=False, methods=['get'], url_path='cash-flow')
    def cash_flow(self, request):
        """Cash-flow statement: inflows (payments) vs outflows (costs) by period."""
        since, until = self._period_bounds(request)
        # Break into buckets (daily/weekly/monthly)
        span_days = (until - since).days
        if span_days <= 14:
            bucket = 'daily'
        elif span_days <= 90:
            bucket = 'weekly'
        else:
            bucket = 'monthly'

        buckets = []
        cur = since
        delta = timedelta(days=1 if bucket == 'daily' else 7 if bucket == 'weekly' else 30)
        while cur < until:
            nxt = min(cur + delta, until)
            inflow = float(RentalPayment.objects.filter(
                status='completed', paid_at__gte=cur, paid_at__lt=nxt
            ).aggregate(t=Sum('amount'))['t'] or Decimal('0'))
            outflow = float(FuelTransaction.objects.filter(
                date__gte=cur, date__lt=nxt
            ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            outflow += float(Service.objects.filter(
                performed_at__gte=cur, performed_at__lt=nxt
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            outflow += float(ChargingSession.objects.filter(
                start_time__gte=cur, start_time__lt=nxt
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            outflow += self._expense_total(cur, nxt, status='paid')
            net = inflow - outflow
            buckets.append({
                'date': cur.strftime('%Y-%m-%d'),
                'inflow': round(inflow, 2),
                'outflow': round(outflow, 2),
                'net': round(net, 2),
            })
            cur = nxt

        total_inflow = sum(b['inflow'] for b in buckets)
        total_outflow = sum(b['outflow'] for b in buckets)
        return Response({
            'bucket': bucket,
            'buckets': buckets,
            'total_inflow': round(total_inflow, 2),
            'total_outflow': round(total_outflow, 2),
            'net_cash_flow': round(total_inflow - total_outflow, 2),
        })

    @action(detail=False, methods=['get'], url_path='profit-loss')
    def profit_loss(self, request):
        """Full P&L statement with line items, monthly series, cost breakdown.

        Aggregates across the entire fleet (all vehicles / all rentals).
        Supports ?days= or ?start=&end= (ISO datetimes) just like the other
        financial endpoints.
        """
        import datetime as _dt
        from decimal import Decimal
        from apps.rentals.models import RentalAgreement, RentalPayment, RentalCharge, VehicleDamage
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport, InsuranceClaim
        from apps.inventory.models import PurchaseOrder

        since, until = self._period_bounds(request)
        # For monthly series we need date objects
        if isinstance(since, _dt.datetime):
            d_start = since.date()
        else:
            d_start = since
        if isinstance(until, _dt.datetime):
            d_end = until.date()
        else:
            d_end = until
        prev_start = since - (until - since)

        vehicles = Vehicle.objects.all()

        # ── REVENUE ──
        rentals_qs = RentalAgreement.objects.exclude(status='draft')
        period_rentals = rentals_qs.filter(created_at__gte=since, created_at__lt=until)
        prev_rentals = rentals_qs.filter(created_at__gte=prev_start, created_at__lt=since)

        rental_revenue = float(period_rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        prev_rental_revenue = float(prev_rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))

        # Add-on breakdown
        add_on_fields = ['insurance_premium', 'gps_fee', 'child_seat_fee',
                         'additional_driver_fee', 'delivery_fee']
        add_on_agg = period_rentals.aggregate(**{f: Sum(f) for f in add_on_fields})
        add_on_lines = {}
        for f in add_on_fields:
            val = float(add_on_agg.get(f) or 0)
            if val:
                add_on_lines[f.replace('_', ' ').title()] = val
        base_rental_revenue = rental_revenue - sum(add_on_lines.values())

        # RentalCharges
        charges_qs = RentalCharge.objects.filter(created_at__gte=since, created_at__lt=until)
        charge_by_type = {}
        for ch in charges_qs.values('charge_type').annotate(t=Sum('total_amount')):
            ct = ch['charge_type'] or 'other'
            charge_by_type[ct.replace('_', ' ').title()] = float(ch['t'] or 0)

        # Payments / cash
        payments = RentalPayment.objects.filter(status='completed', paid_at__gte=since, paid_at__lt=until)
        cash_collected = float(payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        prev_payments = RentalPayment.objects.filter(status='completed', paid_at__gte=prev_start, paid_at__lt=since)
        prev_cash = float(prev_payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))

        all_invoiced = float(RentalAgreement.objects.exclude(status='draft')
                             .aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        all_collected = float(RentalPayment.objects.filter(status='completed')
                              .aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        outstanding = all_invoiced - all_collected

        # ── VARIABLE COSTS ──
        fuel_cost = float(FuelTransaction.objects.filter(
            date__gte=since, date__lt=until).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
        charging_cost = float(ChargingSession.objects.filter(
            start_time__gte=since, start_time__lt=until).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        service_cost = float(Service.objects.filter(
            performed_at__gte=since, performed_at__lt=until).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_service = float(Service.objects.filter(
            performed_at__gte=prev_start, performed_at__lt=since).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_fuel = float(FuelTransaction.objects.filter(
            date__gte=prev_start, date__lt=since).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        idling_cost = sum(float(ev.cost or 0) for ev in
                          IdlingEvent.objects.filter(start_time__gte=since, start_time__lt=until))

        accident_cost = float(AccidentReport.objects.filter(
            date__gte=since, date__lt=until).aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
        damage_cost = float(VehicleDamage.objects.filter(
            recorded_at__gte=since, recorded_at__lt=until).aggregate(t=Sum('repair_cost'))['t'] or Decimal('0'))
        insurance_claim_cost = float(InsuranceClaim.objects.filter(
            settled_date__gte=d_start, settled_date__lte=d_end, status='settled'
        ).aggregate(t=Sum('settled_amount'))['t'] or Decimal('0'))
        po_cost = float(PurchaseOrder.objects.filter(
            created_at__gte=since, created_at__lt=until,
            status__in=['received', 'part_received']).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        # ── FIXED COSTS ──
        months = max((until - since).days / 30, 1)
        lease_cost = float(sum(float(v.lease_monthly_rate or 0) for v in vehicles if v.ownership == 'lease') * months)
        insurance_cost = float(sum(float(v.insurance_premium or 0) for v in vehicles) * months / 12.0)
        financing_cost = float(sum(float(v.monthly_payment or 0) for v in vehicles) * months)
        depreciation_cost = float(sum(float(v.annual_depreciation or 0) / 12.0 * months for v in vehicles))

        # ── GENERAL EXPENSES (from Expenses module) ──
        expense_cost = self._expense_total(since, until)
        prev_expense = self._expense_total(prev_start, since)
        expense_by_cat = self._expense_by_category(since, until)

        cogs = fuel_cost + charging_cost + idling_cost
        opex = service_cost + accident_cost + damage_cost + insurance_claim_cost + po_cost + expense_cost
        variable_total = cogs + opex
        fixed_total = lease_cost + insurance_cost + financing_cost + depreciation_cost
        total_costs = variable_total + fixed_total

        gross_profit = rental_revenue - variable_total
        operating_profit = gross_profit - fixed_total
        net_profit = rental_revenue - total_costs
        gross_margin = round((gross_profit / rental_revenue * 100), 1) if rental_revenue else 0
        operating_margin = round((operating_profit / rental_revenue * 100), 1) if rental_revenue else 0
        net_margin = round((net_profit / rental_revenue * 100), 1) if rental_revenue else 0

        prev_variable = prev_fuel + prev_service + prev_expense + float(ChargingSession.objects.filter(
            start_time__gte=prev_start, start_time__lt=since).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_total_costs = prev_variable
        prev_total_revenue = prev_rental_revenue

        revenue_change = round(((rental_revenue - prev_total_revenue) / prev_total_revenue * 100), 1) if prev_total_revenue else 0
        cost_change = round(((total_costs - prev_total_costs) / prev_total_costs * 100), 1) if prev_total_costs else 0
        cash_change = round(((cash_collected - prev_cash) / prev_cash * 100), 1) if prev_cash else 0
        prev_profit = prev_total_revenue - prev_total_costs
        profit_change = round(((net_profit - prev_profit) / abs(prev_profit) * 100), 1) if prev_profit != 0 else 0

        # ── Statement ──
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

        statement.append({'section': 'header', 'label': 'Operating Expenses', 'amount': opex, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Maintenance & Service', 'amount': service_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Accident Damage', 'amount': accident_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Rental Vehicle Damage', 'amount': damage_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Insurance Claims (Settled)', 'amount': insurance_claim_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Inventory & Parts (PO)', 'amount': po_cost, 'type': 'cost'})
        for ec in expense_by_cat:
            if ec['amount'] > 0:
                statement.append({'section': 'cost', 'label': f'Expense — {ec["category"]}', 'amount': ec['amount'], 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total Operating Expenses', 'amount': opex, 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Operating Profit', 'amount': operating_profit, 'type': 'profit'})

        statement.append({'section': 'header', 'label': 'Fixed Costs', 'amount': fixed_total, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Vehicle Lease Payments', 'amount': lease_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Insurance Premiums', 'amount': insurance_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Financing', 'amount': financing_cost, 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Depreciation', 'amount': depreciation_cost, 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total Fixed Costs', 'amount': fixed_total, 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Net Profit / Loss', 'amount': net_profit, 'type': 'profit'})

        # ── Monthly series ──
        monthly = []
        cursor = d_start.replace(day=1)
        m_end_limit = d_end.replace(day=1)
        while cursor <= m_end_limit:
            m_start = cursor
            m_next = cursor.replace(year=cursor.year + 1, month=1, day=1) \
                if cursor.month == 12 else cursor.replace(month=cursor.month + 1, day=1)
            m_rev = float(RentalAgreement.objects.exclude(status='draft').filter(
                created_at__gte=_dt.datetime.combine(m_start, _dt.time.min),
                created_at__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
            m_fuel = float(FuelTransaction.objects.filter(
                date__gte=_dt.datetime.combine(m_start, _dt.time.min),
                date__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            m_chg = float(ChargingSession.objects.filter(
                start_time__gte=_dt.datetime.combine(m_start, _dt.time.min),
                start_time__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_svc = float(Service.objects.filter(
                performed_at__gte=_dt.datetime.combine(m_start, _dt.time.min),
                performed_at__lt=_dt.datetime.combine(m_next, _dt.time.min),
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_fixed = (float(sum(float(v.lease_monthly_rate or 0) for v in vehicles if v.ownership == 'lease')) +
                       float(sum(float(v.insurance_premium or 0) / 12.0 for v in vehicles)) +
                       float(sum(float(v.monthly_payment or 0) for v in vehicles)) +
                       float(sum(float(v.annual_depreciation or 0) / 12.0 for v in vehicles)))
            m_exp = self._expense_total(
                _dt.datetime.combine(m_start, _dt.time.min),
                _dt.datetime.combine(m_next, _dt.time.min),
            )
            m_cost = m_fuel + m_chg + m_svc + m_fixed + m_exp
            monthly.append({
                'month': m_start.strftime('%b %Y'),
                'month_key': m_start.strftime('%Y-%m'),
                'revenue': m_rev,
                'costs': m_cost,
                'profit': m_rev - m_cost,
            })
            cursor = m_next

        # ── Cost breakdown for pie/bar ──
        cost_breakdown = [
            {'name': 'Fuel', 'value': round(fuel_cost, 2)},
            {'name': 'EV Charging', 'value': round(charging_cost, 2)},
            {'name': 'Service/Maintenance', 'value': round(service_cost, 2)},
            {'name': 'Lease Payments', 'value': round(lease_cost, 2)},
            {'name': 'Insurance', 'value': round(insurance_cost + insurance_claim_cost, 2)},
            {'name': 'Financing', 'value': round(financing_cost, 2)},
            {'name': 'Depreciation', 'value': round(depreciation_cost, 2)},
            {'name': 'Accidents/Damage', 'value': round(accident_cost + damage_cost, 2)},
            {'name': 'Inventory/Parts', 'value': round(po_cost, 2)},
            {'name': 'Idling Waste', 'value': round(idling_cost, 2)},
        ]
        for ec in expense_by_cat:
            if ec['amount'] > 0:
                cost_breakdown.append({'name': f'Expense — {ec["category"]}', 'value': round(ec['amount'], 2)})

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

    # ─────────────────────────────────────────────────────────────────────
    #  LOCATIONS ANALYSIS — per-location financial breakdown
    # ─────────────────────────────────────────────────────────────────────

    def _ann_dep_dict(self, v):
        """Annual depreciation from a vehicle dict."""
        if v.get('depreciation_method') == 'none':
            return 0.0
        pp = float(v.get('purchase_price') or 0)
        sv = float(v.get('salvage_value') or 0)
        ul = v.get('useful_life_years') or 0
        if not pp or not ul:
            return 0.0
        return (pp - sv) / ul

    def locations_analysis(self, request):
        """Per-location financial analysis covering ALL vehicles.

        Groups vehicles by ``Vehicle.location`` text field (matched
        case-insensitively to ``Location.name``) and computes revenue,
        COGS, OpEx, fixed costs and net profit per location.

        Supports the same ``?days=`` / ``?start=&end=`` params used by the
        other financial endpoints.
        """
        import datetime as _dt
        from decimal import Decimal
        from apps.locations.models import Location
        from apps.rentals.models import RentalAgreement, RentalPayment, RentalCharge, VehicleDamage
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport, InsuranceClaim
        from apps.inventory.models import PurchaseOrder

        since, until = self._period_bounds(request)
        if isinstance(since, _dt.datetime):
            d_start = since.date()
        else:
            d_start = since
        if isinstance(until, _dt.datetime):
            d_end = until.date()
        else:
            d_end = until
        months = max((until - since).days / 30, 1)

        # ── All vehicles, grouped by location text field ──
        vehicles_list = list(
            Vehicle.objects.all().values(
                'id', 'location', 'status', 'ownership',
                'lease_monthly_rate', 'deposit', 'lease_start_date',
                'lease_end_date', 'insurance_premium', 'monthly_payment',
                'purchase_price', 'salvage_value', 'useful_life_years',
                'depreciation_method', 'residual_value',
            )
        )

        # Merge distinct location names (vehicle.location + Location.name)
        loc_names_raw = list(
            Vehicle.objects.exclude(location__exact='')
            .values_list('location', flat=True).distinct()
        )
        all_loc_names = list(Location.objects.all().values_list('name', flat=True))
        seen = set()
        merged = []
        for n in list(loc_names_raw) + all_loc_names:
            key = (n or '').strip().lower()
            if key and key not in seen:
                seen.add(key)
                merged.append(n.strip())
        merged.sort()

        loc_meta = {}
        for loc in Location.objects.all():
            loc_meta[loc.name.strip().lower()] = loc

        # Group vehicle dicts by lowercased location
        loc_vehicle_map = {}
        for v in vehicles_list:
            loc_key = (v.get('location') or '').strip().lower()
            if not loc_key:
                continue
            loc_vehicle_map.setdefault(loc_key, []).append(v)

        all_ids = [v['id'] for v in vehicles_list]

        # ── Pre-aggregate per-vehicle figures ──
        # Revenue (from RentalAgreement excluding drafts)
        rev_by_vehicle = {}
        for ra in RentalAgreement.objects.exclude(status='draft').filter(
                vehicle_id__in=all_ids,
                created_at__gte=since, created_at__lt=until).values('vehicle_id', 'total_amount'):
            vid = ra['vehicle_id']
            rev_by_vehicle[vid] = rev_by_vehicle.get(vid, 0) + float(ra['total_amount'] or 0)

        # Cash collected
        cash_by_vehicle = {}
        for rp in RentalPayment.objects.filter(
                status='completed',
                agreement__vehicle_id__in=all_ids,
                paid_at__gte=since, paid_at__lt=until).values('agreement__vehicle_id', 'amount'):
            vid = rp['agreement__vehicle_id']
            cash_by_vehicle[vid] = cash_by_vehicle.get(vid, 0) + float(rp['amount'] or 0)

        # Rental charges (add-on revenue)
        charge_by_vehicle = {}
        for rc in RentalCharge.objects.filter(
                created_at__gte=since, created_at__lt=until,
                agreement__vehicle_id__in=all_ids).values('agreement__vehicle_id', 'total_amount'):
            vid = rc['agreement__vehicle_id']
            charge_by_vehicle[vid] = charge_by_vehicle.get(vid, 0) + float(rc['total_amount'] or 0)

        # Fuel cost
        fuel_by_vehicle = {}
        for ft in FuelTransaction.objects.filter(
                vehicle_id__in=all_ids,
                date__gte=since, date__lt=until).values('vehicle_id').annotate(t=Sum('total_cost')):
            fuel_by_vehicle[ft['vehicle_id']] = float(ft['t'] or 0)

        # Charging cost
        chg_by_vehicle = {}
        for cs in ChargingSession.objects.filter(
                vehicle_id__in=all_ids,
                start_time__gte=since, start_time__lt=until).values('vehicle_id').annotate(t=Sum('cost')):
            chg_by_vehicle[cs['vehicle_id']] = float(cs['t'] or 0)

        # Service cost
        svc_by_vehicle = {}
        for sv_ in Service.objects.filter(
                vehicle_id__in=all_ids,
                performed_at__gte=since, performed_at__lt=until).values('vehicle_id').annotate(t=Sum('cost')):
            svc_by_vehicle[sv_['vehicle_id']] = float(sv_['t'] or 0)

        # Idling cost (property — must iterate)
        idle_by_vehicle = {}
        for ie in IdlingEvent.objects.filter(
                vehicle_id__in=all_ids,
                start_time__gte=since, start_time__lt=until):
            vid = ie.vehicle_id
            idle_by_vehicle[vid] = idle_by_vehicle.get(vid, 0) + float(ie.cost or 0)

        # Accident cost
        accident_by_vehicle = {}
        for ar in AccidentReport.objects.filter(
                date__gte=since, date__lt=until).exclude(vehicle__isnull=True).values('vehicle_id').annotate(
                t=Sum('estimated_damage_cost')):
            accident_by_vehicle[ar['vehicle_id']] = float(ar['t'] or 0)

        # General expenses by vehicle
        exp_by_vehicle = {}
        for ex in Expense.objects.exclude(status='draft').filter(
                vehicle_id__in=all_ids,
                expense_date__gte=since.date() if hasattr(since, 'date') else since,
                expense_date__lt=until.date() if hasattr(until, 'date') else until,
        ).values('vehicle_id').annotate(t=Sum(F('amount') + F('tax_amount'))):
            exp_by_vehicle[ex['vehicle_id']] = float(ex['t'] or 0)

        # Damage cost
        damage_by_vehicle = {}
        for vd in VehicleDamage.objects.filter(
                recorded_at__gte=since, recorded_at__lt=until,
                agreement__vehicle_id__in=all_ids).values('agreement__vehicle_id', 'repair_cost'):
            vid = vd['agreement__vehicle_id']
            damage_by_vehicle[vid] = damage_by_vehicle.get(vid, 0) + float(vd['repair_cost'] or 0)

        # Purchase orders (by vehicle — via work order / service link if available;
        # otherwise assign to PO's vehicle if it has one; fallback: distribute to all)
        po_cost_total = float(PurchaseOrder.objects.filter(
            created_at__gte=since, created_at__lt=until,
            status__in=['received', 'part_received']).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        # ── Build per-location rows ──
        location_rows = []
        for loc_name in merged:
            loc_key = loc_name.lower()
            vs = loc_vehicle_map.get(loc_key, [])
            meta = loc_meta.get(loc_key)

            vehicle_ids = [v['id'] for v in vs]
            vehicle_count = len(vs)
            active_count = sum(1 for v in vs if v['status'] == 'active')
            leased_count = sum(1 for v in vs if v['ownership'] == 'lease')
            owned_count = sum(1 for v in vs if v['ownership'] == 'self')

            status_breakdown = {}
            for v in vs:
                s = v['status'] or 'unknown'
                status_breakdown[s] = status_breakdown.get(s, 0) + 1

            # Lease financials
            monthly_lease = sum(float(v.get('lease_monthly_rate') or 0) for v in vs if v.get('ownership') == 'lease')
            total_deposit = sum(float(v.get('deposit') or 0) for v in vs if v.get('ownership') == 'lease')

            # Fixed costs
            lease_cost = monthly_lease * months
            insurance_cost = sum(float(v.get('insurance_premium') or 0) for v in vs) * months / 12.0
            financing_cost = sum(float(v.get('monthly_payment') or 0) for v in vs) * months
            depreciation_cost = sum(self._ann_dep_dict(v) / 12.0 * months for v in vs)
            fixed_costs = lease_cost + insurance_cost + financing_cost + depreciation_cost

            # Revenue and variable costs
            revenue = sum(rev_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            charges = sum(charge_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            total_revenue = revenue + charges
            cash = sum(cash_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            fuel = sum(fuel_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            charging = sum(chg_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            service = sum(svc_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            idling = sum(idle_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            accident = sum(accident_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            damage = sum(damage_by_vehicle.get(vid, 0) for vid in vehicle_ids)
            exp = sum(exp_by_vehicle.get(vid, 0) for vid in vehicle_ids)

            cogs = fuel + charging + idling
            opex = service + accident + damage + exp
            variable_costs = cogs + opex
            total_costs = variable_costs + fixed_costs
            gross_profit = total_revenue - variable_costs
            net_profit = total_revenue - total_costs

            # Margins
            gross_margin = round(gross_profit / total_revenue * 100, 1) if total_revenue else 0
            net_margin = round(net_profit / total_revenue * 100, 1) if total_revenue else 0

            # Expiring leases (within 30 days)
            now_date = timezone.now().date()
            expiring_30d = 0
            for v in vs:
                end_d = v.get('lease_end_date')
                if end_d and v.get('ownership') == 'lease':
                    days_left = (end_d - now_date).days
                    if 0 <= days_left <= 30:
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
                'leased_vehicles': leased_count,
                'owned_vehicles': owned_count,
                'status_breakdown': status_breakdown,
                'monthly_lease': round(monthly_lease, 2),
                'total_deposit': round(total_deposit, 2),
                'expiring_30d': expiring_30d,
                'revenue': round(revenue, 2),
                'rental_charges': round(charges, 2),
                'total_revenue': round(total_revenue, 2),
                'cash_collected': round(cash, 2),
                'fuel_cost': round(fuel, 2),
                'charging_cost': round(charging, 2),
                'service_cost': round(service, 2),
                'idling_cost': round(idling, 2),
                'accident_cost': round(accident, 2),
                'damage_cost': round(damage, 2),
                'expense_cost': round(exp, 2),
                'cogs': round(cogs, 2),
                'opex': round(opex, 2),
                'variable_costs': round(variable_costs, 2),
                'lease_cost': round(lease_cost, 2),
                'insurance_cost': round(insurance_cost, 2),
                'financing_cost': round(financing_cost, 2),
                'depreciation_cost': round(depreciation_cost, 2),
                'fixed_costs': round(fixed_costs, 2),
                'total_costs': round(total_costs, 2),
                'gross_profit': round(gross_profit, 2),
                'net_profit': round(net_profit, 2),
                'gross_margin': gross_margin,
                'net_margin': net_margin,
            })

        # Sort by net profit descending
        location_rows.sort(key=lambda r: r['net_profit'], reverse=True)

        # Summary
        total_vehicles = len(vehicles_list)
        total_locations = len(location_rows)
        sum_revenue = sum(r['total_revenue'] for r in location_rows)
        sum_costs = sum(r['total_costs'] for r in location_rows)
        sum_gross = sum(r['gross_profit'] for r in location_rows)
        sum_net = sum(r['net_profit'] for r in location_rows)
        sum_monthly_lease = sum(r['monthly_lease'] for r in location_rows)
        sum_deposit = sum(r['total_deposit'] for r in location_rows)
        sum_cogs = sum(r['cogs'] for r in location_rows)
        sum_opex = sum(r['opex'] for r in location_rows)
        sum_fixed = sum(r['fixed_costs'] for r in location_rows)
        sum_variable = sum(r['variable_costs'] for r in location_rows)
        sum_cash = sum(r['cash_collected'] for r in location_rows)

        top_profit = location_rows[0] if location_rows else None
        top_loss = min(location_rows, key=lambda r: r['net_profit']) if location_rows else None

        overall_net_margin = round(sum_net / sum_revenue * 100, 1) if sum_revenue else 0
        overall_gross_margin = round(sum_gross / sum_revenue * 100, 1) if sum_revenue else 0

        return Response({
            'period': {'start': d_start.isoformat(), 'end': d_end.isoformat()},
            'summary': {
                'total_locations': total_locations,
                'total_vehicles': total_vehicles,
                'leased_vehicles': sum(r['leased_vehicles'] for r in location_rows),
                'owned_vehicles': sum(r['owned_vehicles'] for r in location_rows),
                'total_monthly_lease': round(sum_monthly_lease, 2),
                'total_deposit': round(sum_deposit, 2),
                'total_revenue': round(sum_revenue, 2),
                'total_cash_collected': round(sum_cash, 2),
                'total_cogs': round(sum_cogs, 2),
                'total_opex': round(sum_opex, 2),
                'total_variable_costs': round(sum_variable, 2),
                'total_fixed_costs': round(sum_fixed, 2),
                'total_costs': round(sum_costs, 2),
                'gross_profit': round(sum_gross, 2),
                'net_profit': round(sum_net, 2),
                'gross_margin': overall_gross_margin,
                'net_margin': overall_net_margin,
                'expiring_30d': sum(r['expiring_30d'] for r in location_rows),
                'top_profit_location': top_profit['name'] if top_profit else None,
                'top_profit_value': round(top_profit['net_profit'], 2) if top_profit else 0,
                'top_loss_location': top_loss['name'] if top_loss else None,
                'top_loss_value': round(top_loss['net_profit'], 2) if top_loss else 0,
            },
            'locations': location_rows,
            'po_cost': round(po_cost_total, 2),
        })

    # ─────────────────────────────────────────────────────────────────────
    #  COST OF OWNERSHIP — fleet-wide TCO
    # ─────────────────────────────────────────────────────────────────────

    @action(detail=False, methods=['get'], url_path='ownership')
    def cost_of_ownership(self, request):
        """Fleet-wide Total Cost of Ownership across all vehicles for the period."""
        import datetime as _dt
        from django.db.models import Sum, Count, Q
        from django.utils.timezone import make_aware
        from apps.rentals.models import RentalAgreement
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport

        since, until = self._period_bounds(request)
        _tz = timezone.get_current_timezone()
        months = max((until - since).days / 30, 1)
        d_start = since.date()
        d_end = until.date()

        vehicles = list(Vehicle.objects.all())
        if not vehicles:
            return Response({'vehicles': [], 'summary': {}, 'breakdown': [], 'monthly': []})

        rows = []
        totals = {
            'depreciation': 0.0, 'financing': 0.0, 'lease': 0.0,
            'insurance': 0.0, 'fuel': 0.0, 'charging': 0.0, 'idling': 0.0,
            'maintenance': 0.0, 'accidents': 0.0, 'expenses': 0.0,
        }
        rental_totals = {v.id: 0.0 for v in vehicles}
        for ra in RentalAgreement.objects.exclude(status='draft').filter(created_at__gte=since, created_at__lt=until).select_related('vehicle'):
            if ra.vehicle_id and ra.vehicle_id in rental_totals:
                rental_totals[ra.vehicle_id] += float(ra.total_amount)

        for v in vehicles:
            is_lease = v.ownership == 'lease'
            ann_dep = float(v.annual_depreciation or 0)
            pp = float(v.purchase_price or 0)
            sv = float(v.salvage_value or 0)
            life = v.useful_life_years or 0
            if not is_lease and not ann_dep and life and pp:
                ann_dep = (pp - sv) / life
            dep = ann_dep / 12.0 * months if not is_lease else 0.0
            fin = float(v.monthly_payment or 0) * months
            lease = float(v.lease_monthly_rate or 0) * months if is_lease else 0.0
            ins = float(v.insurance_premium or 0) * months / 12.0

            fuel = float(FuelTransaction.objects.filter(vehicle=v, date__gte=since, date__lt=until)
                         .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            charge = float(ChargingSession.objects.filter(vehicle=v, start_time__gte=since, start_time__lt=until)
                            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            idling = sum(float(ev.cost or 0) for ev in IdlingEvent.objects.filter(vehicle=v, start_time__gte=since, start_time__lt=until))
            svc = float(Service.objects.filter(vehicle=v, performed_at__gte=since, performed_at__lt=until)
                        .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            acc = float(AccidentReport.objects.filter(vehicle=v, date__gte=since, date__lt=until)
                        .aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
            exp = float(Expense.objects.exclude(status='draft').filter(
                vehicle=v,
                expense_date__gte=d_start, expense_date__lt=d_end,
            ).aggregate(t=Sum(F('amount') + F('tax_amount')))['t'] or Decimal('0'))

            capital = dep + fin + lease
            energy = fuel + charge + idling
            operating = svc + acc + exp
            total = capital + ins + energy + operating
            revenue = rental_totals.get(v.id, 0.0)
            net = revenue - total
            mileage = float(v.current_mileage or 0)
            in_svc = v.in_service_date
            if in_svc and mileage:
                total_days = max((d_end - in_svc).days, 1)
                period_days = max((d_end - d_start).days, 1)
                period_mileage = mileage * (period_days / total_days)
            else:
                period_mileage = 0
            cpk = round(total / period_mileage, 2) if period_mileage else 0
            cpd = round(total / max((d_end - d_start).days, 1), 2)

            for k, val in [('depreciation', dep), ('financing', fin), ('lease', lease), ('insurance', ins),
                           ('fuel', fuel), ('charging', charge), ('idling', idling),
                           ('maintenance', svc), ('accidents', acc), ('expenses', exp)]:
                totals[k] += val

            rows.append({
                'id': v.id,
                'vehicle': v.display_name,
                'vin': v.vin,
                'license_plate': v.license_plate,
                'status': v.status,
                'ownership': v.ownership,
                'capital_cost': round(capital, 2),
                'depreciation': round(dep, 2),
                'financing': round(fin, 2),
                'lease': round(lease, 2),
                'insurance': round(ins, 2),
                'fuel': round(fuel, 2),
                'charging': round(charge, 2),
                'idling': round(idling, 2),
                'maintenance': round(svc, 2),
                'accidents': round(acc, 2),
                'expenses': round(exp, 2),
                'energy_cost': round(energy, 2),
                'operating_cost': round(operating, 2),
                'total_cost': round(total, 2),
                'revenue': round(revenue, 2),
                'net_profit': round(net, 2),
                'cost_per_km': cpk,
                'cost_per_day': cpd,
            })

        rows.sort(key=lambda x: x['total_cost'], reverse=True)

        grand_total = sum(r['total_cost'] for r in rows)
        grand_revenue = sum(r['revenue'] for r in rows)
        grand_net = grand_revenue - grand_total
        total_book_value = sum(float(v.current_book_value or 0) for v in vehicles)
        total_ann_dep = sum(float(v.annual_depreciation or 0) for v in vehicles)

        breakdown = []
        if totals['depreciation'] > 0:
            breakdown.append({'name': 'Depreciation', 'value': round(totals['depreciation'], 2)})
        if totals['lease'] > 0:
            breakdown.append({'name': 'Lease Payments', 'value': round(totals['lease'], 2)})
        if totals['financing'] > 0:
            breakdown.append({'name': 'Financing', 'value': round(totals['financing'], 2)})
        if totals['insurance'] > 0:
            breakdown.append({'name': 'Insurance', 'value': round(totals['insurance'], 2)})
        if totals['fuel'] > 0:
            breakdown.append({'name': 'Fuel', 'value': round(totals['fuel'], 2)})
        if totals['charging'] > 0:
            breakdown.append({'name': 'EV Charging', 'value': round(totals['charging'], 2)})
        if totals['idling'] > 0:
            breakdown.append({'name': 'Idling Waste', 'value': round(totals['idling'], 2)})
        if totals['maintenance'] > 0:
            breakdown.append({'name': 'Maintenance', 'value': round(totals['maintenance'], 2)})
        if totals['accidents'] > 0:
            breakdown.append({'name': 'Accidents', 'value': round(totals['accidents'], 2)})
        if totals['expenses'] > 0:
            breakdown.append({'name': 'General Expenses', 'value': round(totals['expenses'], 2)})

        # Monthly trend
        monthly = []
        cursor = d_start.replace(day=1)
        m_end_limit = (d_end.replace(day=1) + _dt.timedelta(days=32)).replace(day=1)
        while cursor <= m_end_limit:
            m_start = cursor
            m_next = cursor.replace(year=cursor.year + 1, month=1, day=1) \
                if cursor.month == 12 \
                else cursor.replace(month=cursor.month + 1, day=1)
            ms = make_aware(_dt.datetime.combine(m_start, _dt.time.min), _tz)
            me = make_aware(_dt.datetime.combine(m_next, _dt.time.min), _tz)

            m_dep = total_ann_dep / 12.0
            m_fuel = float(FuelTransaction.objects.filter(date__gte=ms, date__lt=me)
                           .aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            m_charge = float(ChargingSession.objects.filter(start_time__gte=ms, start_time__lt=me)
                            .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_svc = float(Service.objects.filter(performed_at__gte=ms, performed_at__lt=me)
                          .aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_acc = float(AccidentReport.objects.filter(date__gte=ms, date__lt=me)
                         .aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
            m_exp = self._expense_total(ms, me)
            m_total = m_dep + m_fuel + m_charge + m_svc + m_acc + m_exp
            monthly.append({
                'month': m_start.strftime('%b %Y'),
                'month_key': m_start.strftime('%Y-%m'),
                'cost': round(m_total, 2),
            })
            cursor = m_next

        keep = [m for m in monthly if
                _dt.date.fromisoformat(m['month_key'] + '-01') >= d_start.replace(day=1) and
                _dt.date.fromisoformat(m['month_key'] + '-01') <= d_end.replace(day=1)]
        monthly = keep or monthly

        return Response({
            'period': {'start': since.isoformat(), 'end': until.isoformat()},
            'vehicles': rows[:50],
            'vehicle_count': len(rows),
            'summary': {
                'total_cost': round(grand_total, 2),
                'total_revenue': round(grand_revenue, 2),
                'net_cost': round(grand_net, 2),
                'depreciation': round(totals['depreciation'], 2),
                'financing': round(totals['financing'], 2),
                'lease': round(totals['lease'], 2),
                'insurance': round(totals['insurance'], 2),
                'fuel': round(totals['fuel'], 2),
                'charging': round(totals['charging'], 2),
                'idling': round(totals['idling'], 2),
                'maintenance': round(totals['maintenance'], 2),
                'accidents': round(totals['accidents'], 2),
                'expenses': round(totals['expenses'], 2),
                'capital_cost': round(totals['depreciation'] + totals['financing'] + totals['lease'], 2),
                'energy_cost': round(totals['fuel'] + totals['charging'] + totals['idling'], 2),
                'operating_cost': round(totals['maintenance'] + totals['accidents'] + totals['expenses'], 2),
                'period_months': round(months, 1),
                'total_book_value': round(total_book_value, 2),
            },
            'breakdown': breakdown,
            'monthly': monthly,
        })

    # ─────────────────────────────────────────────────────────────────────
    #  GENERAL LEDGER — double-entry journal auto-generated from transactions
    # ─────────────────────────────────────────────────────────────────────

    @action(detail=False, methods=['get'], url_path='general-ledger')
    def general_ledger(self, request):
        """General Ledger with auto-generated double-entry journal entries.

        Derives journal entries from existing fleet transactions (rental revenue,
        cash receipts, fuel, services, depreciation, insurance, financing, accidents)
        and maps them to a standard chart of accounts.  Returns:
          - ``accounts``   – Chart of Accounts (code → name, type, category)
          - ``entries``     – Journal entries (date, account, debit, credit, ref, description)
          - ``trial_balance`` – Per-account totals (debits, credits, balance)
          - ``monthly``     – Monthly debit/credit trend series
        """
        import datetime as _dt
        from collections import defaultdict
        from django.utils.timezone import make_aware

        since, until = self._period_bounds(request)
        _tz = timezone.get_current_timezone()
        d_start = since.date() if hasattr(since, 'date') else since
        d_end = until.date() if hasattr(until, 'date') else until

        # ── Chart of Accounts ──
        accounts = [
            # Assets
            {'code': '1000', 'name': 'Cash and Bank',       'type': 'asset',     'category': 'Current Assets'},
            {'code': '1100', 'name': 'Accounts Receivable',  'type': 'asset',     'category': 'Current Assets'},
            {'code': '1200', 'name': 'Vehicles (at cost)',    'type': 'asset',     'category': 'Fixed Assets'},
            {'code': '1210', 'name': 'Accumulated Depreciation', 'type': 'asset',  'category': 'Fixed Assets', 'contra': True},
            {'code': '1300', 'name': 'Inventory',             'type': 'asset',     'category': 'Current Assets'},
            {'code': '1400', 'name': 'Prepaid Insurance',      'type': 'asset',     'category': 'Current Assets'},
            # Liabilities
            {'code': '2000', 'name': 'Accounts Payable',      'type': 'liability', 'category': 'Current Liabilities'},
            {'code': '2100', 'name': 'Lease Payable',          'type': 'liability', 'category': 'Long-Term Liabilities'},
            {'code': '2200', 'name': 'Vehicle Loan Payable',    'type': 'liability', 'category': 'Long-Term Liabilities'},
            {'code': '2300', 'name': 'Sales Tax Payable',       'type': 'liability', 'category': 'Current Liabilities'},
            {'code': '2400', 'name': 'Customer Deposits',       'type': 'liability', 'category': 'Current Liabilities'},
            # Equity
            {'code': '3000', 'name': 'Owners Equity',          'type': 'equity',    'category': 'Equity'},
            {'code': '3100', 'name': 'Retained Earnings',       'type': 'equity',    'category': 'Equity'},
            # Revenue
            {'code': '4000', 'name': 'Rental Revenue',         'type': 'revenue',   'category': 'Operating Revenue'},
            {'code': '4100', 'name': 'Rental Charges',          'type': 'revenue',   'category': 'Operating Revenue'},
            {'code': '4900', 'name': 'Sales Tax Collected',      'type': 'revenue',   'category': 'Other Revenue'},
            # COGS
            {'code': '5000', 'name': 'Fuel and Energy',          'type': 'expense',  'category': 'Variable Costs'},
            {'code': '5100', 'name': 'Maintenance and Repairs',   'type': 'expense',  'category': 'Variable Costs'},
            # Operating Expenses
            {'code': '6000', 'name': 'Depreciation Expense',     'type': 'expense',  'category': 'Fixed Costs'},
            {'code': '6100', 'name': 'Insurance Expense',         'type': 'expense',  'category': 'Fixed Costs'},
            {'code': '6200', 'name': 'Lease Expense',             'type': 'expense',  'category': 'Fixed Costs'},
            {'code': '6300', 'name': 'Financing Expense',         'type': 'expense',  'category': 'Fixed Costs'},
            {'code': '6400', 'name': 'Idling Waste Expense',      'type': 'expense',  'category': 'Variable Costs'},
            {'code': '6500', 'name': 'Accident Damage Expense',   'type': 'expense',  'category': 'Variable Costs'},
            {'code': '6600', 'name': 'Inventory Purchases',       'type': 'expense',  'category': 'Operating Expenses'},
            {'code': '6700', 'name': 'Vehicle Damage Expense',    'type': 'expense',  'category': 'Variable Costs'},
            {'code': '6800', 'name': 'General Expenses',          'type': 'expense',  'category': 'Operating Expenses'},
        ]
        acct_map = {a['code']: a for a in accounts}

        entries: list[dict] = []
        _seq = [0]

        def _add(date, code, debit, credit, ref, description, source='manual'):
            _seq[0] += 1
            entries.append({
                'id': _seq[0],
                'date': date.isoformat() if hasattr(date, 'isoformat') else str(date),
                'account_code': code,
                'account_name': acct_map.get(code, {}).get('name', code),
                'account_type': acct_map.get(code, {}).get('type', 'unknown'),
                'category': acct_map.get(code, {}).get('category', ''),
                'debit': round(float(debit or 0), 2),
                'credit': round(float(credit or 0), 2),
                'reference': ref,
                'description': description,
                'source': source,
            })

        # ── 1. Rental Revenue (accrual) ──
        for ra in RentalAgreement.objects.exclude(status='draft').filter(
            created_at__gte=since, created_at__lt=until
        ).select_related('vehicle', 'customer'):
            amt = float(ra.total_amount or 0)
            tax = float(ra.taxes or 0)
            subtotal = float(ra.subtotal or 0)
            disc = float(ra.discount_total or 0)
            veh = ra.vehicle.display_name if ra.vehicle else 'N/A'
            cust = str(ra.customer) if ra.customer else 'Walk-in'
            if subtotal > 0:
                _add(ra.start_datetime or ra.created_at, '1100', subtotal, 0,
                     f'RA-{ra.id}', f'Rental income — {veh} ({cust})', 'rental')
                _add(ra.start_datetime or ra.created_at, '4000', 0, subtotal,
                     f'RA-{ra.id}', f'Rental revenue — {veh} ({cust})', 'rental')
            if tax > 0:
                _add(ra.start_datetime or ra.created_at, '1100', tax, 0,
                     f'RA-{ra.id}', f'Sales tax on rental — {veh}', 'rental')
                _add(ra.start_datetime or ra.created_at, '2300', 0, tax,
                     f'RA-{ra.id}', f'Sales tax payable — {veh}', 'rental')
            if disc > 0:
                _add(ra.start_datetime or ra.created_at, '4000', disc, 0,
                     f'RA-{ra.id}', f'Discount — {veh} ({cust})', 'rental')
                _add(ra.start_datetime or ra.created_at, '1100', 0, disc,
                     f'RA-{ra.id}', f'Discount applied — {veh}', 'rental')

        # ── 2. Cash Receipts (payments) ──
        for pmt in RentalPayment.objects.filter(
            status='completed', paid_at__gte=since, paid_at__lt=until
        ).select_related('agreement__vehicle'):
            amt = float(pmt.amount or 0)
            if amt <= 0:
                continue
            veh = pmt.agreement.vehicle.display_name if pmt.agreement and pmt.agreement.vehicle else 'N/A'
            method = (pmt.payment_method or 'cash').title()
            _add(pmt.paid_at, '1000', amt, 0,
                 f'PMT-{pmt.id}', f'Cash receipt ({method}) — {veh}', 'payment')
            _add(pmt.paid_at, '1100', 0, amt,
                 f'PMT-{pmt.id}', f'Settled A/R — {veh}', 'payment')

        # ── 3. Rental Charges (upsells) ──
        for ch in RentalCharge.objects.filter(
            created_at__gte=since, created_at__lt=until
        ).select_related('agreement__vehicle'):
            amt = float(ch.total_amount or 0)
            if amt <= 0:
                continue
            veh = ch.agreement.vehicle.display_name if ch.agreement and ch.agreement.vehicle else 'N/A'
            ctype = (ch.charge_type or 'other').replace('_', ' ').title()
            _add(ch.created_at, '1100', amt, 0,
                 f'CHG-{ch.id}', f'{ctype} charge — {veh}', 'charge')
            _add(ch.created_at, '4100', 0, amt,
                 f'CHG-{ch.id}', f'{ctype} revenue — {veh}', 'charge')

        # ── 4. Fuel Transactions ──
        for ft in FuelTransaction.objects.filter(
            date__gte=since, date__lt=until
        ).select_related('vehicle'):
            amt = float(ft.total_cost or 0)
            if amt <= 0:
                continue
            veh = ft.vehicle.display_name if ft.vehicle else 'N/A'
            _add(ft.date, '5000', amt, 0,
                 f'FT-{ft.id}', f'Fuel — {veh}', 'fuel')
            _add(ft.date, '2000', 0, amt,
                 f'FT-{ft.id}', f'A/P — fuel — {veh}', 'fuel')

        # ── 5. EV Charging ──
        for cs in ChargingSession.objects.filter(
            start_time__gte=since, start_time__lt=until
        ).select_related('vehicle'):
            amt = float(cs.cost or 0)
            if amt <= 0:
                continue
            veh = cs.vehicle.display_name if cs.vehicle else 'N/A'
            _add(cs.start_time, '5000', amt, 0,
                 f'EV-{cs.id}', f'EV charging — {veh}', 'charging')
            _add(cs.start_time, '2000', 0, amt,
                 f'EV-{cs.id}', f'A/P — charging — {veh}', 'charging')

        # ── 6. Idling Waste ──
        for ev in IdlingEvent.objects.filter(
            start_time__gte=since, start_time__lt=until
        ).select_related('vehicle'):
            fuel_burned = float(ev.fuel_burned or 0)
            price = float(ev.fuel_price_per_gallon or 0)
            amt = round(fuel_burned * price, 2)
            if amt <= 0:
                continue
            veh = ev.vehicle.display_name if ev.vehicle else 'N/A'
            _add(ev.start_time, '6400', amt, 0,
                 f'IDLE-{ev.id}', f'Idling waste — {veh}', 'idling')
            _add(ev.start_time, '2000', 0, amt,
                 f'IDLE-{ev.id}', f'A/P — idling — {veh}', 'idling')

        # ── 7. Services / Maintenance ──
        for svc in Service.objects.filter(
            performed_at__gte=since, performed_at__lt=until
        ).select_related('vehicle'):
            amt = float(svc.cost or 0)
            if amt <= 0:
                continue
            veh = svc.vehicle.display_name if svc.vehicle else 'N/A'
            stype = (svc.service_type or 'other').replace('_', ' ').title()
            _add(svc.performed_at, '5100', amt, 0,
                 f'SVC-{svc.id}', f'{stype} — {veh}', 'service')
            _add(svc.performed_at, '2000', 0, amt,
                 f'SVC-{svc.id}', f'A/P — service — {veh}', 'service')

        # ── 8. Accident Damage ──
        for acc in AccidentReport.objects.filter(
            date__gte=since, date__lt=until
        ).select_related('vehicle'):
            amt = float(acc.estimated_damage_cost or 0)
            if amt <= 0:
                continue
            veh = acc.vehicle.display_name if acc.vehicle else 'N/A'
            _add(acc.date, '6500', amt, 0,
                 f'ACC-{acc.id}', f'Accident damage — {veh}', 'accident')
            _add(acc.date, '2000', 0, amt,
                 f'ACC-{acc.id}', f'A/P — accident — {veh}', 'accident')

        # ── 9. Vehicle Damage (from rentals) ──
        from apps.rentals.models import VehicleDamage
        for dmg in VehicleDamage.objects.filter(
            recorded_at__gte=since, recorded_at__lt=until
        ).select_related('agreement__vehicle'):
            amt = float(dmg.repair_cost or 0)
            if amt <= 0:
                continue
            veh = dmg.agreement.vehicle.display_name if dmg.agreement and dmg.agreement.vehicle else 'N/A'
            _add(dmg.recorded_at, '6700', amt, 0,
                 f'DMG-{dmg.id}', f'Vehicle damage — {veh} ({dmg.severity})', 'damage')
            _add(dmg.recorded_at, '2000', 0, amt,
                 f'DMG-{dmg.id}', f'A/P — damage — {veh}', 'damage')

        # ── 10. Insurance Claims (settled) ──
        from apps.accidents.models import InsuranceClaim
        for cl in InsuranceClaim.objects.filter(
            status='settled', settled_date__gte=d_start, settled_date__lte=d_end
        ).select_related('accident__vehicle'):
            amt = float(cl.settled_amount or 0)
            if amt <= 0:
                continue
            veh = cl.accident.vehicle.display_name if cl.accident and cl.accident.vehicle else 'N/A'
            _add(make_aware(_dt.datetime.combine(cl.settled_date, _dt.time.min), _tz), '1000', amt, 0,
                 f'CLM-{cl.id}', f'Insurance settlement — {veh}', 'insurance')
            _add(make_aware(_dt.datetime.combine(cl.settled_date, _dt.time.min), _tz), '1100', 0, amt,
                 f'CLM-{cl.id}', f'A/R settled — {veh}', 'insurance')

        # ── 11. Fixed Costs: Depreciation, Insurance, Lease, Financing ──
        months = max((d_end - d_start).days / 30, 1)
        for v in Vehicle.objects.all():
            is_lease = v.ownership == 'lease'
            ann_dep = float(v.annual_depreciation or 0)
            pp = float(v.purchase_price or 0)
            sv = float(v.salvage_value or 0)
            life = v.useful_life_years or 0
            if not is_lease and not ann_dep and life and pp:
                ann_dep = (pp - sv) / life
            dep = ann_dep / 12.0 * months if not is_lease else 0.0
            ins = float(v.insurance_premium or 0) * months / 12.0
            lease = float(v.lease_monthly_rate or 0) * months if is_lease else 0.0
            fin = float(v.monthly_payment or 0) * months

            post_date = make_aware(_dt.datetime.combine(d_start.replace(day=1), _dt.time.min), _tz)
            veh = v.display_name

            if dep > 0:
                _add(post_date, '6000', dep, 0, f'DEP-{v.id}', f'Depreciation — {veh}', 'depreciation')
                _add(post_date, '1210', 0, dep, f'DEP-{v.id}', f'Accumulated depreciation — {veh}', 'depreciation')
            if ins > 0:
                _add(post_date, '6100', ins, 0, f'INS-{v.id}', f'Insurance expense — {veh}', 'insurance')
                _add(post_date, '1400', 0, ins, f'INS-{v.id}', f'Prepaid insurance consumed — {veh}', 'insurance')
            if lease > 0:
                _add(post_date, '6200', lease, 0, f'LSE-{v.id}', f'Lease expense — {veh}', 'lease')
                _add(post_date, '2100', 0, lease, f'LSE-{v.id}', f'Lease payable — {veh}', 'lease')
            if fin > 0:
                _add(post_date, '6300', fin, 0, f'FIN-{v.id}', f'Financing expense — {veh}', 'financing')
                _add(post_date, '2200', 0, fin, f'FIN-{v.id}', f'Loan payable — {veh}', 'financing')

        # ── 12. Purchase Orders (received) ──
        from apps.inventory.models import PurchaseOrder
        for po in PurchaseOrder.objects.exclude(status='draft').exclude(status='cancelled').filter(
            created_at__gte=since, created_at__lt=until
        ):
            amt = float(po.total_cost or 0)
            if amt <= 0:
                continue
            _add(po.created_at, '6600', amt, 0,
                 f'PO-{po.id}', f'Inventory purchase — PO #{po.id}', 'purchase')
            _add(po.created_at, '2000', 0, amt,
                 f'PO-{po.id}', f'A/P — PO #{po.id}', 'purchase')

        # ── 13. General Expenses (from Expenses module) ──
        for exp in Expense.objects.exclude(status='draft').filter(
            expense_date__gte=d_start, expense_date__lt=d_end
        ).select_related('category', 'vehicle'):
            amt = float(exp.total_amount)
            if amt <= 0:
                continue
            veh = exp.vehicle.display_name if exp.vehicle else 'N/A'
            cat = exp.category.name if exp.category else 'General'
            ref = exp.expense_number or f'EXP-{exp.id}'
            desc = f'Expense — {exp.title} ({cat})'
            if exp.vehicle:
                desc += f' — {veh}'
            _add(make_aware(_dt.datetime.combine(exp.expense_date, _dt.time.min), _tz),
                 '6800', amt, 0, ref, desc, 'expense')
            _add(make_aware(_dt.datetime.combine(exp.expense_date, _dt.time.min), _tz),
                 '2000', 0, amt, ref, f'A/P — {cat} expense', 'expense')

        # ── Sort entries by date ──
        entries.sort(key=lambda e: e['date'])

        # ── Re-number after sort ──
        for i, e in enumerate(entries, 1):
            e['id'] = i

        # ── Trial Balance ──
        tb: dict[str, dict] = {}
        for a in accounts:
            tb[a['code']] = {
                'code': a['code'],
                'name': a['name'],
                'type': a['type'],
                'category': a.get('category', ''),
                'debit': 0.0,
                'credit': 0.0,
                'balance': 0.0,
            }
        for e in entries:
            row = tb.get(e['account_code'])
            if not row:
                continue
            row['debit'] += e['debit']
            row['credit'] += e['credit']

        trial_balance = []
        for a in accounts:
            row = tb[a['code']]
            row['debit'] = round(row['debit'], 2)
            row['credit'] = round(row['credit'], 2)
            is_debit = a['type'] in ('asset', 'expense') and not a.get('contra')
            is_credit = a['type'] in ('liability', 'equity', 'revenue') or a.get('contra')
            if is_debit:
                row['balance'] = round(row['debit'] - row['credit'], 2)
            elif is_credit:
                row['balance'] = round(row['credit'] - row['debit'], 2)
            else:
                row['balance'] = round(row['debit'] - row['credit'], 2)
            if row['debit'] or row['credit'] or row['balance']:
                trial_balance.append(row)

        # ── Monthly trend ──
        monthly: list[dict] = []
        if entries:
            min_d = _dt.date.fromisoformat(entries[0]['date'][:10])
            max_d = _dt.date.fromisoformat(entries[-1]['date'][:10])
        else:
            min_d = max_d = d_start
        cursor = (min_d.replace(day=1) if hasattr(min_d, 'replace') else min_d)
        m_end_limit = (max_d.replace(day=1) if hasattr(max_d, 'replace') else max_d)
        # ensure at least one month
        if m_end_limit < d_start:
            m_end_limit = d_start.replace(day=1)
        while cursor <= m_end_limit:
            m_next = cursor.replace(year=cursor.year + 1, month=1) if cursor.month == 12 else cursor.replace(month=cursor.month + 1)
            m_total_debit = sum(e['debit'] for e in entries if e['date'][:7] == cursor.strftime('%Y-%m'))
            m_total_credit = sum(e['credit'] for e in entries if e['date'][:7] == cursor.strftime('%Y-%m'))
            monthly.append({
                'month': cursor.strftime('%b %Y'),
                'month_key': cursor.strftime('%Y-%m'),
                'debit': round(m_total_debit, 2),
                'credit': round(m_total_credit, 2),
            })
            cursor = m_next

        # ── Summary ──
        total_debits = round(sum(e['debit'] for e in entries), 2)
        total_credits = round(sum(e['credit'] for e in entries), 2)
        tb_dr_total = round(sum(r['debit'] for r in trial_balance), 2)
        tb_cr_total = round(sum(r['credit'] for r in trial_balance), 2)

        # ── Source breakdown ──
        source_totals: dict[str, dict] = defaultdict(lambda: {'count': 0, 'debit': 0.0, 'credit': 0.0})
        for e in entries:
            src = e.get('source') or 'manual'
            source_totals[src]['count'] += 1
            source_totals[src]['debit'] += e['debit']
            source_totals[src]['credit'] += e['credit']
        source_breakdown = [
            {
                'source': src,
                'count': d['count'],
                'debit': round(d['debit'], 2),
                'credit': round(d['credit'], 2),
                'total': round(d['debit'] + d['credit'], 2),
            }
            for src, d in sorted(source_totals.items(), key=lambda x: x[1]['debit'] + x[1]['credit'], reverse=True)
        ]

        # ── A/R Aging (Accounts Receivable: 1100) ──
        # Invoices posted to A/R that have not yet been settled by a cash receipt.
        # We approximate settling via FIFO: cash receipts (credits to 1100) offset
        # the oldest invoice debits.
        ar_entries = [e for e in entries if e['account_code'] == '1100']
        ar_open_invoices = []
        for e in ar_entries:
            if e['debit'] > 0:
                ar_open_invoices.append({
                    'date': e['date'],
                    'reference': e['reference'],
                    'description': e['description'],
                    'amount': e['debit'],
                    'remaining': e['debit'],
                })
        ar_settlements = [e for e in ar_entries if e['credit'] > 0]
        # Apply FIFO settlements
        settle_idx = 0
        for settle in ar_settlements:
            amt = settle['credit']
            while amt > 0 and settle_idx < len(ar_open_invoices):
                inv = ar_open_invoices[settle_idx]
                applied = min(amt, inv['remaining'])
                inv['remaining'] -= applied
                amt -= applied
                if inv['remaining'] <= 0.001:
                    settle_idx += 1
        # Build aging buckets
        now_date = timezone.now().date()
        ar_buckets = {'current': 0.0, '1_30': 0.0, '31_60': 0.0, '61_90': 0.0, '90_plus': 0.0}
        ar_detail = []
        for inv in ar_open_invoices:
            if inv['remaining'] <= 0.01:
                continue
            inv_date = _dt.date.fromisoformat(inv['date'][:10]) if isinstance(inv['date'], str) else inv['date']
            days_outstanding = (now_date - inv_date).days if hasattr(now_date, 'days') else 0
            if isinstance(days_outstanding, (int, float)):
                pass
            else:
                days_outstanding = 0
            bucket = 'current'
            if days_outstanding > 90:
                bucket = '90_plus'
            elif days_outstanding > 60:
                bucket = '61_90'
            elif days_outstanding > 30:
                bucket = '31_60'
            elif days_outstanding > 0:
                bucket = '1_30'
            ar_buckets[bucket] += inv['remaining']
            ar_detail.append({
                'date': inv['date'],
                'reference': inv['reference'],
                'description': inv['description'],
                'amount': round(inv['amount'], 2),
                'remaining': round(inv['remaining'], 2),
                'days_outstanding': days_outstanding,
                'bucket': bucket,
            })
        ar_aging = {
            'total_outstanding': round(sum(v for v in ar_buckets.values()), 2),
            'buckets': {k: round(v, 2) for k, v in ar_buckets.items()},
            'detail': ar_detail,
        }

        # ── A/P Aging (Accounts Payable: 2000) ──
        ap_entries = [e for e in entries if e['account_code'] == '2000']
        ap_open_invoices = []
        for e in ap_entries:
            if e['credit'] > 0:
                ap_open_invoices.append({
                    'date': e['date'],
                    'reference': e['reference'],
                    'description': e['description'],
                    'amount': e['credit'],
                    'remaining': e['credit'],
                })
        # A/P debits (payments) — if any
        ap_settlements = [e for e in ap_entries if e['debit'] > 0]
        settle_idx = 0
        for settle in ap_settlements:
            amt = settle['debit']
            while amt > 0 and settle_idx < len(ap_open_invoices):
                inv = ap_open_invoices[settle_idx]
                applied = min(amt, inv['remaining'])
                inv['remaining'] -= applied
                amt -= applied
                if inv['remaining'] <= 0.001:
                    settle_idx += 1
        ap_buckets = {'current': 0.0, '1_30': 0.0, '31_60': 0.0, '61_90': 0.0, '90_plus': 0.0}
        ap_detail = []
        for inv in ap_open_invoices:
            if inv['remaining'] <= 0.01:
                continue
            inv_date = _dt.date.fromisoformat(inv['date'][:10]) if isinstance(inv['date'], str) else inv['date']
            days_outstanding = (now_date - inv_date).days if hasattr(now_date, 'days') else 0
            if not isinstance(days_outstanding, (int, float)):
                days_outstanding = 0
            bucket = 'current'
            if days_outstanding > 90:
                bucket = '90_plus'
            elif days_outstanding > 60:
                bucket = '61_90'
            elif days_outstanding > 30:
                bucket = '31_60'
            elif days_outstanding > 0:
                bucket = '1_30'
            ap_buckets[bucket] += inv['remaining']
            ap_detail.append({
                'date': inv['date'],
                'reference': inv['reference'],
                'description': inv['description'],
                'amount': round(inv['amount'], 2),
                'remaining': round(inv['remaining'], 2),
                'days_outstanding': days_outstanding,
                'bucket': bucket,
            })
        ap_aging = {
            'total_outstanding': round(sum(v for v in ap_buckets.values()), 2),
            'buckets': {k: round(v, 2) for k, v in ap_buckets.items()},
            'detail': ap_detail,
        }

        # ── Comparative Trial Balance (previous period) ──
        # Compute the previous period of equal length and derive a mini
        # trial balance for comparison.
        prev_until = since
        prev_since = since - (until - since)
        prev_tb: dict[str, dict] = {}
        for a in accounts:
            prev_tb[a['code']] = {'debit': 0.0, 'credit': 0.0, 'balance': 0.0}

        # Build previous-period entries (lightweight — just enough for totals)
        prev_entries: list[dict] = []

        def _prev_add(code, debit, credit):
            prev_entries.append({
                'account_code': code,
                'account_type': acct_map.get(code, {}).get('type', 'unknown'),
                'debit': round(float(debit or 0), 2),
                'credit': round(float(credit or 0), 2),
            })

        for ra in RentalAgreement.objects.exclude(status='draft').filter(
            created_at__gte=prev_since, created_at__lt=prev_until
        ):
            subtotal = float(ra.subtotal or 0)
            tax = float(ra.taxes or 0)
            disc = float(ra.discount_total or 0)
            if subtotal > 0:
                _prev_add('1100', subtotal, 0)
                _prev_add('4000', 0, subtotal)
            if tax > 0:
                _prev_add('1100', tax, 0)
                _prev_add('2300', 0, tax)
            if disc > 0:
                _prev_add('4000', disc, 0)
                _prev_add('1100', 0, disc)
        for pmt in RentalPayment.objects.filter(
            status='completed', paid_at__gte=prev_since, paid_at__lt=prev_until
        ):
            amt = float(pmt.amount or 0)
            if amt > 0:
                _prev_add('1000', amt, 0)
                _prev_add('1100', 0, amt)
        for ch in RentalCharge.objects.filter(created_at__gte=prev_since, created_at__lt=prev_until):
            amt = float(ch.total_amount or 0)
            if amt > 0:
                _prev_add('1100', amt, 0)
                _prev_add('4100', 0, amt)
        for ft in FuelTransaction.objects.filter(date__gte=prev_since, date__lt=prev_until):
            amt = float(ft.total_cost or 0)
            if amt > 0:
                _prev_add('5000', amt, 0)
                _prev_add('2000', 0, amt)
        for cs in ChargingSession.objects.filter(start_time__gte=prev_since, start_time__lt=prev_until):
            amt = float(cs.cost or 0)
            if amt > 0:
                _prev_add('5000', amt, 0)
                _prev_add('2000', 0, amt)
        for ev in IdlingEvent.objects.filter(start_time__gte=prev_since, start_time__lt=prev_until):
            amt = round(float(ev.fuel_burned or 0) * float(ev.fuel_price_per_gallon or 0), 2)
            if amt > 0:
                _prev_add('6400', amt, 0)
                _prev_add('2000', 0, amt)
        for svc in Service.objects.filter(performed_at__gte=prev_since, performed_at__lt=prev_until):
            amt = float(svc.cost or 0)
            if amt > 0:
                _prev_add('5100', amt, 0)
                _prev_add('2000', 0, amt)
        for acc in AccidentReport.objects.filter(date__gte=prev_since, date__lt=prev_until):
            amt = float(acc.estimated_damage_cost or 0)
            if amt > 0:
                _prev_add('6500', amt, 0)
                _prev_add('2000', 0, amt)
        for dmg in VehicleDamage.objects.filter(recorded_at__gte=prev_since, recorded_at__lt=prev_until):
            amt = float(dmg.repair_cost or 0)
            if amt > 0:
                _prev_add('6700', amt, 0)
                _prev_add('2000', 0, amt)
        prev_months = max((prev_until - prev_since).days / 30, 1)
        prev_period_start = prev_since.date() if hasattr(prev_since, 'date') else prev_since
        for v in Vehicle.objects.all():
            is_lease = v.ownership == 'lease'
            ann_dep = float(v.annual_depreciation or 0)
            pp = float(v.purchase_price or 0)
            sv_p = float(v.salvage_value or 0)
            life = v.useful_life_years or 0
            if not is_lease and not ann_dep and life and pp:
                ann_dep = (pp - sv_p) / life
            p_dep = ann_dep / 12.0 * prev_months if not is_lease else 0.0
            p_ins = float(v.insurance_premium or 0) * prev_months / 12.0
            p_lease = float(v.lease_monthly_rate or 0) * prev_months if is_lease else 0.0
            p_fin = float(v.monthly_payment or 0) * prev_months
            if p_dep > 0:
                _prev_add('6000', p_dep, 0)
                _prev_add('1210', 0, p_dep)
            if p_ins > 0:
                _prev_add('6100', p_ins, 0)
                _prev_add('1400', 0, p_ins)
            if p_lease > 0:
                _prev_add('6200', p_lease, 0)
                _prev_add('2100', 0, p_lease)
            if p_fin > 0:
                _prev_add('6300', p_fin, 0)
                _prev_add('2200', 0, p_fin)
        for po in PurchaseOrder.objects.exclude(status='draft').exclude(status='cancelled').filter(
            created_at__gte=prev_since, created_at__lt=prev_until
        ):
            amt = float(po.total_cost or 0)
            if amt > 0:
                _prev_add('6600', amt, 0)
                _prev_add('2000', 0, amt)

        for pe in prev_entries:
            row = prev_tb.get(pe['account_code'])
            if not row:
                continue
            row['debit'] += pe['debit']
            row['credit'] += pe['credit']

        comparative_tb = []
        for a in accounts:
            cur = tb[a['code']]
            prev = prev_tb[a['code']]
            is_debit = a['type'] in ('asset', 'expense') and not a.get('contra')
            is_credit = a['type'] in ('liability', 'equity', 'revenue') or a.get('contra')
            prev_bal = 0.0
            if is_debit:
                prev_bal = prev['debit'] - prev['credit']
            elif is_credit:
                prev_bal = prev['credit'] - prev['debit']
            else:
                prev_bal = prev['debit'] - prev['credit']
            cur_bal = cur['balance']
            change = round(cur_bal - prev_bal, 2)
            if (cur['debit'] or cur['credit'] or cur_bal or prev['debit'] or prev['credit'] or prev_bal):
                comparative_tb.append({
                    'code': a['code'],
                    'name': a['name'],
                    'type': a['type'],
                    'category': a.get('category', ''),
                    'current_debit': cur['debit'],
                    'current_credit': cur['credit'],
                    'current_balance': cur_bal,
                    'previous_debit': round(prev['debit'], 2),
                    'previous_credit': round(prev['credit'], 2),
                    'previous_balance': round(prev_bal, 2),
                    'change': change,
                    'change_pct': round(change / abs(prev_bal) * 100, 1) if prev_bal else 0,
                })

        return Response({
            'period': {'start': d_start.isoformat(), 'end': d_end.isoformat()},
            'accounts': accounts,
            'entries': entries,
            'trial_balance': trial_balance,
            'comparative_trial_balance': comparative_tb,
            'monthly': monthly,
            'source_breakdown': source_breakdown,
            'ar_aging': ar_aging,
            'ap_aging': ap_aging,
            'summary': {
                'entry_count': len(entries),
                'total_debits': total_debits,
                'total_credits': total_credits,
                'balanced': total_debits == total_credits,
                'tb_debit_total': tb_dr_total,
                'tb_credit_total': tb_cr_total,
                'ar_outstanding': ar_aging['total_outstanding'],
                'ap_outstanding': ap_aging['total_outstanding'],
            },
        })

    @action(detail=False, methods=['get'], url_path='seed-demo')
    def seed_demo(self, request):
        """Seed demo financial data (rentals with payments) for testing."""
        from apps.rentals.models import Customer
        import random

        customers = list(Customer.objects.all()[:10])
        vehicles = list(Vehicle.objects.filter(status='active')[:5])
        if not customers or not vehicles:
            return Response({'detail': 'Need customers and vehicles first.'}, status=400)

        existing = RentalAgreement.objects.filter(created_at__gte=timezone.now() - timedelta(days=30)).count()
        if existing >= 20:
            return Response({'detail': f'{existing} rentals already exist in last 30d.'}, status=400)

        rate_periods = [('daily', 3500, 5000), ('weekly', 18000, 25000), ('weekend', 8000, 12000)]
        payment_methods = ['mpesa', 'cash', 'card', 'bank_transfer']
        created = 0
        now = timezone.now()
        for i in range(15):
            cust = random.choice(customers)
            veh = random.choice(vehicles)
            rp, min_rate, max_rate = random.choice(rate_periods)
            daily_rate = Decimal(str(random.randint(min_rate, max_rate)))
            days_ago = random.randint(0, 25)
            start = now - timedelta(days=days_ago)
            end = start + timedelta(days=random.randint(2, 14))
            insurance = Decimal(str(random.randint(500, 2000)))
            gps = Decimal(str(random.randint(0, 500)))
            discount = Decimal(str(random.randint(0, 10)))

            ra = RentalAgreement.objects.create(
                customer=cust, vehicle=veh, status=random.choice(['active', 'completed', 'completed']),
                rate_period=rp, daily_rate=daily_rate,
                start_datetime=start, end_datetime=end,
                insurance_premium=insurance, gps_fee=gps,
                discount_percent=discount,
                driver_daily_rate=Decimal(str(random.randint(1000, 3000))),
            )
            # Compute total
            from decimal import Decimal as D
            num_days = (end - start).days or 1
            subtotal = daily_rate * num_days + insurance + gps
            disc = subtotal * (discount / D('100'))
            subtotal -= disc
            tax = subtotal * D('0.16')
            ra.subtotal = subtotal
            ra.discount_total = disc
            ra.taxes = tax
            ra.total_amount = subtotal + tax
            ra.save()

            # Create payment(s)
            num_payments = random.randint(1, 2)
            remaining = float(ra.total_amount)
            for p in range(num_payments):
                amt = remaining / (num_payments - p)
                RentalPayment.objects.create(
                    agreement=ra,
                    amount=Decimal(str(round(amt, 2))),
                    payment_method=random.choice(payment_methods),
                    status='completed',
                    paid_at=ra.start_datetime + timedelta(hours=random.randint(1, 48)),
                )
                remaining -= amt
            created += 1

        return Response({'created': created, 'detail': f'Successfully seeded {created} demo rental agreements with payments.'})

    @action(detail=False, methods=['get'], url_path='export')
    def export(self, request):
        """Export report data to CSV, Excel, or PDF."""
        report_type = request.query_params.get('type', 'cost-per-mile')
        fmt = request.query_params.get('format', 'csv')
        view = StandardReportsView()
        # Get data by calling the appropriate method
        method_map = {
            'cost-per-mile': self.cost_per_mile, 'cost_per_mile': self.cost_per_mile,
            'fuel-efficiency': self.fuel_efficiency, 'fuel_efficiency': self.fuel_efficiency,
            'mechanic-utilization': self.mechanic_utilization, 'mechanic_utilization': self.mechanic_utilization,
            'fleet-aging': self.fleet_aging, 'fleet_aging': self.fleet_aging,
            'benchmark': self.benchmark,
        }
        method = method_map.get(report_type, self.cost_per_mile)
        data = method(request).data

        if not data:
            return Response({'detail': 'No data to export'}, status=400)

        filename = f'{report_type}_{timezone.now().strftime("%Y%m%d")}'

        if fmt == 'csv':
            return self._export_csv(data, filename)
        elif fmt == 'excel':
            return self._export_excel(data, filename)
        elif fmt == 'pdf':
            return self._export_pdf(data, filename, report_type)
        return Response({'detail': 'Unsupported format'}, status=400)

    def _export_csv(self, data, filename):
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="{filename}.csv"'
        writer = csv.DictWriter(response, fieldnames=data[0].keys())
        writer.writeheader()
        for row in data:
            writer.writerow(row)
        return response

    def _export_excel(self, data, filename):
        from openpyxl import Workbook
        from openpyxl.utils import get_column_letter
        wb = Workbook()
        ws = wb.active
        ws.title = filename
        headers = list(data[0].keys())
        ws.append(headers)
        for row in data:
            ws.append(list(row.values()))
        for i, header in enumerate(headers, 1):
            ws.column_dimensions[get_column_letter(i)].width = 20
        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        response = HttpResponse(
            output.getvalue(),
            content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
        response['Content-Disposition'] = f'attachment; filename="{filename}.xlsx"'
        return response

    def _export_pdf(self, data, filename, title):
        from reportlab.lib import colors
        from reportlab.lib.pagesizes import letter, landscape
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet

        output = io.BytesIO()
        doc = SimpleDocTemplate(output, pagesize=landscape(letter))
        styles = getSampleStyleSheet()
        elements = [
            Paragraph(f'<b>DomendraFleet Report: {title.replace("_", " ").title()}</b>', styles['Title']),
            Spacer(1, 20),
        ]
        headers = list(data[0].keys())
        table_data = [headers] + [[str(v) for v in row.values()] for row in data]
        table = Table(table_data, repeatRows=1)
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4f46e5')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
        ]))
        elements.append(table)
        doc.build(elements)
        output.seek(0)
        response = HttpResponse(content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="{filename}.pdf"'
        response.write(output.getvalue())
        return response
