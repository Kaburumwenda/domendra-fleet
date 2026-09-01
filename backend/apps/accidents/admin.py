from django.contrib import admin

from .models import AccidentReport, AccidentWitness, InsuranceClaim, AccidentPhoto


class AccidentWitnessInline(admin.TabularInline):
    model = AccidentWitness
    extra = 0


class AccidentPhotoInline(admin.TabularInline):
    model = AccidentPhoto
    extra = 0


@admin.register(AccidentReport)
class AccidentReportAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'date', 'severity', 'location', 'estimated_damage_cost')
    list_filter = ('severity', 'weather', 'road_condition')
    search_fields = ('location', 'description', 'police_report_number')
    inlines = [AccidentWitnessInline, AccidentPhotoInline]
    raw_id_fields = ('vehicle', 'driver', 'created_by')


@admin.register(InsuranceClaim)
class InsuranceClaimAdmin(admin.ModelAdmin):
    list_display = ('accident', 'claim_number', 'insurance_company', 'status', 'claim_amount', 'settled_amount')
    list_filter = ('status',)
    search_fields = ('claim_number', 'insurance_company')
