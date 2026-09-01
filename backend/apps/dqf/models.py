from django.db import models
from django.utils import timezone


class DriverQualificationFile(models.Model):
    """Tracks the regulatory Driver Qualification File for a CDL driver."""
    class Status(models.TextChoices):
        INCOMPLETE = 'incomplete', 'Incomplete'
        PENDING = 'pending', 'Pending Review'
        COMPLETE = 'complete', 'Complete'
        EXPIRED = 'expired', 'Expired'
        REJECTED = 'rejected', 'Rejected'

    driver = models.OneToOneField('contacts.Contact', on_delete=models.CASCADE, related_name='dqf', limit_choices_to={'contact_type': 'driver'})
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.INCOMPLETE)
    application_date = models.DateField(null=True, blank=True, help_text='Date driver applied / was hired')
    hire_date = models.DateField(null=True, blank=True)
    review_date = models.DateField(null=True, blank=True, help_text='Annual DQF review date')
    next_review_due = models.DateField(null=True, blank=True)

    road_test_passed = models.BooleanField(default=False)
    road_test_date = models.DateField(null=True, blank=True)
    road_test_examiner = models.CharField(max_length=200, blank=True)

    background_check_passed = models.BooleanField(default=False)
    background_check_date = models.DateField(null=True, blank=True)

    drug_test_passed = models.BooleanField(default=False)
    drug_test_date = models.DateField(null=True, blank=True)

    medical_examiner = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f'DQF – {self.driver}'

    @property
    def completion_pct(self):
        total = len(self._required_items())
        if not total:
            return 0
        done = sum(1 for item in self._required_items() if self._is_item_complete(item))
        return round(done / total * 100)

    def _required_items(self):
        return [
            'application', 'road_test', 'background_check', 'drug_test',
            'mvr_check', 'medical_card', 'license_check',
        ]

    def _is_item_complete(self, item):
        checks = {
            'application': self.application_date,
            'road_test': self.road_test_passed,
            'background_check': self.background_check_passed,
            'drug_test': self.drug_test_passed,
            'mvr_check': self.mvr_checks.filter(status=DqfCheck.Status.CLEARED).exists(),
            'medical_card': self.driver.driver_profile and self.driver.driver_profile.medical_card_expiry and self.driver.driver_profile.medical_card_expiry > timezone.now().date(),
            'license_check': self.driver.driver_profile and self.driver.driver_profile.license_expiry and self.driver.driver_profile.license_expiry > timezone.now().date(),
        }
        return bool(checks.get(item))

    @property
    def is_expired(self):
        if not self.next_review_due:
            return False
        return self.next_review_due < timezone.now().date()


class DqfCheck(models.Model):
    """A required DQF element with its own document + status (MVR, license, medical, etc.)."""
    class CheckType(models.TextChoices):
        APPLICATION = 'application', 'Employment Application'
        ROAD_TEST = 'road_test', 'Road Test'
        BACKGROUND = 'background_check', 'Background Check'
        DRUG_TEST = 'drug_test', 'Pre-employment Drug Test'
        MVR = 'mvr_check', 'Motor Vehicle Record (MVR)'
        MEDICAL = 'medical_card', 'Medical Examiner Certificate'
        LICENSE = 'license_check', 'Commercial License Verification'
        PSP = 'psp', 'Pre-employment Screening Program (PSP)'
        OTHER = 'other', 'Other'

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        CLEARED = 'cleared', 'Cleared'
        FLAGGED = 'flagged', 'Flagged'
        EXPIRED = 'expired', 'Expired'

    dqf = models.ForeignKey(DriverQualificationFile, on_delete=models.CASCADE, related_name='checks')
    check_type = models.CharField(max_length=20, choices=CheckType.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    document = models.ForeignKey('documents.Document', null=True, blank=True, on_delete=models.SET_NULL, related_name='dqf_checks')
    completed_date = models.DateField(null=True, blank=True)
    expiry_date = models.DateField(null=True, blank=True)
    result_notes = models.TextField(blank=True)
    performed_by = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('dqf', 'check_type')
        ordering = ['check_type']

    @property
    def is_expired(self):
        return bool(self.expiry_date) and self.expiry_date < timezone.now().date()

    @property
    def is_complete(self):
        return self.status == self.Status.CLEARED
