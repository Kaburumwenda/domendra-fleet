from rest_framework import serializers

from .models import ReportExecution, ReportTemplate, ScheduledReport


class ReportTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReportTemplate
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'created_by']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['created_by'] = request.user
        return super().create(validated_data)


class ScheduledReportSerializer(serializers.ModelSerializer):
    template_name = serializers.CharField(source='template.name', read_only=True)
    class Meta:
        model = ScheduledReport
        fields = '__all__'
        read_only_fields = ['created_at', 'last_run', 'next_run']


class ReportExecutionSerializer(serializers.ModelSerializer):
    template_name = serializers.CharField(source='template.name', read_only=True)
    class Meta:
        model = ReportExecution
        fields = '__all__'
        read_only_fields = ['started_at', 'completed_at', 'file', 'status', 'error_message']
