from django.db import models


class NotificationChannel(models.TextChoices):
    pass


class NotificationTemplate(models.Model):
    class Channel(models.TextChoices):
        EMAIL = 'email', 'Email'
        SMS = 'sms', 'SMS'
        IN_APP = 'in_app', 'In-App'
        PUSH = 'push', 'Push'

    name = models.CharField(max_length=100, unique=True)
    channel = models.CharField(max_length=20, choices=Channel.choices, default=Channel.EMAIL)
    event = models.CharField(max_length=100, help_text='Triggering event, e.g. reminder_due, work_order_assigned')
    subject = models.CharField(max_length=300, blank=True, help_text='Email subject / SMS sender line')
    body = models.TextField(help_text='Template body. Supports {{variables}}.')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']
        unique_together = ('name', 'channel')

    def __str__(self):
        return f'{self.name} ({self.channel})'

    def render(self, **context):
        text = self.body
        for key, value in context.items():
            text = text.replace('{{' + key + '}}', str(value))
        subject = self.subject
        for key, value in context.items():
            subject = subject.replace('{{' + key + '}}', str(value))
        return subject, text


class Notification(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        SENT = 'sent', 'Sent'
        DELIVERED = 'delivered', 'Delivered'
        FAILED = 'failed', 'Failed'

    recipient_user = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='notifications')
    recipient_email = models.CharField(max_length=200, blank=True)
    recipient_phone = models.CharField(max_length=50, blank=True)
    channel = models.CharField(max_length=20, choices=NotificationTemplate.Channel.choices, default=NotificationTemplate.Channel.IN_APP)
    event = models.CharField(max_length=100, blank=True)
    subject = models.CharField(max_length=300, blank=True)
    body = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    error_message = models.TextField(blank=True)
    related_object_type = models.CharField(max_length=100, blank=True)
    related_object_id = models.IntegerField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['recipient_user', 'is_read']), models.Index(fields=['event'])]

    def __str__(self):
        return f'{self.event or self.channel} – {self.status}'


class NotificationPreference(models.Model):
    """Per-user opt-in/opt-out for notification channels and events."""
    user = models.OneToOneField('users.User', on_delete=models.CASCADE, related_name='notification_preferences')
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=True)
    in_app_enabled = models.BooleanField(default=True)
    push_enabled = models.BooleanField(default=True)
    muted_events = models.JSONField(default=list, blank=True, help_text='List of event names to suppress')
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'Preferences for {self.user}'
