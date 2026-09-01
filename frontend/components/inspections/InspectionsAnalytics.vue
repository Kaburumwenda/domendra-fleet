<template>
  <div class="d-flex flex-column ga-3">
    <!-- KPI cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="primary"><v-icon>mdi-clipboard-check-outline</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-primary mb-0">{{ stats?.total || reports.length }}</p><p class="text-caption text-medium-emphasis">Total Reports</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-check-circle</v-icon>Across all vehicles</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterStatus', 'pass')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="success"><v-icon>mdi-check-decagram</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-success mb-0">{{ stats?.passed || 0 }}</p><p class="text-caption text-medium-emphasis">Passed</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-percent</v-icon>{{ stats?.pass_rate ?? 0 }}% pass rate</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterStatus', 'fail')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="error"><v-icon>mdi-close-circle</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-error mb-0">{{ stats?.failed || 0 }}</p><p class="text-caption text-medium-emphasis">Failed</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-alert-octagon</v-icon>{{ stats?.critical_fails || 0 }} critical</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="kpi-card pa-3 cursor-pointer" @click="$emit('filterStatus', 'conditional')">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" variant="tonal" color="warning"><v-icon>mdi-alert-circle</v-icon></v-avatar>
            <div><p class="text-h5 font-weight-bold text-warning mb-0">{{ stats?.conditional || 0 }}</p><p class="text-caption text-medium-emphasis">Conditional</p></div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1"><v-icon size="12">mdi-pencil</v-icon>{{ stats?.drafts || 0 }} drafts pending</p>
        </v-card>
      </v-col>
    </v-row>

    <!-- Breakdown cards -->
    <v-row dense>
      <v-col cols="12" md="5">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-clipboard-text-multiple</v-icon>By Inspection Form</p>
          <div v-for="f in stats?.by_form || []" :key="f.form_name" class="d-flex align-center ga-2 py-1">
            <v-icon size="18" color="primary">mdi-clipboard-text-outline</v-icon>
            <span class="text-body-2 flex-grow-1 text-truncate" style="max-width:140px">{{ f.form_name }}</span>
            <v-chip size="small" variant="tonal" color="success">{{ f.pass }}</v-chip>
            <v-chip size="small" variant="tonal" color="warning">{{ f.conditional }}</v-chip>
            <v-chip size="small" variant="tonal" color="error">{{ f.fail }}</v-chip>
          </div>
          <div v-if="!(stats?.by_form || []).length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
      <v-col cols="12" md="7">
        <v-card elevation="0" border rounded="lg" class="pa-3 h-100">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-car-multiple</v-icon>By Vehicle <span class="text-caption text-medium-emphasis font-weight-normal">(pass · fail)</span></p>
          <v-row dense>
            <v-col v-for="v in stats?.by_vehicle || []" :key="v.vehicle_name" cols="6" md="4">
              <div class="d-flex align-center ga-2 py-1 cursor-pointer vehicle-chip" @click="$emit('filterVehicle', v.vehicle_name)">
                <v-avatar size="28" variant="tonal" color="primary"><v-icon size="16">mdi-car</v-icon></v-avatar>
                <span class="text-body-2 flex-grow-1 text-truncate" style="max-width:120px">{{ v.vehicle_name }}</span>
                <v-chip size="x-small" variant="flat" color="error" v-if="v.fail">{{ v.fail }}</v-chip>
                <v-chip size="x-small" variant="tonal" color="grey">{{ v.count }}</v-chip>
              </div>
            </v-col>
          </v-row>
          <div v-if="!(stats?.by_vehicle || []).length" class="text-center text-caption text-medium-emphasis py-2">No data</div>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
defineProps<{ stats: any; reports: any[] }>()
defineEmits<{ filterStatus: [s: string]; filterVehicle: [v: string] }>()
</script>

<style scoped>
.kpi-card { transition: transform .15s, box-shadow .15s; }
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.cursor-pointer { cursor: pointer; }
.vehicle-chip:hover { background: rgba(99,102,241,.06); border-radius: 6px; }
</style>
