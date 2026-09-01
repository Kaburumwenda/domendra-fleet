<template>
  <DetailPage v-if="data" :data="data" />
  <div v-else class="fc-notfound">
    <PageHero eyebrow="404" title="Feature not found" subtitle="The feature you're looking for doesn't exist." :cta="true" />
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const slug = computed(() => route.params.slug as string)
const data = computed(() => featurePages[slug.value])
definePageMeta({ layout: 'marketing' })
useHead(() => ({ title: data.value ? data.value.title : 'Feature' }))
</script>

<style scoped>
.fc-notfound { padding-bottom: 80px; }
</style>
