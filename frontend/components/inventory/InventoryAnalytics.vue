<template>
  <v-row dense>
    <!-- Total Inventory Value -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" style="cursor:pointer" @click="$emit('filterTab', 'items')">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background:#f0f7ff;color:#3b82f6">
            <v-icon size="24">mdi-cash-multiple</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ fmtCur(stats.total_value) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Inventory Value</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-package-variant</v-icon> {{ stats.total_on_hand?.toLocaleString() || 0 }} units on hand</div>
      </v-card>
    </v-col>

    <!-- Total SKUs -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterTab', 'items')" style="cursor:pointer">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background:#f0fdf4;color:#22c55e">
            <v-icon size="24">mdi-package-variant-closed</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.total_skus || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total SKUs</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-check-circle</v-icon> {{ stats.active_skus || 0 }} active</div>
      </v-card>
    </v-col>

    <!-- Low Stock Alerts -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterTab', 'items')" style="cursor:pointer">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background:#fef2f2;color:#ef4444">
            <v-icon size="24">mdi-alert</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color:#ef4444">{{ stats.low_stock_count || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Low Stock Items</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-bell-alert</v-icon> needs reorder</div>
      </v-card>
    </v-col>

    <!-- Locations -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100" @click="$emit('filterTab', 'locations')" style="cursor:pointer">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background:#fffbeb;color:#f59e0b">
            <v-icon size="24">mdi-warehouse</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color:#f59e0b">{{ stats.location_count || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Locations</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-map-marker</v-icon> {{ stats.po_count || 0 }} purchase orders</div>
      </v-card>
    </v-col>

    <!-- Breakdown Row -->
    <v-col cols="12">
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <v-row dense>
          <!-- PO Status -->
          <v-col cols="12" md="4">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-clipboard-text-outline</v-icon>Purchase Order Status</p>
            <div class="d-flex flex-wrap ga-2">
              <div v-for="s in poStatusList" :key="s.value" class="type-chip">
                <v-icon size="16" :color="poStatusColor(s.value)">{{ poStatusIcon(s.value) }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ s.label }}</span>
                <v-chip size="x-small" variant="flat" :color="poStatusColor(s.value)">{{ stats.po_by_status?.[s.value] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>

          <!-- Top Categories by Value -->
          <v-col cols="12" md="4">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-chart-bar</v-icon>Top Categories (by Value)</p>
            <div v-if="categoryData.length" class="d-flex flex-column ga-1">
              <div v-for="c in categoryData" :key="c.category" class="quarter-row">
                <span class="text-body-2 font-weight-medium text-truncate" style="max-width:100px">{{ c.category }}</span>
                <v-spacer />
                <v-chip size="x-small" variant="outlined" color="primary">{{ c.count }} items</v-chip>
                <span class="text-body-2 font-weight-bold text-primary">{{ fmtCur(c.value) }}</span>
              </div>
            </div>
            <p v-else class="text-caption text-medium-emphasis">No category data.</p>
          </v-col>

          <!-- Quick Stats -->
          <v-col cols="12" md="4">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-chart-donut</v-icon>Category Distribution</p>
            <div v-if="categoryData.length" class="d-flex flex-column ga-1">
              <div v-for="c in categoryData" :key="c.category" class="d-flex align-center ga-2">
                <span class="text-caption font-weight-medium" style="min-width:80px">{{ c.category }}</span>
                <v-progress-linear :model-value="c.qty / maxQty * 100" color="primary" height="6" rounded />
                <span class="text-caption text-medium-emphasis" style="min-width:40px">{{ c.qty }}</span>
              </div>
            </div>
            <p v-else class="text-caption text-medium-emphasis">No data yet.</p>
          </v-col>
        </v-row>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
const props = defineProps<{ stats: any }>()
defineEmits<{ filterTab: [v: string] }>()
const { currencySymbol } = useCurrency()

const poStatusList = [
  { label: 'Draft', value: 'draft' },
  { label: 'Submitted', value: 'submitted' },
  { label: 'Partial', value: 'partially_received' },
  { label: 'Received', value: 'received' },
  { label: 'Cancelled', value: 'cancelled' },
]

const categoryData = computed(() => props.stats?.by_category_top || [])
const maxQty = computed(() => Math.max(1, ...categoryData.value.map((c: any) => c.qty || 0)))

function poStatusColor(s: string) { return ({ draft: 'grey', submitted: 'primary', partially_received: 'warning', received: 'success', cancelled: 'error' } as any)[s] || 'grey' }
function poStatusIcon(s: string) { return ({ draft: 'mdi-pencil-outline', submitted: 'mdi-send', partially_received: 'mdi-progress-clock', received: 'mdi-check-circle', cancelled: 'mdi-close-circle' } as any)[s] || 'mdi-circle-outline' }
function fmtCur(v?: number) { return v != null ? `${currencySymbol.value}${parseFloat(v).toLocaleString([], { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : `${currencySymbol.value}0.00` }
</script>

<style scoped>
.stat-card { border-radius: 12px; transition: all .2s; }
.stat-card:hover { border-color: #c7d2fe; box-shadow: 0 2px 8px rgba(99,102,241,.08); }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-sub { display: flex; align-items: center; gap: 4px; padding: 0 16px 10px; font-size: 12px; color: #64748b; }
.type-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0; }
.quarter-row { display: flex; align-items: center; gap: 4px; padding: 4px 8px; border-radius: 6px; background: #fafafa; }
</style>
