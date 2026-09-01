import random
from collections import defaultdict
from datetime import timedelta
from decimal import Decimal

from django.db.models import Count, Q, Sum
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import FuelPurchase, IftaQuarter, Jurisdiction, TripLog
from .serializers import (
    FuelPurchaseSerializer,
    IftaQuarterSerializer,
    JurisdictionSerializer,
    TripLogSerializer,
)


class JurisdictionViewSet(viewsets.ModelViewSet):
    queryset = Jurisdiction.objects.all()
    serializer_class = JurisdictionSerializer
    search_fields = ['code', 'name']
    ordering_fields = ['name', 'code']
    filterset_fields = ['country', 'is_ifta']


class TripLogViewSet(viewsets.ModelViewSet):
    queryset = TripLog.objects.select_related('vehicle', 'driver', 'jurisdiction')
    serializer_class = TripLogSerializer
    filterset_fields = ['vehicle', 'jurisdiction', 'date', 'source', 'trip_type']
    ordering_fields = ['date', 'distance', 'created_at']
    search_fields = ['route']


class FuelPurchaseViewSet(viewsets.ModelViewSet):
    queryset = FuelPurchase.objects.select_related('vehicle', 'jurisdiction', 'fuel_transaction')
    serializer_class = FuelPurchaseSerializer
    filterset_fields = ['vehicle', 'jurisdiction', 'date', 'source']
    ordering_fields = ['date', 'gallons', 'total_cost']


