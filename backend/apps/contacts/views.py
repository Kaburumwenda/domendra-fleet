import datetime
import random
from collections import Counter

from django.db.models import Avg
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status

from .models import (
    Contact,
    DriverProfile,
    DriverViolation,
    DriverDrugTest,
    DriverTraining,
    DriverHoursOfService,
    DriverAssignment,
    DriverNote,
    VendorProfile,
)
from .serializers import (
    ContactSerializer,
    DriverProfileSerializer,
    DriverViolationSerializer,
    DriverDrugTestSerializer,
    DriverTrainingSerializer,
    DriverHoursOfServiceSerializer,
    DriverAssignmentSerializer,
    DriverNoteSerializer,
)


class ContactViewSet(viewsets.ModelViewSet):
    queryset = Contact.objects.select_related('driver_profile', 'vendor_profile')
    serializer_class = ContactSerializer
    filterset_fields = ['contact_type', 'is_active', 'city', 'state']
    search_fields = ['first_name', 'last_name', 'email', 'phone', 'company_name']
    ordering_fields = ['first_name', 'last_name', 'created_at']

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = self.get_queryset()
        total = qs.count()
        active = qs.filter(is_active=True).count()
        inactive = qs.filter(is_active=False).count()

        # By contact_type
        from collections import Counter
        type_counts = Counter(qs.values_list('contact_type', flat=True))
        by_type = {k: v for k, v in type_counts.items()}

        # Vendors with rating
        vendors = qs.filter(contact_type='vendor', vendor_profile__isnull=False)
        vendor_count = vendors.count()
        avg_rating = vendors.aggregate(avg=Avg('vendor_profile__rating'))['avg'] or 0

        # Geographic distribution
        city_counts = Counter(qs.values_list('city', flat=True))
        by_city = {k: v for k, v in city_counts.items() if k}

        return Response({
            'total': total,
            'active': active,
            'inactive': inactive,
            'by_type': by_type,
            'vendor_count': vendor_count,
            'avg_rating': round(avg_rating, 2),
            'by_city': by_city,
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo contacts (vendors, mechanics, insurance agents, towing, managers).
        Also enriches existing vendors with missing VendorProfile entries."""
        existing_non_driver = Contact.objects.exclude(contact_type='driver').count()

        # Enrich existing vendor contacts that lack a VendorProfile
        vendors_without_profile = Contact.objects.filter(
            contact_type='vendor', vendor_profile__isnull=True
        )
        enriched = 0
        vendor_profiles_data = {
            'autoparts': {'service_type': 'Auto Parts Supplier', 'rating': 4.5, 'payment_terms': 'Net 30', 'tax_id': 'P051234567A'},
            'quickfix': {'service_type': 'Roadside Assistance', 'rating': 4.0, 'payment_terms': 'Net 15', 'tax_id': 'P051234568B'},
            'tyremasters': {'service_type': 'Tyre Supplier', 'rating': 4.8, 'payment_terms': 'Net 45', 'tax_id': 'P051234569C'},
            'oil': {'service_type': 'Fuel Supplier', 'rating': 3.5, 'payment_terms': 'Net 30', 'tax_id': 'P051234570D'},
        }
        profiles_list = list(vendor_profiles_data.values())
        for idx, vendor in enumerate(vendors_without_profile):
            company_lower = (vendor.company_name or '').lower()
            matched = None
            for key, prof in vendor_profiles_data.items():
                if key in company_lower:
                    matched = prof
                    break
            if not matched:
                # assign a default profile based on position
                matched = profiles_list[idx % len(profiles_list)]
            VendorProfile.objects.create(contact=vendor, **matched)
            enriched += 1

        if existing_non_driver >= 10:
            if enriched:
                return Response({
                    'created': 0,
                    'enriched': enriched,
                    'detail': f'{existing_non_driver} contacts already exist. Enriched {enriched} vendor(s) with profiles.',
                })
            return Response(
                {'detail': f'{existing_non_driver} contacts already exist. Seeding is skipped.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        today = datetime.date.today()

        contacts_data = [
            # Vendors
            {
                'contact_type': 'vendor', 'company_name': 'AutoParts Kenya Ltd',
                'first_name': 'Robert', 'last_name': 'Kibet',
                'email': 'info@autoparts.co.ke', 'phone': '+254700111222',
                'address': 'Industrial Area, Nairobi', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'vendor_profile': {'service_type': 'Auto Parts Supplier', 'rating': 4.5, 'payment_terms': 'Net 30', 'tax_id': 'P051234567A'},
            },
            {
                'contact_type': 'vendor', 'company_name': 'QuickFix Mechanics',
                'first_name': 'Samuel', 'last_name': 'Njoroge',
                'email': 'samuel@quickfix.co.ke', 'phone': '+254700222333',
                'address': 'Mombasa Road, Nairobi', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'vendor_profile': {'service_type': 'Roadside Assistance', 'rating': 4.0, 'payment_terms': 'Net 15', 'tax_id': 'P051234568B'},
            },
            {
                'contact_type': 'vendor', 'company_name': 'TyreMasters EA',
                'first_name': 'Esther', 'last_name': 'Wambui',
                'email': 'sales@tyremasters.co.ke', 'phone': '+254700333444',
                'address': 'Thika Road, Nairobi', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'vendor_profile': {'service_type': 'Tyre Supplier', 'rating': 4.8, 'payment_terms': 'Net 45', 'tax_id': 'P051234569C'},
            },
            {
                'contact_type': 'vendor', 'company_name': 'Oil Libya Services',
                'first_name': 'James', 'last_name': 'Mutiso',
                'email': 'james@oil libya.co.ke', 'phone': '+254700444555',
                'address': 'Eldoret Town', 'city': 'Eldoret', 'state': 'Uasin Gishu', 'country': 'Kenya',
                'vendor_profile': {'service_type': 'Fuel Supplier', 'rating': 3.5, 'payment_terms': 'Net 30', 'tax_id': 'P051234570D'},
            },
            # Mechanics
            {
                'contact_type': 'mechanic', 'first_name': 'Peter', 'last_name': 'Maina',
                'email': 'peter.maina@acme.com', 'phone': '+254711555666',
                'address': 'Nairobi', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'department': 'Garage', 'employee_id': 'MEC-001',
            },
            {
                'contact_type': 'mechanic', 'first_name': 'Paul', 'last_name': 'Kariuki',
                'email': 'paul.kariuki@acme.com', 'phone': '+254711666777',
                'address': 'Mombasa', 'city': 'Mombasa', 'state': 'Mombasa', 'country': 'Kenya',
                'department': 'Garage', 'employee_id': 'MEC-002',
            },
            # Insurance Agent
            {
                'contact_type': 'insurance_agent', 'company_name': 'Jubilee Insurance',
                'first_name': 'Grace', 'last_name': 'Achieng',
                'email': 'gachieng@jubilee.co.ke', 'phone': '+254711777888',
                'address': 'Westlands, Nairobi', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
            },
            # Towing Company
            {
                'contact_type': 'towing', 'company_name': 'Highway Towing Services',
                'first_name': 'Daniel', 'last_name': 'Omondi',
                'email': 'dispatch@highwaytowing.co.ke', 'phone': '+254711888999',
                'address': 'Nakuru', 'city': 'Nakuru', 'state': 'Nakuru', 'country': 'Kenya',
            },
            # Manager
            {
                'contact_type': 'manager', 'first_name': 'Alice', 'last_name': 'Wangari',
                'email': 'alice.wangari@acme.com', 'phone': '+254711999000',
                'address': 'Nairobi', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'department': 'Operations', 'employee_id': 'MGR-001',
            },
            {
                'contact_type': 'manager', 'first_name': 'Brian', 'last_name': 'Owino',
                'email': 'brian.owino@acme.com', 'phone': '+254722000111',
                'address': 'Kisumu', 'city': 'Kisumu', 'state': 'Kisumu', 'country': 'Kenya',
                'department': 'Fleet', 'employee_id': 'MGR-002',
            },
        ]

        created = 0
        for d in contacts_data:
            vendor_data = d.pop('vendor_profile', None)
            contact = Contact.objects.create(
                contact_type=d['contact_type'],
                first_name=d.get('first_name', ''),
                last_name=d.get('last_name', ''),
                company_name=d.get('company_name', ''),
                email=d.get('email', ''),
                phone=d.get('phone', ''),
                address=d.get('address', ''),
                city=d.get('city', ''),
                state=d.get('state', ''),
                country=d.get('country', ''),
                department=d.get('department', ''),
                employee_id=d.get('employee_id', ''),
                is_active=True,
            )
            if vendor_data:
                VendorProfile.objects.create(contact=contact, **vendor_data)
            created += 1

        detail_parts = [f'Successfully seeded {created} demo contacts.']
        if enriched:
            detail_parts.append(f'Enriched {enriched} vendor(s) with profiles.')
        return Response({
            'created': created,
            'enriched': enriched,
            'detail': ' '.join(detail_parts),
        })


class DriverViewSet(viewsets.ModelViewSet):
    """Drivers are Contact records with contact_type='driver', exposed with their DriverProfile."""
    serializer_class = ContactSerializer
    filterset_fields = ['is_active', 'city', 'state', 'driver_profile__employment_status', 'driver_profile__mvr_status']
    search_fields = ['first_name', 'last_name', 'email', 'phone', 'company_name', 'driver_profile__license_number']
    ordering_fields = ['first_name', 'last_name', 'created_at', 'driver_profile__hire_date']

    def get_queryset(self):
        return (
            Contact.objects
            .filter(contact_type='driver')
            .select_related('driver_profile', 'driver_profile__contact')
            .prefetch_related(
                'driver_profile__violations',
                'driver_profile__drug_tests',
                'driver_profile__trainings',
                'driver_profile__assignments',
            )
            .order_by('-created_at')
        )

    @action(detail=False, methods=['get'], url_path='stats')
    def stats(self, request):
        qs = self.get_queryset()
        total = qs.count()
        active = qs.filter(is_active=True).count()
        on_leave = qs.filter(driver_profile__employment_status=DriverProfile.EmploymentStatus.ON_LEAVE).count()
        suspended = qs.filter(driver_profile__employment_status=DriverProfile.EmploymentStatus.SUSPENDED).count()
        terminated = qs.filter(driver_profile__employment_status=DriverProfile.EmploymentStatus.TERMINATED).count()
        clean_mvr = qs.filter(driver_profile__mvr_status=DriverProfile.MvrStatus.CLEAN).count()
        warning_mvr = qs.filter(driver_profile__mvr_status=DriverProfile.MvrStatus.WARNING).count()
        today = datetime.date.today()
        expiring_lic = qs.filter(
            driver_profile__license_expiry__isnull=False,
            driver_profile__license_expiry__lte=today + datetime.timedelta(days=30),
        ).count()
        expired_lic = qs.filter(
            driver_profile__license_expiry__isnull=False,
            driver_profile__license_expiry__lt=today,
        ).count()
        expiring_med = qs.filter(
            driver_profile__medical_card_expiry__isnull=False,
            driver_profile__medical_card_expiry__lte=today + datetime.timedelta(days=30),
        ).count()
        return Response({
            'total': total,
            'active': active,
            'on_leave': on_leave,
            'suspended': suspended,
            'terminated': terminated,
            'mvr_clean': clean_mvr,
            'mvr_warning': warning_mvr,
            'licenses_expiring_30d': expiring_lic,
            'licenses_expired': expired_lic,
            'med_cards_expiring_30d': expiring_med,
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo drivers with profiles, violations, drug tests, trainings, HOS logs, and notes."""
        existing = Contact.objects.filter(contact_type='driver').count()
        if existing >= 8:
            return Response(
                {'detail': f'{existing} drivers already exist. Seeding is skipped.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        today = datetime.date.today()

        drivers_data = [
            {
                'first_name': 'James', 'last_name': 'Mwangi', 'email': 'james.mwangi@acme.com',
                'phone': '+254712345678', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'department': 'Long Haul', 'employee_id': 'ACM-001',
                'license_number': 'DL-A-2019-1234', 'license_class': DriverProfile.LicenseClass.CDL_A,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=400),
                'license_endorsements': ['hazmat', 'tanker'],
                'medical_card_expiry': today + datetime.timedelta(days=300),
                'medical_card_number': 'MC-98765', 'mvr_status': DriverProfile.MvrStatus.CLEAN,
                'mvr_last_checked': today - datetime.timedelta(days=45),
                'mvr_next_due': today + datetime.timedelta(days=320),
                'hire_date': today - datetime.timedelta(days=900),
                'employment_status': DriverProfile.EmploymentStatus.ACTIVE,
                'home_terminal': 'Nairobi DC', 'pay_rate': 28.50, 'pay_type': 'hourly',
                'emergency_contact_name': 'Grace Mwangi', 'emergency_contact_phone': '+254722334455',
                'emergency_contact_relation': 'Spouse', 'blood_type': 'O+',
            },
            {
                'first_name': 'Sarah', 'last_name': 'Kamau', 'email': 'sarah.kamau@acme.com',
                'phone': '+254723456789', 'city': 'Mombasa', 'state': 'Mombasa', 'country': 'Kenya',
                'department': 'Regional', 'employee_id': 'ACM-002',
                'license_number': 'DL-B-2018-5678', 'license_class': DriverProfile.LicenseClass.CDL_B,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=20),
                'license_endorsements': ['airbrake'],
                'medical_card_expiry': today + datetime.timedelta(days=15),
                'medical_card_number': 'MC-45678', 'mvr_status': DriverProfile.MvrStatus.WARNING,
                'mvr_last_checked': today - datetime.timedelta(days=60),
                'mvr_next_due': today + datetime.timedelta(days=10),
                'hire_date': today - datetime.timedelta(days=500),
                'employment_status': DriverProfile.EmploymentStatus.ACTIVE,
                'home_terminal': 'Mombasa DC', 'pay_rate': 25.00, 'pay_type': 'hourly',
                'emergency_contact_name': 'Peter Kamau', 'emergency_contact_phone': '+254733445566',
                'emergency_contact_relation': 'Brother', 'blood_type': 'A+',
            },
            {
                'first_name': 'David', 'last_name': 'Ochieng', 'email': 'david.ochieng@acme.com',
                'phone': '+254734567890', 'city': 'Kisumu', 'state': 'Kisumu', 'country': 'Kenya',
                'department': 'Local Delivery', 'employee_id': 'ACM-003',
                'license_number': 'DL-C-2020-9012', 'license_class': DriverProfile.LicenseClass.C,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=200),
                'license_endorsements': ['passenger'],
                'medical_card_expiry': today + datetime.timedelta(days=250),
                'medical_card_number': 'MC-12345', 'mvr_status': DriverProfile.MvrStatus.CLEAN,
                'mvr_last_checked': today - datetime.timedelta(days=15),
                'mvr_next_due': today + datetime.timedelta(days=350),
                'hire_date': today - datetime.timedelta(days=300),
                'employment_status': DriverProfile.EmploymentStatus.ACTIVE,
                'home_terminal': 'Kisumu DC', 'pay_rate': 22.00, 'pay_type': 'hourly',
                'emergency_contact_name': 'Mary Ochieng', 'emergency_contact_phone': '+254744556677',
                'emergency_contact_relation': 'Sister', 'blood_type': 'B+',
            },
            {
                'first_name': 'Michael', 'last_name': 'Otieno', 'email': 'michael.otieno@acme.com',
                'phone': '+254745678901', 'city': 'Nakuru', 'state': 'Nakuru', 'country': 'Kenya',
                'department': 'Long Haul', 'employee_id': 'ACM-004',
                'license_number': 'DL-A-2017-3456', 'license_class': DriverProfile.LicenseClass.CDL_A,
                'license_state': 'KE', 'license_expiry': today - datetime.timedelta(days=30),
                'license_endorsements': ['hazmat', 'tanker', 'airbrake'],
                'medical_card_expiry': today - datetime.timedelta(days=10),
                'medical_card_number': 'MC-67890', 'mvr_status': DriverProfile.MvrStatus.SUSPENDED,
                'mvr_last_checked': today - datetime.timedelta(days=90),
                'mvr_next_due': today - datetime.timedelta(days=5),
                'hire_date': today - datetime.timedelta(days=1200),
                'employment_status': DriverProfile.EmploymentStatus.SUSPENDED,
                'home_terminal': 'Nakuru DC', 'pay_rate': 30.00, 'pay_type': 'hourly',
                'emergency_contact_name': 'Joyce Otieno', 'emergency_contact_phone': '+254755667788',
                'emergency_contact_relation': 'Wife', 'blood_type': 'AB+',
            },
            {
                'first_name': 'Grace', 'last_name': 'Wanjiru', 'email': 'grace.wanjiru@acme.com',
                'phone': '+254756789012', 'city': 'Nairobi', 'state': 'Nairobi', 'country': 'Kenya',
                'department': 'Regional', 'employee_id': 'ACM-005',
                'license_number': 'DL-B-2021-7890', 'license_class': DriverProfile.LicenseClass.B,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=180),
                'license_endorsements': ['airbrake'],
                'medical_card_expiry': today + datetime.timedelta(days=120),
                'medical_card_number': 'MC-34567', 'mvr_status': DriverProfile.MvrStatus.CLEAN,
                'mvr_last_checked': today - datetime.timedelta(days=20),
                'mvr_next_due': today + datetime.timedelta(days=340),
                'hire_date': today - datetime.timedelta(days=150),
                'employment_status': DriverProfile.EmploymentStatus.ON_LEAVE,
                'home_terminal': 'Nairobi DC', 'pay_rate': 24.00, 'pay_type': 'hourly',
                'emergency_contact_name': 'John Wanjiru', 'emergency_contact_phone': '+254766778899',
                'emergency_contact_relation': 'Father', 'blood_type': 'O-',
            },
            {
                'first_name': 'Joseph', 'last_name': 'Kiptoo', 'email': 'joseph.kiptoo@acme.com',
                'phone': '+254767890123', 'city': 'Eldoret', 'state': 'Uasin Gishu', 'country': 'Kenya',
                'department': 'Long Haul', 'employee_id': 'ACM-006',
                'license_number': 'DL-A-2016-2345', 'license_class': DriverProfile.LicenseClass.A,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=500),
                'license_endorsements': ['tanker'],
                'medical_card_expiry': today + datetime.timedelta(days=280),
                'medical_card_number': 'MC-89012', 'mvr_status': DriverProfile.MvrStatus.EXPIRED,
                'mvr_last_checked': today - datetime.timedelta(days=400),
                'mvr_next_due': today - datetime.timedelta(days=300),
                'hire_date': today - datetime.timedelta(days=2000),
                'employment_status': DriverProfile.EmploymentStatus.TERMINATED,
                'termination_date': today - datetime.timedelta(days=60),
                'home_terminal': 'Eldoret DC', 'pay_rate': 26.00, 'pay_type': 'mileage',
                'emergency_contact_name': 'Rose Kiptoo', 'emergency_contact_phone': '+254777889900',
                'emergency_contact_relation': 'Wife', 'blood_type': 'A-',
            },
            {
                'first_name': 'Daniel', 'last_name': 'Mutua', 'email': 'daniel.mutua@acme.com',
                'phone': '+254778901234', 'city': 'Machakos', 'state': 'Machakos', 'country': 'Kenya',
                'department': 'Local Delivery', 'employee_id': 'ACM-007',
                'license_number': 'DL-C-2022-6789', 'license_class': DriverProfile.LicenseClass.C,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=350),
                'license_endorsements': [],
                'medical_card_expiry': today + datetime.timedelta(days=330),
                'medical_card_number': 'MC-23456', 'mvr_status': DriverProfile.MvrStatus.CLEAN,
                'mvr_last_checked': today - datetime.timedelta(days=10),
                'mvr_next_due': today + datetime.timedelta(days=355),
                'hire_date': today - datetime.timedelta(days=90),
                'employment_status': DriverProfile.EmploymentStatus.PROBATION,
                'home_terminal': 'Machakos DC', 'pay_rate': 20.00, 'pay_type': 'hourly',
                'emergency_contact_name': 'Faith Mutua', 'emergency_contact_phone': '+254788990011',
                'emergency_contact_relation': 'Mother', 'blood_type': 'B-',
            },
            {
                'first_name': 'Anthony', 'last_name': 'Maina', 'email': 'anthony.maina@acme.com',
                'phone': '+254789012345', 'city': 'Nyeri', 'state': 'Nyeri', 'country': 'Kenya',
                'department': 'Long Haul', 'employee_id': 'ACM-008',
                'license_number': 'DL-A-2023-0123', 'license_class': DriverProfile.LicenseClass.CDL_A,
                'license_state': 'KE', 'license_expiry': today + datetime.timedelta(days=250),
                'license_endorsements': ['hazmat', 'tanker', 'airbrake', 'passenger'],
                'medical_card_expiry': today + datetime.timedelta(days=25),
                'medical_card_number': 'MC-56789', 'mvr_status': DriverProfile.MvrStatus.WARNING,
                'mvr_last_checked': today - datetime.timedelta(days=50),
                'mvr_next_due': today + datetime.timedelta(days=20),
                'hire_date': today - datetime.timedelta(days=700),
                'employment_status': DriverProfile.EmploymentStatus.ACTIVE,
                'home_terminal': 'Nyeri DC', 'pay_rate': 27.00, 'pay_type': 'salary',
                'emergency_contact_name': 'Lucy Maina', 'emergency_contact_phone': '+254799001122',
                'emergency_contact_relation': 'Spouse', 'blood_type': 'O+',
            },
        ]

        created = 0
        for i, d in enumerate(drivers_data):
            contact = Contact.objects.create(
                contact_type='driver',
                first_name=d['first_name'],
                last_name=d['last_name'],
                email=d['email'],
                phone=d['phone'],
                city=d['city'],
                state=d['state'],
                country=d['country'],
                department=d['department'],
                employee_id=d['employee_id'],
                is_active=d['employment_status'] != DriverProfile.EmploymentStatus.TERMINATED,
            )
            profile = DriverProfile.objects.create(
                contact=contact,
                license_number=d['license_number'],
                license_class=d['license_class'],
                license_state=d['license_state'],
                license_expiry=d['license_expiry'],
                license_endorsements=d['license_endorsements'],
                medical_card_expiry=d['medical_card_expiry'],
                medical_card_number=d['medical_card_number'],
                mvr_status=d['mvr_status'],
                mvr_last_checked=d['mvr_last_checked'],
                mvr_next_due=d['mvr_next_due'],
                hire_date=d['hire_date'],
                termination_date=d.get('termination_date'),
                employment_status=d['employment_status'],
                home_terminal=d['home_terminal'],
                pay_rate=d['pay_rate'],
                pay_type=d['pay_type'],
                emergency_contact_name=d['emergency_contact_name'],
                emergency_contact_phone=d['emergency_contact_phone'],
                emergency_contact_relation=d['emergency_contact_relation'],
                blood_type=d['blood_type'],
            )

            # Add violations for drivers with warning/suspended/expired MVR
            if d['mvr_status'] in (
                DriverProfile.MvrStatus.WARNING,
                DriverProfile.MvrStatus.SUSPENDED,
                DriverProfile.MvrStatus.EXPIRED,
            ):
                DriverViolation.objects.create(
                    driver_profile=profile,
                    violation_type=DriverViolation.ViolationType.SPEEDING,
                    severity=DriverViolation.Severity.MINOR,
                    date=today - datetime.timedelta(days=random.randint(30, 180)),
                    state='KE',
                    points=random.randint(2, 6),
                    description='Exceeded speed limit by 15 km/h on highway.',
                    fine_amount=random.randint(2000, 5000),
                    paid=random.choice([True, False]),
                )
                if d['mvr_status'] == DriverProfile.MvrStatus.SUSPENDED:
                    DriverViolation.objects.create(
                        driver_profile=profile,
                        violation_type=DriverViolation.ViolationType.RECKLESS,
                        severity=DriverViolation.Severity.MAJOR,
                        date=today - datetime.timedelta(days=random.randint(60, 120)),
                        state='KE',
                        points=random.randint(8, 12),
                        description='Reckless driving — weaving through traffic at high speed.',
                        fine_amount=random.randint(8000, 15000),
                        paid=False,
                    )

            # Drug tests
            DriverDrugTest.objects.create(
                driver_profile=profile,
                test_type=DriverDrugTest.TestType.PRE_EMPLOYMENT,
                test_date=d['hire_date'] or today - datetime.timedelta(days=90),
                result=DriverDrugTest.Result.NEGATIVE,
                lab_name='Nairobi Diagnostic Lab',
                chain_of_custody=f'COC-{i + 1001}',
            )
            if d['employment_status'] == DriverProfile.EmploymentStatus.ACTIVE:
                DriverDrugTest.objects.create(
                    driver_profile=profile,
                    test_type=DriverDrugTest.TestType.RANDOM,
                    test_date=today - datetime.timedelta(days=random.randint(10, 60)),
                    result=random.choice([
                        DriverDrugTest.Result.NEGATIVE,
                        DriverDrugTest.Result.NEGATIVE,
                        DriverDrugTest.Result.PENDING,
                    ]),
                    lab_name='Eldoret Lab Services',
                    chain_of_custody=f'COC-{i + 2001}',
                )

            # Training
            DriverTraining.objects.create(
                driver_profile=profile,
                course_name='Defensive Driving Course',
                provider='NTSA Safety Academy',
                status=DriverTraining.Status.COMPLETED,
                completion_date=d['hire_date'] or today - datetime.timedelta(days=80),
                expiry_date=today + datetime.timedelta(days=365),
                score=random.uniform(85, 98),
                hours=8,
                certificate_number=f'DC-{i + 301}',
            )
            if d['employment_status'] in (
                DriverProfile.EmploymentStatus.ACTIVE,
                DriverProfile.EmploymentStatus.PROBATION,
            ):
                DriverTraining.objects.create(
                    driver_profile=profile,
                    course_name='Hazmat Handling & Transport',
                    provider='Kenya Transport Institute',
                    status=random.choice([
                        DriverTraining.Status.COMPLETED,
                        DriverTraining.Status.IN_PROGRESS,
                    ]),
                    completion_date=today - datetime.timedelta(days=random.randint(30, 120)) if random.choice([True, False]) else None,
                    expiry_date=today + datetime.timedelta(days=365),
                    score=random.uniform(75, 95),
                    hours=16,
                    certificate_number=f'HZ-{i + 401}',
                )

            # HOS logs (last 3 days)
            for day_offset in range(3):
                DriverHoursOfService.objects.create(
                    driver_profile=profile,
                    date=today - datetime.timedelta(days=day_offset),
                    duty_status=random.choice([
                        DriverHoursOfService.DutyStatus.DRIVING,
                        DriverHoursOfService.DutyStatus.ON_DUTY,
                        DriverHoursOfService.DutyStatus.OFF_DUTY,
                    ]),
                    hours=round(random.uniform(3, 11), 1),
                    driving_hours=round(random.uniform(0, 8), 1),
                    on_duty_hours=round(random.uniform(2, 12), 1),
                    cycle_hours=round(random.uniform(20, 60), 1),
                    location=d['home_terminal'],
                    vehicle=f'KXX {100 + i}A',
                )

            # Notes
            DriverNote.objects.create(
                driver_profile=profile,
                category=DriverNote.Category.GENERAL,
                body=f'{d["first_name"]} attended quarterly safety briefing and completed all required paperwork.',
                author='HR Department',
            )
            if d['mvr_status'] != DriverProfile.MvrStatus.CLEAN:
                DriverNote.objects.create(
                    driver_profile=profile,
                    category=DriverNote.Category.WARNING,
                    body='MVR flagged for recent violation. Review required before next assignment.',
                    author='Safety Officer',
                )

            created += 1

        return Response({'created': created, 'detail': f'Successfully seeded {created} demo drivers with violations, drug tests, trainings, HOS logs, and notes.'})


