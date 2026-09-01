"""Serializers for the RBAC app."""

from rest_framework import serializers

from apps.users.models import User
from apps.users.serializers import UserSerializer

from .models import Permission, Role, RoleAssignment
from .permissions_registry import PERMISSIONS_REGISTRY


class PermissionSerializer(serializers.ModelSerializer):
    code = serializers.CharField(read_only=True)

    class Meta:
        model = Permission
        fields = ['id', 'module', 'action', 'label', 'description', 'code']


class PermissionGroupSerializer(serializers.Serializer):
    """Groups permissions by module for the permission matrix UI."""

    module = serializers.CharField()
    label = serializers.CharField()
    icon = serializers.CharField()
    permissions = PermissionSerializer(many=True)


class RoleSerializer(serializers.ModelSerializer):
    permission_codes = serializers.SerializerMethodField()
    permissions = serializers.PrimaryKeyRelatedField(
        queryset=Permission.objects.all(),
        many=True,
        required=False,
    )

    class Meta:
        model = Role
        fields = [
            'id', 'name', 'key', 'description', 'color', 'icon',
            'is_system', 'is_default', 'user_count',
            'permissions', 'permission_codes',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'is_system', 'is_default', 'user_count', 'created_at', 'updated_at']

    def get_permission_codes(self, obj):
        """Return list of ``module:action`` strings for this role."""
        return [p.code for p in obj.permissions.all()]

    def validate_key(self, value):
        """Ensure key is unique and does not collide with system role keys."""
        instance = self.instance
        system_keys = {r['key'] for r in __import__(
            'apps.rbac.permissions_registry', fromlist=['SYSTEM_ROLES']
        ).SYSTEM_ROLES}
        if value in system_keys and not instance:
            raise serializers.ValidationError('This key is reserved for system roles.')
        qs = Role.objects.filter(key=value)
        if instance:
            qs = qs.exclude(pk=instance.pk)
        if qs.exists():
            raise serializers.ValidationError('A role with this key already exists.')
        return value


class RoleDetailSerializer(RoleSerializer):
    """Extended role serializer with grouped permissions for detail view."""

    permission_groups = serializers.SerializerMethodField()

    class Meta(RoleSerializer.Meta):
        fields = RoleSerializer.Meta.fields + ['permission_groups']

    def get_permission_groups(self, obj):
        perm_ids = set(obj.permissions.values_list('id', flat=True))
        groups = []
        for module, label, icon, actions in PERMISSIONS_REGISTRY:
            perms = []
            for action, action_label, desc in actions:
                p = Permission.objects.filter(module=module, action=action).first()
                if p:
                    perms.append({
                        'id': p.id,
                        'module': module,
                        'action': action,
                        'label': action_label,
                        'description': desc,
                        'code': p.code,
                        'granted': p.id in perm_ids,
                    })
            groups.append({
                'module': module,
                'label': label,
                'icon': icon,
                'permissions': perms,
            })
        return groups


class RoleAssignmentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    role = RoleSerializer(read_only=True)
    assigned_by_name = serializers.CharField(source='assigned_by.full_name', read_only=True, default='')

    class Meta:
        model = RoleAssignment
        fields = [
            'id', 'user', 'role', 'is_primary',
            'assigned_by', 'assigned_by_name',
            'created_at',
        ]
        read_only_fields = ['id', 'assigned_by', 'created_at']


class AssignRoleSerializer(serializers.Serializer):
    """Payload for assigning a role to a user."""

    user_id = serializers.IntegerField()
    role_id = serializers.IntegerField()
    is_primary = serializers.BooleanField(required=False, default=False)

    def validate_user_id(self, value):
        if not User.objects.filter(id=value).exists():
            raise serializers.ValidationError('User does not exist.')
        return value

    def validate_role_id(self, value):
        if not Role.objects.filter(id=value).exists():
            raise serializers.ValidationError('Role does not exist.')
        return value


class CloneRoleSerializer(serializers.Serializer):
    """Payload for cloning an existing role into a new custom role."""

    name = serializers.CharField(max_length=80)
    key = serializers.CharField(max_length=50)
    description = serializers.CharField(required=False, allow_blank=True, default='')
    color = serializers.CharField(required=False, allow_blank=True, default='#6366f1')
    icon = serializers.CharField(required=False, allow_blank=True, default='mdi-shield-account-outline')

    def validate_key(self, value):
        system_keys = {r['key'] for r in __import__(
            'apps.rbac.permissions_registry', fromlist=['SYSTEM_ROLES']
        ).SYSTEM_ROLES}
        if value in system_keys:
            raise serializers.ValidationError('This key is reserved for system roles.')
        if Role.objects.filter(key=value).exists():
            raise serializers.ValidationError('A role with this key already exists.')
        return value


class UserWithRolesSerializer(UserSerializer):
    """Extends the standard user serializer with role assignment details."""

    roles = serializers.SerializerMethodField()
    primary_role_name = serializers.SerializerMethodField()

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ['roles', 'primary_role_name']

    def get_roles(self, obj):
        assignments = obj.role_assignments.all()
        result = []
        for assignment in assignments:
            result.append({
                'id': assignment.role.id,
                'name': assignment.role.name,
                'key': assignment.role.key,
                'color': assignment.role.color,
                'icon': assignment.role.icon,
                'is_primary': assignment.is_primary,
            })
        return result

    def get_primary_role_name(self, obj):
        assignment = obj.role_assignments.filter(is_primary=True).first()
        if not assignment:
            assignment = obj.role_assignments.first()
        return assignment.role.name if assignment else None
