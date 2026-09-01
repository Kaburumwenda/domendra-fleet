<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="540" temporary style="top:0; height:100vh; z-index:1000">
    <div v-if="quarter" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="statusColor(quarter.status)" variant="flat" size="small">
            <v-icon start size="14">{{ statusIcon(quarter.status) }}</v-icon>{{ statusLabel(quarter.status) }}
          </v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ quarter.label }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis mt-1"><v-icon size="14">mdi-car</v-icon> {{ quarter.vehicle_name }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- KPI Grid -->
        <div class="kpi-grid">
          <div class="kpi-item">
            <v-icon size="18" color="primary">mdi-map-marker-path</v-icon>
            <div><p class="text-caption text-medium-emphasis">Total Miles</p><p class="text-body-1 font-weight-bold">{{ fmtNum(quarter.total_miles) }}</p></div>
          </div>
          <div class="kpi-item">
            <v-icon size="18" color="warning">mdi-gas-station</v-icon>
            <div><p class="text-caption text-medium-emphasis">Total Gallons</p><p class="text-body-1 font-weight-bold">{{ fmtNum(quarter.total_gallons) }}</p></div>
          </div>
          <div class="kpi-item">
            <v-icon size="18" color="info">mdi-speedometer</v-icon>
            <div><p class="text-caption text-medium-emphasis">Avg MPG</p><p class="text-body-1 font-weight-bold">{{ mpg }}</p></div>
          </div>
          <div class="kpi-item">
            <v-icon size="18" :color="netTaxNegative ? 'error' : 'success'">mdi-currency-usd</v-icon>
            <div><p class="text-caption text-medium-emphasis">Net Tax</p><p class="text-body-1 font-weight-bold" :class="netTaxNegative ? 'text-error' : 'text-success'">{{ fmtCur(quarter.net_tax) }}</p></div>
          </div>
        </div>

        <!-- Tax Breakdown -->
        <div class="section-block">
          <div class="d-flex align-center justify-space-between mb-1">
            <p class="text-subtitle-2 font-weight-bold mb-0"><v-icon size="16" class="mr-1">mdi-file-table</v-icon>Tax Due vs Credit</p>
          </div>
          <div class="progress-card">
            <div class="d-flex justify-space-between mb-1">
              <span class="text-body-2"><v-icon size="14" color="error">mdi-arrow-up</v-icon> Tax Due: <b>{{ fmtCur(quarter.total_tax_due) }}</b></span>
            </div>
            <div class="d-flex justify-space-between mb-1">
              <span class="text-body-2"><v-icon size="14" color="success">mdi-arrow-down</v-icon> Tax Credit: <b>{{ fmtCur(quarter.total_tax_credit) }}</b></span>
            </div>
            <v-divider class="my-2" />
            <div class="d-flex justify-space-between">
              <span class="text-body-1 font-weight-bold">Net Tax Owed</span>
              <span class="text-body-1 font-weight-bold" :class="netTaxNegative ? 'text-error' : 'text-success'">{{ fmtCur(quarter.net_tax) }}</span>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="quarter.notes" class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-note-text</v-icon>Notes</p>
          <div class="notes-card">{{ quarter.notes }}</div>
        </div>

        <!-- Breakdown Table -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-chart-box-outline</v-icon>Per-Jurisdiction Breakdown</p>
          <div v-if="!breakdown.length" class="text-center py-4 text-medium-emphasis">
            <v-icon size="32" class="mb-2">mdi-chart-box-outline</v-icon>
            <p class="text-caption">Loading breakdown data…</p>
          </div>
          <v-data-table v-else :headers="breakHeaders" :items="breakdown" density="compact" hide-default-footer hover>
            <template #item.jurisdiction="{ value }"><span class="font-weight-medium">{{ value }}</span></template>
            <template #item.miles="{ value }">{{ fmtNum(value) }}</template>
            <template #item.gallons="{ value }">{{ fmtNum(value) }}</template>
            <template #item.consumed_gallons="{ value }">{{ fmtNum(value) }}</template>
            <template #item.rate="{ value }">${{ parseFloat(value).toFixed(4) }}</template>
            <template #item.tax_due="{ value }"><span class="font-weight-bold text-error">{{ fmtCur(value) }}</span></template>
          </v-data-table>
        </div>

        <!-- Meta -->
        <div class="section-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information-outline</v-icon>Metadata</p>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-key-variant</v-icon>
            <span class="text-caption text-medium-emphasis">ID:</span>
            <span class="text-body-2 font-weight-medium">#{{ quarter.id }}</span>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <span class="text-caption text-medium-emphasis">Created:</span>
            <span class="text-body-2">{{ fmtDate(quarter.created_at) }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="drawer-actions">
        <v-btn variant="text" prepend-icon="mdi-sync" @click="$emit('regenerate', quarter)">Regenerate</v-btn>
        <v-spacer />
        <v-btn v-if="quarter.status === 'draft'" variant="tonal" color="primary" prepend-icon="mdi-send" @click="$emit('setStatus', { quarter, status: 'submitted' })">Submit</v-btn>
        <v-btn v-if="quarter.status === 'submitted'" variant="tonal" color="success" prepend-icon="mdi-check-circle" @click="$emit('setStatus', { quarter, status: 'filed' })">File</v-btn>
        <v-btn v-if="quarter.status !== 'draft'" variant="tonal" color="grey" prepend-icon="mdi-pencil" @click="$emit('setStatus', { quarter, status: 'draft' })">Revert to Draft</v-btn>
        <v-btn variant="tonal" color="error" prepend-icon="mdi-delete-outline" @click="$emit('delete', quarter)">Delete</v-btn>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-icon size="48" color="grey-lighten-2">mdi-file-chart-outline</v-icon>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; quarter: any; breakdown: any[] }>()
