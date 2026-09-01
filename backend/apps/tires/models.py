from django.db import models
from django.utils import timezone


class Tire(models.Model):
    class Status(models.TextChoices):
        IN_STOCK = 'in_stock', 'In Stock'
        MOUNTED = 'mounted', 'Mounted'
        SPARE = 'spare', 'Spare'
        RETIRED = 'retired', 'Retired'
        SCRAPPED = 'scrapped', 'Scrapped'

    class Condition(models.TextChoices):
        NEW = 'new', 'New'
        SECOND_HAND = 'second_hand', 'Second Hand'
        RETREADED = 'retreaded', 'Retreaded'
        RECLAIMED = 'reclaimed', 'Reclaimed'
        USED = 'used', 'Used'

    serial_number = models.CharField(max_length=100, unique=True)
    brand = models.CharField(max_length=100, blank=True)
    model = models.CharField(max_length=100, blank=True)
    size = models.CharField(max_length=50, blank=True, help_text='e.g. 11R22.5')
    type = models.CharField(max_length=50, blank=True, help_text='e.g. Steer, Drive, Trailer')

    condition = models.CharField(max_length=20, choices=Condition.choices, default=Condition.NEW)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.IN_STOCK)
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='tires')
    position = models.CharField(max_length=20, blank=True, help_text='e.g. FL_Outer, RR_Inner')

    purchase_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    purchase_date = models.DateField(null=True, blank=True)
    warranty_miles = models.FloatField(null=True, blank=True)
    min_tread_depth = models.FloatField(default=4, help_text='Retread/replace threshold in 32nds of an inch')
    quantity = models.PositiveIntegerField(default=1, help_text='Number of identical tires in stock for this line item')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['status']), models.Index(fields=['vehicle'])]

    def __str__(self):
        return f'{self.serial_number} – {self.brand} {self.size}'

    @property
    def latest_tread_depth(self):
        latest = self.inspections.order_by('-measured_at').first()
        return latest.tread_depth if latest else None

    @property
    def total_miles(self):
        agg = self.inspections.exclude(odometer__isnull=True).aggregate(m=models.Max('odometer'))
        return agg.get('m') or 0

    @property
    def needs_replacement(self):
        depth = self.latest_tread_depth
        return depth is not None and depth <= self.min_tread_depth

    @property
    def last_mount_date(self):
        """Date of the most recent mount movement for this tire."""
        last = self.movements.filter(movement_type=TireMovement.MovementType.MOUNT).order_by('-performed_at').first()
        return last.performed_at if last else None

    @property
    def retired_date(self):
        """Date of the most recent unmount movement that has no subsequent mount."""
        ms = list(
            self.movements
            .filter(movement_type__in=[TireMovement.MovementType.MOUNT, TireMovement.MovementType.UNMOUNT])
            .order_by('performed_at')
            .values('movement_type', 'performed_at')
        )
        if not ms:
            return None
        # If the chronologically last event is a mount, the tire is still in service
        if ms[-1]['movement_type'] == TireMovement.MovementType.MOUNT:
            return None
        # otherwise find the last unmount that isn't followed by a mount
        for i in range(len(ms) - 1, -1, -1):
            if ms[i]['movement_type'] == TireMovement.MovementType.UNMOUNT:
                return ms[i]['performed_at']
        return None


class TireInspection(models.Model):
    tire = models.ForeignKey(Tire, on_delete=models.CASCADE, related_name='inspections')
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='tire_inspections')
    tread_depth = models.FloatField(help_text='Tread depth in 32nds of an inch')
    pressure_psi = models.FloatField(null=True, blank=True)
    odometer = models.FloatField(null=True, blank=True)
    position = models.CharField(max_length=20, blank=True)
    condition = models.CharField(max_length=20, choices=[('good', 'Good'), ('worn', 'Worn'), ('damaged', 'Damaged'), ('ok', 'OK')], default='ok')
    notes = models.TextField(blank=True)
    measured_at = models.DateField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-measured_at']


class TireRotation(models.Model):
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='tire_rotations')
    performed_at = models.DateField(db_index=True)
    rotation_pattern = models.CharField(max_length=50, blank=True, help_text='e.g. Front-to-rear, X-pattern')
    odometer = models.FloatField(null=True, blank=True)
    notes = models.TextField(blank=True)
    swaps = models.JSONField(null=True, blank=True, help_text='Array of swap objects: {tire, from_position, to_position}')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-performed_at']


class TireMovement(models.Model):
    """Mount/unmount/transfer history for a single tire."""
    class MovementType(models.TextChoices):
        MOUNT = 'mount', 'Mount'
        UNMOUNT = 'unmount', 'Unmount'
        TRANSFER = 'transfer', 'Transfer'
        RETREAD = 'retread', 'Retread'

    tire = models.ForeignKey(Tire, on_delete=models.CASCADE, related_name='movements')
    movement_type = models.CharField(max_length=20, choices=MovementType.choices)
    from_vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='tire_movements_from')
    to_vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='tire_movements_to')
    from_position = models.CharField(max_length=20, blank=True)
    to_position = models.CharField(max_length=20, blank=True)
    odometer = models.FloatField(null=True, blank=True)
    notes = models.TextField(blank=True)
    performed_at = models.DateField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-performed_at']
