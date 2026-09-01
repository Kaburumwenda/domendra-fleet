"""Seed equipment demo data for the acme tenant.

Usage:
    python seed_equipment.py            # add demo data (skip existing asset numbers)
    python seed_equipment.py --clear     # wipe existing equipment data, then seed fresh
"""
import os
import sys

import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
django.setup()

from django_tenants.utils import schema_context


def run(clear=False):
    from apps.equipment.demo_data import seed_equipment_demo_data
    result = seed_equipment_demo_data(clear=clear)

    print('\n✅ Seed complete:')
    print(f"   Categories:       {result['categories']}")
    print(f"   Equipment items:   {result['equipment']}")
    print(f'   Equip by status:')
    for s, cnt in result['by_status'].items():
        print(f'     {s:20s} {cnt}')
    print(f"   Meter entries:     {result['meter_entries']}")
    print(f"   Calibration recs:   {result['calibrations']}")
    print(f"   Checkouts:         {result['checkouts']}")
    print(f"     Active: {result['active_checkouts']}, Overdue: {result['overdue_checkouts']}")
    print(f"   Calibration: {result['calibration_overdue']} overdue, {result['calibration_due_soon']} due soon")


if __name__ == '__main__':
    clear = '--clear' in sys.argv
    with schema_context('acme'):
        run(clear=clear)
