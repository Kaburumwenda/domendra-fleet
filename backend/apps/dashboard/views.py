from datetime import timedelta
from decimal import Decimal

from django.db.models import Count, F, Q, Sum
from django.db.models.functions import Coalesce, TruncMonth, TruncDay, TruncWeek
from django.utils import timezone
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView


class DashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from datetime import datetime as _dt, time as _time
        from apps.vehicles.models import Vehicle
        from apps.issues.models import Issue, WorkOrder
        from apps.reminders.models import Reminder
        from apps.documents.models import Document
        from apps.inspections.models import InspectionReport
        from apps.inventory.models import InventoryItem
        from apps.contacts.models import Contact
        from apps.rentals.models import RentalAgreement, RentalPayment
        from apps.fuel.models import FuelTransaction
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport

        today = timezone.now().date()
        week_later = today + timedelta(days=7)
        now = timezone.now()

        # ── Date-range from params (defaults to current month) ──
        start_str = request.query_params.get('start_date')
        end_str = request.query_params.get('end_date')
        if start_str and end_str:
            try:
                from django.utils.dateparse import parse_date
                d_start = parse_date(start_str)
                d_end = parse_date(end_str)
                if not d_start or not d_end:
                    raise ValueError
            except ValueError:
                d_start = now.date().replace(day=1)
                d_end = today
        else:
            d_start = now.date().replace(day=1)
            d_end = today

        # Convert to datetime bounds for ORM filters
        period_start = _dt.combine(d_start, _time.min)
        period_end = _dt.combine(d_end + timedelta(days=1), _time.min)

        vehicles = Vehicle.objects.all()

        total_vehicles = vehicles.count()
        active_vehicles = vehicles.filter(status=Vehicle.Status.ACTIVE).count()
        out_of_service = vehicles.filter(status__in=[
            Vehicle.Status.OUT_OF_SERVICE, Vehicle.Status.IN_MAINTENANCE,
        ]).count()

        total_purchase = vehicles.aggregate(
            t=Coalesce(Sum('purchase_price'), Decimal('0'))
        )['t']

        open_issues = Issue.objects.exclude(status__in=['resolved', 'closed']).count()
        critical_issues = Issue.objects.filter(
            priority='critical'
        ).exclude(status__in=['resolved', 'closed']).count()

        open_work_orders = WorkOrder.objects.exclude(
            status__in=['completed', 'closed']
        ).count()

        upcoming_reminders = Reminder.objects.filter(
            is_active=True,
            next_due_date__gte=today,
            next_due_date__lte=week_later,
        ).count()
        overdue_reminders = Reminder.objects.filter(
            is_active=True, next_due_date__lt=today,
        ).count()

        expiring_docs = Document.objects.filter(
            expiry_date__gte=today, expiry_date__lte=week_later,
        ).count()
        expired_docs = Document.objects.filter(expiry_date__lt=today).count()

        recent_inspections = InspectionReport.objects.filter(
            submitted_at__gte=timezone.now() - timedelta(days=30)
        ).count()
        failed_inspections = InspectionReport.objects.filter(
            submitted_at__gte=timezone.now() - timedelta(days=30), status='fail',
        ).count()

        low_stock = InventoryItem.objects.filter(
            quantity_on_hand__lte=F('reorder_point')
        ).count()

        total_drivers = Contact.objects.filter(
            contact_type='driver', is_active=True
        ).count()

        fleet_utilization = round(
            (active_vehicles / total_vehicles * 100), 1
        ) if total_vehicles else 0

        vehicles_by_status = list(
            vehicles.values('status').annotate(count=Count('id')).order_by('-count')
        )
        vehicles_by_type = list(
            vehicles.values('vehicle_type').annotate(count=Count('id')).order_by('-count')
        )
        vehicles_by_fuel = list(
            vehicles.values('fuel_type').annotate(count=Count('id')).order_by('-count')
        )

        # ── Revenue & cost for the selected period ──
        month_revenue = float(RentalPayment.objects.filter(
            status='completed', paid_at__gte=period_start, paid_at__lt=period_end
        ).aggregate(t=Coalesce(Sum('amount'), Decimal('0')))['t'])
        month_fuel = float(FuelTransaction.objects.filter(
            date__gte=period_start, date__lt=period_end
        ).aggregate(t=Coalesce(Sum('total_cost'), Decimal('0')))['t'])
        month_service = float(Service.objects.filter(
            performed_at__gte=period_start, performed_at__lt=period_end
        ).aggregate(t=Coalesce(Sum('cost'), Decimal('0')))['t'])
        month_rental_total = float(RentalAgreement.objects.exclude(status='draft').filter(
            created_at__gte=period_start, created_at__lt=period_end
        ).aggregate(t=Coalesce(Sum('total_amount'), Decimal('0')))['t'])

        # ── Cost trend over the selected period (fuel + service) ──
        trend_from = period_start
        fuel_by_month = list(FuelTransaction.objects.filter(
            date__gte=trend_from, date__lt=period_end
        ).annotate(month=TruncMonth('date')).values('month').annotate(
            total=Coalesce(Sum('total_cost'), Decimal('0'))
        ).order_by('month'))
        service_by_month = list(Service.objects.filter(
            performed_at__gte=trend_from, performed_at__lt=period_end
        ).annotate(month=TruncMonth('performed_at')).values('month').annotate(
            total=Coalesce(Sum('cost'), Decimal('0'))
        ).order_by('month'))
        # Merge into unified list
        month_map: dict = {}
        for f in fuel_by_month:
            key = f['month'].strftime('%b')
            month_map.setdefault(key, {'month': key, 'fuel': 0.0, 'service': 0.0})
            month_map[key]['fuel'] = float(f['total'])
        for s in service_by_month:
            key = s['month'].strftime('%b')
            month_map.setdefault(key, {'month': key, 'fuel': 0.0, 'service': 0.0})
            month_map[key]['service'] = float(s['total'])
        cost_trend = list(month_map.values())

        # ── Recent rentals (last 8 within the selected period) ──
        recent_rentals = []
        rental_qs = RentalAgreement.objects.select_related('customer', 'vehicle')
        if start_str and end_str:
            rental_qs = rental_qs.filter(created_at__gte=period_start, created_at__lt=period_end)
        for r in rental_qs.order_by('-created_at')[:8]:
            recent_rentals.append({
                'id': r.id,
                'agreement_no': r.agreement_no,
                'customer_name': r.customer.full_name if r.customer else 'Walk-in',
                'vehicle_display': r.vehicle.display_name if r.vehicle else 'Unassigned',
                'status': r.status,
                'total_amount': float(r.total_amount or 0),
                'start_datetime': r.start_datetime.isoformat() if r.start_datetime else None,
            })

        # ── Recent fuel transactions (last 5 within the selected period) ──
        recent_fuel = []
        fuel_qs = FuelTransaction.objects.select_related('vehicle')
        if start_str and end_str:
            fuel_qs = fuel_qs.filter(date__gte=period_start, date__lt=period_end)
        for ft in fuel_qs.order_by('-date')[:5]:
            recent_fuel.append({
                'vehicle_display': ft.vehicle.display_name if ft.vehicle else 'Unknown',
                'fuel_type': ft.fuel_type,
                'quantity': ft.quantity,
                'unit': ft.unit,
                'total_cost': float(ft.total_cost or 0),
                'date': ft.date.isoformat() if ft.date else None,
                'station_name': ft.station_name or '',
            })

        # ── Recent services (last 5 within the selected period) ──
        recent_services = []
        svc_qs = Service.objects.select_related('vehicle', 'vendor')
        if start_str and end_str:
            svc_qs = svc_qs.filter(performed_at__gte=period_start, performed_at__lt=period_end)
        for s in svc_qs.order_by('-performed_at')[:5]:
            recent_services.append({
                'vehicle_display': s.vehicle.display_name if s.vehicle else 'Unknown',
                'service_type': s.service_type,
                'cost': float(s.cost or 0),
                'performed_at': s.performed_at.isoformat() if s.performed_at else None,
                'vendor_name': s.vendor.full_name if s.vendor else '',
            })

        # ── Vehicle status breakdown ──
        status_counts = {v[0]: 0 for v in Vehicle.Status.choices}
        for v in vehicles:
            status_counts[v.status] = status_counts.get(v.status, 0) + 1

        # ── This Month bar chart data (revenue vs costs) ──
        monthly_bar = [
            {'label': 'Revenue', 'value': month_revenue, 'color': '#16a34a'},
            {'label': 'Rental Total', 'value': month_rental_total, 'color': '#3b82f6'},
            {'label': 'Fuel Cost', 'value': month_fuel, 'color': '#f59e0b'},
            {'label': 'Service Cost', 'value': month_service, 'color': '#ef4444'},
        ]

        # ── Rental revenue by vehicle type (for the selected period) ──
        revenue_by_type = list(
            RentalAgreement.objects.exclude(status='draft')
            .filter(created_at__gte=period_start, created_at__lt=period_end)
            .values('vehicle__vehicle_type')
            .annotate(total=Coalesce(Sum('total_amount'), Decimal('0')))
            .order_by('-total')
        )
        revenue_by_type_list = [
            {'type': r['vehicle__vehicle_type'] or 'Unknown', 'total': float(r['total'])}
            for r in revenue_by_type
        ]

        # ── Total accidents (for the selected period) ──
        month_accidents = AccidentReport.objects.filter(
            date__gte=period_start, date__lt=period_end
        ).count()

        return Response({
            'period': {
                'start': d_start.isoformat(),
                'end': d_end.isoformat(),
            },
            'kpis': {
                'total_vehicles': total_vehicles,
                'active_vehicles': active_vehicles,
                'out_of_service': out_of_service,
                'fleet_utilization': fleet_utilization,
                'total_drivers': total_drivers,
                'total_purchase_value': float(total_purchase),
            },
            'alerts': {
                'open_issues': open_issues,
                'critical_issues': critical_issues,
                'open_work_orders': open_work_orders,
                'overdue_reminders': overdue_reminders,
                'expired_docs': expired_docs,
                'low_stock_items': low_stock,
                'failed_inspections_30d': failed_inspections,
            },
            'upcoming': {
                'reminders_7d': upcoming_reminders,
                'expiring_docs_30d': expiring_docs,
                'recent_inspections_30d': recent_inspections,
            },
            'charts': {
                'vehicles_by_status': vehicles_by_status,
                'vehicles_by_type': vehicles_by_type,
                'vehicles_by_fuel': vehicles_by_fuel,
            },
            'monthly': {
                'revenue': month_revenue,
                'rental_total': month_rental_total,
                'fuel_cost': month_fuel,
                'service_cost': month_service,
                'accidents': month_accidents,
            },
            'cost_trend': cost_trend,
            'recent_rentals': recent_rentals,
            'recent_fuel': recent_fuel,
            'recent_services': recent_services,
            'status_counts': status_counts,
            'monthly_bar': monthly_bar,
            'revenue_by_type': revenue_by_type_list,
        })


