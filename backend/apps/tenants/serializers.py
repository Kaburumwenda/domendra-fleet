from rest_framework import serializers

from .models import Tenant


class TenantSettingsSerializer(serializers.ModelSerializer):
    currency_choices = serializers.SerializerMethodField()

    class Meta:
        model = Tenant
        fields = [
            'short_name',
            'full_name',
            'email',
            'country',
            'mobile_number',
            'address',
            'logo',
            'currency',
            'currency_choices',
        ]
        read_only_fields = ['currency_choices']

    def get_currency_choices(self, obj):
        return [{'value': c[0], 'label': c[1]} for c in Tenant.Currency.choices]
