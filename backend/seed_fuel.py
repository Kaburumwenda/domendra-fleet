import os, django, random
from datetime import timedelta

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.utils import timezone
from django_tenants.utils import schema_context
from apps.tenants.models import Tenant
from apps.vehicles.models import Vehicle
from apps.fuel.models import FuelTransaction, ChargingSession, IdlingEvent, FuelCard, FuelBudget


def run():
    tenant = Tenant.objects.get(schema_name="acme")
    with schema_context(tenant.schema_name):
        vehicles = list(Vehicle.objects.all())
        if not vehicles:
            print("No vehicles found. Run seed_data.py first.")
            return

        now = timezone.now()
        print("Creating fuel transactions...")

        # Ford Transit — diesel transactions over 30 days
        ford = vehicles[0]
        for days_ago in range(28, 0, -7):
            tx = FuelTransaction.objects.create(
                vehicle=ford,
                date=now - timedelta(days=days_ago),
                fuel_type="Diesel",
                quantity=round(random.uniform(15, 28), 2),
                unit="gallons",
                total_cost=round(random.uniform(55, 100), 2),
                odometer_reading=ford.current_mileage - (28 - days_ago) * 200,
                station_name="Shell Station " + str(days_ago),
                station_location="Nairobi, Kenya",
            )
            print(f"  Fuel tx: {tx}")

        # Toyota Hilux — gasoline transactions
        toyota = vehicles[1]
        for days_ago in range(25, 0, -5):
            tx = FuelTransaction.objects.create(
                vehicle=toyota,
                date=now - timedelta(days=days_ago),
                fuel_type="Petrol",
                quantity=round(random.uniform(10, 20), 2),
                unit="gallons",
                total_cost=round(random.uniform(35, 75), 2),
                odometer_reading=toyota.current_mileage - (25 - days_ago) * 150,
                station_name="Total Gas Station",
            )
            print(f"  Fuel tx: {tx}")

        # Create a fraud-triggering transaction (wrong fuel: gasoline for diesel truck)
        fraud_tx = FuelTransaction.objects.create(
            vehicle=ford,
            date=now - timedelta(hours=2),
            fuel_type="Petrol",
            quantity=20,
            unit="gallons",
            total_cost=65,
            station_name="BP Express",
            notes="Suspicious: gasoline in diesel vehicle",
        )
        from apps.fuel.services import run_fraud_checks
        alerts = run_fraud_checks(fraud_tx)
        print(f"  Fraud alert tx created: {len(alerts)} alert(s)")

        # Tesla — charging session
        if len(vehicles) >= 3:
            tesla = vehicles[2]
            cs = ChargingSession.objects.create(
                vehicle=tesla,
                start_time=now - timedelta(days=3),
                end_time=now - timedelta(days=3, hours=-4),
                energy_kwh=45.5,
                cost=18.20,
                station_name="ChargePoint - Westlands",
                station_network="chargepoint",
                start_soc=22,
                end_soc=80,
            )
            print(f"  Charging session: {cs}")

        # Idling event
        idling = IdlingEvent.objects.create(
            vehicle=ford,
            start_time=now - timedelta(days=1, hours=3),
            end_time=now - timedelta(days=1),
            fuel_burn_rate=0.6,
            fuel_price_per_gallon=3.75,
            location="Depot Yard",
            notes="Extended idling during loading",
        )
        print(f"  Idling event: {idling}, cost=${idling.cost}")

        # Fuel card (idempotent)
        card, created = FuelCard.objects.get_or_create(
            card_number="4532 1234 5678 9012",
            defaults={"provider": "WEX", "card_holder_name": "John Doe", "vehicle": ford},
        )
        print(f"  Fuel card: {card} ({'new' if created else 'exists'})")

        # Fuel budget (fleet-wide for current month, idempotent)
        from datetime import date
        budget, bud_created = FuelBudget.objects.get_or_create(
            scope="fleet",
            target_ref="",
            month=date(now.year, now.month, 1),
            defaults={"budget_amount": 5000},
        )
        print(f"  Fuel budget: {budget} ({'new' if bud_created else 'exists'})")

        # Additional idling event for analytics depth
        idling2 = IdlingEvent.objects.create(
            vehicle=toyota,
            start_time=now - timedelta(days=2, hours=2),
            end_time=now - timedelta(days=2),
            fuel_burn_rate=0.4,
            fuel_price_per_gallon=3.50,
            location="Distribution Center",
            notes="Idling at pickup",
        )
        print(f"  Idling event 2: {idling2}, cost=${idling2.cost}")

        # Additional charging session
        if len(vehicles) >= 3:
            cs2 = ChargingSession.objects.create(
                vehicle=vehicles[2],
                start_time=now - timedelta(days=1),
                end_time=now - timedelta(days=1, hours=-2),
                energy_kwh=32.1,
                cost=11.50,
                station_name="EVgo - Karen",
                station_network="evgo",
                start_soc=15,
                end_soc=85,
            )
            print(f"  Charging session 2: {cs2}")

        print("\nPhase 3 fuel seed data complete!")


if __name__ == "__main__":
    run()
