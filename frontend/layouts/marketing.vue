<template>
  <v-app>
    <MarketingNav />
    <v-main>
      <slot />
    </v-main>
    <MarketingFooter />
  </v-app>
</template>

<script setup lang="ts">
useHead({
  titleTemplate: (t) => t ? `${t} · DomendraFleet` : 'DomendraFleet · Premium Fleet Management Software',
})
</script>

<style scoped>
:deep(.v-main) { background: #fff !important; }
</style>
