import os
import django
from django.utils import timezone
from django.db import models
from django.db.models import Count, Q

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django_tenants.utils import schema_context
from apps.tenants.models import Tenant

def seed(tenant=None):
    from apps.dispatch.models import Job, RouteStop, VehicleAssignment
    from apps.vehicles.models import Vehicle
    from apps.contacts.models import Contact

    # Clean existing demo jobs (keep schema)
    Job.objects.all().delete()

    drivers = list(Contact.objects.filter(contact_type='driver')[:10])
    vehicles = list(Vehicle.objects.all()[:20])

    if not vehicles:
        print("No vehicles found. Run seed_vehicle_types / create some vehicles first.")
        return

    if not drivers:
        print("No driver contacts found. Run seed_data first.")
        return

    import random
    from datetime import timedelta

    now = timezone.now()

    titles = [
        "Containers → North Hub",
        "Pallets to Riverside",
        "Cold chain to Port",
        "Construction materials to Site B",
        "Hazmat transfer",
        "Bulk grain delivery",
        "Automotive parts run",
        "Pharmaceuticals to depot",
        "Intermodal pickup",
        "Same-day residential",
        "Long-haul interstate",
        "LTL multi-stop route",
        "Cross-dock consolidation",
        "Last-mile urban",
        "Drayage terminal f",
    ]
    pickups = [
        "100 Terminal Way, Long Beach, CA",
        "200 Industrial Blvd, Riverside, CA",
        "315 Harbor Dr, San Pedro, CA",
        "40 Logistics Pkwy, Ontario, CA",
        "55 Rail Yard Rd, Los Angeles, CA",
        "78 Freight Center, Vernon, CA",
        "99 Commerce Cir, Irvine, CA",
        "1 Distribution Dr, Moreno Valley, CA",
        "12 Cross Dock Ave, Fontana, CA",
        "44 Cargo Ct, Carson, CA",
    ]
    dropoffs = [
        "1500 North Hub, Las Vegas, NV",
        "800 Riverside Dr, San Diego, CA",
        "99 Port Terminal, Oakland, CA",
        "Bldg 4 Site B, Phoenix, AZ",
        "Hazmat Facility 7, Tucson, AZ",
        "Grain Elevator 3, Bakersfield, CA",
        "Auto Plant 2, Fremont, CA",
        "Pharma Depot, Sacramento, CA",
        "Intermodal Yard, Reno, NV",
        "Warehouse 22, Salt Lake City, UT",
    ]
    statuses = ['pending','pending','assigned','assigned','in_progress','in_progress','completed','completed','cancelled']
    priorities = ['low','medium','medium','high','urgent']

    for i, title in enumerate(titles):
        st = statuses[i % len(statuses)]
        pri = priorities[i % len(priorities)]
        sched_horizon = random.randint(2, 8)
        scheduled_start_dt = now + timedelta(hours=i - 5)
        scheduled_end_dt = now + timedelta(hours=i - 5 + sched_horizon)
        if st == 'completed':
            # ~60% on-time (actual_end <= scheduled_end), ~40% delayed
            if random.random() < 0.6:
                actual_end_dt = scheduled_end_dt - timedelta(minutes=random.randint(0, 60))
            else:
                actual_end_dt = scheduled_end_dt + timedelta(minutes=random.randint(15, 180))
            actual_start_dt = scheduled_start_dt + timedelta(minutes=random.randint(0, 30))
        elif st == 'in_progress':
            actual_start_dt = now - timedelta(minutes=random.randint(5, 90))
            actual_end_dt = None
        else:
            actual_start_dt = None
            actual_end_dt = None
        job = Job.objects.create(
            title=title,
            vehicle=random.choice(vehicles) if st != 'pending' else None,
            driver=random.choice(drivers) if st != 'pending' else None,
            status=st,
            priority=pri,
            pickup_address=pickups[i % len(pickups)],
            dropoff_address=dropoffs[i % len(dropoffs)],
            pickup_lat=33.75 + random.random()*0.2,
            pickup_lng=-118.25 - random.random()*0.2,
            dropoff_lat=33.55 + random.random()*0.4,
            dropoff_lng=-117.95 - random.random()*0.3,
            scheduled_start=scheduled_start_dt,
            scheduled_end=scheduled_end_dt,
            actual_start=actual_start_dt,
            actual_end=actual_end_dt,
            notes=("On-time window tight." if pri == 'urgent' else ""),
        )
        # Add 2–4 route stops for richness
        nstops = random.randint(2, 4)
        for s in range(nstops):
            RouteStop.objects.create(
                job=job,
                sequence=s + 1,
                address=f"Stop {s+1}: {job.dropoff_address}",
                latitude=33.6 + random.random()*0.3,
                longitude=-118.0 - random.random()*0.3,
                scheduled_arrival=job.scheduled_start + timedelta(hours=s + 1) if st not in ('pending','cancelled') else None,
                actual_arrival=timezone.now() - timedelta(hours=nstops - s) if st == 'completed' else None,
                status=('departed' if st == 'completed' else ('arrived' if st == 'in_progress' and s == 0 else 'pending')),
            )
        if job.vehicle and job.driver and st != 'pending':
            VehicleAssignment.objects.create(
                vehicle=job.vehicle,
                driver=job.driver,
                job=job,
                is_active=(st in ('assigned','in_progress')),
                unassigned_at=None if st in ('assigned','in_progress','pending') else timezone.now() - timedelta(hours=2),
            )

    print(f"Seeded {Job.objects.count()} dispatch jobs with stops and assignments.")

if __name__ == '__main__':
    tenant = Tenant.objects.first()
    if not tenant:
        print("No tenant found.")
    else:
        with schema_context(tenant.schema_name):
            print(f"Seeding into schema '{tenant.schema_name}'...")
            seed(tenant)
