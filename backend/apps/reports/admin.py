from django.contrib import admin

from .models import ReportExecution, ReportTemplate, ScheduledReport


@admin.register(ReportTemplate)
class ReportTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'report_type', 'created_by', 'created_at')
    list_filter = ('report_type',)


@admin.register(ScheduledReport)
class ScheduledReportAdmin(admin.ModelAdmin):
    list_display = ('template', 'frequency', 'format', 'is_active', 'next_run')
    list_filter = ('frequency', 'format', 'is_active')


@admin.register(ReportExecution)
class ReportExecutionAdmin(admin.ModelAdmin):
    list_display = ('template', 'status', 'file_format', 'started_at', 'completed_at')
    list_filter = ('status', 'file_format')
    readonly_fields = ('started_at', 'completed_at', 'error_message')
