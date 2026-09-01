from datetime import timedelta

from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import DqfCheck, DriverQualificationFile
from .serializers import DqfCheckSerializer, DriverQualificationFileSerializer


class DriverQualificationFileViewSet(viewsets.ModelViewSet):
    queryset = DriverQualificationFile.objects.select_related('driver')
    serializer_class = DriverQualificationFileSerializer
    filterset_fields = ['status', 'driver']
    search_fields = ['driver__first_name', 'driver__last_name', 'medical_examiner', 'road_test_examiner']
    ordering_fields = ['created_at', 'updated_at', 'next_review_due']

    @action(detail=False, methods=['get'])
    def expiring(self, request):
        """DQFs with reviews or medical/license expiring within 30 days."""
        soon = timezone.now().date() + timedelta(days=30)
        qs = self.get_queryset().filter(next_review_due__lte=soon)
        return Response(DriverQualificationFileSerializer(qs, many=True).data)

    @action(detail=True, methods=['post'])
    def complete_review(self, request, pk=None):
        dqf = self.get_object()
        dqf.review_date = timezone.now().date()
        dqf.next_review_due = dqf.review_date + timedelta(days=365)
        if dqf.completion_pct == 100:
            dqf.status = DriverQualificationFile.Status.COMPLETE
        else:
            dqf.status = DriverQualificationFile.Status.INCOMPLETE
        dqf.save()
        return Response(DriverQualificationFileSerializer(dqf).data)


class DqfCheckViewSet(viewsets.ModelViewSet):
    queryset = DqfCheck.objects.select_related('dqf', 'document')
    serializer_class = DqfCheckSerializer
    filterset_fields = ['dqf', 'check_type', 'status']
    ordering_fields = ['check_type', 'completed_date', 'expiry_date']

    @action(detail=True, methods=['post'])
    def clear(self, request, pk=None):
        check = self.get_object()
        check.status = DqfCheck.Status.CLEARED
        check.completed_date = request.data.get('completed_date') or timezone.now().date()
        check.result_notes = request.data.get('result_notes', check.result_notes)
        check.save(update_fields=['status', 'completed_date', 'result_notes', 'updated_at'])
        return Response(DqfCheckSerializer(check).data)
