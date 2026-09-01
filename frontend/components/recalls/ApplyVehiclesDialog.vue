<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="520">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-link-plus">Apply Recall to Vehicles</AppModalHeader>
      <v-card-text>
        <div class="d-flex align-center ga-2 mb-3">
          <p class="text-body-2 text-medium-emphasis flex-grow-1">Select vehicles affected by this recall.</p>
        </div>
        <div v-if="recall" class="d-flex align-center ga-2 mb-3 px-3 py-2 rounded" style="background: #f8fafc">
          <v-icon size="18" color="error">mdi-car-info</v-icon>
          <span class="text-body-2 font-weight-medium">{{ recall.title }}</span>
          <v-chip v-if="recall.is_critical" color="error" variant="flat" size="x-small">Critical</v-chip>
        </div>
        <v-autocomplete
          v-model="selected"
          :items="vehicleOptions"
          item-title="display_name"
          item-value="id"
          label="Vehicles"
          multiple
          chips
          closable-chips
          density="compact"
          :loading="loading"
          placeholder="Search and select vehicles…"
        />
      </v-card-text>
      <v-divider />
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-link-plus" @click="onApply" :loading="saving" :disabled="!selected.length">Apply</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; recall: any; vehicleOptions: any[]; saving: boolean; loading?: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; apply: [payload: { recall: any; vehicle_ids: number[] }] }>()

const selected = ref<number[]>([])

watch(() => props.modelValue, (v) => {
  if (v) selected.value = []
})

function onApply() {
  emit('apply', { recall: props.recall, vehicle_ids: selected.value })
}
</script>