defineEmits<{ 'update:modelValue': [v: boolean]; regenerate: [q: any]; delete: [q: any]; setStatus: [payload: any] }>()

const breakHeaders = [
  { title: 'Jur.', key: 'jurisdiction', width: '70px' },
  { title: 'Miles', key: 'miles', width: '90px' },
  { title: 'Gallons', key: 'gallons', width: '80px' },
  { title: 'Consumed', key: 'consumed_gallons', width: '80px' },
  { title: 'Rate', key: 'rate', width: '80px' },
  { title: 'Tax Due', key: 'tax_due', width: '90px' },
]

const mpg = computed(() => {
  if (!props.quarter?.total_gallons) return '0.00'
  return (props.quarter.total_miles / props.quarter.total_gallons).toFixed(2)
})
const netTaxNegative = computed(() => parseFloat(props.quarter?.net_tax || 0) > 0)

function statusColor(s: string) { return ({ draft: 'grey', submitted: 'primary', filed: 'success' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ draft: 'mdi-pencil-outline', submitted: 'mdi-send', filed: 'mdi-check-circle' } as any)[s] || 'mdi-circle-outline' }
function statusLabel(s: string) { return ({ draft: 'Draft', submitted: 'Submitted', filed: 'Filed' } as any)[s] || s }
function fmtNum(v?: number) { return v ? parseFloat(v).toLocaleString([], { maximumFractionDigits: 1 }) : '0' }
function fmtCur(v?: number) { return v ? `$${parseFloat(v).toLocaleString([], { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : '$0.00' }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
</script>

<style scoped>
.drawer-head { padding: 16px 20px 12px; }
.drawer-body { padding: 12px 20px; overflow-y: auto; flex: 1 1 0; }
.drawer-actions { padding: 12px 16px; border-top: 1px solid #e2e8f0; display: flex; gap: 4px; flex-wrap: wrap; align-items: center; }
.kpi-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.kpi-item { display: flex; align-items: flex-start; gap: 10px; padding: 10px; border-radius: 10px; background: #f8fafc; }
.section-block { margin-top: 16px; }
.progress-card { padding: 12px; border-radius: 10px; background: #f8fafc; }
.notes-card { padding: 12px; border-radius: 10px; background: #f8fafc; font-size: 14px; line-height: 1.5; }
.info-row { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
</style>