class DriverProfileViewSet(viewsets.ModelViewSet):
    queryset = DriverProfile.objects.select_related('contact').prefetch_related(
        'violations', 'drug_tests', 'trainings', 'hos_logs', 'assignments', 'notes_log',
    )
    serializer_class = DriverProfileSerializer
    filterset_fields = ['employment_status', 'mvr_status', 'license_class']
    search_fields = ['contact__first_name', 'contact__last_name', 'license_number']
    ordering_fields = ['hire_date', 'mvr_status', 'employment_status']


class DriverViolationViewSet(viewsets.ModelViewSet):
    queryset = DriverViolation.objects.select_related('driver_profile__contact')
    serializer_class = DriverViolationSerializer
    filterset_fields = ['driver_profile', 'violation_type', 'severity']
    ordering_fields = ['date', 'points']


class DriverDrugTestViewSet(viewsets.ModelViewSet):
    queryset = DriverDrugTest.objects.select_related('driver_profile__contact')
    serializer_class = DriverDrugTestSerializer
    filterset_fields = ['driver_profile', 'test_type', 'result']
    ordering_fields = ['test_date']


class DriverTrainingViewSet(viewsets.ModelViewSet):
    queryset = DriverTraining.objects.select_related('driver_profile__contact')
    serializer_class = DriverTrainingSerializer
    filterset_fields = ['driver_profile', 'status']
    search_fields = ['course_name', 'provider']
    ordering_fields = ['completion_date', 'expiry_date']


class DriverHoursOfServiceViewSet(viewsets.ModelViewSet):
    queryset = DriverHoursOfService.objects.select_related('driver_profile__contact')
    serializer_class = DriverHoursOfServiceSerializer
    filterset_fields = ['driver_profile', 'duty_status', 'date']
    ordering_fields = ['date']


class DriverAssignmentViewSet(viewsets.ModelViewSet):
    queryset = DriverAssignment.objects.select_related('driver_profile__contact', 'vehicle')
    serializer_class = DriverAssignmentSerializer
    filterset_fields = ['driver_profile', 'vehicle', 'is_active']
    ordering_fields = ['assigned_at']

    @action(detail=True, methods=['post'], url_path='release')
    def release(self, request, pk=None):
        from django.utils import timezone
        a = self.get_object()
        a.is_active = False
        a.unassigned_at = timezone.now()
        a.save()
        return Response({'status': 'released'})


class DriverNoteViewSet(viewsets.ModelViewSet):
    queryset = DriverNote.objects.select_related('driver_profile__contact')
    serializer_class = DriverNoteSerializer
    filterset_fields = ['driver_profile', 'category']
    ordering_fields = ['created_at']
