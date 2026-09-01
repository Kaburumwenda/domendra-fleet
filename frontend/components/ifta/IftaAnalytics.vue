<template>
  <v-row dense>
    <!-- Total Miles -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterTab', 'triplogs')" style="cursor:pointer">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0f7ff; color: #3b82f6">
            <v-icon size="24">mdi-map-marker-path</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ fmtNum(stats.total_miles) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total Miles</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-map</v-icon> {{ stats.total_trips || 0 }} trip logs</div>
      </v-card>
    </v-col>

    <!-- Total Gallons -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterTab', 'fuel')" style="cursor:pointer">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fffbeb; color: #f59e0b">
            <v-icon size="24">mdi-gas-station</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #f59e0b">{{ fmtNum(stats.total_gallons) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total Gallons</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-fuel</v-icon> {{ stats.total_fuel_purchases || 0 }} purchases · {{ fmtCur(stats.total_fuel_cost) }}</div>
      </v-card>
    </v-col>

    <!-- Avg MPG -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0fdf4; color: #22c55e">
            <v-icon size="24">mdi-speedometer</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #22c55e">{{ stats.avg_mpg || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Fleet Avg MPG</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-chart-line</v-icon> {{ stats.jurisdiction_count || 0 }} jurisdictions</div>
      </v-card>
    </v-col>

    <!-- Net Tax -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterTab', 'quarters')" style="cursor:pointer">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" :style="{ background: netTaxColor + '1a', color: netTaxColor }">
            <v-icon size="24">{{ netTaxIcon }}</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" :style="{ color: netTaxColor }">{{ fmtCur(stats.total_net_tax) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Net Tax Due</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-calendar-check</v-icon> {{ stats.quarter_count || 0 }} quarterly reports</div>
      </v-card>
    </v-col>

    <!-- Breakdown Row -->
    <v-col cols="12">
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <v-row dense>
          <!-- By Status -->
          <v-col cols="12" md="4">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-file-chart-outline</v-icon>Report Status</p>
            <div class="d-flex flex-wrap ga-2">
              <div v-for="s in statusList" :key="s.value" class="type-chip">
                <v-icon size="16" :color="statusColor(s.value)">{{ statusIcon(s.value) }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ s.label }}</span>
                <v-chip size="x-small" variant="flat" :color="statusColor(s.value)">{{ stats.by_status?.[s.value] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>

          <!-- By Quarter -->
          <v-col cols="12" md="4">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-calendar-month</v-icon>Net Tax by Quarter</p>
            <div v-if="quarterData.length" class="d-flex flex-column ga-1">
              <div v-for="q in quarterData" :key="q.label" class="quarter-row">
                <span class="text-body-2 font-weight-medium">{{ q.label }}</span>
                <v-spacer />
                <span class="text-body-2 font-weight-bold" :class="q.net >= 0 ? 'text-error' : 'text-success'">{{ fmtCur(q.net) }}</span>
              </div>
            </div>
            <p v-else class="text-caption text-medium-emphasis">No quarterly reports yet.</p>
          </v-col>

          <!-- By Vehicle -->
          <v-col cols="12" md="4">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-car-multiple</v-icon>Trips by Vehicle</p>
            <div v-if="vehicleData.length" class="d-flex flex-column ga-1">
              <div v-for="v in vehicleData.slice(0, 8)" :key="v.vehicle_name" class="quarter-row">
                <v-icon size="14">mdi-car</v-icon>
                <span class="text-body-2 font-weight-medium text-truncate" style="max-width:120px">{{ v.vehicle_name }}</span>
                <v-spacer />
                <v-chip size="x-small" variant="outlined" color="primary">{{ v.trips }} trips</v-chip>
                <v-chip size="x-small" variant="outlined" color="warning">{{ fmtNum(v.miles) }} mi</v-chip>
              </div>
            </div>
            <p v-else class="text-caption text-medium-emphasis">No trip data yet.</p>
          </v-col>
        </v-row>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
const props = defineProps<{ stats: any }>()
defineEmits<{ filterTab: [v: string] }>()

const statusList = [
  { label: 'Draft', value: 'draft' },
  { label: 'Submitted', value: 'submitted' },
  { label: 'Filed', value: 'filed' },
]

const netTaxColor = computed(() => {
  const v = parseFloat(props.stats?.total_net_tax || 0)
  return v > 0 ? '#ef4444' : v < 0 ? '#22c55e' : '#64748b'
})
const netTaxIcon = computed(() => {
  const v = parseFloat(props.stats?.total_net_tax || 0)
  return v > 0 ? 'mdi-currency-usd' : v < 0 ? 'mdi-currency-usd-off' : 'mdi-currency-usd'
})

const quarterData = computed(() => {
  if (!props.stats?.by_quarter) return []
  return Object.entries(props.stats.by_quarter).map(([label, net]) => ({ label, net: net as number })).slice(0, 8)
})
const vehicleData = computed(() => props.stats?.by_vehicle || [])

function statusColor(s: string) { return ({ draft: 'grey', submitted: 'primary', filed: 'success' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ draft: 'mdi-pencil-outline', submitted: 'mdi-send', filed: 'mdi-check-circle' } as any)[s] || 'mdi-circle-outline' }
function fmtNum(v?: number) { return v ? v.toLocaleString([], { maximumFractionDigits: 0 }) : '0' }
function fmtCur(v?: number) { return v ? `$${parseFloat(v).toLocaleString([], { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : '$0.00' }
</script>

<style scoped>
.stat-card { border-radius: 12px; transition: all .2s; }
.stat-card:hover { border-color: #c7d2fe; box-shadow: 0 2px 8px rgba(99,102,241,.08); }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-sub { display: flex; align-items: center; gap: 4px; padding: 0 16px 10px; font-size: 12px; color: #64748b; }
.type-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0; }
.quarter-row { display: flex; align-items: center; gap: 4px; padding: 4px 8px; border-radius: 6px; background: #fafafa; }
</style>
