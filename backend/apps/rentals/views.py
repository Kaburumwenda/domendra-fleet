import math
from decimal import Decimal

from django.db import transaction
from django.db.models import ProtectedError
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Customer, DigitalSignature, DriverHireRate, InspectionCheck, Invoice, RentalAgreement, RentalCharge, RentalPayment, VehicleDamage, VehicleCheck, VehiclePricing
from .serializers import (
    CustomerSerializer,
    DigitalSignatureSerializer,
    DriverHireRateSerializer,
    InspectionCheckSerializer,
    InvoiceSerializer,
    RentalAgreementListSerializer,
    RentalAgreementSerializer,
    RentalChargeSerializer,
    RentalPaymentSerializer,
    VehicleDamageSerializer,
    VehicleCheckSerializer,
    VehiclePricingSerializer,
)


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all().order_by('-created_at')
    serializer_class = CustomerSerializer
    search_fields = ['full_name', 'email', 'phone', 'id_number', 'driving_license_no']
    filterset_fields = ['customer_type', 'country']
    ordering_fields = ['created_at', 'full_name']

    def get_queryset(self):
        qs = super().get_queryset()
        q = self.request.query_params.get('q')
        if q:
            qs = qs.filter(
                full_name__icontains=q
            ) | qs.filter(email__icontains=q) | qs.filter(
                phone__icontains=q
            ) | qs.filter(id_number__icontains=q) | qs.filter(driving_license_no__icontains=q)
        return qs.distinct()

    @action(detail=True, methods=['get'], url_path='agreements')
    def agreements(self, request, pk=None):
        """List all rental agreements linked to this customer."""
        customer = self.get_object()
        agreements = RentalAgreement.objects.filter(customer=customer).order_by('-created_at')
        serializer = RentalAgreementListSerializer(agreements, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='check-links')
    def check_links(self, request, pk=None):
        """Check if the customer has any linked rental agreements before deletion."""
        customer = self.get_object()
        agreements = RentalAgreement.objects.filter(customer=customer).order_by('-created_at')
        serializer = RentalAgreementListSerializer(agreements, many=True)
        return Response({
            'has_agreements': agreements.exists(),
            'agreements_count': agreements.count(),
            'agreements': serializer.data,
        })

    @transaction.atomic
    def destroy(self, request, *args, **kwargs):
        """Delete a customer. If cascade=true, also delete all linked rental agreements first."""
        customer = self.get_object()
        cascade = request.query_params.get('cascade', '').lower() in ('true', '1', 'yes')

        linked_count = RentalAgreement.objects.filter(customer=customer).count()
        if linked_count > 0 and not cascade:
            return Response(
                {
                    'detail': f'This customer is linked to {linked_count} rental agreement(s). '
                              f'Delete the agreements first, or confirm cascade deletion.',
                    'has_agreements': True,
                    'agreements_count': linked_count,
                },
                status=status.HTTP_409_CONFLICT,
            )

        try:
            if cascade:
                # Delete all linked agreements (and their nested charges/damages/signatures via cascade)
                RentalAgreement.objects.filter(customer=customer).delete()
            customer.delete()
        except ProtectedError as e:
            return Response(
                {'detail': f'Cannot delete customer: {e}', 'has_agreements': True},
                status=status.HTTP_409_CONFLICT,
            )

        return Response(status=status.HTTP_204_NO_CONTENT)


