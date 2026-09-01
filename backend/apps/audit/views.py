from rest_framework import viewsets

from .models import AuditLog
from .serializers import AuditLogSerializer


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.select_related('user')
    serializer_class = AuditLogSerializer
    filterset_fields = ['action', 'resource_type', 'user', 'method', 'priority']
    search_fields = ['path', 'resource_type']
    ordering_fields = ['timestamp', 'action']
