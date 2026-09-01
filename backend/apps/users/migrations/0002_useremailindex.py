"""Migration for the UserEmailIndex model stored in the public schema."""
from django.db import migrations, models


class Migration(migrations.Migration):

    atomic = False

    dependencies = [
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='UserEmailIndex',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('email', models.EmailField(db_index=True, max_length=254, unique=True)),
                ('schema_name', models.CharField(max_length=63)),
                ('user_id', models.BigIntegerField(blank=True, help_text='Cross-reference for invalidation', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'db_table': 'users_user_email_index',
                'verbose_name': 'User email → tenant index',
                'verbose_name_plural': 'User email → tenant indices',
            },
        ),
        migrations.AddIndex(
            model_name='useremailindex',
            index=models.Index(fields=['email'], name='users_eml_idx'),
        ),
    ]
