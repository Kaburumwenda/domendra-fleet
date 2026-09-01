from rest_framework import serializers

from .models import Reminder


class ReminderSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    is_due = serializers.BooleanField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)

    class Meta:
        model = Reminder
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'last_triggered_value']
