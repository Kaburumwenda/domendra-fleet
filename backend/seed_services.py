import os
import django
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django_tenants.utils import schema_context
from apps.tenants.models import Tenant
from datetime import timedelta
import random

def seed():
    from apps.services.models import Service, VendorRating
    from apps.vehicles.models import Vehicle
    from apps.contacts.models import Contact
    from apps.users.models import User

    Service.objects.all().delete()

    vehicles = list(Vehicle.objects.all()[:10])
    vendors = list(Contact.objects.filter(contact_type='vendor')[:5])
    techs = list(User.objects.all()[:3])

    if not vehicles:
        print("No vehicles found.")
        return

    # Create some vendor contacts if none exist
    if not vendors:
        vendor_names = ['FleetFix Garage', 'QuickLube Express', 'BrakeMasters Pro', 'AllTruck Service Center', 'Precision Auto Works']
        for n in vendor_names:
            Contact.objects.create(contact_type='vendor', company_name=n, phone='555-0100', address='Industrial Way', city='Los Angeles', state='CA', is_active=True)
        vendors = list(Contact.objects.filter(contact_type='vendor')[:5])
        print(f"Created {len(vendors)} vendor contacts.")

    types = ['oil_change','tire_rotation','brake_service','inspection','repair','preventive','other']
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

    n = 0
    for i in range(28):
        v = random.choice(vehicles)
        t = random.choice(types)
        vendor = random.choice(vendors) if random.random() > 0.2 else None
        tech = random.choice(techs) if techs and random.random() > 0.3 else None
        days_ago = random.randint(0, 120)
        svc = Service.objects.create(
            vehicle=v, service_type=t,
            description=random.choice(descmap.get(t, ['Service performed'])),
            performed_at=now - timedelta(days=days_ago, hours=random.randint(0, 8)),
            cost=round(random.uniform(45, 2400), 2),
            vendor=vendor,
            technician=tech,
            odometer_reading=random.randint(20000, 320000),
            downtime_hours=round(random.uniform(0, 24), 1) if t in ('repair','brake_service') else round(random.uniform(0, 3), 1),
        )
        n += 1
        # Rate ~60% of vendor services
        if vendor and random.random() > 0.4:
            cr = round(random.uniform(2.5, 5), 1)
            qr = round(random.uniform(3, 5), 1)
            tr = round(random.uniform(2, 5), 1)
            noteopts = [None, 'Fast turnaround, good work.', 'Fair pricing but quality concerns.', 'Excellent service.', 'Would use again.']
            VendorRating.objects.create(
                service=svc, cost_rating=cr, quality_rating=qr, turnaround_rating=tr,
                notes=random.choice(noteopts) or '',
            )

    print(f"Seeded {Service.objects.count()} service records with {VendorRating.objects.count()} ratings.")

if __name__ == '__main__':
    t = Tenant.objects.first()
    if t:
        with schema_context(t.schema_name):
            print(f"Seeding into '{t.schema_name}'...")
            seed()
    else:
        print("No tenant found.")
