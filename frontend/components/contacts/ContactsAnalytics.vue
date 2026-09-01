<template>
  <v-row dense>
    <!-- Total Contacts -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterType', '')" :class="{ active: activeTypeFilter === '' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #eef2ff; color: #6366f1">
            <v-icon size="24">mdi-card-account-details-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.total || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Total Contacts</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-check-circle-outline</v-icon> {{ stats.active || 0 }} active · {{ stats.inactive || 0 }} inactive</div>
      </v-card>
    </v-col>

    <!-- Active -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterActive', 'true')" :class="{ active: activeActiveFilter === 'true' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0fdf4; color: #22c55e">
            <v-icon size="24">mdi-account-check-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #22c55e">{{ stats.active || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Active</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-account-group</v-icon> {{ Math.round(((stats.active || 0) / Math.max(stats.total || 1, 1)) * 100) }}% of total</div>
      </v-card>
    </v-col>

    <!-- Vendors -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterType', 'vendor')" :class="{ active: activeTypeFilter === 'vendor' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f0fdfa; color: #14b8a6">
            <v-icon size="24">mdi-store-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0" style="color: #14b8a6">{{ stats.vendor_count || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Vendors</p>
          </div>
        </div>
        <div class="stat-sub">
          <v-icon size="14">mdi-star</v-icon> {{ stats.avg_rating || 0 }} avg rating
        </div>
      </v-card>
    </v-col>

    <!-- Inactive -->
    <v-col cols="6" md="3">
      <v-card elevation="0" border class="stat-card h-100 cursor-pointer" @click="$emit('filterActive', 'false')" :class="{ active: activeActiveFilter === 'false' }">
        <div class="d-flex align-center ga-3 pa-4">
          <div class="stat-icon" style="background: #f8fafc; color: #64748b">
            <v-icon size="24">mdi-account-off-outline</v-icon>
          </div>
          <div>
            <p class="text-h5 font-weight-bold mb-0">{{ stats.inactive || 0 }}</p>
            <p class="text-caption text-medium-emphasis mb-0">Inactive</p>
          </div>
        </div>
        <div class="stat-sub"><v-icon size="14">mdi-pause-circle-outline</v-icon> Deactivated contacts</div>
      </v-card>
    </v-col>

    <!-- Breakdown Row -->
    <v-col cols="12">
      <v-card elevation="0" border rounded="lg" class="pa-4">
        <v-row dense>
          <!-- By Type -->
          <v-col cols="12" md="7">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-format-list-bulleted-type</v-icon>Contacts by Type</p>
            <div class="d-flex flex-wrap ga-2">
              <div
                v-for="t in contactTypes"
                :key="t.value"
                class="type-chip cursor-pointer"
                :class="{ active: activeTypeFilter === t.value }"
                @click="$emit('filterType', t.value)"
              >
                <v-icon size="16" :color="t.color">{{ t.icon }}</v-icon>
                <span class="text-body-2 font-weight-medium">{{ t.label }}</span>
                <v-chip size="x-small" variant="flat" :color="t.color">{{ stats.by_type?.[t.value] || 0 }}</v-chip>
              </div>
            </div>
          </v-col>

          <!-- By City -->
          <v-col v-if="cityList.length" cols="12" md="5">
            <p class="text-subtitle-2 font-weight-bold mb-3"><v-icon size="16" class="mr-1">mdi-map-marker-multiple</v-icon>Top Cities</p>
            <div class="d-flex flex-column ga-1">
              <div v-for="c in cityList" :key="c.city" class="city-chip">
                <v-icon size="14">mdi-map-marker</v-icon>
                <span class="text-body-2 font-weight-medium flex-grow-1 text-truncate">{{ c.city }}</span>
                <v-chip size="x-small" variant="flat" color="primary">{{ c.count }}</v-chip>
              </div>
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
  activeTypeFilter?: string
  activeActiveFilter?: string
}>()
defineEmits<{ filterType: [v: string]; filterActive: [v: string] }>()

const contactTypes = [
  { label: 'Driver', value: 'driver', color: 'primary', icon: 'mdi-steering' },
  { label: 'Vendor', value: 'vendor', color: 'teal', icon: 'mdi-store-outline' },
  { label: 'Mechanic', value: 'mechanic', color: 'amber', icon: 'mdi-wrench' },
  { label: 'Manager', value: 'manager', color: 'deep-purple', icon: 'mdi-account-tie' },
  { label: 'Insurance Agent', value: 'insurance_agent', color: 'cyan', icon: 'mdi-shield-outline' },
  { label: 'Towing Company', value: 'towing', color: 'error', icon: 'mdi-tow-truck' },
]

const cityList = computed(() => {
  const cities = props.stats?.by_city || {}
  return Object.entries(cities)
    .map(([city, count]) => ({ city, count: count as number }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 6)
})
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
.city-chip { display: flex; align-items: center; gap: 6px; padding: 6px 10px; border-radius: 10px; background: #fafafa; border: 1px solid #f1f5f9; }
.cursor-pointer { cursor: pointer; }
</style>