class IftaQuarterViewSet(viewsets.ModelViewSet):
    queryset = IftaQuarter.objects.select_related('vehicle')
    serializer_class = IftaQuarterSerializer
    filterset_fields = ['vehicle', 'year', 'quarter', 'status']
    ordering_fields = ['year', 'quarter']

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate IFTA statistics for analytics cards."""
        trips_qs = TripLog.objects.all()
        fuel_qs = FuelPurchase.objects.all()
        quarters_qs = IftaQuarter.objects.all()
        total_trips = trips_qs.count()
        total_fuel_purchases = fuel_qs.count()
        total_miles = sum(t.distance_miles for t in trips_qs)
        total_gallons = sum(p.gallons for p in fuel_qs)
        total_fuel_cost = sum(float(p.total_cost) for p in fuel_qs)
        total_tax_paid = sum(float(p.tax_paid) for p in fuel_qs)
        total_net_tax = sum(float(q.net_tax) for q in quarters_qs)
        jur_count = Jurisdiction.objects.count()
        by_status = {}
        for choice in IftaQuarter.Status.choices:
            by_status[choice[0]] = quarters_qs.filter(status=choice[0]).count()
        by_quarter = {}
        for q in quarters_qs:
            key = f'{q.year} {q.quarter}'
            by_quarter[key] = float(q.net_tax)
        by_vehicle = {}
        for v_id in set(trips_qs.values_list('vehicle_id', flat=True)):
            tr = trips_qs.filter(vehicle_id=v_id).first()
            if tr:
                vid = v_id
                if vid not in by_vehicle:
                    by_vehicle[vid] = {'vehicle_name': tr.vehicle.display_name, 'trips': 0, 'miles': 0, 'gallons': 0}
                by_vehicle[vid]['trips'] = trips_qs.filter(vehicle_id=vid).count()
                by_vehicle[vid]['miles'] = sum(t.distance_miles for t in trips_qs.filter(vehicle_id=vid))
        for p in fuel_qs:
            vid = p.vehicle_id
            if vid not in by_vehicle:
                by_vehicle[vid] = {'vehicle_name': p.vehicle.display_name, 'trips': 0, 'miles': 0, 'gallons': 0}
            by_vehicle[vid]['gallons'] += p.gallons
        avg_mpg = round(total_miles / total_gallons, 2) if total_gallons else 0
        return Response({
            'total_trips': total_trips,
            'total_fuel_purchases': total_fuel_purchases,
            'total_miles': round(total_miles, 2),
            'total_gallons': round(total_gallons, 2),
            'total_fuel_cost': round(total_fuel_cost, 2),
            'total_tax_paid': round(total_tax_paid, 2),
            'total_net_tax': round(total_net_tax, 2),
            'avg_mpg': avg_mpg,
            'jurisdiction_count': jur_count,
            'quarter_count': quarters_qs.count(),
            'by_status': by_status,
            'by_quarter': by_quarter,
            'by_vehicle': list(by_vehicle.values())[:20],
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo trip logs, fuel purchases, and quarterly reports."""
        from apps.vehicles.models import Vehicle

        vehicles = list(Vehicle.objects.all()[:10])
        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        # Create jurisdictions if none exist
        if not Jurisdiction.objects.exists():
            jur_templates = [
                ('CA', 'California', 'USA', 0.5460),
                ('TX', 'Texas', 'USA', 0.2000),
                ('AZ', 'Arizona', 'USA', 0.1800),
                ('NV', 'Nevada', 'USA', 0.2700),
                ('OR', 'Oregon', 'USA', 0.0000),
                ('WA', 'Washington', 'USA', 0.4490),
                ('UT', 'Utah', 'USA', 0.2990),
                ('NM', 'New Mexico', 'USA', 0.1700),
                ('CO', 'Colorado', 'USA', 0.2200),
                ('ID', 'Idaho', 'USA', 0.2500),
                ('WY', 'Wyoming', 'USA', 0.2400),
                ('MT', 'Montana', 'USA', 0.2775),
                ('ON', 'Ontario', 'Canada', 0.1200),
                ('BC', 'British Columbia', 'Canada', 0.0900),
            ]
            for code, name, country, rate in jur_templates:
                Jurisdiction.objects.create(code=code, name=name, country=country, fuel_tax_rate=rate)

        jurisdictions = list(Jurisdiction.objects.all())
        now = timezone.now()
        routes = [
            'Los Angeles, CA → Phoenix, AZ', 'Dallas, TX → Albuquerque, NM',
            'Portland, OR → Seattle, WA', 'Salt Lake City, UT → Denver, CO',
            'Las Vegas, NV → Los Angeles, CA', 'Houston, TX → New Orleans, LA',
            'Chicago, IL → Indianapolis, IN', 'Denver, CO → Cheyenne, WY',
            'Toronto, ON → Detroit, MI', 'Sacramento, CA → Reno, NV',
        ]
        trip_types = ['loaded', 'empty', 'bobtail']
        created_trips = 0
        created_fuel = 0

        for v in vehicles:
            # Create trip logs for each vehicle (30-60 days spread)
            num_trips = random.randint(8, 20)
            for _ in range(num_trips):
                jur = random.choice(jurisdictions)
                days_ago = random.randint(0, 180)
                date = (now - timedelta(days=days_ago)).date()
                dist = random.uniform(50, 600)
                TripLog.objects.create(
                    vehicle=v, jurisdiction=jur, date=date,
                    start_odometer=random.randint(50000, 150000),
                    end_odometer=random.randint(50000, 150000),
                    distance=round(dist, 1), distance_unit='miles',
                    trip_type=random.choice(trip_types),
                    route=random.choice(routes),
                    source=random.choice(['manual', 'telematics']),
                )
                created_trips += 1

            # Create fuel purchases (5-15 per vehicle)
            num_fuel = random.randint(5, 15)
            for _ in range(num_fuel):
                jur = random.choice(jurisdictions)
                days_ago = random.randint(0, 180)
                date = (now - timedelta(days=days_ago)).date()
                gallons = random.uniform(50, 150)
                cost = round(gallons * random.uniform(3.5, 4.8), 2)
                tax = round(gallons * float(jur.fuel_tax_rate), 2)
                FuelPurchase.objects.create(
                    vehicle=v, jurisdiction=jur, date=date,
                    gallons=round(gallons, 2), total_cost=cost, tax_paid=tax,
                    vendor=random.choice(['Pilot Flying J', 'Love\'s Travel Stops', 'TA Petro', 'Speedway', 'Maverik']),
                    source=random.choice(['manual', 'fuel_card']),
                )
                created_fuel += 1

        # Generate quarterly reports for each vehicle
        year = now.year
        quarter = f'Q{((now.month - 1) // 3) + 1}'
        created_reports = 0
        for v in vehicles:
            for q in ['Q1', 'Q2', 'Q3', 'Q4']:
                q_year = year
                if q == 'Q1' and now.month < 4:
                    q_year = year - 1
                quarter_ranges = {
                    'Q1': (f'{q_year}-01-01', f'{q_year}-03-31'),
                    'Q2': (f'{q_year}-04-01', f'{q_year}-06-30'),
                    'Q3': (f'{q_year}-07-01', f'{q_year}-09-30'),
                    'Q4': (f'{q_year}-10-01', f'{q_year}-12-31'),
                }
                start, end = quarter_ranges[q]
                trips = TripLog.objects.filter(vehicle_id=v.id, date__range=(start, end))
                purchases = FuelPurchase.objects.filter(vehicle_id=v.id, date__range=(start, end))
                if not trips.exists() and not purchases.exists():
                    continue
                total_m = sum(t.distance_miles for t in trips)
                total_g = sum(p.gallons for p in purchases)
                total_tp = sum(float(p.tax_paid) for p in purchases)
                jur_miles = defaultdict(float)
                jur_rate = {}
                for t in trips:
                    jur_miles[t.jurisdiction.code] += t.distance_miles
                    jur_rate[t.jurisdiction.code] = t.jurisdiction.fuel_tax_rate
                for p in purchases:
                    jur_rate[p.jurisdiction.code] = p.jurisdiction.fuel_tax_rate
                fleet_avg = (total_m / total_g) if total_g else 0
                tax_due = Decimal('0')
                for code, miles in jur_miles.items():
                    rate = jur_rate.get(code, Decimal('0'))
                    gallons_in_jur = miles / fleet_avg if fleet_avg else 0
                    tax_due += Decimal(str(gallons_in_jur)) * rate
                net_tax = tax_due - Decimal(str(total_tp))
                IftaQuarter.objects.update_or_create(
                    vehicle_id=v.id, year=q_year, quarter=q,
                    defaults={
                        'total_miles': round(total_m, 2),
                        'total_gallons': round(total_g, 2),
                        'total_tax_due': tax_due,
                        'total_tax_credit': Decimal(str(total_tp)),
                        'net_tax': net_tax,
                        'status': random.choice(['draft', 'draft', 'submitted', 'filed']),
                    },
                )
                created_reports += 1

        return Response({'detail': f'Seeded {created_trips} trip logs, {created_fuel} fuel purchases, and {created_reports} quarterly reports.'})

    @action(detail=False, methods=['post'])
    def generate(self, request):
        """Build or refresh a quarterly report from TripLog + FuelPurchase data.
        Payload: {'vehicle': id, 'year': 2024, 'quarter': 'Q1'}"""
        vehicle_id = request.data.get('vehicle')
        year = request.data.get('year')
        quarter = request.data.get('quarter')
        if not (vehicle_id and year and quarter):
            return Response({'detail': 'vehicle, year and quarter are required.'}, status=400)

        quarter_ranges = {
            'Q1': (f'{year}-01-01', f'{year}-03-31'),
            'Q2': (f'{year}-04-01', f'{year}-06-30'),
            'Q3': (f'{year}-07-01', f'{year}-09-30'),
            'Q4': (f'{year}-10-01', f'{year}-12-31'),
        }
        start, end = quarter_ranges[quarter]

        trips = TripLog.objects.filter(vehicle_id=vehicle_id, date__range=(start, end))
        purchases = FuelPurchase.objects.filter(vehicle_id=vehicle_id, date__range=(start, end))

        total_miles = sum(t.distance_miles for t in trips)
        total_gallons = sum(p.gallons for p in purchases)
        total_tax_paid = sum(p.tax_paid for p in purchases)

        # Per-jurisdiction aggregation
        jur_miles = defaultdict(float)
        jur_gallons = defaultdict(float)
        jur_rate = {}
        for t in trips:
            jur_miles[t.jurisdiction.code] += t.distance_miles
            jur_rate[t.jurisdiction.code] = t.jurisdiction.fuel_tax_rate
        for p in purchases:
            jur_gallons[p.jurisdiction.code] += p.gallons
            jur_rate[p.jurisdiction.code] = p.jurisdiction.fuel_tax_rate

        fleet_avg = (total_miles / total_gallons) if total_gallons else 0
        tax_due = Decimal('0')
        for code, miles in jur_miles.items():
            rate = jur_rate.get(code, Decimal('0'))
            gallons_in_jur = miles / fleet_avg if fleet_avg else 0
            tax_due += Decimal(str(gallons_in_jur)) * rate

        total_credit = Decimal(str(total_tax_paid))
        net_tax = tax_due - total_credit

        report, _ = IftaQuarter.objects.update_or_create(
            vehicle_id=vehicle_id, year=year, quarter=quarter,
            defaults={
                'total_miles': round(total_miles, 2),
                'total_gallons': round(total_gallons, 2),
                'total_tax_due': tax_due,
                'total_tax_credit': total_credit,
                'net_tax': net_tax,
                'status': IftaQuarter.Status.DRAFT,
            },
        )
        return Response(IftaQuarterSerializer(report).data)

    @action(detail=True, methods=['get'])
    def breakdown(self, request, pk=None):
        """Per-jurisdiction breakdown for a quarter report."""
        report = self.get_object()
        quarter_ranges = {
            'Q1': (f'{report.year}-01-01', f'{report.year}-03-31'),
            'Q2': (f'{report.year}-04-01', f'{report.year}-06-30'),
            'Q3': (f'{report.year}-07-01', f'{report.year}-09-30'),
            'Q4': (f'{report.year}-10-01', f'{report.year}-12-31'),
        }
        start, end = quarter_ranges[report.quarter]
        trips = TripLog.objects.filter(vehicle=report.vehicle, date__range=(start, end)).select_related('jurisdiction')
        purchases = FuelPurchase.objects.filter(vehicle=report.vehicle, date__range=(start, end)).select_related('jurisdiction')

        rows = {}
        for t in trips:
            code = t.jurisdiction.code
            rows.setdefault(code, {'jurisdiction': code, 'name': t.jurisdiction.name, 'miles': 0, 'gallons': 0, 'rate': float(t.jurisdiction.fuel_tax_rate)})
            rows[code]['miles'] += t.distance_miles
        for p in purchases:
            code = p.jurisdiction.code
            rows.setdefault(code, {'jurisdiction': code, 'name': p.jurisdiction.name, 'miles': 0, 'gallons': 0, 'rate': float(p.jurisdiction.fuel_tax_rate)})
            rows[code]['gallons'] += p.gallons

        fleet_avg = report.total_miles / report.total_gallons if report.total_gallons else 0
        for code, row in rows.items():
            row['consumed_gallons'] = round(row['miles'] / fleet_avg, 2) if fleet_avg else 0
            row['tax_due'] = round(row['consumed_gallons'] * row['rate'], 2)
        return Response(list(rows.values()))
