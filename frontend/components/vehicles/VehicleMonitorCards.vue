<template>
  <div>
    <div v-if="loading && vehicles.length === 0" class="d-flex justify-center align-center py-12">
      <v-progress-circular indeterminate color="primary" />
    </div>
    <div v-else-if="vehicles.length === 0" class="text-center py-12 text-medium-emphasis">
      <v-icon size="48" class="mb-3">mdi-monitor-off</v-icon>
      <p>No vehicles match the current filters.</p>
    </div>
    <v-row v-else dense>
      <v-col v-for="v in vehicles" :key="v.id" cols="12" sm="6" md="4" lg="3">
        <v-card
          elevation="0"
          border
          rounded="lg"
          class="cursor-pointer h-100"
          hover
          @click="$emit('select', v)"
        >
          <!-- Card header -->
          <div class="d-flex align-center justify-space-between pa-3" :style="cardStripeStyle(v)">
            <div class="d-flex align-center ga-2">
              <v-avatar :color="monitorStatusColor(v.monitor_status)" variant="tonal" size="36">
                <v-icon size="20">{{ monitorStatusIcon(v.monitor_status) }}</v-icon>
              </v-avatar>
              <div>
                <div class="text-body-2 font-weight-bold" style="color: #1e293b">{{ v.display_name }}</div>
                <div class="text-caption text-medium-emphasis">{{ v.license_plate || v.vin.slice(-6) }}</div>
              </div>
            </div>
            <v-chip :color="monitorStatusColor(v.monitor_status)" size="x-small" variant="flat">
              {{ monitorStatusLabel(v.monitor_status) }}
            </v-chip>
          </div>

          <v-divider />

          <!-- Live telematics row -->
          <div class="d-flex align-center justify-space-between pa-3">
            <div class="d-flex align-center ga-2">
              <v-icon :color="liveStatusColor(v.telematics)" size="small">{{ liveStatusIcon(v.telematics) }}</v-icon>
              <div>
                <div class="text-caption font-weight-medium">{{ liveStatusLabel(v.telematics) }}</div>
                <div v-if="v.telematics" class="text-caption text-medium-emphasis">
                  {{ v.telematics.speed ? v.telematics.speed.toFixed(0) : 0 }} {{ v.mileage_unit === 'miles' ? 'mph' : 'km/h' }}
                </div>
              </div>
            </div>
            <div class="text-right">
              <div v-if="v.telematics" class="text-caption" :class="v.telematics.is_stale ? 'text-warning' : 'text-medium-emphasis'">
                {{ timeAgo(v.telematics.last_reported_at) }}
              </div>
              <div v-else class="text-caption text-medium-emphasis">No device</div>
            </div>
          </div>

          <v-divider />

          <!-- Mileage & fuel -->
          <div class="pa-3">
            <div class="d-flex justify-space-between mb-2">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="primary">mdi-road-variant</v-icon>
                <span class="text-body-2">{{ formatNumber(v.current_mileage) }} {{ v.mileage_unit }}</span>
              </div>
              <div v-if="v.engine_hours > 0" class="d-flex align-center ga-1">
                <v-icon size="small" color="medium-emphasis">mdi-clock-outline</v-icon>
                <span class="text-body-2 text-medium-emphasis">{{ formatNumber(v.engine_hours) }}h</span>
              </div>
            </div>
            <!-- EV vehicles show battery -->
            <div v-if="isElectric(v.fuel_type)" class="d-flex align-center ga-2 mb-2">
              <v-icon size="small" color="primary">mdi-battery-charging</v-icon>
              <v-progress-linear
                :model-value="v.state_of_charge ?? 0"
                :color="batteryColor(v.state_of_charge)"
                height="6"
                rounded
                style="flex: 1; max-width: 120px;"
              />
              <span class="text-caption">{{ v.state_of_charge ?? 0 }}%</span>
            </div>
            <!-- Fuel vehicles show fuel used -->
            <div v-else class="d-flex justify-space-between mb-2">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="warning">mdi-gas-station</v-icon>
                <span class="text-caption">{{ formatFuel(v.total_fuel_used) }}</span>
              </div>
              <span class="text-caption text-medium-emphasis">{{ fmtMoney(v.total_fuel_cost) }}</span>
            </div>
            <!-- Installed batteries (non-EV) -->
            <div v-if="!isElectric(v.fuel_type) && v.battery_summary" class="d-flex justify-space-between mb-2">
              <div class="d-flex align-center ga-2">
                <v-icon size="small" color="primary">mdi-car-battery</v-icon>
                <span class="text-caption">
                  {{ v.battery_summary.count }} {{ v.battery_summary.count === 1 ? 'battery' : 'batteries' }}
                  <span v-if="v.battery_summary.avg_voltage"> &middot; {{ v.battery_summary.avg_voltage }}V</span>
                </span>
              </div>
              <v-chip v-if="v.battery_summary.warranty_expired > 0" size="x-small" color="error" variant="tonal">
                {{ v.battery_summary.warranty_expired }} exp warranty
              </v-chip>
            </div>
          </div>

          <v-divider />

          <!-- Rental info -->
          <div v-if="v.rental" class="pa-3" style="background: rgba(99,102,241,0.05)">
            <div class="d-flex align-center ga-2 mb-1">
              <v-icon size="small" color="primary">mdi-car-key</v-icon>
              <span class="text-caption font-weight-medium" style="color:#4f46e5">{{ v.rental.agreement_no }}</span>
            </div>
            <div class="text-caption text-medium-emphasis">{{ v.rental.customer_name }}</div>
            <div class="text-caption text-medium-emphasis">Due: {{ formatDate(v.rental.end_datetime) }}</div>
            <div v-if="v.rental_mileage != null" class="text-caption">
              Mileage: {{ formatNumber(v.rental_mileage) }} {{ v.mileage_unit }}
            </div>
          </div>
          <div v-else-if="v.monitor_status === 'available'" class="pa-3 text-center">
            <v-chip color="success" size="x-small" variant="tonal">
              <v-icon start size="x-small">mdi-parking</v-icon>
              Available
            </v-chip>
          </div>
          <div v-else-if="v.monitor_status === 'in_maintenance'" class="pa-3 text-center">
            <v-chip color="warning" size="x-small" variant="tonal">
              <v-icon start size="x-small">mdi-wrench</v-icon>
              In Maintenance
            </v-chip>
          </div>

          <v-divider />

          <!-- Alerts row -->
          <div class="d-flex align-center justify-space-between pa-3">
            <div class="d-flex ga-2">
              <v-chip v-if="v.open_alerts" color="error" size="x-small" variant="flat">
                <v-icon start size="x-small">mdi-bell-alert</v-icon>
                {{ v.open_alerts }} alerts
              </v-chip>
              <v-chip v-if="v.open_issues" color="warning" size="x-small" variant="flat">
                <v-icon start size="x-small">mdi-alert</v-icon>
                {{ v.open_issues }} issues
              </v-chip>
              <span v-if="!v.open_alerts && !v.open_issues" class="text-caption text-medium-emphasis">No alerts</span>
            </div>
            <v-btn icon="mdi-eye-outline" size="x-small" variant="text" @click.stop="$emit('select', v)" />
          </div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  vehicles: any[]
  loading?: boolean
  currencySymbol?: string
}>()

defineEmits<{ select: [item: any] }>()

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

function formatDate(d: string | null): string {
  if (!d) return '&mdash;'
  return new Date(d).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
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
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}

function cardStripeStyle(v: any) {
  const colors: Record<string, string> = {
    on_rent: 'rgba(99,102,241,0.06)',
    available: 'rgba(16,185,129,0.06)',
    in_maintenance: 'rgba(245,158,11,0.06)',
    out_of_service: 'rgba(239,68,68,0.06)',
  }
  return { background: colors[v.monitor_status] || 'transparent' }
}
</script>
