<template>
  <v-app>
    <AppSidebar :collapsed="collapsed" />
    <AppHeader :collapsed="collapsed" @toggle="collapsed = !collapsed" />
    <v-main>
      <v-container fluid class="pa-4 pa-md-6">
        <slot />
      </v-container>
    </v-main>
  </v-app>
</template>

<script setup lang="ts">
const collapsed = ref(false)
const { load: loadCurrency } = useCurrency()
onMounted(() => { loadCurrency() })
</script>
