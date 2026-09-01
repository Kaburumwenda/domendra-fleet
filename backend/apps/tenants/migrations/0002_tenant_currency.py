from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('tenants', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='tenant',
            name='currency',
            field=models.CharField(
                choices=[
                    ('USD', 'USD ($)'),
                    ('EUR', 'EUR (\u20ac)'),
                    ('GBP', 'GBP (\u00a3)'),
                    ('KES', 'KES (KSh)'),
                    ('NGN', 'NGN (\u20a6)'),
                    ('ZAR', 'ZAR (R)'),
                    ('AED', 'AED (\u062f.\u0625)'),
                    ('SAR', 'SAR (\ufdfc)'),
                    ('INR', 'INR (\u20b9)'),
                    ('CAD', 'CAD (C$)'),
                    ('AUD', 'AUD (A$)'),
                    ('JPY', 'JPY (\u00a5)'),
                    ('CNY', 'CNY (\u00a5)'),
                    ('BRL', 'BRL (R$)'),
                    ('GHS', 'GHS (\u20b5)'),
                    ('TZS', 'TZS (TSh)'),
                    ('UGX', 'UGX (USh)'),
                    ('RWF', 'RWF (FRw)'),
                    ('ETB', 'ETB (Br)'),
                ],
                default='USD',
                max_length=3,
            ),
        ),
    ]
