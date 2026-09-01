<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="480">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-account-plus-outline">Assign Vehicle & Driver</AppModalHeader>
      <v-card-text>
        <p class="text-caption text-medium-emphasis mb-3">Assign resources to <b>{{ job?.title }}</b>.</p>
        <v-row dense>
          <v-col cols="12">
            <v-select v-model="assign.vehicle" :items="vehicleOptions" :item-title="(v:any)=>v.display_name||v.id" item-value="id" label="Vehicle" variant="outlined" density="compact" hide-details="auto" clearable return-object />
          </v-col>
          <v-col cols="12">
            <v-select v-model="assign.driver" :items="driverOptions" :item-title="(d:any)=>d.full_name||`#${d.id}`" item-value="id" label="Driver" variant="outlined" density="compact" hide-details="auto" clearable return-object />
          </v-col>
          <v-col cols="12">
            <v-checkbox v-model="createAssignment" label="Also create a Vehicle Assignment record (audit trail)" density="compact" hide-details="auto" />
          </v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="primary" prepend-icon="mdi-send" :loading="saving" @click="onAssign">Assign</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; job: any; vehicleOptions: any[]; driverOptions: any[]; saving: boolean }>()
const emit = defineEmits<{
  'update:modelValue': [v: boolean]
  confirm: [jobId: number, vehicleId: number | null, driverId: number | null, createAssignment: boolean]
}>()
const createAssignment = ref(true)
const assign = reactive<any>({ vehicle: null, driver: null })

watch(() => props.job, (j) => {
  if (j) { assign.vehicle = j.vehicle || null; assign.driver = j.driver || null }
}, { immediate: true })

function onAssign() {
  const vid = assign.vehicle?.id ?? (assign.vehicle ?? null)
  const did = assign.driver?.id ?? (assign.driver ?? null)
  emit('confirm', props.job.id, vid, did, createAssignment.value)
}
</script>
