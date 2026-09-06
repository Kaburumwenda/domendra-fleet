<template>
  <v-card elevation="0" border rounded="lg" class="pa-5">
    <div class="d-flex align-center justify-space-between mb-4 flex-wrap ga-2">
      <div class="d-flex align-center ga-2">
        <v-icon color="success" size="small">mdi-cash-refund</v-icon>
        <h3 class="text-subtitle-1 font-weight-bold section-heading">Vehicle ROI Analysis</h3>
      </div>
      <div class="d-flex ga-1">
        <v-chip size="small" variant="tonal" :color="roiPositive ? 'success' : 'error'">
          Fleet ROI: {{ totalROI }}%
        </v-chip>
        <v-chip size="small" variant="tonal" color="primary">
          Total Net: {{ currencySymbol }}{{ formatNum(totalNet) }}
        </v-chip>
        <v-btn variant="text" size="small" prepend-icon="mdi-download" color="primary" @click="exportCsv">Export</v-btn>
      </div>
    </div>

    <v-data-table
      :headers="headers"
      :items="vehicles"
      density="compact"
      :items-per-page="15"
      class="rounded-lg"
      :sort-by="[{ key: 'net_profit', order: 'desc' }]"
    >
      <template #item.index="{ index }">
        <span class="text-body-2 font-weight-bold text-medium-emphasis">{{ index + 1 }}</span>
      </template>
      <template #item.vehicle="{ item }">
        <div class="d-flex align-center ga-2">
          <v-avatar size="32" :color="item.ownership === 'lease' ? 'orange' : 'primary'" variant="tonal">
            <v-icon size="small">{{ item.ownership === 'lease' ? 'mdi-file-sign' : 'mdi-truck' }}</v-icon>
          </v-avatar>
          <div>
            <div class="text-body-2 font-weight-medium">{{ item.vehicle }}</div>
            <div class="text-caption text-medium-emphasis">{{ item.ownership }} · {{ item.group || 'No group' }}</div>
          </div>
        </div>
      </template>
      <template #item.agreement_count="{ value }">
        <v-chip size="small" variant="tonal" color="info">{{ value || 0 }}</v-chip>
      </template>
      <template #item.revenue="{ value }"><span class="font-weight-medium" style="color: #166534">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.fuel_cost="{ value }"><span style="color: #d97706">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.service_cost="{ value }"><span style="color: #2563eb">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.fixed_cost="{ value }"><span style="color: #64748b">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.total_cost="{ value }"><span style="color: #991b1b">{{ currencySymbol }}{{ formatNum(value) }}</span></template>
      <template #item.net_profit="{ value }">
        <v-chip size="small" :color="value >= 0 ? 'success' : 'error'" variant="tonal" class="font-weight-bold">
          {{ value >= 0 ? '' : '-' }}{{ currencySymbol }}{{ formatNum(Math.abs(value)) }}
        </v-chip>
      </template>
      <template #item.roi_pct="{ value }">
        <div class="d-flex align-center ga-1">
          <v-progress-linear :model-value="Math.max(0, Math.min(100, value))" :color="roiColor(value)" :height="6" rounded style="max-width: 60px" />
          <span class="text-caption font-weight-bold" :style="{ color: roiTextColor(value) }">{{ value }}%</span>
        </div>
      </template>
      <template #item.actions="{ item }">
        <v-btn icon="mdi-eye-outline" size="small" variant="text" color="primary" @click="openDetails(item)" />
      </template>
    </v-data-table>

    <!-- ── Vehicle ROI Details Dialog ── -->
    <v-dialog v-model="detailDialog" max-width="640">
      <v-card rounded="xl" class="pa-2">
        <AppModalHeader icon="mdi-cash-refund" :title="selectedVehicle ? `${selectedVehicle.vehicle} — ROI Breakdown` : 'Vehicle ROI Breakdown'" />
        <v-card-text v-if="selectedVehicle" class="pa-5">
          <!-- Vehicle summary -->
          <div class="d-flex align-center ga-3 mb-4">
            <v-avatar size="44" :color="selectedVehicle.ownership === 'lease' ? 'orange' : 'primary'" variant="tonal">
              <v-icon>{{ selectedVehicle.ownership === 'lease' ? 'mdi-file-sign' : 'mdi-truck' }}</v-icon>
            </v-avatar>
            <div>
              <div class="text-subtitle-1 font-weight-bold section-heading">{{ selectedVehicle.vehicle }}</div>
              <div class="text-body-2 text-medium-emphasis">
                {{ selectedVehicle.ownership }} · {{ selectedVehicle.group || 'No group' }}
                <span v-if="selectedVehicle.vin" class="ml-2">VIN: {{ selectedVehicle.vin }}</span>
              </div>
            </div>
          </div>

          <!-- ROI highlight cards -->
          <v-row dense class="mb-4">
            <v-col cols="6" sm="3">
              <div class="detail-kpi" style="border-color: rgba(34, 197, 94, 0.2)">
                <div class="detail-kpi-sub" style="color: #166534">Revenue</div>
                <div class="detail-kpi-val" style="color: #166534">{{ currencySymbol }}{{ formatNum(selectedVehicle.revenue) }}</div>
              </div>
            </v-col>
            <v-col cols="6" sm="3">
              <div class="detail-kpi" style="border-color: rgba(153, 27, 27, 0.2)">
                <div class="detail-kpi-sub" style="color: #991b1b">Total Cost</div>
                <div class="detail-kpi-val" style="color: #991b1b">{{ currencySymbol }}{{ formatNum(selectedVehicle.total_cost) }}</div>
              </div>
            </v-col>
            <v-col cols="6" sm="3">
              <div class="detail-kpi" style="border-color: rgba(99, 102, 241, 0.2)">
                <div class="detail-kpi-sub" style="color: #4338ca">Net Profit</div>
                <div class="detail-kpi-val" :style="{ color: selectedVehicle.net_profit >= 0 ? '#166534' : '#991b1b' }">
                  {{ selectedVehicle.net_profit >= 0 ? '' : '-' }}{{ currencySymbol }}{{ formatNum(Math.abs(selectedVehicle.net_profit)) }}
                </div>
              </div>
            </v-col>
            <v-col cols="6" sm="3">
              <div class="detail-kpi" :style="{ borderColor: roiColorBg(selectedVehicle.roi_pct) }">
                <div class="detail-kpi-sub" :style="{ color: roiTextColor(selectedVehicle.roi_pct) }">ROI</div>
                <div class="detail-kpi-val" :style="{ color: roiTextColor(selectedVehicle.roi_pct) }">{{ selectedVehicle.roi_pct }}%</div>
              </div>
            </v-col>
          </v-row>

          <!-- Cost breakdown list -->
          <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Cost Breakdown</div>
          <div class="d-flex flex-column ga-1 mb-4">
            <div
              v-for="c in costBreakdown"
              :key="c.label"
              class="d-flex align-center justify-space-between rounded-lg px-3 py-2"
              style="background: var(--v-theme-surface-variant)"
            >
              <div class="d-flex align-center ga-2">
                <v-icon size="x-small" :color="c.color">{{ c.icon }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ c.label }}</span>
              </div>
              <div class="d-flex align-center ga-2">
                <span class="text-subtitle-2 font-weight-bold" :style="{ color: c.color }">
                  {{ currencySymbol }}{{ formatNum(c.value) }}
                </span>
                <span class="text-caption text-medium-emphasis">({{ pct(c.value, selectedVehicle.total_cost) }}%)</span>
              </div>
            </div>
          </div>

          <!-- Derived metrics -->
          <div class="mb-2 text-caption font-weight-medium text-medium-emphasis">Per-Mile Metrics</div>
          <v-row dense>
            <v-col cols="6">
              <div class="d-flex align-center ga-2 rounded-lg px-3 py-2" style="background: var(--v-theme-surface-variant)">
                <v-icon size="small" color="error">mdi-road-variant</v-icon>
                <span class="text-body-2 text-medium-emphasis">Cost / Mile</span>
                <v-spacer />
                <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ formatNum(selectedVehicle.cost_per_mile) }}</span>
              </div>
            </v-col>
            <v-col cols="6">
              <div class="d-flex align-center ga-2 rounded-lg px-3 py-2" style="background: var(--v-theme-surface-variant)">
                <v-icon size="small" color="success">mdi-cash-multiple</v-icon>
                <span class="text-body-2 text-medium-emphasis">Revenue / Mile</span>
                <v-spacer />
                <span class="text-body-2 font-weight-bold">{{ currencySymbol }}{{ formatNum(selectedVehicle.revenue_per_mile) }}</span>
              </div>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-5 pb-5">
          <v-spacer />
          <v-btn variant="text" @click="detailDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ vehicles: any[] }>()
