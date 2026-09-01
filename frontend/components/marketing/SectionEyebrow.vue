<template>
  <component :is="tag" class="fc-eyebrow">
    <v-icon v-if="icon" size="14">{{ icon }}</v-icon>
    {{ text }}
  </component>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ text: string; icon?: string; tag?: string }>(), { tag: 'span' })
</script>

<style scoped>
.fc-eyebrow {
  display: inline-flex; align-items: center; gap: 6px;
  font-size: 12.5px; font-weight: 700; letter-spacing: .08em; text-transform: uppercase;
  color: #4f46e5; background: #eef2ff; padding: 6px 12px; border-radius: 999px;
}
</style>
