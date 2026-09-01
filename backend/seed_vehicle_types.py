"""Seed built-in VehicleType collection into the acme tenant schema.

Idempotent — existing types with the same name are skipped (get_or_create).

Usage:
    $env:DJANGO_SETTINGS_MODULE='config.settings'
    python manage.py tenant_command runscript seed_vehicle_types --schema=acme

… or run directly:
    python seed_vehicle_types.py
"""

import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django_tenants.utils import schema_context
from apps.tenants.models import Tenant
from apps.vehicles.models import VehicleType


# Built-in vehicle type collection — a comprehensive list of common
# vehicle types used in fleet management. Each entry maps to a
# VehicleType(name, icon, color, passenger / cargo capacities, sort_order).
VEHICLE_TYPE_SEED = [
    {
        "name": "Sedan",
        "description": "Standard 4-door passenger car with a separate trunk.",
        "icon": "mdi-car-side",
        "color": "#6366f1",
        "passenger_capacity": 5,
        "cargo_capacity_kg": 400,
        "sort_order": 10,
    },
    {
        "name": "SUV",
        "description": "Sport Utility Vehicle — higher ground clearance, 4WD/AWD, spacious cabin.",
        "icon": "mdi-car-estate",
        "color": "#22c55e",
        "passenger_capacity": 7,
        "cargo_capacity_kg": 800,
        "sort_order": 20,
    },
    {
        "name": "Mini-van",
        "description": "Compact van optimized for passenger transport with sliding doors.",
        "icon": "mdi-van-passenger",
        "color": "#f59e0b",
        "passenger_capacity": 8,
        "cargo_capacity_kg": 600,
        "sort_order": 30,
    },
    {
        "name": "Van",
        "description": "Full-size van for cargo or large group transport.",
        "icon": "mdi-van-utility",
        "color": "#06b6d4",
        "passenger_capacity": 12,
        "cargo_capacity_kg": 1000,
        "sort_order": 40,
    },
    {
        "name": "Pickup Truck",
        "description": "Light-duty truck with an open cargo bed — ideal for mixed duty.",
        "icon": "mdi-pickup-truck",
        "color": "#10b981",
        "passenger_capacity": 5,
        "cargo_capacity_kg": 1200,
        "sort_order": 50,
    },
    {
        "name": "Hatchback",
        "description": "Compact car with a rear door that swings upward for a combined cargo area.",
        "icon": "mdi-car-hatchback",
        "color": "#ec4899",
        "passenger_capacity": 5,
        "cargo_capacity_kg": 300,
        "sort_order": 60,
    },
    {
        "name": "Coupe",
        "description": "Two-door sporty car — fixed roof and limited rear-seat space.",
        "icon": "mdi-car-sports",
        "color": "#ef4444",
        "passenger_capacity": 4,
        "cargo_capacity_kg": 250,
        "sort_order": 70,
    },
    {
        "name": "Convertible",
        "description": "Open-body car with a retractable or removable roof.",
        "icon": "mdi-car-convertible",
        "color": "#8b5cf6",
        "passenger_capacity": 4,
        "cargo_capacity_kg": 200,
        "sort_order": 80,
    },
    {
        "name": "Bus",
        "description": "Large passenger vehicle for scheduled or charter services.",
        "icon": "mdi-bus",
        "color": "#f97316",
        "passenger_capacity": 45,
        "cargo_capacity_kg": 500,
        "sort_order": 90,
    },
    {
        "name": "Truck",
        "description": "Heavy-duty truck for freight and long-haul logistics.",
        "icon": "mdi-truck-outline",
        "color": "#4f46e5",
        "passenger_capacity": 3,
        "cargo_capacity_kg": 8000,
        "sort_order": 100,
    },
    {
        "name": "Box Truck",
        "description": "Rigid truck with an enclosed cargo box — for furniture, appliances, deliveries.",
        "icon": "mdi-truck",
        "color": "#0ea5e9",
        "passenger_capacity": 2,
        "cargo_capacity_kg": 6000,
        "sort_order": 110,
    },
    {
        "name": "Flatbed",
        "description": "Truck with an open flatbed for oversized or palletized loads.",
        "icon": "mdi-truck-flatbed",
        "color": "#64748b",
        "passenger_capacity": 2,
        "cargo_capacity_kg": 10000,
        "sort_order": 120,
    },
    {
        "name": "Motorbike",
        "description": "Two-wheeled motor vehicle — dispatch and rapid delivery.",
        "icon": "mdi-motorbike",
        "color": "#dc2626",
        "passenger_capacity": 2,
        "cargo_capacity_kg": 50,
        "sort_order": 130,
    },
    {
        "name": "Refrigerated",
        "description": "Insulated truck with refrigeration for perishable goods (cold chain).",
        "icon": "mdi-snowflake",
        "color": "#0284c7",
        "passenger_capacity": 2,
        "cargo_capacity_kg": 5000,
        "sort_order": 140,
    },
    {
        "name": "Crossover",
        "description": "Car-based SUV body with unibody construction — on-road focused.",
        "icon": "mdi-car-estate",
        "color": "#34d399",
        "passenger_capacity": 5,
        "cargo_capacity_kg": 650,
        "sort_order": 15,
    },
    {
        "name": "Wagon",
        "description": "Estate / station wagon — extended roofline for a larger cargo area.",
        "icon": "mdi-car-estate",
        "color": "#fb7185",
        "passenger_capacity": 5,
        "cargo_capacity_kg": 700,
        "sort_order": 25,
    },
    {
        "name": "Tuk Tuk",
        "description": "Three-wheeled passenger vehicle — urban and short-distance trips.",
        "icon": "mdi-rickshaw",
        "color": "#facc15",
        "passenger_capacity": 3,
        "cargo_capacity_kg": 100,
        "sort_order": 135,
    },
    {
        "name": "Tractor Unit",
        "description": "Semi-tractors for articulated haulage of trailers and containers.",
        "icon": "mdi-truck-trailer",
        "color": "#1e293b",
        "passenger_capacity": 2,
        "cargo_capacity_kg": 20000,
        "sort_order": 105,
    },
    {
        "name": "Trailer",
        "description": "Unpowered trailer — coupled to a tractor unit for hauling.",
        "icon": "mdi-truck-trailer",
        "color": "#94a3b8",
        "passenger_capacity": 0,
        "cargo_capacity_kg": 25000,
        "sort_order": 108,
    },
    {
        "name": "Flatbed Trailer",
        "description": "Open-deck trailer for oversized or non-palletized cargo.",
        "icon": "mdi-truck-flatbed",
        "color": "#cbd5e1",
        "passenger_capacity": 0,
        "cargo_capacity_kg": 30000,
        "sort_order": 115,
    },
    {
        "name": "Tail Lift Van",
        "description": "Van equipped with a tail lift for heavy-item loading.",
        "icon": "mdi-van-utility",
        "color": "#38bdf8",
        "passenger_capacity": 3,
        "cargo_capacity_kg": 1500,
        "sort_order": 45,
    },
]


def run():
    """Entry point for Django's runscript or direct invocation."""
    try:
        tenant = Tenant.objects.get(schema_name="acme")
    except Tenant.DoesNotExist:
        print("Tenant 'acme' not found. Run seed_data.py first.")
        return

    with schema_context(tenant.schema_name):
        created = 0
        existing = 0
        print("\nSeeding vehicle types into schema 'acme'...\n")
        for vtype in VEHICLE_TYPE_SEED:
            obj, was_created = VehicleType.objects.get_or_create(
                name=vtype["name"],
                defaults={
                    "description": vtype["description"],
                    "icon": vtype["icon"],
                    "color": vtype["color"],
                    "passenger_capacity": vtype["passenger_capacity"],
                    "cargo_capacity_kg": vtype["cargo_capacity_kg"],
                    "sort_order": vtype["sort_order"],
                    "is_active": True,
                },
            )
            if was_created:
                created += 1
                print(f"  + Created: {obj.name}")
            else:
                existing += 1
                print(f"    Exists:  {obj.name}")

        print(f"\nDone. Created {created} new types — {existing} already existed.")
        print(f"Total vehicle types now: {VehicleType.objects.count()}")


if __name__ == "__main__":
    run()
