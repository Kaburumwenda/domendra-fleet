"""Transfer service: point-to-point passenger transport bookings (e.g. airport
hotels, hotel airport, inter-city transfers).

Each transfer records the passenger details, pickup and drop-off locations
(with coordinates for live tracking), assigned vehicle and driver, pricing
and a full lifecycle workflow (draft  scheduled  assigned  en route
completed / cancelled).
"""

from decimal import Decimal

from django.db import models


def _generate_ref(prefix: str = 'TRF'):
    """Generate a unique, human-friendly reference like ``TRF-2026-00001``."""
    from django.utils import timezone
    year = timezone.now().year
    # Count existing records this year to build a sequential number
    qs = Transfer.objects.filter(reference__startswith=f'{prefix}-{year}-')
    seq = qs.count() + 1
    return f'{prefix}-{year}-{seq:05d}'


class Transfer(models.Model):
    """A single transfer booking (one pickup location to one drop-off location,
    optionally with intermediate stops)."""

    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        SCHEDULED = 'scheduled', 'Scheduled'
        ASSIGNED = 'assigned', 'Assigned'
        EN_ROUTE = 'en_route', 'En Route'
        PICKED_UP = 'picked_up', 'Picked Up'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'
        NO_SHOW = 'no_show', 'No Show'

    class ServiceClass(models.TextChoices):
        ECONOMY = 'economy', 'Economy'
        BUSINESS = 'business', 'Business'
        PREMIUM = 'premium', 'Premium'
        LUXURY = 'luxury', 'Luxury'
        VAN = 'van', 'Van / Minibus'
        EXECUTIVE = 'executive', 'Executive'

    class TripType(models.TextChoices):
        ONE_WAY = 'one_way', 'One-Way'
        ROUND_TRIP = 'round_trip', 'Round Trip'
        HOURLY = 'hourly', 'Hourly Hire'

    class PaymentStatus(models.TextChoices):
        UNPAID = 'unpaid', 'Unpaid'
        PARTIAL = 'partial', 'Partially Paid'
        PAID = 'paid', 'Paid'
        REFUNDED = 'refunded', 'Refunded'

    # ── Reference & status ──
    reference = models.CharField(max_length=30, unique=True, editable=False, default=_generate_ref)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    trip_type = models.CharField(max_length=20, choices=TripType.choices, default=TripType.ONE_WAY)
    service_class = models.CharField(max_length=20, choices=ServiceClass.choices, default=ServiceClass.BUSINESS)
    payment_status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.UNPAID)

    # ── Passenger details ──
    passenger_name = models.CharField(max_length=200)
    passenger_email = models.EmailField(blank=True)
    passenger_phone = models.CharField(max_length=40, blank=True)
    passenger_count = models.PositiveSmallIntegerField(default=1, help_text='Number of passengers incl. children')
    luggage_count = models.PositiveSmallIntegerField(default=0, help_text='Number of luggage pieces')
    has_child_seat = models.BooleanField(default=False)
    has_infant_seat = models.BooleanField(default=False)
    passenger_notes = models.TextField(blank=True, help_text='Special requests, accessibility needs, etc.')

    # ── Pickup location ──
    pickup_name = models.CharField(max_length=300, help_text='Place name e.g. "JFK International Airport Terminal 4"')
    pickup_address = models.TextField()
    pickup_lat = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    pickup_lng = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    pickup_datetime = models.DateTimeField()
    pickup_flight_no = models.CharField(max_length=40, blank=True, help_text='Flight / train number for meet-and-greet tracking')

    # ── Drop-off location ──
    dropoff_name = models.CharField(max_length=300, help_text='Place name e.g. "Hilton Garden Inn, Manhattan"')
    dropoff_address = models.TextField()
    dropoff_lat = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    dropoff_lng = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    dropoff_datetime = models.DateTimeField(null=True, blank=True)

    # ── Assignment ──
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='transfers')
    driver = models.ForeignKey('contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL, related_name='transfers', limit_choices_to={'contact_type': 'driver'})

    # ── Pricing ──
    base_fare = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    distance_km = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text='Estimated route distance')
    estimated_duration_min = models.PositiveIntegerField(default=0, help_text='Estimated trip duration in minutes')
    tolls_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    parking_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    meet_greet_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Meet-and-greet service fee')
    waiting_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Waiting-time charges')
    child_seat_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    driver_tip = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, help_text='Sales tax / VAT percentage applied')
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=3, default='USD')

    # ── Round-trip / hourly ──
    return_datetime = models.DateTimeField(null=True, blank=True, help_text='Return pickup time for round-trip bookings')

    # ── Payments ──
    amount_paid = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    payment_method = models.CharField(max_length=30, blank=True, help_text='cash, card, paypal, bank_transfer')
    payment_reference = models.CharField(max_length=120, blank=True, help_text='Transaction reference')

    # ── Tracking ──
    actual_pickup_time = models.DateTimeField(null=True, blank=True)
    actual_dropoff_time = models.DateTimeField(null=True, blank=True)
    driver_current_lat = models.FloatField(null=True, blank=True)
    driver_current_lng = models.FloatField(null=True, blank=True)

    # ── Rating & feedback ──
    rating = models.PositiveSmallIntegerField(null=True, blank=True, help_text='1–5 passenger rating')
    feedback = models.TextField(blank=True)

    notes = models.TextField(blank=True, help_text='Internal notes (not shown to passenger)')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # ── Relations ──

    # Optional link to a recurring/corporate booking (standalone for now)
    recurring_id = models.IntegerField(null=True, blank=True, db_index=True, help_text='ID of recurring schedule if applicable')

    class Meta:
        ordering = ['-pickup_datetime']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['pickup_datetime']),
            models.Index(fields=['vehicle']),
            models.Index(fields=['driver']),
        ]
        verbose_name = 'Transfer'
        verbose_name_plural = 'Transfers'

    def __str__(self):
        return f'{self.reference}  {self.passenger_name}  {self.pickup_name} → {self.dropoff_name}'

    def save(self, *args, **kwargs):
        # Auto-compute total if not explicitly set
        if not self.total_amount:
            self.total_amount = self._calc_total()
        # Auto-compute payment status
        if self.amount_paid >= self.total_amount and self.total_amount > 0:
            self.payment_status = self.PaymentStatus.PAID
        elif self.amount_paid > 0:
            self.payment_status = self.PaymentStatus.PARTIAL
        # Auto-set dropoff datetime from estimated duration
        if not self.dropoff_datetime and self.estimated_duration_min:
            from datetime import timedelta
            self.dropoff_datetime = self.pickup_datetime + timedelta(minutes=int(self.estimated_duration_min))
        super().save(*args, **kwargs)

    def _calc_total(self) -> Decimal:
        """Calculate the grand total from fare components."""
        subtotal = (
            self.base_fare + self.tolls_amount + self.parking_amount +
            self.meet_greet_fee + self.waiting_fee + self.child_seat_fee +
            self.driver_tip + self.tax_amount
        )
        return Decimal(max(0, subtotal - self.discount_amount))

    @property
    def remaining_balance(self) -> Decimal:
        return max(Decimal('0'), self.total_amount - self.amount_paid)

    @property
    def is_upcoming(self) -> bool:
        from django.utils import timezone
        return self.status in (self.Status.DRAFT, self.Status.SCHEDULED, self.Status.ASSIGNED) and self.pickup_datetime > timezone.now()

    @property
    def is_active(self) -> bool:
        return self.status in (self.Status.ASSIGNED, self.Status.EN_ROUTE, self.Status.PICKED_UP)


