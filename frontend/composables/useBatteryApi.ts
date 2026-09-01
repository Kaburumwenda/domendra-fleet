/**
 * Battery API composable — centralises all battery-related API calls.
 */
export function useBatteryApi() {
  const { $api } = useNuxtApp()

  // ── Battery CRUD ──
  function fetchBatteries(params: Record<string, any> = {}) {
    return $api('/batteries/', { query: params })
  }
  function fetchBattery(id: string | number) {
    return $api(`/batteries/${id}/`)
  }
  function saveBattery(payload: Record<string, any>, id?: number) {
    const url = id ? `/batteries/${id}/` : '/batteries/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteBattery(id: number) {
    return $api(`/batteries/${id}/`, { method: 'DELETE' })
  }

  // ── Battery actions ──
  function installBattery(id: number, payload: Record<string, any>) {
    return $api(`/batteries/${id}/install/`, { method: 'POST', body: payload })
  }
  function uninstallBattery(id: number, payload: Record<string, any> = {}) {
    return $api(`/batteries/${id}/uninstall/`, { method: 'POST', body: payload })
  }
  function chargeBattery(id: number, payload: Record<string, any> = {}) {
    return $api(`/batteries/${id}/charge/`, { method: 'POST', body: payload })
  }
  function retireBattery(id: number, payload: Record<string, any> = {}) {
    return $api(`/batteries/${id}/retire/`, { method: 'POST', body: payload })
  }

  // ── Catalog & analytics ──
  function fetchCatalog() {
    return $api('/batteries/catalog/')
  }
  function fetchStats() {
    return $api('/batteries/stats/')
  }
  function fetchNeedsReplacement() {
    return $api('/batteries/needs-replacement/')
  }

  // ── Readings ──
  function fetchReadings(params: Record<string, any> = {}) {
    return $api('/batteries/readings/', { query: params })
  }
  function saveReading(payload: Record<string, any>, id?: number) {
    const url = id ? `/batteries/readings/${id}/` : '/batteries/readings/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteReading(id: number) {
    return $api(`/batteries/readings/${id}/`, { method: 'DELETE' })
  }

  // ── Movements ──
  function fetchMovements(params: Record<string, any> = {}) {
    return $api('/batteries/movements/', { query: params })
  }

  // ── Charge Cycles ──
  function fetchCycles(params: Record<string, any> = {}) {
    return $api('/batteries/cycles/', { query: params })
  }
  function saveCycle(payload: Record<string, any>, id?: number) {
    const url = id ? `/batteries/cycles/${id}/` : '/batteries/cycles/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteCycle(id: number) {
    return $api(`/batteries/cycles/${id}/`, { method: 'DELETE' })
  }

  // ── Replacements ──
  function fetchReplacements(params: Record<string, any> = {}) {
    return $api('/batteries/replacements/', { query: params })
  }
  function saveReplacement(payload: Record<string, any>, id?: number) {
    const url = id ? `/batteries/replacements/${id}/` : '/batteries/replacements/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteReplacement(id: number) {
    return $api(`/batteries/replacements/${id}/`, { method: 'DELETE' })
  }

  return {
    fetchBatteries, fetchBattery, saveBattery, deleteBattery,
    installBattery, uninstallBattery, chargeBattery, retireBattery,
    fetchCatalog, fetchStats, fetchNeedsReplacement,
    fetchReadings, saveReading, deleteReading,
    fetchMovements,
    fetchCycles, saveCycle, deleteCycle,
    fetchReplacements, saveReplacement, deleteReplacement,
  }
}
