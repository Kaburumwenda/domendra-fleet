"""Fuel-card provider integration layer.

Each provider exposes a `fetch_transactions(card, since)` method returning a
list of normalized transaction dicts ready to feed into FuelTransaction.
Live API credentials come from the FuelCard (`provider_account_id`, `api_key`)
or settings. Without configured credentials the adapters raise
``NotImplementedError`` so the sync endpoint can surface a clear message rather
than silently no-op.
"""
from __future__ import annotations

import logging
from datetime import datetime
from decimal import Decimal

from django.conf import settings

from .models import FuelCard, FuelTransaction

logger = logging.getLogger(__name__)


def _norm_tx(card, raw: dict) -> dict:
    return {
        'vehicle': card.vehicle_id,
        'fuel_card_id': card.id,
        'date': raw['date'],
        'fuel_type': raw.get('fuel_type', FuelTransaction.FuelType.PETROL),
        'quantity': raw['quantity'],
        'unit': raw.get('unit', FuelTransaction.Unit.GALLONS),
        'total_cost': Decimal(str(raw['total_cost'])),
        'odometer_reading': raw.get('odometer'),
        'station_name': raw.get('station_name', ''),
        'station_location': raw.get('station_location', ''),
        'latitude': raw.get('latitude'),
        'longitude': raw.get('longitude'),
        'provider_transaction_id': raw['provider_transaction_id'],
    }


class WexClient:
    BASE_URL = 'https://api.wexinc.com/v1'

    def __init__(self, card: FuelCard):
        self.card = card

    def fetch_transactions(self, since):
        token = self.card.api_key or settings.WEX_API_TOKEN
        if not token:
            raise NotImplementedError('WEX API credentials not configured. Set the card api_key or WEX_API_TOKEN.')
        import requests
        resp = requests.get(
            f'{self.BASE_URL}/cards/{self.card.provider_account_id}/transactions',
            headers={'Authorization': f'Bearer {token}'},
            params={'from': since.isoformat()},
            timeout=30,
        )
        resp.raise_for_status()
        out = []
        for item in resp.json().get('transactions', []):
            out.append(_norm_tx(self.card, {
                'date': datetime.fromisoformat(item['transactionDate']),
                'quantity': float(item['gallons']),
                'total_cost': item['amount'],
                'odometer': item.get('odometer'),
                'station_name': item.get('merchantName', ''),
                'station_location': item.get('merchantLocation', ''),
                'fuel_type': _map_fuel(item.get('fuelType', '')),
                'provider_transaction_id': str(item['transactionId']),
            }))
        return out


class ComdataClient:
    BASE_URL = 'https://api.comdata.com/v1'

    def __init__(self, card: FuelCard):
        self.card = card

    def fetch_transactions(self, since):
        token = self.card.api_key or settings.COMDATA_API_TOKEN
        if not token:
            raise NotImplementedError('Comdata API credentials not configured.')
        import requests
        resp = requests.get(
            f'{self.BASE_URL}/card/{self.card.provider_account_id}/purchases',
            headers={'Authorization': f'Bearer {token}'},
            params={'startDate': since.date().isoformat()},
            timeout=30,
        )
        resp.raise_for_status()
        out = []
        for item in resp.json().get('data', []):
            out.append(_norm_tx(self.card, {
                'date': datetime.fromisoformat(item['date']),
                'quantity': float(item['quantity']),
                'total_cost': item['amount'],
                'odometer': item.get('odometer'),
                'station_name': item.get('merchant', ''),
                'provider_transaction_id': str(item['id']),
            }))
        return out


