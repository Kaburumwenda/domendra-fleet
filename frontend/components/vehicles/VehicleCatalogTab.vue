<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <span class="text-body-2 text-medium-emphasis">Manage makes, body types and models available when adding vehicles.</span>
      <v-btn variant="outlined" color="primary" prepend-icon="mdi-database-import-outline" size="small" :loading="seeding" @click="seedCatalog">Seed Catalog</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-tabs v-model="subTab" density="compact" color="primary">
        <v-tab value="makes" prepend-icon="mdi-car-multiple">Makes</v-tab>
        <v-tab value="bodytypes" prepend-icon="mdi-shape">Body Types</v-tab>
        <v-tab value="models" prepend-icon="mdi-format-list-bulleted-type">Models</v-tab>
      </v-tabs>
      <v-divider />

      <v-window v-model="subTab">
        <!-- MAKES -->
        <v-window-item value="makes">
          <div class="d-flex align-center justify-space-between pa-4">
            <v-text-field v-model="makeSearch" prepend-inner-icon="mdi-magnify" placeholder="Search makes..." density="compact" hide-details style="max-width: 300px" variant="outlined" />
            <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openMakeCreate">Add Make</v-btn>
          </div>
          <v-data-table :headers="makeHeaders" :items="makes" :loading="makesPending" :items-per-page="20" :search="makeSearch" hover>
            <template #item.name="{ item }">
              <span class="font-weight-medium" style="color: #1e293b">{{ item.name }}</span>
            </template>
            <template #item.model_count="{ value }">
              <v-chip size="small" variant="tonal">{{ value || 0 }}</v-chip>
            </template>
            <template #item.actions="{ item }">
              <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteMake(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-car-multiple</v-icon>
                <p>No makes yet.</p>
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- BODY TYPES -->
        <v-window-item value="bodytypes">
          <div class="d-flex align-center justify-space-between pa-4">
            <v-text-field v-model="btSearch" prepend-inner-icon="mdi-magnify" placeholder="Search body types..." density="compact" hide-details style="max-width: 300px" variant="outlined" />
            <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openBtCreate">Add Body Type</v-btn>
          </div>
          <v-data-table :headers="btHeaders" :items="bodyTypes" :loading="btPending" :items-per-page="20" :search="btSearch" hover>
            <template #item.icon="{ value }">
              <v-icon>{{ value || 'mdi-car' }}</v-icon>
            </template>
            <template #item.label="{ item }">
              <span class="font-weight-medium" style="color: #1e293b">{{ item.label }}</span>
            </template>
            <template #item.model_count="{ value }">
              <v-chip size="small" variant="tonal">{{ value || 0 }}</v-chip>
            </template>
            <template #item.actions="{ item }">
              <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteBt(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-shape</v-icon>
                <p>No body types yet.</p>
              </div>
            </template>
          </v-data-table>
        </v-window-item>

        <!-- MODELS -->
        <v-window-item value="models">
          <div class="d-flex flex-wrap align-center justify-space-between ga-2 pa-4">
            <div class="d-flex ga-2">
              <v-select v-model="modelMakeFilter" :items="makeFilterItems" item-title="name" item-value="id" label="Make" density="compact" hide-details clearable style="max-width: 200px" />
              <v-select v-model="modelBtFilter" :items="btFilterItems" item-title="label" item-value="id" label="Body Type" density="compact" hide-details clearable style="max-width: 200px" />
            </div>
            <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openModelCreate">Add Model</v-btn>
          </div>
          <v-data-table :headers="modelHeaders" :items="filteredModels" :loading="modelsPending" :items-per-page="20" hover>
            <template #item.make_name="{ item }">
              <span class="font-weight-medium" style="color: #1e293b">{{ item.make_name }}</span>
            </template>
            <template #item.body_type_label="{ item }">
              <div class="d-flex align-center ga-2">
                <v-icon size="small">{{ bodyTypeIconValue(item) }}</v-icon>
                <span>{{ item.body_type_label }}</span>
              </div>
            </template>
            <template #item.actions="{ item }">
              <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteModel(item)" />
            </template>
            <template #no-data>
              <div class="text-center py-12 text-medium-emphasis">
                <v-icon size="48" class="mb-3">mdi-format-list-bulleted-type</v-icon>
                <p>No models yet.</p>
              </div>
            </template>
          </v-data-table>
        </v-window-item>
      </v-window>
    </v-card>

    <!-- Make dialog -->
    <v-dialog v-model="makeDialog" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-car-multiple">Add Make</AppModalHeader>
        <v-card-text>
          <v-text-field v-model="makeForm.name" label="Make Name" density="comfortable" :error-messages="makeErrors.name" autofocus />
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="makeDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="makeSaving" @click="saveMake">Create Make</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Body type dialog -->
    <v-dialog v-model="btDialog" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-shape">Add Body Type</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12"><v-text-field v-model="btForm.label" label="Label" density="comfortable" :error-messages="btErrors.label" placeholder="e.g. Sedan" /></v-col>
            <v-col cols="12"><v-text-field v-model="btForm.value" label="Value (slug)" density="comfortable" :error-messages="btErrors.value" placeholder="e.g. sedan" hint="Lowercase, no spaces" /></v-col>
            <v-col cols="12">
              <v-select v-model="btForm.icon" :items="iconPresets" label="Icon" density="comfortable">
                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend><v-icon>{{ item.raw }}</v-icon></template>
                  </v-list-item>
                </template>
                <template #selection="{ item }">
                  <v-icon size="18" class="mr-2">{{ item.raw }}</v-icon>
                  <span>{{ item.raw }}</span>
                </template>
              </v-select>
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="btDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="btSaving" @click="saveBt">Create Body Type</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Model dialog -->
    <v-dialog v-model="modelDialog" max-width="420">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-format-list-bulleted-type">Add Model</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12">
              <v-select v-model="modelForm.make" :items="makes" item-title="name" item-value="id" label="Make" density="comfortable" :error-messages="modelErrors.make" />
            </v-col>
            <v-col cols="12">
              <v-select v-model="modelForm.body_type" :items="bodyTypes" item-title="label" item-value="id" label="Body Type" density="comfortable" :error-messages="modelErrors.body_type" />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="modelForm.name" label="Model Name" density="comfortable" :error-messages="modelErrors.name" placeholder="e.g. Corolla" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="modelDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="modelSaving" @click="saveModel">Create Model</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { vehicleCatalog, bodyTypes as staticBodyTypes } from '~/composables/useVehicleCatalog'

const { $api, $swal } = useNuxtApp()

const subTab = ref('makes')

const tc = useTenantCatalog()
async function syncShared() {
  await tc.reload()
}

const seeding = ref(false)
function buildSeedPayload() {
  const makes = Array.from(new Set(vehicleCatalog.map((c) => c.make)))
  const body_types = staticBodyTypes.map((b) => ({ label: b.label, value: b.value, icon: b.icon }))
  const models: { make: string; body_type_value: string; name: string }[] = []
  for (const c of vehicleCatalog) {
    for (const m of c.models) {
      models.push({ make: c.make, body_type_value: c.bodyType, name: m })
    }
  }
  return { makes, body_types, models }
}
async function seedCatalog() {
  const { isConfirmed } = await $swal.fire({
    title: 'Seed Catalog',
    text: 'Seed the catalog with the built-in makes, body types and models? Existing entries are kept; only missing ones are added.',
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: 'Seed Catalog',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  seeding.value = true
  try {
    const res = await $api('/vehicles/catalog/seed/', { method: 'POST', body: buildSeedPayload() })
    await Promise.all([refreshMakes(), refreshBt(), refreshModels()])
    await syncShared()
    await $swal.fire({
      title: 'Catalog Seeded',
      html: `Makes: <b>${res.makes}</b><br>Body types: <b>${res.body_types}</b><br>Models: <b>${res.models}</b>`,
      icon: 'success',
      confirmButtonText: 'OK',
    })
  } catch (e: any) {
    console.error('Seed failed:', e?.data || e)
    await $swal.fire({ title: 'Seed Failed', text: 'Could not seed the catalog. See console for details.', icon: 'error', confirmButtonText: 'OK' })
  } finally {
    seeding.value = false
  }
}

const iconPresets = [
  'mdi-car-side', 'mdi-car-estate', 'mdi-car-hatchback', 'mdi-pickup-truck',
  'mdi-car-sports', 'mdi-car-convertible', 'mdi-van-passenger', 'mdi-van',
  'mdi-truck-outline', 'mdi-truck', 'mdi-bus', 'mdi-motorbike',
  'mdi-truck-flatbed', 'mdi-snowflake', 'mdi-car',
]

// --- Makes ---
const makeSearch = ref('')
const makeDialog = ref(false)
const makeSaving = ref(false)
const makeErrors = reactive<any>({})
const makeForm = reactive({ name: '' })
const makeHeaders = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Models', key: 'model_count', sortable: false, width: '120px' },
  { title: '', key: 'actions', width: '80px', sortable: false },
]
const { data: makesData, pending: makesPending, refresh: refreshMakes } = useAsyncData('catalog-makes', () =>
  $api('/vehicles/catalog/makes/'), { default: () => ({ results: [], count: 0 }) }
)
const makes = computed<any[]>(() => makesData.value?.results || makesData.value || [])

function openMakeCreate() {
  makeForm.name = ''
  makeErrors.name = ''
  makeDialog.value = true
}
async function saveMake() {
  makeErrors.name = ''
  if (!makeForm.name) { makeErrors.name = 'Name is required.'; return }
  makeSaving.value = true
  try {
    await $api('/vehicles/catalog/makes/', { method: 'POST', body: { name: makeForm.name } })
    makeDialog.value = false
    await refreshMakes()
    await syncShared()
  } catch (e: any) {
    makeErrors.name = e?.data?.name?.[0] || ''
  } finally {
    makeSaving.value = false
  }
}
async function deleteMake(m: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Make',
    text: `Delete make "${m.name}"? This also removes its models.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/vehicles/catalog/makes/${m.id}/`, { method: 'DELETE' })
  await refreshMakes()
  await refreshModels()
  await syncShared()
}

// --- Body Types ---
const btSearch = ref('')
const btDialog = ref(false)
const btSaving = ref(false)
const btErrors = reactive<any>({})
const btForm = reactive({ label: '', value: '', icon: 'mdi-car-side' })
const btHeaders = [
  { title: 'Icon', key: 'icon', sortable: false, width: '70px' },
  { title: 'Label', key: 'label', sortable: true },
  { title: 'Value', key: 'value', sortable: true, width: '160px' },
  { title: 'Models', key: 'model_count', sortable: false, width: '120px' },
  { title: '', key: 'actions', width: '80px', sortable: false },
]
const { data: btData, pending: btPending, refresh: refreshBt } = useAsyncData('catalog-bodytypes', () =>
  $api('/vehicles/catalog/body-types/'), { default: () => ({ results: [], count: 0 }) }
)
const bodyTypes = computed<any[]>(() => btData.value?.results || btData.value || [])

function slugify(s: string) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '')
}
watch(() => btForm.label, (v) => {
  if (v) btForm.value = slugify(v)
})
function openBtCreate() {
  Object.assign(btForm, { label: '', value: '', icon: 'mdi-car-side' })
  btErrors.label = ''; btErrors.value = ''
  btDialog.value = true
}
async function saveBt() {
  btErrors.label = ''; btErrors.value = ''
  if (!btForm.label) { btErrors.label = 'Label is required.'; return }
  if (!btForm.value) btForm.value = slugify(btForm.label)
  btSaving.value = true
  try {
    await $api('/vehicles/catalog/body-types/', { method: 'POST', body: { ...btForm } })
    btDialog.value = false
    await refreshBt()
    await syncShared()
  } catch (e: any) {
    btErrors.value = e?.data?.value?.[0] || ''
    btErrors.label = e?.data?.label?.[0] || ''
  } finally {
    btSaving.value = false
  }
}
async function deleteBt(b: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Body Type',
    text: `Delete body type "${b.label}"? This also removes its models.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/vehicles/catalog/body-types/${b.id}/`, { method: 'DELETE' })
  await refreshBt()
  await refreshModels()
  await syncShared()
}
function bodyTypeIconValue(item: any) {
  return bodyTypes.value.find((b) => b.id === item.body_type)?.icon || 'mdi-car'
}

