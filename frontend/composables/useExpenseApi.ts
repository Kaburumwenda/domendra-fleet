/**
 * Expenses API composable — centralises all expense-related API calls
 * used across the Expenses dashboard tabs.
 */
export function useExpenseApi() {
  const { $api } = useNuxtApp()

  // ── Expenses ──────────────────────────────────────────────
  function fetchExpenses(params: Record<string, any> = {}) {
    return $api('/expenses/', { query: { page_size: 1000, ...params } })
  }
  function fetchExpense(id: number) {
    return $api(`/expenses/${id}/`)
  }
  function saveExpense(payload: FormData, id?: number) {
    const url = id ? `/expenses/${id}/` : '/expenses/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteExpense(id: number) {
    return $api(`/expenses/${id}/`, { method: 'DELETE' })
  }
  function fetchExpenseSummary(params: Record<string, any> = {}) {
    return $api('/expenses/summary/', { query: params })
  }
  function seedDemo() {
    return $api('/expenses/seed-demo/', { method: 'POST' })
  }

  // ── Workflow ─────────────────────────────────────────────
  function submitExpense(id: number) {
    return $api(`/expenses/${id}/submit/`, { method: 'POST' })
  }
  function approveExpense(id: number) {
    return $api(`/expenses/${id}/approve/`, { method: 'POST' })
  }
  function rejectExpense(id: number, reason = '') {
    return $api(`/expenses/${id}/reject/`, { method: 'POST', body: { reason } })
  }
  function markPaid(id: number, reference = '') {
    return $api(`/expenses/${id}/mark-paid/`, { method: 'POST', body: { payment_reference: reference } })
  }

  // ── Attachments ───────────────────────────────────────────
  function uploadAttachment(id: number, files: File | File[]) {
    const form = new FormData()
    if (Array.isArray(files)) files.forEach((f) => form.append('files', f))
    else form.append('files', files)
    return $api(`/expenses/${id}/upload-attachment/`, { method: 'POST', body: form })
  }
  function deleteAttachment(id: number, attachmentId: number) {
    return $api(`/expenses/${id}/attachments/${attachmentId}/`, { method: 'DELETE' })
  }

  // ── Comments ──────────────────────────────────────────────
  function addComment(id: number, body: string) {
    return $api(`/expenses/${id}/add-comment/`, { method: 'POST', body: { body } })
  }

  // ── Categories ─────────────────────────────────────────────
  function fetchCategories(params: Record<string, any> = {}) {
    return $api('/expenses/categories/', { query: { page_size: 1000, ...params } })
  }
  function saveCategory(payload: any, id?: number) {
    return id
      ? $api(`/expenses/categories/${id}/`, { method: 'PATCH', body: payload })
      : $api('/expenses/categories/', { method: 'POST', body: payload })
  }
  function deleteCategory(id: number) {
    return $api(`/expenses/categories/${id}/`, { method: 'DELETE' })
  }

  // ── Recurring ─────────────────────────────────────────────
  function fetchRecurring(params: Record<string, any> = {}) {
    return $api('/expenses/recurring/', { query: { page_size: 1000, ...params } })
  }
  function saveRecurring(payload: any, id?: number) {
    return id
      ? $api(`/expenses/recurring/${id}/`, { method: 'PATCH', body: payload })
      : $api('/expenses/recurring/', { method: 'POST', body: payload })
  }
  function deleteRecurring(id: number) {
    return $api(`/expenses/recurring/${id}/`, { method: 'DELETE' })
  }
  function materializeRecurring() {
    return $api('/expenses/recurring/materialize/', { method: 'POST' })
  }

  // ── Budgets ───────────────────────────────────────────────
  function fetchBudgets(params: Record<string, any> = {}) {
    return $api('/expenses/budgets/', { query: { page_size: 1000, ...params } })
  }
  function fetchBudgetSummary(params: Record<string, any> = {}) {
    return $api('/expenses/budgets/summary/', { query: params })
  }
  function saveBudget(payload: any, id?: number) {
    return id
      ? $api(`/expenses/budgets/${id}/`, { method: 'PATCH', body: payload })
      : $api('/expenses/budgets/', { method: 'POST', body: payload })
  }
  function deleteBudget(id: number) {
    return $api(`/expenses/budgets/${id}/`, { method: 'DELETE' })
  }

  return {
    // expenses
    fetchExpenses,
    fetchExpense,
    saveExpense,
    deleteExpense,
    fetchExpenseSummary,
    seedDemo,
    // workflow
    submitExpense,
    approveExpense,
    rejectExpense,
    markPaid,
    // attachments
    uploadAttachment,
    deleteAttachment,
    // comments
    addComment,
    // categories
    fetchCategories,
    saveCategory,
    deleteCategory,
    // recurring
    fetchRecurring,
    saveRecurring,
    deleteRecurring,
    materializeRecurring,
    // budgets
    fetchBudgets,
    fetchBudgetSummary,
    saveBudget,
    deleteBudget,
  }
}
