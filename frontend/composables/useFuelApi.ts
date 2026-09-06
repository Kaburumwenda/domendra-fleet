/**
 * Fuel & Energy API composable — centralises all fuel-related API calls
 * used across the Fuel & Energy dashboard tabs.
 */
export function useFuelApi() {
  const { $api } = useNuxtApp()

  function fetchTransactions(params: Record<string, any> = {}) {
    return $api('/fuel/transactions/', { query: params })
  }
  function fetchAnalytics(params: Record<string, any> = {}) {
    return $api('/fuel/transactions/analytics/', { query: params })
  }
  function saveTransaction(payload: FormData, id?: number) {
    const url = id ? `/fuel/transactions/${id}/` : '/fuel/transactions/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteTransaction(id: number) {
    return $api(`/fuel/transactions/${id}/`, { method: 'DELETE' })
  }

  function fetchCards(params: Record<string, any> = {}) {
    return $api('/fuel/cards/', { query: params })
  }
  function saveCard(payload: any, id?: number) {
    return id
      ? $api(`/fuel/cards/${id}/`, { method: 'PATCH', body: payload })
      : $api('/fuel/cards/', { method: 'POST', body: payload })
  }
  function deleteCard(id: number) {
    return $api(`/fuel/cards/${id}/`, { method: 'DELETE' })
  }
  function syncCard(id: number) {
    return $api(`/fuel/cards/${id}/sync/`, { method: 'POST' })
  }
  function syncAllCards() {
    return $api('/fuel/cards/sync-all/', { method: 'POST' })
  }

  function fetchCharging(params: Record<string, any> = {}) {
    return $api('/fuel/charging/', { query: params })
  }
  function fetchChargingSummary(params: Record<string, any> | number = 30) {
    const query = typeof params === 'number' ? { days: params } : params
    return $api('/fuel/charging/summary/', { query })
  }
  function saveChargingSession(payload: any, id?: number) {
    return id
      ? $api(`/fuel/charging/${id}/`, { method: 'PATCH', body: payload })
      : $api('/fuel/charging/', { method: 'POST', body: payload })
  }
  function deleteChargingSession(id: number) {
    return $api(`/fuel/charging/${id}/`, { method: 'DELETE' })
  }

  function fetchIdling(params: Record<string, any> = {}) {
    return $api('/fuel/idling/', { query: params })
  }
  function fetchIdlingSummary(params: Record<string, any> | number = 30) {
    const query = typeof params === 'number' ? { days: params } : params
    return $api('/fuel/idling/summary/', { query })
  }
  function saveIdlingEvent(payload: any, id?: number) {
    return id
      ? $api(`/fuel/idling/${id}/`, { method: 'PATCH', body: payload })
      : $api('/fuel/idling/', { method: 'POST', body: payload })
  }
  function deleteIdlingEvent(id: number) {
    return $api(`/fuel/idling/${id}/`, { method: 'DELETE' })
  }

  function fetchSchedules(params: Record<string, any> = {}) {
    return $api('/fuel/charge-schedules/', { query: params })
  }
  function saveSchedule(payload: any, id?: number) {
    return id
      ? $api(`/fuel/charge-schedules/${id}/`, { method: 'PATCH', body: payload })
      : $api('/fuel/charge-schedules/', { method: 'POST', body: payload })
  }
  function deleteSchedule(id: number) {
    return $api(`/fuel/charge-schedules/${id}/`, { method: 'DELETE' })
  }

  function fetchBudgets(params: Record<string, any> = {}) {
    return $api('/fuel/budgets/', { query: params })
  }
  function fetchBudgetSummary() {
    return $api('/fuel/budgets/summary/')
  }
  function saveBudget(payload: any, id?: number) {
    return id
      ? $api(`/fuel/budgets/${id}/`, { method: 'PATCH', body: payload })
      : $api('/fuel/budgets/', { method: 'POST', body: payload })
  }
  function deleteBudget(id: number) {
    return $api(`/fuel/budgets/${id}/`, { method: 'DELETE' })
  }

  function fetchFraud(params: Record<string, any> = {}) {
    return $api('/fuel/fraud/', { query: params })
  }
  function fetchFraudSummary() {
    return $api('/fuel/fraud/summary/')
  }
  function resolveFraud(id: number, note = '') {
    return $api(`/fuel/fraud/${id}/resolve/`, { method: 'POST', body: { status_note: note } })
  }
  function dismissFraud(id: number, note = '') {
    return $api(`/fuel/fraud/${id}/dismiss/`, { method: 'POST', body: { status_note: note } })
  }
  function reviewFraud(id: number, note = '') {
    return $api(`/fuel/fraud/${id}/review/`, { method: 'POST', body: { status_note: note } })
  }
  function reopenFraud(id: number, note = '') {
    return $api(`/fuel/fraud/${id}/reopen/`, { method: 'POST', body: { status_note: note } })
  }

  return {
    fetchTransactions,
    fetchAnalytics,
    saveTransaction,
    deleteTransaction,
    fetchCards,
    saveCard,
    deleteCard,
    syncCard,
    syncAllCards,
    fetchCharging,
    fetchChargingSummary,
    saveChargingSession,
    deleteChargingSession,
    fetchIdling,
    fetchIdlingSummary,
    saveIdlingEvent,
    deleteIdlingEvent,
    fetchSchedules,
    saveSchedule,
    deleteSchedule,
    fetchBudgets,
    fetchBudgetSummary,
    saveBudget,
    deleteBudget,
    fetchFraud,
    fetchFraudSummary,
    resolveFraud,
    dismissFraud,
    reviewFraud,
    reopenFraud,
  }
}