// --- Models ---
const modelDialog = ref(false)
const modelSaving = ref(false)
const modelErrors = reactive<any>({})
const modelForm = reactive({ make: null as any, body_type: null as any, name: '' })
const modelMakeFilter = ref<any>(null)
const modelBtFilter = ref<any>(null)
const modelHeaders = [
  { title: 'Make', key: 'make_name', sortable: true },
  { title: 'Body Type', key: 'body_type_label', sortable: true },
  { title: 'Model', key: 'name', sortable: true },
  { title: '', key: 'actions', width: '80px', sortable: false },
]
const { data: modelsData, pending: modelsPending, refresh: refreshModels } = useAsyncData('catalog-models', () =>
  $api('/vehicles/catalog/models/'), { default: () => ({ results: [], count: 0 }) }
)
const models = computed<any[]>(() => modelsData.value?.results || modelsData.value || [])

const makeFilterItems = computed(() => makes.value)
const btFilterItems = computed(() => bodyTypes.value)
const filteredModels = computed(() => {
  if (!modelMakeFilter.value && !modelBtFilter.value) return models.value
  return models.value.filter((m) =>
    (!modelMakeFilter.value || m.make === modelMakeFilter.value) &&
    (!modelBtFilter.value || m.body_type === modelBtFilter.value)
  )
})

