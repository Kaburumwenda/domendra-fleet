<template>
  <div>
    <PageHero :eyebrow="slug === 'privacy' ? 'Privacy' : 'Terms'" :icon="slug === 'privacy' ? 'mdi-shield-lock-outline' : 'mdi-file-document-outline'" :title="slug === 'privacy' ? 'Privacy Policy' : 'Terms of Service'" subtitle="Last updated: January 2026" :cta="false" />
    <section class="fc-legal">
      <div class="fc-legal__inner">
        <p v-for="(p, i) in content" :key="i">{{ p }}</p>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'marketing' })
const route = useRoute()
const slug = computed(() => route.params.slug as string)
useHead(() => ({ title: slug.value === 'privacy' ? 'Privacy Policy' : 'Terms of Service' }))
const content = [
  'This is a standard legal document placeholder for DomendraFleet. In a production deployment this content would be replaced with your organization\'s actual privacy policy or terms of service, reviewed by legal counsel.',
  'DomendraFleet is committed to protecting your data. We use schema-based multi-tenant isolation, JWT authentication, full audit logging, and TLS encryption in transit to keep your fleet data secure.',
  'By using DomendraFleet you agree to our acceptable use policy, which prohibits unauthorized access, abuse of the API, and sharing of credentials. API overage is billed transparently at the published rate.',
  'For questions about this document, contact domendrafleet@tiktek-ex.com.',
]
</script>

<style scoped>
.fc-legal { max-width: 760px; margin: 0 auto; padding: 0 24px 80px; }
.fc-legal__inner { display: flex; flex-direction: column; gap: 16px; }
.fc-legal__inner p { color: #64748b; line-height: 1.7; font-size: 15.5px; }
</style>
