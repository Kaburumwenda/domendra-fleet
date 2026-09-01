<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="500" temporary permanent style="top:0; height:100vh; z-index:1000">
    <div v-if="svc" class="d-flex flex-column h-100">
      <div class="drawer-head">
        <div class="d-flex align-center ga-2 mb-2">
          <v-chip :color="typeColor(svc.service_type)" variant="flat" size="small" class="text-capitalize">
            <v-icon start size="14">{{ typeIcon(svc.service_type) }}</v-icon>{{ svc.service_type ? svc.service_type.replace('_', ' ') : '' }}
          </v-chip>
        </div>
        <div class="d-flex align-center">
          <h2 class="text-h6 font-weight-bold flex-grow-1">{{ svc.vehicle_name }}</h2>
          <v-btn icon variant="text" size="small" @click="$emit('update:modelValue', false)"><v-icon>mdi-close</v-icon></v-btn>
        </div>
        <p class="text-caption text-medium-emphasis">#{{ svc.id }} · {{ fmt(svc.performed_at) }}</p>
      </div>
      <v-divider />

      <div class="drawer-body">
        <!-- Cost & downtime summary -->
        <div class="cost-grid">
          <div class="cost-item">
            <p class="text-caption text-medium-emphasis">Service Cost</p>
            <p class="text-h6 font-weight-bold text-primary">{{ currencySymbol }}{{ money(svc.cost) }}</p>
          </div>
          <div class="cost-item">
            <p class="text-caption text-medium-emphasis">Downtime</p>
            <p class="text-h6 font-weight-bold text-warning">{{ svc.downtime_hours || 0 }}h</p>
          </div>
          <div class="cost-item">
            <p class="text-caption text-medium-emphasis">Odometer</p>
            <p class="text-subtitle-1 font-weight-bold">{{ svc.odometer_reading != null ? svc.odometer_reading.toLocaleString() + ' mi' : '—' }}</p>
          </div>
        </div>

        <!-- Assignment info -->
        <div class="info-list">
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-truck</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Vehicle</p>
              <p class="text-body-2 font-weight-medium">{{ svc.vehicle_name || '—' }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-store</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Vendor</p>
              <p class="text-body-2 font-weight-medium">{{ svc.vendor_name || 'No vendor assigned' }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-account-wrench</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Technician</p>
              <p class="text-body-2 font-weight-medium">{{ svc.technician_name || 'Unassigned' }}</p>
            </div>
          </div>
          <div class="info-row">
            <v-icon size="18" color="medium-emphasis">mdi-clock-outline</v-icon>
            <div>
              <p class="text-caption text-medium-emphasis">Performed At</p>
              <p class="text-body-2 font-weight-medium">{{ fmt(svc.performed_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Vendor rating -->
        <div class="rating-block">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="18" color="amber" class="mr-1">mdi-star</v-icon>Vendor Rating</p>
          <div v-if="svc.rating" class="rating-details">
            <div class="d-flex align-center ga-2 mb-2">
              <v-rating :model-value="svc.rating.overall_rating" readonly half-increments size="small" color="amber" />
              <span class="text-h6 font-weight-bold">{{ svc.rating.overall_rating?.toFixed(1) }}</span>
            </div>
            <div class="rating-row"><span class="text-body-2">Cost</span><v-rating :model-value="svc.rating.cost_rating || 0" readonly half-increments density="compact" size="x-small" color="amber" /></div>
            <div class="rating-row"><span class="text-body-2">Quality</span><v-rating :model-value="svc.rating.quality_rating || 0" readonly half-increments density="compact" size="x-small" color="amber" /></div>
            <div class="rating-row"><span class="text-body-2">Turnaround</span><v-rating :model-value="svc.rating.turnaround_rating || 0" readonly half-increments density="compact" size="x-small" color="amber" /></div>
            <p v-if="svc.rating.notes" class="text-body-2 mt-2 rating-notes">{{ svc.rating.notes }}</p>
          </div>
          <div v-else class="text-center pa-4">
            <v-icon size="32" color="medium-emphasis">mdi-star-outline</v-icon>
            <p class="text-caption text-medium-emphasis mt-1">No rating yet</p>
            <v-btn v-if="svc.vendor" color="amber" variant="tonal" size="small" prepend-icon="mdi-star" class="mt-2" @click="$emit('rate', svc)">Rate Vendor</v-btn>
          </div>
        </div>

        <!-- Description -->
        <div v-if="svc.description" class="desc-block">
          <p class="text-caption text-medium-emphasis mb-1"><v-icon size="14">mdi-note-text</v-icon> Description</p>
          <p class="text-body-2">{{ svc.description }}</p>
        </div>

        <!-- Actions -->
        <div class="action-row">
          <v-btn variant="outlined" prepend-icon="mdi-pencil" block @click="$emit('edit', svc)">Edit Service</v-btn>
          <v-btn v-if="svc.vendor && !svc.rating" color="amber" variant="flat" prepend-icon="mdi-star" block @click="$emit('rate', svc)">Rate Vendor</v-btn>
          <v-btn v-if="svc.rating" color="amber" variant="outlined" prepend-icon="mdi-star-edit" block @click="$emit('rate', svc)">Update Rating</v-btn>
          <v-btn variant="text" color="error" prepend-icon="mdi-delete" block @click="$emit('delete', svc)">Delete Service</v-btn>
        </div>
      </div>
    </div>
    <div v-else class="d-flex align-center justify-center h-100">
      <v-progress-circular indeterminate color="primary" />
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; svc: any; currencySymbol: string }>()
defineEmits<{ 'update:modelValue': [v: boolean]; edit: [s: any]; rate: [s: any]; delete: [s: any] }>()
function money(v: any) { return parseFloat(v || 0).toFixed(2) }
function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function typeColor(t: string) { return ({ oil_change: 'amber', tire_rotation: 'blue', brake_service: 'error', inspection: 'success', repair: 'deep-orange', preventive: 'indigo', other: 'grey' } as any)[t] || 'grey' }
function typeIcon(t: string) { return ({ oil_change: 'mdi-oil', tire_rotation: 'mdi-tire', brake_service: 'mdi-car-brake-abs', inspection: 'mdi-clipboard-check-outline', repair: 'mdi-wrench', preventive: 'mdi-calendar-sync', other: 'mdi-dots-horizontal' } as any)[t] || 'mdi-wrench' }
</script>

<style scoped>
.drawer-head { padding:18px 20px 14px; }
.drawer-body { flex:1; overflow-y:auto; padding:0 20px 20px; display:flex; flex-direction:column; gap:18px; }
.cost-grid { display:grid; grid-template-columns: repeat(3,1fr); gap:10px; }
.cost-item { background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:12px; text-align:center; }
.info-list { display:flex; flex-direction:column; gap:12px; }
.info-row { display:flex; gap:10px; align-items:flex-start; }
.rating-block { background:#fffbeb; border:1px solid #fde68a; border-radius:12px; padding:14px; }
.rating-row { display:flex; align-items:center; justify-content:space-between; gap:8px; margin-top:6px; }
.rating-notes { color:#92400e; font-style:italic; }
.desc-block { background:#f1f5f9; border:1px solid #e2e8f0; border-radius:10px; padding:12px; }
.action-row { display:flex; flex-direction:column; gap:8px; }
</style>
