from django.urls import path

from .views import IssuePhotoViewSet, IssueViewSet, WorkOrderViewSet

app_name = 'issues'

urlpatterns = [
    path('issues/', IssueViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='issue-list'),
    path('issues/<int:pk>/', IssueViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='issue-detail'),
    path('issues/<int:pk>/create-work-order/', IssueViewSet.as_view({'post': 'create_work_order'}), name='issue-create-wo'),
    path('issues/<int:pk>/assign/', IssueViewSet.as_view({'post': 'assign'}), name='issue-assign'),
    path('issues/stats/', IssueViewSet.as_view({'get': 'stats'}), name='issue-stats'),
    path('issues/bulk-update-status/', IssueViewSet.as_view({'post': 'bulk_update_status'}), name='issue-bulk-status'),
    path('issues/seed-demo/', IssueViewSet.as_view({'post': 'seed_demo'}), name='issue-seed-demo'),
    path('photos/', IssuePhotoViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='issue-photo-list'),
    path('photos/<int:pk>/', IssuePhotoViewSet.as_view({
        'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='issue-photo-detail'),
    path('work-orders/', WorkOrderViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='work-order-list'),
    path('work-orders/<int:pk>/', WorkOrderViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='work-order-detail'),
    path('work-orders/<int:pk>/clock-in/', WorkOrderViewSet.as_view({'post': 'clock_in'}), name='wo-clock-in'),
    path('work-orders/<int:pk>/clock-out/', WorkOrderViewSet.as_view({'post': 'clock_out'}), name='wo-clock-out'),
    path('work-orders/<int:pk>/add-note/', WorkOrderViewSet.as_view({'post': 'add_note'}), name='wo-add-note'),
    path('work-orders/<int:pk>/add-part/', WorkOrderViewSet.as_view({'post': 'add_part'}), name='wo-add-part'),
    path('work-orders/<int:pk>/complete/', WorkOrderViewSet.as_view({'post': 'complete'}), name='wo-complete'),
    path('work-orders/<int:pk>/start-work/', WorkOrderViewSet.as_view({'post': 'start_work'}), name='wo-start-work'),
    path('work-orders/stats/', WorkOrderViewSet.as_view({'get': 'stats'}), name='wo-stats'),
    path('work-orders/seed-demo/', WorkOrderViewSet.as_view({'post': 'seed_demo'}), name='wo-seed-demo'),
]
