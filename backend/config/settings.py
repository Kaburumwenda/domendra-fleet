"""
Django settings for DomendraFleet SaaS – production-ready multi-tenant configuration.

Architecture:
  • Schema-based multi-tenancy via django-tenants (PostgreSQL)
  • DRF + SimpleJWT for stateless API auth
  • Celery + Redis for background tasks
  • Django Channels for WebSocket real-time features
"""

from pathlib import Path
from datetime import timedelta
from decouple import config, Csv

BASE_DIR = Path(__file__).resolve().parent.parent

# ──────────────────────────────────────────────
# Core security
# ──────────────────────────────────────────────
SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1,10.0.2.2', cast=Csv())

# ──────────────────────────────────────────────
# Multi-tenancy (django-tenants)
# ──────────────────────────────────────────────
TENANT_MODEL = 'tenants.Tenant'
TENANT_DOMAIN_MODEL = 'tenants.Domain'
PUBLIC_SCHEMA_NAME = 'public'
SHOW_PUBLIC_IF_NO_TENANT_FOUND = True

SHARED_APPS = [
    # django-tenants core
    'django_tenants',
    # Tenant & billing (shared / SaaS-level data)
    'apps.tenants',
    'apps.billing',
    'apps.superadmin',
    # Custom user model must be in both shared and tenant apps
    'apps.users',
    # RBAC (shared so public-schema superadmin can have roles/permissions too)
    'apps.rbac',
    # Django built-ins (public schema infrastructure)
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # JWT token blacklist (shared so the super-admin in public schema can
    # issue/blacklist tokens without a tenant schema)
    'rest_framework_simplejwt.token_blacklist',
    # Third-party framework apps
    'rest_framework',
    'drf_spectacular',
    'corsheaders',
    'django_filters',
    'django_celery_beat',
    'django_celery_results',
    'django_extensions',
    'storages',
    'channels',
]

TENANT_APPS = [
    # Django built-ins that must exist per-tenant
    'django.contrib.auth',
    'django.contrib.contenttypes',
    # JWT token blacklist (per-tenant so FK to users_user resolves)
    'rest_framework_simplejwt.token_blacklist',
    # Per-tenant business apps
    'apps.users',
    'apps.rbac',
    'apps.vehicles',
    'apps.lessors',
    'apps.contacts',
    'apps.documents',
    'apps.inspections',
    'apps.issues',
    'apps.reminders',
    'apps.services',
    'apps.inventory',
    'apps.dashboard',
    'apps.fuel',
    'apps.reports',
    'apps.garage',
    'apps.accidents',
    'apps.dispatch',
    'apps.audit',
    'apps.equipment',
    'apps.telematics',
    'apps.locations',
    'apps.ifta',
    'apps.tires',
    'apps.batteries',
    'apps.recalls',
    'apps.notifications',
    'apps.dqf',
    'apps.rentals',
    'apps.transfers',
    'apps.expenses',
    'apps.financing',
]

INSTALLED_APPS = list(SHARED_APPS) + [
    app for app in TENANT_APPS if app not in SHARED_APPS
]

# ──────────────────────────────────────────────
# Middleware
# ──────────────────────────────────────────────
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'apps.tenants.middleware.TenantResolutionMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'apps.billing.middleware.ApiUsageBillingMiddleware',
    'apps.audit.middleware.AuditMiddleware',
]

ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# ──────────────────────────────────────────────
# Database (PostgreSQL + django-tenants)
# ──────────────────────────────────────────────
DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'NAME': config('DB_NAME', default='domendradb'),
        'USER': config('DB_USER', default='postgres'),
        'PASSWORD': config('DB_PASSWORD', default='postgres'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

DATABASE_ROUTERS = ('django_tenants.routers.TenantSyncRouter',)

# ──────────────────────────────────────────────
# Custom user model (per-tenant)
# ──────────────────────────────────────────────
AUTH_USER_MODEL = 'users.User'

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ──────────────────────────────────────────────
# REST Framework
# ──────────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ),
    'DEFAULT_PAGINATION_CLASS': 'config.pagination.StandardPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/day',
        'user': '10000/day',
    },
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=365),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=365),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'TOKEN_OBTAIN_SERIALIZER': 'apps.users.serializers.TenantTokenObtainPairSerializer',
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'DomendraFleet SaaS API',
    'DESCRIPTION': 'Premium multi-tenant Fleet Management Platform',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'COMPONENT_SPLIT_REQUEST': True,
}

# ──────────────────────────────────────────────
# CORS
# ──────────────────────────────────────────────
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = config('CORS_ALLOWED_ORIGINS', default='http://localhost:3000', cast=Csv())
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    'accept', 'authorization', 'content-type', 'origin',
    'user-agent', 'x-csrftoken', 'x-requested-with', 'x-tenant-schema',
]
CORS_ALLOW_METHODS = [
    'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS',
]
CORS_EXPOSE_HEADERS = [
    'content-disposition', 'content-length', 'content-type',
    'x-tenant-schema',
]
CSRF_TRUSTED_ORIGINS = config('CSRF_TRUSTED_ORIGINS', default='http://localhost:3000', cast=Csv())

