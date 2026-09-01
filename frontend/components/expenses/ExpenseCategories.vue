<template>
  <div class="d-flex flex-column ga-4">
    <div class="d-flex align-center justify-space-between ga-2">
      <h3 class="text-subtitle-1 font-weight-bold">Expense Categories</h3>
      <v-btn color="primary" prepend-icon="mdi-plus" size="small" variant="tonal" @click="openDialog()">Add Category</v-btn>
    </div>

    <v-card elevation="0" border rounded="lg">
      <v-data-table
        :headers="headers" :items="categories" :loading="pending" hover density="compact"
        :items-per-page="-1" hide-default-footer
      >
        <template #item.name="{ item }">
          <div class="d-flex align-center ga-2">
            <div class="d-flex align-center justify-center" :style="{ width: '32px', height: '32px', borderRadius: '8px', background: (item.color || '#6366f1') + '22' }">
              <v-icon :color="item.color || 'primary'" size="small">{{ item.icon || 'mdi-cash' }}</v-icon>
            </div>
            <div>
              <p class="font-weight-medium mb-0">{{ item.name }}</p>
              <p v-if="item.code" class="text-caption text-medium-emphasis mb-0">{{ item.code }}</p>
            </div>
          </div>
        </template>
        <template #item.type="{ value }"><v-chip :color="typeColor(value)" variant="flat" size="small" class="text-capitalize">{{ value }}</v-chip></template>
        <template #item.is_active="{ value }"><v-chip :color="value ? 'success' : 'grey'" variant="tonal" size="small">{{ value ? 'Active' : 'Inactive' }}</v-chip></template>
        <template #item.expense_count="{ value }">{{ value || 0 }} expenses</template>
        <template #item.actions="{ item }">
          <v-menu>
            <template #activator="{ props: p }"><v-btn icon="mdi-dots-vertical" variant="text" size="small" v-bind="p" /></template>
            <v-list density="compact">
              <v-list-item prepend-icon="mdi-pencil" @click="openDialog(item)">Edit</v-list-item>
              <v-list-item prepend-icon="mdi-delete" base-color="error" @click="removeCategory(item)">Delete</v-list-item>
            </v-list>
          </v-menu>
        </template>
      </v-data-table>
    </v-card>

    <!-- Dialog -->
    <v-dialog v-model="dialog" max-width="520" scroll-strategy="none">
      <v-card rounded="xl" class="overflow-hidden">
        <AppModalHeader icon="mdi-tag-outline">{{ editing ? 'Edit' : 'Add' }} Category</AppModalHeader>
        <v-card-text class="pt-5">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.name" label="Name *" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field v-model="form.code" label="Code (short)" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="6">
              <v-select v-model="form.type" :items="typeOptions" item-title="label" item-value="value" label="Type" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="3">
              <v-text-field v-model="form.color" label="Color" density="compact" variant="outlined" hide-details="auto" />
            </v-col>
            <v-col cols="12" md="3">
              <div class="d-flex align-center justify-center pa-2 mt-2" :style="{ background: form.color || '#6366f1', height: '40px', borderRadius: '8px' }">
                <v-icon color="white">{{ form.icon || 'mdi-cash' }}</v-icon>
              </div>
            </v-col>
            <v-col cols="12" md="6">
              <v-text-field
                :model-value="form.icon"
                label="Icon"
                density="compact" variant="outlined" hide-details="auto"
                :prepend-inner-icon="form.icon || 'mdi-cash'"
                readonly
                @click="iconPicker = !iconPicker"
              >
                <template #append-inner>
                  <v-icon size="small" @click="iconPicker = !iconPicker">{{ iconPicker ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
                </template>
              </v-text-field>
            </v-col>
            <v-col cols="12" md="6">
              <v-switch v-model="form.is_active" label="Active" color="primary" density="compact" hide-details="auto" />
            </v-col>
            <v-col cols="12" v-if="iconPicker" class="mt-n2">
              <v-card variant="outlined" rounded="lg" class="pa-2" style="max-height: 260px; overflow-y: auto">
                <v-text-field v-model="iconSearch" label="Search icons…" density="compact" variant="outlined" hide-details prepend-inner-icon="mdi-magnify" class="mb-2" />
                <div class="d-flex flex-wrap ga-1">
                  <div
                    v-for="ic in filteredIcons" :key="ic"
                    class="d-flex align-center justify-center cursor-pointer rounded-lg"
                    :style="{
                      width: '36px', height: '36px',
                      background: form.icon === ic ? (form.color || '#6366f1') + '22' : 'transparent',
                      border: form.icon === ic ? ('2px solid ' + (form.color || '#6366f1')) : '2px solid transparent',
                    }"
                    @click="form.icon = ic; iconPicker = false"
                  >
                    <v-icon :color="form.icon === ic ? (form.color || 'primary') : 'default'" size="20">{{ ic }}</v-icon>
                  </div>
                </div>
              </v-card>
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.description" label="Description" rows="2" density="compact" variant="outlined" hide-details="auto" />
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
const { fetchCategories, saveCategory, deleteCategory: apiDel } = useExpenseApi()

const headers = [
  { title: 'Category', key: 'name' },
  { title: 'Type', key: 'type', width: '140px' },
  { title: 'Expenses', key: 'expense_count', width: '140px' },
  { title: 'Active', key: 'is_active', width: '120px' },
  { title: '', key: 'actions', width: '50px', sortable: false },
]

const typeOptions = [
  { label: 'Operating', value: 'operating' },
  { label: 'Capital', value: 'capital' },
  { label: 'Cost of Goods Sold', value: 'cogs' },
  { label: 'Other', value: 'other' },
]

const { data, pending, refresh } = useAsyncData('exp-cats', () => fetchCategories().catch(() => ({ results: [] })) as Promise<any>, { default: () => ({ results: [] }) })
const categories = computed(() => data.value?.results || [])

const dialog = ref(false)
const saving = ref(false)
const editing = ref<any>(null)
const iconPicker = ref(false)
const iconSearch = ref('')
const form = reactive<any>({ name: '', code: '', type: 'operating', color: '#6366f1', icon: 'mdi-cash', is_active: true, description: '' })

const availableIcons = [
  'mdi-cash', 'mdi-cash-multiple', 'mdi-cash-register', 'mdi-currency-usd', 'mdi-currency-eur', 'mdi-currency-gbp',
  'mdi-receipt', 'mdi-receipt-text-outline', 'mdi-receipt-text', 'mdi-invoice', 'mdi-file-document-outline', 'mdi-file-invoice',
  'mdi-credit-card', 'mdi-credit-card-outline', 'mdi-bank', 'mdi-wallet', 'mdi-wallet-outline', 'mdi-hand-coin-outline',
  'mdi-car', 'mdi-car-info', 'mdi-car-cog', 'mdi-car-wrench', 'mdi-forklift', 'mdi-truck',
  'mdi-truck-outline', 'mdi-steering', 'mdi-steering-off', 'mdi-fuel', 'mdi-gas-station', 'mdi-gas-station-outline',
  'mdi-oil', 'mdi-oil-level', 'mdi-car-tire-alert', 'mdi-tire',
  'mdi-wrench', 'mdi-wrench-outline', 'mdi-tools', 'mdi-hammer-wrench', 'mdi-screwdriver', 'mdi-cog',
  'mdi-cog-outline', 'mdi-cogs', 'mdi-domain', 'mdi-office-building', 'mdi-office-building-outline', 'mdi-store',
  'mdi-shopping', 'mdi-cart-outline', 'mdi-shopping-outline', 'mdi-store-outline', 'mdi-package-variant-closed', 'mdi-package-variant',
  'mdi-phone', 'mdi-phone-outline', 'mdi-email', 'mdi-email-outline', 'mdi-laptop', 'mdi-laptop-account',
  'mdi-monitor', 'mdi-cellphone', 'mdi-wifi', 'mdi-cloud', 'mdi-cloud-outline', 'mdi-shield-car',
  'mdi-shield-car-outline', 'mdi-security', 'mdi-lock', 'mdi-lock-outline', 'mdi-calendar', 'mdi-calendar-blank',
  'mdi-calendar-alert', 'mdi-bell', 'mdi-bell-outline', 'mdi-alarm', 'mdi-clock-outline', 'mdi-timer-sand',
  'mdi-airplane', 'mdi-train', 'mdi-bus', 'mdi-bus-side', 'mdi-taxi', 'mdi-ship-wheel',
  'mdi-leaf', 'mdi-leaf-circle-outline', 'mdi-recycle', 'mdi-earth', 'mdi-thermometer', 'mdi-pillar',
  'mdi-account-cash', 'mdi-account-cash-outline', 'mdi-account-multiple', 'mdi-account-group', 'mdi-briefcase', 'mdi-briefcase-outline',
  'mdi-chart-line', 'mdi-chart-pie', 'mdi-chart-bar', 'mdi-chart-donut', 'mdi-chart-arc', 'mdi-trending-up',
  'mdi-percent', 'mdi-percent-outline', 'mdi-tag', 'mdi-tag-outline', 'mdi-label', 'mdi-label-outline',
  'mdi-package', 'mdi-dolly', 'mdi-fork-reverse-variant', 'mdi-racing-helmet',
  'mdi-parking', 'mdi-parking-lights', 'mdi-road-variant', 'mdi-road', 'mdi-map-marker', 'mdi-map-marker-distance',
  'mdi-bag-personal', 'mdi-bag-suitcase', 'mdi-bed', 'mdi-bed-outline', 'mdi-food', 'mdi-food-outline',
  'mdi-silverware-fork-knife', 'mdi-coffee', 'mdi-coffee-outline', 'mdi-cup-water', 'mdi-water',
  'mdi-lightbulb', 'mdi-lightbulb-outline', 'mdi-flash', 'mdi-flash-outline', 'mdi-fire', 'mdi-weather-windy',
  'mdi-palette', 'mdi-brush', 'mdi-brush-variant', 'mdi-pen', 'mdi-pencil', 'mdi-scissors-cutting',
  'mdi-newspaper', 'mdi-book-open', 'mdi-bookshelf', 'mdi-library', 'mdi-file-cabinet', 'mdi-archive',
  'mdi-clipboard', 'mdi-clipboard-list', 'mdi-clipboard-text', 'mdi-clipboard-check', 'mdi-note', 'mdi-note-text',
  'mdi-script', 'mdi-script-text', 'mdi-form-textbox', 'mdi-form-select', 'mdi-toll', 'mdi-sign-direction',
]

const filteredIcons = computed(() => {
  const s = iconSearch.value.toLowerCase().trim()
  if (!s) return availableIcons
  return availableIcons.filter(ic => ic.toLowerCase().includes(s))
})

function openDialog(item?: any) {
  if (item) { editing.value = item; Object.assign(form, item) }
  else { editing.value = null; Object.assign(form, { name: '', code: '', type: 'operating', color: '#6366f1', icon: 'mdi-cash', is_active: true, description: '' }) }
  dialog.value = true
}

async function save() {
  if (!form.name) { $swal?.fire?.({ icon: 'error', title: 'Name is required', toast: true, timer: 1500, position: 'top-end' }); return }
  saving.value = true
  try {
    await saveCategory({ ...form }, editing.value?.id)
    dialog.value = false
    await refresh()
    $swal?.fire?.({ icon: 'success', title: editing.value ? 'Category updated' : 'Category created', toast: true, timer: 1500, position: 'top-end' })
  } catch (e) { console.error(e); $swal?.fire?.({ icon: 'error', title: 'Save failed', toast: true, timer: 2000, position: 'top-end' }) } finally { saving.value = false }
}

async function removeCategory(c: any) {
  const r = await $swal?.fire?.({ icon: 'warning', title: 'Delete category?', text: c.name, showCancelButton: true, confirmButtonText: 'Delete', confirmButtonColor: '#dc2626' })
  if (!r?.isConfirmed) return
  await apiDel(c.id)
  await refresh()
  $swal?.fire?.({ icon: 'success', title: 'Category deleted', toast: true, timer: 1500, position: 'top-end' })
}

function typeColor(t: string) { return ({ operating: 'primary', capital: 'warning', cogs: 'info', other: 'grey' } as any)[t] || 'grey' }

defineExpose({ refresh })
</script>
