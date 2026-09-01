from decimal import Decimal

from django.db import models
from django.utils import timezone


class EquipmentCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    color = models.CharField(max_length=7, default='#6366f1')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name_plural = 'Equipment categories'

    def __str__(self):
        return self.name


class Equipment(models.Model):
    class Status(models.TextChoices):
        AVAILABLE = 'available', 'Available'
        IN_USE = 'in_use', 'In Use'
        IN_MAINTENANCE = 'in_maintenance', 'In Maintenance'
        RETIRED = 'retired', 'Retired'

    name = models.CharField(max_length=200)
    category = models.ForeignKey(EquipmentCategory, null=True, blank=True, on_delete=models.SET_NULL, related_name='items')
    asset_number = models.CharField(max_length=50, unique=True)
    serial_number = models.CharField(max_length=100, blank=True)
    barcode = models.CharField(max_length=100, blank=True, db_index=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.AVAILABLE)
    description = models.TextField(blank=True)

    location = models.CharField(max_length=200, blank=True)
    assigned_to = models.ForeignKey(
        'contacts.Contact', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='assigned_equipment', limit_choices_to={'contact_type': 'driver'},
    )
    assigned_vehicle = models.ForeignKey(
        'vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='equipment',
    )

    current_hours = models.FloatField(default=0, help_text='Hour meter reading')
    requires_calibration = models.BooleanField(default=False)
    last_calibrated_at = models.DateField(null=True, blank=True)
    next_calibration_due = models.DateField(null=True, blank=True)
    calibration_interval_days = models.IntegerField(default=365, help_text='Default interval between calibrations')

    purchase_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    purchase_date = models.DateField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        indexes = [models.Index(fields=['status']), models.Index(fields=['category'])]

    def __str__(self):
        return f'{self.name} ({self.asset_number})'

    @property
    def display_name(self):
        return f'{self.name} – {self.asset_number}'

    @property
    def is_checked_out(self):
        return self.checkouts.filter(returned_at__isnull=True).exists()

    @property
    def calibration_overdue(self):
        if not self.requires_calibration or not self.next_calibration_due:
            return False
        return self.next_calibration_due < timezone.now().date()

    @property
    def calibration_due_soon(self):
        if not self.requires_calibration or not self.next_calibration_due:
            return False
        days = (self.next_calibration_due - timezone.now().date()).days
        return 0 <= days <= 30


class EquipmentCheckout(models.Model):
    equipment = models.ForeignKey(Equipment, on_delete=models.CASCADE, related_name='checkouts')
    checked_out_to = models.ForeignKey('contacts.Contact', on_delete=models.PROTECT, related_name='equipment_checkouts')
    checked_out_by = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='equipment_checkouts_issued')
    checked_out_at = models.DateTimeField(auto_now_add=True)
    expected_return_at = models.DateTimeField(null=True, blank=True)
    returned_at = models.DateTimeField(null=True, blank=True)
    returned_to = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='equipment_checkins_received')
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ['-checked_out_at']

    @property
    def is_overdue(self):
        if self.returned_at or not self.expected_return_at:
            return False
        return self.expected_return_at < timezone.now()

    @property
    def duration_hours(self):
        end = self.returned_at or timezone.now()
        return round((end - self.checked_out_at).total_seconds() / 3600, 2)


class EquipmentMeterEntry(models.Model):
    equipment = models.ForeignKey(Equipment, on_delete=models.CASCADE, related_name='meter_entries')
    hours = models.FloatField()
    recorded_at = models.DateTimeField(auto_now_add=True)
    notes = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ['-recorded_at']

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.hours > self.equipment.current_hours:
            self.equipment.current_hours = self.hours
            self.equipment.save(update_fields=['current_hours', 'updated_at'])


class CalibrationRecord(models.Model):
    equipment = models.ForeignKey(Equipment, on_delete=models.CASCADE, related_name='calibration_records')
    calibrated_at = models.DateField()
    calibrated_by = models.CharField(max_length=200, blank=True)
    result = models.CharField(max_length=20, choices=[('pass', 'Pass'), ('fail', 'Fail'), ('adjusted', 'Adjusted')], default='pass')
    certificate_number = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-calibrated_at']

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        super().save(*args, **kwargs)
        if is_new and self.equipment.requires_calibration:
            from datetime import timedelta
            self.equipment.last_calibrated_at = self.calibrated_at
            self.equipment.next_calibration_due = self.calibrated_at + timedelta(days=self.equipment.calibration_interval_days)
            self.equipment.save(update_fields=['last_calibrated_at', 'next_calibration_due', 'updated_at'])
