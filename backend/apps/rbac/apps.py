from django.apps import AppConfig


class RbacConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.rbac'
    label = 'rbac'

    def ready(self):
        # Importing signals registers the receivers.
        from . import signals  # noqa: F401
