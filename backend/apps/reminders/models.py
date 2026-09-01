from django.db import models


class Reminder(models.Model):
    class TriggerType(models.TextChoices):
        TIME = 'time', 'Time (Months)'
        MILEAGE = 'mileage', 'Mileage'
        ENGINE_HOURS = 'engine_hours', 'Engine Hours'

    class EscalationLevel(models.IntegerChoices):
        NONE = 0, 'None'
        EMAIL_DRIVER = 1, 'Email Driver'
        SMS_MANAGER = 2, 'SMS Manager'
        BLOCK_DISPATCH = 3, 'Block Dispatch'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='reminders')
    title = models.CharField(max_length=200)
    trigger_type = models.CharField(max_length=20, choices=TriggerType.choices, default=TriggerType.TIME)
    trigger_interval = models.IntegerField(default=6, help_text='Every X months / miles / hours')
    last_triggered_value = models.BigIntegerField(default=0)
    next_due_date = models.DateField(null=True, blank=True)
    next_due_mileage = models.BigIntegerField(null=True, blank=True)
    next_due_engine_hours = models.FloatField(null=True, blank=True)
    escalation_level = models.IntegerField(choices=EscalationLevel.choices, default=EscalationLevel.NONE)
    auto_generate_work_order = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['next_due_date', 'next_due_mileage']

    def __str__(self):
        return f'{self.title} – {self.vehicle.display_name}'

    @property
    def is_due(self):
        from django.utils import timezone
        today = timezone.now().date()
        if self.trigger_type == self.TriggerType.TIME and self.next_due_date:
            return self.next_due_date <= today
        if self.trigger_type == self.TriggerType.MILEAGE and self.next_due_mileage:
            return self.vehicle.current_mileage >= self.next_due_mileage
        if self.trigger_type == self.TriggerType.ENGINE_HOURS and self.next_due_engine_hours:
            return self.vehicle.engine_hours >= self.next_due_engine_hours
        return False

    @property
    def is_overdue(self):
        if not self.is_due:
            return False
        from django.utils import timezone
        today = timezone.now().date()
        if self.trigger_type == self.TriggerType.TIME and self.next_due_date:
            return self.next_due_date < today
        return False
