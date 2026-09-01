<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between">
      <div class="d-flex align-center ga-3">
        <span class="text-body-2 text-medium-emphasis">{{ files.length }} driver files</span>
        <v-btn v-if="expiringCount" prepend-icon="mdi-alert" variant="outlined" color="warning" size="small" @click="showExpiring">Expiring ({{ expiringCount }})</v-btn>
      </div>
      <v-btn v-can="'dqf:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openCreate">Add DQF</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table :headers="headers" :items="files" :loading="pending" hover>
        <template #item.status="{ value }"><v-chip size="small" :color="statusColor(value)">{{ value }}</v-chip></template>
        <template #item.completion_pct="{ value }">
          <v-progress-linear :model-value="value" :color="value === 100 ? 'success' : value >= 50 ? 'primary' : 'error'" height="8" rounded />
        </template>
        <template #item.next_review_due="{ value }">{{ value || '—' }}</template>
        <template #item.road_test_passed="{ value }"><v-icon :color="value ? 'success' : 'grey'">{{ value ? 'mdi-check' : 'mdi-close' }}</v-icon></template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openDetail(item)" />
            <v-btn v-can="'dqf:update'" icon="mdi-check-circle-outline" variant="text" size="small" title="Complete Review" @click="completeReview(item)" />
            <v-btn v-can="'dqf:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteItem(item)" />
          </div>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-account-check-outline</v-icon><p>No driver qualification files yet.</p></div>
        </template>
      </v-data-table>
    </v-card>

    <v-dialog v-model="dialogVisible" max-width="560">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-account-check-outline">{{ editing ? 'Edit DQF' : 'Add Driver Qualification File' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12"><v-select v-model="form.driver" :items="drivers" item-title="full_name" item-value="id" label="Driver" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.application_date" type="date" label="Application Date" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.hire_date" type="date" label="Hire Date" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.road_test_date" type="date" label="Road Test Date" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.road_test_examiner" label="Road Test Examiner" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.background_check_date" type="date" label="Background Check Date" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.drug_test_date" type="date" label="Drug Test Date" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.medical_examiner" label="Medical Examiner" /></v-col>
            <v-col cols="6"><v-text-field v-model="form.next_review_due" type="date" label="Next Review Due" /></v-col>
            <v-col cols="4"><v-checkbox v-model="form.road_test_passed" label="Road test" density="compact" /></v-col>
            <v-col cols="4"><v-checkbox v-model="form.background_check_passed" label="Background" density="compact" /></v-col>
            <v-col cols="4"><v-checkbox v-model="form.drug_test_passed" label="Drug test" density="compact" /></v-col>
            <v-col cols="12"><v-textarea v-model="form.notes" label="Notes" rows="2" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" @click="save" :loading="saving">{{ editing ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <v-dialog v-model="detailDialog" max-width="640">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-account-check-outline">DQF — {{ activeFile?.driver_name }}</AppModalHeader>
        <v-card-text>
          <div class="d-flex align-center ga-3 mb-4">
            <span class="text-body-2">Completion</span>
            <v-progress-linear :model-value="activeFile?.completion_pct || 0" color="primary" height="10" rounded style="max-width: 200px" />
            <span class="font-weight-bold">{{ activeFile?.completion_pct || 0 }}%</span>
            <v-chip size="small" :color="statusColor(activeFile?.status)">{{ activeFile?.status }}</v-chip>
          </div>
          <v-list density="compact">
            <v-list-item v-for="c in checks" :key="c.id" :title="c.check_type_label" :subtitle="c.result_notes">
              <template #append><v-chip size="x-small" :color="c.status === 'cleared' ? 'success' : c.status === 'flagged' ? 'error' : 'grey'">{{ c.status_label || c.status }}</v-chip></template>
            </v-list-item>
            <v-list-item v-if="!checks.length"><div class="text-center py-6 text-medium-emphasis">No checks recorded.</div></v-list-item>
          </v-list>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="detailDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const dialogVisible = ref(false)
const detailDialog = ref(false)
const editing = ref(false)
const saving = ref(false)
const activeFile = ref<any>(null)
const checks = ref<any[]>([])
const defaultForm = () => ({ driver: null, application_date: '', hire_date: '', road_test_date: '', road_test_examiner: '', background_check_date: '', drug_test_date: '', medical_examiner: '', next_review_due: '', road_test_passed: false, background_check_passed: false, drug_test_passed: false, notes: '' })
const form = reactive<any>(defaultForm())

const headers = [
  { title: 'Driver', key: 'driver_name', sortable: true },
  { title: 'Status', key: 'status', width: '130px' },
  { title: 'Completion', key: 'completion_pct', width: '160px' },
  { title: 'Road Test', key: 'road_test_passed', width: '90px' },
  { title: 'Next Review', key: 'next_review_due', width: '140px' },
  { title: '', key: 'actions', width: '140px', sortable: false },
]

const { data: fData, pending, refresh } = useAsyncData('dqf', () => $api('/dqf/files/'), { default: () => ({ results: [] }) })
const files = computed(() => fData.value?.results || [])
const { data: drvData } = useAsyncData('dqf-drivers', () => $api('/contacts/', { query: { contact_type: 'driver' } }), { default: () => ({ results: [] }) })
const drivers = computed(() => drvData.value?.results || [])

const expiringCount = computed(() => files.value.filter((f: any) => f.is_expired).length)

function statusColor(s: string) { return { complete: 'success', incomplete: 'warning', pending: 'info', expired: 'error', rejected: 'grey' }[s] || 'grey' }

function openCreate() { editing.value = false; Object.assign(form, defaultForm()); dialogVisible.value = true }
function openEdit(i: any) { editing.value = true; Object.assign(form, i); form._id = i.id; dialogVisible.value = true }
async function save() {
  saving.value = true
  try {
    if (editing.value) await $api(`/dqf/files/${form._id}/`, { method: 'PATCH', body: form })
    else await $api('/dqf/files/', { method: 'POST', body: form })
    dialogVisible.value = false; await refresh()
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteItem(i: any) { if (!confirm('Delete this DQF?')) return; await $api(`/dqf/files/${i.id}/`, { method: 'DELETE' }); await refresh() }
async function completeReview(i: any) { await $api(`/dqf/files/${i.id}/complete-review/`, { method: 'POST' }); await refresh() }

async function openDetail(i: any) { activeFile.value = i; checks.value = await $api('/dqf/checks/', { query: { dqf: i.id } }); detailDialog.value = true }
async function showExpiring() { const data = await $api('/dqf/files/expiring/'); fData.value = { results: data, count: data.length } }
</script>
