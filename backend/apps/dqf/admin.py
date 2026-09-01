from django.contrib import admin

from .models import DqfCheck, DriverQualificationFile


@admin.register(DriverQualificationFile)
class DriverQualificationFileAdmin(admin.ModelAdmin):
    list_display = ('driver', 'status', 'completion_pct', 'next_review_due', 'road_test_passed', 'background_check_passed', 'drug_test_passed')
    list_filter = ('status',)
    raw_id_fields = ('driver',)


@admin.register(DqfCheck)
class DqfCheckAdmin(admin.ModelAdmin):
    list_display = ('dqf', 'check_type', 'status', 'completed_date', 'expiry_date')
    list_filter = ('check_type', 'status')
    raw_id_fields = ('dqf', 'document')
