from django.db import models
from django.utils import timezone
import json


class Customer(models.Model):
    """A local or foreign customer that rents a vehicle."""

    class CustomerType(models.TextChoices):
        LOCAL = 'local', 'Local'
        FOREIGNER = 'foreigner', 'Foreigner'

    class IDType(models.TextChoices):
        NATIONAL_ID = 'national_id', 'National ID'
        PASSPORT = 'passport', 'Passport'
        DRIVER_LICENSE = 'driver_license', "Driver's License"
        ALIEN_CARD = 'alien_card', 'Alien Card'

    customer_type = models.CharField(max_length=20, choices=CustomerType.choices, default=CustomerType.LOCAL)
    full_name = models.CharField(max_length=200)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=40, blank=True)
    address = models.TextField(blank=True)
    place_name = models.CharField(max_length=300, blank=True, help_text='Google Places place name')
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    country = models.CharField(max_length=80, blank=True, help_text='Country of residence')
    id_type = models.CharField(max_length=20, choices=IDType.choices, default=IDType.NATIONAL_ID)
    id_number = models.CharField(max_length=80)
    driving_license_no = models.CharField(max_length=80, blank=True)
    license_issued_country = models.CharField(max_length=80, blank=True)
    license_expiry = models.DateField(null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    emergency_contact_name = models.CharField(max_length=200, blank=True)
    emergency_contact_phone = models.CharField(max_length=40, blank=True)

    # ── Document images ──
    passport_photo = models.ImageField(upload_to='customers/', null=True, blank=True)
    id_front_image = models.ImageField(upload_to='customers/', null=True, blank=True)
    id_back_image = models.ImageField(upload_to='customers/', null=True, blank=True)
    driving_license_image = models.ImageField(upload_to='customers/', null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Customer'
        verbose_name_plural = 'Customers'

    def __str__(self) -> str:
        return f'{self.full_name} ({self.get_customer_type_display()})'


class RentalAgreement(models.Model):
    """A signed car hire/rental contract."""

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        ACTIVE = 'active', 'Active'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'
        OVERDUE = 'overdue', 'Overdue'

    class RatePeriod(models.TextChoices):
        DAILY = 'daily', 'Daily'
        WEEKLY = 'weekly', 'Weekly'
        MONTHLY = 'monthly', 'Monthly'
        WEEKEND = 'weekend', 'Weekend'

    agreement_no = models.CharField(max_length=40, unique=True, editable=False)
    customer = models.ForeignKey(Customer, on_delete=models.PROTECT, related_name='agreements')
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.PROTECT, related_name='rental_agreements')
    driver = models.ForeignKey(
        'contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='rental_agreements_as_driver',
        help_text='Assigned driver (optional, from contacts with type "Driver")',
    )
    driver_daily_rate = models.DecimalField(
        max_digits=12, decimal_places=2, default=0,
        help_text='Daily rate paid to the assigned driver',
    )

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    rate_period = models.CharField(max_length=20, choices=RatePeriod.choices, default=RatePeriod.DAILY)
    daily_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    monthly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekend_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    pickup_location = models.CharField(max_length=200, blank=True)
    dropoff_location = models.CharField(max_length=200, blank=True)
    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    actual_return_datetime = models.DateTimeField(null=True, blank=True)

    # Add-ons
    insurance_type = models.CharField(max_length=40, blank=True, help_text='CDW, Third-Party, Comprehensive, etc.')
    insurance_premium = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    gps_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    child_seat_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    additional_driver_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    delivery_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Discounts & Damage Deposits
    discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, help_text='Percentage 0–100')
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    security_deposit = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    damage_deposit = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Mileage
    free_mileage = models.PositiveIntegerField(default=0, help_text='Free km allowed')
    excess_mileage_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Per extra km')
    start_mileage = models.FloatField(null=True, blank=True)
    end_mileage = models.FloatField(null=True, blank=True)

    # Fuel
    class FuelPolicy(models.TextChoices):
        FULL_TO_FULL = 'full_full', 'Full to Full'
        PREPAID = 'prepaid', 'Prepaid'
        HALF_TANK = 'half_tank', 'Half Tank'

    fuel_policy = models.CharField(max_length=20, choices=FuelPolicy.choices, default=FuelPolicy.FULL_TO_FULL)
    start_fuel_level = models.CharField(max_length=20, blank=True, default='full')
    end_fuel_level = models.CharField(max_length=20, blank=True)

    # Computed totals cached for fast lookup / reporting
    subtotal = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    discount_total = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    taxes = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)

    notes = models.TextField(blank=True)
    inspection_notes = models.TextField(blank=True, default='')
    terms_and_conditions = models.JSONField(
        default=list, blank=True,
        help_text='Editable list of {id, title, text} clauses for this agreement',
    )
    pdf_file = models.FileField(upload_to='rental-agreements/', null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Rental Agreement'
        verbose_name_plural = 'Rental Agreements'

    def __str__(self) -> str:
        return f'{self.agreement_no} — {self.customer}'

    def save(self, *args, **kwargs):
        if not self.agreement_no:
            from django.utils.timezone import now as _now
            ts = self.created_at or _now()
            self.agreement_no = f'RA-{ts.strftime("%Y%m%d")}-{self.pk or RentalAgreement.objects.count() + 1:04d}'
        super().save(*args, **kwargs)


class RentalPayment(models.Model):
    """A payment recorded against a rental agreement."""

    class PaymentMethod(models.TextChoices):
        MPESA = 'mpesa', 'M-Pesa'
        CASH = 'cash', 'Cash'
        CARD = 'card', 'Card'
        BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'
        CHEQUE = 'cheque', 'Cheque'
        OTHER = 'other', 'Other'

    class Status(models.TextChoices):
        COMPLETED = 'completed', 'Completed'
        PENDING = 'pending', 'Pending'
        FAILED = 'failed', 'Failed'
        REFUNDED = 'refunded', 'Refunded'

    agreement = models.ForeignKey(
        RentalAgreement, on_delete=models.CASCADE, related_name='payments',
    )
    amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    payment_method = models.CharField(
        max_length=20, choices=PaymentMethod.choices, default=PaymentMethod.MPESA,
    )
    reference = models.CharField(
        max_length=100, blank=True,
        help_text='Transaction ref, M-Pesa code, cheque no, etc.',
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.COMPLETED,
    )
    paid_at = models.DateTimeField(default=timezone.now)
    notes = models.TextField(blank=True)
    recorded_by = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-paid_at']
        verbose_name = 'Rental Payment'
        verbose_name_plural = 'Rental Payments'

    def __str__(self) -> str:
        return f'{self.agreement.agreement_no} — {self.amount} ({self.get_payment_method_display()})'


class RentalCharge(models.Model):
    """Line-item charge added to an agreement (e.g.Late return fee, extra driver, cleaning)."""

    class ChargeType(models.TextChoices):
        BASE_RENTAL = 'base_rental', 'Base Rental'
        INSURANCE = 'insurance', 'Insurance'
        GPS = 'gps', 'GPS'
        CHILD_SEAT = 'child_seat', 'Child Seat'
        ADDITIONAL_DRIVER = 'additional_driver', 'Additional Driver'
        DELIVERY = 'delivery', 'Delivery'
        LATE_RETURN = 'late_return', 'Late Return'
        EXCESS_MILEAGE = 'excess_mileage', 'Excess Mileage'
        FUEL_REFILL = 'fuel_refill', 'Fuel Refill'
        CLEANING = 'cleaning', 'Cleaning'
        DAMAGE = 'damage', 'Damage'
        OTHER = 'other', 'Other'

    agreement = models.ForeignKey(RentalAgreement, on_delete=models.CASCADE, related_name='charges')
    charge_type = models.CharField(max_length=30, choices=ChargeType.choices)
    description = models.CharField(max_length=200, blank=True)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    unit_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['id']
        verbose_name = 'Rental Charge'
        verbose_name_plural = 'Rental Charges'


class VehicleDamage(models.Model):
    """Damage inspection recorded at pickup or return."""

    class Severity(models.TextChoices):
        NONE = 'none', 'None'
        MINOR = 'minor', 'Minor'
        MODERATE = 'moderate', 'Moderate'
        SEVERE = 'severe', 'Severe'

    agreement = models.ForeignKey(RentalAgreement, on_delete=models.CASCADE, related_name='damages')
    location = models.CharField(max_length=120, help_text='e.g. Front bumper, Driver door')
    description = models.TextField(blank=True)
    severity = models.CharField(max_length=20, choices=Severity.choices, default=Severity.NONE)
    repair_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    recorded_at = models.DateTimeField(auto_now_add=True)
    photo = models.FileField(upload_to='rental-damages/', null=True, blank=True)

    class Meta:
        ordering = ['recorded_at']
        verbose_name = 'Vehicle Damage'
        verbose_name_plural = 'Vehicle Damages'


class DigitalSignature(models.Model):
    """Captured signature pad data (SVG/PNG data URL) for a party."""

    class PartyType(models.TextChoices):
        CUSTOMER = 'customer', 'Customer'
        COMPANY_REP = 'company_rep', 'Company Representative'

    agreement = models.ForeignKey(RentalAgreement, on_delete=models.CASCADE, related_name='signatures')
    party_type = models.CharField(max_length=20, choices=PartyType.choices, default=PartyType.CUSTOMER)
    signatory_name = models.CharField(max_length=200, blank=True)
    signature_data = models.TextField(help_text='SVG path string or data URL of drawn signature')
    signed_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.CharField(max_length=64, blank=True)

    class Meta:
        ordering = ['signed_at']
        verbose_name = 'Digital Signature'
        verbose_name_plural = 'Digital Signatures'


class VehicleCheck(models.Model):
    """A vehicle extras / accessories check item recorded at pickup or return.

    Stores the status of each accessory/extra (spare wheel, jack, tools, etc.)
    so both parties can confirm what's present at handover.
    """

    class CheckStatus(models.TextChoices):
        PRESENT = 'present', 'Present'
        MISSING = 'missing', 'Missing'
        DAMAGED = 'damaged', 'Damaged'
        N_A = 'n_a', 'N/A'

    class CheckStage(models.TextChoices):
        PICKUP = 'pickup', 'Pickup'
        RETURN = 'return', 'Return'

    # Canonical list of vehicle extras that can be checked
    EXTRAS_CATALOG = [
        ('spare_wheel', 'Spare Wheel'),
        ('jack', 'Jack'),
        ('wheel_spanner', 'Wheel Spanner / Lug Wrench'),
        ('tools', 'Tools (general toolkit)'),
        ('tape_cd_changer', 'Tape / CD Changer'),
        ('first_aid_kit', 'First Aid Kit'),
        ('fire_extinguisher', 'Fire Extinguisher'),
        ('warning_triangle', 'Warning Triangle'),
        ('spare_keys', 'Spare Keys'),
        ('radio', 'Radio / Stereo'),
        ('floor_mats', 'Floor Mats'),
        ('headrests', 'Headrests'),
        ('cargo_cover', 'Cargo Cover / Tonneau'),
        ('wheel_caps', 'Wheel Caps / Hubcaps'),
        ('reflective_jacket', 'Reflective Jacket'),
        ('jumper_cables', 'Jumper Cables'),
        ('torch', 'Torch / Flashlight'),
        ('phone_charger', 'Phone Charger'),
        ('navigation_gps', 'Navigation / GPS Unit'),
        ('baby_seat', 'Baby / Child Seat'),
        ('roof_rack', 'Roof Rack / Bars'),
        ('tow_rope', 'Tow Rope'),
        ('workshop_manual', 'Workshop / Owner Manual'),
        ('spare_fuses', 'Spare Fuses'),
        ('registration_docs', 'Registration / Logbook'),
        ('insurance_docs', 'Insurance / Cover Note'),
        ('license_disc', 'License Disc / Sticker'),
    ]

    agreement = models.ForeignKey(RentalAgreement, on_delete=models.CASCADE, related_name='vehicle_checks')
    item_key = models.CharField(max_length=40, help_text='Key from EXTRAS_CATALOG or custom')
    item_name = models.CharField(max_length=120, help_text='Display name')
    status = models.CharField(max_length=20, choices=CheckStatus.choices, default=CheckStatus.PRESENT)
    stage = models.CharField(max_length=20, choices=CheckStage.choices, default=CheckStage.PICKUP)
    notes = models.CharField(max_length=200, blank=True)
    checked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['item_key', 'stage']
        verbose_name = 'Vehicle Check'
        verbose_name_plural = 'Vehicle Checks'
        unique_together = ('agreement', 'item_key', 'stage')

    def __str__(self) -> str:
        return f'{self.item_name} — {self.get_status_display()} ({self.get_stage_display()})'


class InspectionCheck(models.Model):
    """A vehicle condition inspection item recorded at pickup or return.

    Covers mechanical / electrical / cosmetic checks like headlights, brake
    lights, horn, battery, tires, cleaning, wipers, etc.
    """

    class CheckStatus(models.TextChoices):
        PASS = 'pass', 'Pass'
        FAIL = 'fail', 'Fail'
        WARNING = 'warning', 'Warning'
        N_A = 'n_a', 'N/A'

    # Canonical list of vehicle inspection items
    INSPECTION_CATALOG = [
        ('headlights', 'Headlights'),
        ('brake_lights', 'Brake Lights'),
        ('indicators', 'Indicators / Turn Signals'),
        ('horn', 'Horn'),
        ('battery', 'Battery'),
        ('tires', 'Tires'),
        ('cleaning', 'Vehicle Cleaning'),
        ('wipers', 'Wiper Blades'),
        ('mirrors', 'Mirrors'),
        ('seatbelts', 'Seatbelts'),
        ('engine_oil', 'Engine Oil Level'),
        ('coolant', 'Coolant Level'),
        ('brake_fluid', 'Brake Fluid'),
        ('ac_heater', 'AC / Heater'),
    ]

    agreement = models.ForeignKey(RentalAgreement, on_delete=models.CASCADE, related_name='inspection_checks')
    item_key = models.CharField(max_length=40, help_text='Key from INSPECTION_CATALOG or custom')
    item_name = models.CharField(max_length=120, help_text='Display name')
    status = models.CharField(max_length=20, choices=CheckStatus.choices, default=CheckStatus.PASS)
    notes = models.CharField(max_length=200, blank=True)
    failed_parts = models.JSONField(default=list, blank=True, help_text='List of specific sub-items that failed (e.g. left headlight)')
    checked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['item_key']
        verbose_name = 'Inspection Check'
        verbose_name_plural = 'Inspection Checks'
        unique_together = ('agreement', 'item_key')

    def __str__(self) -> str:
        return f'{self.item_name} — {self.get_status_display()}'


class Invoice(models.Model):
    """An invoice generated from a rental agreement."""

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        SENT = 'sent', 'Sent'
        PAID = 'paid', 'Paid'
        PARTIALLY_PAID = 'partially_paid', 'Partially Paid'
        UNPAID = 'unpaid', 'Unpaid'
        OVERDUE = 'overdue', 'Overdue'
        CANCELLED = 'cancelled', 'Cancelled'

    invoice_no = models.CharField(max_length=40, unique=True, editable=False)
    agreement = models.ForeignKey(
        RentalAgreement, on_delete=models.CASCADE, related_name='invoices',
        null=True, blank=True,
        help_text='Primary agreement for single-agreement invoices; null for multi-agreement consolidated invoices.',
    )
    transfer = models.ForeignKey(
        'transfers.Transfer', on_delete=models.CASCADE, related_name='invoices',
        null=True, blank=True,
        help_text='Linked transfer booking for transfer-generated invoices.',
    )
    agreements = models.JSONField(
        default=list, blank=True,
        help_text='List of {id, agreement_no} for multi-agreement consolidated invoices.',
    )
    customer = models.ForeignKey(
        Customer, on_delete=models.PROTECT, related_name='invoices',
        null=True, blank=True,
        help_text='Linked customer for agreement-based invoices; null for standalone custom invoices.',
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    issue_date = models.DateField(default=timezone.now)
    due_date = models.DateField(null=True, blank=True)
    subtotal = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    discount_total = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    taxes = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    amount_paid = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    balance_due = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    notes = models.TextField(blank=True)
    line_items = models.JSONField(default=list, blank=True, help_text='Snapshot of charges at invoice generation time')
    invoice_to = models.JSONField(
        default=dict, blank=True,
        help_text='Billing recipient details {name, company, address, email, phone} for customized invoices.',
    )
    branding_color = models.CharField(
        max_length=7, default='#0d9488', blank=True,
        help_text='Hex color used to brand the invoice (header, totals, accents).',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Invoice'
        verbose_name_plural = 'Invoices'

    def __str__(self) -> str:
        return f'{self.invoice_no} — {self.customer}'

    def save(self, *args, **kwargs):
        if not self.invoice_no:
            from django.utils.timezone import now as _now
            import re as _re
            ts = self.created_at or _now()
            date_prefix = f'INV-{ts.strftime("%Y%m%d")}-'
            # Find the highest sequence number used today to avoid collisions
            # after deletions (count()-based logic collides when invoices were deleted).
            existing_nos = Invoice.objects.filter(invoice_no__startswith=date_prefix)
            max_seq = 0
            for no in existing_nos.values_list('invoice_no', flat=True):
                m = _re.match(r'INV-\d{8}-(\d{4})', no or '')
                if m:
                    max_seq = max(max_seq, int(m.group(1)))
            seq = max_seq + 1
            # If we have a PK, also ensure it doesn't collide
            if self.pk:
                seq = max(seq, self.pk)
            self.invoice_no = f'{date_prefix}{seq:04d}'
        # Compute balance
        self.balance_due = self.total_amount - self.amount_paid
        super().save(*args, **kwargs)


class VehiclePricing(models.Model):
    """Reusable pricing plan that can apply to a vehicle group or a list of vehicles."""

    class ApplyTo(models.TextChoices):
        GROUP = 'group', 'Group'
        VEHICLES = 'vehicles', 'Specific Vehicles'

    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    apply_to = models.CharField(max_length=20, choices=ApplyTo.choices, default=ApplyTo.GROUP)

    # When apply_to == 'group'
    vehicle_group = models.ForeignKey(
        'vehicles.FleetGroup', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='pricing_plans',
    )
    # When apply_to == 'group' — alternatively a vehicle type category
    vehicle_type = models.ForeignKey(
        'vehicles.VehicleType', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='pricing_plans',
    )
    # When apply_to == 'vehicles' — a list of specific vehicles
    vehicles = models.ManyToManyField(
        'vehicles.Vehicle', blank=True, related_name='pricing_plans',
    )

    # Base rates
    daily_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekend_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    monthly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Per-rate discount %
    daily_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    weekly_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    weekend_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    monthly_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    # Per-rate markup %
    daily_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, help_text='Percentage increase applied to the base daily rate')
    weekly_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, help_text='Percentage increase applied to the base weekly rate')
    weekend_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, help_text='Percentage increase applied to the base weekend rate')
    monthly_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0, help_text='Percentage increase applied to the base monthly rate')

    # Custom rate (e.g. "3-day package", "hourly", etc.)
    custom_rate_label = models.CharField(max_length=80, blank=True, help_text='Label for the custom rate, e.g. "3-Day Package"')
    custom_rate_value = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    custom_rate_days = models.PositiveIntegerField(default=0, help_text='Number of days the custom rate covers')

    # Deposits
    deposit_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='General deposit amount')
    security_deposit = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    damage_deposit = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Mileage
    free_mileage = models.PositiveIntegerField(default=0, help_text='Free miles/km per day (0 = unlimited)')
    excess_mileage_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Tax
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    # Add-on fees
    insurance_premium = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    gps_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    child_seat_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    additional_driver_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    driver_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Per-driver fee')
    delivery_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    prep_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Vehicle preparation / cleaning fee')
    after_hours_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='After-hours pickup/drop-off fee')
    underage_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Young driver surcharge')
    one_way_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Status / validity
    is_active = models.BooleanField(default=True)
    valid_from = models.DateField(null=True, blank=True)
    valid_to = models.DateField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Vehicle Pricing Plan'
        verbose_name_plural = 'Vehicle Pricing Plans'

    def __str__(self) -> str:
        if self.apply_to == self.ApplyTo.GROUP:
            if self.vehicle_type:
                target = self.vehicle_type.name
            elif self.vehicle_group:
                target = self.vehicle_group.name
            else:
                target = 'All Types'
        elif self.apply_to == self.ApplyTo.VEHICLES:
            count = self.vehicles.count()
            target = f'{count} vehicle{"s" if count != 1 else ""}'
        else:
            target = 'All Vehicles'
        return f'{self.name} ({target})'


