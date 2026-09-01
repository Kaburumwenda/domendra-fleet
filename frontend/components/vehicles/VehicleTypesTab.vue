<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <span class="text-body-2 text-medium-emphasis">{{ types.length }} vehicle types</span>
      <div class="d-flex ga-2">
        <v-btn variant="outlined" color="primary" prepend-icon="mdi-database-import-outline" size="small" :loading="seeding" @click="seedTypes">Seed Vehicle Types</v-btn>
        <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-shape-plus" size="small" @click="openCreate">Add Vehicle Type</v-btn>
      </div>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers"
        :items="types"
        :loading="pending"
        :items-per-page="20"
        :items-per-page-options="[10, 20, 50]"
        :search="search"
        hover
      >
        <template #top>
          <div class="d-flex align-center justify-space-between pa-4">
            <v-text-field
              v-model="search"
              prepend-inner-icon="mdi-magnify"
              placeholder="Search vehicle types..."
              density="compact"
              hide-details
              style="max-width: 300px"
              variant="outlined"
            />
          </div>
        </template>

        <template #item.name="{ item }">
          <div class="d-flex align-center ga-2">
            <v-avatar size="36" rounded="lg" :color="item.color + '22'">
              <v-icon :color="item.color">{{ item.icon || 'mdi-car' }}</v-icon>
            </v-avatar>
            <span class="font-weight-medium" style="color: #1e293b">{{ item.name }}</span>
          </div>
        </template>

        <template #item.description="{ value }">
          <span class="text-body-2 text-medium-emphasis">{{ value || '—' }}</span>
        </template>

        <template #item.passenger_capacity="{ value }">
          <v-chip v-if="value" size="small" variant="tonal">{{ value }} pax</v-chip>
          <span v-else class="text-body-2 text-medium-emphasis">—</span>
        </template>

        <template #item.cargo_capacity_kg="{ value }">
          <span v-if="value" class="text-body-2">{{ Number(value).toLocaleString() }} kg</span>
          <span v-else class="text-body-2 text-medium-emphasis">—</span>
        </template>

        <template #item.is_active="{ value }">
          <v-chip size="small" :color="value ? 'success' : 'default'" variant="flat">{{ value ? 'Active' : 'Inactive' }}</v-chip>
        </template>

        <template #item.sort_order="{ value }">
          <span class="text-body-2 text-medium-emphasis">{{ value }}</span>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteType(item)" />
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-shape</v-icon>
            <p>No vehicle types yet. Create one or seed the built-in collection.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <v-dialog v-model="dialogVisible" max-width="560">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-shape-plus">{{ editing ? 'Edit Vehicle Type' : 'Add Vehicle Type' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="form.name" label="Name *" density="comfortable" :error-messages="errors.name" />
              <div class="d-flex flex-wrap ga-2 mt-2">
                <v-chip
                  v-for="preset in typePresets"
                  :key="preset.name"
                  size="small"
                  variant="outlined"
                  :color="form.name === preset.name ? 'primary' : undefined"
                  @click="applyPreset(preset)"
                >{{ preset.name }}</v-chip>
              </div>
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.description" label="Description" density="comfortable" rows="2" />
            </v-col>
            <v-col cols="6">
              <v-text-field v-model="form.icon" label="MDI Icon" density="comfortable" prepend-inner-icon="mdi-gauge" hint="Material Design Icon name (e.g. mdi-car-sports)" persistent-hint hide-details />
              <div class="icon-picker-grid mt-2">
                <button
                  v-for="ic in iconPresets"
                  :key="ic"
                  type="button"
                  class="icon-picker-item"
                  :class="{ 'icon-picker-item--active': form.icon === ic }"
                  :title="ic"
                  @click="form.icon = ic"
                >
                  <v-icon size="20">{{ ic }}</v-icon>
                </button>
              </div>
            </v-col>
            <v-col cols="6">
              <div class="d-flex align-center ga-3">
                <v-text-field v-model="form.color" label="Color" density="comfortable" hide-details style="max-width: 160px" />
                <v-color-picker v-model="form.color" hide-canvas hide-inputs mode="hex" width="120" />
              </div>
              <div class="d-flex flex-wrap ga-2 mt-2">
                <div
                  v-for="c in colorPresets"
                  :key="c"
                  class="color-swatch"
                  :style="{ background: c }"
                  :title="c"
                  @click="form.color = c"
                >
                  <v-icon v-if="form.color === c" size="16" color="white">mdi-check</v-icon>
                </div>
              </div>
            </v-col>
            <v-col cols="6">
              <v-text-field v-model.number="form.passenger_capacity" type="number" label="Passenger Capacity" density="comfortable" hint="0 = not specified" persistent-hint hide-details />
            </v-col>
            <v-col cols="6">
              <v-text-field v-model.number="form.cargo_capacity_kg" type="number" label="Cargo Capacity (kg)" density="comfortable" hint="0 = not specified" persistent-hint hide-details />
            </v-col>
            <v-col cols="6">
              <v-text-field v-model.number="form.sort_order" type="number" label="Sort Order" density="comfortable" hint="Lower appears first" persistent-hint hide-details />
            </v-col>
            <v-col cols="6">
              <v-select v-model="form.is_active" :items="[{label:'Active',value:true},{label:'Inactive',value:false}]" item-title="label" item-value="value" label="Status" density="comfortable" hide-details />
            </v-col>
            <!-- Icon preview -->
            <v-col cols="12" class="mt-2">
              <div class="text-caption text-medium-emphasis mb-2">Icon preview</div>
              <v-avatar size="44" rounded="lg" :color="form.color + '22'">
                <v-icon :color="form.color" size="24">{{ form.icon || 'mdi-car' }}</v-icon>
              </v-avatar>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="save">{{ editing ? 'Update Type' : 'Create Type' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()

const search = ref('')
const dialogVisible = ref(false)
const saving = ref(false)
const seeding = ref(false)
const editing = ref(false)
const errors = reactive<any>({})
const form = reactive({
  id: null as any,
  name: '',
  description: '',
  icon: 'mdi-car',
  color: '#6366f1',
  passenger_capacity: 0,
  cargo_capacity_kg: 0,
  sort_order: 0,
  is_active: true,
})

const headers = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Description', key: 'description', sortable: false },
  { title: 'Capacity', key: 'passenger_capacity', sortable: false, width: '120px' },
  { title: 'Cargo (kg)', key: 'cargo_capacity_kg', sortable: false, width: '130px' },
  { title: 'Order', key: 'sort_order', sortable: true, width: '80px' },
  { title: 'Status', key: 'is_active', sortable: true, width: '100px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

const colorPresets = [
  '#6366f1', '#4f46e5', '#22c55e', '#10b981', '#f59e0b',
  '#ef4444', '#ec4899', '#06b6d4', '#f97316', '#8b5cf6',
]

/** Selectable MDI icon grid — vehicle / trailer / equipment related. */
const iconPresets = [
  'mdi-car',
  'mdi-car-side',
  'mdi-car-estate',
  'mdi-car-hatchback',
  'mdi-car-sports',
  'mdi-car-convertible',
  'mdi-car-electric',
  'mdi-car-limousine',
  'mdi-car-wash',
  'mdi-pickup-truck',
  'mdi-van-passenger',
  'mdi-van-utility',
  'mdi-van',
  'mdi-truck',
  'mdi-truck-outline',
  'mdi-truck-flatbed',
  'mdi-truck-trailer',
  'mdi-bus',
  'mdi-bus-side',
  'mdi-motorbike',
  'mdi-bicycle',
  'mdi-rickshaw',
  'mdi-snowflake',
  'mdi-tanker-truck',
  'mdi-forklift',
  'mdi-tractor',
  'mdi-bulldozer',
  'mdi-wrench',
  'mdi-forklift',
]

/**
 * Built-in vehicle type collection users can seed into the database.
 * Mirrors the preset list in seed_vehicle_types.py — kept here for quick
 * selection when creating a new type, and for client-side seeding.
 */
const typePresets = [
  { name: 'Sedan', description: 'Standard 4-door passenger car with a separate trunk — ideal for executive and daily commute use.', icon: 'mdi-car-side', color: '#6366f1', passenger_capacity: 5, cargo_capacity_kg: 400 },
  { name: 'SUV', description: 'Sport Utility Vehicle with higher ground clearance, 4WD/AWD, and a spacious cabin for 7+ passengers.', icon: 'mdi-car-estate', color: '#22c55e', passenger_capacity: 7, cargo_capacity_kg: 800 },
  { name: 'Mini-van', description: 'Compact van optimized for passenger transport with sliding doors — perfect for small group trips.', icon: 'mdi-van-passenger', color: '#f59e0b', passenger_capacity: 8, cargo_capacity_kg: 600 },
  { name: 'Van', description: 'Full-size van for cargo or large group transport, with flexible seating and loading configurations.', icon: 'mdi-van-utility', color: '#06b6d4', passenger_capacity: 12, cargo_capacity_kg: 1000 },
  { name: 'Pickup Truck', description: 'Light-duty truck with an open cargo bed — versatile for mixed passenger and cargo duty.', icon: 'mdi-pickup-truck', color: '#10b981', passenger_capacity: 5, cargo_capacity_kg: 1200 },
  { name: 'Hatchback', description: 'Compact car with a rear door that swings upward for a combined cargo and passenger area.', icon: 'mdi-car-hatchback', color: '#ec4899', passenger_capacity: 5, cargo_capacity_kg: 300 },
  { name: 'Coupe', description: 'Two-door sporty car with a fixed roof and limited rear-seat space.', icon: 'mdi-car-sports', color: '#ef4444', passenger_capacity: 4, cargo_capacity_kg: 250 },
  { name: 'Convertible', description: 'Open-body car with a retractable or removable roof — premium leisure segment.', icon: 'mdi-car-convertible', color: '#8b5cf6', passenger_capacity: 4, cargo_capacity_kg: 200 },
  { name: 'Bus', description: 'Large passenger vehicle for scheduled, charter, or shuttle services.', icon: 'mdi-bus', color: '#f97316', passenger_capacity: 45, cargo_capacity_kg: 500 },
  { name: 'Truck', description: 'Heavy-duty truck for freight and long-haul logistics with a enclosed or open body.', icon: 'mdi-truck-outline', color: '#4f46e5', passenger_capacity: 3, cargo_capacity_kg: 8000 },
  { name: 'Box Truck', description: 'Rigid truck with an enclosed cargo box — for furniture, appliances, and parcel deliveries.', icon: 'mdi-truck', color: '#0ea5e9', passenger_capacity: 2, cargo_capacity_kg: 6000 },
  { name: 'Flatbed', description: 'Truck with an open flatbed for oversized or palletized loads and equipment transport.', icon: 'mdi-truck-flatbed', color: '#64748b', passenger_capacity: 2, cargo_capacity_kg: 10000 },
  { name: 'Motorbike', description: 'Two-wheeled motor vehicle — for dispatch, courier, and rapid last-mile delivery.', icon: 'mdi-motorbike', color: '#dc2626', passenger_capacity: 2, cargo_capacity_kg: 50 },
  { name: 'Refrigerated', description: 'Insulated truck with refrigeration for perishable goods and cold-chain logistics.', icon: 'mdi-snowflake', color: '#0284c7', passenger_capacity: 2, cargo_capacity_kg: 5000 },
  { name: 'Crossover', description: 'Car-based SUV body with unibody construction — on-road focused with elevated seating.', icon: 'mdi-car-estate', color: '#34d399', passenger_capacity: 5, cargo_capacity_kg: 650 },
  { name: 'Wagon', description: 'Estate / station wagon with an extended roofline for a larger cargo area.', icon: 'mdi-car-estate', color: '#fb7185', passenger_capacity: 5, cargo_capacity_kg: 700 },
  { name: 'Tuk Tuk', description: 'Three-wheeled passenger vehicle — urban and short-distance trips.', icon: 'mdi-rickshaw', color: '#facc15', passenger_capacity: 3, cargo_capacity_kg: 100 },
  { name: 'Tractor Unit', description: 'Semi-tractor for articulated haulage of trailers and shipping containers.', icon: 'mdi-truck-trailer', color: '#1e293b', passenger_capacity: 2, cargo_capacity_kg: 20000 },
  { name: 'Trailer', description: 'Unpowered trailer — coupled to a tractor unit for hauling freight and goods.', icon: 'mdi-truck-trailer', color: '#94a3b8', passenger_capacity: 0, cargo_capacity_kg: 25000 },
  { name: 'Tail Lift Van', description: 'Van equipped with a tail lift for heavy-item loading and pallet deliveries.', icon: 'mdi-van-utility', color: '#38bdf8', passenger_capacity: 3, cargo_capacity_kg: 1500 },
]

const { data: typesData, pending, refresh } = useAsyncData('vehicle-types', () =>
  $api('/vehicles/vehicle-types/'), { default: () => ({ results: [], count: 0 }) }
)
const types = computed<any[]>(() => typesData.value?.results || typesData.value || [])

function applyPreset(preset: { name: string; description: string; icon: string; color: string; passenger_capacity: number; cargo_capacity_kg: number }) {
  form.name = preset.name
  form.description = preset.description
  form.icon = preset.icon
  form.color = preset.color
  form.passenger_capacity = preset.passenger_capacity
  form.cargo_capacity_kg = preset.cargo_capacity_kg
  errors.name = ''
}

/**
 * Track the last description that was auto-applied so we don't overwrite a
 * user's manual edit when they change the name. When the user empties the
 * name or types a value that matches a preset, we auto-fill the description
 * (only if the current description is empty or was previously auto-applied).
 */
let _lastAutoDesc = ''
watch(() => form.name, (name) => {
  if (editing.value) return
  const match = typePresets.find((p) => p.name.toLowerCase() === (name || '').trim().toLowerCase())
  if (match) {
    if (!form.description || form.description === _lastAutoDesc) {
      form.description = match.description
      _lastAutoDesc = match.description
      // Also align icon / colour / capacities when the name matches exactly
      if (form.icon === 'mdi-car' || !form.icon) form.icon = match.icon
      if (form.color === '#6366f1') form.color = match.color
      if (!form.passenger_capacity) form.passenger_capacity = match.passenger_capacity
      if (!form.cargo_capacity_kg) form.cargo_capacity_kg = match.cargo_capacity_kg
    }
  } else if (!name && form.description === _lastAutoDesc) {
    // Name cleared — clear the auto-applied description too
    form.description = ''
    _lastAutoDesc = ''
  }
})

function openCreate() {
  editing.value = false
  _lastAutoDesc = ''
  Object.assign(form, {
    id: null, name: '', description: '', icon: 'mdi-car', color: '#6366f1',
    passenger_capacity: 0, cargo_capacity_kg: 0, sort_order: 0, is_active: true,
  })
  errors.name = ''
  dialogVisible.value = true
}

function openEdit(t: any) {
  editing.value = true
  _lastAutoDesc = t.description || ''
  Object.assign(form, {
    id: t.id, name: t.name, description: t.description || '', icon: t.icon || 'mdi-car',
    color: t.color || '#6366f1', passenger_capacity: t.passenger_capacity || 0,
    cargo_capacity_kg: t.cargo_capacity_kg || 0, sort_order: t.sort_order || 0,
    is_active: t.is_active !== null ? t.is_active : true,
  })
  errors.name = ''
  dialogVisible.value = true
}

async function save() {
  errors.name = ''
  if (!form.name) {
    errors.name = 'Name is required.'
    return
  }
  saving.value = true
  try {
    const body = { ...form }
    delete (body as any).id
    if (editing.value) {
      await $api(`/vehicles/vehicle-types/${form.id}/`, { method: 'PATCH', body })
    } else {
      await $api('/vehicles/vehicle-types/', { method: 'POST', body })
    }
    dialogVisible.value = false
    await refresh()
  } catch (e: any) {
    errors.name = e?.data?.name?.[0] || ''
    console.error('Vehicle type save failed:', e?.data || e)
  } finally {
    saving.value = false
  }
}

async function deleteType(t: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Vehicle Type',
    text: `Delete vehicle type "${t.name}"?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
    confirmButtonColor: '#ef4444',
  })
  if (!isConfirmed) return
  await $api(`/vehicles/vehicle-types/${t.id}/`, { method: 'DELETE' })
  await refresh()
}

/** Seed the entire built-in vehicle type collection via the API (idempotent). */
async function seedTypes() {
  const { isConfirmed } = await $swal.fire({
    title: 'Seed Vehicle Types',
    html: 'Seed the built-in vehicle type collection (Sedan, SUV, Mini-van, Pickup Truck, Bus, Truck, Motorbike, etc.) into the database?<br><br>Existing types with the same name are kept — only missing ones are added.',
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Seed',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  seeding.value = true
  let created = 0
  let existing = 0
  try {
    // POST each preset individually; report counters
    for (const preset of typePresets) {
      try {
        await $api('/vehicles/vehicle-types/', {
          method: 'POST',
          body: {
            name: preset.name,
            description: preset.description,
            icon: preset.icon,
            color: preset.color,
            passenger_capacity: preset.passenger_capacity,
            cargo_capacity_kg: preset.cargo_capacity_kg,
            is_active: true,
          },
        })
        created++
      } catch (e: any) {
        // Conflict (unique name) means the type already exists
        existing++
      }
    }
    await refresh()
    await $swal.fire({
      title: 'Vehicle Types Seeded',
      html: `Created: <b>${created}</b><br>Already existed: <b>${existing}</b>`,
      icon: 'success',
      confirmButtonText: 'OK',
    })
  } catch (e: any) {
    console.error('Seed failed:', e?.data || e)
    await $swal.fire({ title: 'Seed Failed', text: 'Could not seed vehicle types. See console for details.', icon: 'error', confirmButtonText: 'OK' })
  } finally {
    seeding.value = false
  }
}
</script>

<style scoped>
.color-swatch {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: border-color 0.15s ease, transform 0.15s ease;
}
.color-swatch:hover {
  transform: scale(1.1);
}

/* Icon picker grid */
.icon-picker-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(40px, 1fr));
  gap: 6px;
  max-height: 200px;
  overflow-y: auto;
  padding: 8px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
}
.icon-picker-item {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: #ffffff;
  color: #475569;
  cursor: pointer;
  transition: all 0.15s ease;
}
.icon-picker-item:hover {
  border-color: #c7d2fe;
  background: #eef2ff;
  color: #4f46e5;
  transform: translateY(-1px);
}
.icon-picker-item--active {
  border-color: #6366f1;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}
.icon-picker-item--active:hover {
  border-color: #6366f1;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: #ffffff;
}
</style>
