<template>
  <v-app>
    <v-main>
      <div class="d-flex align-center justify-center text-center pa-4" style="min-height: 100vh">
        <div style="max-width: 448px">
          <div class="d-inline-flex align-center justify-center mb-6" style="width: 80px; height: 80px; border-radius: 16px; background: #6366f1">
            <v-icon color="white" size="x-large">mdi-alert</v-icon>
          </div>
          <h1 class="text-h2 font-weight-bold mb-2" style="color: #1e293b">{{ error?.statusCode || 500 }}</h1>
          <p class="text-body-1 text-medium-emphasis mb-6">{{ error?.message || 'An unexpected error occurred' }}</p>
          <v-btn color="primary" prepend-icon="mdi-home" @click="handleError">Back to Dashboard</v-btn>
        </div>
      </div>
    </v-main>
  </v-app>
</template>

<script setup lang="ts">
const props = defineProps<{ error: any }>()

function handleError() {
  clearError({ redirect: '/app' })
}
</script>
