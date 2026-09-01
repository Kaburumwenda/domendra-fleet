<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between ga-2">
      <h3 class="text-subtitle-1 font-weight-bold">Recurring Expenses</h3>
      <div class="d-flex align-center ga-2">
        <v-btn variant="outlined" size="small" prepend-icon="mdi-refresh" :loading="materializing" @click="materializeNow">Run Now</v-btn>
        <v-btn color="primary" size="small" prepend-icon="mdi-plus" variant="tonal" @click="openDialog()">Add Rule</v-btn>
      </div>
    </div>

    <v-alert type="info" variant="tonal" border density="comfortable" class="text-body-2">
      <template #prepend><v-icon>mdi-information-outline</v-icon></template>
      Recurring rules generate <strong>Draft</strong> expenses automatically on their scheduled date. A daily background job materializes any due rules.
      If auto-approve is enabled, generated expenses are created directly as <strong>Paid</strong>.
    </v-alert>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers" :items="rules" :loading="pending" hover density="compact"
        :items-per-page="-1" hide-default-footer
      >
        <template #item.title="{ item }">
          <div>
            <p class="font-weight-medium mb-0">{{ item.title }}</p>
            <p v-if="item.description" class="text-caption text-medium-emphasis mb-0">{{ item.description }}</p>
          </div>
        </template>
        <template #item.frequency="{ item }">
          <v-chip size="small" color="primary" variant="tonal" class="text-capitalize">{{ item.frequency_display }}</v-chip>
        </template>
        <template #item.amount="{ value }"><span class="font-weight-medium">{{ currencySymbol }}{{ money(value) }}</span></template>
        <template #item.next_date="{ value }">
          <v-chip :color="dueColor(value)" variant="tonal" size="small">{{ value }}</v-chip>
        </template>
        <template #item.is_active="{ value }"><v-chip :color="value ? 'success' : 'grey'" variant="tonal" size="small">{{ value ? 'Active' : 'Paused' }}</v-chip></template>
        <template #item.auto_approve="{ value }"><v-icon :color="value ? 'success' : 'grey'">{{ value ? 'mdi-check-circle' : 'mdi-circle-outline' }}</v-icon></template>
        <template #item.actions="{ item }">
          <v-menu>
            <template #activator="{ props: p }"><v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" /></template>
            <v-list density="compact">
              <v-list-item prepend-icon="mdi-pencil" @click="openDialog(item)">Edit</v-list-item>
              <v-list-item prepend-icon="mdi-delete" base-color="error" @click="removeRule(item)">Delete</v-list-item>
            </v-list>
          </v-menu>
        </template>
      </v-data-table>
    </v-card>

    <!-- Dialog -->
    <v-dialog v-model="dialog" max-width="640" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-calendar-sync">Recurring Expense Rule</AppModalHeader>
        <v-card-text class="pt-5" style="max-height: 70vh; overflow-y: auto">
          <v-row dense>
            <v-col cols="12">
              <v-text-field v-model="form.title" label="Title *" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.description" label="Description" rows="2" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.category" :items="categoryOptions" item-title="name" item-value="id" label="Category" density="compact" variant="outlined" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.vendor_name" label="Vendor name" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="form.amount" label="Amount *" type="number" min="0" step="0.01" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="form.tax_rate" label="Tax Rate" type="number" step="0.0001"density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="form.payment_method" :items="paymentMethods" item-title="label" item-value="value" label="Payment Method" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle" density="compact" variant="outlined" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.contact" :items="contactOptions" item-title="full_name" item-value="id" label="Contact" density="compact" variant="outlined" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="4">
              <v-select v-model="form.frequency" :items="frequencyOptions" item-title="label" item-value="value" label="Frequency *" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="form.interval" label="Interval (every N)" type="number" min="1" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model.number="form.day_of_month" label="Day of Month (1-31)" type="number" min="1" max="31" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model="form.start_date" type="date" label="Start Date *" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model="form.end_date" type="date" label="End Date (optional)" density="compact" variant="outlined" hide-details="auto" clearable />
            </v-col>
            <v-col cols="12" md="4" v-if="!editing">
              <v-text-field v-model="form.next_date" type="date" label="Next Date (auto)" density="compact" variant="outlined" hide-details="auto" readonly />
            </v-col>
            <v-col cols="12" md="6">
              <v-switch v-model="form.is_active" label="Active" color="primary" density="compact" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-switch v-model="form.auto_approve" label="Auto-approve generated expenses" color="success" density="compact" hide-details="auto" />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialog = false">Cancel</v-btn>
          <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">{{ editing ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $swal } = useNuxtApp()
