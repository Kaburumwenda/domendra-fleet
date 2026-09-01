from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from .models import Location
from .serializers import LocationSerializer


class LocationViewSet(viewsets.ModelViewSet):
    queryset = Location.objects.all()
    serializer_class = LocationSerializer
    filterset_fields = ['type', 'is_geofence', 'is_active']
    search_fields = ['name', 'address']
    ordering_fields = ['name', 'created_at']

    def _log_errors(self, action_name, serializer):
        print(f"[Location {action_name} ERROR] validation_errors={serializer.errors} "
              f"raw_data={dict(serializer.initial_data) if hasattr(serializer, 'initial_data') else ''}")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            self._log_errors('create', serializer)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=201, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        if not serializer.is_valid():
            self._log_errors('update', serializer)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        if getattr(instance, '_prefetched_objects_cache', None):
            serializer._prefetched_objects_cache = {p: getattr(instance, p) for p in instance._prefetched_objects_cache}
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def geofences(self, request):
        qs = self.get_queryset().filter(is_geofence=True, is_active=True)
        return Response(LocationSerializer(qs, many=True).data)
