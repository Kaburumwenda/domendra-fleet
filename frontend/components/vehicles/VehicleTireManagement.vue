<template>
  <div class="tire-mgmt-wrap">
    <!-- Loading skeleton -->
    <div v-if="loading" class="d-flex justify-center align-center pa-10">
      <v-progress-circular indeterminate color="primary" />
    </div>

    <template v-else>
      <!-- Summary chips -->
      <div class="tm-summary-row">
        <div
          class="tm-summary-card tm-summary-card--primary tm-summary-card--clickable"
          :class="{ 'tm-summary-card--primary-active': activeTab === 'mounted' }"
          @click="activeTab = activeTab === 'mounted' ? null : 'mounted'"
        >
          <v-icon size="18" class="me-2">mdi-tire</v-icon>
          <div>
            <div class="tm-summary-num">{{ mountedTires.length }}</div>
            <div class="tm-summary-lbl">Mounted Tires</div>
          </div>
          <v-icon class="tm-summary-chev" size="16">{{ activeTab === 'mounted' ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
        </div>
        <div
          class="tm-summary-card tm-summary-card--clickable"
          :class="{ 'tm-summary-card--active': activeTab === 'rotations' }"
          @click="activeTab = activeTab === 'rotations' ? null : 'rotations'"
        >
          <v-icon size="18" class="me-2" color="primary">mdi-swap-horizontal-bold</v-icon>
          <div>
            <div class="tm-summary-num">{{ rotations.length }}</div>
            <div class="tm-summary-lbl">Rotations</div>
          </div>
          <v-icon class="tm-summary-chev" size="16">{{ activeTab === 'rotations' ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
        </div>
        <div
          class="tm-summary-card tm-summary-card--clickable"
          :class="{ 'tm-summary-card--active': activeTab === 'inspections' }"
          @click="activeTab = activeTab === 'inspections' ? null : 'inspections'"
        >
          <v-icon size="18" class="me-2" color="success">mdi-clipboard-check-outline</v-icon>
          <div>
            <div class="tm-summary-num">{{ inspections.length }}</div>
            <div class="tm-summary-lbl">Inspections</div>
          </div>
          <v-icon class="tm-summary-chev" size="16">{{ activeTab === 'inspections' ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
        </div>
        <div
          class="tm-summary-card tm-summary-card--clickable"
          :class="{ 'tm-summary-card--active': activeTab === 'movements' }"
          @click="activeTab = activeTab === 'movements' ? null : 'movements'"
        >
          <v-icon size="18" class="me-2" color="info">mdi-transit-transfer-variant</v-icon>
          <div>
            <div class="tm-summary-num">{{ movements.length }}</div>
            <div class="tm-summary-lbl">Movements</div>
          </div>
          <v-icon class="tm-summary-chev" size="16">{{ activeTab === 'movements' ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
        </div>
        <div class="tm-summary-card">
          <v-icon size="18" class="me-2" color="warning">mdi-alert-circle-outline</v-icon>
          <div>
            <div class="tm-summary-num">{{ needsReplacementCount }}</div>
            <div class="tm-summary-lbl">Need Replacement</div>
          </div>
        </div>
      </div>

      <!-- Two column: 3D axle + mounted tires list -->
      <div v-show="activeTab === 'mounted'" class="tm-grid">
        <div class="tm-axle-panel">
          <div class="d-flex align-center justify-space-between mb-3">
            <p class="tm-section-title mb-0">
              <v-icon size="16" class="me-1" color="primary">mdiCar-cog</v-icon>
              3D Axle Layout
            </p>
            <v-chip size="x-small" variant="tonal" color="primary">{{ vehicleData?.drivetrain || '—' }}</v-chip>
          </div>
          <div class="tm-axle-scroll">
            <AxlePositionDiagram
              :drivetrain="vehicleData?.drivetrain"
              :vehicle-type="vehicleData?.vehicle_type"
              :steering="vehicleData?.steering"
              :vehicle-name="vehicleData?.display_name"
              :mounted-tires="mountedTiresMap"
            />
          </div>
          <p class="text-caption text-medium-emphasis mt-2 mb-0">
            Each wheel shows the mounted tire's serial number. Empty hubs indicate unoccupied positions.
          </p>
        </div>

        <div class="tm-mounted-panel">
          <p class="tm-section-title mb-3">
            <v-icon size="16" class="me-1" color="success">mdi-tire</v-icon>
            Mounted Tires
          </p>
          <div v-if="!mountedTires.length" class="text-center py-8 tm-empty">
            <v-icon size="36" class="mb-2">mdi-tire</v-icon>
            <p>No tires mounted on this vehicle.</p>
          </div>
          <div v-else class="d-flex flex-column ga-2">
            <div v-for="t in mountedTires" :key="t.id" class="tm-tire-row" @click="openTireDetail(t)">
              <div class="tm-tire-row__top">
                <span class="tm-tire-serial">{{ t.serial_number }}</span>
                <v-chip size="x-small" variant="flat" :color="positionColor(t.position)">{{ formatPosition(t.position) }}</v-chip>
              </div>
              <div class="tm-tire-row__meta">
                <span>{{ t.brand }} {{ t.model }}</span>
                <span class="dot">•</span>
                <span>{{ t.size || '—' }}</span>
                <span v-if="t.latest_tread_depth != null" class="dot">•</span>
                <span v-if="t.latest_tread_depth != null" :class="t.needs_replacement ? 'text-error' : 'text-success'" class="font-weight-medium">
                  {{ t.latest_tread_depth }}/32″
                </span>
              </div>
              <v-chip v-if="t.needs_replacement" size="x-small" variant="flat" color="error" class="mt-1">Needs Replacement</v-chip>
            </div>
          </div>
        </div>
      </div>

      <!-- Action row: always-visible Record Rotation action -->
      <div class="d-flex align-center justify-end ga-2">
        <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-swap-horizontal-bold" @click="goToRotate">Record Rotation</v-btn>
      </div>

      <!-- Rotations -->
      <div v-show="activeTab === 'rotations'" class="tm-block">
        <div class="d-flex align-center justify-space-between mb-3">
          <p class="tm-section-title mb-0">
            <v-icon size="16" class="me-1" color="primary">mdi-swap-horizontal-bold</v-icon>
            Rotation History
          </p>
        </div>
        <div v-if="!rotations.length" class="text-center py-8 tm-empty">
          <v-icon size="36" class="mb-2">mdi-swap-horizontal-bold</v-icon>
          <p>No rotations recorded for this vehicle yet.</p>
        </div>
        <v-data-table v-else :headers="rotationHeaders" :items="rotations" density="compact" hover items-per-page="5">
          <template #item.performed_at="{ value }">
            <div class="d-flex align-center ga-1">
              <v-icon size="14" color="medium-emphasis">mdi-calendar</v-icon>
              <span>{{ formatDate(value) }}</span>
            </div>
          </template>
          <template #item.swaps_count="{ item }">
            <v-chip size="x-small" variant="tonal">{{ (item.swaps_detail || item.swaps || []).length }} swap{{ (item.swaps_detail || item.swaps || []).length === 1 ? '' : 's' }}</v-chip>
          </template>
          <template #item.pattern="{ value }">
            <span class="text-body-2">{{ value || '—' }}</span>
          </template>
          <template #item.actions="{ item }">
            <v-btn size="x-small" variant="text" icon="mdi-eye-outline" @click="openRotationDetail(item)" />
          </template>
          <template #item.swaps_preview="{ item }">
            <div class="d-flex flex-wrap ga-1">
              <v-chip
                v-for="(s, i) in (item.swaps_detail || []).slice(0, 3)"
                :key="i"
                size="x-small"
                variant="outlined"
                color="primary"
              >
                {{ s.tire_serial || `#${s.tire}` }}: {{ formatPosition(s.from_position) }} → {{ formatPosition(s.to_position) }}
              </v-chip>
              <v-chip v-if="(item.swaps_detail || []).length > 3" size="x-small" variant="tonal">
                +{{ (item.swaps_detail || []).length - 3 }}
              </v-chip>
            </div>
          </template>
        </v-data-table>
      </div>

      <!-- Inspections -->
      <div v-show="activeTab === 'inspections'" class="tm-block">
        <p class="tm-section-title mb-3">
          <v-icon size="16" class="me-1" color="success">mdi-clipboard-check-outline</v-icon>
          Recent Inspections
        </p>
        <div v-if="!inspections.length" class="text-center py-8 tm-empty">
          <v-icon size="36" class="mb-2">mdi-clipboard-check-outline</v-icon>
          <p>No inspections recorded for this vehicle's tires.</p>
        </div>
        <v-data-table v-else :headers="inspectionHeaders" :items="inspections" density="compact" hover items-per-page="5">
          <template #item.measured_at="{ value }">
            <div class="d-flex align-center ga-1">
              <v-icon size="14" color="medium-emphasis">mdi-calendar</v-icon>
              <span>{{ formatDate(value) }}</span>
            </div>
          </template>
          <template #item.condition="{ value }">
            <v-chip size="x-small" :color="conditionColor(value)" variant="flat">{{ conditionLabel(value) }}</v-chip>
          </template>
          <template #item.tread_depth="{ value }">
            <span :class="(value != null && value < 4) ? 'text-error font-weight-medium' : ''">{{ value != null ? `${value} /32″` : '—' }}</span>
          </template>
          <template #item.tire_serial="{ value }">
            <span class="font-weight-medium">{{ value || '—' }}</span>
          </template>
        </v-data-table>
      </div>

      <!-- Movements -->
      <div v-show="activeTab === 'movements'" class="tm-block">
        <p class="tm-section-title mb-3">
          <v-icon size="16" class="me-1" color="info">mdi-transit-transfer-variant</v-icon>
          Movement History
        </p>
        <div v-if="!movements.length" class="text-center py-8 tm-empty">
          <v-icon size="36" class="mb-2">mdi-transit-transfer-variant</v-icon>
          <p>No tire movement history for this vehicle.</p>
        </div>
        <v-data-table v-else :headers="movementHeaders" :items="movements" density="compact" hover items-per-page="5">
          <template #item.performed_at="{ value }">
            <div class="d-flex align-center ga-1">
              <v-icon size="14" color="medium-emphasis">mdi-calendar</v-icon>
              <span>{{ formatDate(value) }}</span>
            </div>
          </template>
          <template #item.movement_type="{ value }">
            <v-chip size="x-small" :color="movementColor(value)" variant="flat" class="text-capitalize">{{ value }}</v-chip>
          </template>
          <template #item.tire_serial="{ value }">
            <span class="font-weight-medium">{{ value || '—' }}</span>
          </template>
          <template #item.from_position="{ value }">{{ formatPosition(value) }}</template>
          <template #item.to_position="{ value }">{{ formatPosition(value) }}</template>
        </v-data-table>
      </div>
    </template>

    <!-- Rotation detail dialog -->
    <v-dialog v-model="rotationDialog" max-width="720" scroll-strategy="none">
      <v-card v-if="selectedRotation" rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-swap-horizontal-bold">Rotation Detail</AppModalHeader>
        <v-card-text class="pa-5">
          <v-row dense>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Date</div><div class="text-body-2">{{ formatDate(selectedRotation.performed_at) }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Pattern</div><div class="text-body-2">{{ selectedRotation.pattern || '—' }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Odometer</div><div class="text-body-2">{{ selectedRotation.odometer ? `${Number(selectedRotation.odometer).toLocaleString()} km` : '—' }}</div></v-col>
            <v-col cols="12" v-if="selectedRotation.notes"><div class="text-caption text-medium-emphasis mb-1">Notes</div><div class="text-body-2">{{ selectedRotation.notes }}</div></v-col>
          </v-row>
          <p class="text-subtitle-2 font-weight-medium mt-4 mb-2" style="color:#475569">Swaps</p>
          <div class="tm-swap-list">
            <div v-for="(s, i) in (selectedRotation.swaps_detail || [])" :key="i" class="tm-swap-row">
              <span class="font-weight-medium">{{ s.tire_serial || `Tire #${s.tire}` }}</span>
              <span class="text-medium-emphasis mx-2">{{ s.tire_brand || '' }} {{ s.tire_size || '' }}</span>
              <v-chip size="x-small" variant="outlined" color="warning">{{ formatPosition(s.from_position) }}</v-chip>
              <v-icon size="14" class="mx-1">mdi-arrow-right</v-icon>
              <v-chip size="x-small" variant="flat" color="success">{{ formatPosition(s.to_position) }}</v-chip>
            </div>
            <div v-if="!(selectedRotation.swaps_detail || []).length" class="text-center py-4 text-medium-emphasis">No swap details available.</div>
          </div>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="rotationDialog = false">Close</v-btn>
          <v-btn color="primary" variant="tonal" prepend-icon="mdi-pencil-outline" @click="goToEditRotation(selectedRotation)">Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Tire detail dialog (mini) -->
    <v-dialog v-model="tireDialog" max-width="620" scroll-strategy="none">
      <v-card v-if="selectedTire" rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-tire">Tire · {{ selectedTire.serial_number }}</AppModalHeader>
        <v-card-text class="pa-5">
          <v-row dense>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Brand</div><div class="text-body-2">{{ selectedTire.brand || '—' }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Model</div><div class="text-body-2">{{ selectedTire.model || '—' }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Size</div><div class="text-body-2">{{ selectedTire.size || '—' }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Type</div><div class="text-body-2">{{ selectedTire.type || '—' }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Position</div><div class="text-body-2"><v-chip size="small" :color="positionColor(selectedTire.position)" variant="flat">{{ formatPosition(selectedTire.position) }}</v-chip></div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Condition</div><div class="text-body-2"><v-chip v-if="selectedTire.condition" size="small" :color="conditionChipColor(selectedTire.condition)" variant="flat">{{ conditionLabel(selectedTire.condition) }}</v-chip><span v-else>—</span></div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Latest Tread</div><div class="text-body-2" :class="selectedTire.needs_replacement ? 'text-error' : 'text-success'">{{ selectedTire.latest_tread_depth != null ? `${selectedTire.latest_tread_depth} /32″` : '—' }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Total Miles</div><div class="text-body-2">{{ Number(selectedTire.total_miles || 0).toLocaleString() }}</div></v-col>
            <v-col cols="6"><div class="text-caption text-medium-emphasis mb-1">Mounted Since</div><div class="text-body-2">{{ formatDate(selectedTire.last_mount_date) }}</div></v-col>
          </v-row>
        </v-card-text>
        <v-divider />
        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn variant="text" @click="tireDialog = false">Close</v-btn>
          <v-btn color="primary" variant="tonal" prepend-icon="mdi-arrow-top-right" @click="goToTire(selectedTire)">View in Tires</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ vehicleId: string | number }>()

const { $api } = useNuxtApp()

const loading = ref(true)
const vehicleData = ref<any>(null)
const tires = ref<any[]>([])
const rotations = ref<any[]>([])
const inspections = ref<any[]>([])
const movements = ref<any[]>([])

// Clickable summary-card tabs: 'mounted' | 'rotations' | 'inspections' | 'movements' | null
const activeTab = ref<'mounted' | 'rotations' | 'inspections' | 'movements' | null>('mounted')

const rotationDialog = ref(false)
const selectedRotation = ref<any>(null)
const tireDialog = ref(false)
const selectedTire = ref<any>(null)

const mountedTires = computed(() => tires.value.filter((t) => t.status === 'mounted' && t.position))
const needsReplacementCount = computed(() => tires.value.filter((t) => t.needs_replacement).length)

/** Map of position code → { serial, brand, size } for AxlePositionDiagram. */
const mountedTiresMap = computed(() => {
  const map: Record<string, { serial?: string; brand?: string; size?: string }> = {}
  for (const t of mountedTires.value) {
    if (t.position) map[t.position] = { serial: t.serial_number, brand: t.brand, size: t.size }
  }
  return map
})

const rotationHeaders = [
  { title: 'Date', key: 'performed_at', width: '140px', sortable: true },
  { title: 'Pattern', key: 'pattern', width: '160px' },
  { title: 'Swaps', key: 'swaps_preview', sortable: false },
  { title: 'Count', key: 'swaps_count', width: '90px', align: 'end' as const },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const inspectionHeaders = [
  { title: 'Date', key: 'measured_at', width: '140px', sortable: true },
  { title: 'Tire', key: 'tire_serial', width: '140px' },
  { title: 'Tread', key: 'tread_depth', width: '100px', align: 'end' as const },
  { title: 'Pressure', key: 'pressure_psi', width: '100px', align: 'end' as const },
  { title: 'Condition', key: 'condition', width: '120px' },
  { title: 'Odometer', key: 'odometer', width: '120px', align: 'end' as const },
]
const movementHeaders = [
  { title: 'Date', key: 'performed_at', width: '140px', sortable: true },
  { title: 'Tire', key: 'tire_serial', width: '140px' },
  { title: 'Type', key: 'movement_type', width: '120px' },
  { title: 'From', key: 'from_position', width: '140px' },
  { title: 'To', key: 'to_position', width: '140px' },
  { title: 'From Vehicle', key: 'from_vehicle_name', width: '160px' },
  { title: 'To Vehicle', key: 'to_vehicle_name', width: '160px' },
]

// --- helpers ---
const STATUS_LABELS: Record<string, string> = { in_stock: 'In Stock', mounted: 'Mounted', spare: 'Spare', retired: 'Retired', scrapped: 'Scrapped' }
const POS_PREFIX: Record<string, string> = { F: 'Front', D: 'Drive', G: 'Tag', T: 'Trailer' }

function formatPosition(p: string) {
  if (!p) return '—'
  if (p === 'Spare') return 'Spare'
  const parts = p.split('_')
  if (parts.length === 1) return POS_PREFIX[parts[0]] || parts[0]
  const prefix = parts[0]
  const side = parts.find((x) => x === 'L' || x === 'R')
  const wheel = parts.find((x) => x === 'Outer' || x === 'Inner')
  const segs = [POS_PREFIX[prefix] || prefix]
  if (side) segs.push(side === 'L' ? 'Left' : 'Right')
  if (wheel) segs.push(wheel)
  return segs.join(' ')
}

function positionColor(p: string) {
  if (!p) return 'default'
  if (p.startsWith('F')) return 'primary'
  if (p.startsWith('D')) return 'success'
  if (p.startsWith('G') || p.startsWith('T')) return 'info'
  return 'default'
}

function formatDate(d: any) {
  if (!d) return '—'
  return String(d).slice(0, 10)
}

function conditionLabel(c: string) {
  if (!c) return '—'
  return c.charAt(0).toUpperCase() + c.slice(1)
}

function conditionColor(c: string) {
  return { good: 'success', ok: 'info', worn: 'warning', damaged: 'error', new: 'primary' }[c] || 'default'
}

function conditionChipColor(c: string) {
  return conditionColor(c)
}

function movementColor(m: string) {
  return { mount: 'success', unmount: 'warning', rotate: 'primary', retire: 'error', scrap: 'error', transfer: 'info' }[m] || 'default'
}

function openTireDetail(t: any) {
  selectedTire.value = t
  tireDialog.value = true
}

function openRotationDetail(r: any) {
  selectedRotation.value = r
  rotationDialog.value = true
}

function goToRotate() {
  navigateTo(`/app/tires/rotate?vehicle=${props.vehicleId}`)
}

function goToEditRotation(r: any) {
  rotationDialog.value = false
  navigateTo(`/app/tires/rotate/${r.id}`)
}

function goToTire(_t: any) {
  navigateTo('/app/tires')
}

async function load() {
  loading.value = true
  try {
    const [v, t, r, i, m] = await Promise.all([
      $api(`/vehicles/vehicles/${props.vehicleId}/`),
      $api(`/tires/?vehicle=${props.vehicleId}`),
      $api(`/tires/rotations/?vehicle=${props.vehicleId}`),
      $api(`/tires/inspections/?vehicle=${props.vehicleId}`),
      $api(`/tires/movements/?from_vehicle=${props.vehicleId}`),
    ])
    vehicleData.value = v
    tires.value = t?.results || t || []
    rotations.value = (r?.results || r || []).sort((a: any, b: any) => (b.performed_at || '').localeCompare(a.performed_at || ''))
    inspections.value = (i?.results || i || []).sort((a: any, b: any) => (b.measured_at || '').localeCompare(a.measured_at || ''))
    movements.value = (m?.results || m || []).sort((a: any, b: any) => (b.performed_at || '').localeCompare(a.performed_at || ''))
  } catch (e) {
    // soft-fail
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<style scoped>
.tire-mgmt-wrap {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Summary cards */
.tm-summary-row {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
}
.tm-summary-card {
  display: flex;
  align-items: center;
  padding: 14px 16px;
  border-radius: 14px;
  background: linear-gradient(180deg, #ffffff, #f8fafc);
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}
.tm-summary-card--primary {
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: #ffffff;
  border-color: #4f46e5;
}
/* Dimmed state when the primary Mounted Tires card is not the active tab */
.tm-summary-card--primary:not(.tm-summary-card--primary-active) {
  opacity: 0.65;
  background: linear-gradient(135deg, #a5b4fc, #818cf8);
  border-color: #a5b4fc;
}
.tm-summary-card--primary .tm-summary-num,
.tm-summary-card--primary .tm-summary-lbl {
  color: #ffffff;
}
.tm-summary-num {
  font-size: 22px;
  font-weight: 700;
  line-height: 1;
  color: #0f172a;
  letter-spacing: -0.02em;
}
.tm-summary-lbl {
  font-size: 11px;
  color: #64748b;
  margin-top: 2px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.tm-summary-card--clickable {
  cursor: pointer;
  transition: all 0.15s ease;
  position: relative;
  user-select: none;
}
.tm-summary-card--clickable:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.10);
  border-color: #c7d2fe;
}
.tm-summary-card--clickable:active {
  transform: translateY(0);
}
.tm-summary-card--active {
  border-color: #6366f1;
  background: linear-gradient(180deg, #eef2ff, #e0e7ff);
  box-shadow: 0 4px 14px rgba(99, 102, 241, 0.18);
}
.tm-summary-card--active .tm-summary-num { color: #4f46e5; }
.tm-summary-chev {
  margin-left: 6px;
  color: #94a3b8;
  transition: color 0.15s ease;
}
.tm-summary-card--active .tm-summary-chev { color: #4f46e5; }
.tm-summary-card--primary .tm-summary-chev { color: rgba(255, 255, 255, 0.85); }

/* Two-column: 3D axle + mounted list */
.tm-grid {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 16px;
}
.tm-axle-panel,
.tm-mounted-panel {
  background: linear-gradient(180deg, #ffffff, #fbfcfe);
  border: 1px solid #eef2f6;
  border-radius: 16px;
  padding: 18px;
}
.tm-axle-scroll {
  max-height: 420px;
  overflow: auto;
  border-radius: 12px;
}
.tm-section-title {
  display: flex;
  align-items: center;
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.01em;
}

/* Tire rows */
.tm-tire-row {
  padding: 12px 14px;
  border: 1px solid #eef2f6;
  border-radius: 12px;
  background: #ffffff;
  cursor: pointer;
  transition: all 0.15s ease;
}
.tm-tire-row:hover {
  border-color: #c7d2fe;
  background: #f5f7ff;
}
.tm-tire-row__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}
.tm-tire-serial {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  letter-spacing: 0.02em;
}
.tm-tire-row__meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
}
.tm-tire-row__meta .dot {
  opacity: 0.5;
}

/* Blocks */
.tm-block {
  background: linear-gradient(180deg, #ffffff, #fbfcfe);
  border: 1px solid #eef2f6;
  border-radius: 16px;
  padding: 18px;
}

/* Empty state */
.tm-empty {
  color: #94a3b8;
}
.tm-empty p {
  font-size: 13px;
  margin: 0;
}

/* Swap list */
.tm-swap-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.tm-swap-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  padding: 10px 12px;
  background: #f8fafc;
  border-radius: 10px;
  border: 1px solid #eef2f6;
  font-size: 13px;
  color: #1e293b;
}

/* Responsive */
@media (max-width: 1100px) {
  .tm-summary-row { grid-template-columns: repeat(2, 1fr); }
  .tm-grid { grid-template-columns: 1fr; }
}
</style>
