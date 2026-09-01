from django.db import models


class Contact(models.Model):
    class ContactType(models.TextChoices):
        DRIVER = 'driver', 'Driver'
        MECHANIC = 'mechanic', 'Mechanic'
        MANAGER = 'manager', 'Manager'
        VENDOR = 'vendor', 'Vendor'
        INSURANCE_AGENT = 'insurance_agent', 'Insurance Agent'
        TOWING = 'towing', 'Towing Company'

    contact_type = models.CharField(max_length=20, choices=ContactType.choices)
    first_name = models.CharField(max_length=100, blank=True)
    last_name = models.CharField(max_length=100, blank=True)
    company_name = models.CharField(max_length=200, blank=True)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    zip_code = models.CharField(max_length=20, blank=True)
    country = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    photo = models.ImageField(upload_to='drivers/photos/', null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    department = models.CharField(max_length=100, blank=True)
    employee_id = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['first_name', 'last_name']
        indexes = [models.Index(fields=['contact_type'])]

    def __str__(self):
        full = f'{self.first_name} {self.last_name}'.strip()
        return full or self.company_name or f'Contact #{self.pk}'

    @property
    def full_name(self):
        full = f'{self.first_name} {self.last_name}'.strip()
        return full or self.company_name or f'Contact #{self.pk}'


class DriverProfile(models.Model):
    class LicenseClass(models.TextChoices):
        A = 'A', 'Class A'
        B = 'B', 'Class B'
        C = 'C', 'Class C'
        CDL_A = 'CDL-A', 'CDL-A'
        CDL_B = 'CDL-B', 'CDL-B'
        M = 'M', 'Class M'

    class MvrStatus(models.TextChoices):
        CLEAN = 'clean', 'Clean'
        WARNING = 'warning', 'Warning'
        SUSPENDED = 'suspended', 'Suspended'
        EXPIRED = 'expired', 'Expired'

    class Endorsement(models.TextChoices):
        HAZMAT = 'hazmat', 'Hazmat (H)'
        TANKER = 'tanker', 'Tanker (N)'
        PASSENGER = 'passenger', 'Passenger (P)'
        SCHOOL_BUS = 'school_bus', 'School Bus (S)'
        AIRBRAKE = 'airbrake', 'Air Brake (L)'
        COMB_TANKER_HAZMAT = 'comb_tanker_hazmat', 'Tanker + Hazmat (X)'

    class EmploymentStatus(models.TextChoices):
        ACTIVE = 'active', 'Active'
        ON_LEAVE = 'on_leave', 'On Leave'
        SUSPENDED = 'suspended', 'Suspended'
        TERMINATED = 'terminated', 'Terminated'
        PROBATION = 'probation', 'Probation'

    contact = models.OneToOneField(Contact, on_delete=models.CASCADE, related_name='driver_profile')
    license_number = models.CharField(max_length=50, blank=True)
    license_class = models.CharField(max_length=10, choices=LicenseClass.choices, blank=True)
    license_state = models.CharField(max_length=10, blank=True, help_text='Issuing state')
    license_expiry = models.DateField(null=True, blank=True)
    license_endorsements = models.JSONField(default=list, blank=True, help_text='List of endorsement codes')
    medical_card_expiry = models.DateField(null=True, blank=True)
    medical_card_number = models.CharField(max_length=50, blank=True)
    mvr_status = models.CharField(max_length=20, choices=MvrStatus.choices, default=MvrStatus.CLEAN)
    mvr_last_checked = models.DateField(null=True, blank=True)
    mvr_next_due = models.DateField(null=True, blank=True)
    hire_date = models.DateField(null=True, blank=True)
    termination_date = models.DateField(null=True, blank=True)
    employment_status = models.CharField(max_length=20, choices=EmploymentStatus.choices, default=EmploymentStatus.ACTIVE)
    home_terminal = models.CharField(max_length=200, blank=True)
    pay_rate = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text='Hourly rate (0 = salary)')
    pay_type = models.CharField(max_length=20, default='hourly', help_text='hourly, mileage, salary, percentage')
    emergency_contact_name = models.CharField(max_length=200, blank=True)
    emergency_contact_phone = models.CharField(max_length=20, blank=True)
    emergency_contact_relation = models.CharField(max_length=100, blank=True)
    blood_type = models.CharField(max_length=10, blank=True)

    class Meta:
        indexes = [models.Index(fields=['employment_status']), models.Index(fields=['mvr_status'])]

    @property
    def mvr_is_expired(self):
        if not self.mvr_next_due:
            return False
        from django.utils import timezone
        return self.mvr_next_due < timezone.now().date()

    @property
    def license_is_expired(self):
        if not self.license_expiry:
            return False
        from django.utils import timezone
        return self.license_expiry < timezone.now().date()

    @property
    def medical_is_expired(self):
        if not self.medical_card_expiry:
            return False
        from django.utils import timezone
        return self.medical_card_expiry < timezone.now().date()


