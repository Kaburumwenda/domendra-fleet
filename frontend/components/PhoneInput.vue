<template>
  <div class="d-flex ga-2 align-start" style="width: 100%;">
    <v-select
      v-model="selectedCode"
      :items="dialOptions"
      item-title="name"
      item-value="code"
      :density="density"
      :variant="variant"
      style="max-width: 120px; flex: 0 0 120px"
      hide-details
    >
      <template #selection="{ item }">
        <span class="d-flex align-center ga-1">
          <span style="font-size: 1.1em">{{ item.raw.flag }}</span>
          <span>+{{ item.raw.dial }}</span>
        </span>
      </template>
      <template #item="{ props, item }">
        <v-list-item v-bind="props" :title="`${item.raw.name} (+${item.raw.dial})`">
          <template #prepend>
            <span style="font-size: 1.2em">{{ item.raw.flag }}</span>
          </template>
        </v-list-item>
      </template>
    </v-select>
    <v-text-field
      v-model="number"
      :label="label"
      :density="density"
      :variant="variant"
      placeholder="700 000 000"
      type="tel"
      style="flex: 1"
    />
  </div>
</template>

<script setup lang="ts">
const props = withDefaults(defineProps<{
  modelValue?: string
  countryName?: string
  label?: string
  density?: any
  variant?: any
}>(), {
  modelValue: '',
  countryName: '',
  label: 'Telephone',
  density: 'comfortable',
  variant: undefined,
})

const emit = defineEmits<{ 'update:modelValue': [string] }>()

const { countries, flagEmoji } = useCountries()

const dialOptions = computed(() =>
  countries
    .filter((c) => c.dial)
    .map((c) => ({ code: c.code, dial: c.dial, name: c.name, flag: flagEmoji(c.code) }))
)

const selectedCode = ref('')
const number = ref('')

function dialOf(code: string) {
  return countries.find((c) => c.code === code)?.dial || ''
}

function parseValue(val: string) {
  const v = (val || '').trim()
  const m = v.match(/^\+(\d{1,4})\s*(.*)$/)
  if (m) {
    const matched = countries.find((c) => c.dial === m[1])
    selectedCode.value = matched?.code || ''
    number.value = m[2] || ''
  } else {
    number.value = v
    selectedCode.value = ''
  }
}

parseValue(props.modelValue)

watch(() => props.modelValue, (val) => {
  const built = buildValue()
  if (built !== (val || '').trim()) parseValue(val)
})

watch(() => props.countryName, (name) => {
  if (!name) return
  const c = countries.find((x) => x.name.toLowerCase() === name.trim().toLowerCase())
  if (c) selectedCode.value = c.code
}, { immediate: false })

function buildValue() {
  const num = (number.value || '').trim()
  const d = dialOf(selectedCode.value)
  if (d) return num ? `+${d} ${num}` : `+${d}`
  return num
}

watch([selectedCode, number], () => {
  emit('update:modelValue', buildValue())
}, { immediate: true })
</script>
