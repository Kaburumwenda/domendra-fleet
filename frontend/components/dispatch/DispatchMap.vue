<template>
  <v-card elevation="0" border rounded="lg" class="h-100 d-flex flex-column">
    <v-card-title class="d-flex align-center ga-2 text-subtitle-1 font-weight-bold">
      <v-icon color="primary">mdi-map-marker-multiple</v-icon>
      Live Route Map
      <v-spacer />
      <v-btn-toggle v-model="layer" density="compact" mandatory color="primary" variant="outlined">
        <v-btn size="x-small" value="route" prepend-icon="mdi-map-marker-path">Route</v-btn>
        <v-btn size="x-small" value="fleet" prepend-icon="mdi-truck-fast">Fleet</v-btn>
      </v-btn-toggle>
    </v-card-title>
    <v-divider />
    <div ref="mapEl" class="dispatch-map" :class="{ loading: loading }">
      <div v-if="loading" class="map-loading">
        <v-progress-circular indeterminate color="primary" size="48" />
        <p class="text-caption text-medium-emphasis mt-2">Loading map…</p>
      </div>
      <div v-if="!loading && !pts.length" class="map-empty">
        <v-icon size="42" color="medium-emphasis">mdi-map-off-outline</v-icon>
        <p class="text-caption text-medium-emphasis mt-2">No geocoded points to display.</p>
      </div>
    </div>
    <v-divider />
    <div class="map-legend">
      <span><span class="leg-dot" style="background:#10b981" /> Pickup</span>
      <span><span class="leg-dot" style="background:#3b82f6" /> Stop</span>
      <span><span class="leg-dot" style="background:#ef4444" /> Dropoff</span>
      <span v-if="layer === 'fleet'"><span class="leg-dot" style="background:#8b5cf6" /> Driver (live)</span>
    </div>
  </v-card>
</template>

<script setup lang="ts">
import { useDispatchMap, type DispatchMarker } from '~/composables/useDispatchMap'

const props = defineProps<{ jobs: any[] }>()
const layer = ref<'route' | 'fleet'>('route')
const mapEl = ref<HTMLElement | null>(null)
const { render, loading } = useDispatchMap()

const pts = computed<DispatchMarker[]>(() => {
  if (layer.value === 'fleet') {
    return driverMarkers.value
  }
  const arr: DispatchMarker[] = []
  for (const j of props.jobs) {
    if (j.status === 'cancelled') continue
    if (j.pickup_lat != null && j.pickup_lng != null) {
      arr.push({ id: `${j.id}-p`, lat: j.pickup_lat, lng: j.pickup_lng, kind: 'pickup', title: `Pickup: ${j.title}`, label: j.pickup_address })
    }
    if (j.pickup_lat != null && j.pickup_lng != null && j.stops?.length) {
      j.stops.forEach((s: any, i: number) => {
        if (s.latitude != null && s.longitude != null) {
          arr.push({ id: `s-${s.id}`, lat: s.latitude, lng: s.longitude, kind: 'stop', sequence: i, title: `Stop ${i + 1}: ${s.address}` })
        }
      })
    }
    if (j.dropoff_lat != null && j.dropoff_lng != null) {
      arr.push({ id: `${j.id}-d`, lat: j.dropoff_lat, lng: j.dropoff_lng, kind: 'dropoff', title: `Dropoff: ${j.title}`, label: j.dropoff_address })
    }
  }
  return arr
})

const driverMarkers = computed<DispatchMarker[]>(() => {
  // Simulated driver positions interpolated near pickup
  return props.jobs
    .filter(j => j.status === 'in_progress' && j.pickup_lat != null)
    .map(j => ({
      id: `drv-${j.id}`,
      lat: j.pickup_lat + 0.018 * Math.sin(j.id),
      lng: j.pickup_lng + 0.016 * Math.cos(j.id),
      kind: 'driver' as const,
      title: `${j.driver_name || 'Driver'} · ${j.title}`,
    }))
})

watch([pts, mapEl], async ([p, el]) => {
  if (!el || !p || !(p as any[]).length) return
  await nextTick()
  render(el as HTMLElement, p as DispatchMarker[], { drawRoute: layer.value === 'route', fit: true })
}, { immediate: true })
</script>

<style scoped>
.dispatch-map { position: relative; height: 460px; min-height: 360px; background:#e9eef6; }
.dispatch-map.loading { display:flex; align-items:center; justify-content:center; }
.map-loading, .map-empty { position:absolute; inset:0; display:flex; flex-direction:column; align-items:center; justify-content:center; z-index:1; }
.map-legend { display:flex; flex-wrap:wrap; gap:14px; padding:10px 16px; font-size:12px; color:#475569; }
.leg-dot { width:10px; height:10px; border-radius:50%; display:inline-block; margin-right:4px; }
</style>
