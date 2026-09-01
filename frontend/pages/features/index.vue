<template>
  <div>
    <PageHero eyebrow="Features" icon="mdi-view-grid-outline" title="Every feature you need to run your fleet" subtitle="Maintenance, inspections, fuel, inventory, reports and more — with intelligence built in." :cta="true" />
    <FeatureGrid />
    <CtaBand />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'marketing' })
useHead({ title: 'Features' })
</script>
