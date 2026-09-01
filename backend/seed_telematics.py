"""Seed telematics devices, trips, and alerts for the acme tenant."""
import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

import django
django.setup()

from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from django_tenants.utils import tenant_context
from apps.tenants.models import Tenant
from apps.vehicles.models import Vehicle
from apps.contacts.models import Contact
from apps.telematics.models import (
    TelematicsDevice, Trip, VehicleLocation,
    TelematicsAlert, GeofenceEvent,
)


def run():
    tenant = Tenant.objects.get(schema_name='acme')
    with tenant_context(tenant):
        vehicles = list(Vehicle.objects.all()[:5])
        drivers = list(Contact.objects.filter(contact_type='driver')[:3])
        now = timezone.now()

        # ── Devices ─────────────────────────────────────────
        device_specs = [
            ('GEOTAB-001', 'geotab', '356938035643809', 80),
            ('SAMSARA-002', 'samsara', '356938035643810', 80),
            ('MOTIVE-003', 'keeptruckin', '356938035643811', 80),
            ('GENERIC-004', 'generic', '356938035643812', None),
        ]
        devices = []
        for i, (serial, provider, imei, speed_limit) in enumerate(device_specs):
            dev = TelematicsDevice.objects.filter(serial_number=serial).first()
            if dev:
                devices.append(dev)
                continue
            dev = TelematicsDevice.objects.create(
                vehicle=vehicles[i] if i < len(vehicles) else None,
                serial_number=serial,
                provider=provider,
                imei=imei,
                status='active',
                speed_limit=speed_limit,
                last_latitude=40.7128 + i * 0.05,
                last_longitude=-74.006 + i * 0.03,
                last_heading=45 + i * 30,
                last_speed=[0, 55, 72, 0][i],
                last_ignition_on=True,
                last_reported_at=now - timedelta(minutes=[5, 1, 2, 40][i]),
            )
            devices.append(dev)
            print(f'  Created device: {serial} -> {dev.vehicle.display_name if dev.vehicle else "unassigned"}')

        # ── Vehicle locations (ping history) ─────────────
        for dev in devices:
            if not dev.vehicle:
                continue
            for step in range(20):
                t = now - timedelta(minutes=20 - step)
                VehicleLocation.objects.create(
                    device=dev,
                    vehicle=dev.vehicle,
                    latitude=40.7128 + (step * 0.003),
                    longitude=-74.006 + (step * 0.004),
                    heading=dev.last_heading or 0,
                    speed=dev.last_speed,
                    ignition_on=True,
                    recorded_at=t,
                )
        print('  Created location pings')

        # ── Trips ──────────────────────────────────────────
        for i, dev in enumerate(devices[:3]):
            if not dev.vehicle:
                continue
            trip = Trip.objects.create(
                vehicle=dev.vehicle,
                driver=drivers[i] if i < len(drivers) else None,
                device=dev,
                status='completed' if i > 0 else 'active',
                start_latitude=40.7128,
                start_longitude=-74.006,
                start_address='123 Main St, New York, NY',
                start_odometer=50000 + i * 100,
                started_at=now - timedelta(hours=3 - i),
                end_latitude=40.7589 if i > 0 else None,
                end_longitude=-73.9851 if i > 0 else None,
                end_address='Times Square, NY' if i > 0 else '',
                end_odometer=50012.5 if i > 0 else None,
                ended_at=now - timedelta(hours=2 - i) if i > 0 else None,
                distance=12.5 if i > 0 else 0,
                duration_minutes=45 if i > 0 else 0,
                max_speed=65 if i > 0 else None,
                idle_minutes=5 if i > 0 else 0,
                harsh_braking_events=1 if i == 1 else 0,
                harsh_acceleration_events=0,
            )
            print(f'  Created trip: {trip.id} -> {trip.vehicle.display_name}')

        # ── Alerts ─────────────────────────────────────────
        alert_specs = [
            (TelematicsAlert.AlertType.SPEEDING, TelematicsAlert.Severity.WARNING,
             'Speed 92 exceeds limit 80', 92, 80),
            (TelematicsAlert.AlertType.HARSH_BRAKING, TelematicsAlert.Severity.WARNING,
             'Harsh braking detected at 35 km/h', None, None),
            (TelematicsAlert.AlertType.IDLE, TelematicsAlert.Severity.INFO,
             'Vehicle idle for 25 minutes', None, None),
            (TelematicsAlert.AlertType.DEVICE_OFFLINE, TelematicsAlert.Severity.CRITICAL,
             'Device has not reported in 40 minutes', None, None),
        ]
        for i, (atype, sev, msg, speed, threshold) in enumerate(alert_specs):
            dev = devices[i % len(devices)]
            TelematicsAlert.objects.create(
                device=dev,
                vehicle=dev.vehicle,
                alert_type=atype,
                severity=sev,
                message=msg,
                latitude=dev.last_latitude,
                longitude=dev.last_longitude,
                speed=speed,
                threshold=threshold,
                triggered_at=now - timedelta(hours=i),
            )
        print(f'  Created {len(alert_specs)} alerts')

        # ── Geofence events ────────────────────────────────
        from apps.locations.models import Location
        from apps.telematics.models import GeofenceEvent
        geofences = Location.objects.filter(is_geofence=True)[:2]
        if not geofences:
            # Create a sample geofence
            gf = Location.objects.create(
                name='NYC Depot Zone',
                type='depot',
                address='123 Main St, New York, NY',
                latitude=40.7128,
                longitude=-74.006,
                is_geofence=True,
                shape='circle',
                radius_meters=500,
                color='#6366f1',
            )
            geofences = [gf]
            print(f'  Created geofence: {gf.name}')

        for i, dev in enumerate(devices[:2]):
            GeofenceEvent.objects.create(
                vehicle=dev.vehicle,
                location=geofences[0],
                event_type='enter' if i == 0 else 'exit',
                latitude=dev.last_latitude,
                longitude=dev.last_longitude,
                occurred_at=now - timedelta(hours=2 - i),
            )
        print(f'  Created {len(devices[:2])} geofence events')

        print('\nTelematics seed complete!')


if __name__ == '__main__':
    run()
