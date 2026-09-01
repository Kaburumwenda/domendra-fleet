<template>
  <div class="d-flex flex-column ga-4">
    <!-- Filter bar -->
    <div class="d-flex flex-wrap align-center ga-2">
      <v-select
        v-model="localEventType"
        :items="eventTypes"
        item-title="label"
        item-value="value"
        placeholder="All Events"
        density="compact"
        variant="outlined"
        hide-details
        clearable
        style="max-width: 170px"
      />
      <v-select
        v-model="localVehicle"
        :items="vehicles"
        item-title="display_name"
        item-value="id"
        placeholder="All Vehicles"
        density="compact"
        variant="outlined"
        hide-details
        clearable
        style="max-width: 200px"
      />
      <v-spacer />
      <v-btn variant="outlined" size="small" prepend-icon="mdi-refresh" :loading="loading" @click="$emit('refresh')">Refresh</v-btn>
    </div>

    <v-card elevation="0" border class="pa-4">
      <v-data-table
        :items="events"
        :headers="headers"
        :loading="loading"
        density="comfortable"
        :items-per-page="15"
      >
        <template #[`item.event_type`]="{ item }">
          <v-chip
            :color="item.event_type === 'enter' ? 'success' : 'warning'"
            variant="tonal"
            size="small"
            class="text-capitalize"
          >
            <v-icon start size="x-small">
              {{ item.event_type === 'enter' ? 'mdi-location-enter' : 'mdi-location-exit' }}
            </v-icon>
            {{ item.event_type }}
          </v-chip>
        </template>
        <template #[`item.vehicle_name`]="{ item }">
          <span class="font-weight-medium">{{ item.vehicle_name || '—' }}</span>
        </template>
        <template #[`item.location_name`]="{ item }">
          {{ item.location_name || '—' }}
        </template>
        <template #[`item.occurred_at`]="{ item }">
          {{ item.occurred_at ? fmtDateTime(item.occurred_at) : '—' }}
        </template>
      </v-data-table>

      <div v-if="!loading && events.length === 0" class="text-center pa-8 text-medium-emphasis">
        <v-icon size="40" class="mb-2">mdi-shield-map-outline</v-icon>
        <p class="text-body-2">No geofence events recorded yet.</p>
        <p class="text-caption">Geofence events are automatically generated when vehicles enter or exit geofence zones.</p>
      </div>
    </v-card>

    <!-- Geofence info -->
    <v-alert type="info" variant="tonal" border density="comfortable" class="text-body-2">
      <template #prepend><v-icon color="info">mdi-shield-map-outline</v-icon></template>
      Geofence zones are managed in the
      <v-btn variant="text" color="info" size="small" class="px-1" to="/app/locations">Locations</v-btn>
      section — create a location with is_geofence=true to enable enter/exit tracking.
    </v-alert>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  events: any[]
  vehicles: any[]
  loading: boolean
  eventTypeFilter: string | null
  vehicleFilter: number | null
}>()

const emit = defineEmits<{
  (e: 'refresh'): void
  (e: 'update:eventTypeFilter', val: string | null): void
  (e: 'update:vehicleFilter', val: number | null): void
}>()

const localEventType = computed({
  get: () => props.eventTypeFilter,
  set: (val) => emit('update:eventTypeFilter', val),
})

const localVehicle = computed({
  get: () => props.vehicleFilter,
  set: (val) => emit('update:vehicleFilter', val),
})

const eventTypes = [
  { label: 'Enter', value: 'enter' },
  { label: 'Exit', value: 'exit' },
]

const headers = [
  { title: 'Event', key: 'event_type', sortable: true, width: 120 },
  { title: 'Vehicle', key: 'vehicle_name', sortable: true },
  { title: 'Location', key: 'location_name', sortable: true },
  { title: 'Coordinates', key: 'coordinates', sortable: false },
  { title: 'Occurred At', key: 'occurred_at', sortable: true, width: 180 },
]

function fmtDateTime(d: any): string {
  if (!d) return '—'
  try {
    return new Date(d).toLocaleString('en-US', {
      month: 'short', day: 'numeric', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    })
  } catch { return String(d) }
}
</script>
