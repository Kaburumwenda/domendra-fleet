from datetime import datetime, timedelta

import django_filters
from django.db import connection
from django.db.models import Avg, Count, Max, Min, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import ChargeSchedule, ChargingSession, FuelBudget, FuelCard, FuelFraudAlert, FuelTransaction, IdlingEvent
from .serializers import (
    ChargeScheduleSerializer,
    ChargingSessionSerializer,
    FuelBudgetSerializer,
    FuelCardSerializer,
    FuelFraudAlertSerializer,
    FuelTransactionSerializer,
    IdlingEventSerializer,
)


class FuelCardViewSet(viewsets.ModelViewSet):
    queryset = FuelCard.objects.select_related('vehicle', 'driver')
    serializer_class = FuelCardSerializer
    filterset_fields = ['provider', 'is_active', 'vehicle', 'driver']
    search_fields = ['card_number', 'card_holder_name']

    @action(detail=True, methods=['post'])
    def sync(self, request, pk=None):
        """Pull recent transactions from the card provider."""
        from .integrations import sync_card
        card = self.get_object()
        if not card.vehicle:
            return Response({'detail': 'Card must be linked to a vehicle before syncing.'}, status=400)
        try:
            result = sync_card(card)
        except NotImplementedError as exc:
            return Response({'detail': str(exc)}, status=501)
        except Exception as exc:
            return Response({'detail': f'Sync failed: {exc}'}, status=502)
        return Response(result)

    @action(detail=False, methods=['post'])
    def sync_all(self, request):
        """Sync all active cards with provider credentials."""
        from .integrations import sync_card
        cards = self.get_queryset().filter(is_active=True, vehicle__isnull=False).exclude(provider_account_id='')
        results = []
        for card in cards:
            try:
                results.append(sync_card(card))
            except NotImplementedError:
                continue
            except Exception as exc:
                results.append({'provider': card.provider, 'error': str(exc)})
        return Response(results)


class FuelTransactionFilter(django_filters.FilterSet):
    date__gte = django_filters.IsoDateTimeFilter(field_name='date', lookup_expr='gte')
    date__lte = django_filters.IsoDateTimeFilter(field_name='date', lookup_expr='lte')

    class Meta:
        model = FuelTransaction
        fields = ['vehicle', 'fuel_type', 'fuel_card', 'date', 'date__gte', 'date__lte']


