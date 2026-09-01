from django.contrib import admin

from .models import InspectionForm, InspectionItem, InspectionReport, InspectionResponse


class InspectionItemInline(admin.TabularInline):
    model = InspectionItem
    extra = 1
    ordering = ['order']


class InspectionResponseInline(admin.TabularInline):
    model = InspectionResponse
    extra = 0
    readonly_fields = ['is_fail']


@admin.register(InspectionForm)
class InspectionFormAdmin(admin.ModelAdmin):
    list_display = ('name', 'is_active', 'item_count', 'created_at')
    inlines = [InspectionItemInline]

    def item_count(self, obj):
        return obj.items.count()


@admin.register(InspectionReport)
class InspectionReportAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'form', 'status', 'driver', 'submitted_at')
    list_filter = ('status',)
    inlines = [InspectionResponseInline]
    raw_id_fields = ('vehicle', 'driver', 'form')