# ──────────────────────────────────────────────
# Channels (WebSockets)
# ──────────────────────────────────────────────
ASGI_APPLICATION = 'config.asgi.application'
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [config('CHANNELS_REDIS_URL', default='redis://localhost:6379/2')],
        },
    },
}

# ──────────────────────────────────────────────
# Celery
# ──────────────────────────────────────────────
CELERY_BROKER_URL = config('CELERY_BROKER_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND = config('CELERY_RESULT_BACKEND', default='redis://localhost:6379/1')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Africa/Nairobi'
CELERY_ENABLE_UTC = True
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'
CELERY_TASK_ALWAYS_EAGER = config('CELERY_TASK_ALWAYS_EAGER', default=False, cast=bool)
CELERY_TASK_EAGER_PROPAGATES = True

# ──────────────────────────────────────────────
# API Billing
# ──────────────────────────────────────────────
BILLING_RATE_PER_1000_REQUESTS = config('BILLING_RATE_PER_1000_REQUESTS', default=0.007, cast=float)
BILLING_FREE_TIER_REQUESTS = config('BILLING_FREE_TIER_REQUESTS', default=10000, cast=int)

# ──────────────────────────────────────────────
# External APIs
# ──────────────────────────────────────────────
GOOGLE_MAPS_API_KEY = config('GOOGLE_MAPS_API_KEY', default='')
VIN_API_BASE_URL = config('VIN_API_BASE_URL', default='https://vpic.nhtsa.dot.gov/api')

# ──────────────────────────────────────────────
# Fuel card provider credentials (optional)
# ──────────────────────────────────────────────
WEX_API_TOKEN = config('WEX_API_TOKEN', default='')
COMDATA_API_TOKEN = config('COMDATA_API_TOKEN', default='')
FLEETCOR_API_TOKEN = config('FLEETCOR_API_TOKEN', default='')
BP_API_TOKEN = config('BP_API_TOKEN', default='')

# ──────────────────────────────────────────────
# SMS gateway (optional)
# ──────────────────────────────────────────────
TWILIO_ACCOUNT_SID = config('TWILIO_ACCOUNT_SID', default='')
TWILIO_AUTH_TOKEN = config('TWILIO_AUTH_TOKEN', default='')
TWILIO_FROM_NUMBER = config('TWILIO_FROM_NUMBER', default='')

# ──────────────────────────────────────────────
# Internationalization
# ──────────────────────────────────────────────
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Nairobi'
USE_I18N = True
USE_TZ = True

# ──────────────────────────────────────────────
# Static & Media files
# ──────────────────────────────────────────────
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# ──────────────────────────────────────────────
# AWS S3 media storage (django-storages)
# Activated when AWS_ACCESS_KEY_ID is set in .env
# ──────────────────────────────────────────────
AWS_ACCESS_KEY_ID = config('AWS_ACCESS_KEY_ID', default='')
AWS_SECRET_ACCESS_KEY = config('AWS_SECRET_ACCESS_KEY', default='')
AWS_STORAGE_BUCKET_NAME = config('AWS_STORAGE_BUCKET_NAME', default='')
AWS_S3_REGION_NAME = config('AWS_S3_REGION_NAME', default='eu-central-1')
AWS_S3_FILE_OVERWRITE = config('AWS_S3_FILE_OVERWRITE', default=False, cast=bool)
_default_acl = config('AWS_DEFAULT_ACL', default='public-read')
AWS_DEFAULT_ACL = _default_acl if _default_acl and _default_acl.lower() != 'none' else None
AWS_S3_VERIFY = config('AWS_S3_VERIFY', default=True, cast=bool)
AWS_QUERYSTRING_AUTH = config('AWS_QUERYSTRING_AUTH', default=False, cast=bool)
AWS_S3_SIGNATURE_NAME = config('AWS_S3_SIGNATURE_NAME', default='s3v4')

USE_S3_MEDIA = bool(AWS_ACCESS_KEY_ID and AWS_STORAGE_BUCKET_NAME)

# If boto3 isn't installed, fall back to local filesystem storage
try:
    import boto3  # noqa: F401
except ImportError:
    USE_S3_MEDIA = False

if USE_S3_MEDIA:
    AWS_S3_CUSTOM_DOMAIN = f'{AWS_STORAGE_BUCKET_NAME}.s3.{AWS_S3_REGION_NAME}.amazonaws.com'
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/'
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

STORAGES = {
    'default': {
        'BACKEND': 'storages.backends.s3boto3.S3Boto3Storage' if USE_S3_MEDIA else 'django.core.files.storage.FileSystemStorage',
    },
    'staticfiles': {
        'BACKEND': 'django.contrib.staticfiles.storage.StaticFilesStorage',
    },
}

# ──────────────────────────────────────────────
# Default primary key
# ──────────────────────────────────────────────
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ──────────────────────────────────────────────
# Email
# ──────────────────────────────────────────────
EMAIL_HOST = config('EMAIL_HOST', default='')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_USE_SSL = config('EMAIL_USE_SSL', default=False, cast=bool)
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='noreply@domendrafleet.com')

# ──────────────────────────────────────────────
# File upload limits
# ──────────────────────────────────────────────
DATA_UPLOAD_MAX_MEMORY_SIZE = 50 * 1024 * 1024  # 50 MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 50 * 1024 * 1024
