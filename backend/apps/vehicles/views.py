from drf_spectacular.utils import extend_schema
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import CustomField, CustomFieldValue, FleetGroup, MeterEntry, Vehicle, VehicleBodyType, VehicleMake, VehicleModel, VehicleType
from .serializers import (
    CustomFieldSerializer,
    CustomFieldValueSerializer,
    FleetGroupSerializer,
    MeterEntrySerializer,
    VehicleBodyTypeSerializer,
    VehicleMakeSerializer,
    VehicleModelSerializer,
    VehicleSerializer,
    VehicleTypeSerializer,
    VinDecodeSerializer,
)


class FleetGroupViewSet(viewsets.ModelViewSet):
    queryset = FleetGroup.objects.all()
    serializer_class = FleetGroupSerializer
    filterset_fields = ['name']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at']


class VehicleTypeViewSet(viewsets.ModelViewSet):
    queryset = VehicleType.objects.all()
    serializer_class = VehicleTypeSerializer
    search_fields = ['name', 'description']
    ordering_fields = ['sort_order', 'name', 'created_at']
    filterset_fields = ['is_active']


class VehicleMakeViewSet(viewsets.ModelViewSet):
    queryset = VehicleMake.objects.all()
    serializer_class = VehicleMakeSerializer
    search_fields = ['name']
    ordering_fields = ['name', 'created_at']


class VehicleBodyTypeViewSet(viewsets.ModelViewSet):
    queryset = VehicleBodyType.objects.all()
    serializer_class = VehicleBodyTypeSerializer
    search_fields = ['label', 'value']
    ordering_fields = ['label', 'created_at']


class VehicleModelViewSet(viewsets.ModelViewSet):
    queryset = VehicleModel.objects.select_related('make', 'body_type').all()
    serializer_class = VehicleModelSerializer
    filterset_fields = ['make', 'body_type']
    search_fields = ['name']
    ordering_fields = ['name', 'created_at']


