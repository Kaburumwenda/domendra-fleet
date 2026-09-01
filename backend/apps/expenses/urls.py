from django.urls import path

from .views import (
    ExpenseAttachmentViewSet,
    ExpenseBudgetViewSet,
    ExpenseCategoryViewSet,
    ExpenseViewSet,
    RecurringExpenseViewSet,
)

app_name = 'expenses'

urlpatterns = [
    # Categories
    path('categories/', ExpenseCategoryViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='category-list'),
    path('categories/<int:pk>/', ExpenseCategoryViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='category-detail'),

    # Budgets
    path('budgets/', ExpenseBudgetViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='budget-list'),
    path('budgets/<int:pk>/', ExpenseBudgetViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='budget-detail'),
    path('budgets/summary/', ExpenseBudgetViewSet.as_view({'get': 'summary'}), name='budget-summary'),

    # Recurring
    path('recurring/', RecurringExpenseViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='recurring-list'),
    path('recurring/<int:pk>/', RecurringExpenseViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='recurring-detail'),
    path('recurring/materialize/', RecurringExpenseViewSet.as_view({'post': 'materialize'}), name='recurring-materialize'),

    # Attachments (read-only)
    path('attachments/', ExpenseAttachmentViewSet.as_view({'get': 'list'}), name='attachment-list'),
    path('attachments/<int:pk>/', ExpenseAttachmentViewSet.as_view({'get': 'retrieve'}), name='attachment-detail'),

    # Expenses
    path('', ExpenseViewSet.as_view({
        'get': 'list', 'post': 'create',
    }), name='expense-list'),
    path('summary/', ExpenseViewSet.as_view({'get': 'summary'}), name='expense-summary'),
    path('seed-demo/', ExpenseViewSet.as_view({'post': 'seed_demo'}), name='expense-seed-demo'),
    path('<int:pk>/', ExpenseViewSet.as_view({
        'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy',
    }), name='expense-detail'),
    path('<int:pk>/submit/', ExpenseViewSet.as_view({'post': 'submit'}), name='expense-submit'),
    path('<int:pk>/approve/', ExpenseViewSet.as_view({'post': 'approve'}), name='expense-approve'),
    path('<int:pk>/reject/', ExpenseViewSet.as_view({'post': 'reject'}), name='expense-reject'),
    path('<int:pk>/mark-paid/', ExpenseViewSet.as_view({'post': 'mark_paid'}), name='expense-mark-paid'),
    path('<int:pk>/upload-attachment/', ExpenseViewSet.as_view({'post': 'upload_attachment'}), name='expense-upload-attachment'),
    path('<int:pk>/attachments/<int:attachment_id>/', ExpenseViewSet.as_view({'delete': 'delete_attachment'}), name='expense-delete-attachment'),
    path('<int:pk>/add-comment/', ExpenseViewSet.as_view({'post': 'add_comment'}), name='expense-add-comment'),
]
