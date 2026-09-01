<template>
  <v-navigation-drawer v-model="open" location="right" temporary width="460" class="expense-drawer">
    <template v-if="exp">
      <!-- Header -->
      <div class="px-5 py-4 d-flex align-center justify-space-between" style="background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: #fff">
        <div>
          <p class="text-caption opacity-80 mb-0">{{ exp.expense_number }}</p>
          <h3 class="text-h6 font-weight-bold mb-0">{{ exp.title }}</h3>
        </div>
        <v-btn icon="mdi-close" variant="text" size="small" color="white" @click="open = false" />
      </div>

      <div class="pa-5 d-flex flex-column ga-4" style="overflow-y: auto; height: calc(100% - 160px)">
        <!-- Key facts -->
        <v-card elevation="0" border class="pa-4">
          <v-row dense>
            <v-col cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Amount</p>
              <p class="text-h6 font-weight-bold mb-0">{{ exp.currency }} {{ money(exp.amount) }}</p>
            </v-col>
            <v-col cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Tax</p>
              <p class="text-subtitle-1 font-weight-bold mb-0">{{ currencySymbol }}{{ money(exp.tax_amount) }}</p>
            </v-col>
            <v-col cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Total</p>
              <p class="text-subtitle-1 font-weight-bold mb-0">{{ currencySymbol }}{{ money(exp.total_amount) }}</p>
            </v-col>
            <v-col cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Date</p>
              <p class="text-body-2 font-weight-medium mb-0">{{ fmtDate(exp.expense_date) }}</p>
            </v-col>
            <v-col cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Status</p>
              <v-chip :color="statusColor(exp.status)" variant="flat" size="small" class="text-capitalize">{{ exp.status }}</v-chip>
            </v-col>
            <v-col cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Payment Method</p>
              <p class="text-body-2 font-weight-medium mb-0 text-capitalize">{{ exp.payment_method_display }}</p>
            </v-col>
            <v-col v-if="exp.vendor_name" cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Vendor</p>
              <p class="text-body-2 font-weight-medium mb-0">{{ exp.vendor_name }}</p>
            </v-col>
            <v-col v-if="exp.vehicle_name" cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Vehicle</p>
              <p class="text-body-2 font-weight-medium mb-0">{{ exp.vehicle_name }}</p>
            </v-col>
            <v-col v-if="exp.contact_name" cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Contact</p>
              <p class="text-body-2 font-weight-medium mb-0">{{ exp.contact_name }}</p>
            </v-col>
            <v-col v-if="exp.category_name" cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Category</p>
              <v-chip :color="chipColor(exp)" variant="tonal" size="small" class="text-capitalize">
                <v-icon start size="12">{{ exp.category_icon || 'mdi-cash' }}</v-icon>{{ exp.category_name }}
              </v-chip>
            </v-col>
            <v-col v-if="exp.payment_reference" cols="6">
              <p class="text-caption text-medium-emphasis mb-0">Reference</p>
              <p class="text-body-2 font-weight-medium mb-0">{{ exp.payment_reference }}</p>
            </v-col>
          </v-row>
        </v-card>

        <!-- Description & notes -->
        <v-card v-if="exp.description || exp.notes" elevation="0" border class="pa-4">
          <p v-if="exp.description" class="text-body-2 mb-3">{{ exp.description }}</p>
          <div v-if="exp.notes">
            <p class="text-caption text-medium-emphasis">Notes</p>
            <p class="text-body-2">{{ exp.notes }}</p>
          </div>
          <div v-if="exp.tags" class="d-flex flex-wrap ga-1 mt-2">
            <v-chip v-for="tag in exp.tags.split(',').filter(Boolean)" :key="tag" size="x-small" variant="outlined">{{ tag.trim() }}</v-chip>
          </div>
        </v-card>

        <v-alert v-if="exp.status === 'rejected' && exp.rejection_reason" type="error" variant="tonal" density="comfortable" class="text-body-2">
          <template #prepend><v-icon>mdi-alert</v-icon></template>
          <strong>Rejection reason:</strong> {{ exp.rejection_reason }}
        </v-alert>

        <!-- Approvals / audit -->
        <v-card elevation="0" border class="pa-4">
          <h4 class="text-subtitle-2 font-weight-medium mb-2 d-flex align-center ga-2"><v-icon size="small" color="primary">mdi-account-clock-outline</v-icon>Audit Trail</h4>
          <v-timeline side="end" density="compact">
            <v-timeline-item v-if="exp.created_by_name" dot-color="primary" size="small">
              <div class="text-caption"><strong>{{ exp.created_by_name }}</strong> created</div>
              <p class="text-caption text-medium-emphasis">{{ fmtDateTime(exp.created_at) }}</p>
            </v-timeline-item>
            <v-timeline-item v-if="exp.submitted_by_name" dot-color="warning" size="small">
              <div class="text-caption"><strong>{{ exp.submitted_by_name }}</strong> submitted</div>
              <p class="text-caption text-medium-emphasis">{{ fmtDateTime(exp.submitted_at) }}</p>
            </v-timeline-item>
            <v-timeline-item v-if="approvedNotRejected" dot-color="success" size="small">
              <div class="text-caption"><strong>{{ exp.approved_by_name }}</strong> {{ approvedActionLabel }}</div>
              <p class="text-caption text-medium-emphasis">{{ fmtDateTime(exp.approved_at) }}</p>
            </v-timeline-item>
            <v-timeline-item v-if="exp.paid_at" dot-color="success" size="small">
              <div class="text-caption">Marked paid</div>
              <p class="text-caption text-medium-emphasis">{{ fmtDateTime(exp.paid_at) }}</p>
            </v-timeline-item>
          </v-timeline>
        </v-card>

        <!-- Attachments -->
        <v-card elevation="0" border class="pa-4">
          <h4 class="text-subtitle-2 font-weight-medium mb-2 d-flex align-center ga-2"><v-icon size="small" color="primary">mdi-paperclip</v-icon>Attachments</h4>
          <v-list density="compact" lines="one" class="pa-0">
            <v-list-item v-for="att in (exp.attachments || [])" :key="att.id" :href="att.file_url" target="_blank">
              <template #prepend><v-icon color="primary">mdi-file-outline</v-icon></template>
              <v-list-item-title class="text-body-2">{{ att.filename }}</v-list-item-title>
              <v-list-item-subtitle>{{ humanSize(att.file_size) }}</v-list-item-subtitle>
              <template #append>
                <v-btn icon="mdi-delete-outline" variant="text" size="x-small" color="error" @click.prevent="$emit('remove-attachment', att)" />
              </template>
            </v-list-item>
            <div v-if="!(exp.attachments || []).length" class="text-center py-4 text-medium-emphasis">
              <p class="text-caption">No attachments.</p>
            </div>
          </v-list>
          <v-file-input v-model="pendingFiles" multiple chips show-size prepend-icon="mdi-upload" label="Add attachments" density="compact" variant="outlined" accept="image/*,.pdf" class="mt-2" hide-details="auto" />
          <v-btn v-if="pendingFiles && pendingFiles.length" block color="primary" variant="tonal" size="small" class="mt-2" prepend-icon="mdi-cloud-upload" @click="uploadPending">Upload {{ pendingFiles.length }} file(s)</v-btn>
        </v-card>

        <!-- Comments -->
        <v-card elevation="0" border class="pa-4">
          <h4 class="text-subtitle-2 font-weight-medium mb-2 d-flex align-center ga-2"><v-icon size="small" color="primary">mdi-comment-text-outline</v-icon>Comments</h4>
          <v-timeline side="end" density="compact">
            <v-timeline-item v-for="c in (exp.comments || [])" :key="c.id" dot-color="indigo" size="small">
              <div class="d-flex align-center ga-2 mb-1">
                <v-avatar size="24" color="indigo" variant="tonal"><span class="text-caption font-weight-bold">{{ c.author_initials }}</span></v-avatar>
                <strong class="text-body-2">{{ c.author_name }}</strong>
                <span class="text-caption text-medium-emphasis">{{ fmtDateTime(c.created_at) }}</span>
              </div>
              <p class="text-body-2 mb-0">{{ c.body }}</p>
            </v-timeline-item>
          </v-timeline>
          <div v-if="!(exp.comments || []).length" class="text-center py-3 text-medium-emphasis"><p class="text-caption mb-0">No comments yet.</p></div>
          <v-textarea v-model="commentBody" label="Add a comment…" rows="2" class="mt-3" density="compact" variant="outlined" hide-details="auto" />
          <v-btn block color="primary" variant="tonal" size="small" prepend-icon="mdi-send" class="mt-2" @click="postComment">Post Comment</v-btn>
        </v-card>
      </div>

      <!-- Bottom action bar -->
      <div class="pa-4 border-t d-flex align-center ga-2" style="background: rgb(var(--v-theme-surface))">
        <v-btn v-if="exp.status === 'draft'" color="primary" variant="flat" prepend-icon="mdi-send-outline" @click="$emit('submit', exp)">Submit</v-btn>
        <v-btn v-if="exp.status === 'submitted'" color="success" variant="flat" prepend-icon="mdi-check" @click="$emit('approve', exp)">Approve</v-btn>
        <v-btn v-if="exp.status === 'submitted'" color="error" variant="tonal" prepend-icon="mdi-close" @click="rejectOpen = true">Reject</v-btn>
        <v-btn v-if="exp.status === 'submitted'" color="primary" variant="tonal" prepend-icon="mdi-cash-check" @click="$emit('mark-paid', exp)">Mark Paid</v-btn>
        <v-spacer />
        <v-btn icon="mdi-pencil" variant="text" size="small" @click="$emit('edit', exp)" />
        <v-btn icon="mdi-delete" variant="text" size="small" color="error" @click="$emit('delete', exp)" />
      </div>
    </template>

    <!-- Reject dialog -->
    <v-dialog v-model="rejectOpen" max-width="480" scroll-strategy="none">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-close-circle" color="error">Reject Expense</AppModalHeader>
        <v-card-text class="pt-5">
          <v-textarea v-model="rejectReason" label="Rejection reason" rows="3" density="compact" variant="outlined" hide-details="auto" />
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="rejectOpen = false">Cancel</v-btn>
          <v-btn color="error" variant="flat" @click="confirmReject">Reject Expense</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-navigation-drawer>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; exp: any; currencySymbol: string }>()
