/**
 * Vehicle Monitor API composable — real-time fleet activity monitoring.
 *
 * Backed by the ``vehicle_monitor`` @action on the VehicleViewSet, this
 * composable centralises all calls used across the Vehicle Monitor dashboard.
 */
export function useVehicleMonitorApi() {
  const { $api } = useNuxtApp()

  /** Fetch the full vehicle monitor payload (summary + per-vehicle rows). */
  function fetchMonitor(params: Record<string, any> = {}) {
    return $api('/vehicles/vehicles/vehicle-monitor/', { query: params })
  }

  return { fetchMonitor }
}
