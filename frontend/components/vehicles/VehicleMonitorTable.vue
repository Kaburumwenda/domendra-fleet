<template>
  <v-data-table
    :headers="headers"
    :items="vehicles"
    :loading="loading"
    hover
    items-per-page="15"
  >
    <template #item.display_name="{ item }">
      <div class="d-flex align-center ga-2 cursor-pointer" @click="$emit('select', item)">
        <v-avatar size="32" :color="monitorStatusColor(item.monitor_status)" variant="tonal">
          <v-icon size="18">{{ monitorStatusIcon(item.monitor_status) }}</v-icon>
        </v-avatar>
        <div>
          <div class="text-body-2 font-weight-medium">{{ item.display_name }}</div>
          <div class="text-caption text-medium-emphasis">{{ item.license_plate || '&mdash;' }}</div>
        </div>
      </div>
    </template>
    <template #item.monitor_status="{ item }">
      <v-chip :color="monitorStatusColor(item.monitor_status)" size="small" variant="tonal">
        <v-icon start size="x-small">{{ monitorStatusIcon(item.monitor_status) }}</v-icon>
        {{ monitorStatusLabel(item.monitor_status) }}
      </v-chip>
    </template>
    <template #item.driver="{ item }">
      <span class="text-body-2">{{ item.assigned_driver_name || '&mdash;' }}</span>
    </template>
    <template #item.current_mileage="{ item }">
      <span class="text-body-2">{{ formatNumber(item.current_mileage) }} {{ item.mileage_unit }}</span>
    </template>
    <template #item.live_signal="{ item }">
      <v-chip :color="liveStatusColor(item.telematics)" size="x-small" variant="tonal">
        <v-icon start size="x-small">{{ liveStatusIcon(item.telematics) }}</v-icon>
        {{ liveStatusLabel(item.telematics) }}
      </v-chip>
    </template>
    <template #item.speed="{ item }">
      <span v-if="item.telematics" class="text-body-2">
        {{ item.telematics.speed ? item.telematics.speed.toFixed(0) : 0 }} {{ item.mileage_unit === 'miles' ? 'mph' : 'km/h' }}
      </span>
      <span v-else class="text-medium-emphasis">&mdash;</span>
    </template>
    <template #item.total_fuel_used="{ item }">
      <div class="d-flex flex-column">
        <span v-if="item.total_fuel_used > 0" class="text-body-2">{{ formatFuel(item.total_fuel_used) }}</span>
        <span class="text-caption text-medium-emphasis">{{ fmtMoney(item.total_fuel_cost) }}</span>
      </div>
    </template>
    <template #item.state_of_charge="{ item }">
      <div v-if="isElectric(item.fuel_type) && item.state_of_charge != null" class="d-flex align-center ga-2">
        <v-progress-linear
          :model-value="item.state_of_charge"
          :color="batteryColor(item.state_of_charge)"
          height="6"
          rounded
          style="max-width: 90px;"
        />
        <span class="text-body-2">{{ item.state_of_charge }}%</span>
      </div>
      <div v-else-if="item.battery_summary" class="d-flex flex-column">
        <span class="text-body-2 font-weight-medium">
          {{ item.battery_summary.count }} {{ item.battery_summary.count === 1 ? 'battery' : 'batteries' }}
        </span>
        <span class="text-caption text-medium-emphasis">{{ item.battery_summary.brands || '&mdash;' }}</span>
      </div>
      <span v-else class="text-medium-emphasis">&mdash;</span>
    </template>
    <template #item.open_alerts="{ item }">
      <v-chip v-if="item.open_alerts" color="error" size="x-small" variant="flat">{{ item.open_alerts }}</v-chip>
      <span v-else>&mdash;</span>
    </template>
    <template #item.open_issues="{ item }">
      <v-chip v-if="item.open_issues" color="warning" size="x-small" variant="flat">{{ item.open_issues }}</v-chip>
      <span v-else>&mdash;</span>
    </template>
    <template #item.last_reported_at="{ item }">
      <span v-if="item.telematics" :class="item.telematics.is_stale ? 'text-warning' : ''">
        {{ timeAgo(item.telematics.last_reported_at) }}
      </span>
      <span v-else class="text-medium-emphasis">&mdash;</span>
    </template>
    <template #item.action="{ item }">
      <v-btn icon="mdi-eye-outline" size="x-small" variant="text" @click="$emit('select', item)" />
    </template>
  </v-data-table>
</template>

<script setup lang="ts">
const props = defineProps<{
  vehicles: any[]
  loading?: boolean
  currencySymbol?: string
}>()

defineEmits<{ select: [item: any] }>()

const headers = [
  { title: 'Vehicle', key: 'display_name', align: 'start' as const },
  { title: 'Status', key: 'monitor_status' },
  { title: 'Driver', key: 'driver' },
  { title: 'Mileage', key: 'current_mileage' },
  { title: 'Signal', key: 'live_signal' },
  { title: 'Speed', key: 'speed' },
  { title: 'Fuel', key: 'total_fuel_used' },
  { title: 'Battery', key: 'state_of_charge' },
  { title: 'Alerts', key: 'open_alerts' },
  { title: 'Issues', key: 'open_issues' },
  { title: 'Last Seen', key: 'last_reported_at' },
  { title: '', key: 'action', sortable: false },
]

const { fmtMoney } = useCurrency()

function monitorStatusColor(s: string) {
  return { on_rent: 'primary', available: 'success', in_maintenance: 'warning', out_of_service: 'error' }[s] || 'medium-emphasis'
}
function monitorStatusIcon(s: string) {
  return { on_rent: 'mdi-car-key', available: 'mdi-parking', in_maintenance: 'mdi-wrench', out_of_service: 'mdi-cancel' }[s] || 'mdi-car'
}
function monitorStatusLabel(s: string) {
  return (s || '').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

function liveStatusColor(t: any) {
  if (!t) return 'grey'
  if (t.device_status === 'offline') return 'error'
  if (t.is_stale) return 'warning'
  if ((t.speed ?? 0) > 0) return 'success'
  return 'primary'
}
function liveStatusIcon(t: any) {
  if (!t) return 'mdi-help-circle-outline'
  if (t.device_status === 'offline') return 'mdi-lan-disconnect'
  if (t.is_stale) return 'mdi-clock-alert-outline'
  if ((t.speed ?? 0) > 0) return 'mdi-truck-fast'
  return 'mdi-parking'
}
function liveStatusLabel(t: any) {
  if (!t) return 'No Device'
  if (t.device_status === 'offline') return 'Offline'
  if (t.is_stale) return 'Stale'
  if ((t.speed ?? 0) > 0) return 'Moving'
  return 'Parked'
}

function batteryColor(soc: number | null | undefined) {
  const v = soc ?? 0
  if (v < 20) return 'error'
  if (v < 50) return 'warning'
  return 'success'
}

function isElectric(fuelType: string) {
  return fuelType === 'Electric' || fuelType === 'Fuel Cell (Hydrogen)'
}

function formatFuel(qty: number) {
  if (!qty) return '0'
  return `${formatNumber(qty)} gal`
}

function formatNumber(v: any, decimals = 1) {
  const n = Number(v ?? 0)
  if (Number.isNaN(n)) return v
  return n.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: decimals })
}

function timeAgo(d: string | null) {
  if (!d) return '&mdash;'
  const now = Date.now()
  const then = new Date(d).getTime()
  const diff = Math.max(0, now - then)
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'Just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ${mins % 60}m ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}
</script>
