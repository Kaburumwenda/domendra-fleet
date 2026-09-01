<template>
  <v-row dense>
    <!-- Total Documents -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterType', '')" :class="{ active: activeTypeFilter === '' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0f7ff; color: #3b82f6">
            <v-icon size="24">mdi-file-document-multiple-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.total || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total Documents</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-tray-arrow-up</v-icon> {{ formatSize(stats.total_size || 0) }} total storage</div>
      </v-card>
    </v-col>

    <!-- Expiring Soon -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterExpiry', 'expiring')" :class="{ active: activeExpiryFilter === 'expiring' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fffbeb; color: #f59e0b">
            <v-icon size="24">mdi-clock-alert-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #f59e0b">{{ stats.expiring_soon || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Expiring Soon</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-calendar-clock</v-icon> Within 30 days</div>
      </v-card>
    </v-col>

    <!-- Expired -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterExpiry', 'expired')" :class="{ active: activeExpiryFilter === 'expired' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fef2f2; color: #ef4444">
            <v-icon size="24">mdi-alert-circle-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #ef4444">{{ stats.expired || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Expired</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-close-circle</v-icon> Needs renewal</div>
      </v-card>
    </v-col>

    <!-- No Expiry -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterExpiry', 'none')" :class="{ active: activeExpiryFilter === 'none' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0fdf4; color: #22c55e">
            <v-icon size="24">mdi-shield-check-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.no_expiry || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">No Expiry</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-infinity</v-icon> Permanent records</div>
      </v-card>
    </v-col>

    <!-- Breakdown Row -->
    <v-col cols="12">
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <v-row dense>
          <!-- By Type -->
          <v-col cols="12" md="7">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-format-list-bulleted-type</v-icon>Documents by Type</p>
            <div class="d-flex flex-wrap ga-2">
              <div
                v-for="t in docTypes"
                :key="t.value"
                class="type-chip cursor-pointer"
                :class="{ active: activeTypeFilter === t.value }"
                @click="$emit('filterType', t.value)"
              >
                <v-icon size="16" :color="typeColor(t.value)">{{ typeIcon(t.value) }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ t.label }}</span>
                <v-chip size="x-small" variant="flat" :color="typeColor(t.value)">{{ stats.by_type?.[t.value] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>

          <!-- By Vehicle -->
          <v-col v-if="stats.by_vehicle?.length" cols="12" md="5">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-car-multiple</v-icon>Documents by Vehicle</p>
            <div class="d-flex flex-column ga-1">
              <div v-for="v in stats.by_vehicle" :key="v.vehicle_name" class="vehicle-chip">
                <v-icon size="14">mdi-car</v-icon>
                <span class="text-body-2 font-weight-medium flex-grow-1 text-truncate">{{ v.vehicle_name }}</span>
                <v-chip size="x-small" variant="flat" color="primary">{{ v.count }}</v-chip>
                <v-chip v-if="v.expired" size="x-small" variant="flat" color="error">{{ v.expired }} exp</v-chip>
              </div>
            </div>
          </v-col>
        </v-row>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
const props = defineProps<{ stats: any; activeTypeFilter?: string; activeExpiryFilter?: string }>()
defineEmits<{ filterType: [v: string]; filterExpiry: [v: string] }>()

const docTypes = [
  { label: 'Insurance', value: 'insurance' },
  { label: 'Registration', value: 'registration' },
  { label: 'Title', value: 'title' },
  { label: 'Inspection', value: 'inspection' },
  { label: 'License', value: 'license' },
  { label: 'Medical Card', value: 'medical_card' },
  { label: 'Warranty', value: 'warranty' },
  { label: 'Contract', value: 'contract' },
  { label: 'Permit', value: 'permit' },
  { label: 'Maintenance', value: 'maintenance' },
  { label: 'Other', value: 'other' },
]

function typeColor(t: string) {
  return ({
    insurance: 'primary',
    registration: 'info',
    title: 'success',
    inspection: 'warning',
    license: 'deep-purple',
    medical_card: 'pink',
    warranty: 'teal',
    contract: 'indigo',
    permit: 'orange',
    maintenance: 'cyan',
    other: 'grey',
  } as any)[t] || 'grey'
}

function typeIcon(t: string) {
  return ({
    insurance: 'mdi-shield-outline',
    registration: 'mdi-file-document-outline',
    title: 'mdi-bookmark-outline',
    inspection: 'mdi-clipboard-check-outline',
    license: 'mdi-card-account-details-outline',
    medical_card: 'mdi-heart-pulse',
    warranty: 'mdi-shield-home-outline',
    contract: 'mdi-file-sign',
    permit: 'mdi-ticket-confirmation',
    maintenance: 'mdi-wrench-check',
    other: 'mdi-file-document-outline',
  } as any)[t] || 'mdi-file-document-outline'
}

function formatSize(bytes: number) {
  if (!bytes) return '0 B'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`
}
</script>

<style scoped>
.stat-card { border-radius: 12px; transition: all .2s; }
.stat-card:hover { border-color: #c7d2fe; box-shadow: 0 2px 8px rgba(99,102,241,.08); }
.stat-card.active { border-color: #6366f1; box-shadow: 0 0 0 2px rgba(99,102,241,.15); }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-sub { display: flex; align-items: center; gap: 4px; padding: 0 16px 10px; font-size: 12px; color: #64748b; }
.type-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0; transition: all .15s; }
.type-chip.active { border-color: #6366f1; background: #f0f7ff; }
.type-chip:hover { background: #f0f7ff; }
.vehicle-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #fafafa; border: 1px solid #f1f5f9; }
.cursor-pointer { cursor: pointer; }
</style>