const { currencySymbol } = useCurrency()

const headers = [
  { title: '#', key: 'index', width: '50px', sortable: false, align: 'center' as const },
  { title: 'Vehicle', key: 'vehicle', width: '18%' },
  { title: 'Agreements', key: 'agreement_count', align: 'center' as const, width: '90px' },
  { title: 'Revenue', key: 'revenue', align: 'end' as const },
  { title: 'Fuel', key: 'fuel_cost', align: 'end' as const },
  { title: 'Service', key: 'service_cost', align: 'end' as const },
  { title: 'Fixed', key: 'fixed_cost', align: 'end' as const },
  { title: 'Total Cost', key: 'total_cost', align: 'end' as const },
  { title: 'Net Profit', key: 'net_profit', align: 'end' as const },
  { title: 'ROI', key: 'roi_pct', width: '120px' },
  { title: '', key: 'actions', sortable: false, align: 'center' as const, width: '60px' },
]

const totalROI = computed(() => {
  const totalCost = props.vehicles.reduce((s, v) => s + (v.total_cost || 0), 0)
  const totalNet = props.vehicles.reduce((s, v) => s + (v.net_profit || 0), 0)
  return totalCost > 0 ? Math.round(totalNet / totalCost * 100) : 0
})
const totalNet = computed(() => props.vehicles.reduce((s, v) => s + (v.net_profit || 0), 0))
const roiPositive = computed(() => totalROI.value >= 0)