class RentalAgreementViewSet(viewsets.ModelViewSet):
    queryset = RentalAgreement.objects.select_related('customer', 'vehicle').order_by('-created_at')

    def get_serializer_class(self):
        if self.action == 'list':
            return RentalAgreementListSerializer
        return RentalAgreementSerializer

    filterset_fields = ['status', 'customer', 'vehicle', 'rate_period']
    ordering_fields = ['start_datetime', 'end_datetime', 'created_at', 'total_amount']
    search_fields = ['agreement_no', 'customer__full_name', 'vehicle__license_plate']

    def _auto_overdue(self):
        """Flip active agreements whose end_datetime has passed to overdue."""
        now = timezone.now()
        stale = RentalAgreement.objects.filter(
            status=RentalAgreement.Status.ACTIVE,
            end_datetime__lt=now,
        )
        stale_ids = list(stale.values_list('id', flat=True))
        if stale_ids:
            RentalAgreement.objects.filter(id__in=stale_ids).update(status=RentalAgreement.Status.OVERDUE)

    def list(self, request, *args, **kwargs):
        self._auto_overdue()
        return super().list(request, *args, **kwargs)

    def retrieve(self, request, *args, **kwargs):
        self._auto_overdue()
        return super().retrieve(request, *args, **kwargs)

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        customer_data = request.data.get('customer')
        charges_data = request.data.get('charges', [])
        damages_data = request.data.get('damages', [])
        signatures_data = request.data.get('signatures', [])
        vehicle_checks_data = request.data.get('vehicle_checks', [])
        inspection_checks_data = request.data.get('inspection_checks', [])

        # Pop nested fields we'll handle manually
        data = dict(request.data)
        data.pop('charges', None)
        data.pop('damages', None)
        data.pop('signatures', None)
        data.pop('vehicle_checks', None)
        data.pop('inspection_checks', None)

        # Resolve or create customer (dict or id)
        if isinstance(customer_data, dict):
            customer = Customer.objects.create(**{k: v for k, v in customer_data.items() if k in CustomerSerializer().fields})
            data['customer'] = customer.id
        elif customer_data is None and not data.get('customer'):
            return Response({'detail': 'A customer is required to create a rental agreement.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        agreement = serializer.save()
        agreement.refresh_from_db()

        # Attach nested charges / damages / signatures
        for c in charges_data:
            RentalCharge.objects.create(
                agreement=agreement,
                charge_type=c.get('charge_type', 'other'),
                description=c.get('description', ''),
                quantity=Decimal(str(c.get('quantity', 1))),
                unit_amount=Decimal(str(c.get('unit_amount', 0))),
                total_amount=Decimal(str(c.get('total_amount', 0))),
            )
        for d in damages_data:
            VehicleDamage.objects.create(
                agreement=agreement,
                location=d.get('location', ''),
                description=d.get('description', ''),
                severity=d.get('severity', 'none'),
                repair_cost=Decimal(str(d.get('repair_cost', 0))),
            )
        for s in signatures_data:
            DigitalSignature.objects.create(
                agreement=agreement,
                party_type=s.get('party_type', 'customer'),
                signatory_name=s.get('signatory_name', ''),
                signature_data=s.get('signature_data', ''),
            )
        for vc in vehicle_checks_data:
            VehicleCheck.objects.create(
                agreement=agreement,
                item_key=vc.get('item_key', ''),
                item_name=vc.get('item_name', vc.get('item_key', '')),
                status=vc.get('status', 'present'),
                stage=vc.get('stage', 'pickup'),
                notes=vc.get('notes', ''),
            )
        for ic in inspection_checks_data:
            InspectionCheck.objects.create(
                agreement=agreement,
                item_key=ic.get('item_key', ''),
                item_name=ic.get('item_name', ic.get('item_key', '')),
                status=ic.get('status', 'pass'),
                notes=ic.get('notes', ''),
                failed_parts=ic.get('failed_parts', []),
            )

        # Recalculate totals if not provided
        self._recalculate_totals(agreement)

        headers = self.get_success_headers(serializer.data)
        return Response(self.get_serializer(agreement).data, status=status.HTTP_201_CREATED, headers=headers)

    @transaction.atomic
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        data = dict(request.data)
        charges_data = data.pop('charges', None)
        damages_data = data.pop('damages', None)
        signatures_data = data.pop('signatures', None)
        vehicle_checks_data = data.pop('vehicle_checks', None)
        inspection_checks_data = data.pop('inspection_checks', None)

        serializer = self.get_serializer(instance, data=data, partial=partial)
        serializer.is_valid(raise_exception=True)
        agreement = serializer.save()

        if charges_data is not None:
            agreement.charges.all().delete()
            for c in charges_data:
                RentalCharge.objects.create(
                    agreement=agreement,
                    charge_type=c.get('charge_type', 'other'),
                    description=c.get('description', ''),
                    quantity=Decimal(str(c.get('quantity', 1))),
                    unit_amount=Decimal(str(c.get('unit_amount', 0))),
                    total_amount=Decimal(str(c.get('total_amount', 0))),
                )
        if damages_data is not None:
            agreement.damages.all().delete()
            for d in damages_data:
                VehicleDamage.objects.create(
                    agreement=agreement,
                    location=d.get('location', ''),
                    description=d.get('description', ''),
                    severity=d.get('severity', 'none'),
                    repair_cost=Decimal(str(d.get('repair_cost', 0))),
                )
        if signatures_data is not None:
            agreement.signatures.all().delete()
            for s in signatures_data:
                DigitalSignature.objects.create(
                    agreement=agreement,
                    party_type=s.get('party_type', 'customer'),
                    signatory_name=s.get('signatory_name', ''),
                    signature_data=s.get('signature_data', ''),
                )
        if vehicle_checks_data is not None:
            agreement.vehicle_checks.all().delete()
            for vc in vehicle_checks_data:
                VehicleCheck.objects.create(
                    agreement=agreement,
                    item_key=vc.get('item_key', ''),
                    item_name=vc.get('item_name', vc.get('item_key', '')),
                    status=vc.get('status', 'present'),
                    stage=vc.get('stage', 'pickup'),
                    notes=vc.get('notes', ''),
                )
        if inspection_checks_data is not None:
            agreement.inspection_checks.all().delete()
            for ic in inspection_checks_data:
                InspectionCheck.objects.create(
                    agreement=agreement,
                    item_key=ic.get('item_key', ''),
                    item_name=ic.get('item_name', ic.get('item_key', '')),
                    status=ic.get('status', 'pass'),
                    notes=ic.get('notes', ''),
                    failed_parts=ic.get('failed_parts', []),
                )

        self._recalculate_totals(agreement)
        return Response(self.get_serializer(agreement).data)

    def _recalculate_totals(self, agreement: RentalAgreement, billing_basis: str = 'actual'):
        """Compute subtotal / discount / tax / total based on the agreement rate spans and add-ons.

        billing_basis='actual'  → use actual_return_datetime (reduces total if returned early)
        billing_basis='scheduled' → use end_datetime (keep original price regardless of early return)
        """
        rate_map = {
            'daily': ('daily_rate', 1),
            'weekly': ('weekly_rate', 7),
            'monthly': ('monthly_rate', 30),
            'weekend': ('weekend_rate', 1),
        }
        rate_field, per_days = rate_map.get(agreement.rate_period, ('daily_rate', 1))
        rate = Decimal(getattr(agreement, rate_field) or 0)
        if rate == 0 and agreement.daily_rate:
            rate = Decimal(agreement.daily_rate)
            per_days = 1

        # Determine total days (round to nearest day, min 1 — matches frontend Math.round)
        if billing_basis == 'scheduled':
            end = agreement.end_datetime
        else:
            end = agreement.actual_return_datetime or agreement.end_datetime
        delta_seconds = (end - agreement.start_datetime).total_seconds()
        days = max(math.floor(delta_seconds / 86400 + 0.5), 1)
        if agreement.rate_period == 'weekend':
            days = 2  # Fri–Sun typical weekend package

        # Per-period billing: weekly / monthly divide the day count to apply the per-package rate
        if agreement.rate_period == 'weekly':
            base_rental = rate * Decimal(days) / Decimal(per_days)
        elif agreement.rate_period == 'monthly':
            base_rental = rate * Decimal(days) / Decimal(per_days)
        else:
            base_rental = rate * Decimal(days)
        base_rental = round(base_rental, 2)

        addons = (
            Decimal(agreement.insurance_premium or 0)
            + Decimal(agreement.gps_fee or 0)
            + Decimal(agreement.child_seat_fee or 0)
            + Decimal(agreement.additional_driver_fee or 0)
            + Decimal(agreement.delivery_fee or 0)
            + Decimal(agreement.driver_daily_rate or 0) * Decimal(days)
        )

        # Include return-time damages and additional charges
        damages_total = Decimal(
            sum(
                (d.repair_cost or 0) for d in agreement.damages.all()
            ) or 0
        )
        charges_total = Decimal(
            sum(
                (c.total_amount or 0) for c in agreement.charges.all()
            ) or 0
        )

        subtotal = base_rental + addons + damages_total + charges_total
        discount_pct = Decimal(agreement.discount_percent or 0)
        discount_from_pct = subtotal * discount_pct / Decimal(100)
        discount_total = discount_from_pct + Decimal(agreement.discount_amount or 0)
        taxable = max(subtotal - discount_total, Decimal(0))
        tax_amount = taxable * Decimal(agreement.tax_percent or 0) / Decimal(100)

        agreement.subtotal = subtotal
        agreement.discount_total = discount_total
        agreement.taxes = tax_amount
        agreement.total_amount = taxable + tax_amount
        agreement.save(update_fields=['subtotal', 'discount_total', 'taxes', 'total_amount'])

    @action(detail=True, methods=['post'], url_path='sign')
    def sign(self, request, pk=None):
        """Add a digital signature to an agreement."""
        agreement = self.get_object()
        sig = DigitalSignature.objects.create(
            agreement=agreement,
            party_type=request.data.get('party_type', 'customer'),
            signatory_name=request.data.get('signatory_name', ''),
            signature_data=request.data.get('signature_data', ''),
        )
        return Response(DigitalSignatureSerializer(sig).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='activate')
    def activate(self, request, pk=None):
        agreement = self.get_object()
        agreement.status = RentalAgreement.Status.ACTIVE
        agreement.save(update_fields=['status', 'updated_at'])
        return Response(self.get_serializer(agreement).data)

    @action(detail=True, methods=['post'], url_path='complete')
    def complete(self, request, pk=None):
        agreement = self.get_object()
        data = request.data

        with transaction.atomic():
            agreement.status = RentalAgreement.Status.COMPLETED
            return_dt = data.get('actual_return_datetime')
            if return_dt and isinstance(return_dt, str):
                from datetime import datetime, timezone as _tz
                try:
                    return_dt = datetime.fromisoformat(return_dt.replace('Z', '+00:00'))
                except ValueError:
                    return_dt = None
                # Ensure timezone-aware if USE_TZ is True
                from django.conf import settings as _settings
                if getattr(_settings, 'USE_TZ', True) and return_dt and return_dt.tzinfo is None:
                    return_dt = _tz.localize(return_dt) if hasattr(_tz, 'localize') else return_dt.replace(tzinfo=_tz.utc)
            agreement.actual_return_datetime = return_dt or timezone.now()
            agreement.end_mileage = data.get('end_mileage') or agreement.end_mileage
            agreement.end_fuel_level = data.get('end_fuel_level') or agreement.end_fuel_level
            agreement.save(update_fields=[
                'status', 'actual_return_datetime', 'end_mileage',
                'end_fuel_level', 'updated_at',
            ])

            # Return-stage damages (append, don't replace existing)
            for d in data.get('damages', []):
                VehicleDamage.objects.create(
                    agreement=agreement,
                    location=d.get('location', ''),
                    description=d.get('description', ''),
                    severity=d.get('severity', 'none'),
                    repair_cost=Decimal(str(d.get('repair_cost', 0))),
                )

            # Return-stage vehicle checks (append with stage='return')
            for vc in data.get('vehicle_checks', []):
                VehicleCheck.objects.create(
                    agreement=agreement,
                    item_key=vc.get('item_key', ''),
                    item_name=vc.get('item_name', ''),
                    status=vc.get('status', 'present'),
                    stage='return',
                    notes=vc.get('notes', ''),
                )

            # Return-stage charges (late return, excess mileage, fuel refill, cleaning, etc.)
            for c in data.get('charges', []):
                RentalCharge.objects.create(
                    agreement=agreement,
                    charge_type=c.get('charge_type', 'other'),
                    description=c.get('description', ''),
                    quantity=Decimal(str(c.get('quantity', 1))),
                    unit_amount=Decimal(str(c.get('unit_amount', 0))),
                    total_amount=Decimal(str(c.get('total_amount', 0))),
                )

            # Return-stage inspection checks — update existing checks with return status
            for ic in data.get('inspection_checks', []):
                existing = agreement.inspection_checks.filter(item_key=ic.get('item_key', '')).first()
                if existing:
                    existing.status = ic.get('status', existing.status)
                    existing.notes = ic.get('notes', existing.notes)
                    existing.failed_parts = ic.get('failed_parts', existing.failed_parts or [])
                    existing.save(update_fields=['status', 'notes', 'failed_parts'])

            self._recalculate_totals(agreement, billing_basis=data.get('billing_basis', 'actual'))

        return Response(self.get_serializer(agreement).data)


class RentalChargeViewSet(viewsets.ModelViewSet):
    queryset = RentalCharge.objects.all()
    serializer_class = RentalChargeSerializer
    filterset_fields = ['agreement', 'charge_type']


class VehicleDamageViewSet(viewsets.ModelViewSet):
    queryset = VehicleDamage.objects.all()
    serializer_class = VehicleDamageSerializer
    filterset_fields = ['agreement', 'severity']


class DigitalSignatureViewSet(viewsets.ModelViewSet):
    queryset = DigitalSignature.objects.all()
    serializer_class = DigitalSignatureSerializer
    filterset_fields = ['agreement', 'party_type']


class VehicleCheckViewSet(viewsets.ModelViewSet):
    queryset = VehicleCheck.objects.all()
    serializer_class = VehicleCheckSerializer
    filterset_fields = ['agreement', 'status', 'stage']


class VehiclePricingViewSet(viewsets.ModelViewSet):
    queryset = VehiclePricing.objects.all().order_by('-created_at')
    serializer_class = VehiclePricingSerializer
    search_fields = ['name', 'description', 'vehicles__display_name', 'vehicle_group__name']
    filterset_fields = ['apply_to', 'is_active', 'vehicle_group']
    ordering_fields = ['created_at', 'name', 'daily_rate']

    def get_queryset(self):
        qs = super().get_queryset()
        q = self.request.query_params.get('q')
        if q:
            qs = qs.filter(name__icontains=q) | \
                qs.filter(description__icontains=q) | \
                qs.filter(vehicles__display_name__icontains=q) | \
                qs.filter(vehicle_group__name__icontains=q)
        return qs.distinct()


class RentalPaymentViewSet(viewsets.ModelViewSet):
    """Viewset for recording and listing rental payments."""
    queryset = RentalPayment.objects.select_related('agreement', 'agreement__customer', 'agreement__vehicle').order_by('-paid_at')
    serializer_class = RentalPaymentSerializer
    filterset_fields = ['agreement', 'payment_method', 'status']
    ordering_fields = ['paid_at', 'amount', 'created_at']
    search_fields = ['agreement__agreement_no', 'reference', 'agreement__customer__full_name']

    def get_queryset(self):
        qs = super().get_queryset()
        q = self.request.query_params.get('q')
        if q:
            qs = qs.filter(agreement__agreement_no__icontains=q) | \
                qs.filter(reference__icontains=q) | \
                qs.filter(agreement__customer__full_name__icontains=q)
        return qs.distinct()

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request):
        """Aggregate payment summary across all agreements."""
        from django.db.models import Sum
        completed = self.queryset.filter(status='completed')
        total_collected = completed.aggregate(t=Sum('amount'))['t'] or 0
        total_invoices = RentalAgreement.objects.exclude(status='draft').aggregate(
            t=Sum('total_amount')
        )['t'] or 0
        return Response({
            'total_collected': str(total_collected),
            'total_invoices': str(total_invoices),
            'total_outstanding': str(total_invoices - total_collected),
            'payment_count': self.queryset.count(),
        })


class DriverHireRateViewSet(viewsets.ModelViewSet):
    """Global driver hire rate plans with discounts and markups."""
    queryset = DriverHireRate.objects.select_related('driver').order_by('-created_at')
    serializer_class = DriverHireRateSerializer
    filterset_fields = ['driver', 'status', 'default_rate_period', 'is_default']
    ordering_fields = ['created_at', 'daily_rate', 'weekly_rate', 'valid_from']
    search_fields = ['name', 'description', 'driver__first_name', 'driver__last_name']

    @action(detail=True, methods=['post'], url_path='compute')
    def compute(self, request, pk=None):
        """Compute a billing estimate for this plan.

        Body: { "period": "daily|hourly|weekly|monthly|weekend", "units": 1 }
        """
        plan = self.get_object()
        period = request.data.get('period', plan.default_rate_period)
        if period not in dict(DriverHireRate.RatePeriod.choices):
            return Response({'detail': f'Invalid period: {period}'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            units = int(request.data.get('units', 1))
        except (TypeError, ValueError):
            units = 1
        units = max(units, 1)
        return Response(plan.compute_charge(period, units))


class InvoiceViewSet(viewsets.ModelViewSet):
    """Invoice CRUD + generate-from-agreement / from-transfer actions."""

    queryset = Invoice.objects.all().select_related('agreement', 'customer', 'agreement__vehicle', 'transfer')
    serializer_class = InvoiceSerializer
    filterset_fields = ['status', 'customer', 'agreement', 'transfer']
    search_fields = ['invoice_no', 'customer__full_name', 'agreement__agreement_no', 'transfer__reference']
    ordering_fields = ['issue_date', 'due_date', 'total_amount', 'created_at']

    @action(detail=False, methods=['post'], url_path='from-transfer')
    def from_transfer(self, request):
        """Generate an invoice from a transfer booking.

        Body: { "transfer": <id>, "due_date": "YYYY-MM-DD" (optional), "notes": "" }
        """
        from apps.transfers.models import Transfer

        transfer_id = request.data.get('transfer')
        if not transfer_id:
            return Response({'detail': 'transfer is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            transfer = Transfer.objects.get(pk=transfer_id)
        except Transfer.DoesNotExist:
            return Response({'detail': 'Transfer not found'}, status=status.HTTP_404_NOT_FOUND)

        # Build line items from transfer fare components
        line_items = []

        if transfer.base_fare:
            line_items.append({
                'description': f'Transfer — {transfer.pickup_name} → {transfer.dropoff_name}',
                'quantity': 1,
                'unit_amount': float(transfer.base_fare),
                'total_amount': float(transfer.base_fare),
            })

        extras = [
            ('tolls_amount', 'Tolls'),
            ('parking_amount', 'Parking'),
            ('meet_greet_fee', 'Meet & Greet Fee'),
            ('waiting_fee', 'Waiting Fee'),
            ('child_seat_fee', 'Child Seat Fee'),
            ('driver_tip', 'Driver Tip'),
        ]
        for field, label in extras:
            val = getattr(transfer, field, 0) or 0
            if val and val > 0:
                line_items.append({
                    'description': label,
                    'quantity': 1,
                    'unit_amount': float(val),
                    'total_amount': float(val),
                })

        if transfer.tax_amount:
            line_items.append({
                'description': 'Tax',
                'quantity': 1,
                'unit_amount': float(transfer.tax_amount),
                'total_amount': float(transfer.tax_amount),
            })

        if transfer.discount_amount and transfer.discount_amount > 0:
            line_items.append({
                'description': 'Discount',
                'quantity': 1,
                'unit_amount': -float(transfer.discount_amount),
                'total_amount': -float(transfer.discount_amount),
            })

        subtotal = transfer.base_fare + transfer.tolls_amount + transfer.parking_amount + transfer.meet_greet_fee + transfer.waiting_fee + transfer.child_seat_fee + transfer.driver_tip + transfer.tax_amount
        invoice = Invoice.objects.create(
            transfer=transfer,
            status=Invoice.Status.DRAFT,
            issue_date=timezone.now().date(),
            due_date=request.data.get('due_date') or None,
            subtotal=subtotal,
            discount_total=transfer.discount_amount,
            taxes=transfer.tax_amount,
            total_amount=transfer.total_amount,
            amount_paid=transfer.amount_paid or 0,
            notes=request.data.get('notes', f'Invoice for transfer {transfer.reference}'),
            line_items=line_items,
            invoice_to={
                'name': transfer.passenger_name,
                'email': transfer.passenger_email,
                'phone': transfer.passenger_phone,
            },
        )

        # Set payment status based on amount paid
        if transfer.amount_paid and transfer.amount_paid > 0:
            if transfer.amount_paid >= transfer.total_amount:
                invoice.status = Invoice.Status.PAID
            else:
                invoice.status = Invoice.Status.PARTIALLY_PAID

        invoice.save()

        return Response(InvoiceSerializer(invoice).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='from-agreement')
    def from_agreement(self, request):
        """Generate an invoice from a rental agreement.

        Body: { "agreement": <id>, "due_date": "YYYY-MM-DD" (optional), "notes": "" }
        """
        agreement_id = request.data.get('agreement')
        if not agreement_id:
            return Response({'detail': 'agreement is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            agreement = RentalAgreement.objects.get(pk=agreement_id)
        except RentalAgreement.DoesNotExist:
            return Response({'detail': 'Agreement not found'}, status=status.HTTP_404_NOT_FOUND)

        # Build line items snapshot from agreement charges + base totals
        line_items = []
        for c in agreement.charges.all():
            line_items.append({
                'description': c.get_charge_type_display() + (f' — {c.description}' if c.description else ''),
                'quantity': float(c.quantity),
                'unit_amount': float(c.unit_amount),
                'total_amount': float(c.total_amount),
            })

        # Add damage line items from VehicleDamage records on this agreement
        damages_total = Decimal(0)
        for d in agreement.damages.all():
            cost = Decimal(d.repair_cost or 0)
            if cost > 0 or d.severity != 'none':
                desc = f'Damage — {d.location or "Unspecified"}'
                if d.description:
                    desc += f' ({d.description})'
                if d.severity and d.severity != 'none':
                    desc += f' [{d.get_severity_display()}]'
                line_items.append({
                    'description': desc,
                    'quantity': 1,
                    'unit_amount': float(cost),
                    'total_amount': float(cost),
                })
                damages_total += cost

        # Always include base rental as a line item
        if not any(li['description'].startswith('Base Rental') for li in line_items):
            rp = agreement.get_rate_period_display() if hasattr(agreement, 'get_rate_period_display') else agreement.rate_period
            # Compute number of days for the rental period
            end = agreement.actual_return_datetime or agreement.end_datetime
            delta_seconds = (end - agreement.start_datetime).total_seconds()
            days = max(int(math.floor(delta_seconds / 86400 + 0.5)), 1)
            if agreement.rate_period == 'weekend':
                days = 2
            # Determine the rate per unit (per day for daily, per week for weekly, etc.)
            rate_map = {
                'daily': ('daily_rate', 1),
                'weekly': ('weekly_rate', 7),
                'monthly': ('monthly_rate', 30),
                'weekend': ('weekend_rate', 1),
            }
            rate_field, per_days = rate_map.get(agreement.rate_period, ('daily_rate', 1))
            unit_rate = Decimal(getattr(agreement, rate_field) or 0)
            if unit_rate == 0 and agreement.daily_rate:
                unit_rate = Decimal(agreement.daily_rate)
                per_days = 1
            # For weekly/monthly: qty = days / per_days, unit = per-package rate
            # For daily/weekend: qty = days, unit = per-day rate
            if agreement.rate_period in ('weekly', 'monthly'):
                qty = days / per_days
            else:
                qty = days
            base_total = agreement.subtotal - sum(Decimal(str(li['total_amount'])) for li in line_items)
            line_items.insert(0, {
                'description': f'Base Rental ({rp})',
                'quantity': qty,
                'unit_amount': float(unit_rate),
                'total_amount': float(base_total),
            })

        invoice = Invoice.objects.create(
            agreement=agreement,
            customer=agreement.customer,
            status=Invoice.Status.DRAFT,
            issue_date=timezone.now().date(),
            due_date=request.data.get('due_date') or None,
            subtotal=agreement.subtotal,
            discount_total=agreement.discount_total,
            taxes=agreement.taxes,
            total_amount=agreement.total_amount,
            amount_paid=agreement.payments.filter(status='completed').aggregate(
                t=__import__('django.db.models', fromlist=['Sum']).Sum('amount')
            )['t'] or 0,
            notes=request.data.get('notes', ''),
            line_items=line_items,
        )

        # Update amount_paid
        from django.db.models import Sum
        paid = agreement.payments.filter(status='completed').aggregate(s=Sum('amount'))['s'] or 0
        invoice.amount_paid = paid
        invoice.balance_due = invoice.total_amount - paid
        if paid > 0 and paid < invoice.total_amount:
            invoice.status = Invoice.Status.PARTIALLY_PAID
        elif paid >= invoice.total_amount and invoice.total_amount > 0:
            invoice.status = Invoice.Status.PAID
        invoice.save()

        return Response(InvoiceSerializer(invoice).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='from-agreements')
    def from_agreements(self, request):
        """Generate a consolidated invoice from multiple rental agreements for one customer.

        Body: { "agreements": [<id>, ...], "due_date": "YYYY-MM-DD" (optional), "notes": "" }
        All agreements must belong to the same customer.
        """
        agreement_ids = request.data.get('agreements', [])
        if not agreement_ids or not isinstance(agreement_ids, list):
            return Response({'detail': 'agreements (list of IDs) is required'}, status=status.HTTP_400_BAD_REQUEST)

        agreements = list(RentalAgreement.objects.filter(pk__in=agreement_ids).order_by('-created_at'))
        if len(agreements) != len(agreement_ids):
            return Response({'detail': 'One or more agreements not found'}, status=status.HTTP_404_NOT_FOUND)

        # Validate single customer
        customer_ids = set(a.customer_id for a in agreements)
        if len(customer_ids) > 1:
            return Response({'detail': 'All agreements must belong to the same customer'}, status=status.HTTP_400_BAD_REQUEST)

        customer = agreements[0].customer

        # Build consolidated line items and damage records across all agreements
        line_items = []
        for ag in agreements:
            # Agreement header line (so the customer sees which agreement charges belong to)
            start_str = ag.start_datetime.strftime('%d %b %Y') if ag.start_datetime else ''
            end_dt = ag.actual_return_datetime or ag.end_datetime
            end_str = end_dt.strftime('%d %b %Y') if end_dt else ''
            plate = ag.vehicle.license_plate if ag.vehicle else ''
            date_range = f'{start_str} — {end_str}' if start_str and end_str else (start_str or end_str)
            header_desc = f'{ag.agreement_no}'
            if date_range:
                header_desc += f' — {date_range}'
            if plate:
                header_desc += f' --- {plate}'
            line_items.append({
                'description': header_desc,
                'quantity': '',
                'unit_amount': '',
                'total_amount': '',
                'is_header': True,
            })
            # Base rental for this agreement
            rp = ag.get_rate_period_display() if hasattr(ag, 'get_rate_period_display') else ag.rate_period
            end = ag.actual_return_datetime or ag.end_datetime
            days = max(int(math.floor((end - ag.start_datetime).total_seconds() / 86400 + 0.5)), 1)
            if ag.rate_period == 'weekend':
                days = 2
            rate_map = {
                'daily': ('daily_rate', 1),
                'weekly': ('weekly_rate', 7),
                'monthly': ('monthly_rate', 30),
                'weekend': ('weekend_rate', 1),
            }
            rate_field, per_days = rate_map.get(ag.rate_period, ('daily_rate', 1))
            unit_rate = Decimal(getattr(ag, rate_field) or 0)
            if unit_rate == 0 and ag.daily_rate:
                unit_rate = Decimal(ag.daily_rate)
                per_days = 1
            if ag.rate_period in ('weekly', 'monthly'):
                qty = days / per_days
            else:
                qty = days
            # Compute this agreement's base rental = subtotal - charges - damages
            charges_sum = sum(Decimal(str(c.total_amount or 0)) for c in ag.charges.all())
            damages_sum = sum(Decimal(str(d.repair_cost or 0)) for d in ag.damages.all())
            base_total = ag.subtotal - charges_sum - damages_sum
            if base_total > 0:
                line_items.append({
                    'description': f'Base Rental ({rp})',
                    'quantity': qty,
                    'unit_amount': float(unit_rate),
                    'total_amount': float(base_total),
                })
            # Charges
            for c in ag.charges.all():
                line_items.append({
                    'description': '  ' + c.get_charge_type_display() + (f' — {c.description}' if c.description else ''),
                    'quantity': float(c.quantity),
                    'unit_amount': float(c.unit_amount),
                    'total_amount': float(c.total_amount),
                })
            # Damages
            for d in ag.damages.all():
                cost = Decimal(d.repair_cost or 0)
                if cost > 0 or d.severity != 'none':
                    desc = f'  Damage — {d.location or "Unspecified"}'
                    if d.description:
                        desc += f' ({d.description})'
                    if d.severity and d.severity != 'none':
                        desc += f' [{d.get_severity_display()}]'
                    line_items.append({
                        'description': desc,
                        'quantity': 1,
                        'unit_amount': float(cost),
                        'total_amount': float(cost),
                    })

        # Aggregate totals across all agreements
        subtotal = sum(Decimal(ag.subtotal or 0) for ag in agreements)
        discount_total = sum(Decimal(ag.discount_total or 0) for ag in agreements)
        taxes = sum(Decimal(ag.taxes or 0) for ag in agreements)
        total_amount = sum(Decimal(ag.total_amount or 0) for ag in agreements)

        # Sum completed payments across all agreements
        from django.db.models import Sum
        paid = RentalPayment.objects.filter(
            agreement_id__in=agreement_ids, status='completed'
        ).aggregate(s=Sum('amount'))['s'] or Decimal(0)

        # Use the latest (first in list, ordered by -created_at) as primary agreement
        primary = agreements[0]

        invoice = Invoice.objects.create(
            agreement=primary,
            customer=customer,
            agreements=[{'id': ag.id, 'agreement_no': ag.agreement_no} for ag in agreements],
            status=Invoice.Status.DRAFT,
            issue_date=timezone.now().date(),
            due_date=request.data.get('due_date') or None,
            subtotal=subtotal,
            discount_total=discount_total,
            taxes=taxes,
            total_amount=total_amount,
            amount_paid=paid,
            notes=request.data.get('notes', ''),
            line_items=line_items,
        )

        invoice.balance_due = invoice.total_amount - paid
        if paid > 0 and paid < invoice.total_amount:
            invoice.status = Invoice.Status.PARTIALLY_PAID
        elif paid >= invoice.total_amount and invoice.total_amount > 0:
            invoice.status = Invoice.Status.PAID
        invoice.save()

        return Response(InvoiceSerializer(invoice).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='custom')
    def custom_invoice(self, request):
        """Create a fully custom invoice with user-defined line items.

        Body: {
            "customer": <id> (optional),
            "line_items": [{"description": "...", "vehicle": <id>, "quantity": 1, "unit_amount": 100, "total_amount": 100}],
            "discount_total": 0,
            "taxes": 0,
            "due_date": "YYYY-MM-DD" (optional),
            "notes": "" (optional),
            "invoice_to": {"name": "...", "company": "...", "email": "...", "phone": "...", "address": "..."} (optional)
        }
        """
        customer_id = request.data.get('customer')
        customer = None
        if customer_id:
            try:
                customer = Customer.objects.get(pk=customer_id)
            except Customer.DoesNotExist:
                return Response({'detail': 'Customer not found'}, status=status.HTTP_404_NOT_FOUND)

        raw_items = request.data.get('line_items', [])
        if not raw_items or not isinstance(raw_items, list):
            return Response({'detail': 'line_items (non-empty list) is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Pre-load vehicles for line-item lookups
        from apps.vehicles.models import Vehicle
        vehicle_ids = set()
        for li in raw_items:
            vid = li.get('vehicle')
            if vid:
                try:
                    vehicle_ids.add(int(vid))
                except (TypeError, ValueError):
                    pass
        vehicles_map = {}
        if vehicle_ids:
            for v in Vehicle.objects.filter(id__in=vehicle_ids):
                vehicles_map[v.id] = {'id': v.id, 'display_name': v.display_name, 'license_plate': v.license_plate}

        # Build validated line items
        line_items = []
        subtotal = Decimal(0)
        for idx, li in enumerate(raw_items):
            desc = (li.get('description') or '').strip()
            if not desc:
                continue
            qty = Decimal(str(li.get('quantity') or 1))
            unit = Decimal(str(li.get('unit_amount') or 0))
            total = qty * unit
            vid = li.get('vehicle')
            try:
                vid = int(vid) if vid else None
            except (TypeError, ValueError):
                vid = None
            line_items.append({
                'description': desc,
                'vehicle': vehicles_map.get(vid) if vid else None,
                'quantity': float(qty),
                'unit_amount': float(unit),
                'rate_period': (li.get('rate_period') or 'flat').strip()[:20],
                'total_amount': float(total),
            })
            subtotal += total

        if not line_items:
            return Response({'detail': 'At least one line item with a description is required'}, status=status.HTTP_400_BAD_REQUEST)

        discount = Decimal(str(request.data.get('discount_total') or 0))
        # Taxes can be sent as a computed amount (taxes) or a percentage (tax_percent)
        tax_percent = Decimal(str(request.data.get('tax_percent') or 0))
        taxes = Decimal(str(request.data.get('taxes') or 0))
        if tax_percent and not request.data.get('taxes'):
            taxes = (subtotal * tax_percent / Decimal(100)).quantize(Decimal('0.01'))
        total_amount = subtotal - discount + taxes

        invoice_to = request.data.get('invoice_to')
        if invoice_to is not None and not isinstance(invoice_to, dict):
            return Response({'detail': 'invoice_to must be an object'}, status=status.HTTP_400_BAD_REQUEST)

        # Require at least a name in invoice_to when no customer is selected
        if not customer and not (invoice_to and (invoice_to.get('name') or '').strip()):
            return Response(
                {'detail': 'Either a customer or invoice_to.name is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        invoice = Invoice.objects.create(
            customer=customer,
            status=Invoice.Status.DRAFT,
            issue_date=timezone.now().date(),
            due_date=request.data.get('due_date') or None,
            subtotal=subtotal,
            discount_total=discount,
            taxes=taxes,
            total_amount=total_amount,
            amount_paid=Decimal(0),
            notes=request.data.get('notes', ''),
            line_items=line_items,
            invoice_to=invoice_to or {},
            branding_color=(request.data.get('branding_color') or '#0d9488')[:7],
        )

        return Response(InvoiceSerializer(invoice).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'], url_path='update-custom')
    def update_custom(self, request, pk=None):
        """Update a custom (standalone) invoice's full content.

        Allowed fields: customer, line_items, discount_total, tax_percent,
        taxes, due_date, notes, invoice_to, branding_color, status, amount_paid.
        """
        invoice = self.get_object()

        # Only standalone invoices (no agreement linkage) should be editable here
        if invoice.agreement_id or (invoice.agreements and len(invoice.agreements)):
            return Response(
                {'detail': 'This endpoint is for custom invoices only. Agreement-based invoices cannot be edited here.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        customer_id = request.data.get('customer')
        customer = None
        if customer_id:
            try:
                customer = Customer.objects.get(pk=customer_id)
            except Customer.DoesNotExist:
                return Response({'detail': 'Customer not found'}, status=status.HTTP_404_NOT_FOUND)

        raw_items = request.data.get('line_items', [])
        if not raw_items or not isinstance(raw_items, list):
            return Response({'detail': 'line_items (non-empty list) is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Pre-load vehicles for line-item lookups
        from apps.vehicles.models import Vehicle
        vehicle_ids = set()
        for li in raw_items:
            vid = li.get('vehicle')
            if vid:
                try:
                    vehicle_ids.add(int(vid))
                except (TypeError, ValueError):
                    pass
        vehicles_map = {}
        if vehicle_ids:
            for v in Vehicle.objects.filter(id__in=vehicle_ids):
                vehicles_map[v.id] = {'id': v.id, 'display_name': v.display_name, 'license_plate': v.license_plate}

        # Build validated line items
        line_items = []
        subtotal = Decimal(0)
        for idx, li in enumerate(raw_items):
            desc = (li.get('description') or '').strip()
            if not desc:
                continue
            qty = Decimal(str(li.get('quantity') or 1))
            unit = Decimal(str(li.get('unit_amount') or 0))
            total = qty * unit
            vid = li.get('vehicle')
            try:
                vid = int(vid) if vid else None
            except (TypeError, ValueError):
                vid = None
            line_items.append({
                'description': desc,
                'vehicle': vehicles_map.get(vid) if vid else None,
                'quantity': float(qty),
                'unit_amount': float(unit),
                'rate_period': (li.get('rate_period') or 'flat').strip()[:20],
                'total_amount': float(total),
            })
            subtotal += total

        if not line_items:
            return Response({'detail': 'At least one line item with a description is required'}, status=status.HTTP_400_BAD_REQUEST)

        discount = Decimal(str(request.data.get('discount_total') or 0))
        tax_percent = Decimal(str(request.data.get('tax_percent') or 0))
        taxes = Decimal(str(request.data.get('taxes') or 0))
        if tax_percent and not request.data.get('taxes'):
            taxes = (subtotal * tax_percent / Decimal(100)).quantize(Decimal('0.01'))
        total_amount = subtotal - discount + taxes

        invoice_to = request.data.get('invoice_to')
        if invoice_to is not None and not isinstance(invoice_to, dict):
            return Response({'detail': 'invoice_to must be an object'}, status=status.HTTP_400_BAD_REQUEST)

        if not customer and not (invoice_to and (invoice_to.get('name') or '').strip()):
            return Response(
                {'detail': 'Either a customer or invoice_to.name is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Apply updates
        invoice.customer = customer
        invoice.line_items = line_items
        invoice.subtotal = subtotal
        invoice.discount_total = discount
        invoice.taxes = taxes
        invoice.total_amount = total_amount
        if 'amount_paid' in request.data:
            invoice.amount_paid = Decimal(str(request.data.get('amount_paid') or 0))
        if 'status' in request.data:
            invoice.status = request.data.get('status')
        if request.data.get('due_date') is not None:
            invoice.due_date = request.data.get('due_date') or None
        if request.data.get('notes') is not None:
            invoice.notes = request.data.get('notes', '')
        invoice.invoice_to = invoice_to or {}
        if request.data.get('branding_color'):
            invoice.branding_color = request.data.get('branding_color')[:7]
        invoice.save()

        return Response(InvoiceSerializer(invoice).data, status=status.HTTP_200_OK)
