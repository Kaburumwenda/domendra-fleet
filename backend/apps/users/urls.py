from django.urls import path

from .views import (
    CustomTokenRefreshView,
    LoginView,
    LogoutView,
    MeView,
    RegisterView,
    UserCreateView,
    UserDetailView,
    UserListView,
    UserPasswordResetView,
)

app_name = 'users'

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('refresh/', CustomTokenRefreshView.as_view(), name='refresh'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('me/', MeView.as_view(), name='me'),
    # User management (RBAC-administered)
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/create/', UserCreateView.as_view(), name='user-create'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),
    path('users/<int:pk>/reset-password/', UserPasswordResetView.as_view(), name='user-reset-password'),
]
