<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="640">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-paperclip">{{ editing ? 'Edit Document' : 'Upload Document' }}</AppModalHeader>
      <v-card-text class="pt-2">
        <v-row dense>
          <v-col cols="12">
            <v-select
              v-model="form.lessor"
              :items="lessorItems"
              item-title="display_name"
              item-value="id"
              label="Lessor"
              density="compact"
              :rules="[v => !!v || 'Required']"
            />
          </v-col>
          <v-col cols="12" md="6">
            <v-select v-model="form.document_type" :items="typeOptions" label="Document Type" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.name" label="Document Name" density="compact" />
          </v-col>
          <v-col cols="12">
            <v-textarea v-model="form.description" label="Description" rows="2" density="compact" />
          </v-col>
          <v-col cols="12" md="6">
            <v-text-field v-model="form.expires_at" label="Expires At" type="date" density="compact" />
          </v-col>
          <v-col cols="12">
            <FileDropZone
              v-model="form.file"
              label="Upload document file (PDF, images, etc.)"
              accept=".pdf,.png,.jpg,.jpeg,.doc,.docx"
            />
          </v-col>
          <v-col cols="12">
            <v-text-field v-model="form.file_url" label="Or paste external URL" density="compact" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">{{ editing ? 'Update' : 'Upload' }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; document?: any | null; lessors: any[] }>()
const emit = defineEmits(['update:modelValue', 'saved'])

const { $api } = useNuxtApp()
const saving = ref(false)
const editing = computed(() => !!props.document?.id)
const lessorItems = computed(() => props.lessors || [])

const typeOptions = [
  { title: 'Contract', value: 'contract' },
  { title: 'Insurance', value: 'insurance' },
  { title: 'Registration', value: 'registration' },
  { title: 'License', value: 'license' },
  { title: 'Tax Document', value: 'tax' },
  { title: 'Bank Document', value: 'bank' },
  { title: 'Other', value: 'other' },
]

const defaultForm = () => ({
  lessor: null as number | null,
  document_type: 'other',
  name: '',
  description: '',
  expires_at: '',
  file: null as File | null,
  file_url: '',
})

const form = reactive<any>(defaultForm())

watch(() => props.modelValue, (v) => {
  if (v) {
    Object.assign(form, defaultForm())
    if (props.document?.id) {
      Object.assign(form, {
        lessor: props.document.lessor,
        document_type: props.document.document_type,
        name: props.document.name,
        description: props.document.description,
        expires_at: props.document.expires_at || '',
        file_url: props.document.file_url || '',
      })
    }
  }
})

async function save() {
  saving.value = true
  try {
    const fd = new FormData()
    fd.append('lessor', String(form.lessor))
    fd.append('document_type', form.document_type)
    fd.append('name', form.name)
    fd.append('description', form.description)
    if (form.expires_at) fd.append('expires_at', form.expires_at)
    if (form.file_url) fd.append('file_url', form.file_url)
    if (form.file) fd.append('file', form.file)
    if (props.document?.id) {
      await $api(`/lessors/documents/${props.document.id}/`, { method: 'PATCH', body: fd })
    } else {
      await $api('/lessors/documents/', { method: 'POST', body: fd })
    }
    emit('update:modelValue', false)
    emit('saved')
  } catch (e: any) {
    console.error('Save document error:', e?.data)
    const { $swal } = useNuxtApp() as any
    $swal?.fire({ icon: 'error', title: 'Save Failed', text: e?.data?.detail || 'Check required fields.' })
  } finally {
    saving.value = false
  }
}
</script>
