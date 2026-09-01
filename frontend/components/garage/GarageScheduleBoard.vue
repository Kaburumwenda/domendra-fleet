<template>
  <div>
    <v-row dense>
      <v-col v-for="bay in bayColumns" :key="bay.key" cols="12" md="3">
        <div class="kanban-col" :style="{ borderTopColor: bay.color }">
          <div class="d-flex align-center ga-2 mb-3 px-1">
            <v-icon :color="bay.color" size="20">{{ bay.icon }}</v-icon>
            <span class="text-subtitle-2 font-weight-bold">{{ bay.title }}</span>
            <v-chip size="small" variant="tonal" :color="bay.color" class="ml-auto">{{ bay.items.length }}</v-chip>
          </div>
          <div class="kanban-list">
            <v-card
              v-for="b in bay.items" :key="b.id"
              elevation="0" border rounded="lg" class="kanban-card mb-2 cursor-pointer"
              :class="'kanban-card-' + bay.key"
              @click="$emit('openBay', b)"
            >
              <div class="pa-3">
                <div class="d-flex align-start ga-2 mb-1">
                  <v-icon :color="bayTypeColor(b.bay_type)" size="18" class="mt-0">{{ bayTypeIcon(b.bay_type) }}</v-icon>
                  <span class="text-body-2 font-weight-bold flex-grow-1 text-truncate">{{ b.name }}</span>
                  <v-chip size="x-small" variant="flat" :color="bayTypeColor(b.bay_type)">{{ bayTypeLabel(b.bay_type) }}</v-chip>
                </div>
                <p class="text-caption text-medium-emphasis mb-2"><v-icon size="12">mdi-parking</v-icon>Capacity: {{ b.capacity }}</p>
                <div v-if="b.notes" class="text-caption text-medium-emphasis pa-2 rounded" style="background:#f8fafc">{{ b.notes }}</div>
                <div v-if="!b.is_active" class="text-caption text-error mt-1"><v-icon size="12">mdi-pause-circle</v-icon> Inactive</div>
              </div>
            </v-card>
            <div v-if="!bay.items.length" class="text-center text-caption text-medium-emphasis py-6">
              <v-icon size="32" color="grey-lighten-2">mdi-inbox-outline</v-icon>
              <p class="mt-1">No bays</p>
            </div>
          </div>
        </div>
      </v-col>
    </v-row>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ bays: any[] }>()
defineEmits<{ openBay: [b: any] }>()

const bayColumns = computed(() => [
  { key: 'available', title: 'Available', color: '#22c55e', icon: 'mdi-check-circle-outline', items: props.bays.filter(b => b.is_active && !b.is_occupied) },
  { key: 'occupied', title: 'Occupied', color: '#ef4444', icon: 'mdi-car-connected', items: props.bays.filter(b => b.is_active && b.is_occupied) },
  { key: 'lift', title: 'Lift Bays', color: '#6366f1', icon: 'mdi-arrow-up', items: props.bays.filter(b => b.bay_type === 'lift') },
  { key: 'other', title: 'Other Bays', color: '#94a3b8', icon: 'mdi-sitemap', items: props.bays.filter(b => b.bay_type !== 'lift' && b.bay_type !== 'general' || (b.bay_type === 'general')) },
])

function bayTypeColor(t: string) { return ({ lift: 'primary', flat: 'info', paint: 'deep-purple', wash: 'cyan', inspection: 'warning', general: 'grey' } as any)[t] || 'grey' }
function bayTypeIcon(t: string) { return ({ lift: 'mdi-arrow-up', flat: 'mdi-minus', paint: 'mdi-palette', wash: 'mdi-water', inspection: 'mdi-magnify', general: 'mdi-sitemap' } as any)[t] || 'mdi-sitemap' }
function bayTypeLabel(t: string) { return ({ lift: 'Lift', flat: 'Flat', paint: 'Paint', wash: 'Wash', inspection: 'Insp', general: 'Gen' } as any)[t] || t }
</script>

<style scoped>
.kanban-col { border-top: 3px solid #ccc; background: #f8fafc; border-radius: 12px; padding: 12px; min-height: 240px; }
.kanban-list { min-height: 180px; }
.kanban-card { transition: transform .15s, box-shadow .15s; }
.kanban-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(2,6,23,.08); }
.kanban-card-available { border-left: 3px solid #22c55e; }
.kanban-card-occupied { border-left: 3px solid #ef4444; }
.kanban-card-lift { border-left: 3px solid #6366f1; }
.kanban-card-other { border-left: 3px solid #94a3b8; }
.cursor-pointer { cursor: pointer; }
</style>
