<template>
  <v-navigation-drawer :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" location="right" width="540" temporary>
    <div v-if="po" class="d-flex flex-column h-100">
      <!-- Header -->
      <div class="drawer-header">
        <div class="d-flex align-center justify-space-between">
          <v-chip :color="statusColor(po.status)" variant="flat" size="small" class="text-capitalize">
            <v-icon start size="14">{{ statusIcon(po.status) }}</v-icon>{{ po.status.replace('_',' ') }}
          </v-chip>
          <v-btn icon="mdi-close" variant="text" size="small" @click="$emit('update:modelValue', false)" />
        </div>
        <h2 class="text-h6 font-weight-bold mt-2">Purchase Order #{{ po.id }}</h2>
        <p class="text-caption d-flex align-center ga-1">
          <v-icon size="14">mdi-domain</v-icon>{{ po.vendor_name || 'Unknown vendor' }}
        </p>
      </div>
      <v-divider />

      <!-- Content -->
      <div class="flex-grow-1 overflow-y-auto pa-4">
        <!-- KPIs -->
        <v-row dense class="mb-3">
          <v-col cols="4">
            <div class="kpi"><p class="text-caption">Total Cost</p><p class="text-h6 font-weight-bold text-primary">{{ fmtCur(po.total_cost) }}</p></div>
          </v-col>
          <v-col cols="4">
            <div class="kpi"><p class="text-caption">Line Items</p><p class="text-h6 font-weight-bold">{{ po.items?.length || 0 }}</p></div>
          </v-col>
          <v-col cols="4">
            <div class="kpi"><p class="text-caption">Received</p><p class="text-h6 font-weight-bold">{{ totalReceived }} / {{ totalOrdered }}</p></div>
          </v-col>
        </v-row>

        <!-- Receive form (for submitted/partially_received) -->
        <div v-if="canReceive" class="mb-4">
          <v-card elevation="0" border class="pa-3 rounded-lg" color="blue-grey" variant="outlined">
            <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-package-down</v-icon>Receive Stock</p>
            <div v-for="line in po.items" :key="line.id" class="d-flex align-center ga-2 mb-2">
              <span class="text-body-2 text-truncate" style="flex:1">{{ line.item_name || line.inventory_item_name || 'Item' }}</span>
              <span class="text-caption text-medium-emphasis">{{ line.quantity_received }}/{{ line.quantity_ordered }}</span>
              <v-text-field
                v-model.number="receiveQty[line.id]"
                type="number" density="compact" variant="outlined" hide-details
                style="max-width:70px" placeholder="Qty"
              />
            </div>
            <v-btn color="success" block prepend-icon="mdi-check" @click="$emit('receive', receiveQty)" :loading="saving" class="mt-2">Receive Items</v-btn>
          </v-card>
        </div>

        <!-- Line items table -->
        <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-format-list-bulleted</v-icon>Line Items</p>
        <v-data-table :headers="lineHeaders" :items="po.items || []" density="compact" hide-default-footer>
          <template #item.item_name="{ value }"><span class="font-weight-medium text-body-2">{{ value }}</span></template>
          <template #item.unit_cost="{ value }">{{ fmtCur(value) }}</template>
          <template #item.line_total="{ value }">{{ fmtCur(value) }}</template>
          <template #item.quantity_received="{ item }">
            <span :class="item.quantity_received >= item.quantity_ordered ? 'text-success font-weight-bold' : 'text-medium-emphasis'">{{ item.quantity_received }}/{{ item.quantity_ordered }}</span>
          </template>
        </v-data-table>

        <!-- Notes -->
        <div v-if="po.notes" class="mt-4">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-note-text</v-icon>Notes</p>
          <p class="text-body-2 text-medium-emphasis">{{ po.notes }}</p>
        </div>

        <!-- Metadata -->
        <div class="mt-4">
          <p class="text-subtitle-2 font-weight-bold mb-2"><v-icon size="16" class="mr-1">mdi-information</v-icon>Metadata</p>
          <div class="d-flex flex-column ga-1">
            <div class="text-body-2"><v-icon size="14" class="mr-1">mdi-identifier</v-icon><span class="text-medium-emphasis">ID:</span> #{{ po.id }}</div>
            <div class="text-body-2"><v-icon size="14" class="mr-1">mdi-calendar</v-icon><span class="text-medium-emphasis">Created:</span> {{ fmtDate(po.created_at) }}</div>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <v-divider />
      <div class="pa-3">
        <div class="d-flex flex-wrap ga-2">
          <v-btn variant="outlined" prepend-icon="mdi-send" @click="$emit('submit')" v-if="po.status === 'draft'">Submit</v-btn>
          <v-btn variant="outlined" color="error" prepend-icon="mdi-cancel" @click="$emit('cancel')" v-if="po.status !== 'cancelled' && po.status !== 'received'">Cancel PO</v-btn>
          <v-spacer />
          <v-btn variant="text" color="error" prepend-icon="mdi-trash-can-outline" @click="$emit('delete', po)">Delete</v-btn>
        </div>
      </div>
    </div>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; po: any; saving: boolean }>()
defineEmits<{ 'update:modelValue': [v: boolean]; submit: []; cancel: []; delete: [po: any]; receive: [qty: any] }>()

const lineHeaders = [
  { title: 'Item', key: 'item_name' },
  { title: 'Ordered', key: 'quantity_ordered', width: '70px' },
  { title: 'Received', key: 'quantity_received', width: '90px' },
  { title: 'Cost', key: 'unit_cost', width: '80px' },
  { title: 'Total', key: 'line_total', width: '90px' },
]

const receiveQty = reactive<Record<number, number>>({})
const totalOrdered = computed(() => (props.po?.items || []).reduce((s: number, i: any) => s + (i.quantity_ordered || 0), 0))
const totalReceived = computed(() => (props.po?.items || []).reduce((s: number, i: any) => s + (i.quantity_received || 0), 0))
const canReceive = computed(() => props.po && (props.po.status === 'submitted' || props.po.status === 'partially_received'))

watch(() => props.po?.id, () => { for (const k in receiveQty) delete receiveQty[k]; if (props.po?.items) props.po.items.forEach((i: any) => receiveQty[i.id] = 0) })

function statusColor(s: string) { return ({ draft: 'grey', submitted: 'primary', partially_received: 'warning', received: 'success', cancelled: 'error' } as any)[s] || 'grey' }
function statusIcon(s: string) { return ({ draft: 'mdi-pencil-outline', submitted: 'mdi-send', partially_received: 'mdi-progress-clock', received: 'mdi-check-circle', cancelled: 'mdi-close-circle' } as any)[s] || 'mdi-circle-outline' }
const { currencySymbol } = useCurrency()
function fmtCur(v?: number) { return v != null ? `${currencySymbol.value}${parseFloat(v).toLocaleString([], { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : `${currencySymbol.value}0.00` }
function fmtDate(v?: string) { return v ? new Date(v).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
</script>

<style scoped>
.drawer-header { padding: 16px 16px 8px; }
.kpi { text-align: center; }
.kpi p { margin: 0; }
</style>
