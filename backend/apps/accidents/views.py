from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Count, Sum
from datetime import timedelta
from django.utils import timezone

from .models import AccidentReport, AccidentWitness, InsuranceClaim, AccidentPhoto
from .serializers import AccidentReportSerializer, AccidentWitnessSerializer, InsuranceClaimSerializer, AccidentPhotoSerializer


class AccidentReportViewSet(viewsets.ModelViewSet):
    queryset = AccidentReport.objects.select_related('vehicle', 'driver', 'created_by').prefetch_related('witnesses')
    serializer_class = AccidentReportSerializer
    filterset_fields = ['severity', 'status', 'weather', 'vehicle', 'driver']
    search_fields = ['location', 'description', 'police_report_number']
    ordering_fields = ['date', 'severity', 'estimated_damage_cost', 'created_at']

    @action(detail=False, methods=['get'], url_path='stats')
    def stats(self, request):
        qs = self.get_queryset()
        now = timezone.now()
        thirty_days_ago = now - timedelta(days=30)

        total = qs.count()
        by_severity = dict(qs.values_list('severity').annotate(c=Count('id')).order_by())
        by_status = dict(qs.values_list('status').annotate(c=Count('id')).order_by())
        total_damage = qs.aggregate(s=Sum('estimated_damage_cost'))['s'] or 0
        last_30d = qs.filter(date__gte=thirty_days_ago).count()
        claims_filed = InsuranceClaim.objects.filter(accident__in=qs, status='filed').count()
        claims_settled = InsuranceClaim.objects.filter(accident__in=qs, status='settled').count()
        claims_total = InsuranceClaim.objects.filter(accident__in=qs).aggregate(
            s=Sum('claim_amount'))['s'] or 0
        claims_settled_amount = InsuranceClaim.objects.filter(accident__in=qs, status='settled').aggregate(
            s=Sum('settled_amount'))['s'] or 0

        return Response({
            'total': total,
            'last_30_days': last_30d,
            'minor': by_severity.get('minor', 0),
            'moderate': by_severity.get('moderate', 0),
            'serious': by_severity.get('serious', 0),
            'fatal': by_severity.get('fatal', 0),
            'reported': by_status.get('reported', 0),
            'under_investigation': by_status.get('under_investigation', 0),
            'resolved': by_status.get('resolved', 0),
            'closed': by_status.get('closed', 0),
            'total_damage_cost': total_damage,
            'claims_filed': claims_filed,
            'claims_settled': claims_settled,
            'claims_total_amount': claims_total,
            'claims_settled_amount': claims_settled_amount,
        })


class AccidentWitnessViewSet(viewsets.ModelViewSet):
    queryset = AccidentWitness.objects.select_related('accident')
    serializer_class = AccidentWitnessSerializer
    filterset_fields = ['accident']


class InsuranceClaimViewSet(viewsets.ModelViewSet):
    queryset = InsuranceClaim.objects.select_related('accident', 'agent')
    serializer_class = InsuranceClaimSerializer
    filterset_fields = ['status', 'insurance_company']
    ordering_fields = ['filed_date', 'claim_amount']


class AccidentPhotoViewSet(viewsets.ModelViewSet):
    queryset = AccidentPhoto.objects.select_related('accident')
    serializer_class = AccidentPhotoSerializer
    filterset_fields = ['accident']

    def perform_create(self, serializer):
        serializer.save()

    @action(detail=True, methods=['delete'], url_path='delete')
    def delete_photo(self, request, pk=None):
        photo = self.get_object()
        photo.image.delete(save=False)
        photo.delete()
        return Response(status=204)