// ── Details dialog ──
const detailDialog = ref(false)
const selectedVehicle = ref<any | null>(null)

const costBreakdown = computed(() => {
  if (!selectedVehicle.value) return []
  const v = selectedVehicle.value
  return [
    { label: 'Fuel and Charging', value: v.fuel_cost, icon: 'mdi-gas-station', color: '#d97706' },
    { label: 'Service and Maintenance', value: v.service_cost, icon: 'mdi-wrench', color: '#2563eb' },
    { label: 'Fixed Costs (Lease / Insurance / Depreciation)', value: v.fixed_cost, icon: 'mdi-currency-usd', color: '#64748b' },
  ].filter(c => c.value > 0)
})

function openDetails(item: any) {
  selectedVehicle.value = item
  detailDialog.value = true
}

function roiTextColor(value: number) {
  if (value >= 20) return '#166534'
  if (value >= 0) return '#92400e'
  return '#991b1b'
}
function roiColor(value: number) {
  if (value >= 20) return 'success'
  if (value >= 0) return 'warning'
  return 'error'
}
function roiColorBg(value: number) {
  if (value >= 20) return 'rgba(34, 197, 94, 0.2)'
  if (value >= 0) return 'rgba(245, 158, 11, 0.2)'
  return 'rgba(153, 27, 27, 0.2)'
}
function pct(val: number, total: number | undefined) {
  if (!val || !total) return 0
  return Math.round((val / total) * 100)
}

function formatNum(n: number | undefined) {
  if (!n) return '0'
  return Math.round(n).toLocaleString()
}

function exportCsv() {
  if (!props.vehicles?.length) return
  const rows = ['Vehicle,VIN,Group,Agreements,Revenue,Fuel,Service,Fixed,Total Cost,Net Profit,ROI %,Cost/Mile,Rev/Mile']
  for (const v of props.vehicles) {
    rows.push(`"${v.vehicle}","${v.vin}","${v.group}",${v.agreement_count || 0},${v.revenue},${v.fuel_cost},${v.service_cost},${v.fixed_cost},${v.total_cost},${v.net_profit},${v.roi_pct},${v.cost_per_mile},${v.revenue_per_mile}`)
  }
  const blob = new Blob([rows.join('\n')], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `vehicle-roi-${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
</script>

<style scoped>
.section-heading { color: #1e293b; }
.v-theme--dark .section-heading { color: #e2e8f0; }
.detail-kpi { padding: 12px; border-radius: 12px; background: rgba(99, 102, 241, 0.06); border: 1px solid rgba(99, 102, 241, 0.12); }
.v-theme--dark .detail-kpi { background: rgba(30, 41, 59, 0.4); }
.detail-kpi-sub { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600; }
.detail-kpi-val { font-size: 1.15rem; font-weight: 700; line-height: 1.2; margin-top: 2px; }
</style>
