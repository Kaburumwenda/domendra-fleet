from django.urls import path

from .views import AccidentReportViewSet, AccidentWitnessViewSet, InsuranceClaimViewSet, AccidentPhotoViewSet

app_name = 'accidents'

urlpatterns = [
    path('reports/', AccidentReportViewSet.as_view({'get': 'list', 'post': 'create'}), name='report-list'),
    path('reports/stats/', AccidentReportViewSet.as_view({'get': 'stats'}), name='report-stats'),
    path('reports/<int:pk>/', AccidentReportViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='report-detail'),
    path('witnesses/', AccidentWitnessViewSet.as_view({'get': 'list', 'post': 'create'}), name='witness-list'),
    path('witnesses/<int:pk>/', AccidentWitnessViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='witness-detail'),
    path('claims/', InsuranceClaimViewSet.as_view({'get': 'list', 'post': 'create'}), name='claim-list'),
    path('claims/<int:pk>/', InsuranceClaimViewSet.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'}), name='claim-detail'),
    path('photos/', AccidentPhotoViewSet.as_view({'get': 'list', 'post': 'create'}), name='photo-list'),
    path('photos/<int:pk>/', AccidentPhotoViewSet.as_view({'get': 'retrieve', 'patch': 'partial_update', 'delete': 'destroy'}), name='photo-detail'),
]
