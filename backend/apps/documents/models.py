from django.db import models


class Document(models.Model):
    class DocumentType(models.TextChoices):
        INSURANCE = 'insurance', 'Insurance'
        REGISTRATION = 'registration', 'Registration'
        TITLE = 'title', 'Title'
        INSPECTION = 'inspection', 'Inspection'
        LICENSE = 'license', 'License'
        MEDICAL_CARD = 'medical_card', 'Medical Card'
        WARRANTY = 'warranty', 'Warranty'
        CONTRACT = 'contract', 'Contract'
        PERMIT = 'permit', 'Permit'
        MAINTENANCE = 'maintenance', 'Maintenance Record'
        OTHER = 'other', 'Other'

    vehicle = models.ForeignKey(
        'vehicles.Vehicle', null=True, blank=True, on_delete=models.CASCADE,
        related_name='documents',
    )
    contact = models.ForeignKey(
        'contacts.Contact', null=True, blank=True, on_delete=models.CASCADE,
        related_name='documents',
    )
    document_type = models.CharField(max_length=20, choices=DocumentType.choices, default=DocumentType.OTHER)
    title = models.CharField(max_length=200)
    file = models.FileField(upload_to='documents/')
    file_size = models.BigIntegerField(null=True, blank=True)
    expiry_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    uploaded_by = models.ForeignKey(
        'users.User', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='uploaded_documents',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['document_type']), models.Index(fields=['expiry_date'])]

    def __str__(self):
        return self.title

    @property
    def is_expired(self):
        if not self.expiry_date:
            return False
        from django.utils import timezone
        return self.expiry_date < timezone.now().date()

    @property
    def is_expiring_soon(self):
        if not self.expiry_date:
            return False
        from datetime import timedelta
        from django.utils import timezone
        return timezone.now().date() <= self.expiry_date <= timezone.now().date() + timedelta(days=30)

    @property
    def days_to_expiry(self):
        if not self.expiry_date:
            return None
        from django.utils import timezone
        return (self.expiry_date - timezone.now().date()).days

    @property
    def file_extension(self):
        import os
        return os.path.splitext(self.file.name)[1].lower().lstrip('.') if self.file else ''

    @property
    def file_type_icon(self):
        ext = self.file_extension
        if ext in ('pdf',):
            return 'pdf'
        if ext in ('jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'):
            return 'image'
        if ext in ('doc', 'docx'):
            return 'word'
        if ext in ('xls', 'xlsx', 'csv'):
            return 'excel'
        if ext in ('txt', 'rtf'):
            return 'text'
        return 'other'

    @property
    def file_size_display(self):
        if not self.file_size:
            return '—'
        size = float(self.file_size)
        if size < 1024:
            return f'{int(size)} B'
        if size < 1024 * 1024:
            return f'{size / 1024:.1f} KB'
        if size < 1024 * 1024 * 1024:
            return f'{size / (1024 * 1024):.1f} MB'
        return f'{size / (1024 * 1024 * 1024):.1f} GB'

