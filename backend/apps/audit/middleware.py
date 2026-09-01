import json
import logging

from django.db import connection

from .models import AuditLog

logger = logging.getLogger(__name__)

WRITE_METHODS = {'POST', 'PUT', 'PATCH', 'DELETE'}
LOGIN_PATHS = ('/api/auth/login/', '/api/auth/logout/')
SKIP_PATHS = ('/api/auth/refresh/', '/api/schema/', '/api/docs/')


class AuditMiddleware:
    """Logs all write operations and login attempts to the AuditLog."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        if request.path.startswith('/api/'):
            # Always log login/logout attempts (success and failure)
            if request.path in LOGIN_PATHS and request.method == 'POST':
                self._log(request, response, is_login=True)
            elif request.method in WRITE_METHODS and not request.path.startswith(SKIP_PATHS):
                self._log(request, response)

        return response

    def _log(self, request, response, is_login=False):
        try:
            user = getattr(request, 'user', None)
            if user and not user.is_authenticated:
                user = None

            if is_login:
                if request.path == '/api/auth/login/':
                    action = AuditLog.Action.LOGIN
                else:
                    action = AuditLog.Action.LOGOUT
                resource_type = 'auth'
            else:
                action = {
                    'POST': AuditLog.Action.CREATE,
                    'PUT': AuditLog.Action.UPDATE,
                    'PATCH': AuditLog.Action.UPDATE,
                    'DELETE': AuditLog.Action.DELETE,
                }.get(request.method, AuditLog.Action.VIEW)

                resource_type = request.path.split('/api/')[1].split('/')[0] if '/api/' in request.path else ''

            details = {}
            if request.content_type and 'json' in request.content_type:
                try:
                    body = json.loads(request.body) if request.body else {}
                    if isinstance(body, dict):
                        details = {k: v for k, v in body.items() if k not in ('password', 'token', 'refresh')}
                except (json.JSONDecodeError, UnicodeDecodeError):
                    pass

            ip = request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0] or request.META.get('REMOTE_ADDR')

            login_success = is_login and response.status_code == 200

            AuditLog.objects.create(
                user=user if login_success else None,
                action=action,
                resource_type=resource_type,
                resource_id=request.path,
                method=request.method,
                path=request.path,
                details=details,
                ip_address=ip,
                status_code=response.status_code,
            )
        except Exception as exc:
            logger.debug('Audit log failed: %s', exc)
