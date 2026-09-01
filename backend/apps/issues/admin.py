from django.contrib import admin

from .models import Issue, PartUsage, TimeLog, WorkOrder, WorkOrderNote


class WorkOrderNoteInline(admin.TabularInline):
    model = WorkOrderNote
    extra = 0


class TimeLogInline(admin.TabularInline):
    model = TimeLog
    extra = 0


class PartUsageInline(admin.TabularInline):
    model = PartUsage
    extra = 0


@admin.register(Issue)
class IssueAdmin(admin.ModelAdmin):
    list_display = ('title', 'vehicle', 'status', 'priority', 'created_at')
    list_filter = ('status', 'priority')
    search_fields = ('title', 'description')


@admin.register(WorkOrder)
class WorkOrderAdmin(admin.ModelAdmin):
    list_display = ('issue', 'status', 'assigned_to', 'estimated_cost', 'total_cost', 'created_at')
    list_filter = ('status', 'assignment_type')
    inlines = [WorkOrderNoteInline, TimeLogInline, PartUsageInline]
