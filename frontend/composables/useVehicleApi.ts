/**
 * Vehicle API composable — centralises all vehicle-related API calls
 * used across the Vehicle Management dashboard tabs.
 */
export function useVehicleApi() {
  const { $api } = useNuxtApp()

  function fetchVehicles(params: Record<string, any> = {}) {
    return $api('/vehicles/vehicles/', { query: params })
  }
  function fetchVehicle(id: string | number, params: Record<string, any> = {}) {
    return $api(`/vehicles/vehicles/${id}/`, { query: params })
  }
  function saveVehicle(payload: FormData | Record<string, any>, id?: number) {
    const url = id ? `/vehicles/vehicles/${id}/` : '/vehicles/vehicles/'
    const method = id ? 'PATCH' : 'POST'
    return $api(url, { method, body: payload })
  }
  function deleteVehicle(id: number) {
    return $api(`/vehicles/vehicles/${id}/`, { method: 'DELETE' })
  }
  function fetchAnalytics(params: Record<string, any> = {}) {
    return $api('/vehicles/vehicles/analytics/', { query: params })
  }
  function fetchProfitLoss(id: string | number, params: Record<string, any> = {}) {
    return $api(`/vehicles/vehicles/${id}/profit-loss/`, { query: params })
  }
  function fetchCostOfOwnership(id: string | number, params: Record<string, any> = {}) {
    return $api(`/vehicles/vehicles/${id}/cost-of-ownership/`, { query: params })
  }
  function createMeterEntry(id: string | number, payload: any) {
    return $api(`/vehicles/vehicles/${id}/meter-entry/`, { method: 'POST', body: payload })
  }
  function decodeVin(vin: string) {
    return $api('/vehicles/vin-decode/', { method: 'POST', body: { vin } })
  }
  // Groups
  function fetchGroups(params: Record<string, any> = {}) {
    return $api('/vehicles/groups/', { query: params })
  }
  function saveGroup(payload: any, id?: number) {
    return id
      ? $api(`/vehicles/groups/${id}/`, { method: 'PATCH', body: payload })
      : $api('/vehicles/groups/', { method: 'POST', body: payload })
  }
  function deleteGroup(id: number) {
    return $api(`/vehicles/groups/${id}/`, { method: 'DELETE' })
  }
  // Vehicle Types
  function fetchVehicleTypes(params: Record<string, any> = {}) {
    return $api('/vehicles/vehicle-types/', { query: params })
  }
  function saveVehicleType(payload: any, id?: number) {
    return id
      ? $api(`/vehicles/vehicle-types/${id}/`, { method: 'PATCH', body: payload })
      : $api('/vehicles/vehicle-types/', { method: 'POST', body: payload })
  }
  function deleteVehicleType(id: number) {
    return $api(`/vehicles/vehicle-types/${id}/`, { method: 'DELETE' })
  }
  // Catalog
  function fetchMakes() { return $api('/vehicles/catalog/makes/') }
  function fetchBodyTypes() { return $api('/vehicles/catalog/body-types/') }
  function fetchModels(params: Record<string, any> = {}) {
    return $api('/vehicles/catalog/models/', { query: params })
  }
  function saveMake(payload: any, id?: number) {
    return id
      ? $api(`/vehicles/catalog/makes/${id}/`, { method: 'PATCH', body: payload })
      : $api('/vehicles/catalog/makes/', { method: 'POST', body: payload })
  }
  function deleteMake(id: number) {
    return $api(`/vehicles/catalog/makes/${id}/`, { method: 'DELETE' })
  }
  function saveBodyType(payload: any, id?: number) {
    return id
      ? $api(`/vehicles/catalog/body-types/${id}/`, { method: 'PATCH', body: payload })
      : $api('/vehicles/catalog/body-types/', { method: 'POST', body: payload })
  }
  function deleteBodyType(id: number) {
    return $api(`/vehicles/catalog/body-types/${id}/`, { method: 'DELETE' })
  }
  function saveModel(payload: any, id?: number) {
    return id
      ? $api(`/vehicles/catalog/models/${id}/`, { method: 'PATCH', body: payload })
      : $api('/vehicles/catalog/models/', { method: 'POST', body: payload })
  }
  function deleteModel(id: number) {
    return $api(`/vehicles/catalog/models/${id}/`, { method: 'DELETE' })
  }
  function seedCatalog(payload: any) {
    return $api('/vehicles/catalog/seed/', { method: 'POST', body: payload })
  }

  return {
    fetchVehicles, fetchVehicle, saveVehicle, deleteVehicle,
    fetchAnalytics, fetchProfitLoss, fetchCostOfOwnership, createMeterEntry, decodeVin,
    fetchGroups, saveGroup, deleteGroup,
    fetchVehicleTypes, saveVehicleType, deleteVehicleType,
    fetchMakes, fetchBodyTypes, fetchModels,
    saveMake, deleteMake, saveBodyType, deleteBodyType, saveModel, deleteModel, seedCatalog,
  }
}
