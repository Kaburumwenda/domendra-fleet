<template>
  <v-dialog :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" max-width="480">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-star">Rate Vendor — {{ vendorName }}</AppModalHeader>
      <v-card-text>
        <p class="text-caption text-medium-emphasis mb-3">Rate the performance of this vendor for quality tracking.</p>
        <div class="rating-section">
          <div class="rating-line">
            <div class="rating-label">
              <v-icon size="18" color="amber">mdi-cash</v-icon>
              <div><span class="text-body-2 font-weight-medium">Cost</span><p class="text-caption text-medium-emphasis">Price competitiveness</p></div>
            </div>
            <v-rating v-model="form.cost_rating" half-increments hover length="5" size="x-large" color="amber" />
          </div>
          <div class="rating-line">
            <div class="rating-label">
              <v-icon size="18" color="amber">mdi-medal</v-icon>
              <div><span class="text-body-2 font-weight-medium">Quality</span><p class="text-caption text-medium-emphasis">Workmanship &amp; standards</p></div>
            </div>
            <v-rating v-model="form.quality_rating" half-increments hover length="5" size="x-large" color="amber" />
          </div>
          <div class="rating-line">
            <div class="rating-label">
              <v-icon size="18" color="amber">mdi-clock-fast</v-icon>
              <div><span class="text-body-2 font-weight-medium">Turnaround</span><p class="text-caption text-medium-emphasis">Speed of completion</p></div>
            </div>
            <v-rating v-model="form.turnaround_rating" half-increments hover length="5" size="x-large" color="amber" />
          </div>
        </div>

        <div class="overall-preview">
          <span class="text-body-2 font-weight-bold">Overall</span>
          <v-rating :model-value="overallRating" readonly half-increments size="large" color="amber" />
          <span class="text-h6 font-weight-bold text-amber">{{ overallRating.toFixed(1) }}</span>
        </div>

        <v-textarea v-model="form.notes" label="Notes" rows="3" placeholder="Add any comments about this vendor's performance..." variant="outlined" density="compact" hide-details="auto" class="mt-2" />
      </v-card-text>
      <v-card-actions class="px-4 pb-4">
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:modelValue', false)">Cancel</v-btn>
        <v-btn color="amber" prepend-icon="mdi-star-check" :loading="saving" @click="onSubmit">Submit Rating</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
const props = defineProps<{ modelValue: boolean; vendorName: string; saving: boolean }>()
const emit = defineEmits<{ 'update:modelValue': [v: boolean]; submit: [payload: any] }>()
const form = reactive<any>({ cost_rating: 0, quality_rating: 0, turnaround_rating: 0, notes: '' })
const overallRating = computed(() => round1((Number(form.cost_rating) + Number(form.quality_rating) + Number(form.turnaround_rating)) / (3 || 1)))
function round1(v: number) { return Math.round(v * 10) / 10 }

defineExpose({
  populate: (r: any) => Object.assign(form, { cost_rating: r?.cost_rating || 0, quality_rating: r?.quality_rating || 0, turnaround_rating: r?.turnaround_rating || 0, notes: r?.notes || '' }),
  reset: () => Object.assign(form, { cost_rating: 0, quality_rating: 0, turnaround_rating: 0, notes: '' }),
})

function onSubmit() {
  emit('submit', { ...form })
}
</script>

<style scoped>
.rating-section { display:flex; flex-direction:column; gap:14px; }
.rating-line { display:flex; align-items:center; justify-content:space-between; gap:12px; }
.rating-label { display:flex; align-items:flex-start; gap:8px; }
.overall-preview { display:flex; align-items:center; gap:10px; padding:12px 14px; background:#fffbeb; border:1px solid #fde68a; border-radius:10px; margin-top:14px; }
.text-amber { color:#d97706; }
</style>