class VehicleViewSet(viewsets.ModelViewSet):
    queryset = Vehicle.objects.select_related(
        'group', 'assigned_driver', 'lessor',
    ).prefetch_related(
        'rental_agreements__customer',
    )
    serializer_class = VehicleSerializer
    filterset_fields = ['status', 'fuel_type', 'vehicle_type', 'group', 'assigned_driver', 'ownership', 'lessor']
    search_fields = ['vin', 'license_plate', 'make', 'model']
    ordering_fields = ['created_at', 'year', 'current_mileage', 'purchase_price', 'lease_start_date', 'lease_end_date']

    @action(detail=False, methods=['get'])
    def analytics(self, request):
        """Fleet-wide vehicle analytics dashboards."""
        from django.db.models import Avg, Count, FloatField, IntegerField, Max, Q, Sum
        from django.db.models.functions import Coalesce, TruncMonth
        from django.utils.timezone import make_aware
        from datetime import datetime as _dt, time as _time
        qs = self.get_queryset()

        def _parse_dt(value, end=False):
            """Parse a date string 'YYYY-MM-DD' into a timezone-aware datetime."""
            if not value:
                return None
            try:
                d = _dt.strptime(value, '%Y-%m-%d')
                return make_aware(_dt.combine(d.date(), _time.max if end else _time.min))
            except (ValueError, TypeError):
                return None

        # Date range input (used for revenue/service filtering only — NOT for
        # filtering the base vehicle queryset, which would hide all vehicles
        # not purchased within the range and blank out fleet stats).
        date_gte = request.query_params.get('date__gte')
        date_lte = request.query_params.get('date__lte')

        # Revenue date range (filters rental/service by datetime fields)
        rev_start = _parse_dt(request.query_params.get('rev_start') or date_gte, end=False)
        rev_end = _parse_dt(request.query_params.get('rev_end') or date_lte, end=True)
        total = qs.count()

        # --- Status breakdown ---
        status_counts = list(qs.values('status').annotate(count=Count('id')).order_by('-count'))

        # --- Fuel type breakdown ---
        fuel_counts = list(qs.values('fuel_type').annotate(count=Count('id')).order_by('-count'))

        # --- Vehicle type breakdown ---
        vtype_counts = list(qs.values('vehicle_type').annotate(count=Count('id')).order_by('-count'))

        # --- Ownership breakdown ---
        ownership_counts = list(qs.values('ownership').annotate(count=Count('id')).order_by('-count'))

        # --- Make breakdown (top 10) ---
        make_counts = list(
            qs.exclude(make='').values('make').annotate(count=Count('id')).order_by('-count')[:10]
        )

        # --- Acquisition trend (by month) ---
        acquisition = list(
            qs.filter(purchase_date__isnull=False)
              .annotate(month=TruncMonth('purchase_date'))
              .values('month')
              .annotate(count=Count('id'))
              .order_by('month')
        )
        for row in acquisition:
            m = row.get('month')
            row['month'] = m.strftime('%Y-%m') if m else ''

        # --- Mileage statistics ---
        mileage_agg = qs.aggregate(
            total_mileage=Coalesce(Sum('current_mileage'), 0, output_field=IntegerField()),
            avg_mileage=Coalesce(Avg('current_mileage'), 0, output_field=IntegerField()),
            total_engine_hours=Coalesce(Sum('engine_hours'), 0, output_field=FloatField()),
        )

        # --- Value / depreciation ---
        value_agg = qs.aggregate(
            total_purchase_value=Coalesce(Sum('purchase_price'), 0, output_field=IntegerField()),
            avg_purchase_value=Coalesce(Avg('purchase_price'), 0, output_field=IntegerField()),
        )

        # --- Fleet age distribution ---
        from datetime import date
        this_year = date.today().year
        age_buckets = {'0-2': 0, '3-5': 0, '6-10': 0, '11-15': 0, '15+': 0, 'Unknown': 0}
        for v in qs.values('year'):
            y = v.get('year')
            if not y:
                age_buckets['Unknown'] += 1
                continue
            age = this_year - y
            if age <= 2: age_buckets['0-2'] += 1
            elif age <= 5: age_buckets['3-5'] += 1
            elif age <= 10: age_buckets['6-10'] += 1
            elif age <= 15: age_buckets['11-15'] += 1
            else: age_buckets['15+'] += 1

        # --- Active vs inactive ---
        active = qs.filter(status='active').count()
        in_maintenance = qs.filter(status='in_maintenance').count()
        out_of_service = qs.filter(status='out_of_service').count()
        retired = qs.filter(status='retired').count()

        # --- EV stats ---
        ev_count = qs.filter(
            Q(fuel_type='Electric') | Q(fuel_type='Fuel Cell (Hydrogen)')
        ).count()
        ev_agg = qs.filter(
            Q(fuel_type='Electric') | Q(fuel_type='Fuel Cell (Hydrogen)')
        ).aggregate(
            avg_soc=Coalesce(Avg('state_of_charge'), 0, output_field=FloatField()),
            avg_soh=Coalesce(Avg('state_of_health'), 0, output_field=FloatField()),
        )

        # --- Utilization & Performance ---
        from apps.rentals.models import RentalAgreement as RA
        rental_qs = RA.objects.exclude(status='draft')
        if rev_start and rev_end:
            rental_qs = rental_qs.filter(created_at__gte=rev_start, created_at__lte=rev_end)
        total_rentals = rental_qs.count()
        active_rentals = rental_qs.filter(status='active').count()
        completed_rentals = rental_qs.filter(status='completed').count()
        cancelled_rentals = rental_qs.filter(status='cancelled').count()
        overdue_rentals = rental_qs.filter(status='overdue').count()

        # Vehicles with at least 1 active rental
        vehicles_with_active_rentals = qs.filter(
            rental_agreements__status='active'
        ).distinct().count()
        utilization_rate = round(
            (vehicles_with_active_rentals / max(total, 1)) * 100, 1
        ) if total else 0

        # Revenue per vehicle (filtered by date range if provided)
        rev_date_q = Q()
        if rev_start and rev_end:
            rev_date_q = Q(rental_agreements__created_at__gte=rev_start,
                           rental_agreements__created_at__lte=rev_end)
        rev_status_q = Q(rental_agreements__status='active') | Q(rental_agreements__status='completed')
        revenue_agg = qs.annotate(
            rev=Coalesce(Sum('rental_agreements__total_amount',
                             filter=rev_status_q & rev_date_q, output_field=IntegerField()), 0,
                        output_field=IntegerField()),
        ).aggregate(
            total_revenue=Coalesce(Sum('rev'), 0, output_field=IntegerField()),
            avg_revenue=Coalesce(Avg('rev'), 0, output_field=IntegerField()),
            max_revenue=Coalesce(Max('rev'), 0, output_field=IntegerField()),
        )

        # Revenue by month (last 12 months from rental agreements)
        rev_monthly = list(
            rental_qs.filter(status__in=['active', 'completed'])
            .annotate(month=TruncMonth('created_at'))
            .values('month')
            .annotate(revenue=Coalesce(Sum('total_amount'), 0, output_field=IntegerField()),
                      count=Count('id'))
            .order_by('month')[:12]
        )
        for row in rev_monthly:
            m = row.get('month')
            row['month'] = m.strftime('%Y-%m') if m else ''

        # Revenue by vehicle type
        rev_by_type = list(
            qs.values('vehicle_type')
              .annotate(
                revenue=Coalesce(Sum('rental_agreements__total_amount',
                                     filter=Q(rental_agreements__status='active') |
                                            Q(rental_agreements__status='completed'), output_field=IntegerField()), 0,
                                output_field=IntegerField()),
                count=Count('id'),
              )
              .order_by('-revenue')
        )

        # Top revenue vehicles (filtered by date range if provided)
        top_vehicles = list(
            qs.annotate(
                rev=Coalesce(Sum('rental_agreements__total_amount',
                                 filter=rev_status_q & rev_date_q, output_field=IntegerField()), 0,
                            output_field=IntegerField()),
                rental_cnt=Count('rental_agreements', filter=rev_status_q & rev_date_q, distinct=True),
            ).values('id', 'make', 'model', 'year', 'license_plate', 'rev', 'rental_cnt', 'status')
              .order_by('-rev')[:10]
        )

        # Idle vehicles (no rentals at all)
        vehicles_with_rentals = set(
            rental_qs.values_list('vehicle_id', flat=True)
        )
        idle_vehicles = qs.exclude(id__in=vehicles_with_rentals).count()

        # --- Cost & Depreciation ---
        # Total service costs (filtered by date range on performed_at if provided)
        from apps.services.models import Service
        svc_filter = Q(vehicle__in=qs)
        if rev_start and rev_end:
            svc_filter &= Q(performed_at__gte=rev_start, performed_at__lte=rev_end)
        service_cost_agg = Service.objects.filter(
            svc_filter
        ).aggregate(
            total_cost=Coalesce(Sum('cost'), 0, output_field=IntegerField()),
            avg_cost=Coalesce(Avg('cost'), 0, output_field=IntegerField()),
            total_downtime=Coalesce(Sum('downtime_hours'), 0, output_field=FloatField()),
        )
        total_services = Service.objects.filter(svc_filter).count()

        # Service cost by type
        service_by_type = list(
            Service.objects.filter(svc_filter)
            .values('service_type')
            .annotate(count=Count('id'),
                      cost=Coalesce(Sum('cost'), 0, output_field=IntegerField()))
            .order_by('-cost')
        )

        # Depreciation per vehicle
        from datetime import date as _date
        today = _date.today()
        depreciation_data = []
        for v in qs.values('id', 'make', 'model', 'year', 'purchase_price', 'purchase_date',
                          'salvage_value', 'useful_life_years', 'current_mileage'):
            pp = float(v.get('purchase_price') or 0)
            sv = float(v.get('salvage_value') or 0)
            uly = v.get('useful_life_years')
            pd = v.get('purchase_date')
            age_years = 0
            if pd:
                age_years = max((today - pd).days / 365.25, 0)
            # Straight-line depreciation
            book_value = pp
            annual_dep = 0
            if pp and uly:
                annual_dep = (pp - sv) / uly
                book_value = max(pp - (annual_dep * age_years), sv)
            depreciation_pct = round(((pp - book_value) / pp) * 100, 1) if pp else 0
            depreciation_data.append({
                'id': v['id'],
                'make': v['make'],
                'model': v['model'],
                'year': v['year'],
                'license_plate': v.get('license_plate', ''),
                'purchase_price': pp,
                'book_value': round(book_value, 2),
                'depreciation_pct': depreciation_pct,
                'annual_depreciation': round(annual_dep, 2),
                'age_years': round(age_years, 1),
                'current_mileage': v.get('current_mileage', 0),
            })
        depreciation_data.sort(key=lambda x: x['depreciation_pct'], reverse=True)

        total_book_value = sum(d['book_value'] for d in depreciation_data)
        total_annual_dep = sum(d['annual_depreciation'] for d in depreciation_data)
        total_dep_loss = sum(d['purchase_price'] - d['book_value'] for d in depreciation_data)

        # Cost per km
        total_mileage_val = float(mileage_agg['total_mileage'] or 0)
        total_operating_cost = float(service_cost_agg['total_cost'] or 0)
        cost_per_km = round(total_operating_cost / total_mileage_val, 2) if total_mileage_val else 0

        # --- Fleet Health ---
        # Inspection stats
        from apps.inspections.models import InspectionReport
        inspection_stats = InspectionReport.objects.filter(
            vehicle__in=qs
        ).values('status').annotate(count=Count('id'))
        inspection_map = {s['status']: s['count'] for s in inspection_stats}
        total_inspections = sum(inspection_map.values())
        pass_count = inspection_map.get('pass', 0)
        fail_count = inspection_map.get('fail', 0)
        inspection_pass_rate = round(
            (pass_count / max(total_inspections, 1)) * 100, 1
        ) if total_inspections else 0

        # Health score: weighted combination of utilisation, inspection pass rate, and status
        active_pct = round((active / max(total, 1)) * 100, 1) if total else 0
        fleet_health_score = round(
            (utilization_rate * 0.3) + (inspection_pass_rate * 0.3) + (active_pct * 0.4), 1
        ) if total else 0

        # Maintenance ratio
        maintenance_pct = round((in_maintenance / max(total, 1)) * 100, 1) if total else 0
        out_of_service_pct = round((out_of_service / max(total, 1)) * 100, 1) if total else 0

        # Vehicles needing attention (in maintenance, out of service, or failed inspection)
        vehicles_needing_attention = in_maintenance + out_of_service + fail_count

        # --- ABC Analysis (revenue-based Pareto) ---
        # Classify vehicles as A (top 80% revenue), B (next 15%), C (bottom 5%)
        from apps.rentals.models import RentalAgreement as RA2

        # ABC-specific date range: use rev_start/rev_end or abc_start/abc_end
        abc_start = _parse_dt(request.query_params.get('abc_start'), end=False) or rev_start
        abc_end = _parse_dt(request.query_params.get('abc_end'), end=True) or rev_end

        abc_q = Q(rental_agreements__status='active') | Q(rental_agreements__status='completed')
        if abc_start and abc_end:
            abc_q &= Q(rental_agreements__created_at__gte=abc_start,
                       rental_agreements__created_at__lte=abc_end)

        vehicle_revenue = list(
            qs.exclude(rental_agreements__status='draft')
              .annotate(
                total_rev=Coalesce(Sum('rental_agreements__total_amount', filter=abc_q, output_field=IntegerField()), 0,
                                   output_field=IntegerField()),
                rental_count=Count('rental_agreements', filter=abc_q, distinct=True),
              )
              .values('id', 'make', 'model', 'year', 'license_plate',
                     'vin', 'total_rev', 'rental_count',
                     'fuel_type', 'vehicle_type', 'current_mileage',
                     'purchase_price', 'status')
              .order_by('-total_rev')
        )

        grand_total = sum(v['total_rev'] for v in vehicle_revenue)
        cumulative = 0
        abc_a, abc_b, abc_c = [], [], []
        for v in vehicle_revenue:
            cumulative += v['total_rev']
            pct = (cumulative / grand_total * 100) if grand_total else 0
            v['cumulative_pct'] = round(pct, 2)
            v['revenue_pct'] = round((v['total_rev'] / grand_total * 100) if grand_total else 0, 2)
            if pct <= 80:
                v['abc_class'] = 'A'
                abc_a.append(v)
            elif pct <= 95:
                v['abc_class'] = 'B'
                abc_b.append(v)
            else:
                v['abc_class'] = 'C'
                abc_c.append(v)

        abc_summary = {
            'A': {'count': len(abc_a), 'revenue': sum(v['total_rev'] for v in abc_a),
                  'pct': round(len(abc_a) / max(len(vehicle_revenue), 1) * 100, 1)},
            'B': {'count': len(abc_b), 'revenue': sum(v['total_rev'] for v in abc_b),
                  'pct': round(len(abc_b) / max(len(vehicle_revenue), 1) * 100, 1)},
            'C': {'count': len(abc_c), 'revenue': sum(v['total_rev'] for v in abc_c),
                  'pct': round(len(abc_c) / max(len(vehicle_revenue), 1) * 100, 1)},
            'total_revenue': grand_total,
            'total_vehicles': len(vehicle_revenue),
        }

        # Vehicles with zero rentals (for context)
        no_revenue_count = qs.exclude(
            id__in=[v['id'] for v in vehicle_revenue]
        ).count()

        # --- Vehicle Type Analysis ---
        from apps.services.models import Service as _Svc

        # Base stats per type (no rental join → no row multiplication)
        type_analysis = list(
            qs.values('vehicle_type')
              .annotate(
                count=Count('id'),
                total_mileage=Coalesce(Sum('current_mileage'), 0, output_field=IntegerField()),
                avg_mileage=Coalesce(Avg('current_mileage'), 0, output_field=IntegerField()),
                total_purchase_value=Coalesce(Sum('purchase_price'), 0, output_field=IntegerField()),
                active_count=Count('id', filter=Q(status='active')),
                in_maintenance_count=Count('id', filter=Q(status='in_maintenance')),
                out_of_service_count=Count('id', filter=Q(status='out_of_service')),
                ev_count=Count('id', filter=Q(fuel_type='Electric') | Q(fuel_type='Fuel Cell (Hydrogen)')),
              )
              .order_by('-count')
        )

        # Revenue per type (separate query to avoid join multiplication)
        rev_filter = Q(rental_agreements__status='active') | Q(rental_agreements__status='completed')
        if rev_start and rev_end:
            rev_filter &= Q(rental_agreements__created_at__gte=rev_start,
                            rental_agreements__created_at__lte=rev_end)
        type_revenue = list(
            qs.values('vehicle_type')
              .annotate(
                revenue=Coalesce(Sum('rental_agreements__total_amount', filter=rev_filter, output_field=IntegerField()), 0,
                                 output_field=IntegerField()),
                rental_count=Count('rental_agreements', filter=rev_filter, distinct=True),
              )
        )
        type_rev_map = {r['vehicle_type']: r for r in type_revenue}

        # Service cost per type
        svc_vtype_filter = Q(vehicle__in=qs)
        if rev_start and rev_end:
            svc_vtype_filter &= Q(performed_at__gte=rev_start, performed_at__lte=rev_end)
        service_by_vtype = list(
            _Svc.objects.filter(svc_vtype_filter)
            .values('vehicle__vehicle_type')
            .annotate(
                service_cost=Coalesce(Sum('cost'), 0, output_field=IntegerField()),
                service_count=Count('id'),
            )
        )
        svc_map = {row['vehicle__vehicle_type'] or 'Unknown': row for row in service_by_vtype}

        for row in type_analysis:
            vt = row['vehicle_type'] or 'Unknown'
            row['vehicle_type'] = vt
            rev_row = type_rev_map.get(row['vehicle_type'], {})
            row['revenue'] = rev_row.get('revenue', 0) or 0
            row['rental_count'] = rev_row.get('rental_count', 0) or 0
            st = svc_map.get(vt, {})
            row['service_cost'] = st.get('service_cost', 0)
            row['service_count'] = st.get('service_count', 0)

        # --- Location Analysis ---
        loc_vehicle_qs = qs.exclude(location='')

        # Base stats per location (no rental join → no row multiplication)
        location_analysis = list(
            loc_vehicle_qs.values('location')
              .annotate(
                count=Count('id'),
                total_mileage=Coalesce(Sum('current_mileage'), 0, output_field=IntegerField()),
                avg_mileage=Coalesce(Avg('current_mileage'), 0, output_field=IntegerField()),
                total_purchase_value=Coalesce(Sum('purchase_price'), 0, output_field=IntegerField()),
                active_count=Count('id', filter=Q(status='active')),
                in_maintenance_count=Count('id', filter=Q(status='in_maintenance')),
                out_of_service_count=Count('id', filter=Q(status='out_of_service')),
                ev_count=Count('id', filter=Q(fuel_type='Electric') | Q(fuel_type='Fuel Cell (Hydrogen)')),
                types_count=Count('vehicle_type', distinct=True),
              )
              .order_by('-count')
        )

        # Revenue per location (separate query)
        loc_revenue = list(
            loc_vehicle_qs.values('location')
              .annotate(
                revenue=Coalesce(Sum('rental_agreements__total_amount', filter=rev_filter, output_field=IntegerField()), 0,
                                 output_field=IntegerField()),
                rental_count=Count('rental_agreements', filter=rev_filter, distinct=True),
              )
        )
        loc_rev_map = {r['location']: r for r in loc_revenue}

        # Service cost per location
        svc_loc_filter = Q(vehicle__in=qs, vehicle__location__isnull=False) & ~Q(vehicle__location='')
        if rev_start and rev_end:
            svc_loc_filter &= Q(performed_at__gte=rev_start, performed_at__lte=rev_end)
        service_by_loc = list(
            _Svc.objects.filter(svc_loc_filter)
            .values('vehicle__location')
            .annotate(
                service_cost=Coalesce(Sum('cost'), 0, output_field=IntegerField()),
                service_count=Count('id'),
            )
        )
        svc_loc_map = {row['vehicle__location']: row for row in service_by_loc}

        for row in location_analysis:
            loc = row['location']
            rev_row = loc_rev_map.get(loc, {})
            row['revenue'] = rev_row.get('revenue', 0) or 0
            row['rental_count'] = rev_row.get('rental_count', 0) or 0
            st = svc_loc_map.get(loc, {})
            row['service_cost'] = st.get('service_cost', 0)
            row['service_count'] = st.get('service_count', 0)

        return Response({
            'total_vehicles': total,
            'active': active,
            'in_maintenance': in_maintenance,
            'out_of_service': out_of_service,
            'retired': retired,
            'status_breakdown': status_counts,
            'fuel_type_breakdown': fuel_counts,
            'vehicle_type_breakdown': vtype_counts,
            'ownership_breakdown': ownership_counts,
            'top_makes': make_counts,
            'acquisition_trend': acquisition,
            'mileage_stats': {
                'total_mileage': float(mileage_agg['total_mileage']),
                'avg_mileage': float(mileage_agg['avg_mileage']),
                'total_engine_hours': float(mileage_agg['total_engine_hours']),
            },
            'value_stats': {
                'total_purchase_value': float(value_agg['total_purchase_value']),
                'avg_purchase_value': float(value_agg['avg_purchase_value']),
            },
            'age_distribution': age_buckets,
            'ev_stats': {
                'count': ev_count,
                'avg_state_of_charge': float(ev_agg['avg_soc']),
                'avg_state_of_health': float(ev_agg['avg_soh']),
            },
            # --- Utilization & Performance ---
            'utilization': {
                'total_rentals': total_rentals,
                'active_rentals': active_rentals,
                'completed_rentals': completed_rentals,
                'cancelled_rentals': cancelled_rentals,
                'overdue_rentals': overdue_rentals,
                'utilization_rate': utilization_rate,
                'vehicles_with_active_rentals': vehicles_with_active_rentals,
                'idle_vehicles': idle_vehicles,
                'total_revenue': float(revenue_agg['total_revenue']),
                'avg_revenue_per_vehicle': float(revenue_agg['avg_revenue']),
                'max_revenue': float(revenue_agg['max_revenue']),
                'revenue_monthly': rev_monthly,
                'revenue_by_type': rev_by_type,
                'top_vehicles': top_vehicles,
            },
            # --- Cost & Depreciation ---
            'cost_analysis': {
                'total_service_cost': float(service_cost_agg['total_cost']),
                'avg_service_cost': float(service_cost_agg['avg_cost']),
                'total_downtime_hours': float(service_cost_agg['total_downtime']),
                'total_services': total_services,
                'service_by_type': service_by_type,
                'total_book_value': round(total_book_value, 2),
                'total_annual_depreciation': round(total_annual_dep, 2),
                'total_depreciation_loss': round(total_dep_loss, 2),
                'cost_per_km': cost_per_km,
                'vehicles': depreciation_data[:20],
            },
            # --- Fleet Health ---
            'fleet_health': {
                'fleet_health_score': fleet_health_score,
                'inspection_pass_rate': inspection_pass_rate,
                'total_inspections': total_inspections,
                'pass_count': pass_count,
                'fail_count': fail_count,
                'maintenance_pct': maintenance_pct,
                'out_of_service_pct': out_of_service_pct,
                'vehicles_needing_attention': vehicles_needing_attention,
            },
            'abc_analysis': {
                'summary': abc_summary,
                'vehicles': vehicle_revenue[:50],  # Top 50 for UI display
                'no_revenue_count': no_revenue_count,
            },
            'type_analysis': type_analysis,
            'location_analysis': location_analysis,
        })

    @action(detail=True, methods=['post'])
    def meter_entry(self, request, pk=None):
        vehicle = self.get_object()
        serializer = MeterEntrySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(vehicle=vehicle)
        vehicle.refresh_from_db()
        return Response(VehicleSerializer(vehicle).data)

    @action(detail=True, methods=['get'])
    def profit_loss(self, request, pk=None):
        """Per-vehicle Profit and Loss statement.

        Aggregates all revenue and cost data specific to this vehicle:
          - Revenue: Rental agreements, add-ons, charges
          - Variable Costs: fuel, charging, service, accidents
          - Fixed Costs: lease, insurance, financing, depreciation
          - Monthly trend, cost distribution, statement
        Supports ?start_date= and ?end_date= query params.
        """
        import datetime as _dt
        from decimal import Decimal
        from django.db.models import Sum
        from django.utils import timezone
        from apps.rentals.models import RentalAgreement, RentalPayment, RentalCharge, VehicleDamage
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport

        vehicle = self.get_object()

        start_str = request.query_params.get('start_date')
        end_str = request.query_params.get('end_date')
        now = timezone.now()
        now_date = now.date()

        if start_str and end_str:
            try:
                d_start = _dt.date.fromisoformat(start_str)
                d_end = _dt.date.fromisoformat(end_str)
            except ValueError:
                d_start = now_date.replace(day=1) - _dt.timedelta(days=30 * 5)
                d_end = now_date
        else:
            d_start = now_date.replace(day=1) - _dt.timedelta(days=30 * 5)
            d_end = now_date

        since = _dt.datetime.combine(d_start, _dt.time.min)
        until = _dt.datetime.combine(d_end + _dt.timedelta(days=1), _dt.time.min)
        prev_start = since - (until - since)

        # ── REVENUE ──
        rentals = RentalAgreement.objects.filter(vehicle=vehicle).exclude(status='draft')
        period_rentals = rentals.filter(created_at__gte=since, created_at__lt=until)
        prev_rentals = rentals.filter(created_at__gte=prev_start, created_at__lt=since)

        rental_revenue = float(period_rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        prev_rental_revenue = float(prev_rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))

        # Add-ons breakdown
        add_on_fields = ['insurance_premium', 'gps_fee', 'child_seat_fee',
                         'additional_driver_fee', 'delivery_fee']
        add_on_agg = period_rentals.aggregate(**{f: Sum(f) for f in add_on_fields})
        add_on_lines = {}
        for f in add_on_fields:
            val = float(add_on_agg.get(f) or 0)
            if val:
                add_on_lines[f.replace('_', ' ').title()] = val
        base_rental_revenue = rental_revenue - sum(add_on_lines.values())

        # Rental charges per type
        charges_qs = RentalCharge.objects.filter(
            agreement__vehicle=vehicle,
            created_at__gte=since, created_at__lt=until,
        )
        charge_by_type = {}
        for ch in charges_qs.values('charge_type').annotate(t=Sum('total_amount')):
            ct = ch['charge_type'] or 'other'
            charge_by_type[ct.replace('_', ' ').title()] = float(ch['t'] or 0)

        # Payments collected
        payments = RentalPayment.objects.filter(
            agreement__vehicle=vehicle,
            status='completed', paid_at__gte=since, paid_at__lt=until,
        )
        cash_collected = float(payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        prev_payments = RentalPayment.objects.filter(
            agreement__vehicle=vehicle,
            status='completed', paid_at__gte=prev_start, paid_at__lt=since,
        )
        prev_cash = float(prev_payments.aggregate(t=Sum('amount'))['t'] or Decimal('0'))

        # Outstanding A/R for this vehicle
        all_invoiced = float(rentals.aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
        all_collected = float(RentalPayment.objects.filter(
            agreement__vehicle=vehicle, status='completed'
        ).aggregate(t=Sum('amount'))['t'] or Decimal('0'))
        outstanding = all_invoiced - all_collected

        # ── VARIABLE COSTS (COGS) ──
        fuel_cost = float(FuelTransaction.objects.filter(
            vehicle=vehicle, date__gte=since, date__lt=until
        ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
        prev_fuel = float(FuelTransaction.objects.filter(
            vehicle=vehicle, date__gte=prev_start, date__lt=since
        ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))

        charging_cost = float(ChargingSession.objects.filter(
            vehicle=vehicle, start_time__gte=since, start_time__lt=until
        ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))

        idling_cost = 0.0
        for ev in IdlingEvent.objects.filter(vehicle=vehicle, start_time__gte=since, start_time__lt=until):
            idling_cost += float(ev.cost or 0)

        cgs = fuel_cost + charging_cost + idling_cost

        # ── OPERATING COSTS (OPEX) ──
        service_cost = float(Service.objects.filter(
            vehicle=vehicle, performed_at__gte=since, performed_at__lt=until
        ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        prev_service = float(Service.objects.filter(
            vehicle=vehicle, performed_at__gte=prev_start, performed_at__lt=since
        ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))

        accident_cost = float(AccidentReport.objects.filter(
            vehicle=vehicle, date__gte=since, date__lt=until
        ).aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))

        damage_cost = float(VehicleDamage.objects.filter(
            agreement__vehicle=vehicle, recorded_at__gte=since, recorded_at__lt=until
        ).aggregate(t=Sum('repair_cost'))['t'] or Decimal('0'))

        opex = service_cost + accident_cost + damage_cost
        variable_total = cgs + opex

        # ── FIXED COSTS ──
        months = max((until - since).days / 30, 1)
        lease_cost = float(vehicle.lease_monthly_rate or 0) * months if vehicle.ownership == 'lease' else 0.0
        insurance_cost = float(vehicle.insurance_premium or 0) * months / 12.0
        financing_cost = float(vehicle.monthly_payment or 0) * months
        depreciation_cost = float(vehicle.annual_depreciation or 0) / 12.0 * months
        fixed_total = lease_cost + insurance_cost + financing_cost + depreciation_cost

        total_costs = variable_total + fixed_total

        # ── P&L ──
        gross_profit = rental_revenue - variable_total
        operating_profit = gross_profit - fixed_total
        net_profit = rental_revenue - total_costs
        gross_margin = round((gross_profit / rental_revenue * 100), 1) if rental_revenue else 0
        operating_margin = round((operating_profit / rental_revenue * 100), 1) if rental_revenue else 0
        net_margin = round((net_profit / rental_revenue * 100), 1) if rental_revenue else 0

        # Trends
        prev_variable = prev_fuel + prev_service
        prev_total_costs = prev_variable
        revenue_change = round(((rental_revenue - prev_rental_revenue) / prev_rental_revenue * 100), 1) \
            if prev_rental_revenue else 0
        cost_change = round(((total_costs - prev_total_costs) / prev_total_costs * 100), 1) \
            if prev_total_costs else 0
        cash_change = round(((cash_collected - prev_cash) / prev_cash * 100), 1) if prev_cash else 0
        profit_change = round(((net_profit - (prev_rental_revenue - prev_total_costs)) /
                               abs(prev_rental_revenue - prev_total_costs) * 100), 1) \
            if (prev_rental_revenue - prev_total_costs) != 0 else 0

        # ── Statement ──
        statement = [
            {'section': 'header', 'label': 'Revenue', 'amount': round(rental_revenue, 2), 'type': 'revenue'},
            {'section': 'revenue', 'label': 'Base Rental Income', 'amount': round(base_rental_revenue, 2), 'type': 'revenue'},
        ]
        for label, amt in add_on_lines.items():
            statement.append({'section': 'revenue', 'label': label, 'amount': round(amt, 2), 'type': 'revenue'})
        for label, amt in charge_by_type.items():
            statement.append({'section': 'revenue', 'label': f'Charge — {label}', 'amount': round(amt, 2), 'type': 'revenue'})
        statement.append({'section': 'subtotal', 'label': 'Total Revenue', 'amount': round(rental_revenue, 2), 'type': 'revenue'})

        statement.append({'section': 'header', 'label': 'Cost of Goods Sold (COGS)', 'amount': round(cgs, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Fuel', 'amount': round(fuel_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'EV Charging', 'amount': round(charging_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Idling Waste', 'amount': round(idling_cost, 2), 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total COGS', 'amount': round(cgs, 2), 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Gross Profit', 'amount': round(gross_profit, 2), 'type': 'profit'})

        statement.append({'section': 'header', 'label': 'Operating Expenses', 'amount': round(opex, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Maintenance and Service', 'amount': round(service_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Accident Damage', 'amount': round(accident_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Rental Vehicle Damage', 'amount': round(damage_cost, 2), 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total Operating Expenses', 'amount': round(opex, 2), 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Operating Profit', 'amount': round(operating_profit, 2), 'type': 'profit'})

        statement.append({'section': 'header', 'label': 'Fixed Costs', 'amount': round(fixed_total, 2), 'type': 'cost'})
        if vehicle.ownership == 'lease':
            statement.append({'section': 'cost', 'label': 'Vehicle Lease Payments', 'amount': round(lease_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Insurance Premiums', 'amount': round(insurance_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Financing', 'amount': round(financing_cost, 2), 'type': 'cost'})
        statement.append({'section': 'cost', 'label': 'Depreciation', 'amount': round(depreciation_cost, 2), 'type': 'cost'})
        statement.append({'section': 'subtotal', 'label': 'Total Fixed Costs', 'amount': round(fixed_total, 2), 'type': 'cost'})
        statement.append({'section': 'result', 'label': 'Net Profit / Loss', 'amount': round(net_profit, 2), 'type': 'profit'})

        # ── Monthly trend ──
        monthly = []
        cursor = d_start.replace(day=1)
        m_end_limit = (d_end.replace(day=1) + _dt.timedelta(days=32)).replace(day=1)
        while cursor <= m_end_limit:
            m_start = cursor
            m_next = cursor.replace(year=cursor.year + 1, month=1, day=1) \
                if cursor.month == 12 \
                else cursor.replace(month=cursor.month + 1, day=1)
            ms = _dt.datetime.combine(m_start, _dt.time.min)
            me = _dt.datetime.combine(m_next, _dt.time.min)
            m_rev = float(RentalAgreement.objects.filter(vehicle=vehicle).exclude(status='draft').filter(
                created_at__gte=ms, created_at__lt=me
            ).aggregate(t=Sum('total_amount'))['t'] or Decimal('0'))
            m_fuel = float(FuelTransaction.objects.filter(
                vehicle=vehicle, date__gte=ms, date__lt=me
            ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            m_svc = float(Service.objects.filter(
                vehicle=vehicle, performed_at__gte=ms, performed_at__lt=me
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_lease = float(vehicle.lease_monthly_rate or 0) if vehicle.ownership == 'lease' else 0.0
            m_ins = float(vehicle.insurance_premium or 0) / 12.0
            m_fin = float(vehicle.monthly_payment or 0)
            m_dep = float(vehicle.annual_depreciation or 0) / 12.0
            m_fixed = m_lease + m_ins + m_fin + m_dep
            m_cost = m_fuel + m_svc + m_fixed
            monthly.append({
                'month': m_start.strftime('%b %Y'),
                'month_key': m_start.strftime('%Y-%m'),
                'revenue': round(m_rev, 2),
                'costs': round(m_cost, 2),
                'profit': round(m_rev - m_cost, 2),
            })
            cursor = m_next

        keep = [m for m in monthly if
                _dt.date.fromisoformat(m['month_key'] + '-01') >= d_start.replace(day=1) and
                _dt.date.fromisoformat(m['month_key'] + '-01') <= d_end.replace(day=1)]
        monthly = keep or monthly

        # Cost breakdown for pie
        cost_breakdown = [
            {'name': 'Fuel', 'value': round(fuel_cost, 2)},
            {'name': 'EV Charging', 'value': round(charging_cost, 2)},
            {'name': 'Service/Maintenance', 'value': round(service_cost, 2)},
        ]
        if vehicle.ownership == 'lease':
            cost_breakdown.append({'name': 'Lease Payments', 'value': round(lease_cost, 2)})
        cost_breakdown.extend([
            {'name': 'Insurance', 'value': round(insurance_cost, 2)},
            {'name': 'Financing', 'value': round(financing_cost, 2)},
            {'name': 'Depreciation', 'value': round(depreciation_cost, 2)},
            {'name': 'Accidents/Damage', 'value': round(accident_cost + damage_cost, 2)},
            {'name': 'Idling Waste', 'value': round(idling_cost, 2)},
        ])

        # Vehicle financial profile
        is_lease = vehicle.ownership == 'lease'
        financial_profile = {
            'ownership': vehicle.ownership,
            'purchase_price': float(vehicle.purchase_price or 0),
            'purchase_date': vehicle.purchase_date.isoformat() if vehicle.purchase_date else None,
            'annual_depreciation': float(vehicle.annual_depreciation or 0) if not is_lease else 0,
            'current_book_value': float(vehicle.current_book_value or 0) if not is_lease else 0,
            'salvage_value': float(vehicle.salvage_value or 0) if not is_lease else 0,
            'useful_life_years': vehicle.useful_life_years,
            'lease_monthly_rate': float(vehicle.lease_monthly_rate or 0) if is_lease else 0,
            'lease_start_date': vehicle.lease_start_date.isoformat() if vehicle.lease_start_date else None,
            'lease_end_date': vehicle.lease_end_date.isoformat() if vehicle.lease_end_date else None,
            'deposit': float(vehicle.deposit or 0) if is_lease else 0,
            'insurance_premium': float(vehicle.insurance_premium or 0),
            'insurance_type': vehicle.insurance_type,
            'insurance_start_date': vehicle.insurance_start_date.isoformat() if vehicle.insurance_start_date else None,
            'insurance_end_date': vehicle.insurance_end_date.isoformat() if vehicle.insurance_end_date else None,
            'monthly_payment': float(vehicle.monthly_payment or 0),
        }

        return Response({
            'period': {'start': d_start.isoformat(), 'end': d_end.isoformat()},
            'vehicle': {
                'id': vehicle.id,
                'display_name': vehicle.display_name,
                'vin': vehicle.vin,
                'license_plate': vehicle.license_plate,
                'status': vehicle.status,
                'ownership': vehicle.ownership,
            },
            'financial_profile': financial_profile,
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
                'cogs': round(cgs, 2),
                'opex': round(opex, 2),
                'fixed_costs': round(fixed_total, 2),
                'variable_costs': round(variable_total, 2),
            },
            'trends': {
                'revenue_change_pct': revenue_change,
                'cost_change_pct': cost_change,
                'cash_change_pct': cash_change,
                'profit_change_pct': profit_change,
                'prev_revenue': round(prev_rental_revenue, 2),
                'prev_costs': round(prev_total_costs, 2),
                'prev_cash': round(prev_cash, 2),
            },
            'statement': statement,
            'monthly_series': monthly,
            'cost_breakdown': [c for c in cost_breakdown if c['value'] > 0],
        })

    @action(detail=True, methods=['get'])
    def cost_of_ownership(self, request, pk=None):
        """Comprehensive Total Cost of Ownership (TCO) for a single vehicle.

        Covers acquisition, depreciation, financing, insurance, fuel/charging,
        maintenance, accidents, lease, and downtime.  Returns KPIs, a cost
        breakdown pie, a monthly trend chart, cost-per-km, and a full ledger.
        Supports ?start_date= and ?end_date= query params.
        """
        import datetime as _dt
        from decimal import Decimal
        from django.db.models import Sum, Count, Avg, Q
        from django.utils import timezone
        from apps.rentals.models import RentalAgreement
        from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent
        from apps.services.models import Service
        from apps.accidents.models import AccidentReport

        vehicle = self.get_object()
        is_lease = vehicle.ownership == 'lease'

        start_str = request.query_params.get('start_date')
        end_str = request.query_params.get('end_date')
        now = timezone.now()
        now_date = now.date()

        from django.utils.timezone import make_aware
        _tz = timezone.get_current_timezone()

        if start_str and end_str:
            try:
                d_start = _dt.date.fromisoformat(start_str)
                d_end = _dt.date.fromisoformat(end_str)
            except ValueError:
                d_start = now_date.replace(day=1) - _dt.timedelta(days=365)
                d_end = now_date
        else:
            d_start = now_date.replace(day=1) - _dt.timedelta(days=365)
            d_end = now_date

        since = make_aware(_dt.datetime.combine(d_start, _dt.time.min), _tz)
        until = make_aware(_dt.datetime.combine(d_end + _dt.timedelta(days=1), _dt.time.min), _tz)
        months = max((until - since).days / 30, 1)

        # ── Acquisition / Capital cost (amortized over the period) ──
        purchase_price = float(vehicle.purchase_price or 0)
        salvage_value = float(vehicle.salvage_value or 0)
        useful_life = vehicle.useful_life_years or 0
        annual_dep = float(vehicle.annual_depreciation or 0)
        if not is_lease and not annual_dep and useful_life and purchase_price:
            annual_dep = (purchase_price - salvage_value) / useful_life
        depreciation_cost = annual_dep / 12.0 * months if not is_lease else 0.0

        # ── Financing ──
        monthly_payment = float(vehicle.monthly_payment or 0)
        financing_cost = monthly_payment * months

        # ── Lease ──
        lease_monthly = float(vehicle.lease_monthly_rate or 0) if is_lease else 0.0
        lease_cost = lease_monthly * months
        deposit = float(vehicle.deposit or 0) if is_lease else 0.0

        # ── Insurance ──
        insurance_premium = float(vehicle.insurance_premium or 0)
        insurance_cost = insurance_premium * months / 12.0

        # ── Fuel ──
        fuel = FuelTransaction.objects.filter(
            vehicle=vehicle, date__gte=since, date__lt=until
        )
        fuel_cost = float(fuel.aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
        fuel_volume = float(fuel.aggregate(t=Sum('quantity'))['t'] or Decimal('0'))
        fuel_entries = fuel.count()

        # ── EV Charging ──
        charging = ChargingSession.objects.filter(
            vehicle=vehicle, start_time__gte=since, start_time__lt=until
        )
        charging_cost = float(charging.aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        charging_energy = float(charging.aggregate(t=Sum('energy_kwh'))['t'] or Decimal('0'))
        charging_sessions = charging.count()

        # ── Idling ──
        idling_cost = 0.0
        idling_qs = IdlingEvent.objects.filter(vehicle=vehicle, start_time__gte=since, start_time__lt=until)
        for ev in idling_qs:
            idling_cost += float(ev.cost or 0)
        idling_events = idling_qs.count()

        # ── Maintenance / Service ──
        services = Service.objects.filter(
            vehicle=vehicle, performed_at__gte=since, performed_at__lt=until
        )
        service_cost = float(services.aggregate(t=Sum('cost'))['t'] or Decimal('0'))
        service_count = services.count()
        downtime_hours = float(services.aggregate(t=Sum('downtime_hours'))['t'] or Decimal('0'))

        # ── Accidents & Damage ──
        accident_cost = float(AccidentReport.objects.filter(
            vehicle=vehicle, date__gte=since, date__lt=until
        ).aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))
        accident_count = AccidentReport.objects.filter(
            vehicle=vehicle, date__gte=since, date__lt=until
        ).count()

        # ── Totals ──
        capital_cost = depreciation_cost + financing_cost + (lease_cost if is_lease else 0)
        energy_cost = fuel_cost + charging_cost + idling_cost
        operating_cost = service_cost + accident_cost
        insurance_total = insurance_cost
        total_cost = capital_cost + insurance_total + energy_cost + operating_cost

        # ── Cost per km / per day ──
        mileage = float(vehicle.current_mileage or 0)
        # Estimate mileage during the period proportionally
        in_service_date = vehicle.in_service_date
        if in_service_date and mileage:
            total_days = max((now_date - in_service_date).days, 1)
            period_days = max((d_end - d_start).days, 1)
            period_mileage = mileage * (period_days / total_days)
        else:
            period_mileage = 0
        cost_per_km = round(total_cost / period_mileage, 2) if period_mileage else 0
        cost_per_day = round(total_cost / max((d_end - d_start).days, 1), 2)

        # Collected days since in-service
        days_owned = (now_date - (in_service_date or purchase_price and vehicle.purchase_date or now_date)).days if (in_service_date or vehicle.purchase_date) else 0
        days_owned = max(days_owned, 0)

        # Lifetime cost estimate (annualise the period cost)
        lifetime_cost = (total_cost / months) * 12 * (useful_life or 5) if not is_lease else lease_monthly * 12 * 5 + total_cost

        # ── Cost breakdown for pie chart ──
        breakdown = []
        if not is_lease and depreciation_cost:
            breakdown.append({'name': 'Depreciation', 'value': round(depreciation_cost, 2)})
        if is_lease and lease_cost:
            breakdown.append({'name': 'Lease Payments', 'value': round(lease_cost, 2)})
        if financing_cost:
            breakdown.append({'name': 'Financing', 'value': round(financing_cost, 2)})
        if insurance_cost:
            breakdown.append({'name': 'Insurance', 'value': round(insurance_cost, 2)})
        if fuel_cost:
            breakdown.append({'name': 'Fuel', 'value': round(fuel_cost, 2)})
        if charging_cost:
            breakdown.append({'name': 'EV Charging', 'value': round(charging_cost, 2)})
        if idling_cost:
            breakdown.append({'name': 'Idling Waste', 'value': round(idling_cost, 2)})
        if service_cost:
            breakdown.append({'name': 'Maintenance', 'value': round(service_cost, 2)})
        if accident_cost:
            breakdown.append({'name': 'Accidents', 'value': round(accident_cost, 2)})

        # ── Monthly trend ──
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

            m_dep = annual_dep / 12.0 if not is_lease else 0.0
            m_lease = lease_monthly if is_lease else 0.0
            m_fin = monthly_payment
            m_ins = insurance_premium / 12.0
            m_capital = m_dep + m_fin + m_lease

            m_fuel = float(FuelTransaction.objects.filter(
                vehicle=vehicle, date__gte=ms, date__lt=me
            ).aggregate(t=Sum('total_cost'))['t'] or Decimal('0'))
            m_charge = float(ChargingSession.objects.filter(
                vehicle=vehicle, start_time__gte=ms, start_time__lt=me
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_svc = float(Service.objects.filter(
                vehicle=vehicle, performed_at__gte=ms, performed_at__lt=me
            ).aggregate(t=Sum('cost'))['t'] or Decimal('0'))
            m_acc = float(AccidentReport.objects.filter(
                vehicle=vehicle, date__gte=ms, date__lt=me
            ).aggregate(t=Sum('estimated_damage_cost'))['t'] or Decimal('0'))

            m_total = m_capital + m_ins + m_fuel + m_charge + m_svc + m_acc
            monthly.append({
                'month': m_start.strftime('%b %Y'),
                'month_key': m_start.strftime('%Y-%m'),
                'capital': round(m_capital, 2),
                'insurance': round(m_ins, 2),
                'energy': round(m_fuel + m_charge, 2),
                'maintenance': round(m_svc, 2),
                'accidents': round(m_acc, 2),
                'total': round(m_total, 2),
            })
            cursor = m_next

        keep = [m for m in monthly if
                _dt.date.fromisoformat(m['month_key'] + '-01') >= d_start.replace(day=1) and
                _dt.date.fromisoformat(m['month_key'] + '-01') <= d_end.replace(day=1)]
        monthly = keep or monthly

        # ── Ledger ──
        ledger = [
            {'category': 'Capital', 'item': 'Depreciation' if not is_lease else 'Lease Payments',
             'amount': round(depreciation_cost if not is_lease else lease_cost, 2), 'type': 'capital'},
            {'category': 'Capital', 'item': 'Financing', 'amount': round(financing_cost, 2), 'type': 'capital'},
            {'category': 'Capital', 'item': 'Deposit' if is_lease else 'Insurance (Annualised)',
             'amount': round(deposit if is_lease else insurance_cost, 2), 'type': 'capital'},
        ]
        if not is_lease:
            ledger.append({'category': 'Insurance', 'item': 'Premiums', 'amount': round(insurance_cost, 2), 'type': 'insurance'})
        ledger.extend([
            {'category': 'Energy', 'item': 'Fuel', 'amount': round(fuel_cost, 2), 'type': 'energy'},
            {'category': 'Energy', 'item': 'EV Charging', 'amount': round(charging_cost, 2), 'type': 'energy'},
        ])
        if idling_cost:
            ledger.append({'category': 'Energy', 'item': 'Idling Waste', 'amount': round(idling_cost, 2), 'type': 'energy'})
        ledger.extend([
            {'category': 'Maintenance', 'item': 'Service and Repairs', 'amount': round(service_cost, 2), 'type': 'maintenance'},
        ])
        if accident_cost:
            ledger.append({'category': 'Incidents', 'item': 'Accident Damage', 'amount': round(accident_cost, 2), 'type': 'incidents'})

        return Response({
            'period': {'start': d_start.isoformat(), 'end': d_end.isoformat()},
            'vehicle': {
                'id': vehicle.id,
                'display_name': vehicle.display_name,
                'vin': vehicle.vin,
                'license_plate': vehicle.license_plate,
                'status': vehicle.status,
                'ownership': vehicle.ownership,
            },
            'financial_profile': {
                'ownership': vehicle.ownership,
                'purchase_price': purchase_price,
                'purchase_date': vehicle.purchase_date.isoformat() if vehicle.purchase_date else None,
                'annual_depreciation': annual_dep,
                'current_book_value': float(vehicle.current_book_value or 0),
                'salvage_value': salvage_value,
                'useful_life_years': useful_life,
                'lease_monthly_rate': lease_monthly if is_lease else 0,
                'deposit': deposit,
                'insurance_premium': insurance_premium,
                'monthly_payment': monthly_payment,
                'in_service_date': in_service_date.isoformat() if in_service_date else None,
            },
            'summary': {
                'total_cost': round(total_cost, 2),
                'capital_cost': round(capital_cost, 2),
                'energy_cost': round(energy_cost, 2),
                'maintenance_cost': round(service_cost, 2),
                'insurance_cost': round(insurance_total, 2),
                'incident_cost': round(accident_cost, 2),
                'cost_per_km': cost_per_km,
                'cost_per_day': cost_per_day,
                'days_owned': days_owned,
                'lifetime_cost_estimate': round(lifetime_cost, 2),
                'period_months': round(months, 1),
            },
            'cost_breakdown': breakdown,
            'monthly_series': monthly,
            'ledger': ledger,
            'usage_stats': {
                'fuel_volume': round(fuel_volume, 2),
                'fuel_entries': fuel_entries,
                'charging_energy': round(charging_energy, 2),
                'charging_sessions': charging_sessions,
                'idling_events': idling_events,
                'service_count': service_count,
                'downtime_hours': round(downtime_hours, 1),
                'accident_count': accident_count,
                'mileage': round(mileage, 0),
                'period_mileage': round(period_mileage, 0),
            },
        })

    # ──────────────────────────────────────────────────────────────────────
    # Vehicle Monitor — real-time fleet activity overview
    # ──────────────────────────────────────────────────────────────────────
    @action(detail=False, methods=['get'])
    def vehicle_monitor(self, request):
        """Real-time vehicle monitor dashboard.

        Returns per-vehicle activity status (on_rent / available / in_maintenance /
        out_of_service), latest telematics position & speed, last reported
        mileage, fuel used so far, EV battery state-of-charge, idle hours,
        odometer delta since last service, and active alerts.

        Query params:
          ?search=          — search vin / plate / make / model
          ?status=          — filter by vehicle.status
          ?rental_status=   — on_rent | available
          ?group=           — filter by fleet group id
          ?vehicle_type=    — filter by vehicle_type
          ?stale_only=true  — only vehicles with stale telematics
        """
        from django.db.models import (
            Avg, Count, FloatField, IntegerField, Max, Q, Sum,
        )
        from django.db.models.functions import Coalesce
        from django.utils import timezone as _tz
        from apps.rentals.models import RentalAgreement
        from apps.fuel.models import FuelTransaction, ChargingSession
        from apps.telematics.models import TelematicsDevice, TelematicsAlert
        from apps.services.models import Service
        from apps.issues.models import Issue
        from apps.batteries.models import Battery

        qs = self.get_queryset()

        # ── Filtering ──
        search = request.query_params.get('search')
        if search:
            qs = qs.filter(
                Q(vin__icontains=search)
                | Q(license_plate__icontains=search)
                | Q(make__icontains=search)
                | Q(model__icontains=search)
            )
        status = request.query_params.get('status')
        if status:
            qs = qs.filter(status=status)
        group = request.query_params.get('group')
        if group:
            qs = qs.filter(group_id=group)
        vehicle_type = request.query_params.get('vehicle_type')
        if vehicle_type:
            qs = qs.filter(vehicle_type=vehicle_type)
        rental_status = request.query_params.get('rental_status')
        stale_only = request.query_params.get('stale_only')
        now = _tz.now()
        # Keep retired vehicles out of the monitor by default
        if not status:
            qs = qs.exclude(status='retired')

        # ── Active rentals map: vehicle_id -> {agreement_no, customer, ... } ──
        active_rentals = {}
        for ra in RentalAgreement.objects.filter(
            status__in=['active', 'overdue']
        ).select_related('customer', 'vehicle'):
            active_rentals[ra.vehicle_id] = {
                'agreement_no': ra.agreement_no,
                'customer_name': ra.customer.full_name if ra.customer else '',
                'customer_type': ra.customer.customer_type if ra.customer else '',
                'start_datetime': ra.start_datetime.isoformat() if ra.start_datetime else None,
                'end_datetime': ra.end_datetime.isoformat() if ra.end_datetime else None,
                'start_mileage': ra.start_mileage,
                'daily_rate': float(ra.daily_rate or 0),
                'pickup_location': ra.pickup_location,
                'dropoff_location': ra.dropoff_location,
                'rate_period': ra.rate_period,
            }

        # ── Latest telematics device per vehicle (one row per vehicle) ──
        device_map = {}
        for d in TelematicsDevice.objects.filter(
            vehicle__in=qs
        ).order_by('-last_reported_at'):
            if d.vehicle_id not in device_map:
                device_map[d.vehicle_id] = d

        # ── Fuel totals per vehicle (all-time) ──
        fuel_map = {}
        for row in FuelTransaction.objects.filter(
            vehicle__in=qs
        ).values('vehicle_id').annotate(
            total_qty=Coalesce(Sum('quantity'), 0, output_field=FloatField()),
            total_cost=Coalesce(Sum('total_cost'), 0, output_field=IntegerField()),
            last_fill=Max('date'),
        ):
            fuel_map[row['vehicle_id']] = row

        # ── Charging totals per vehicle (EV) ──
        charge_map = {}
        for row in ChargingSession.objects.filter(
            vehicle__in=qs
        ).values('vehicle_id').annotate(
            total_kwh=Coalesce(Sum('energy_kwh'), 0, output_field=FloatField()),
            total_cost=Coalesce(Sum('cost'), 0, output_field=IntegerField()),
            last_session=Max('start_time'),
        ):
            charge_map[row['vehicle_id']] = row

        # ── Open issues per vehicle ──
        issue_map = {}
        for row in Issue.objects.filter(
            vehicle__in=qs, status__in=['open', 'in_progress']
        ).values('vehicle_id').annotate(
            count=Count('id'),
        ):
            issue_map[row['vehicle_id']] = row['count']

        # ── Last service + total service cost per vehicle ──
        service_map = {}
        for row in Service.objects.filter(
            vehicle__in=qs
        ).values('vehicle_id').annotate(
            count=Count('id'),
            total_cost=Coalesce(Sum('cost'), 0, output_field=IntegerField()),
            last_service=Max('performed_at'),
        ):
            service_map[row['vehicle_id']] = row

        # ── Unacknowledged telematics alerts per vehicle ──
        alert_map = {}
        for row in TelematicsAlert.objects.filter(
            vehicle__in=qs, acknowledged=False
        ).values('vehicle_id').annotate(
            count=Count('id'),
        ):
            alert_map[row['vehicle_id']] = row['count']

        # ── Installed batteries per vehicle ──
        battery_list_map = {}
        battery_summary_map = {}
        for row in Battery.objects.filter(
            vehicle__in=qs, status=Battery.Status.INSTALLED
        ).order_by('position', 'id'):
            vlist = battery_list_map.setdefault(row.vehicle_id, [])
            vlist.append({
                'id': row.id,
                'serial_number': row.serial_number,
                'brand': row.brand,
                'model': row.model,
                'chemistry': row.chemistry,
                'voltage': row.voltage,
                'capacity_ah': row.capacity_ah,
                'condition': row.condition,
                'position': row.position,
                'install_date': row.install_date.isoformat() if row.install_date else None,
                'warranty_expiry': row.warranty_expiry.isoformat() if row.warranty_expiry else None,
                'warranty_days_left': row.warranty_days_left,
                'last_tested': row.last_tested.isoformat() if row.last_tested else None,
            })
        for vid, batteries in battery_list_map.items():
            battery_summary_map[vid] = {
                'count': len(batteries),
                'brands': ', '.join(sorted({b['brand'] for b in batteries if b['brand']})),
                'avg_voltage': round(sum(b['voltage'] or 0 for b in batteries) / max(len(batteries), 1), 1),
                'total_capacity_ah': round(sum((b['capacity_ah'] or 0) for b in batteries), 1),
                'warranty_expired': sum(1 for b in batteries if not b['warranty_days_left']),
            }

        # ── Build per-vehicle monitor rows ──
        vehicles = []
        total_in_db = qs.count()
        on_rent_count = 0
        available_count = 0
        moving_count = 0
        stale_count = 0
        offline_count = 0
        for v in qs.select_related('group', 'assigned_driver'):
            rental = active_rentals.get(v.id)
            if rental:
                vstatus = 'on_rent'
                on_rent_count += 1
            elif v.status == 'in_maintenance':
                vstatus = 'in_maintenance'
            elif v.status == 'out_of_service':
                vstatus = 'out_of_service'
            else:
                vstatus = 'available'
                available_count += 1

            # Telematics snapshot
            dev = device_map.get(v.id)
            tlat = None
            if dev:
                is_stale = dev.is_stale
                if is_stale:
                    stale_count += 1
                if dev.status == 'offline':
                    offline_count += 1
                if (dev.last_speed or 0) > 0 and not is_stale:
                    moving_count += 1
                tlat = {
                    'device_id': dev.id,
                    'provider': dev.provider,
                    'serial_number': dev.serial_number,
                    'latitude': dev.last_latitude,
                    'longitude': dev.last_longitude,
                    'heading': dev.last_heading,
                    'speed': dev.last_speed,
                    'ignition_on': dev.last_ignition_on,
                    'last_reported_at': dev.last_reported_at.isoformat() if dev.last_reported_at else None,
                    'is_stale': is_stale,
                    'device_status': dev.status,
                }
            else:
                stale_count += 1

            # Apply stale_only filter after computation
            if stale_only and not (tlat and tlat.get('is_stale')):
                continue

            # Apply rental_status filter after computation
            if rental_status and vstatus != rental_status:
                continue

            # Mileage delta since last service
            last_svc = service_map.get(v.id, {})
            last_svc_mileage = None
            mileage_since_service = None
            if last_svc.get('last_service'):
                # Estimate using the most recent service's performed_at
                last_svc_obj = Service.objects.filter(
                    vehicle=v
                ).order_by('-performed_at').first()
                if last_svc_obj and last_svc_obj.odometer_reading:
                    last_svc_mileage = last_svc_obj.odometer_reading
                    mileage_since_service = max(0, (v.current_mileage or 0) - last_svc_mileage)

            # Rental mileage
            rental_mileage = None
            if rental and rental.get('start_mileage') is not None:
                rental_mileage = max(0, (v.current_mileage or 0) - float(rental['start_mileage']))

            vehicles.append({
                'id': v.id,
                'display_name': v.display_name,
                'vin': v.vin,
                'license_plate': v.license_plate,
                'make': v.make,
                'model': v.model,
                'year': v.year,
                'color': v.color,
                'fuel_type': v.fuel_type,
                'vehicle_type': v.vehicle_type,
                'group_name': v.group.name if v.group else '',
                'assigned_driver_name': (
                    f'{v.assigned_driver.first_name} {v.assigned_driver.last_name}'
                    if v.assigned_driver else None
                ),
                'status': v.status,
                'monitor_status': vstatus,
                'rental': rental,
                'rental_mileage': round(rental_mileage, 1) if rental_mileage is not None else None,
                # Telematics
                'telematics': tlat,
                # Mileage & engine
                'current_mileage': v.current_mileage or 0,
                'mileage_unit': v.mileage_unit,
                'engine_hours': round(v.engine_hours or 0, 1),
                'mileage_since_last_service': mileage_since_service,
                'last_service_mileage': last_svc_mileage,
                # Fuel
                'total_fuel_used': round(fuel_map.get(v.id, {}).get('total_qty', 0), 2),
                'total_fuel_cost': float(fuel_map.get(v.id, {}).get('total_cost', 0)),
                'last_fuel_date': (
                    fuel_map.get(v.id, {}).get('last_fill').isoformat()
                    if fuel_map.get(v.id, {}).get('last_fill') else None
                ),
                # EV
                'state_of_charge': v.state_of_charge,
                'state_of_health': v.state_of_health,
                # Batteries (installed physical units)
                'batteries': battery_list_map.get(v.id, []),
                'battery_summary': battery_summary_map.get(v.id, None),
                'total_charging_kwh': round(charge_map.get(v.id, {}).get('total_kwh', 0), 2),
                'total_charging_cost': float(charge_map.get(v.id, {}).get('total_cost', 0)),
                'last_charging_date': (
                    charge_map.get(v.id, {}).get('last_session').isoformat()
                    if charge_map.get(v.id, {}).get('last_session') else None
                ),
                # Maintenance & issues
                'service_count': service_map.get(v.id, {}).get('count', 0),
                'total_service_cost': float(service_map.get(v.id, {}).get('total_cost', 0)),
                'last_service_at': (
                    service_map.get(v.id, {}).get('last_service').isoformat()
                    if service_map.get(v.id, {}).get('last_service') else None
                ),
                'open_issues': issue_map.get(v.id, 0),
                'open_alerts': alert_map.get(v.id, 0),
                # Location
                'location': v.location,
                'image': v.image.url if v.image else None,
            })

        # ── Fleet summary KPIs ──
        total_fuel = sum(v['total_fuel_used'] for v in vehicles)
        total_fuel_cost = sum(v['total_fuel_cost'] for v in vehicles)
        total_charging_kwh = sum(v['total_charging_kwh'] for v in vehicles)
        total_mileage = sum(v['current_mileage'] for v in vehicles)
        total_engine_hours = sum(v['engine_hours'] for v in vehicles)
        alert_total = sum(v['open_alerts'] for v in vehicles)
        issue_total = sum(v['open_issues'] for v in vehicles)
        service_total = sum(v['service_count'] for v in vehicles)
        active_rental_count = sum(1 for v in vehicles if v['monitor_status'] == 'on_rent')

        # ── Status distribution for donut chart ──
        status_dist = [
            {'label': 'On Rent', 'value': on_rent_count, 'color': '#6366f1'},
            {'label': 'Available', 'value': available_count, 'color': '#10b981'},
            {'label': 'In Maintenance', 'value': sum(1 for v in vehicles if v['monitor_status'] == 'in_maintenance'), 'color': '#f59e0b'},
            {'label': 'Out of Service', 'value': sum(1 for v in vehicles if v['monitor_status'] == 'out_of_service'), 'color': '#ef4444'},
        ]

        return Response({
            'summary': {
                'total_vehicles': total_in_db,
                'on_rent': on_rent_count,
                'available': available_count,
                'moving': moving_count,
                'stale': stale_count,
                'offline': offline_count,
                'active_rentals': active_rental_count,
                'open_alerts': alert_total,
                'open_issues': issue_total,
                'total_services': service_total,
                'total_fuel_used': round(total_fuel, 2),
                'total_fuel_cost': round(total_fuel_cost, 2),
                'total_charging_kwh': round(total_charging_kwh, 2),
                'total_mileage': total_mileage,
                'total_engine_hours': round(total_engine_hours, 1),
            },
            'status_distribution': status_dist,
            'vehicles': vehicles,
        })


class VinDecodeView(APIView):
    @extend_schema(request=VinDecodeSerializer, responses=dict)
    def post(self, request):
        serializer = VinDecodeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        decoded = serializer.save()
        return Response(decoded, status=status.HTTP_200_OK)


class CustomFieldViewSet(viewsets.ModelViewSet):
    queryset = CustomField.objects.all()
    serializer_class = CustomFieldSerializer
    filterset_fields = ['field_type', 'is_active']
    search_fields = ['name', 'label']
    ordering_fields = ['name', 'created_at']


class CustomFieldValueViewSet(viewsets.ModelViewSet):
    queryset = CustomFieldValue.objects.select_related('vehicle', 'field')
    serializer_class = CustomFieldValueSerializer
    filterset_fields = ['vehicle', 'field']
    ordering_fields = ['created_at']


class CatalogSeedView(APIView):
    """Seed the tenant vehicle catalog (makes, body types, models) from a payload.

    Idempotent: existing records are reused via get_or_create.
    Expected payload:
        {
            "makes": ["Toyota", "Ford", ...],
            "body_types": [{"label": "Sedan", "value": "sedan", "icon": "mdi-car-side"}, ...],
            "models": [{"make": "Toyota", "body_type_value": "sedan", "name": "Camry"}, ...]
        }
    """

    def post(self, request):
        makes = request.data.get('makes', []) or []
        body_types = request.data.get('body_types', []) or []
        models = request.data.get('models', []) or []

        bt_map = {}
        for bt in body_types:
            value = bt.get('value')
            if not value:
                continue
            obj, _ = VehicleBodyType.objects.get_or_create(
                value=value,
                defaults={
                    'label': bt.get('label', value),
                    'icon': bt.get('icon', 'mdi-car'),
                },
            )
            bt_map[value] = obj

        mk_map = {}
        for name in makes:
            if not name:
                continue
            obj, _ = VehicleMake.objects.get_or_create(name=name)
            mk_map[name] = obj

        created_models = 0
        for m in models:
            make = mk_map.get(m.get('make'))
            bt = bt_map.get(m.get('body_type_value'))
            model_name = m.get('name')
            if not make or not bt or not model_name:
                continue
            _, created = VehicleModel.objects.get_or_create(
                make=make, body_type=bt, name=model_name,
            )
            if created:
                created_models += 1

        return Response({
            'makes': VehicleMake.objects.count(),
            'body_types': VehicleBodyType.objects.count(),
            'models': VehicleModel.objects.count(),
            'models_created': created_models,
        })