class TransferStop(models.Model):
    """Intermediate stop for a multi-stop transfer (e.g. airport hotel stop before final destination)."""

    transfer = models.ForeignKey(Transfer, on_delete=models.CASCADE, related_name='stops')
    sequence = models.IntegerField(default=0, help_text='Order of this stop along the route')
    place_name = models.CharField(max_length=300)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    duration_min = models.PositiveIntegerField(default=0, help_text='Planned stop duration in minutes')
    notes = models.CharField(max_length=500, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['sequence']

    def __str__(self):
        return f'Stop {self.sequence}: {self.place_name}'


class TransferDriverOffer(models.Model):
    """Driver offer/quote for a transfer request (multi-driver dispatch model).
    Useful when no vehicle is directly assigned — drivers can bid on transfers.
    """

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ACCEPTED = 'accepted', 'Accepted'
        REJECTED = 'rejected', 'Rejected'
        EXPIRED = 'expired', 'Expired'

    transfer = models.ForeignKey(Transfer, on_delete=models.CASCADE, related_name='driver_offers')
    driver = models.ForeignKey('contacts.Contact', on_delete=models.CASCADE, related_name='transfer_offers', limit_choices_to={'contact_type': 'driver'})
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='transfer_offers')
    quoted_amount = models.DecimalField(max_digits=12, decimal_places=2)
    quoted_eta_min = models.PositiveIntegerField(default=0, help_text='Minutes driver expects to arrive at pickup')
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['quoted_eta_min', 'created_at']
        unique_together = [('transfer', 'driver')]

    def __str__(self):
        return f'{self.driver} → {self.transfer.reference} ({self.status})'
