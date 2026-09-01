from django.db import migrations, models


def copy_name_to_short_full(apps, schema_editor):
    Tenant = apps.get_model('tenants', 'Tenant')
    for tenant in Tenant.objects.all():
        tenant.short_name = (tenant.name or '')[:80]
        tenant.full_name = tenant.name or ''
        tenant.save(update_fields=['short_name', 'full_name'])


class Migration(migrations.Migration):

    dependencies = [
        ('tenants', '0002_tenant_currency'),
    ]

    operations = [
        migrations.AddField(
            model_name='tenant',
            name='short_name',
            field=models.CharField(max_length=80, default=''),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='tenant',
            name='full_name',
            field=models.CharField(max_length=200, blank=True, default=''),
        ),
        migrations.RunPython(copy_name_to_short_full, migrations.RunPython.noop),
        migrations.RemoveField(
            model_name='tenant',
            name='name',
        ),
    ]
