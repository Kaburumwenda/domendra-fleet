"""Seed Battery Management sample data for the acme tenant."""
import os
import sys
import random
from datetime import date, timedelta
from decimal import Decimal

import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

django.setup()

from django_tenants.utils import tenant_context
from apps.tenants.models import Tenant

from apps.batteries.models import (
    Battery, BatteryReading, BatteryMovement, ChargeCycle, BatteryReplacement,
)

BRANDS = ['Optima', 'ACDelco', 'DieHard', 'Interstate', 'Exide', 'Duralast', 'Odyssey', 'Bosch', 'Motorcraft', 'Battle Born']
MODELS = ['RedTop 34', 'YellowTop 34', 'Gold D31A', 'Silver 24', 'Maxx-24', 'PC1200D-M', 'PC1500DT', 'Premium 34', 'AGM H6', 'BB10012']
CHEMISTRIES = [Battery.Chemistry.LEAD_ACID, Battery.Chemistry.AGM, Battery.Chemistry.GEL, Battery.Chemistry.LI_ION, Battery.Chemistry.LiFEPO4]
CONDITIONS = [Battery.Condition.NEW, Battery.Condition.EXCELLENT, Battery.Condition.GOOD, Battery.Condition.FAIR, Battery.Condition.POOR]
POSITIONS = ['Starter', 'Auxiliary', 'House', 'Traction', 'Deep Cycle']
GROUP_CODES = ['24', '27', '31', '34', '65', '78', 'H6', 'H7', 'H8', 'GC2']

TEST_RESULTS = ['pass', 'pass', 'pass', 'marginal', 'fail', 'charge']
CHARGE_METHODS = ['ac', 'dc', 'alternator', 'solar', 'regen']
REPLACEMENT_REASONS = [
    'End of service life', 'Failed load test', 'Sulphation - low capacity',
    'Internal short circuit', 'Cracked case', 'Low electrolyte - excessive drain',
]


def generate_serial(idx: int) -> str:
    return f'BAT-{2026}{idx:05d}'


def seed():
    Battery.objects.all().delete()
    BatteryReading.objects.all().delete()
    BatteryMovement.objects.all().delete()
    ChargeCycle.objects.all().delete()
    BatteryReplacement.objects.all().delete()

    today = date(2026, 8, 11)
    vehicles = []
    from apps.vehicles.models import Vehicle
    vehicles = list(Vehicle.objects.all())
    if not vehicles:
        print('No vehicles found!')
        return

    count = 0
    for i in range(1, 26):
        chem = random.choice(CHEMISTRIES)
        cond = random.choice(CONDITIONS)
        if cond == Battery.Condition.NEW:
            st = random.choice([Battery.Status.IN_STOCK, Battery.Status.SPARE])
        elif cond in (Battery.Condition.POOR, Battery.Condition.DAMAGED):
            st = random.choice([Battery.Status.RETIRED, Battery.Status.IN_STOCK])
        else:
            st = random.choice([Battery.Status.INSTALLED, Battery.Status.IN_STOCK, Battery.Status.SPARE, Battery.Status.CHARGING])

        v = random.choice(vehicles) if st == Battery.Status.INSTALLED else None
        pdate = today - timedelta(days=random.randint(30, 900))
        warr_months = random.choice([12, 18, 24, 36, 48])
        warr_exp = pdate + timedelta(days=warr_months * 30)
        lifespan = random.choice([36, 48, 60, 72])

        price = Decimal(str(random.randint(100, 800)))

        batt = Battery.objects.create(
            serial_number=generate_serial(i),
            brand=random.choice(BRANDS),
            model=random.choice(MODELS),
            part_number=f'PRT-{random.randint(10000, 99999)}',
            chemistry=chem,
            voltage=random.choice([12, 12, 12, 24]),
            capacity_ah=random.choice([35, 50, 65, 75, 80, 100, 125, 150]),
            cca=random.choice([400, 500, 550, 600, 650, 700, 750, 800, 850, 900, 1000]),
            rc_minutes=random.choice([90, 100, 110, 120, 140, 160]),
            condition=cond,
            status=st,
            vehicle=v,
            position=random.choice(POSITIONS) if v else '',
            purchase_price=price,
            purchase_date=pdate,
            warranty_months=warr_months,
            warranty_expiry=warr_exp if warr_exp > today else warr_exp,
            install_date=pdate + timedelta(days=random.randint(1, 30)) if v else None,
            expected_lifespan_months=lifespan,
            group_code=random.choice(GROUP_CODES),
            weight_kg=round(random.uniform(8, 30), 1),
            notes=random.choice(['', '', 'Replaced under warranty', 'OEM battery', 'Fleet standard', '']),
        )
        count += 1

        # Generate readings (1–4 per battery)
        for j in range(random.randint(1, 4)):
            measured = today - timedelta(days=random.randint(1, 200))
            voltage = round(random.uniform(11.2, 13.0), 2)
            BatteryReading.objects.create(
                battery=batt,
                vehicle=v,
                measured_at=measured,
                voltage=voltage,
                specific_gravity=round(random.uniform(1.15, 1.30), 3) if random.random() > 0.5 else None,
                internal_resistance=round(random.uniform(3, 15), 1),
                temperature_c=round(random.uniform(10, 40), 1),
                soc_pct=round(random.uniform(20, 100), 1),
                test_result=random.choice(TEST_RESULTS),
                notes='',
            )

        # Create install movement if installed
        if v:
            BatteryMovement.objects.create(
                battery=batt,
                movement_type=BatteryMovement.MovementType.INSTALL,
                to_vehicle=v,
                to_position=batt.position,
                performed_at=batt.install_date or pdate,
            )

        # Create charge cycles for some batteries
        if st == Battery.Status.CHARGING or chem in (Battery.Chemistry.LI_ION, Battery.Chemistry.LiFEPO4):
            for k in range(random.randint(1, 3)):
                cdate = today - timedelta(days=random.randint(1, 100))
                start_v = round(random.uniform(11.0, 12.2), 2)
                end_v = round(random.uniform(12.5, 13.5), 2)
                ChargeCycle.objects.create(
                    battery=batt,
                    started_at=cdate,
                    completed_at=cdate + timedelta(hours=2),
                    start_voltage=start_v,
                    end_voltage=end_v,
                    energy_kwh=round(random.uniform(0.5, 10), 2),
                    charge_method=random.choice(CHARGE_METHODS),
                )

        # Create a replacement record for some batteries
        if cond in (Battery.Condition.POOR, Battery.Condition.FAIR) or random.random() < 0.15:
            rdate = today + timedelta(days=random.randint(-30, 60))
            BatteryReplacement.objects.create(
                battery=batt,
                vehicle=v,
                scheduled_date=rdate if rdate > today else None,
                completed_date=rdate if rdate <= today else None,
                reason=random.choice(REPLACEMENT_REASONS),
                estimated_cost=Decimal(str(random.randint(100, 600))),
                status=random.choice(['scheduled', 'completed', 'ordered', 'cancelled']) if rdate <= today else 'scheduled',
            )

    print(f'Seeded {count} batteries with readings, movements, cycles, and replacements.')


if __name__ == '__main__':
    tenant = Tenant.objects.get(schema_name='acme')
    with tenant_context(tenant):
        seed()