class FleetcorClient:
    BASE_URL = 'https://api.fleetcor.com/v1'

    def __init__(self, card: FuelCard):
        self.card = card

    def fetch_transactions(self, since):
        token = self.card.api_key or settings.FLEETCOR_API_TOKEN
        if not token:
            raise NotImplementedError('Fleetcor API credentials not configured.')
        import requests
        resp = requests.get(
            f'{self.BASE_URL}/accounts/{self.card.provider_account_id}/transactions',
            headers={'Authorization': f'Bearer {token}'},
            params={'since': since.isoformat()},
            timeout=30,
        )
        resp.raise_for_status()
        out = []
        for item in resp.json().get('transactions', []):
            out.append(_norm_tx(self.card, {
                'date': datetime.fromisoformat(item['postedAt']),
                'quantity': float(item['volume']),
                'total_cost': item['amount'],
                'station_name': item.get('merchantName', ''),
                'provider_transaction_id': str(item['id']),
            }))
        return out


class BPClient:
    BASE_URL = 'https://api.bpfleet.com/v1'

    def __init__(self, card: FuelCard):
        self.card = card

    def fetch_transactions(self, since):
        token = self.card.api_key or settings.BP_API_TOKEN
        if not token:
            raise NotImplementedError('BP Fuel API credentials not configured.')
        import requests
        resp = requests.get(
            f'{self.BASE_URL}/cards/{self.card.provider_account_id}/transactions',
            headers={'Authorization': f'Bearer {token}'},
            params={'from': since.isoformat()},
            timeout=30,
        )
        resp.raise_for_status()
        out = []
        for item in resp.json().get('items', []):
            out.append(_norm_tx(self.card, {
                'date': datetime.fromisoformat(item['time']),
                'quantity': float(item['litres']) / 3.78541 if item.get('unit') == 'L' else float(item.get('gallons', 0)),
                'total_cost': item['amount'],
                'station_name': item.get('site', ''),
                'provider_transaction_id': str(item['ref']),
            }))
        return out


_CLIENTS = {
    FuelCard.Provider.WEX: WexClient,
    FuelCard.Provider.COMDATA: ComdataClient,
    FuelCard.Provider.FLEETCOR: FleetcorClient,
    FuelCard.Provider.BP: BPClient,
}


def get_client(card: FuelCard):
    cls = _CLIENTS.get(card.provider)
    if not cls:
        raise NotImplementedError(f'No integration adapter for provider {card.provider}.')
    return cls(card)


def _map_fuel(raw: str) -> str:
    r = (raw or '').lower()
    if 'die' in r:
        return FuelTransaction.FuelType.DIESEL
    if 'e85' in r or 'ethanol' in r:
        return FuelTransaction.FuelType.ETHANOL
    if 'elec' in r:
        return FuelTransaction.FuelType.ELECTRIC
    if 'cng' in r:
        return FuelTransaction.FuelType.CNG
    if 'lng' in r:
        return FuelTransaction.FuelType.LNG
    if 'lpg' in r or 'prop' in r or 'propane' in r:
        return FuelTransaction.FuelType.LPG
    if 'hybrid' in r:
        return FuelTransaction.FuelType.HYBRID_PETROL
    if 'flex' in r:
        return FuelTransaction.FuelType.FLEX_FUEL
    if 'biodiesel' in r:
        return FuelTransaction.FuelType.BIODIESEL
    return FuelTransaction.FuelType.PETROL


def sync_card(card: FuelCard) -> dict:
    """Pull recent transactions for a card, dedupe by provider_transaction_id."""
    from django.utils import timezone
    from datetime import timedelta
    from .services import run_fraud_checks

    since = card.last_synced_at or (timezone.now() - timedelta(days=30))
    client = get_client(card)
    transactions = client.fetch_transactions(since)
    created = 0
    skipped = 0
    for raw in transactions:
        ptid = raw.get('provider_transaction_id')
        if ptid and FuelTransaction.objects.filter(fuel_card=card, provider_transaction_id=ptid).exists():
            skipped += 1
            continue
        raw.pop('vehicle', None)
        raw.pop('fuel_card_id', None)
        tx = FuelTransaction.objects.create(vehicle=card.vehicle, fuel_card=card, **raw)
        run_fraud_checks(tx)
        created += 1
    card.last_synced_at = timezone.now()
    card.save(update_fields=['last_synced_at'])
    return {'created': created, 'skipped': skipped, 'provider': card.provider}
