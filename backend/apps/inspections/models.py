from django.db import models


class InspectionForm(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class InspectionItem(models.Model):
    class ItemType(models.TextChoices):
        PASS_FAIL = 'pass_fail', 'Pass / Fail'
        TEXT = 'text', 'Text'
        NUMBER = 'number', 'Number'
        PHOTO = 'photo', 'Photo'
        SIGNATURE = 'signature', 'Signature'
        CHECKLIST = 'checklist', 'Checklist'

    form = models.ForeignKey(InspectionForm, on_delete=models.CASCADE, related_name='items')
    label = models.CharField(max_length=300)
    item_type = models.CharField(max_length=20, choices=ItemType.choices, default=ItemType.PASS_FAIL)
    is_critical = models.BooleanField(default=False, help_text='Failing this item automatically creates an Issue')
    is_required = models.BooleanField(default=True)
    order = models.IntegerField(default=0)
    help_text = models.CharField(max_length=500, blank=True)

    class Meta:
        ordering = ['order']
        indexes = [models.Index(fields=['form'])]


class InspectionReport(models.Model):
    class Status(models.TextChoices):
        PASS = 'pass', 'Pass'
        FAIL = 'fail', 'Fail'
        CONDITIONAL = 'conditional', 'Conditional'
        DRAFT = 'draft', 'Draft'

    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.CASCADE, related_name='inspections')
    form = models.ForeignKey(InspectionForm, null=True, blank=True, on_delete=models.SET_NULL, related_name='reports')
    driver = models.ForeignKey('users.User', null=True, blank=True, on_delete=models.SET_NULL, related_name='inspections')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    notes = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    odometer_reading = models.BigIntegerField(null=True, blank=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-submitted_at']


class InspectionResponse(models.Model):
    report = models.ForeignKey(InspectionReport, on_delete=models.CASCADE, related_name='responses')
    item = models.ForeignKey(InspectionItem, on_delete=models.CASCADE, related_name='responses')
    value = models.CharField(max_length=500, blank=True)
    photo = models.ImageField(upload_to='inspection-photos/', blank=True, null=True)
    notes = models.TextField(blank=True)
    is_fail = models.BooleanField(default=False)

    class Meta:
        unique_together = ('report', 'item')
