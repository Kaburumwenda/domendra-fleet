<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <span class="text-body-2 text-medium-emphasis">{{ groups.length }} groups</span>
      <v-btn v-can="'vehicles:create'" color="primary" prepend-icon="mdi-folder-plus" size="small" @click="openCreate">Add Vehicle Group</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers"
        :items="groups"
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
              placeholder="Search groups..."
              density="compact"
              hide-details
              style="max-width: 300px"
              variant="outlined"
            />
          </div>
        </template>

        <template #item.name="{ item }">
          <div class="d-flex align-center ga-2">
            <v-icon :color="item.color">mdi-folder</v-icon>
            <span class="font-weight-medium" style="color: #1e293b">{{ item.name }}</span>
          </div>
        </template>

        <template #item.color="{ value }">
          <div class="d-flex align-center ga-2">
            <span class="color-dot" :style="{ background: value }" />
            <span class="text-body-2 text-medium-emphasis">{{ value }}</span>
          </div>
        </template>

        <template #item.description="{ value }">
          <span class="text-body-2 text-medium-emphasis">{{ value || '—' }}</span>
        </template>

        <template #item.vehicle_count="{ value }">
          <v-chip size="small" variant="tonal">{{ value || 0 }}</v-chip>
        </template>

        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn v-can="'vehicles:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            <v-btn v-can="'vehicles:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteGroup(item)" />
          </div>
        </template>

        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-folder</v-icon>
            <p>No groups yet. Create one to organize your fleet.</p>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <v-dialog v-model="dialogVisible" max-width="500">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-folder-plus">{{ editing ? 'Edit Vehicle Group' : 'Add Vehicle Group' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="form.name" label="Group Name" density="comfortable" :error-messages="errors.name" />
              <div class="d-flex flex-wrap ga-2 mt-2">
                <v-chip
                  v-for="preset in groupPresets"
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
            <v-col cols="12">
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
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="save">{{ editing ? 'Update Group' : 'Create Group' }}</v-btn>
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
const editing = ref(false)
const errors = reactive<any>({})
const form = reactive({ id: null as any, name: '', description: '', color: '#6366f1' })

const headers = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Color', key: 'color', sortable: false, width: '150px' },
  { title: 'Description', key: 'description', sortable: false },
  { title: 'Vehicles', key: 'vehicle_count', sortable: false, width: '110px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

const groupPresets = [
  { name: 'Delivery', description: 'Vehicles used for deliveries and last-mile logistics.' },
  { name: 'Service', description: 'Vehicles assigned to field service and maintenance crews.' },
  { name: 'Sales', description: 'Vehicles used by the sales and account management team.' },
  { name: 'Long Haul', description: 'Long-distance freight and highway trucks.' },
  { name: 'Maintenance', description: 'Vehicles reserved for internal maintenance and shop use.' },
  { name: 'Rental', description: 'Vehicles available for rent or short-term assignment.' },
  { name: 'Executive', description: 'Vehicles reserved for executive and VIP transport.' },
]

const colorPresets = ['#6366f1', '#4f46e5', '#818cf8', '#22c55e', '#10b981', '#f59e0b', '#ef4444', '#ec4899', '#06b6d4', '#64748b']

const { data: groupsData, pending, refresh } = useAsyncData('vehicle-groups', () =>
  $api('/vehicles/groups/'), { default: () => ({ results: [], count: 0 }) }
)
const groups = computed(() => groupsData.value?.results || groupsData.value || [])

function applyPreset(preset: { name: string; description: string }) {
  form.name = preset.name
  if (preset.description) form.description = preset.description
  errors.name = ''
}

function openCreate() {
  editing.value = false
  Object.assign(form, { id: null, name: '', description: '', color: '#6366f1' })
  errors.name = ''
  dialogVisible.value = true
}

function openEdit(g: any) {
  editing.value = true
  Object.assign(form, { id: g.id, name: g.name, description: g.description || '', color: g.color || '#6366f1' })
  errors.name = ''
  dialogVisible.value = true
}

async function save() {
  errors.name = ''
  if (!form.name) {
    errors.name = 'Group name is required.'
    return
  }
  saving.value = true
  try {
    const body = { name: form.name, description: form.description, color: form.color }
    if (editing.value) {
      await $api(`/vehicles/groups/${form.id}/`, { method: 'PATCH', body })
    } else {
      await $api('/vehicles/groups/', { method: 'POST', body })
    }
    dialogVisible.value = false
    await refresh()
  } catch (e: any) {
    errors.name = e?.data?.name?.[0] || ''
    console.error('Group save failed:', e?.data || e)
  } finally {
    saving.value = false
  }
}

async function deleteGroup(g: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Group',
    text: `Delete group "${g.name}"? Vehicles will be unassigned.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/vehicles/groups/${g.id}/`, { method: 'DELETE' })
  await refresh()
}
</script>

<style scoped>
.color-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  display: inline-block;
  border: 1px solid #e2e8f0;
}
.color-swatch {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.1s ease, border-color 0.1s ease;
}
.color-swatch:hover {
  transform: scale(1.1);
  border-color: #e2e8f0;
}
</style>