class RentalTrendView(APIView):
    """Rental revenue trend with date filters (this week / month / year / custom)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from datetime import datetime as dt_cls
        from django.utils.dateparse import parse_date
        from apps.rentals.models import RentalAgreement, RentalPayment

        now = timezone.now()
        period = request.query_params.get('period', 'month')
        start = request.query_params.get('start')
        end = request.query_params.get('end')

        if period == 'week':
            since = now - timedelta(days=7)
            until = now
            bucket = 'daily'
        elif period == 'year':
            since = now - timedelta(days=365)
            until = now
            bucket = 'monthly'
        elif period == 'custom' and start and end:
            since = timezone.make_aware(dt_cls.combine(parse_date(start), dt_cls.min.time()))
            until = timezone.make_aware(dt_cls.combine(parse_date(end), dt_cls.max.time()))
            span = (until - since).days
            bucket = 'daily' if span <= 31 else ('weekly' if span <= 186 else 'monthly')
        else:  # month (default)
            since = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            until = now
            bucket = 'daily'

        # Build list of (start, end, label) buckets
        buckets = []
        if bucket == 'daily':
            delta = timedelta(days=1)
            fmt = '%b %d'
        elif bucket == 'weekly':
            delta = timedelta(days=7)
            fmt = '%b %d'
        else:  # monthly
            delta = None
            fmt = '%b %Y'

        cur = since
        while cur < until:
            if bucket == 'monthly':
                # next month boundary
                if cur.month == 12:
                    nxt = cur.replace(year=cur.year + 1, month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
                else:
                    nxt = cur.replace(month=cur.month + 1, day=1, hour=0, minute=0, second=0, microsecond=0)
                nxt = min(nxt, until)
            else:
                nxt = min(cur + delta, until)
            label = cur.strftime(fmt)
            buckets.append((cur, nxt, label))
            cur = nxt

        trend = []
        for b_start, b_end, label in buckets:
            day_revenue = float(RentalAgreement.objects.exclude(status='draft')
                                .filter(created_at__gte=b_start, created_at__lt=b_end)
                                .aggregate(t=Sum('total_amount'))['t'] or 0)
            day_payments = float(RentalPayment.objects.filter(status='completed',
                                paid_at__gte=b_start, paid_at__lt=b_end)
                                .aggregate(t=Sum('amount'))['t'] or 0)
            trend.append({
                'date': label,
                'revenue': round(day_revenue, 2),
                'payments': round(day_payments, 2),
            })

        return Response({
            'trend': trend,
            'period': period,
            'bucket': bucket,
            'since': since.strftime('%Y-%m-%d'),
            'until': until.strftime('%Y-%m-%d'),
        })
