"""Country-to-currency resolution helpers."""

import re

COUNTRY_CURRENCY = {
    'kenya': 'KES',
    'nigeria': 'NGN',
    'south africa': 'ZAR',
    'ghana': 'GHS',
    'tanzania': 'TZS',
    'uganda': 'UGX',
    'rwanda': 'RWF',
    'ethiopia': 'ETB',
    'united states': 'USD',
    'united states of america': 'USD',
    'usa': 'USD',
    'united kingdom': 'GBP',
    'united kingdom of great britain and northern ireland': 'GBP',
    'canada': 'CAD',
    'australia': 'AUD',
    'japan': 'JPY',
    'china': 'CNY',
    'brazil': 'BRL',
    'germany': 'EUR',
    'france': 'EUR',
    'spain': 'EUR',
    'italy': 'EUR',
    'netherlands': 'EUR',
    'ireland': 'EUR',
    'portugal': 'EUR',
    'belgium': 'EUR',
    'united arab emirates': 'AED',
    'saudi arabia': 'SAR',
    'india': 'INR',
}

DEFAULT_CURRENCY = 'USD'


def _normalize(country: str) -> str:
    """Normalize a country name to a stable lookup key.

    Strips parenthetical qualifiers (e.g. \"United States of America (the)\"
    -> \"united states of america\") and drops everything after a comma
    (e.g. \"Tanzania, the United Republic of\" -> \"tanzania\").
    """
    key = country.strip().lower()
    key = re.sub(r'\s*\([^)]*\)\s*', ' ', key).strip()
    key = key.split(',')[0].strip()
    key = re.sub(r'\s+', ' ', key)
    return key


def country_to_currency(country: str | None) -> str:
    """Return the ISO currency code for a country, defaulting to USD."""
    if not country:
        return DEFAULT_CURRENCY
    return COUNTRY_CURRENCY.get(_normalize(country), DEFAULT_CURRENCY)