class DriverViolation(models.Model):
    """Motor vehicle record violations, citations, and accidents for a driver."""
    class Severity(models.TextChoices):
        MINOR = 'minor', 'Minor'
        MAJOR = 'major', 'Major'
        CRITICAL = 'critical', 'Critical'

    class ViolationType(models.TextChoices):
        SPEEDING = 'speeding', 'Speeding'
        RECKLESS = 'reckless', 'Reckless Driving'
        DUI = 'dui', 'DUI / DWI'
        FOLLOWING_TOO_CLOSE = 'following', 'Following Too Close'
        IMPROPER_LANE = 'lane', 'Improper Lane Change'
        EQUIPMENT = 'equipment', 'Equipment Violation'
        ACCIDENT = 'accident', 'Accident'
        OTHER = 'other', 'Other'

    driver_profile = models.ForeignKey(DriverProfile, on_delete=models.CASCADE, related_name='violations')
    violation_type = models.CharField(max_length=20, choices=ViolationType.choices)
    severity = models.CharField(max_length=20, choices=Severity.choices, default=Severity.MINOR)
    date = models.DateField()
    state = models.CharField(max_length=10, blank=True)
    points = models.IntegerField(default=0, help_text='Points assigned')
    description = models.TextField(blank=True)
    fine_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    paid = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']


class DriverDrugTest(models.Model):
    """Drug & alcohol testing records (FMCSA Clearinghouse)."""
    class TestType(models.TextChoices):
        PRE_EMPLOYMENT = 'pre_employment', 'Pre-Employment'
        RANDOM = 'random', 'Random'
        POST_ACCIDENT = 'post_accident', 'Post-Accident'
        REASONABLE_SUSPICION = 'reasonable_suspicion', 'Reasonable Suspicion'
        RETURN_TO_DUTY = 'return_to_duty', 'Return to Duty'
        FOLLOW_UP = 'follow_up', 'Follow-Up'

    class Result(models.TextChoices):
        NEGATIVE = 'negative', 'Negative'
        POSITIVE = 'positive', 'Positive'
        REFUSED = 'refused', 'Refused'
        PENDING = 'pending', 'Pending'

    driver_profile = models.ForeignKey(DriverProfile, on_delete=models.CASCADE, related_name='drug_tests')
    test_type = models.CharField(max_length=30, choices=TestType.choices)
    test_date = models.DateField()
    result = models.CharField(max_length=20, choices=Result.choices, default=Result.PENDING)
    lab_name = models.CharField(max_length=200, blank=True)
    chain_of_custody = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-test_date']


class DriverTraining(models.Model):
    """Training courses and certifications for a driver."""
    class Status(models.TextChoices):
        SCHEDULED = 'scheduled', 'Scheduled'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        EXPIRED = 'expired', 'Expired'
        FAILED = 'failed', 'Failed'

    driver_profile = models.ForeignKey(DriverProfile, on_delete=models.CASCADE, related_name='trainings')
    course_name = models.CharField(max_length=200)
    provider = models.CharField(max_length=200, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SCHEDULED)
    completion_date = models.DateField(null=True, blank=True)
    expiry_date = models.DateField(null=True, blank=True)
    score = models.FloatField(null=True, blank=True, help_text='Percentage 0-100')
    hours = models.FloatField(default=0, help_text='Training hours')
    certificate_number = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-completion_date']


class DriverHoursOfService(models.Model):
    """Daily Hours-of-Service (HOS) log entry (ELD/e-log)."""
    class DutyStatus(models.TextChoices):
        OFF_DUTY = 'off_duty', 'Off Duty'
        SLEEPER = 'sleeper', 'Sleeper Berth'
        DRIVING = 'driving', 'Driving'
        ON_DUTY = 'on_duty', 'On Duty (Not Driving)'

    driver_profile = models.ForeignKey(DriverProfile, on_delete=models.CASCADE, related_name='hos_logs')
    date = models.DateField()
    duty_status = models.CharField(max_length=20, choices=DutyStatus.choices)
    hours = models.FloatField(default=0, help_text='Hours in this duty status')
    driving_hours = models.FloatField(default=0)
    on_duty_hours = models.FloatField(default=0)
    cycle_hours = models.FloatField(default=0, help_text='Cumulative cycle hours (e.g. 70/8)')
    location = models.CharField(max_length=200, blank=True)
    vehicle = models.CharField(max_length=200, blank=True)
    co_driver = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
        indexes = [models.Index(fields=['date'])]


class DriverAssignment(models.Model):
    """Current & historical vehicle-trailer-driver assignments."""
    driver_profile = models.ForeignKey(DriverProfile, on_delete=models.CASCADE, related_name='assignments')
    vehicle = models.ForeignKey('vehicles.Vehicle', null=True, blank=True, on_delete=models.SET_NULL, related_name='driver_assignments')
    assigned_at = models.DateTimeField(auto_now_add=True)
    unassigned_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    notes = models.CharField(max_length=500, blank=True)

    class Meta:
        ordering = ['-assigned_at']


class DriverNote(models.Model):
    """Free-form notes about a driver (performance, incidents, commendations)."""
    class Category(models.TextChoices):
        GENERAL = 'general', 'General'
        PERFORMANCE = 'performance', 'Performance'
        INCIDENT = 'incident', 'Incident'
        COMMENDATION = 'commendation', 'Commendation'
        WARNING = 'warning', 'Warning'
        OTHER = 'other', 'Other'

    driver_profile = models.ForeignKey(DriverProfile, on_delete=models.CASCADE, related_name='notes_log')
    category = models.CharField(max_length=20, choices=Category.choices, default=Category.GENERAL)
    body = models.TextField()
    author = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class VendorProfile(models.Model):
    contact = models.OneToOneField(Contact, on_delete=models.CASCADE, related_name='vendor_profile')
    service_type = models.CharField(max_length=100, blank=True)
    rating = models.FloatField(default=0, help_text='0-5 stars')
    payment_terms = models.CharField(max_length=50, blank=True)
    tax_id = models.CharField(max_length=50, blank=True)
