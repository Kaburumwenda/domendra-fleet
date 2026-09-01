<template>
  <DetailPage v-if="data" :data="data" />
  <div v-else>
    <PageHero eyebrow="404" title="Industry not found" subtitle="The industry you're looking for doesn't exist." :cta="true" />
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const slug = computed(() => route.params.slug as string)
const data = computed(() => industryPages[slug.value])
definePageMeta({ layout: 'marketing' })
useHead(() => ({ title: data.value ? data.value.title : 'Industry' }))
</script>
