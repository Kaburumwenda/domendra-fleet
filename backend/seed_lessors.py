"""Seed lessors: lessor companies/individuals, contracts, payments, documents."""
import os
import django
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django_tenants.utils import schema_context
from apps.tenants.models import Tenant
from datetime import timedelta
from decimal import Decimal
import random

COUNTRIES = ['United States', 'United Kingdom', 'Kenya', 'Nigeria', 'South Africa', 'Canada', 'Germany', 'UAE']


def fmt_date(d):
    return d.strftime('%Y-%m-%d')


def seed():
    from apps.lessors.models import Lessor, LessorContract, LessorPayment, LessorDocument
    from apps.vehicles.models import Vehicle

    # Clear
    LessorDocument.objects.all().delete()
    LessorPayment.objects.all().delete()
    LessorContract.objects.all().delete()
    Lessor.objects.all().delete()

    today = timezone.now().date()

    # ---- Create Lessors ----
    companies = [
        {'lessor_type': 'company', 'company_name': 'Premier Fleet Leasing Inc.', 'representative_name': 'James Carter',
         'registration_number': 'PFL-2023-001', 'email': 'leasing@premierfleet.com', 'phone': '+1-555-0100',
         'country': 'United States', 'address': '1200 Commerce St, Dallas, TX 75201',
         'tax_id': 'US-TX-458291', 'bank_account': 'BOFA-4410-8823', 'payment_terms': 'Net 30'},
        {'lessor_type': 'company', 'company_name': 'EuroLease GmbH', 'representative_name': 'Hans Mueller',
         'registration_number': 'EL-DE-2019-442', 'email': 'info@eurolease.de', 'phone': '+49-30-555-0142',
         'country': 'Germany', 'address': 'Alexanderplatz 7, 10178 Berlin',
         'tax_id': 'DE-2019-8842', 'bank_account': 'DEUT-1200-5544', 'payment_terms': 'Monthly in advance'},
        {'lessor_type': 'company', 'company_name': 'Nairobi Trucking Partners', 'representative_name': 'Amara Ochieng',
         'registration_number': 'NRL-KE-2021-008', 'email': 'amara@nairobipartners.co.ke', 'phone': '+254-722-100-200',
         'country': 'Kenya', 'address': 'Westlands Rd, Nairobi 00100',
         'tax_id': 'KE-PIN-A00888421', 'bank_account': 'KCB-001-2233', 'payment_terms': 'Net 15'},
        {'lessor_type': 'company', 'company_name': 'Gulf Commercial Vehicles LLC', 'representative_name': 'Khalid Al Mansouri',
         'registration_number': 'GCV-AE-2020-100', 'email': 'khalid@gulfcv.ae', 'phone': '+971-4-555-8800',
         'country': 'UAE', 'address': 'Sheikh Zayed Rd, Dubai 0001',
         'tax_id': 'AE-TRN-100456789', 'bank_account': 'FAB-DXB-6610', 'payment_terms': 'Quarterly in advance'},
    ]

    individuals = [
        {'lessor_type': 'individual', 'first_name': 'Robert', 'last_name': 'Sullivan', 'national_id': 'ID-US-8942',
         'email': 'rsullivan@gmail.com', 'phone': '+1-555-0144', 'country': 'Canada', 'address': '45 King St W, Toronto'},
        {'lessor_type': 'individual', 'first_name': 'Sarah', 'middle_name': 'J.', 'last_name': 'Nakamura', 'national_id': 'ID-988231',
         'email': 's.nakamura@gmail.com', 'phone': '+1-555-0188', 'country': 'United States', 'address': '910 Pine Ave, San Francisco'},
        {'lessor_type': 'individual', 'first_name': 'Liam', 'last_name': 'O\'Brien', 'national_id': 'IE-721044',
         'email': 'liam.obrien@mail.ie', 'phone': '+353-1-555-0102', 'country': 'United Kingdom', 'address': '12 Grafton St, Dublin'},
        {'lessor_type': 'individual', 'first_name': 'Thandi', 'last_name': 'Mthembu', 'national_id': 'ZA-601928',
         'email': 'thandi.m@webmail.co.za', 'phone': '+27-11-555-3344', 'country': 'South Africa', 'address': 'Sandton City, Johannesburg'},
    ]

    created_lessors = []
    for i, data in enumerate(companies + individuals):
        data['contract_start_date'] = fmt_date(today - timedelta(days=random.randint(60, 400)))
        data['contract_end_date'] = fmt_date(today + timedelta(days=random.randint(180, 720)))
        data['is_active'] = True
        data['notes'] = random.sample([
            'Reliable partner with flexible terms.',
            'Preferred lessor — high satisfaction.',
            'Specializes in heavy-duty vehicles.',
            'Maintenance included per agreement.',
            'Urgent contact during emergencies.',
        ], 1)[0]
        l = Lessor.objects.create(**data)
        created_lessors.append(l)

    print(f'Created {len(created_lessors)} lessors ({len(companies)} companies, {len(individuals)} individuals)')

    # ---- Create Contracts ----
    statuses_cycle = ['active', 'active', 'active', 'pending', 'active', 'expired', 'active', 'draft']
    created_contracts = []
    for i, lessor in enumerate(created_lessors):
        months_back = random.randint(2, 12)
        start_date = today - timedelta(days=months_back * 30)
        months_duration = random.choice([12, 24, 36, 6, 18])
        end_date = start_date + timedelta(days=months_duration * 30)
        status = statuses_cycle[i % len(statuses_cycle)]
        monthly_rate = Decimal(str(random.choice([1200, 1850, 2200, 3500, 4950, 6200, 8800])))
        contract = LessorContract.objects.create(
            lessor=lessor,
            contract_number=f'CON-{1000 + i}',
            title=f'Lease Agreement {lessor.display_name[:30]}',
            start_date=start_date,
            end_date=end_date,
            status=status,
            monthly_rate=monthly_rate,
            deposit_amount=monthly_rate * Decimal('2'),
            payment_frequency='monthly',
            currency='USD',
            terms='Standard lease agreement. Lessee responsible for insurance and routine maintenance.',
            mileage_limit=random.choice([5000, 8000, 10000, 12000]),
            excess_mileage_rate=Decimal('0.25'),
            insurance_required=True,
            maintenance_responsibility=random.choice(['lessor', 'lessee', 'shared']),
            signed_date=start_date - timedelta(days=2) if status == 'active' else None,
            auto_renew=random.choice([True, False]),
        )
        created_contracts.append(contract)

    print(f'Created {len(created_contracts)} contracts')

    # ---- Create Payments ----
    payment_count = 0
    for contract in created_contracts:
        if contract.status not in ('active', 'expired'):
            continue
        # Generate monthly payment records
        months_elapsed = 0
        c_start = contract.start_date
        c_current = c_start
        while c_current <= today and months_elapsed < 24:
            amount = contract.monthly_rate
            due_date = c_current
            past_due = due_date < today
            if past_due and random.random() > 0.15:
                status = 'paid'
                paid_date = due_date + timedelta(days=random.randint(1, 10))
            elif past_due and random.random() > 0.5:
                status = 'overdue'
                paid_date = None
            else:
                status = 'pending'
                paid_date = None

            LessorPayment.objects.create(
                lessor=contract.lessor,
                contract=contract,
                invoice_number=f'INV-{contract.contract_number}-{c_current.strftime("%Y%m")}',
                amount=amount,
                currency='USD',
                status=status,
                due_date=due_date,
                paid_date=paid_date,
                payment_method='bank_transfer' if status == 'paid' else '',
                reference=f'TXN{random.randint(100000, 999999)}' if status == 'paid' else '',
            )
            payment_count += 1
            months_elapsed += 1
            # advance one month
            c_current = c_current + timedelta(days=30)

    print(f'Created {payment_count} payments')

    # ---- Create Documents ----
    doc_types = ['contract', 'insurance', 'registration', 'license', 'tax', 'bank', 'other']
    doc_count = 0
    for lessor in created_lessors:
        # 2-4 documents per lessor
        for _ in range(random.randint(2, 4)):
            dtype = random.choice(doc_types)
            expires = today + timedelta(days=random.choice([-30, 60, 180, 365, 730]))
            LessorDocument.objects.create(
                lessor=lessor,
                document_type=dtype,
                name=f'{dtype.title()} Document - {lessor.display_name[:20]}',
                description=random.choice([
                    'Valid through lease term.',
                    'Requires renewal soon.',
                    'Filed with local authority.',
                    'Securely stored online copy.',
                    'Original on file at office.',
                ]),
                file_url='',
                expires_at=expires,
            )
            doc_count += 1

    print(f'Created {doc_count} documents')

    # ---- Link some vehicles to lessors ----
    try:
        vehicles = list(Vehicle.objects.filter(ownership='lease')[:15])
        if vehicles:
            for i, v in enumerate(vehicles):
                lessor = created_lessors[i % len(created_lessors)]
                v.lessor = lessor
                if not v.lease_start_date:
                    v.lease_start_date = today - timedelta(days=random.randint(30, 300))
                if not v.lease_end_date:
                    v.lease_end_date = today + timedelta(days=random.randint(180, 540))
                if not v.lease_monthly_rate:
                    v.lease_monthly_rate = Decimal(str(random.choice([1200, 1850, 2200, 3500])))
                v.save(update_fields=['lessor', 'lease_start_date', 'lease_end_date', 'lease_monthly_rate'])
            print(f'Linked {len(vehicles)} vehicles to lessors')
        else:
            print('No leased vehicles found to link.')
    except Exception as e:
        print(f'Vehicle linking skipped: {e}')

    print('\n=== Lessors seed complete ===')


if __name__ == '__main__':
    tenant = Tenant.objects.filter(schema_name='acme').first()
    if not tenant:
        print('Acme tenant not found.')
        exit(1)
    with schema_context('acme'):
        seed()
