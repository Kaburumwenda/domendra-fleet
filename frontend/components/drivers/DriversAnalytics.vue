<template>
  <v-row dense>
    <!-- Total Drivers -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterStatus', '')" :class="{ active: activeStatusFilter === '' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #eef2ff; color: #6366f1">
            <v-icon size="24">mdi-steering</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.total || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total Drivers</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-account-multiple</v-icon> {{ stats.active || 0 }} active</div>
      </v-card>
    </v-col>

    <!-- Active -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterStatus', 'active')" :class="{ active: activeStatusFilter === 'active' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0fdf4; color: #22c55e">
            <v-icon size="24">mdi-account-check-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #22c55e">{{ stats.active || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Active</p>
          </div>
        </div>
        <div class="stat-sub">
          <v-icon size="14">mdi-pause-circle-outline</v-icon> {{ stats.on_leave || 0 }} on leave · {{ stats.suspended || 0 }} suspended
        </div>
      </v-card>
    </v-col>

    <!-- License & Med Card Expiring -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterCompliance', 'expiring')" :class="{ active: activeComplianceFilter === 'expiring' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fffbeb; color: #f59e0b">
            <v-icon size="24">mdi-clock-alert-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #f59e0b">{{ (stats.licenses_expiring_30d || 0) + (stats.med_cards_expiring_30d || 0) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Expiring 30d</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-card-bulleted-outline</v-icon> {{ stats.licenses_expiring_30d || 0 }} licenses · {{ stats.med_cards_expiring_30d || 0 }} med cards</div>
      </v-card>
    </v-col>

    <!-- MVR Issues -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterMvr', 'warning')" :class="{ active: activeMvrFilter === 'warning' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #fef2f2; color: #ef4444">
            <v-icon size="24">mdi-alert-circle-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #ef4444">{{ (stats.mvr_warning || 0) + (stats.licenses_expired || 0) }}</p>
            <p class="text-caption text-medium-emphasis mb-0">MVR Issues</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-shield-alert-outline</v-icon> {{ stats.mvr_warning || 0 }} warnings · {{ stats.licenses_expired || 0 }} expired licenses</div>
      </v-card>
    </v-col>

    <!-- Breakdown Row -->
    <v-col cols="12">
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <v-row dense>
          <!-- Employment Status -->
          <v-col cols="12" md="6">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-account-group</v-icon>Employment Status</p>
            <div class="d-flex flex-wrap ga-2">
              <div
                v-for="s in employmentStatuses"
                :key="s.value"
                class="status-chip cursor-pointer"
                :class="{ active: activeStatusFilter === s.value }"
                @click="$emit('filterStatus', s.value)"
              >
                <v-icon size="16" :color="s.color">{{ s.icon }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ s.label }}</span>
                <v-chip size="x-small" variant="flat" :color="s.color">{{ stats[s.key] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>

          <!-- MVR Status & Compliance -->
          <v-col cols="12" md="6">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-shield-check-outline</v-icon>MVR & Compliance</p>
            <div class="d-flex flex-wrap ga-2">
              <div
                v-for="m in mvrStatuses"
                :key="m.value"
                class="status-chip cursor-pointer"
                :class="{ active: activeMvrFilter === m.value }"
                @click="$emit('filterMvr', m.value)"
              >
                <v-icon size="16" :color="m.color">{{ m.icon }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ m.label }}</span>
                <v-chip size="x-small" variant="flat" :color="m.color">{{ stats[m.key] || 0 }}</v-chip>
              </div>
            </div>
            <v-divider class="my-3" />
            <div class="d-flex flex-wrap ga-2">
              <v-chip size="small" variant="tonal" color="warning" prepend-icon="mdi-calendar-clock">
                {{ stats.licenses_expiring_30d || 0 }} licenses expiring
              </v-chip>
              <v-chip size="small" variant="tonal" color="error" prepend-icon="mdi-close-circle">
                {{ stats.licenses_expired || 0 }} expired licenses
              </v-chip>
              <v-chip size="small" variant="tonal" color="pink" prepend-icon="mdi-heart-pulse">
                {{ stats.med_cards_expiring_30d || 0 }} med cards expiring
              </v-chip>
            </div>
          </v-col>
        </v-row>
      </v-card>
    </v-col>
  </v-row>
</template>

<script setup lang="ts">
const props = defineProps<{
  stats: any
  activeStatusFilter?: string
  activeMvrFilter?: string
  activeComplianceFilter?: string
}>()
defineEmits<{
  filterStatus: [v: string]
  filterMvr: [v: string]
  filterCompliance: [v: string]
}>()

const employmentStatuses = [
  { label: 'Active', value: 'active', key: 'active', color: 'success', icon: 'mdi-check-circle' },
  { label: 'On Leave', value: 'on_leave', key: 'on_leave', color: 'info', icon: 'mdi-pause-circle' },
  { label: 'Suspended', value: 'suspended', key: 'suspended', color: 'warning', icon: 'mdi-alert-circle' },
  { label: 'Terminated', value: 'terminated', key: 'terminated', color: 'grey', icon: 'mdi-close-circle' },
  { label: 'Probation', value: 'probation', key: 'probation', color: 'amber', icon: 'mdi-clock-alert' },
]

const mvrStatuses = [
  { label: 'Clean', value: 'clean', key: 'mvr_clean', color: 'success', icon: 'mdi-shield-check' },
  { label: 'Warning', value: 'warning', key: 'mvr_warning', color: 'warning', icon: 'mdi-shield-alert' },
  { label: 'Suspended', value: 'suspended', key: 'mvr_suspended', color: 'error', icon: 'mdi-shield-off' },
  { label: 'Expired', value: 'expired', key: 'mvr_expired', color: 'grey', icon: 'mdi-shield-remove' },
]
</script>

<style scoped>
.stat-card { border-radius: 12px; transition: all .2s; }
.stat-card:hover { border-color: #c7d2fe; box-shadow: 0 2px 8px rgba(99,102,241,.08); }
.stat-card.active { border-color: #6366f1; box-shadow: 0 0 0 2px rgba(99,102,241,.15); }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-sub { display: flex; align-items: center; gap: 4px; padding: 0 16px 10px; font-size: 12px; color: #64748b; }
.status-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #f8fafc; border: 1px solid #e2e8f0; transition: all .15s; }
.status-chip.active { border-color: #6366f1; background: #f0f7ff; }
.status-chip:hover { background: #f0f7ff; }
.cursor-pointer { cursor: pointer; }
</style>
