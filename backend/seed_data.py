import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django_tenants.utils import schema_context
from apps.tenants.models import Tenant, Domain
from apps.users.models import User
from apps.billing.models import BillingPlan, TenantSubscription
from apps.vehicles.models import Vehicle, FleetGroup


def run():
    print("Creating billing plans...")
    plans = [
        {"name": "free", "description": "Free Tier", "price": 0,
         "included_requests": 10000, "rate_per_1000_requests": 0.007},
        {"name": "starter", "description": "Starter Plan", "price": 49,
         "included_requests": 50000, "rate_per_1000_requests": 0.005},
        {"name": "pro", "description": "Pro Plan", "price": 199,
         "included_requests": 200000, "rate_per_1000_requests": 0.003},
        {"name": "enterprise", "description": "Enterprise Plan", "price": 499,
         "included_requests": 1000000, "rate_per_1000_requests": 0.001},
    ]
    for p in plans:
        obj, created = BillingPlan.objects.get_or_create(name=p["name"], defaults=p)
        print(f"  Plan {obj.name}: {'created' if created else 'exists'}")

    print("\nCreating demo tenant (acme)...")
    tenant, created = Tenant.objects.get_or_create(
        schema_name="acme",
        defaults={
            "name": "ACME Logistics",
            "email": "admin@acme.com",
            "country": "Kenya",
            "mobile_number": "+254700000000",
            "address": "Nairobi, Kenya",
        },
    )
    if created:
        Domain.objects.create(domain="acme.localhost", tenant=tenant, is_primary=True)
        print(f"  Tenant created: {tenant.name}")
    else:
        print(f"  Tenant exists: {tenant.name}")

    print("\nCreating subscription...")
    sub, created = TenantSubscription.objects.get_or_create(
        tenant=tenant,
        defaults={"plan": BillingPlan.objects.get(name="pro"), "status": "active"},
    )
    print(f"  Subscription: {sub.plan.name} ({'created' if created else 'exists'})")

    print("\nCreating users and sample data in tenant schema...")
    with schema_context(tenant.schema_name):
        if not User.objects.filter(email="manager@acme.com").exists():
            User.objects.create_user(
                email="manager@acme.com",
                password="Manager@12345",
                first_name="John",
                last_name="Doe",
                role="admin",
            )
            print("  Admin created: manager@acme.com / Manager@12345")
        else:
            print("  Admin already exists")

        if not User.objects.filter(email="driver@acme.com").exists():
            User.objects.create_user(
                email="driver@acme.com",
                password="Driver@12345",
                first_name="Jane",
                last_name="Smith",
                role="driver",
            )
            print("  Driver created: driver@acme.com / Driver@12345")
        else:
            print("  Driver already exists")

        group, _ = FleetGroup.objects.get_or_create(
            name="Delivery Fleet",
            defaults={"description": "Primary delivery vehicles"},
        )

        sample_vehicles = [
            {"vin": "1HGCM82633A123456", "license_plate": "KDA 001A",
             "make": "Ford", "model": "Transit", "year": 2022,
             "fuel_type": "ICE", "current_mileage": 45200, "group": group,
             "purchase_price": "45000", "purchase_date": "2022-01-15",
             "useful_life_years": 10, "color": "White"},
            {"vin": "2T1BURHE0JC012345", "license_plate": "KDA 002B",
             "make": "Toyota", "model": "Hilux", "year": 2023,
             "fuel_type": "Hybrid", "current_mileage": 12800, "group": group,
             "purchase_price": "52000", "purchase_date": "2023-03-20",
             "useful_life_years": 12, "color": "Silver"},
            {"vin": "5YJ3E1EA7KF312345", "license_plate": "KEV 003C",
             "make": "Tesla", "model": "Model 3", "year": 2023,
             "fuel_type": "EV", "current_mileage": 8700, "group": group,
             "purchase_price": "48000", "purchase_date": "2023-06-10",
             "useful_life_years": 15, "color": "Red",
             "battery_capacity_kwh": 75, "state_of_charge": 82,
             "state_of_health": 99},
        ]
        for v in sample_vehicles:
            obj, created = Vehicle.objects.get_or_create(
                vin=v["vin"], defaults=v,
            )
            if created:
                print(f"  Vehicle created: {obj.display_name}")

    print("\nSeed data complete!")
    print("\nLogin credentials:")
    print("  Admin:   manager@acme.com / Manager@12345")
    print("  Driver:  driver@acme.com / Driver@12345")
    print("  Tenant:  acme")


if __name__ == "__main__":
    run()