const emit = defineEmits<{
  'update:modelValue': [val: boolean]
  edit: [expense: any]
  delete: [expense: any]
  submit: [expense: any]
  approve: [expense: any]
  reject: [expense: any, reason: string]
  'mark-paid': [expense: any]
  'remove-attachment': [att: any]
  'add-comment': [expense: any, body: string]
  'upload-attachments': [expense: any, files: File[]]
}>()

const open = computed({ get: () => props.modelValue, set: (v) => emit('update:modelValue', v) })
const pendingFiles = ref<File[]>([])
const commentBody = ref('')
const rejectOpen = ref(false)
const rejectReason = ref('')

// Avoid `!==` in v-if template binding (Vue SFC parses `>` as tag close)
const approvedNotRejected = computed(() => !!(props.exp?.approved_by_name && props.exp.status !== 'rejected'))
const approvedActionLabel = computed(() => (props.exp?.status === 'rejected' ? 'rejected' : 'approved'))

watch(() => props.exp?.id, () => {
  pendingFiles.value = []
  commentBody.value = ''
  rejectReason.value = ''
})

function uploadPending() {
  if (!pendingFiles.value?.length) return
  emit('upload-attachments', props.exp, pendingFiles.value)
  pendingFiles.value = []
}

function postComment() {
  if (!commentBody.value.trim()) return
  emit('add-comment', props.exp, commentBody.value.trim())
  commentBody.value = ''
}

function confirmReject() {
  emit('reject', props.exp, rejectReason.value || 'Rejected')
  rejectOpen.value = false
  rejectReason.value = ''
}

function money(v: any) { return Number(v || 0).toFixed(2) }
function fmtDate(d?: string) { return d ? new Date(d).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' }) : '—' }
function fmtDateTime(d?: string) { return d ? new Date(d).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—' }
function humanSize(bytes: number) { if (!bytes) return ''; if (bytes < 1024) return bytes + ' B'; if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'; return (bytes / 1024 / 1024).toFixed(1) + ' MB' }
function statusColor(s: string) { return ({ draft: 'grey', submitted: 'warning', approved: 'info', rejected: 'error', paid: 'success' } as any)[s] || 'grey' }
function chipColor(e: any) { return e?.category_color || 'primary' }
</script>
