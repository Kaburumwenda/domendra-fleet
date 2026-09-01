<template>
  <v-card class="pa-5" elevation="0" border :class="clickable ? 'cursor-pointer' : ''" :ripple="clickable">
    <div class="d-flex align-start justify-space-between mb-3">
      <div class="d-flex align-center justify-center" :style="{ width: '44px', height: '44px', borderRadius: '12px', background: bg }">
        <v-icon :color="color" :icon="icon" />
      </div>
      <v-chip v-if="trend !== null && trend !== undefined" :color="trend > 0 ? 'success' : 'error'" variant="flat">
        <v-icon :icon="trend > 0 ? 'mdi-arrow-up' : 'mdi-arrow-down'" size="x-small" start />
        {{ Math.abs(trend) }}%
      </v-chip>
    </div>
    <p class="text-h5 font-weight-bold text-high-emphasis">{{ value }}</p>
    <p class="text-body-2 text-medium-emphasis mt-1">{{ label }}</p>
    <p v-if="subtitle" class="text-caption text-medium-emphasis mt-1">{{ subtitle }}</p>
  </v-card>
</template>

<script setup lang="ts">
const props = defineProps<{
  label: string
  value: string | number
  icon: string
  iconBg?: string
  iconColor?: string
  trend?: number | null
  subtitle?: string
  clickable?: boolean
}>()

const { isDark } = useDarkMode()
const bg = computed(() => props.iconBg || (isDark.value ? 'rgba(99,102,241,0.15)' : '#eef2ff'))
const color = computed(() => props.iconColor || 'primary')
</script>
