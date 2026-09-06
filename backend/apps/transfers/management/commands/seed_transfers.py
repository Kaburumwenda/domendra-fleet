from django.core.management.base import BaseCommand
from django.db import connection
from datetime import timedelta
from decimal import Decimal
from django.utils import timezone


class Command(BaseCommand):
    help = 'Seed demo transfer bookings for the current tenant schema'

    def handle(self, *args, **options):
        from apps.transfers.models import Transfer, TransferStop

        existing = Transfer.objects.count()
        if existing >= 5:
            self.stdout.write(self.style.WARNING(
                f'{existing} transfers already exist. Skipping demo seed.'
            ))
            return

        now = timezone.now()
        demos = [
            {
                'reference': '', 'passenger_name': 'Emily Chen', 'passenger_email': 'emily.chen@email.com',
                'passenger_phone': '+1 917 555 8432', 'passenger_count': 2, 'luggage_count': 3,
                'has_child_seat': True,
                'pickup_name': 'JFK International Airport (Terminal 4)',
                'pickup_address': 'JFK Airport, Terminal 4, Queens, NY 11430',
                'pickup_lat': Decimal('40.6413111'), 'pickup_lng': Decimal('-73.7781391'),
                'pickup_datetime': now + timedelta(days=1, hours=3),
                'pickup_flight_no': 'BAW178',
                'dropoff_name': 'Hilton Garden Inn Manhattan',
                'dropoff_address': '63 W 35th St, New York, NY 10001',
                'dropoff_lat': Decimal('40.7496800'), 'dropoff_lng': Decimal('-73.9877260'),
                'estimated_duration_min': 45, 'distance_km': Decimal('27.4'),
                'service_class': 'business', 'trip_type': 'one_way',
                'base_fare': Decimal('75'), 'tolls_amount': Decimal('17.50'),
                'child_seat_fee': Decimal('10'), 'meet_greet_fee': Decimal('15'),
                'status': 'scheduled', 'payment_status': 'paid',
                'amount_paid': Decimal('117.50'), 'total_amount': Decimal('117.50'),
            },
            {
                'reference': '', 'passenger_name': 'David Okoye', 'passenger_email': 'd.okoye@email.com',
                'passenger_phone': '+44 7700 900392', 'passenger_count': 4, 'luggage_count': 6,
                'pickup_name': 'Heathrow Airport (Terminal 5)',
                'pickup_address': 'Heathrow Airport Terminal 5, Longford, Hounslow TW6 2GA, UK',
                'pickup_lat': Decimal('51.4700'), 'pickup_lng': Decimal('-0.4543'),
                'pickup_datetime': now + timedelta(hours=6),
                'pickup_flight_no': 'VS003',
                'dropoff_name': 'The Savoy Hotel',
                'dropoff_address': 'Strand, London WC2R 0EU, UK',
                'dropoff_lat': Decimal('51.5109'), 'dropoff_lng': Decimal('-0.1185'),
                'estimated_duration_min': 40, 'distance_km': Decimal('24.8'),
                'service_class': 'premium', 'trip_type': 'one_way',
                'base_fare': Decimal('120'), 'tolls_amount': Decimal('15'),
                'driver_tip': Decimal('15'), 'waiting_fee': Decimal('12.50'),
                'status': 'assigned', 'payment_status': 'partial', 'amount_paid': Decimal('80'),
                'total_amount': Decimal('162.50'),
            },
            {
                'reference': '', 'passenger_name': 'Sophia Marin', 'passenger_email': 's.marin@email.com',
                'passenger_phone': '+1 305 555 0135', 'passenger_count': 1, 'luggage_count': 2,
                'pickup_name': 'Fontainebleau Miami Beach',
                'pickup_address': '4441 Collins Ave, Miami Beach, FL 33140',
                'pickup_lat': Decimal('25.8171'), 'pickup_lng': Decimal('-80.1279'),
                'pickup_datetime': now - timedelta(hours=2),
                'dropoff_name': 'Miami International Airport (Concourse D)',
                'dropoff_address': '2100 NW 42nd Ave, Miami, FL 33142',
                'dropoff_lat': Decimal('25.7959'), 'dropoff_lng': Decimal('-80.2870'),
                'estimated_duration_min': 25, 'distance_km': Decimal('18.3'),
                'service_class': 'economy', 'trip_type': 'one_way',
                'base_fare': Decimal('45'), 'driver_tip': Decimal('6'),
                'actual_pickup_time': now - timedelta(hours=1),
                'status': 'en_route', 'payment_status': 'paid',
                'amount_paid': Decimal('51'), 'total_amount': Decimal('51'),
            },
            {
                'reference': '', 'passenger_name': 'Akira Tanaka', 'passenger_email': 'akira.t@email.com',
                'passenger_phone': '+81 90 1983 4456', 'passenger_count': 1, 'luggage_count': 1,
                'pickup_name': 'Grand Hyatt Tokyo',
                'pickup_address': '6-10-3 Roppongi, Minato-ku, Tokyo 106-0032',
                'pickup_lat': Decimal('35.6644'), 'pickup_lng': Decimal('139.7280'),
                'pickup_datetime': now - timedelta(days=1, hours=4),
                'dropoff_name': 'Narita International Airport (Terminal 1)',
                'dropoff_address': '1-1 Furugome, Narita, Chiba 282-0004, Japan',
                'dropoff_lat': Decimal('35.7720'), 'dropoff_lng': Decimal('140.3929'),
                'estimated_duration_min': 90, 'distance_km': Decimal('75.4'),
                'service_class': 'executive', 'trip_type': 'one_way',
                'base_fare': Decimal('280'), 'tolls_amount': Decimal('35'),
                'tax_amount': Decimal('31.50'), 'driver_tip': Decimal('30'),
                'actual_pickup_time': now - timedelta(days=1),
                'actual_dropoff_time': now - timedelta(days=1, hours=1, minutes=30),
                'status': 'completed', 'payment_status': 'paid',
                'amount_paid': Decimal('376.50'), 'total_amount': Decimal('376.50'),
                'rating': 5, 'feedback': 'Excellent service, on time and professional!',
            },
            {
                'reference': '', 'passenger_name': 'Lucy Snider', 'passenger_email': 'lucy.snider@email.com',
                'passenger_phone': '+1 415 555 0338', 'passenger_count': 3, 'luggage_count': 4,
                'pickup_name': 'Fisherman Wharf',
                'pickup_address': '2801 Leavenworth St, San Francisco, CA 94133',
                'pickup_lat': Decimal('37.8076'), 'pickup_lng': Decimal('-122.4152'),
                'pickup_datetime': now + timedelta(days=3, hours=2),
                'dropoff_name': 'San Francisco International Airport',
                'dropoff_address': 'San Francisco, CA 94128, USA',
                'dropoff_lat': Decimal('37.6213'), 'dropoff_lng': Decimal('-122.3790'),
                'estimated_duration_min': 30, 'distance_km': Decimal('22.7'),
                'service_class': 'van', 'trip_type': 'round_trip',
                'base_fare': Decimal('95'), 'tolls_amount': Decimal('8'),
                'meet_greet_fee': Decimal('20'), 'return_datetime': now + timedelta(days=7),
                'status': 'draft', 'payment_status': 'unpaid',
            },
        ]

        created_count = 0
        for data in demos:
            obj = Transfer.objects.create(**{k: v for k, v in data.items() if k != 'reference'})
            created_count += 1
            self.stdout.write(self.style.SUCCESS(f'  + {obj.reference} ({obj.service_class}) {obj.pickup_name} → {obj.dropoff_name}'))

        self.stdout.write(self.style.SUCCESS(
            f'Demo seed complete — {created_count} transfers created in schema: {connection.schema_name}'
        ))
