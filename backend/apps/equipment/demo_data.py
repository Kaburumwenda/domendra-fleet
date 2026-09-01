"""Shared equipment demo data seeder.
Used by both the seed_equipment.py management script and the API seed_demo action.
"""
import random
from datetime import timedelta
from decimal import Decimal

from django.utils import timezone


def seed_equipment_demo_data(clear=False):
    """Seed demo equipment data for the current tenant schema.

    Args:
        clear: If True, delete all existing equipment data before seeding.

    Returns:
        dict with summary counts.
    """
    from apps.equipment.models import (
        CalibrationRecord, Equipment, EquipmentCategory,
        EquipmentCheckout, EquipmentMeterEntry,
    )
    from apps.contacts.models import Contact
    from apps.vehicles.models import Vehicle

    random.seed(42)
    now = timezone.now()
    today = now.date()

    if clear:
        EquipmentCheckout.objects.all().delete()
        EquipmentMeterEntry.objects.all().delete()
        CalibrationRecord.objects.all().delete()
        Equipment.objects.all().delete()
        EquipmentCategory.objects.all().delete()

    # ── Categories ──
    cat_defs = [
        ('Diagnostic', '#6366f1', 'Diagnostic and testing equipment'),
        ('Safety', '#ef4444', 'Personal protective and safety equipment'),
        ('Communication', '#3b82f6', 'Radios, GPS, and communication gear'),
        ('Load Handling', '#f59e0b', 'Lifting, towing, and load management'),
        ('Cleaning', '#22c55e', 'Cleaning and washing equipment'),
        ('Power Tools', '#8b5cf6', 'Power tools and accessories'),
        ('Measurement', '#0d9488', 'Precision measurement instruments'),
    ]
    cats = {}
    for name, color, desc in cat_defs:
        cat, _ = EquipmentCategory.objects.get_or_create(
            name=name, defaults={'color': color, 'description': desc})
        cats[name] = cat

    # ── Equipment items ──
    # (name, asset#, serial, barcode, category, status, location, hours,
    #  req_cal, cal_interval, price)
    items_data = [
        # ── Diagnostic ──
        ('Compressor Pro', 'CMP-001', 'SN-7821A', 'BAR-1001', 'Diagnostic', 'available', 'Warehouse A', 120, True, 360, 28000),
        ('Multi-Tester V2', 'MT-003', 'SN-3345C', 'BAR-1003', 'Diagnostic', 'in_maintenance', 'Garage 1', 89, True, 180, 15000),
        ('DDS Calibrator K2', 'DDS-006', 'SN-5512F', 'BAR-1006', 'Diagnostic', 'available', 'Warehouse A', 210, True, 270, 45000),
        ('Pressure Gauge Cal', 'PG-009', 'SN-4421I', 'BAR-1009', 'Diagnostic', 'in_use', 'Warehouse A', 65, True, 300, 30000),
        ('Thermal Camera T90', 'TC-011', 'SN-2233K', 'BAR-1011', 'Diagnostic', 'in_maintenance', 'Garage 1', 145, True, 200, 55000),
        ('Scanner Pro M5', 'SP-015', 'SN-7712O', 'BAR-1015', 'Diagnostic', 'in_use', 'Bay 3', 45, True, 150, 18000),
        ('Engine Analyzer X7', 'EA-016', 'SN-8822P', 'BAR-1016', 'Diagnostic', 'available', 'Warehouse A', 32, True, 365, 32000),
        ('OBD2 Scanner Pro', 'OBD-017', 'SN-3391Q', 'BAR-1017', 'Diagnostic', 'available', 'Office', 0, False, 365, 8500),
        ('Tire Pressure Monitor Kit', 'TPM-018', 'SN-5568R', 'BAR-1018', 'Diagnostic', 'available', 'Garage 1', 15, False, 365, 12000),
        ('EMI Leak Detector', 'ELD-019', 'SN-7723S', 'BAR-1019', 'Diagnostic', 'retired', 'Warehouse B', 450, True, 180, 9500),

        # ── Safety ──
        ('Breathing Apparatus', 'BA-004', 'SN-9982D', 'BAR-1004', 'Safety', 'available', 'Office', 12, True, 90, 6500),
        ('Safety Harness X1', 'SH-010', 'SN-6699J', 'BAR-1010', 'Safety', 'in_use', 'Service Area', 0, False, 365, 4500),
        ('Label Printer L30', 'LP-013', 'SN-4455M', 'BAR-1013', 'Safety', 'retired', 'Office', 230, False, 365, 20000),
        ('Fire Extinguisher 10lb', 'FE-020', 'SN-1190T', 'BAR-1020', 'Safety', 'available', 'Garage 1', 0, True, 365, 3500),
        ('First Aid Kit Deluxe', 'FAK-021', 'SN-4456U', 'BAR-1021', 'Safety', 'in_use', 'Service Van', 0, False, 365, 1800),
        ('Safety Goggles Bulk', 'SG-022', 'SN-8890V', 'BAR-1022', 'Safety', 'available', 'Warehouse A', 0, False, 365, 450),
        ('High-Vis Vest Set', 'HV-023', 'SN-2231W', 'BAR-1023', 'Safety', 'available', 'Office', 0, False, 365, 1200),
        ('Spill Containment Kit', 'SC-024', 'SN-6677X', 'BAR-1024', 'Safety', 'in_maintenance', 'Bay 3', 5, True, 180, 5600),
        ('Gas Detector Multi', 'GD-025', 'SN-9901Y', 'BAR-1025', 'Safety', 'available', 'Warehouse A', 28, True, 90, 15000),

        # ── Communication ──
        ('Two-Way Radio Set', 'TWR-008', 'SN-7744H', 'BAR-1008', 'Communication', 'available', 'Office', 0, False, 365, 12000),
        ('GPS Tracker Fleet', 'GPS-026', 'SN-3382Z', 'BAR-1026', 'Communication', 'in_use', 'Field Unit', 0, False, 365, 22000),
        ('Satellite Phone Iridium', 'SAT-027', 'SN-5563AA', 'BAR-1027', 'Communication', 'available', 'Office', 0, False, 365, 4500),
        ('Antenna Booster Kit', 'ANT-028', 'SN-8824AB', 'BAR-1028', 'Communication', 'in_maintenance', 'Bay 3', 120, False, 365, 7800),
        ('Cell Signal Repeater', 'CSR-029', 'SN-1195AC', 'BAR-1029', 'Communication', 'available', 'Warehouse A', 0, False, 365, 12500),

        # ── Load Handling ──
        ('Boom Lift R1', 'BLT-002', 'SN-9921B', 'BAR-1002', 'Load Handling', 'in_use', 'Bay 3', 560, False, 365, 350000),
        ('Work Light 2000', 'WL-005', 'SN-1280E', 'BAR-1005', 'Load Handling', 'in_use', 'Garage 1', 340, False, 365, 8000),
        ('Forklift Extender', 'FE-007', 'SN-6633G', 'BAR-1007', 'Load Handling', 'retired', 'Bay 3', 9800, False, 365, 220000),
        ('Compressor NS-2', 'CMP-012', 'SN-1199L', 'BAR-1012', 'Load Handling', 'available', 'Warehouse A', 78, False, 365, 20500),
        ('Floor Jack F-20', 'FJ-014', 'SN-8866N', 'BAR-1014', 'Load Handling', 'available', 'Garage 1', 160, False, 365, 17000),
        ('Chain Hoist 5T', 'CH-030', 'SN-4477AD', 'BAR-1030', 'Load Handling', 'available', 'Bay 3', 240, False, 365, 28000),
        ('Pallet Truck PT-50', 'PT-031', 'SN-2290AE', 'BAR-1031', 'Load Handling', 'in_use', 'Warehouse A', 89, False, 365, 15500),
        ('Crane Scale 10T', 'CS-032', 'SN-7712AF', 'BAR-1032', 'Load Handling', 'available', 'Bay 3', 45, True, 365, 19000),
        ('Towing Strap Heavy', 'TS-033', 'SN-3389AG', 'BAR-1033', 'Load Handling', 'in_use', 'Service Van', 0, False, 365, 3200),

        # ── Cleaning ──
        ('Pressure Washer Pro', 'PW-034', 'SN-8856AH', 'BAR-1034', 'Cleaning', 'available', 'Garage 1', 210, False, 365, 14500),
        ('Vacuum Truck V-300', 'VT-035', 'SN-2267AI', 'BAR-1035', 'Cleaning', 'in_maintenance', 'Bay 3', 580, False, 365, 28000),
        ('Steam Cleaner SC-150', 'SC-036', 'SN-4498AJ', 'BAR-1036', 'Cleaning', 'available', 'Warehouse A', 95, False, 365, 9800),
        ('Parts Washer Deluxe', 'PW-037', 'SN-7710AK', 'BAR-1037', 'Cleaning', 'available', 'Garage 1', 55, False, 365, 12500),

        # ── Power Tools ──
        ('Impact Wrench 1/2"', 'IW-038', 'SN-1167AL', 'BAR-1038', 'Power Tools', 'in_use', 'Garage 1', 320, False, 365, 4500),
        ('Cordless Drill Set', 'CD-039', 'SN-3394AM', 'BAR-1039', 'Power Tools', 'available', 'Warehouse A', 180, False, 365, 3200),
        ('Angle Grinder 4"', 'AG-040', 'SN-5521AN', 'BAR-1040', 'Power Tools', 'available', 'Garage 1', 240, False, 365, 2800),
        ('Battery Pack Pro', 'BP-041', 'SN-8848AO', 'BAR-1041', 'Power Tools', 'in_maintenance', 'Garage 1', 15, False, 365, 5500),

        # ── Measurement ──
        ('Laser Distance Meter', 'LDM-042', 'SN-2202AP', 'BAR-1042', 'Measurement', 'available', 'Office', 0, True, 365, 8500),
        ('Digital Micrometer Set', 'DM-043', 'SN-6675AQ', 'BAR-1043', 'Measurement', 'available', 'Warehouse A', 0, True, 180, 12000),
        ('Torque Wrench Digital', 'TW-044', 'SN-4493AR', 'BAR-1044', 'Measurement', 'in_use', 'Garage 1', 50, True, 365, 9800),
        ('Infrared Thermometer', 'IRT-045', 'SN-8816AS', 'BAR-1045', 'Measurement', 'available', 'Warehouse A', 12, True, 270, 6500),
        ('Boreoscope HD Camera', 'BC-046', 'SN-1139AT', 'BAR-1046', 'Measurement', 'available', 'Office', 0, False, 365, 15000),
        ('Vibration Analyzer Pro', 'VA-047', 'SN-7762AU', 'BAR-1047', 'Measurement', 'in_use', 'Garage 1', 35, True, 200, 42000),
        ('Alignment Laser Kit', 'AL-048', 'SN-3325AV', 'BAR-1048', 'Measurement', 'available', 'Warehouse A', 0, True, 365, 18500),
        ('Coating Thickness Gauge', 'CT-049', 'SN-5557AW', 'BAR-1049', 'Measurement', 'retired', 'Office', 180, True, 180, 8800),
    ]

    vehicles = list(Vehicle.objects.all()[:10])
    assigned_vehicles = {}
    vehicle_assignable = [
        i for i in items_data
        if i[5] == 'in_use' and i[4] in ('Load Handling', 'Diagnostic', 'Communication')
    ]
    for i, item in enumerate(vehicle_assignable):
        if i < len(vehicles):
            assigned_vehicles[item[1]] = vehicles[i]

    for name, asset, serial, barcode, cat_name, status, location, hours, req_cal, cal_days, price in items_data:
        eq, created = Equipment.objects.get_or_create(
            asset_number=asset,
            defaults={
                'name': name,
                'serial_number': serial,
                'barcode': barcode,
                'category': cats[cat_name],
                'status': status,
                'location': location,
                'current_hours': hours,
                'requires_calibration': req_cal,
                'calibration_interval_days': cal_days,
                'purchase_price': Decimal(str(price)),
                'purchase_date': today - timedelta(days=random.randint(60, 1000)),
                'assigned_vehicle': assigned_vehicles.get(asset),
            }
        )
        if created and req_cal:
            cal_state = random.choice(['ok', 'ok', 'ok', 'due_soon', 'overdue'])
            if cal_state == 'overdue':
                eq.last_calibrated_at = today - timedelta(days=cal_days + random.randint(5, 30))
            elif cal_state == 'due_soon':
                eq.last_calibrated_at = today - timedelta(days=cal_days - random.randint(5, 25))
            else:
                eq.last_calibrated_at = today - timedelta(days=random.randint(10, max(cal_days - 30, 15)))
            eq.next_calibration_due = eq.last_calibrated_at + timedelta(days=cal_days)
            eq.save()

    all_eq = list(Equipment.objects.all())

    # ── Meter entries (2-5 per equipment with hours > 0) ──
    entry_notes = [
        'Routine check', 'Scheduled maintenance reading', 'Pre-trip inspection',
        'Post-service verification', 'Monthly meter log', 'Quarterly check',
    ]
    for eq in all_eq:
        if eq.current_hours and eq.current_hours > 0:
            num_entries = random.randint(2, 5)
            prev_hours = eq.current_hours
            for _ in range(num_entries):
                entry_hours = max(0, prev_hours - random.randint(1, 80))
                days_ago = random.randint(1, 180)
                if not EquipmentMeterEntry.objects.filter(
                    equipment=eq, hours=entry_hours, recorded_at__date=today - timedelta(days=days_ago)
                ).exists():
                    EquipmentMeterEntry.objects.create(
                        equipment=eq,
                        hours=entry_hours,
                        notes=random.choice(entry_notes),
                        recorded_at=now - timedelta(days=days_ago),
                    )
                prev_hours = entry_hours

    # ── Calibration records (varied results) ──
    cal_labs = [
        'Calibration Lab Inc.', 'Precision Instruments Co.', 'TechCal Services',
        'Metrology Solutions LLC', 'Accurate Calibration Center',
    ]
    calibratable = [eq for eq in all_eq if eq.requires_calibration]
    for eq in calibratable:
        num_recs = random.randint(1, 3)
        for j in range(num_recs):
            offset = j * (eq.calibration_interval_days or 365)
            cal_date = (eq.last_calibrated_at or today - timedelta(days=120)) - timedelta(days=offset)
            if not CalibrationRecord.objects.filter(
                equipment=eq, calibrated_at=cal_date
            ).exists():
                result = random.choices(
                    ['pass', 'pass', 'pass', 'pass', 'adjusted', 'fail'],
                    weights=[40, 40, 40, 40, 30, 10],
                )[0]
                CalibrationRecord.objects.create(
                    equipment=eq,
                    calibrated_at=cal_date,
                    calibrated_by=random.choice(cal_labs),
                    result=result,
                    certificate_number=f'CERT-{eq.asset_number}-{random.randint(100, 999)}',
                    notes=f'{result.capitalize()} — {"Annual" if j == 0 else "Interim"} calibration',
                )

    # ── Checkouts ──
    drivers = list(Contact.objects.filter(contact_type='driver')[:8])
    if not drivers:
        drivers = list(Contact.objects.filter(contact_type='driver'))

    checkout_notes = [
        'Assigned for project work', 'Daily field assignment', 'Maintenance support',
        'Inspection task', 'Roadside assistance kit', 'Training session use',
    ]

    checkable = [eq for eq in all_eq if eq.status in ('in_use', 'available')]
    for eq in checkable:
        roll = random.random()
        if roll < 0.30:
            to_driver = random.choice(drivers)
            out_date = now - timedelta(days=random.randint(1, 20))
            expected_return = now + timedelta(days=random.randint(3, 14))
            EquipmentCheckout.objects.create(
                equipment=eq,
                checked_out_to=to_driver,
                expected_return_at=expected_return,
                notes=random.choice(checkout_notes),
            )
            eq.status = 'in_use'
            eq.assigned_to = to_driver
            eq.save(update_fields=['status', 'assigned_to', 'updated_at'])
        elif roll < 0.45:
            to_driver = random.choice(drivers)
            out_date = now - timedelta(days=random.randint(15, 45))
            return_date = out_date + timedelta(days=random.randint(2, 10))
            EquipmentCheckout.objects.create(
                equipment=eq,
                checked_out_to=to_driver,
                expected_return_at=out_date + timedelta(days=7),
                returned_at=return_date,
                notes=random.choice(checkout_notes),
            )
            if random.random() < 0.5:
                eq.assigned_to = to_driver
                eq.save(update_fields=['assigned_to', 'updated_at'])
        elif roll < 0.50:
            to_driver = random.choice(drivers)
            out_date = now - timedelta(days=random.randint(10, 30))
            expected_return = out_date + timedelta(days=random.randint(3, 7))
            EquipmentCheckout.objects.create(
                equipment=eq,
                checked_out_to=to_driver,
                expected_return_at=expected_return,
                notes='Equipment overdue — follow up needed',
            )
            eq.status = 'in_use'
            eq.assigned_to = to_driver
            eq.save(update_fields=['status', 'assigned_to', 'updated_at'])

    # ── Return summary ──
    return {
        'categories': EquipmentCategory.objects.count(),
        'equipment': Equipment.objects.count(),
        'by_status': {
            s: Equipment.objects.filter(status=s).count()
            for s in ['available', 'in_use', 'in_maintenance', 'retired']
        },
        'meter_entries': EquipmentMeterEntry.objects.count(),
        'calibrations': CalibrationRecord.objects.count(),
        'checkouts': EquipmentCheckout.objects.count(),
        'active_checkouts': EquipmentCheckout.objects.filter(returned_at__isnull=True).count(),
        'overdue_checkouts': EquipmentCheckout.objects.filter(
            returned_at__isnull=True, expected_return_at__lt=now
        ).count(),
        'calibration_overdue': Equipment.objects.filter(
            requires_calibration=True, next_calibration_due__lt=today
        ).count(),
        'calibration_due_soon': Equipment.objects.filter(
            requires_calibration=True,
            next_calibration_due__gte=today,
            next_calibration_due__lte=today + timedelta(days=30),
        ).count(),
    }
