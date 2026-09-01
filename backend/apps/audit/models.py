from django.db import models


class AuditLog(models.Model):
    class Action(models.TextChoices):
        CREATE = 'create', 'Create'
        UPDATE = 'update', 'Update'
        DELETE = 'delete', 'Delete'
        VIEW = 'view', 'View'
        LOGIN = 'login', 'Login'
        LOGOUT = 'logout', 'Logout'
        EXPORT = 'export', 'Export'

    class Priority(models.TextChoices):
        INFO = 'info', 'Info'
        WARNING = 'warning', 'Warning'
        CRITICAL = 'critical', 'Critical'

    user = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='audit_logs')
    action = models.CharField(max_length=10, choices=Action.choices)
    priority = models.CharField(max_length=10, choices=Priority.choices, default=Priority.INFO)
    resource_type = models.CharField(max_length=100, blank=True, help_text='Model name or API path')
    resource_id = models.CharField(max_length=100, blank=True)
    method = models.CharField(max_length=10, blank=True)
    path = models.CharField(max_length=500, blank=True)
    details = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    status_code = models.IntegerField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['action']),
            models.Index(fields=['resource_type']),
            models.Index(fields=['priority']),
        ]

    def save(self, *args, **kwargs):
        """Auto-assign priority based on action and status code if not set."""
        if not self.priority:
            self.priority = self._compute_priority()
        super().save(*args, **kwargs)

    def _compute_priority(self):
        """Determine priority level: failed logins are warnings, deletes/5xx are critical."""
        status = self.status_code or 0

        # Failed login attempt (401/403 on auth path)
        if self.action == self.Action.LOGIN and status in (400, 401, 403):
            return self.Priority.WARNING

        # Server errors (5xx) are critical
        if status >= 500:
            return self.Priority.CRITICAL

        # Deletes with server error or 4xx failure are critical
        if self.action == self.Action.DELETE and status >= 400:
            return self.Priority.CRITICAL

        # Any 4xx error on write operations is a warning
        if status >= 400 and self.action in (self.Action.CREATE, self.Action.UPDATE, self.Action.DELETE, self.Action.LOGIN):
            return self.Priority.WARNING

        return self.Priority.INFO

    def __str__(self):
        return f'{self.action} {self.resource_type} by {self.user} at {self.timestamp}'