function openModelCreate() {
  if (!makes.value.length) {
    $swal.fire({ title: 'No Makes', text: 'Add a make first.', icon: 'info', confirmButtonText: 'OK' })
    subTab.value = 'makes'
    return
  }
  Object.assign(modelForm, { make: null, body_type: null, name: '' })
  modelErrors.make = ''; modelErrors.body_type = ''; modelErrors.name = ''
  modelDialog.value = true
}
async function saveModel() {
  modelErrors.make = ''; modelErrors.body_type = ''; modelErrors.name = ''
  if (!modelForm.make) { modelErrors.make = 'Make is required.'; return }
  if (!modelForm.body_type) { modelErrors.body_type = 'Body type is required.'; return }
  if (!modelForm.name) { modelErrors.name = 'Name is required.'; return }
  modelSaving.value = true
  try {
    await $api('/vehicles/catalog/models/', { method: 'POST', body: { ...modelForm } })
    modelDialog.value = false
    await refreshModels()
    await syncShared()
  } catch (e: any) {
    modelErrors.name = e?.data?.name?.[0] || ''
  } finally {
    modelSaving.value = false
  }
}
async function deleteModel(m: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Model',
    text: `Delete model "${m.name}"?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/vehicles/catalog/models/${m.id}/`, { method: 'DELETE' })
  await refreshModels()
  await syncShared()
}
</script>
