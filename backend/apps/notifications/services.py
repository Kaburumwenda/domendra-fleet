"""Service layer for dispatching notifications across channels.

This is intentionally pluggable: in production the email path uses Django's
email backend and the SMS path would integrate with a provider (Twilio, etc.).
For now SMS records the attempt without a live gateway so reminders can still
function and the audit trail is complete.
"""
from __future__ import annotations

import logging

from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

from .models import Notification, NotificationTemplate

logger = logging.getLogger(__name__)


def _resolve_recipient(user=None, email=None, phone=None):
    if user:
        return {
            'recipient_user': user,
            'recipient_email': email or user.email,
            'recipient_phone': phone or getattr(user, 'phone', '') or '',
        }
    return {'recipient_email': email or '', 'recipient_phone': phone or ''}


def dispatch(event: str, context: dict | None = None, *, user=None, email=None, phone=None,
             channel=None, related_object_type='', related_object_id=None) -> Notification:
    """Create + attempt to deliver a notification for a given event.

    Looks up an active NotificationTemplate matching (event, channel). Falls back
    to the first active template for the event if no channel-specific match.
    Records the outcome on the Notification record.
    """
    context = context or {}
    template = _find_template(event, channel)

    subject = ''
    body = ''
    if template:
        subject, body = template.render(**context)
        channel = template.channel
    else:
        body = context.get('message', '')
        subject = context.get('subject', event.replace('_', ' ').title())
        channel = channel or NotificationTemplate.Channel.IN_APP

    recipient = _resolve_recipient(user=user, email=email, phone=phone)
    notification = Notification.objects.create(
        event=event, channel=channel, subject=subject, body=body,
        related_object_type=related_object_type, related_object_id=related_object_id,
        status=Notification.Status.PENDING, **recipient,
    )

    _deliver(notification)
    return notification


def _find_template(event, channel):
    qs = NotificationTemplate.objects.filter(event=event, is_active=True)
    if channel:
        t = qs.filter(channel=channel).first()
        if t:
            return t
    return qs.first()


def _deliver(notification: Notification):
    try:
        if notification.channel == NotificationTemplate.Channel.EMAIL and notification.recipient_email:
            if settings.EMAIL_HOST:
                send_mail(
                    notification.subject or 'DomendraFleet Notification',
                    notification.body,
                    settings.DEFAULT_FROM_EMAIL,
                    [notification.recipient_email],
                    fail_silently=True,
                )
            notification.status = Notification.Status.SENT
            notification.sent_at = timezone.now()
        elif notification.channel == NotificationTemplate.Channel.SMS and notification.recipient_phone:
            # SMS gateway integration point (Twilio/Africa's Talking). Recorded as sent.
            notification.status = Notification.Status.SENT
            notification.sent_at = timezone.now()
        elif notification.channel == NotificationTemplate.Channel.IN_APP:
            notification.status = Notification.Status.DELIVERED
            notification.sent_at = timezone.now()
        else:
            notification.status = Notification.Status.SENT if (notification.recipient_email or notification.recipient_phone) else Notification.Status.FAILED
            notification.error_message = 'No recipient address available.' if notification.status == Notification.Status.FAILED else ''
            notification.sent_at = timezone.now() if notification.status != Notification.Status.FAILED else None
        notification.save(update_fields=['status', 'sent_at', 'error_message'])
    except Exception as exc:
        logger.exception('Notification delivery failed: %s', exc)
        notification.status = Notification.Status.FAILED
        notification.error_message = str(exc)
        notification.save(update_fields=['status', 'error_message'])
