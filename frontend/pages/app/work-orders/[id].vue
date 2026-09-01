<template>
  <div v-if="wo" class="d-flex flex-column ga-4">
    <!-- Breadcrumb + header -->
    <div>
      <NuxtLink to="/app/work-orders" class="text-caption text-medium-emphasis text-decoration-none">← Work Orders</NuxtLink>
      <div class="d-flex align-center justify-space-between mt-1 flex-wrap ga-2">
        <div>
          <h2 class="text-h5 font-weight-bold d-flex align-center ga-2">
            <v-icon color="primary">mdi-clipboard-list-outline</v-icon>
            WO #{{ wo.id }} — {{ wo.issue_title }}
          </h2>
          <p class="text-body-2 text-medium-emphasis mt-1">{{ wo.vehicle_name || '—' }} · {{ wo.assigned_to_name || 'Unassigned' }}</p>
        </div>
        <div class="d-flex align-center ga-2">
          <v-chip :color="statusColor(wo.status)" variant="flat" size="small" class="text-capitalize">
            <v-icon start size="14">{{ statusIcon(wo.status) }}</v-icon>{{ wo.status ? wo.status.replace('_', ' ') : '' }}
          </v-chip>
          <v-chip :color="wo.assignment_type === 'internal' ? 'primary' : 'deep-purple'" variant="tonal" size="small" class="text-capitalize">
            <v-icon start size="14">{{ wo.assignment_type === 'internal' ? 'mdi-account-wrench' : 'mdi-store' }}</v-icon>{{ wo.assignment_type === 'internal' ? 'Internal' : 'External' }}
          </v-chip>
        </div>
      </div>
    </div>

    <!-- Cost KPI Cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 text-center kpi-card">
          <v-icon size="20" color="primary" class="mb-1">mdi-cash-approximate</v-icon>
          <p class="text-h5 font-weight-bold text-primary">{{ currencySymbol }}{{ money(wo.estimated_cost) }}</p>
          <p class="text-caption text-medium-emphasis">Estimated</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 text-center kpi-card">
          <v-icon size="20" color="warning" class="mb-1">mdi-account-cash</v-icon>
          <p class="text-h5 font-weight-bold text-warning">{{ currencySymbol }}{{ money(wo.labor_cost) }}</p>
          <p class="text-caption text-medium-emphasis">Labor</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 text-center kpi-card">
          <v-icon size="20" color="deep-purple" class="mb-1">mdi-package-variant-closed</v-icon>
          <p class="text-h5 font-weight-bold text-deep-purple">{{ currencySymbol }}{{ money(wo.parts_cost) }}</p>
          <p class="text-caption text-medium-emphasis">Parts</p>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4 text-center kpi-card kpi-total">
          <v-icon size="20" color="success" class="mb-1">mdi-cash-check</v-icon>
          <p class="text-h5 font-weight-bold text-success">{{ currencySymbol }}{{ money(wo.total_cost) }}</p>
          <p class="text-caption text-medium-emphasis">Total</p>
        </v-card>
      </v-col>
    </v-row>

    <v-row dense>
      <v-col cols="12" md="8">
        <!-- Time & Labor -->
        <v-card elevation="0" border rounded="lg" class="mb-4">
          <v-card-title class="text-subtitle-1 d-flex align-center justify-space-between">
            <span class="d-flex align-center ga-2"><v-icon color="primary">mdi-clock-outline</v-icon>Time &amp; Labor</span>
            <div class="d-flex ga-2">
              <v-btn v-can="'maintenance:update'" v-if="!activeLog" color="primary" prepend-icon="mdi-clock-in" size="small" @click="clockIn" :loading="saving">Clock In</v-btn>
              <v-btn v-can="'maintenance:update'" v-else color="error" prepend-icon="mdi-clock-out" size="small" @click="clockOut" :loading="saving">Clock Out</v-btn>
            </div>
          </v-card-title>
          <v-data-table :headers="timeHeaders" :items="wo.time_logs || []" density="compact" hide-default-footer>
            <template #item.mechanic_name="{ value }">
              <div class="d-flex align-center ga-2">
                <v-avatar size="24" variant="tonal" color="primary" class="text-caption">{{ initials(value || '?') }}</v-avatar>
                <span class="font-weight-medium">{{ value || '—' }}</span>
              </div>
            </template>
            <template #item.hours="{ value }"><v-chip size="small" variant="tonal" :color="value ? 'info' : 'warning'">{{ value ? value.toFixed(2) + 'h' : 'active' }}</v-chip></template>
            <template #item.clock_in="{ value }">{{ value ? fmt(value) : '—' }}</template>
            <template #item.clock_out="{ value }">{{ value ? fmt(value) : '<span class="text-warning">active</span>' }}</template>
            <template #no-data><div class="text-center py-6 text-medium-emphasis"><v-icon size="32" class="mb-2">mdi-clock-alert-outline</v-icon><p>No time logged yet.</p></div></template>
          </v-data-table>
        </v-card>

        <!-- Parts Used -->
        <v-card elevation="0" border rounded="lg" class="mb-4">
          <v-card-title class="text-subtitle-1 d-flex align-center justify-space-between">
            <span class="d-flex align-center ga-2"><v-icon color="deep-purple">mdi-package-variant-closed</v-icon>Parts Used</span>
            <v-btn v-can="'maintenance:create'" color="deep-purple" prepend-icon="mdi-plus" size="small" @click="partDialog = true">Add Part</v-btn>
          </v-card-title>
          <v-data-table :headers="partHeaders" :items="wo.parts_used || []" density="compact" hide-default-footer>
            <template #item.unit_cost="{ value }">{{ currencySymbol }}{{ money(value) }}</template>
            <template #item.total_cost="{ value }"><span class="font-weight-bold">{{ currencySymbol }}{{ money(value) }}</span></template>
            <template #no-data><div class="text-center py-6 text-medium-emphasis"><v-icon size="32" class="mb-2">mdi-package-variant-closed-remove</v-icon><p>No parts used.</p></div></template>
          </v-data-table>
        </v-card>

        <!-- Communication Thread -->
        <v-card elevation="0" border rounded="lg">
          <v-card-title class="text-subtitle-1 d-flex align-center justify-space-between">
            <span class="d-flex align-center ga-2"><v-icon color="info">mdi-comment-text-multiple-outline</v-icon>Communication Thread</span>
            <v-btn v-can="'maintenance:create'" color="info" prepend-icon="mdi-plus" size="small" @click="noteDialog = true">Add Note</v-btn>
          </v-card-title>
          <v-list lines="two">
            <v-list-item v-for="n in (wo.notes || [])" :key="n.id">
              <template #prepend>
                <v-avatar size="32" variant="tonal" :color="n.visibility === 'internal' ? 'grey' : 'info'">
                  <span class="text-caption font-weight-bold">{{ initials(n.author_name || '?') }}</span>
                </v-avatar>
              </template>
              <v-list-item-title class="font-weight-medium">{{ n.author_name }}
                <v-chip v-if="n.visibility === 'internal'" size="x-small" variant="tonal" color="grey" class="ml-2">Internal</v-chip>
                <v-chip v-else size="x-small" variant="tonal" color="info" class="ml-2">External</v-chip>
              </v-list-item-title>
              <v-list-item-subtitle class="text-wrap">{{ n.content }}</v-list-item-subtitle>
              <template #append><span class="text-caption text-medium-emphasis">{{ fmt(n.created_at) }}</span></template>
            </v-list-item>
            <v-list-item v-if="!wo.notes?.length">
              <div class="text-center py-6 text-medium-emphasis">
                <v-icon size="32" class="mb-2">mdi-comment-alert-outline</v-icon>
                <p>No notes yet.</p>
              </div>
            </v-list-item>
          </v-list>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <!-- Details Panel -->
        <v-card elevation="0" border rounded="lg" class="mb-4">
          <AppModalHeader icon="mdi-wrench">Details</AppModalHeader>
          <v-card-text>
            <div class="d-flex flex-column ga-3">
              <v-select v-model="editForm.assigned_to" :items="mechanics" item-title="full_name" item-value="id" label="Assign To" clearable density="compact" variant="outlined" />
              <v-select v-model="editForm.assignment_type" :items="['internal', 'external']" label="Assignment Type" density="compact" variant="outlined" />
              <v-select v-model="editForm.status" :items="woStatuses" label="Status" density="compact" variant="outlined" />
              <v-text-field v-model="editForm.estimated_cost" :label="`Estimated Cost (${currencySymbol})`" density="compact" variant="outlined" />
              <v-textarea v-model="editForm.internal_notes" label="Internal Notes" rows="2" density="compact" variant="outlined" />
              <v-textarea v-model="editForm.external_notes" label="External Notes" rows="2" density="compact" variant="outlined" />
              <v-btn v-can="'maintenance:update'" color="primary" prepend-icon="mdi-content-save" size="small" @click="saveDetails" :loading="saving">Save Changes</v-btn>
              <v-btn v-can="'maintenance:update'" v-if="!['completed', 'closed'].includes(wo.status)" color="success" prepend-icon="mdi-check-circle" size="small" variant="tonal" @click="complete" :loading="saving">Mark Complete</v-btn>
            </div>
          </v-card-text>
        </v-card>

        <!-- Downtime -->
        <v-card elevation="0" border rounded="lg">
          <AppModalHeader icon="mdi-timer-sand">Downtime</AppModalHeader>
          <v-card-text class="text-center">
            <p class="text-h4 font-weight-bold text-warning">{{ wo.downtime_hours ? wo.downtime_hours.toFixed(1) + 'h' : '—' }}</p>
            <p class="text-caption text-medium-emphasis mt-1">{{ wo.started_at ? 'Started ' + new Date(wo.started_at).toLocaleDateString() : 'Not started' }}</p>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Add Note Dialog -->
    <v-dialog v-model="noteDialog" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-comment-plus">Add Note</AppModalHeader>
        <v-card-text>
          <v-textarea v-model="noteForm.content" label="Note" rows="3" variant="outlined" />
          <v-select v-model="noteForm.visibility" :items="['internal', 'external']" label="Visibility" density="compact" variant="outlined" class="mt-3" />
        </v-card-text>
        <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="noteDialog = false">Cancel</v-btn><v-btn v-can="'maintenance:create'" color="primary" @click="addNote" :loading="saving">Add</v-btn></v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Add Part Dialog -->
    <v-dialog v-model="partDialog" max-width="480">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-package-plus">Add Part</AppModalHeader>
        <v-card-text>
          <v-select v-model="partForm.inventory_item" :items="parts" item-title="name" item-value="id" label="Part" variant="outlined" />
          <v-text-field v-model.number="partForm.quantity" label="Quantity" type="number" class="mt-3" variant="outlined" />
        </v-card-text>
        <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="partDialog = false">Cancel</v-btn><v-btn v-can="'maintenance:create'" color="primary" @click="addPart" :loading="saving">Add</v-btn></v-card-actions>
      </v-card>
    </v-dialog>
  </div>
  <div v-else class="text-center py-12"><v-progress-circular indeterminate /></div>
