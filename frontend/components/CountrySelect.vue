<template>
  <v-combobox
    :model-value="modelValue"
    :items="countries"
    item-title="name"
    item-value="name"
    :label="label"
    :density="density"
    :variant="variant"
    :clearable="clearable"
    :rules="rules"
    :hide-details="hideDetails"
    autocomplete="off"
    @update:model-value="onChange"
  >
    <template #item="{ props, item }">
      <v-list-item v-bind="props" :title="undefined">
        <div class="d-flex align-center ga-5">
          <span style="font-size: 1.2em">{{ flagEmoji(item.raw.code) }}</span>
          <span>{{ item.raw.name }}</span>
        </div>
      </v-list-item>
    </template>
    <template #selection="{ item }">
      <div class="d-flex align-center ga-5">
        <span style="font-size: 1.2em">{{ flagEmoji(item.raw?.code || codeFor(item.raw)) }}</span>
        <span>{{ typeof item.raw === 'string' ? item.raw : item.raw.name }}</span>
      </div>
    </template>
  </v-combobox>
</template>

<script setup lang="ts">
const props = withDefaults(defineProps<{
  modelValue: string
  label?: string
  density?: any
  variant?: any
  clearable?: boolean
  rules?: any[]
  hideDetails?: any
}>(), {
  label: 'Country',
  density: 'comfortable',
  variant: undefined,
  clearable: false,
  rules: () => [],
  hideDetails: 'auto',
})

const emit = defineEmits<{ 'update:modelValue': [string]; 'update:code': [string] }>()

const { countries, flagEmoji, findByName } = useCountries()

function codeFor(raw: any) {
  const name = typeof raw === 'string' ? raw : raw?.name
  return findByName(name)?.code || ''
}

function onChange(val: any) {
  const name = typeof val === 'string' ? val : (val?.name ?? '')
  emit('update:modelValue', name || '')
  emit('update:code', findByName(name)?.code || '')
}
</script>
