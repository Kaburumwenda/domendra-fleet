"""API views for the RBAC app."""

from django.db import transaction
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes as perm_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.users.models import User

from .models import Permission, Role, RoleAssignment
from .permissions import HasPermission
from .permissions_registry import PERMISSIONS_REGISTRY
from .serializers import (
    AssignRoleSerializer,
    CloneRoleSerializer,
    PermissionGroupSerializer,
    PermissionSerializer,
    RoleAssignmentSerializer,
    RoleDetailSerializer,
    RoleSerializer,
    UserWithRolesSerializer,
)


# ----------------------------------------------------------------------
# Permission catalog (read-only)
# ----------------------------------------------------------------------
class PermissionGroupListView(APIView):
    """Returns all available permissions grouped by module.

    Used by the frontend permission matrix grid in the role editor.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Auto-create any missing Permission rows so the matrix always
        # shows the full catalog even before the seed migration runs.
        for module, label, icon, actions in PERMISSIONS_REGISTRY:
            for action, action_label, desc in actions:
                Permission.objects.get_or_create(
                    module=module,
                    action=action,
                    defaults={'label': action_label, 'description': desc},
                )

        groups = []
        for module, label, icon, actions in PERMISSIONS_REGISTRY:
            perms_qs = Permission.objects.filter(module=module)
            perms = []
            for action, action_label, desc in actions:
                try:
                    p = perms_qs.get(action=action)
                except Permission.DoesNotExist:
                    continue
                perms.append({
                    'id': p.id,
                    'module': module,
                    'action': action,
                    'label': action_label,
                    'description': desc,
                    'code': p.code,
                })
            groups.append({
                'module': module,
                'label': label,
                'icon': icon,
                'permissions': perms,
            })
        return Response(PermissionGroupSerializer(groups, many=True).data)


# ----------------------------------------------------------------------
# Roles CRUD
# ----------------------------------------------------------------------
class RoleListView(generics.ListCreateAPIView):
    queryset = Role.objects.all().order_by('is_system', 'name')
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated, HasPermission]

    # Creating a role requires users:assign; listing is open to any
    # authenticated user so UI role-selects work everywhere.
    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), HasPermission('users:assign')]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        role = serializer.save()
        role.user_count = 0
        role.save(update_fields=['user_count'])

    def list(self, request, *args, **kwargs):
        # Auto-seed system roles if missing (e.g. fresh tenant before
        # the seed migration has run).
        self._ensure_system_roles()

        # Enrich with permission count for the roles table progress bars.
        queryset = self.filter_queryset(self.get_queryset())
        data = []
        for role in queryset:
            ser = RoleSerializer(role)
            item = ser.data
            item['permission_count'] = role.permissions.count()
            data.append(item)
        return Response(data)

    @staticmethod
    def _ensure_system_roles():
        """Create any missing system roles from the registry.

        Permissions are auto-created lazily by ``PermissionGroupListView``
        or the seed migration; here we just ensure the Role rows exist.
        """
        from apps.rbac.permissions_registry import SYSTEM_ROLES
        for role_data in SYSTEM_ROLES:
            if not Role.objects.filter(key=role_data['key']).exists():
                Role.objects.create(
                    key=role_data['key'],
                    name=role_data['name'],
                    description=role_data['description'],
                    color=role_data['color'],
                    icon=role_data['icon'],
                    is_system=role_data['is_system'],
                    is_default=role_data['is_default'],
                )


class RoleDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Role.objects.all()
    serializer_class = RoleDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.request.method == 'GET':
            return [IsAuthenticated()]
        return [IsAuthenticated(), HasPermission('users:assign')]

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        # Preserve name/key for system roles
        if instance.is_system:
            request.data.pop('key', None)

        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        if getattr(instance, '_prefetched_objects_cache', None):
            instance._prefetched_objects_cache = {}

        return Response(serializer.data)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.is_system:
            return Response(
                {'detail': 'System roles cannot be deleted. You may modify their permissions instead.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if instance.assignments.exists():
            return Response(
                {'detail': 'Cannot delete a role that is currently assigned to users. Remove all assignments first.'},
                status=status.HTTP_409_CONFLICT,
            )
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['POST'])
@perm_classes([IsAuthenticated, HasPermission('users:assign')])
def clone_role_view(request, pk):
    """Clone an existing role (system or custom) into a new custom role.

    The new role inherits the source role's permission set; metadata
    (name, key, description, color, icon) is taken from the request body
    and validated via ``CloneRoleSerializer``.
    """
    source = Role.objects.filter(pk=pk).first()
    if source is None:
        return Response({'detail': 'Role not found.'}, status=status.HTTP_404_NOT_FOUND)
    serializer = CloneRoleSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    with transaction.atomic():
        new_role = Role.objects.create(
            name=data['name'],
            key=data['key'],
            description=data.get('description', ''),
            color=data.get('color', '#6366f1') or '#6366f1',
            icon=data.get('icon', 'mdi-shield-account-outline') or 'mdi-shield-account-outline',
            is_system=False,
            is_default=False,
            user_count=0,
        )
        # Copy the permission set
        source_perms = list(source.permissions.all())
        if source_perms:
            new_role.permissions.set(source_perms)

    return Response(
        RoleDetailSerializer(new_role).data,
        status=status.HTTP_201_CREATED,
    )


# ----------------------------------------------------------------------
# Role assignments (user ↔ role)
# ----------------------------------------------------------------------
class RoleAssignmentListView(generics.ListCreateAPIView):
    queryset = RoleAssignment.objects.all().select_related('user', 'role', 'assigned_by')
    serializer_class = RoleAssignmentSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated(), HasPermission('users:assign')]
        return [IsAuthenticated()]

    def perform_create(self, serializer):
        serializer.save(assigned_by=self.request.user)
        # role.user_count is maintained automatically via signals.


class RoleAssignmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = RoleAssignment.objects.all().select_related('user', 'role', 'assigned_by')
    serializer_class = RoleAssignmentSerializer
    permission_classes = [IsAuthenticated, HasPermission('users:assign')]

    def perform_destroy(self, instance):
        super().perform_destroy(instance)
        # role.user_count is maintained automatically via signals.


class AssignRoleView(APIView):
    """Convenience endpoint: POST with user_id + role_id to assign a role."""

    permission_classes = [IsAuthenticated, HasPermission('users:assign')]

    def post(self, request):
        serializer = AssignRoleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = User.objects.get(id=serializer.validated_data['user_id'])
        role = Role.objects.get(id=serializer.validated_data['role_id'])
        is_primary = serializer.validated_data['is_primary']

        with transaction.atomic():
            assignment, created = RoleAssignment.objects.get_or_create(
                user=user,
                role=role,
                defaults={
                    'is_primary': is_primary,
                    'assigned_by': request.user,
                },
            )
            if not created:
                # Update is_primary if changed
                if assignment.is_primary != is_primary:
                    assignment.is_primary = is_primary
                    assignment.save(update_fields=['is_primary'])
            # role.user_count is maintained automatically via signals.

        return Response(
            RoleAssignmentSerializer(assignment).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class UserRolesView(APIView):
    """List all roles assigned to the current user."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        assignments = request.user.role_assignments.select_related('role').all()
        roles = []
        primary = None
        for a in assignments:
            roles.append({
                'id': a.role.id,
                'name': a.role.name,
                'key': a.role.key,
                'color': a.role.color,
                'icon': a.role.icon,
                'is_primary': a.is_primary,
            })
            if a.is_primary and primary is None:
                primary = {
                    'id': a.role.id,
                    'name': a.role.name,
                    'key': a.role.key,
                    'color': a.role.color,
                    'icon': a.role.icon,
                }
        # If no role assignments exist, fall back to the legacy User.role field
        if not roles:
            roles.append({
                'id': None,
                'name': request.user.get_role_display(),
                'key': request.user.role,
                'color': 'primary',
                'icon': 'mdi-shield-account',
                'is_primary': True,
            })
            primary = roles[0]
        elif primary is None and roles:
            primary = roles[0]
            roles[0]['is_primary'] = True
        return Response({'roles': roles, 'primary_role': primary})


