<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <div>
        <NuxtLink to="/app/inspections" class="text-caption text-medium-emphasis text-decoration-none">← Inspections</NuxtLink>
        <h2 class="text-h5 font-weight-bold mt-1">Inspection Form Builder</h2>
      </div>
      <v-btn v-can="'inspections:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openCreateForm">New Form</v-btn>
    </div>

    <v-row dense>
      <v-col cols="12" md="4">
        <v-card elevation="0" border rounded="lg">
          <v-card-title class="text-subtitle-1">Forms</v-card-title>
          <v-list density="compact">
            <v-list-item v-for="f in forms" :key="f.id" :active="activeFormId === f.id" :title="f.name" :subtitle="`${f.item_count || 0} items`" @click="selectForm(f.id)">
              <template #append>
                <v-chip v-if="!f.is_active" size="x-small" color="grey">off</v-chip>
                <v-btn v-can="'inspections:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click.stop="deleteForm(f)" />
              </template>
            </v-list-item>
            <v-list-item v-if="!forms.length"><div class="text-center py-6 text-medium-emphasis">No forms yet.</div></v-list-item>
          </v-list>
        </v-card>
      </v-col>

      <v-col cols="12" md="8">
        <v-card v-if="activeForm" elevation="0" border rounded="lg">
          <v-card-title class="text-subtitle-1 d-flex align-center justify-space-between">
            <span>{{ activeForm.name }}</span>
            <div class="d-flex ga-2">
              <v-btn v-can="'inspections:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEditForm" />
              <v-btn v-can="'inspections:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openAddItem">Add Item</v-btn>
            </div>
          </v-card-title>
          <v-card-text>
            <p class="text-body-2 text-medium-emphasis mb-4">{{ activeForm.description || 'No description' }}</p>
            <v-data-table :headers="itemHeaders" :items="items" density="compact" hover>
              <template #item.item_type="{ value }"><v-chip size="x-small">{{ value }}</v-chip></template>
              <template #item.is_critical="{ value }"><v-icon :color="value ? 'error' : 'grey'">{{ value ? 'mdi-alert' : 'mdi-minus' }}</v-icon></template>
              <template #item.is_required="{ value }"><v-icon :color="value ? 'success' : 'grey'">{{ value ? 'mdi-check' : 'mdi-minus' }}</v-icon></template>
              <template #item.actions="{ item }">
                <v-btn v-can="'inspections:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEditItem(item)" />
                <v-btn v-can="'inspections:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteItem(item)" />
              </template>
              <template #no-data><div class="text-center py-6 text-medium-emphasis">No items. Add inspection items to this form.</div></template>
            </v-data-table>
          </v-card-text>
        </v-card>
        <v-card v-else elevation="0" border rounded="lg" class="text-center pa-12 text-medium-emphasis">
          <v-icon size="48" class="mb-3">mdi-clipboard-edit-outline</v-icon>
          <p>Select or create a form to manage its inspection items.</p>
        </v-card>
      </v-col>
    </v-row>

    <v-dialog v-model="formDialog" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-clipboard-text-outline">{{ editingForm ? 'Edit Form' : 'New Form' }}</AppModalHeader>
        <v-card-text>
          <div class="d-flex flex-column ga-3">
            <v-text-field v-model="formForm.name" label="Form Name" />
            <v-textarea v-model="formForm.description" label="Description" rows="2" />
            <v-checkbox v-model="formForm.is_active" label="Active" density="compact" />
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="formDialog = false">Cancel</v-btn><v-btn color="primary" @click="saveForm" :loading="saving">{{ editingForm ? 'Update' : 'Create' }}</v-btn></v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="itemDialog" max-width="520">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-format-list-checkbox">{{ editingItem ? 'Edit Item' : 'Add Item' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12"><v-text-field v-model="itemForm.label" label="Item Label" /></v-col>
            <v-col cols="6"><v-select v-model="itemForm.item_type" :items="itemTypes" item-title="label" item-value="value" label="Type" /></v-col>
            <v-col cols="6"><v-text-field v-model.number="itemForm.order" label="Order" type="number" /></v-col>
            <v-col cols="6"><v-checkbox v-model="itemForm.is_critical" label="Critical (fails inspection)" density="compact" /></v-col>
            <v-col cols="6"><v-checkbox v-model="itemForm.is_required" label="Required" density="compact" /></v-col>
            <v-col cols="12"><v-text-field v-model="itemForm.help_text" label="Help Text" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="itemDialog = false">Cancel</v-btn><v-btn color="primary" @click="saveItem" :loading="saving">{{ editingItem ? 'Update' : 'Add' }}</v-btn></v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const activeFormId = ref<number | null>(null)
