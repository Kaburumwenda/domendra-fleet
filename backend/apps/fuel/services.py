"""
Fraud detection service — analyses each FuelTransaction and creates
FuelFraudAlert records for detected anomalies.
"""
from datetime import timedelta
from django.utils import timezone

from .models import FuelFraudAlert, FuelTransaction


VEHICLE_FUEL_MAP: dict[str, set[str]] = {
    # Petrol / Diesel vehicles — expect only their own fuel type.
    'Petrol': {'Petrol'},
    'Diesel': {'Diesel'},
    'LPG': {'LPG'},
    'CNG': {'CNG'},
    'LNG': {'LNG'},
    'Ethanol (E85)': {'Ethanol (E85)'},
    'Flex Fuel': {'Flex Fuel'},
    'Biodiesel': {'Biodiesel'},
    # Electric / Fuel Cell vehicles.
    'Electric': {'Electric'},
    'Fuel Cell (Hydrogen)': {'Fuel Cell (Hydrogen)'},
    # Hybrid vehicles — expect broader compatible fuel types.
    'Hybrid (Petrol)': {'Hybrid (Petrol)', 'Petrol'},
    'Hybrid (Diesel)': {'Hybrid (Diesel)', 'Diesel'},
    'Plug-in Hybrid (Petrol)': {'Plug-in Hybrid (Petrol)', 'Petrol'},
    'Plug-in Hybrid (Diesel)': {'Plug-in Hybrid (Diesel)', 'Diesel'},
    'Mild Hybrid': {'Mild Hybrid', 'Petrol', 'Diesel'},
}

DEFAULT_TANK_CAPACITY = 50  # gallons


def run_fraud_checks(transaction: FuelTransaction) -> list:
    """Run all fraud checks on a transaction. Returns list of created alerts."""
    alerts = []
    alerts.extend(_check_wrong_fuel(transaction))
    alerts.extend(_check_double_fueling(transaction))
    alerts.extend(_check_parked_fueling(transaction))
    alerts.extend(_check_excessive_qty(transaction))
    alerts.extend(_check_off_hours(transaction))
    return alerts


def _create_alert(transaction, alert_type, description, severity='medium'):
    alert, created = FuelFraudAlert.objects.get_or_create(
        transaction=transaction,
        alert_type=alert_type,
        defaults={'description': description, 'severity': severity},
    )
    return alert if created else None


def _check_wrong_fuel(tx: FuelTransaction) -> list:
    vehicle = tx.vehicle
    expected = VEHICLE_FUEL_MAP.get(vehicle.fuel_type, set())
    if tx.fuel_type not in expected:
        return [_create_alert(
            tx,
            FuelFraudAlert.AlertType.WRONG_FUEL,
            f'Vehicle is {vehicle.fuel_type} but fueled with {tx.fuel_type}. '
            f'Expected one of: {", ".join(expected)}.',
            'critical',
        )]
    return []


def _check_double_fueling(tx: FuelTransaction) -> list:
    window_start = tx.date - timedelta(hours=1)
    existing = FuelTransaction.objects.filter(
        vehicle=tx.vehicle,
        date__gte=window_start,
        date__lt=tx.date,
    ).exclude(pk=tx.pk)
    if existing.exists():
        prev = existing.first()
        return [_create_alert(
            tx,
            FuelFraudAlert.AlertType.DOUBLE_FUELING,
            f'Vehicle was fueled {abs((tx.date - prev.date).total_seconds()) / 60:.0f} '
            f'minutes ago at {prev.station_name or "unknown station"}.',
            'high',
        )]
    return []


def _check_parked_fueling(tx: FuelTransaction) -> list:
    vehicle = tx.vehicle
    reasons = []
    if vehicle.status in ('out_of_service', 'retired'):
        reasons.append(f'vehicle is {vehicle.status.replace("_", " ")}')
    if tx.date.weekday() >= 5:  # Saturday or Sunday
        reasons.append('fueling on a weekend')
    if reasons:
        return [_create_alert(
            tx,
            FuelFraudAlert.AlertType.PARKED_FUELING,
            f'Fueling flagged: {"; ".join(reasons)}.',
            'medium',
        )]
    return []


def _check_excessive_qty(tx: FuelTransaction) -> list:
    tank_capacity = getattr(tx.vehicle, 'tank_capacity', None) or DEFAULT_TANK_CAPACITY
    if tx.quantity > tank_capacity * 1.1:  # 10% tolerance
        return [_create_alert(
            tx,
            FuelFraudAlert.AlertType.EXCESSIVE_QTY,
            f'Quantity {tx.quantity} {tx.unit} exceeds estimated tank capacity '
            f'of {tank_capacity} gallons by more than 10%.',
            'medium',
        )]
    return []


def _check_off_hours(tx: FuelTransaction) -> list:
    hour = tx.date.hour
    if hour >= 23 or hour < 5:
        return [_create_alert(
            tx,
            FuelFraudAlert.AlertType.OFF_HOURS,
            f'Fueling at {tx.date.strftime("%H:%M")} (off-hours: 11 PM – 5 AM).',
            'low',
        )]
    return []
