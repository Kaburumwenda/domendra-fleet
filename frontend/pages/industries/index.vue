<template>
  <div>
    <PageHero eyebrow="Industries" icon="mdi-domain" title="Any industry, any size fleet" subtitle="DomendraFleet adapts to how your operation works — across construction, logistics, government and more." :cta="true" />
    <IndustriesGrid />
    <CtaBand />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'marketing' })
useHead({ title: 'Industries' })
</script>
