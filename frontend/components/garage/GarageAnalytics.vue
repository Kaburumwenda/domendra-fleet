<template>
  <div class="d-flex flex-column ga-3">
    <!-- KPI cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="primary"><v-icon>mdi-garage-variant</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-primary mb-0">{{ bayStats?.total || bays.length }}</p><p class="text-caption text-medium-emphasis">Total Bays</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-check-circle</v-icon>{{ bayStats?.active || 0 }} active</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterBayStatus', 'available')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="success"><v-icon>mdi-check-circle-outline</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-success mb-0">{{ bayStats?.available ?? bays.filter(b => !b.is_occupied).length }}</p><p class="text-caption text-medium-emphasis">Available</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-parking</v-icon>Ready for use</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterBayStatus', 'occupied')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="error"><v-icon>mdi-car-connected</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-error mb-0">{{ bayStats?.occupied ?? bays.filter(b => b.is_occupied).length }}</p><p class="text-caption text-medium-emphasis">Occupied</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-wrench</v-icon>In service now</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterResStatus', 'scheduled')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="info"><v-icon>mdi-calendar-clock</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-info mb-0">{{ resStats?.upcoming || 0 }}</p><p class="text-caption text-medium-emphasis">Upcoming (7d)</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-clock-outline</v-icon>{{ resStats?.active || 0 }} active now</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Breakdown cards -->
    <v-row dense>
      <v-col cols="12" md="5">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-sitemap-outline</v-icon>Bay Types</p>
          <div v-for="(count, key) in bayStats?.by_type || {}" :key="key" class="d-flex align-center ga-2 py-1">
            <v-icon size="18" :color="bayTypeColor(key)">{{ bayTypeIcon(key) }}</v-icon>
            <span class="text-body-2 flex-grow-1">{{ bayTypeLabel(key) }}</span>
            <v-chip size="small" variant="tonal" :color="bayTypeColor(key)">{{ count }}</v-chip>
          </div>
          <div v-if="!bayStats?.by_type || !Object.keys(bayStats.by_type).length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="7">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-chart-bar</v-icon>Reservations by Bay <span class="text-caption text-medium-emphasis font-weight-normal">(total · active)</span></p>
          <v-row dense>
            <v-col v-for="b in resStats?.by_bay || []" :key="b.bay_name" cols="6" md="4">
              <div class="d-flex align-center ga-2 py-1 cursor-pointer bay-chip" @click="$emit('filterBay', b.bay_name)">
                <v-avatar size="28" variant="tonal" :color="bayTypeColor(b.bay_type)"><v-icon size="16">{{ bayTypeIcon(b.bay_type) }}</v-icon></v-avatar>
                <span class="text-body-2 flex-grow-1 text-truncate" style="max-width:120px">{{ b.bay_name }}</span>
                <v-chip v-if="b.active" size="x-small" variant="flat" color="success">{{ b.active }}</v-chip>
                <v-chip size="x-small" variant="tonal" color="primary">{{ b.count }}</v-chip>
              </div>
            </v-col>
          </v-row>
          <div v-if="!resStats?.by_bay || !resStats.by_bay.length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
defineProps<{ bayStats: any; resStats: any; bays: any[] }>()
defineEmits<{ filterBayStatus: [s: string]; filterResStatus: [s: string]; filterBay: [name: string] }>()

function bayTypeColor(t: string) { return ({ lift: 'primary', flat: 'info', paint: 'deep-purple', wash: 'cyan', inspection: 'warning', general: 'grey' } as any)[t] || 'grey' }
function bayTypeIcon(t: string) { return ({ lift: 'mdi-arrow-up', flat: 'mdi-minus', paint: 'mdi-palette', wash: 'mdi-water', inspection: 'mdi-magnify', general: 'mdi-sitemap' } as any)[t] || 'mdi-sitemap' }
function bayTypeLabel(t: string) { return ({ lift: 'Lift Bay', flat: 'Flat Bay', paint: 'Paint Bay', wash: 'Wash Bay', inspection: 'Inspection Bay', general: 'General Bay' } as any)[t] || t }
</script>

<style scoped>
.kpi-card { transition: transform .15s, box-shadow .15s; }
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.cursor-pointer { cursor: pointer; }
.bay-chip:hover { background: rgba(99,102,241,.06); border-radius: 6px; }
</style>
