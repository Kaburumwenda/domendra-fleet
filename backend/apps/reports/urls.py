from django.urls import path

from .views import (
    ReportExecutionViewSet,
    ReportTemplateViewSet,
    ScheduledReportViewSet,
    StandardReportsView,
)

app_name = 'reports'

urlpatterns = [
    path('templates/', ReportTemplateViewSet.as_view({'get': 'list', 'post': 'create'}), name='template-list'),
    path('templates/<int:pk>/', ReportTemplateViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='template-detail'),
    path('schedules/', ScheduledReportViewSet.as_view({'get': 'list', 'post': 'create'}), name='schedule-list'),
    path('schedules/<int:pk>/', ScheduledReportViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='schedule-detail'),
    path('executions/', ReportExecutionViewSet.as_view({'get': 'list'}), name='execution-list'),
    path('executions/<int:pk>/', ReportExecutionViewSet.as_view({'get': 'retrieve'}), name='execution-detail'),
    path('standard/cost-per-mile/', StandardReportsView.as_view({'get': 'cost_per_mile'}), name='rpt-cost-per-mile'),
    path('standard/fuel-efficiency/', StandardReportsView.as_view({'get': 'fuel_efficiency'}), name='rpt-fuel-efficiency'),
    path('standard/mechanic-utilization/', StandardReportsView.as_view({'get': 'mechanic_utilization'}), name='rpt-mechanic'),
    path('standard/fleet-aging/', StandardReportsView.as_view({'get': 'fleet_aging'}), name='rpt-fleet-aging'),
    path('standard/benchmark/', StandardReportsView.as_view({'get': 'benchmark'}), name='rpt-benchmark'),
    path('financial/overview/', StandardReportsView.as_view({'get': 'financial_overview'}), name='rpt-fin-overview'),
    path('financial/revenue/', StandardReportsView.as_view({'get': 'revenue_breakdown'}), name='rpt-revenue'),
    path('financial/costs/', StandardReportsView.as_view({'get': 'cost_breakdown'}), name='rpt-costs'),
    path('financial/vehicle-roi/', StandardReportsView.as_view({'get': 'vehicle_roi'}), name='rpt-roi'),
    path('financial/cash-flow/', StandardReportsView.as_view({'get': 'cash_flow'}), name='rpt-cashflow'),
    path('financial/profit-loss/', StandardReportsView.as_view({'get': 'profit_loss'}), name='rpt-profit-loss'),
    path('financial/locations/', StandardReportsView.as_view({'get': 'locations_analysis'}), name='rpt-locations'),
    path('financial/ownership/', StandardReportsView.as_view({'get': 'cost_of_ownership'}), name='rpt-ownership'),
    path('financial/pdf/', StandardReportsView.as_view({'get': 'financial_pdf'}), name='rpt-financial-pdf'),
    path('general-ledger/', StandardReportsView.as_view({'get': 'general_ledger'}), name='rpt-general-ledger'),
    path('seed-demo/', StandardReportsView.as_view({'get': 'seed_demo'}), name='rpt-seed-demo'),
    path('export/', StandardReportsView.as_view({'get': 'export'}), name='rpt-export'),
]