class FuelTransactionViewSet(viewsets.ModelViewSet):
    queryset = FuelTransaction.objects.select_related('vehicle', 'fuel_card')
    serializer_class = FuelTransactionSerializer
    filterset_class = FuelTransactionFilter
    search_fields = ['station_name', 'notes']
    ordering_fields = ['date', 'total_cost', 'quantity']

    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Fuel efficiency trends and cost summaries."""
        from django.db.models import F, Max, Min, Q

        # Support custom date range via date__gte/date__lte, fallback to days
        date_gte = request.query_params.get('date__gte')
        date_lte = request.query_params.get('date__lte')
        qs = self.get_queryset()
        if date_gte:
            qs = qs.filter(date__gte=date_gte)
        if date_lte:
            qs = qs.filter(date__lte=date_lte)
        if not date_gte and not date_lte:
            days = int(request.query_params.get('days', 30))
            since = timezone.now() - timedelta(days=days)
            qs = qs.filter(date__gte=since)
        # Filter by fuel type
        fuel_type = request.query_params.get('fuel_type')
        if fuel_type:
            qs = qs.filter(fuel_type=fuel_type)
        # Filter by vehicle group
        group = request.query_params.get('vehicle_group')
        if group:
            qs = qs.filter(vehicle__group_id=group)
        # Filter by vehicle location
        location = request.query_params.get('vehicle_location')
        if location:
            qs = qs.filter(vehicle__location=location)
        txs = qs

        total_cost = txs.aggregate(t=Sum('total_cost'))['t'] or 0
        total_gallons = txs.aggregate(t=Sum('quantity'))['t'] or 0
        avg_price = txs.aggregate(a=Avg('total_cost'))['a'] or 0
        transaction_count = txs.count()

        by_vehicle = list(
            txs.values('vehicle_id', 'vehicle__vin', 'vehicle__make', 'vehicle__model', 'vehicle__license_plate', 'vehicle__image')
            .annotate(
                total_cost=Sum('total_cost'),
                total_gallons=Sum('quantity'),
                fill_count=Count('id'),
                min_odometer=Min('odometer_reading'),
                max_odometer=Max('odometer_reading'),
            )
            .order_by('-total_cost')
        )
        for row in by_vehicle:
            min_o = row.pop('min_odometer', None)
            max_o = row.pop('max_odometer', None)
            distance = (max_o - min_o) if (min_o is not None and max_o is not None) else None
            row['distance'] = distance
            row['min_odometer'] = min_o
            row['max_odometer'] = max_o
            row['avg_mpg'] = round(distance / row['total_gallons'], 1) if (distance and row['total_gallons']) else None

        monthly = list(
            txs.annotate(month=TruncMonth('date'))
            .values('month')
            .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'))
            .order_by('month')
        )
        for row in monthly:
            m = row.get('month')
            row['month'] = m.strftime('%Y-%m') if m else ''

        # Daily trend for the selected period
        daily = list(
            txs.extra(select={'day': 'DATE(date)'})
              .values('day')
              .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'), count=Count('id'))
              .order_by('day')
        )

        # By fuel type
        by_fuel = list(
            txs.values('fuel_type')
              .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'), count=Count('id'))
              .order_by('-total_cost')
        )

        # By unit (gallons vs liters)
        by_unit = list(
            txs.values('unit')
              .annotate(total_cost=Sum('total_cost'), total_qty=Sum('quantity'), count=Count('id'))
              .order_by('-total_cost')
        )

        # By station (top 10) — include station_location for map clustering
        by_station = list(
            txs.exclude(station_name='')
              .values('station_name', 'station_location')
              .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'), count=Count('id'))
              .order_by('-total_cost')[:50]
        )

        # Price/gallon trends (avg per day)
        price_trend = list(
            txs.extra(select={'day': 'DATE(date)'})
              .values('day')
              .annotate(
                  avg_price=Avg('total_cost'),
                  total_gallons=Sum('quantity'),
              )
              .order_by('day')
        )
        for row in price_trend:
            row['avg_price_per_gallon'] = (
                round(float(row['avg_price']) / row['total_gallons'], 3)
                if row['total_gallons'] else 0
            )

        # Cost extremes
        cost_agg = txs.aggregate(max_cost=Max('total_cost'), min_cost=Min('total_cost'))

        # By group — daily cost trend per vehicle group (for line race chart)
        by_group_daily = list(
            txs.exclude(vehicle__group__isnull=True)
              .extra(select={'day': 'DATE(date)'})
              .values('day', 'vehicle__group__name')
              .annotate(total_cost=Sum('total_cost'))
              .order_by('day')
        )

        # By vehicle type (e.g. SUV, Truck, Mini-van)
        by_vehicle_type = list(
            txs.exclude(vehicle__vehicle_type='')
              .values('vehicle__vehicle_type')
              .annotate(
                  total_cost=Sum('total_cost'),
                  total_gallons=Sum('quantity'),
                  fill_count=Count('id'),
              )
              .order_by('-total_cost')
        )

        return Response({
            'total_cost': float(total_cost),
            'total_gallons': float(total_gallons),
            'transaction_count': transaction_count,
            'avg_price_per_transaction': float(avg_price),
            'avg_price_per_gallon': round(float(total_cost) / total_gallons, 3) if total_gallons else 0,
            'max_transaction_cost': float(cost_agg['max_cost'] or 0),
            'min_transaction_cost': float(cost_agg['min_cost'] or 0),
            'by_vehicle': by_vehicle,
            'monthly_trend': monthly,
            'daily_trend': daily,
            'by_fuel_type': by_fuel,
            'by_unit': by_unit,
            'by_station': by_station,
            'price_trend': price_trend,
            'by_group_daily': by_group_daily,
            'by_vehicle_type': by_vehicle_type,
        })

    @action(detail=False, methods=['get'])
    def vehicle_fuel_pdf(self, request):
        """Generate a PDF report for a specific vehicle's fuel transactions."""
        from .pdf_export import generate_vehicle_fuel_pdf
        from apps.vehicles.models import Vehicle
        from django.shortcuts import get_object_or_404

        vehicle_id = request.query_params.get('vehicle_id')
        if not vehicle_id:
            return Response(
                {'error': 'vehicle_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        vehicle = get_object_or_404(Vehicle, pk=vehicle_id)
        qs = self.get_queryset().filter(vehicle_id=vehicle_id).order_by('date')

        # Optional date filtering
        date_gte = request.query_params.get('date__gte')
        date_lte = request.query_params.get('date__lte')
        if date_gte:
            qs = qs.filter(date__gte=date_gte)
        if date_lte:
            qs = qs.filter(date__lte=date_lte)

        # Currency symbol
        currency = '$'
        tenant_obj = None
        try:
            from apps.tenants.models import Tenant
            tenant_obj = Tenant.objects.get(schema_name=connection.schema_name)
            currency_map = {
                'USD': '$', 'EUR': '€', 'GBP': '£', 'KES': 'KSh',
                'NGN': '₦', 'ZAR': 'R', 'AED': 'AED', 'SAR': 'SAR',
                'INR': '₹', 'CAD': 'C$', 'AUD': 'A$', 'GHS': '₵',
            }
            currency = currency_map.get(getattr(tenant_obj, 'currency', 'USD'), '$')
        except Exception:
            pass

        # Compute period string from explicit filters or transaction date range
        txs_list = list(qs)
        if date_gte or date_lte:
            from_label = datetime.strptime(date_gte[:10], '%Y-%m-%d').strftime('%b %d, %Y') if date_gte else 'All'
            to_label = datetime.strptime(date_lte[:10], '%Y-%m-%d').strftime('%b %d, %Y') if date_lte else 'Present'
            period_str = f'Period: {from_label} — {to_label}'
        elif txs_list:
            dates = sorted([t.date for t in txs_list])
            from_label = dates[0].strftime('%b %d, %Y')
            to_label = dates[-1].strftime('%b %d, %Y')
            period_str = f'Period: {from_label} — {to_label}'
        else:
            period_str = 'Period: No transactions'

        return generate_vehicle_fuel_pdf(vehicle, txs_list, currency, tenant=tenant_obj, period_str=period_str)

    @action(detail=False, methods=['get'])
    def fleet_fuel_pdf(self, request):
        """Generate a PDF report for all vehicles' fuel analytics."""
        from .pdf_export import generate_fleet_fuel_pdf
        from django.db.models import F, Max, Min, Q

        # ── Build the same query as analytics ──
        date_gte = request.query_params.get('date__gte')
        date_lte = request.query_params.get('date__lte')
        qs = self.get_queryset()
        if date_gte:
            qs = qs.filter(date__gte=date_gte)
        if date_lte:
            qs = qs.filter(date__lte=date_lte)
        if not date_gte and not date_lte:
            days = int(request.query_params.get('days', 30))
            since = timezone.now() - timedelta(days=days)
            qs = qs.filter(date__gte=since)
        fuel_type = request.query_params.get('fuel_type')
        if fuel_type:
            qs = qs.filter(fuel_type=fuel_type)
        group = request.query_params.get('vehicle_group')
        if group:
            qs = qs.filter(vehicle__group_id=group)
        location = request.query_params.get('vehicle_location')
        if location:
            qs = qs.filter(vehicle__location=location)

        txs = qs

        # ── Aggregate data (mirrors analytics action) ──
        total_cost = txs.aggregate(t=Sum('total_cost'))['t'] or 0
        total_gallons = txs.aggregate(t=Sum('quantity'))['t'] or 0
        avg_price = txs.aggregate(a=Avg('total_cost'))['a'] or 0
        transaction_count = txs.count()

        by_vehicle = list(
            txs.values('vehicle_id', 'vehicle__vin', 'vehicle__make', 'vehicle__model',
                       'vehicle__license_plate', 'vehicle__image')
            .annotate(
                total_cost=Sum('total_cost'),
                total_gallons=Sum('quantity'),
                fill_count=Count('id'),
                min_odometer=Min('odometer_reading'),
                max_odometer=Max('odometer_reading'),
            )
            .order_by('-total_cost')
        )
        for row in by_vehicle:
            min_o = row.pop('min_odometer', None)
            max_o = row.pop('max_odometer', None)
            distance = (max_o - min_o) if (min_o is not None and max_o is not None) else None
            row['distance'] = distance
            row['min_odometer'] = min_o
            row['max_odometer'] = max_o
            row['avg_mpg'] = round(distance / row['total_gallons'], 1) if (distance and row['total_gallons']) else None

        monthly = list(
            txs.annotate(month=TruncMonth('date'))
            .values('month')
            .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'))
            .order_by('month')
        )
        for row in monthly:
            m = row.get('month')
            row['month'] = m.strftime('%Y-%m') if m else ''

        daily = list(
            txs.extra(select={'day': 'DATE(date)'})
            .values('day')
            .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'), count=Count('id'))
            .order_by('day')
        )

        by_station = list(
            txs.exclude(station_name='')
            .values('station_name', 'station_location')
            .annotate(total_cost=Sum('total_cost'), total_gallons=Sum('quantity'), count=Count('id'))
            .order_by('-total_cost')[:10]
        )

        cost_agg = txs.aggregate(max_cost=Max('total_cost'), min_cost=Min('total_cost'))

        analytics_data = {
            'total_cost': float(total_cost),
            'total_gallons': float(total_gallons),
            'transaction_count': transaction_count,
            'avg_price_per_transaction': float(avg_price),
            'avg_price_per_gallon': round(float(total_cost) / total_gallons, 3) if total_gallons else 0,
            'max_transaction_cost': float(cost_agg['max_cost'] or 0),
            'min_transaction_cost': float(cost_agg['min_cost'] or 0),
            'by_vehicle': by_vehicle,
            'monthly_trend': monthly,
            'daily_trend': daily,
            'by_station': by_station,
        }

        # ── Currency & tenant ──
        currency = '$'
        tenant_obj = None
        try:
            from apps.tenants.models import Tenant
            tenant_obj = Tenant.objects.get(schema_name=connection.schema_name)
            currency_map = {
                'USD': '$', 'EUR': '€', 'GBP': '£', 'KES': 'KSh',
                'NGN': '₦', 'ZAR': 'R', 'AED': 'AED', 'SAR': 'SAR',
                'INR': '₹', 'CAD': 'C$', 'AUD': 'A$', 'GHS': '₵',
            }
            currency = currency_map.get(getattr(tenant_obj, 'currency', 'USD'), '$')
        except Exception:
            pass

        # ── Period string ──
        if date_gte or date_lte:
            from_label = datetime.strptime(date_gte[:10], '%Y-%m-%d').strftime('%b %d, %Y') if date_gte else 'All'
            to_label = datetime.strptime(date_lte[:10], '%Y-%m-%d').strftime('%b %d, %Y') if date_lte else 'Present'
            period_str = f'Period: {from_label} — {to_label}'
        elif daily:
            from_label = str(daily[0].get('day', ''))
            to_label = str(daily[-1].get('day', ''))
            period_str = f'Period: {from_label} — {to_label}'
        else:
            period_str = 'Period: No data'

        return generate_fleet_fuel_pdf(analytics_data, currency, tenant=tenant_obj, period_str=period_str)


class ChargingSessionFilter(django_filters.FilterSet):
    date__gte = django_filters.IsoDateTimeFilter(field_name='start_time', lookup_expr='gte')
    date__lte = django_filters.IsoDateTimeFilter(field_name='start_time', lookup_expr='lte')

    class Meta:
        model = ChargingSession
        fields = ['vehicle', 'station_network', 'date__gte', 'date__lte']


class ChargingSessionViewSet(viewsets.ModelViewSet):
    queryset = ChargingSession.objects.select_related('vehicle')
    serializer_class = ChargingSessionSerializer
    filterset_class = ChargingSessionFilter
    ordering_fields = ['start_time', 'energy_kwh', 'cost']

    @action(detail=False, methods=['get'])
    def summary(self, request):
        date_gte = request.query_params.get('date__gte')
        date_lte = request.query_params.get('date__lte')
        sessions = self.get_queryset()
        if date_gte:
            sessions = sessions.filter(start_time__gte=date_gte)
        if date_lte:
            sessions = sessions.filter(start_time__lte=date_lte)
        if not date_gte and not date_lte:
            days = int(request.query_params.get('days', 30))
            since = timezone.now() - timedelta(days=days)
            sessions = sessions.filter(start_time__gte=since)
        data = sessions.aggregate(
            total_kwh=Sum('energy_kwh'),
            total_cost=Sum('cost'),
            session_count=Count('id'),
        )
        by_network = list(
            sessions.values('station_network')
            .annotate(total_kwh=Sum('energy_kwh'), total_cost=Sum('cost'), count=Count('id'))
            .order_by('-total_cost')
        )
        by_vehicle = list(
            sessions.values('vehicle__vin', 'vehicle__make', 'vehicle__model', 'vehicle__license_plate')
            .annotate(total_kwh=Sum('energy_kwh'), total_cost=Sum('cost'), count=Count('id'))
            .order_by('-total_cost')
        )
        return Response({
            'total_kwh': float(data['total_kwh'] or 0),
            'total_cost': float(data['total_cost'] or 0),
            'session_count': data['session_count'],
            'avg_cost_per_kwh': round(
                float(data['total_cost'] or 0) / max(float(data['total_kwh'] or 1), 1), 3
            ),
            'by_network': by_network,
            'by_vehicle': by_vehicle,
        })


class FuelFraudAlertViewSet(viewsets.ModelViewSet):
    queryset = FuelFraudAlert.objects.select_related('transaction', 'transaction__vehicle', 'resolved_by')
    serializer_class = FuelFraudAlertSerializer
    filterset_fields = ['alert_type', 'severity', 'action_status', 'is_resolved']
    ordering_fields = ['created_at', 'severity']

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        alert = self.get_object()
        alert.action_status = FuelFraudAlert.ActionStatus.RESOLVED
        alert.is_resolved = True
        alert.resolved_by = request.user
        alert.resolved_at = timezone.now()
        note = request.data.get('status_note', '')
        if note:
            alert.status_note = note
        alert.save(update_fields=['action_status', 'is_resolved', 'resolved_by', 'resolved_at', 'status_note'])
        return Response(FuelFraudAlertSerializer(alert).data)

    @action(detail=True, methods=['post'])
    def dismiss(self, request, pk=None):
        alert = self.get_object()
        alert.action_status = FuelFraudAlert.ActionStatus.DISMISSED
        note = request.data.get('status_note', '')
        if note:
            alert.status_note = note
        alert.save(update_fields=['action_status', 'status_note'])
        return Response(FuelFraudAlertSerializer(alert).data)

    @action(detail=True, methods=['post'])
    def review(self, request, pk=None):
        alert = self.get_object()
        alert.action_status = FuelFraudAlert.ActionStatus.UNDER_REVIEW
        note = request.data.get('status_note', '')
        if note:
            alert.status_note = note
        alert.save(update_fields=['action_status', 'status_note'])
        return Response(FuelFraudAlertSerializer(alert).data)

    @action(detail=True, methods=['post'])
    def reopen(self, request, pk=None):
        alert = self.get_object()
        alert.action_status = FuelFraudAlert.ActionStatus.OPEN
        alert.is_resolved = False
        alert.resolved_by = None
        alert.resolved_at = None
        note = request.data.get('status_note', '')
        if note:
            alert.status_note = note
        alert.save(update_fields=['action_status', 'is_resolved', 'resolved_by', 'resolved_at', 'status_note'])
        return Response(FuelFraudAlertSerializer(alert).data)

    @action(detail=False, methods=['get'])
    def summary(self, request):
        qs = self.get_queryset()
        return Response({
            'total': qs.count(),
            'unresolved': qs.filter(is_resolved=False).count(),
            'critical': qs.filter(severity='critical', is_resolved=False).count(),
            'by_type': list(qs.values('alert_type').annotate(count=Count('id'))),
            'by_status': list(qs.values('action_status').annotate(count=Count('id'))),
        })


class ChargeScheduleViewSet(viewsets.ModelViewSet):
    queryset = ChargeSchedule.objects.select_related('vehicle')
    serializer_class = ChargeScheduleSerializer
    filterset_fields = ['vehicle', 'is_active']


class FuelBudgetViewSet(viewsets.ModelViewSet):
    queryset = FuelBudget.objects.all()
    serializer_class = FuelBudgetSerializer
    filterset_fields = ['scope', 'month']
    ordering_fields = ['month', 'budget_amount']

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Budget vs actual spending for the current month."""
        now = timezone.now()
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        next_month = (month_start.replace(day=28) + timedelta(days=4)).replace(day=1)
        budgets = self.get_queryset().filter(month__year=now.year, month__month=now.month)
        txs = FuelTransaction.objects.filter(date__gte=month_start, date__lt=next_month)
        actual_fleet = float(txs.aggregate(t=Sum('total_cost'))['t'] or 0)
        rows = []
        for b in budgets:
            if b.scope == 'fleet':
                actual = actual_fleet
            elif b.scope == 'vehicle_type':
                if not b.target_ref:
                    actual = actual_fleet
                else:
                    actual = float(txs.filter(vehicle__vehicle_type=b.target_ref).aggregate(t=Sum('total_cost'))['t'] or 0)
            elif b.scope == 'location':
                if not b.target_ref:
                    actual = actual_fleet
                else:
                    actual = float(txs.filter(vehicle__location=b.target_ref).aggregate(t=Sum('total_cost'))['t'] or 0)
            else:
                actual = 0
            rows.append({
                'id': b.id,
                'scope': b.scope,
                'target_ref': b.target_ref,
                'month': b.month.strftime('%Y-%m'),
                'budget': float(b.budget_amount),
                'actual': round(actual, 2),
                'variance': round(actual - float(b.budget_amount), 2),
                'pct_used': round(actual / float(b.budget_amount) * 100, 1) if b.budget_amount else 0,
            })
        return Response({'rows': rows, 'actual_fleet': actual_fleet})


class IdlingEventFilter(django_filters.FilterSet):
    date__gte = django_filters.IsoDateTimeFilter(field_name='start_time', lookup_expr='gte')
    date__lte = django_filters.IsoDateTimeFilter(field_name='start_time', lookup_expr='lte')

    class Meta:
        model = IdlingEvent
        fields = ['vehicle', 'date__gte', 'date__lte']


class IdlingEventViewSet(viewsets.ModelViewSet):
    queryset = IdlingEvent.objects.select_related('vehicle')
    serializer_class = IdlingEventSerializer
    filterset_class = IdlingEventFilter
    ordering_fields = ['start_time']

    @action(detail=False, methods=['get'])
    def summary(self, request):
        date_gte = request.query_params.get('date__gte')
        date_lte = request.query_params.get('date__lte')
        events = self.get_queryset()
        if date_gte:
            events = events.filter(start_time__gte=date_gte)
        if date_lte:
            events = events.filter(start_time__lte=date_lte)
        if not date_gte and not date_lte:
            days = int(request.query_params.get('days', 30))
            since = timezone.now() - timedelta(days=days)
            events = events.filter(start_time__gte=since)
        total_cost = sum(e.cost or 0 for e in events)
        total_fuel = sum(e.fuel_burned or 0 for e in events)
        total_hours = sum(e.duration_hours or 0 for e in events)
        # By vehicle
        by_vehicle = []
        for ev in events:
            name = ev.vehicle.display_name if ev.vehicle else 'Unknown'
            found = next((r for r in by_vehicle if r['vehicle'] == name), None)
            if found:
                found['hours'] = round(found['hours'] + (ev.duration_hours or 0), 1)
                found['cost'] = round(found['cost'] + (ev.cost or 0), 2)
                found['fuel'] = round(found['fuel'] + (ev.fuel_burned or 0), 2)
                found['events'] += 1
            else:
                by_vehicle.append({
                    'vehicle': name,
                    'hours': round(ev.duration_hours or 0, 1),
                    'cost': round(ev.cost or 0, 2),
                    'fuel': round(ev.fuel_burned or 0, 2),
                    'events': 1,
                })
        by_vehicle.sort(key=lambda r: r['cost'], reverse=True)
        return Response({
            'total_events': events.count(),
            'total_hours': round(total_hours, 1),
            'total_fuel_burned': round(total_fuel, 2),
            'total_cost': round(total_cost, 2),
            'by_vehicle': by_vehicle[:10],
        })
