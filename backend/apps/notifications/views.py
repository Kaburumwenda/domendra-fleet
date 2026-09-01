from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Notification, NotificationPreference, NotificationTemplate
from .serializers import (
    NotificationSerializer,
    NotificationPreferenceSerializer,
    NotificationTemplateSerializer,
)


class NotificationTemplateViewSet(viewsets.ModelViewSet):
    queryset = NotificationTemplate.objects.all()
    serializer_class = NotificationTemplateSerializer
    filterset_fields = ['channel', 'event', 'is_active']
    search_fields = ['name', 'event']
    ordering_fields = ['name', 'created_at']

    @action(detail=True, methods=['post'])
    def preview(self, request, pk=None):
        template = self.get_object()
        subject, body = template.render(**request.data.get('context', {}))
        return Response({'subject': subject, 'body': body})


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Notification.objects.select_related('recipient_user')
    serializer_class = NotificationSerializer
    filterset_fields = ['recipient_user', 'channel', 'status', 'is_read', 'event']
    ordering_fields = ['created_at']

    @action(detail=False, methods=['get'])
    def unread(self, request):
        qs = self.get_queryset().filter(recipient_user=request.user, is_read=False)
        return Response(NotificationSerializer(qs, many=True).data)

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        Notification.objects.filter(recipient_user=request.user, is_read=False).update(is_read=True)
        return Response({'detail': 'All marked read.'})

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        n = self.get_object()
        n.is_read = True
        n.save(update_fields=['is_read'])
        return Response(NotificationSerializer(n).data)


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    queryset = NotificationPreference.objects.select_related('user')
    serializer_class = NotificationPreferenceSerializer
    filterset_fields = ['user']

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        pref, _ = NotificationPreference.objects.get_or_create(user=request.user)
        if request.method == 'GET':
            return Response(NotificationPreferenceSerializer(pref).data)
        serializer = NotificationPreferenceSerializer(pref, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