const formDialog = ref(false)
const itemDialog = ref(false)
const editingForm = ref(false)
const editingItem = ref(false)
const saving = ref(false)
const itemTypes = [
  { label: 'Pass / Fail', value: 'pass_fail' },
  { label: 'Text', value: 'text' },
  { label: 'Number', value: 'number' },
  { label: 'Photo', value: 'photo' },
  { label: 'Signature', value: 'signature' },
  { label: 'Checklist', value: 'checklist' },
]
const formForm = reactive<any>({ name: '', description: '', is_active: true })
const itemForm = reactive<any>({ label: '', item_type: 'pass_fail', is_critical: false, is_required: true, order: 0, help_text: '' })

const itemHeaders = [
  { title: 'Order', key: 'order', width: '70px' },
  { title: 'Label', key: 'label' },
  { title: 'Type', key: 'item_type', width: '120px' },
  { title: 'Critical', key: 'is_critical', width: '80px' },
  { title: 'Required', key: 'is_required', width: '80px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

const { data: fData, refresh: refreshForms } = useAsyncData('insp-forms-list', () => $api('/inspections/forms/'), { default: () => ({ results: [] }) })
const forms = computed(() => fData.value?.results || [])
const activeForm = computed(() => forms.value.find(f => f.id === activeFormId.value) || null)

const { data: iData, refresh: refreshItems } = useAsyncData('insp-items', () => $api('/inspections/items/', { query: { form: activeFormId.value } }), {
  default: () => ({ results: [] }),
  watch: [activeFormId],
})
const items = computed(() => iData.value?.results || [])

function selectForm(id: number) { activeFormId.value = id }
function openCreateForm() { editingForm.value = false; Object.assign(formForm, { name: '', description: '', is_active: true }); formDialog.value = true }
function openEditForm() { editingForm.value = true; Object.assign(formForm, activeForm.value); formForm._id = activeForm.value.id; formDialog.value = true }
async function saveForm() {
  saving.value = true
  try {
    if (editingForm.value) await $api(`/inspections/forms/${formForm._id}/`, { method: 'PATCH', body: formForm })
    else { const created = await $api('/inspections/forms/', { method: 'POST', body: formForm }); activeFormId.value = created.id }
    formDialog.value = false; await refreshForms()
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteForm(f: any) { if (!confirm(`Delete form ${f.name}?`)) return; await $api(`/inspections/forms/${f.id}/`, { method: 'DELETE' }); if (activeFormId.value === f.id) activeFormId.value = null; await refreshForms() }

function openAddItem() { editingItem.value = false; Object.assign(itemForm, { label: '', item_type: 'pass_fail', is_critical: false, is_required: true, order: items.value.length, help_text: '' }); itemDialog.value = true }
function openEditItem(i: any) { editingItem.value = true; Object.assign(itemForm, i); itemForm._id = i.id; itemDialog.value = true }
async function saveItem() {
  saving.value = true
  try {
    if (editingItem.value) await $api(`/inspections/items/${itemForm._id}/`, { method: 'PATCH', body: itemForm })
    else await $api('/inspections/items/', { method: 'POST', body: { ...itemForm, form: activeFormId.value } })
    itemDialog.value = false; await refreshItems()
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteItem(i: any) { if (!confirm('Delete this item?')) return; await $api(`/inspections/items/${i.id}/`, { method: 'DELETE' }); await refreshItems() }
</script>