</template>

<script setup lang="ts">
const route = useRoute()
const { $api, $swal } = useNuxtApp() as any
const { currencySymbol } = useCurrency()
const saving = ref(false)
const noteDialog = ref(false)
const partDialog = ref(false)
const woStatuses = ['open', 'assigned', 'parts_ordered', 'in_progress', 'on_hold', 'completed', 'closed']
const noteForm = reactive<any>({ content: '', visibility: 'internal' })
const partForm = reactive<any>({ inventory_item: null, quantity: 1 })
const editForm = reactive<any>({ assigned_to: null, assignment_type: 'internal', status: 'open', estimated_cost: '0', internal_notes: '', external_notes: '' })

const timeHeaders = [
  { title: 'Mechanic', key: 'mechanic_name' },
  { title: 'In', key: 'clock_in' },
  { title: 'Out', key: 'clock_out' },
  { title: 'Hours', key: 'hours', width: '80px' },
]
const partHeaders = [
  { title: 'Part', key: 'item_name' },
  { title: 'SKU', key: 'item_sku', width: '110px' },
  { title: 'Qty', key: 'quantity', width: '70px' },
  { title: 'Unit', key: 'unit_cost', width: '90px' },
  { title: 'Total', key: 'total_cost', width: '90px' },
]

const { data: wo, refresh } = useAsyncData(`wo-${route.params.id}`, () => $api(`/issues/work-orders/${route.params.id}/`), { default: () => null })
const { data: mechData } = useAsyncData('wo-mechanics', () => $api('/contacts/', { query: { contact_type: 'mechanic', page_size: 1000 } }), { default: () => ({ results: [] }) })
const mechanics = computed(() => mechData.value?.results || [])
const { data: partData } = useAsyncData('wo-parts', () => $api('/inventory/items/', { query: { page_size: 1000 } }), { default: () => ({ results: [] }) })
const parts = computed(() => partData.value?.results || [])

