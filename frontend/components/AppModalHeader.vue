<template>
  <v-card-title class="bg-primary text-white text-h6 font-weight-bold d-flex align-center ga-2">
    <v-icon v-if="icon" size="20" color="white">{{ icon }}</v-icon>
    <span><slot /></span>
  </v-card-title>
</template>

<script setup lang="ts">
defineProps<{ icon?: string }>()
</script>
