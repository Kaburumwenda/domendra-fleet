from rest_framework import serializers

from .models import Issue, IssuePhoto, PartUsage, TimeLog, WorkOrder, WorkOrderNote


class IssuePhotoSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = IssuePhoto
        fields = '__all__'
        read_only_fields = ['created_at']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image:
            url = obj.image.url
            if request:
                return request.build_absolute_uri(url)
            return url
        return ''


class IssueSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.CharField(source='vehicle.display_name', read_only=True)
    vendor_name = serializers.CharField(source='vendor.full_name', read_only=True)
    reported_by_name = serializers.CharField(source='reported_by.full_name', read_only=True)
    has_work_order = serializers.BooleanField(read_only=True)
    work_order_id = serializers.IntegerField(read_only=True)
    issue_photos = IssuePhotoSerializer(many=True, read_only=True)

    class Meta:
        model = Issue
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at', 'reported_by']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['reported_by'] = request.user
        return super().create(validated_data)


class WorkOrderNoteSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.full_name', read_only=True)

    class Meta:
        model = WorkOrderNote
        fields = '__all__'
        read_only_fields = ['created_at', 'author']

    def create(self, validated_data):
        request = self.context.get('request')
        if request and request.user:
            validated_data['author'] = request.user
        return super().create(validated_data)


class TimeLogSerializer(serializers.ModelSerializer):
    mechanic_name = serializers.CharField(source='mechanic.full_name', read_only=True)

    class Meta:
        model = TimeLog
        fields = '__all__'


class PartUsageSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source='inventory_item.name', read_only=True)
    item_sku = serializers.CharField(source='inventory_item.sku', read_only=True)
    total_cost = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)

    class Meta:
        model = PartUsage
        fields = '__all__'


class WorkOrderSerializer(serializers.ModelSerializer):
    issue_title = serializers.CharField(source='issue.title', read_only=True)
    vehicle_name = serializers.CharField(source='issue.vehicle.display_name', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.full_name', read_only=True)
    notes = WorkOrderNoteSerializer(many=True, read_only=True)
    time_logs = TimeLogSerializer(many=True, read_only=True)
    parts_used = PartUsageSerializer(many=True, read_only=True)
    total_cost = serializers.DecimalField(read_only=True, max_digits=12, decimal_places=2)

    class Meta:
        model = WorkOrder
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']


class WorkOrderCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkOrder
        fields = ['issue', 'assigned_to', 'assignment_type', 'status', 'estimated_cost', 'internal_notes', 'external_notes']
