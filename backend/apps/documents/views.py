import io
import os
import random
from datetime import timedelta
from PIL import Image

from django.core.files.base import ContentFile
from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Document
from .serializers import DocumentSerializer


class DocumentViewSet(viewsets.ModelViewSet):
    queryset = Document.objects.select_related('vehicle', 'contact', 'uploaded_by')
    serializer_class = DocumentSerializer
    filterset_fields = ['document_type', 'vehicle', 'contact', 'expiry_date']
    search_fields = ['title', 'notes']
    ordering_fields = ['created_at', 'expiry_date', 'title']

    @action(detail=False, methods=['get'])
    def stats(self, request, *args, **kwargs):
        """Aggregate document statistics for analytics cards."""
        qs = self.get_queryset()
        total = qs.count()
        by_type = {}
        for choice in Document.DocumentType.choices:
            by_type[choice[0]] = qs.filter(document_type=choice[0]).count()
        expired = qs.filter(expiry_date__lt=timezone.now().date()).count()
        expiring_soon = qs.filter(
            expiry_date__gte=timezone.now().date(),
            expiry_date__lte=timezone.now().date() + timedelta(days=30),
        ).count()
        no_expiry = qs.filter(expiry_date__isnull=True).count()
        total_size = sum(
            (v or 0) for v in qs.values_list('file_size', flat=True)
        )
        by_vehicle = []
        for doc in qs.filter(vehicle__isnull=False).select_related('vehicle'):
            name = doc.vehicle.display_name
            found = next((v for v in by_vehicle if v['vehicle_name'] == name), None)
            if found:
                found['count'] += 1
                if doc.is_expired:
                    found['expired'] += 1
            else:
                by_vehicle.append({'vehicle_name': name, 'count': 1, 'expired': 1 if doc.is_expired else 0})
        by_vehicle.sort(key=lambda x: x['count'], reverse=True)
        return Response({
            'total': total,
            'by_type': by_type,
            'expired': expired,
            'expiring_soon': expiring_soon,
            'no_expiry': no_expiry,
            'total_size': total_size,
            'by_vehicle': by_vehicle[:8],
        })

    @action(detail=False, methods=['post'])
    def seed_demo(self, request, *args, **kwargs):
        """Seed demo documents for the current tenant."""
        from apps.vehicles.models import Vehicle
        from apps.contacts.models import Contact

        vehicles = list(Vehicle.objects.all()[:10])
        contacts = list(Contact.objects.all()[:10])

        existing = Document.objects.count()
        if existing >= 16:
            return Response({'detail': f'{existing} documents already exist. Seeding is skipped.'}, status=400)

        now = timezone.now()

        doc_templates = [
            {'document_type': 'insurance', 'title_prefix': 'Certificate of Insurance — ', 'has_expiry': True, 'days_ahead': 45},
            {'document_type': 'registration', 'title_prefix': 'Vehicle Registration — ', 'has_expiry': True, 'days_ahead': 120},
            {'document_type': 'title', 'title_prefix': 'Vehicle Title — ', 'has_expiry': False, 'days_ahead': 0},
            {'document_type': 'inspection', 'title_prefix': 'Annual Inspection Report — ', 'has_expiry': True, 'days_ahead': 75},
            {'document_type': 'license', 'title_prefix': 'CDL License — ', 'has_expiry': True, 'days_ahead': 15},
            {'document_type': 'medical_card', 'title_prefix': 'Medical Examiner Certificate — ', 'has_expiry': True, 'days_ahead': -5},
            {'document_type': 'warranty', 'title_prefix': 'Extended Warranty — ', 'has_expiry': True, 'days_ahead': 200},
            {'document_type': 'contract', 'title_prefix': 'Lease Agreement — ', 'has_expiry': True, 'days_ahead': 90},
            {'document_type': 'permit', 'title_prefix': 'Oversize Load Permit — ', 'has_expiry': True, 'days_ahead': 7},
            {'document_type': 'maintenance', 'title_prefix': 'Service Record — ', 'has_expiry': False, 'days_ahead': 0},
        ]

        def _make_png(color):
            """Generate a small placeholder PNG file and return (ContentFile, size)."""
            img = Image.new('RGB', (1, 1), color)
            buf = io.BytesIO()
            img.save(buf, format='PNG')
            raw = buf.getvalue()
            return ContentFile(raw, name='placeholder.png'), len(raw)

        created = 0
        colors = [(220, 38, 38), (59, 130, 246), (34, 197, 94), (245, 158, 11), (168, 85, 247), (20, 184, 166), (236, 72, 153), (99, 102, 241), (14, 165, 233), (100, 116, 139)]

        for i, tmpl in enumerate(doc_templates):
            # Distribute across vehicles and contacts
            attach_vehicle = vehicles[i % len(vehicles)] if vehicles else None
            attach_contact = contacts[(i + 3) % len(contacts)] if contacts and i % 3 == 0 else None
            title_name = attach_vehicle.display_name if attach_vehicle else (attach_contact.full_name if attach_contact else 'General')
            color = colors[i % len(colors)]
            cf, sz = _make_png(color)
            filename = f"doc_{tmpl['document_type']}_{i + 1}.png"
            cf.name = filename
            expiry_date = None
            if tmpl['has_expiry']:
                expiry_date = (now + timedelta(days=tmpl['days_ahead'])).date()

            Document.objects.create(
                vehicle=attach_vehicle,
                contact=attach_contact,
                document_type=tmpl['document_type'],
                title=f"{tmpl['title_prefix']}{title_name}",
                file=cf,
                file_size=sz,
                expiry_date=expiry_date,
                notes=f"Auto-generated demo document for {title_name}.",
            )
            created += 1

        # Create 6 extra docs for variety
        extra_types = ['insurance', 'registration', 'inspection', 'warranty', 'maintenance', 'permit']
        for i in range(6):
            etype = extra_types[i]
            attach_vehicle = vehicles[(i + 1) % len(vehicles)] if vehicles else None
            title_name = attach_vehicle.display_name if attach_vehicle else 'General'
            expiry_date = (now + timedelta(days=random.choice([10, 20, -3, 60, 5, 300]))).date()
            cf, sz = _make_png((100, 116, 139))
            filename = f"doc_extra_{etype}_{i + 1}.png"
            cf.name = filename
            Document.objects.create(
                vehicle=attach_vehicle,
                document_type=etype,
                title=f"{etype.title()} — {title_name} (Copy {i + 1})",
                file=cf,
                file_size=sz,
                expiry_date=expiry_date,
                notes="Additional demo document for testing.",
            )
            created += 1

        return Response({'detail': f'Successfully seeded {created} demo documents.'})
