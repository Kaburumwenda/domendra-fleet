import random
from datetime import timedelta

from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Service, VendorRating
from .serializers import ServiceSerializer, VendorRatingSerializer


class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.select_related('vehicle', 'vendor', 'technician', 'rating')
    serializer_class = ServiceSerializer
    filterset_fields = ['service_type', 'vehicle', 'vendor', 'work_order']
    search_fields = ['description']
    ordering_fields = ['performed_at', 'cost']

    @action(detail=True, methods=['post'])
    def rate_vendor(self, request, pk=None):
        service = self.get_object()
        serializer = VendorRatingSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        rating, _ = VendorRating.objects.update_or_create(
            service=service, defaults=serializer.validated_data,
        )
        return Response(VendorRatingSerializer(rating).data)

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo service records and vendor ratings for the current tenant."""
        from apps.vehicles.models import Vehicle
        from apps.contacts.models import Contact
        from apps.users.models import User

        vehicles = list(Vehicle.objects.all()[:10])
        vendors = list(Contact.objects.filter(contact_type='vendor')[:5])
        techs = list(User.objects.all()[:3])

        if not vehicles:
            return Response({'detail': 'No vehicles found. Create vehicles first.'}, status=400)

        # Create vendor contacts if none exist
        if not vendors:
            vendor_names = ['FleetFix Garage', 'QuickLube Express', 'BrakeMasters Pro', 'AllTruck Service Center', 'Precision Auto Works']
            for n in vendor_names:
                Contact.objects.create(contact_type='vendor', company_name=n, phone='555-0100', address='Industrial Way', city='Los Angeles', state='CA', is_active=True)
            vendors = list(Contact.objects.filter(contact_type='vendor')[:5])

        types = ['oil_change', 'tire_rotation', 'brake_service', 'inspection', 'repair', 'preventive', 'other']
        descmap = {
            'oil_change': ['Full synthetic oil change', 'Conventional oil + filter', 'Engine oil refresh'],
            'tire_rotation': ['Tire rotation and balance', 'Tire wear inspection'],
            'brake_service': ['Brake pad replacement', 'Brake fluid flush', 'Rotor resurfacing'],
            'inspection': ['DOT annual inspection', 'Safety inspection', 'Pre-trip inspection'],
            'repair': ['Transmission repair', 'Suspension rebuild', 'Electrical diag & repair'],
            'preventive': ['Scheduled PM-A service', 'Scheduled PM-B service', 'Preventive maintenance'],
            'other': ['AC recharge', 'Battery replacement', 'Windshield replacement'],
        }
        now = timezone.now()
        created = 0
        rated = 0
        for _ in range(28):
            sv = Service.objects.create(
                vehicle=random.choice(vehicles),
                service_type=random.choice(types),
                description=random.choice(descmap[random.choice(types)]),
                performed_at=now - timedelta(days=random.randint(0, 120), hours=random.randint(0, 8)),
                cost=round(random.uniform(45, 2400), 2),
                vendor=random.choice(vendors) if random.random() > 0.2 else None,
                technician=random.choice(techs) if techs and random.random() > 0.3 else None,
                odometer_reading=random.randint(20000, 320000),
                downtime_hours=round(random.uniform(0, 24), 1) if random.random() > 0.6 else round(random.uniform(0, 3), 1),
            )
            created += 1
            if sv.vendor and random.random() > 0.4:
                VendorRating.objects.create(
                    service=sv,
                    cost_rating=round(random.uniform(2.5, 5), 1),
                    quality_rating=round(random.uniform(3, 5), 1),
                    turnaround_rating=round(random.uniform(2, 5), 1),
                    notes=random.choice(['', 'Fast turnaround, good work.', 'Fair pricing but quality concerns.', 'Excellent service.', 'Would use again.']),
                )
                rated += 1

        return Response({'detail': f'Seeded {created} service records with {rated} vendor ratings.'})


class VendorRatingViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VendorRating.objects.select_related('service')
    serializer_class = VendorRatingSerializer
    filterset_fields = ['service__vendor']
