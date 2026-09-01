from django.urls import path

from .views import (
    AssignRoleView,
    PermissionGroupListView,
    RoleAssignmentDetailView,
    RoleAssignmentListView,
    RoleDetailView,
    RoleListView,
    UserDetailWithRolesView,
    UserListWithRolesView,
    UserPermissionsView,
    UserRolesView,
    clone_role_view,
)

app_name = 'rbac'

urlpatterns = [
    # Permission catalog (read-only, grouped by module)
    path('permissions/', PermissionGroupListView.as_view(), name='permission-groups'),
    # Role CRUD
    path('roles/', RoleListView.as_view(), name='role-list'),
    path('roles/<int:pk>/', RoleDetailView.as_view(), name='role-detail'),
    path('roles/<int:pk>/clone/', clone_role_view, name='role-clone'),
    # Role assignments (user ↔ role)
    path('assignments/', RoleAssignmentListView.as_view(), name='assignment-list'),
    path('assignments/<int:pk>/', RoleAssignmentDetailView.as_view(), name='assignment-detail'),
    path('assign/', AssignRoleView.as_view(), name='assign-role'),
    # Current user's permissions and roles (for frontend auth)
    path('me/permissions/', UserPermissionsView.as_view(), name='my-permissions'),
    path('me/roles/', UserRolesView.as_view(), name='my-roles'),
    # User list with roles (for user management UI)
    path('users/', UserListWithRolesView.as_view(), name='user-list-with-roles'),
    path('users/<int:pk>/', UserDetailWithRolesView.as_view(), name='user-detail-with-roles'),
]