class UserPermissionsView(APIView):
    """Return all permission codes granted to the current user.

    This is consumed by the frontend to show/hide UI elements based on
    permissions without round-tripping to the server on every action.
    The response includes the *effective* (hierarchy-expanded) permission
    set so the frontend can check ``can(module, action)`` directly.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # Admin role always gets all permissions
        if user.role == 'admin' or user.is_superuser:
            all_codes = [f'{m}:{a}' for m, _l, _i, acts in PERMISSIONS_REGISTRY
                         for a, _al, _ad in acts]
            return Response({
                'permissions': all_codes,
                'is_admin': True,
                'roles': [{'key': 'admin', 'name': 'Administrator'}],
            })

        # Collect permissions from all role assignments
        perm_codes = set()
        role_keys = []
        for assignment in user.role_assignments.select_related('role').prefetch_related('role__permissions').all():
            role_keys.append({'key': assignment.role.key, 'name': assignment.role.name})
            for perm in assignment.role.permissions.all():
                perm_codes.add(perm.code)

        # Fall back to legacy role-based permissions if no assignments
        if not perm_codes:
            perm_codes = self._legacy_role_permissions(user.role)

        return Response({
            'permissions': sorted(perm_codes),
            'is_admin': False,
            'roles': role_keys,
        })

    def _legacy_role_permissions(self, role):
        """Fallback: derive permissions from flat User.role field."""
        from apps.rbac.permissions_registry import SYSTEM_ROLES
        for sr in SYSTEM_ROLES:
            if sr['key'] == role:
                return {f'{m}:{a}' for m, a in sr['permissions']}
        return set()


# ----------------------------------------------------------------------
# User list with roles (for user management in RBAC UI)
# ----------------------------------------------------------------------
class UserListWithRolesView(generics.ListAPIView):
    serializer_class = UserWithRolesSerializer
    permission_classes = [IsAuthenticated, HasPermission('users:view')]

    def get_queryset(self):
        return User.objects.all().order_by('-date_joined').prefetch_related(
            'role_assignments__role',
        )


class UserDetailWithRolesView(generics.RetrieveUpdateAPIView):
    serializer_class = UserWithRolesSerializer
    permission_classes = [IsAuthenticated]
    queryset = User.objects.all().prefetch_related('role_assignments__role')

    def get_permissions(self):
        if self.request.method == 'GET':
            return [IsAuthenticated()]
        return [IsAuthenticated(), HasPermission('users:update')]