class DriverHireRate(models.Model):
    """
    Global pricing plan for hiring drivers.

    Defines hourly / daily / weekly / monthly / weekend rates that apply
    to all customers during rental agreement creation, plus per-rate
    discount and markup percentages and flat markup/discount amounts.
    """

    class RatePeriod(models.TextChoices):
        HOURLY = 'hourly', 'Hourly'
        DAILY = 'daily', 'Daily'
        WEEKLY = 'weekly', 'Weekly'
        MONTHLY = 'monthly', 'Monthly'
        WEEKEND = 'weekend', 'Weekend'

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        INACTIVE = 'inactive', 'Inactive'
        EXPIRED = 'expired', 'Expired'

    driver = models.ForeignKey(
        'contacts.Contact', null=True, blank=True, on_delete=models.CASCADE,
        related_name='customer_hire_rates',
        help_text='Optional: rate applies to a specific driver (null = default rate for the customer)',
    )
    name = models.CharField(max_length=150, blank=True, help_text='Plan label, e.g. "Corporate Weekend plan"')
    description = models.TextField(blank=True)
    default_rate_period = models.CharField(
        max_length=20, choices=RatePeriod.choices, default=RatePeriod.DAILY,
    )

    # Base rates the customer pays to hire the driver
    hourly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    daily_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    monthly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekend_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # Per-rate discount % applied to the base rate
    hourly_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    daily_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    weekly_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    monthly_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    weekend_discount_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    # Per-rate markup % added on top of the base rate (the fleet markup for the hire service)
    hourly_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    daily_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    weekly_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    monthly_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    weekend_markup_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    # Effective rates (base × (1 − disc%) × (1 + markup%)) — persisted for analytics & billing
    hourly_effective_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Auto-computed: base × (1 − disc%) × (1 + markup%)')
    daily_effective_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Auto-computed: base × (1 − disc%) × (1 + markup%)')
    weekly_effective_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Auto-computed: base × (1 − disc%) × (1 + markup%)')
    monthly_effective_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Auto-computed: base × (1 − disc%) × (1 + markup%)')
    weekend_effective_rate = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Auto-computed: base × (1 − disc%) × (1 + markup%)')

    # Flat markup amount (same currency as rates) added once to the final charge
    markup_flat_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=0,
        help_text='Flat markup amount added on top of the computed rate (per billing period)',
    )
    # Flat discount amount applied after the percentage discount
    discount_flat_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=0,
        help_text='Flat discount amount subtracted after the percentage discount',
    )

    # Deposits & taxes
    security_deposit = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    # Validity window
    valid_from = models.DateField(null=True, blank=True)
    valid_to = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    is_default = models.BooleanField(
        default=False,
        help_text='Use as the default plan when creating a new hire for this customer',
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Driver Hire Rate'
        verbose_name_plural = 'Driver Hire Rates'
        indexes = [models.Index(fields=['status'])]

    def __str__(self) -> str:
        target = self.driver.full_name if self.driver else 'Any Driver'
        return f'{self.name or target} ({self.get_default_rate_period_display()})'

    PERIODS = ('hourly', 'daily', 'weekly', 'monthly', 'weekend')

    def effective_rate_for(self, period: str) -> 'Decimal':
        """Return the effective (discounted + marked-up) rate for a billing period."""
        from decimal import Decimal as D
        base = D(getattr(self, f'{period}_rate', 0) or 0)
        disc = D(getattr(self, f'{period}_discount_percent', 0) or 0)
        markup = D(getattr(self, f'{period}_markup_percent', 0) or 0)
        return base * (D(1) - disc / D(100)) * (D(1) + markup / D(100))

    def save(self, *args, **kwargs):
        """Auto-compute effective rates before saving."""
        from decimal import Decimal as D, ROUND_HALF_UP
        for period in self.PERIODS:
            eff = self.effective_rate_for(period)
            setattr(self, f'{period}_effective_rate', eff.quantize(D('0.01'), rounding=ROUND_HALF_UP))
        super().save(*args, **kwargs)

    @property
    def is_active(self) -> bool:
        if self.status != self.Status.ACTIVE:
            return False
        from django.utils import timezone
        today = timezone.now().date()
        if self.valid_from and today < self.valid_from:
            return False
        if self.valid_to and today > self.valid_to:
            return False
        return True

    def rate_for(self, period: str) -> 'Decimal':
        """Return the base rate for a billing period (hourly/daily/weekly/monthly/weekend)."""
        from decimal import Decimal
        return Decimal(getattr(self, f'{period}_rate', 0) or 0)

    def discount_percent_for(self, period: str) -> 'Decimal':
        from decimal import Decimal
        return Decimal(getattr(self, f'{period}_discount_percent', 0) or 0)

    def markup_percent_for(self, period: str) -> 'Decimal':
        from decimal import Decimal
        return Decimal(getattr(self, f'{period}_markup_percent', 0) or 0)

    def compute_charge(self, period: str, units: int = 1) -> dict:
        """
        Compute the billed amount for `units` billing periods.

        Uses the effective rate (base × (1 − disc%) × (1 + markup%)) which is
        persisted on save, so billing always reflects the discounted/marked-up amount.
        """
        from decimal import Decimal as D, ROUND_HALF_UP
        base = self.rate_for(period) * D(units)
        disc_pct = self.discount_percent_for(period)
        markup_pct = self.markup_percent_for(period)

        # Effective rate (already computed by save()) × units
        eff_per_unit = D(getattr(self, f'{period}_effective_rate', 0) or 0)
        if eff_per_unit == 0:
            eff_per_unit = self.effective_rate_for(period)
        eff_total = eff_per_unit * D(units)

        # Tax
        tax = eff_total * D(self.tax_percent or 0) / D(100)
        total = eff_total + tax

        # Discount/markup breakdown for reference
        disc_from_pct = base * disc_pct / D(100)
        disc_total = (disc_from_pct + D(self.discount_flat_amount or 0)).quantize(D('0.01'), rounding=ROUND_HALF_UP)
        markup_from_pct = base * markup_pct / D(100)
        markup_total = (markup_from_pct + D(self.markup_flat_amount or 0)).quantize(D('0.01'), rounding=ROUND_HALF_UP)

        return {
            'base': str(base.quantize(D('0.01'), rounding=ROUND_HALF_UP)),
            'effective_rate_per_unit': str(eff_per_unit.quantize(D('0.01'), rounding=ROUND_HALF_UP)),
            'discount_percent': str(disc_pct),
            'discount_amount': str(disc_total),
            'markup_percent': str(markup_pct),
            'markup_amount': str(markup_total),
            'tax_percent': str(self.tax_percent or 0),
            'tax_amount': str(tax.quantize(D('0.01'), rounding=ROUND_HALF_UP)),
            'effective_subtotal': str(eff_total.quantize(D('0.01'), rounding=ROUND_HALF_UP)),
            'total': str(total.quantize(D('0.01'), rounding=ROUND_HALF_UP)),
            'units': units,
        }