const { fetchRecurring, saveRecurring, deleteRecurring: apiDel, materializeRecurring } = useExpenseApi()

const props = defineProps<{
  currencySymbol: string
  categoryOptions: any[]
  vehicleOptions: any[]
  contactOptions: any[]
}>()

const headers = [
  { title: 'Title', key: 'title' },
  { title: 'Amount', key: 'amount', width: '120px' },
  { title: 'Schedule', key: 'frequency', width: '120px' },
  { title: 'Next Date', key: 'next_date', width: '130px' },
  { title: 'Auto-Approve', key: 'auto_approve', width: '110px', sortable: false },
  { title: 'Status', key: 'is_active', width: '110px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

const frequencyOptions = [
  { label: 'Daily', value: 'daily' }, { label: 'Weekly', value: 'weekly' },
  { label: 'Monthly', value: 'monthly' }, { label: 'Quarterly', value: 'quarterly' },
  { label: 'Yearly', value: 'yearly' },
]
const paymentMethods = [
  { label: 'Cash', value: 'cash' }, { label: 'Card', value: 'card' }, { label: 'Bank Transfer', value: 'bank' },
  { label: 'Mobile Money', value: 'mobile' }, { label: 'Check', value: 'check' }, { label: 'Other', value: 'other' },
]

const { data, pending, refresh } = useAsyncData('exp-recurring', () => fetchRecurring().catch(() => ({ results: [] })) as Promise<any>, { default: () => ({ results: [] }) })
const rules = computed(() => data.value?.results || [])

const dialog = ref(false)
const saving = ref(false)
const editing = ref<any>(null)
const materializing = ref(false)
const defaultForm = () => ({
  title: '', description: '', category: null, vendor_name: '',
  amount: 0, tax_rate: 0, payment_method: 'bank',
  vehicle: null, contact: null,
  frequency: 'monthly', interval: 1, day_of_month: 1,
  start_date: new Date().toISOString().slice(0, 10),
  end_date: '', next_date: new Date().toISOString().slice(0, 10),
  is_active: true, auto_approve: false,
})
const form = reactive<any>(defaultForm())

function openDialog(item?: any) {
  if (item) { editing.value = item; Object.assign(form, item, { end_date: item.end_date || '' }) }
  else { editing.value = null; Object.assign(form, defaultForm()) }
  dialog.value = true
}

async function save() {
  if (!form.title || !form.amount || !form.start_date || !form.frequency) {
    $swal?.fire?.({ icon: 'error', title: 'Title, amount, frequency & start date required', toast: true, timer: 2000, position: 'top-end' }); return
  }
  saving.value = true
  try {
    await saveRecurring({ ...form }, editing.value?.id)
    dialog.value = false
    await refresh()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Rule updated' : 'Rule created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function removeRule(r: any) {
  const res = await $swal?.fire?.({ icon: 'warning', title: 'Delete recurring rule?', text: r.title, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!res?.isConfirmed) return
  await apiDel(r.id)
  await refresh()
  $swal?.fire?.({ icon: 'success', title: 'Rule deleted', toast: true, timer: 1500, position: 'top-end' })
}

async function materializeNow() {
  materializing.value = true
  try {
    const res: any = await materializeRecurring()
    await refresh()
    $swal?.fire?.({ icon: 'success', title: res?.detail || 'Materialized recurring expenses', toast: true, timer: 2000, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Materialize failed', toast: true, timer: 2000, position: 'top-end' }) } finally { materializing.value = false }
}

function money(v: any) { return Number(v || 0).toFixed(2) }
function dueColor(d: string) {
  if (!d) return 'grey'
  const date = new Date(d)
  const today = new Date(); today.setHours(0, 0, 0, 0)
  const days = Math.round((date.getTime() - today.getTime()) / 86400000)
  if (days <= 0) return 'error'
  if (days <= 3) return 'warning'
  return 'success'
}

defineExpose({ refresh })
</script>