const activeLog = computed(() => wo.value?.time_logs?.find((l: any) => !l.clock_out) || null)

watchEffect(() => {
  if (wo.value) Object.assign(editForm, { assigned_to: wo.value.assigned_to, assignment_type: wo.value.assignment_type, status: wo.value.status, estimated_cost: wo.value.estimated_cost, internal_notes: wo.value.internal_notes, external_notes: wo.value.external_notes })
})

function money(v: any) { return parseFloat(v || 0).toFixed(2) }
function fmt(v?: string) { return v ? new Date(v).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function initials(n: string) { return (n || '?').split(' ').map((w: string) => w[0]).slice(0, 2).join('').toUpperCase() }
function statusColor(s: string) { return ({ open: 'blue', assigned: 'indigo', parts_ordered: 'amber', in_progress: 'orange', on_hold: 'purple', completed: 'success', closed: 'grey' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ open: 'mdi-clipboard-outline', assigned: 'mdi-account-check-outline', parts_ordered: 'mdi-package-variant-closed', in_progress: 'mdi-wrench', on_hold: 'mdi-pause-circle', completed: 'mdi-check-circle', closed: 'mdi-lock-check-outline' } as any)[s] || 'mdi-clipboard' }
function toast(icon: string, title: string) { $swal?.fire?.({ icon, title, toast: true, timer: 1500, position: 'top-end' }) }

async function clockIn() { saving.value = true; try { await $api(`/issues/work-orders/${route.params.id}/clock-in/`, { method: 'POST', body: {} }); await refresh(); toast('success', 'Clocked in') } catch { toast('error', 'Clock-in failed') } finally { saving.value = false } }
async function clockOut() { saving.value = true; try { await $api(`/issues/work-orders/${route.params.id}/clock-out/`, { method: 'POST', body: {} }); await refresh(); toast('success', 'Clocked out') } catch { toast('error', 'Clock-out failed') } finally { saving.value = false } }
async function addNote() { saving.value = true; try { await $api(`/issues/work-orders/${route.params.id}/add-note/`, { method: 'POST', body: { ...noteForm } }); noteDialog.value = false; noteForm.content = ''; await refresh(); toast('success', 'Note added') } catch { toast('error', 'Failed to add note') } finally { saving.value = false } }
async function addPart() { saving.value = true; try { await $api(`/issues/work-orders/${route.params.id}/add-part/`, { method: 'POST', body: { ...partForm } }); partDialog.value = false; await refresh(); toast('success', 'Part added') } catch { toast('error', 'Failed to add part') } finally { saving.value = false } }
async function saveDetails() { saving.value = true; try { const payload = { ...editForm }; if (payload.estimated_cost) payload.estimated_cost = parseFloat(payload.estimated_cost); await $api(`/issues/work-orders/${route.params.id}/`, { method: 'PATCH', body: payload }); await refresh(); toast('success', 'Changes saved') } catch { toast('error', 'Save failed') } finally { saving.value = false } }
async function complete() {
  const r = await $swal?.fire?.({ icon: 'question', title: 'Mark work order complete?', text: `WO #${wo.value?.id} · ${wo.value?.issue_title}`, showCancelButton: true, confirmButtonText: 'Complete', confirmButtonColor: '#10b981' })
  if (!r?.isConfirmed) return
  saving.value = true; try { await $api(`/issues/work-orders/${route.params.id}/complete/`, { method: 'POST' }); await refresh(); toast('success', 'Work order completed') } catch { toast('error', 'Failed to complete') } finally { saving.value = false }
}
</script>

<style scoped>
.kpi-card { transition: transform .15s, box-shadow .15s; }
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.kpi-total { border-color: #10b981 !important; }
</style>
