<template>
  <v-dialog
    :model-value="open"
    @update:model-value="$emit('update:open', $event)"
    max-width="780px"
    scrollable
  >
    <v-card rounded="xl" elevation="0" border class="rbac-role-dialog">
      <!-- Header with gradient -->
      <div class="rbac-dialog-header">
        <div class="d-flex align-center ga-3">
          <div class="rbac-dialog-header-icon">
            <v-icon color="white" size="22">{{ isEditing ? 'mdi-shield-edit-outline' : 'mdi-shield-plus-outline' }}</v-icon>
          </div>
          <div>
            <h3 class="text-h6 font-weight-bold mb-0 text-white">
              {{ isEditing ? 'Edit Role' : 'Create New Role' }}
            </h3>
            <p class="text-caption mb-0 text-white" style="opacity: 0.8">
              {{ isEditing ? 'Customize permissions for this role' : 'Define a custom role with granular permissions' }}
            </p>
          </div>
        </div>
        <v-btn icon="mdi-close" variant="text" color="white" size="small" @click="$emit('update:open', false)" />
      </div>

      <v-card-text class="pa-0">
        <div class="pa-6 pb-0">
          <!-- Role metadata form -->
          <v-row dense>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="form.name"
                label="Role Name"
                variant="outlined"
                density="comfortable"
                :error-messages="errors.name"
                @input="generateKey"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="form.key"
                label="Role Key"
                variant="outlined"
                density="comfortable"
                hint="Unique identifier (auto-generated from name)"
                persistent-hint
                :error-messages="errors.key"
                :disabled="isSystemRole"
              />
            </v-col>
            <v-col cols="12">
              <v-textarea
                v-model="form.description"
                label="Description"
                variant="outlined"
                density="comfortable"
                rows="2"
                auto-grow
                placeholder="What can this role do?"
              />
            </v-col>
            <v-col cols="12" sm="6">
              <v-select
                v-model="form.color"
                :items="colorOptions"
                item-title="label"
                item-value="value"
                label="Color Tag"
                variant="outlined"
                density="comfortable"
              >
                <template #prepend>
                  <div class="rbac-color-preview" :style="{ background: form.color }" />
                </template>
                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend>
                      <div class="rbac-color-swatch" :style="{ background: item.raw.value }" />
                    </template>
                  </v-list-item>
                </template>
              </v-select>
            </v-col>
            <v-col cols="12" sm="6">
              <v-text-field
                v-model="form.icon"
                label="Icon (MDI)"
                variant="outlined"
                density="comfortable"
                hint="Material Design Icon name"
                persistent-hint
              >
                <template #append-inner>
                  <v-icon :icon="form.icon" />
                </template>
              </v-text-field>
            </v-col>
          </v-row>
        </div>

        <!-- ── Permission matrix ─────────────────────────────────────── -->
        <div class="px-6 pt-4 pb-3">
          <div class="d-flex align-center justify-space-between mb-3">
            <div class="d-flex align-center ga-2">
              <v-icon color="primary" size="20">mdi-shield-key</v-icon>
              <h4 class="text-subtitle-1 font-weight-bold mb-0">Permissions Matrix</h4>
            </div>
            <div class="d-flex align-center ga-2">
              <v-chip size="small" variant="tonal" color="primary">
                {{ grantedCount }} granted
              </v-chip>
              <v-btn
                v-if="!isSystemRole"
                size="x-small"
                variant="text"
                @click="selectAll"
              >Select All</v-btn>
              <v-btn
                size="x-small"
                variant="text"
                @click="deselectAll"
              >Clear</v-btn>
            </div>
          </div>

          <!-- Quick filter -->
          <v-text-field
            v-model="filter"
            prepend-inner-icon="mdi-magnify"
            placeholder="Filter permissions by module..."
            variant="outlined"
            density="compact"
            hide-details
            class="mb-3"
            clearable
          />
        </div>

        <!-- Permission groups accordion -->
        <v-divider />
        <div class="rbac-perm-scroll">
          <v-expansion-panels v-model="expandedPanels" multiple variant="accordion" flat>
            <v-expansion-panel
              v-for="group in filteredGroups"
              :key="group.module"
              :value="group.module"
              class="rbac-perm-panel"
            >
              <v-expansion-panel-title class="rbac-perm-panel-title" expand-icon="mdi-chevron-down">
                <div class="d-flex align-center ga-2 flex-1">
                  <div class="rbac-perm-module-icon" :class="{ 'rbac-perm-module-active': moduleAllGranted(group) }">
                    <v-icon :icon="group.icon" size="18" />
                  </div>
                  <span class="text-body-2 font-weight-bold">{{ group.label }}</span>
                  <v-chip size="x-small" variant="tonal" class="ml-auto mr-2">
                    {{ groupPermissionsGranted(group) }}/{{ group.permissions.length }}
                  </v-chip>
                  <v-checkbox
                    v-if="!isSystemRole"
                    :model-value="moduleAllGranted(group)"
                    @click.stop.prevent="toggleModule(group)"
                    color="primary"
                    density="compact"
                    hide-details
                    class="rbac-module-checkbox"
                  />
                </div>
              </v-expansion-panel-title>
              <v-expansion-panel-text class="rbac-perm-panel-text">
                <div class="rbac-perm-grid">
                  <div
                    v-for="perm in group.permissions"
                    :key="perm.code"
                    class="rbac-perm-item"
                    :class="{ 'rbac-perm-item-granted': selectedPerms.has(perm.code) }"
                  >
                    <v-checkbox
                      :model-value="selectedPerms.has(perm.code)"
                      @update:model-value="togglePermission(perm.id, perm.code, $event)"
                      color="primary"
                      density="compact"
                      hide-details
                      class="flex-shrink-0"
                    />
                    <div class="rbac-perm-info">
                      <span class="text-body-2 font-weight-medium">{{ perm.label }}</span>
                      <p class="text-caption text-medium-emphasis mb-0">{{ perm.description }}</p>
                      <code class="rbac-perm-code">{{ perm.code }}</code>
                    </div>
                  </div>
                </div>
              </v-expansion-panel-text>
            </v-expansion-panel>
          </v-expansion-panels>

          <div v-if="filteredGroups.length === 0" class="text-center py-8">
            <v-icon size="40" color="grey-lighten-1">mdi-magnify-close</v-icon>
            <p class="text-body-2 text-medium-emphasis mt-2">No permissions match "{{ filter }}"</p>
          </div>
        </div>
      </v-card-text>

      <v-divider />
      <v-card-actions class="pa-4">
        <v-chip v-if="isSystemRole" size="small" variant="flat" color="primary" class="text-uppercase" label>
          <v-icon start size="14">mdi-shield</v-icon>
          System Role
        </v-chip>
        <v-spacer />
        <v-btn variant="text" @click="$emit('update:open', false)">Cancel</v-btn>
        <v-btn
          color="primary"
          prepend-icon="mdi-content-save"
          :loading="saving"
          @click="save"
        >
          {{ isEditing ? 'Update Role' : 'Create Role' }}
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import type { RbacPermissionGroup, RbacRoleDetail } from '~/composables/useRbac'

const props = defineProps<{
  open: boolean
  role: RbacRoleDetail | null
  permissionGroups: RbacPermissionGroup[]
}>()

const emit = defineEmits<{
  'update:open': [boolean]
  saved: []
}>()

const { $api, $swal } = useNuxtApp()
const rbac = useRbac()

const isEditing = computed(() => !!props.role)
const isSystemRole = computed(() => props.role?.is_system ?? false)

const form = reactive({
  name: '',
  key: '',
  description: '',
  color: '#6366f1',
  icon: 'mdi-shield-account-outline',
})

const errors = reactive<any>({})
const saving = ref(false)
const filter = ref('')
const expandedPanels = ref<string[]>([])
const selectedPerms = ref<Set<string>>(new Set())
const selectedPermIds = ref<Set<number>>(new Set())

// ── Color options ──────────────────────────────────────────────────────
const colorOptions = [
  { label: 'Indigo', value: '#6366f1' },
  { label: 'Blue', value: '#3b82f6' },
  { label: 'Green', value: '#22c55e' },
  { label: 'Orange', value: '#f59e0b' },
  { label: 'Red', value: '#ef4444' },
  { label: 'Purple', value: '#a855f7' },
  { label: 'Teal', value: '#14b8a6' },
  { label: 'Pink', value: '#ec4899' },
  { label: 'Cyan', value: '#06b6d4' },
  { label: 'Gray', value: '#6b7280' },
]

// ── Watchers ──────────────────────────────────────────────────────────
watch(() => props.open, (val) => {
  if (val) {
    if (props.role) {
      form.name = props.role.name
      form.key = props.role.key
      form.description = props.role.description || ''
      form.color = props.role.color || '#6366f1'
      form.icon = props.role.icon || 'mdi-shield-account-outline'
      // Build selected permissions from detail
      selectedPerms.value = new Set()
      selectedPermIds.value = new Set()
      if (props.role.permission_groups) {
        for (const group of props.role.permission_groups) {
          for (const perm of group.permissions) {
            if (perm.granted) {
              selectedPerms.value.add(perm.code)
              selectedPermIds.value.add(perm.id)
            }
          }
          // Expand all groups that have at least one permission
          if (group.permissions.some(p => p.granted)) {
            expandedPanels.value.push(group.module)
          }
        }
      } else {
        // Fallback: use permission_codes
        (props.role.permission_codes || []).forEach((code: string) => selectedPerms.value.add(code))
      }
    } else {
      form.name = ''
      form.key = ''
      form.description = ''
      form.color = '#6366f1'
      form.icon = 'mdi-shield-account-outline'
      selectedPerms.value = new Set()
      selectedPermIds.value = new Set()
      expandedPanels.value = []
    }
  }
}, { immediate: true })

// ── Computed ──────────────────────────────────────────────────────────
const filteredGroups = computed(() => {
  if (!filter.value) return props.permissionGroups
  const f = filter.value.toLowerCase()
  return props.permissionGroups
    .map(g => ({
      ...g,
      permissions: g.permissions.filter(p =>
        p.label.toLowerCase().includes(f) ||
        p.module.toLowerCase().includes(f) ||
        p.description.toLowerCase().includes(f)
      ),
    }))
    .filter(g => g.permissions.length > 0)
})

const grantedCount = computed(() => selectedPerms.value.size)

// ── Helpers ───────────────────────────────────────────────────────────
function generateKey() {
  if (isEditing.value) return
  const slug = form.name.toLowerCase().trim().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '')
  form.key = slug
}

function moduleAllGranted(group: any): boolean {
  return group.permissions.every((p: any) => selectedPerms.value.has(p.code))
}

function groupPermissionsGranted(group: any): number {
  return group.permissions.filter((p: any) => selectedPerms.value.has(p.code)).length
}

function toggleModule(group: any) {
  const allGranted = moduleAllGranted(group)
  if (allGranted) {
    for (const p of group.permissions) {
      selectedPerms.value.delete(p.code)
      selectedPermIds.value.delete(p.id)
    }
  } else {
    for (const p of group.permissions) {
      selectedPerms.value.add(p.code)
      selectedPermIds.value.add(p.id)
    }
  }
  selectedPerms.value = new Set(selectedPerms.value)
  selectedPermIds.value = new Set(selectedPermIds.value)
}

function togglePermission(permId: number, permCode: string, value: any) {
  if (value) {
    selectedPerms.value.add(permCode)
    selectedPermIds.value.add(permId)
  } else {
    selectedPerms.value.delete(permCode)
    selectedPermIds.value.delete(permId)
  }
  selectedPerms.value = new Set(selectedPerms.value)
  selectedPermIds.value = new Set(selectedPermIds.value)
}

function selectAll() {
  for (const group of props.permissionGroups) {
    for (const p of group.permissions) {
      selectedPerms.value.add(p.code)
      selectedPermIds.value.add(p.id)
    }
  }
  selectedPerms.value = new Set(selectedPerms.value)
  selectedPermIds.value = new Set(selectedPermIds.value)
}

function deselectAll() {
  selectedPerms.value.clear()
  selectedPermIds.value.clear()
  selectedPerms.value = new Set()
  selectedPermIds.value = new Set()
}

// ── Save ──────────────────────────────────────────────────────────────
async function save() {
  // Validation
  errors.name = ''
  errors.key = ''
  if (!form.name?.trim()) {
    errors.name = 'Role name is required.'
    return
  }
  if (!form.key?.trim()) {
    errors.key = 'Role key is required.'
    return
  }

  saving.value = true
  const payload = {
    name: form.name,
    key: form.key,
    description: form.description,
    color: form.color,
    icon: form.icon,
    permissions: Array.from(selectedPermIds.value),
  }

  try {
    if (isEditing.value && props.role) {
      await rbac.updateRole(props.role.id, payload)
      $swal.fire({ icon: 'success', title: 'Role Updated', text: `${form.name} has been updated.`, timer: 2000, toast: true, position: 'top-end' })
    } else {
      await rbac.createRole(payload as any)
      $swal.fire({ icon: 'success', title: 'Role Created', text: `${form.name} has been created.`, timer: 2000, toast: true, position: 'top-end' })
    }
    emit('saved')
  } catch (e: any) {
    const msg = e?.data?.key?.[0] || e?.data?.name?.[0] || e?.data?.detail || 'Could not save role.'
    $swal.fire({ icon: 'error', title: 'Save Failed', text: msg })
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.rbac-role-dialog {
  overflow: hidden;
}

.rbac-dialog-header {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 60%, #7c3aed 100%);
  padding: 20px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.rbac-dialog-header-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.18);
  backdrop-filter: blur(4px);
}

.rbac-color-preview {
  width: 24px;
  height: 24px;
  border-radius: 8px;
  border: 2px solid rgba(var(--v-theme-on-surface), 0.1);
}
.rbac-color-swatch {
  width: 20px;
  height: 20px;
  border-radius: 6px;
  margin-right: 8px;
  display: inline-block;
}

.rbac-perm-scroll {
  max-height: 420px;
  overflow-y: auto;
}

.rbac-perm-panel {
  border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.06);
}
.rbac-perm-panel:last-child {
  border-bottom: none;
}

.rbac-perm-panel-title {
  padding: 10px 20px;
  min-height: 48px !important;
}
.rbac-perm-panel-title:hover {
  background: rgba(var(--v-theme-on-surface), 0.03);
}

.rbac-perm-module-icon {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(var(--v-theme-on-surface), 0.06);
  color: rgba(var(--v-theme-on-surface), 0.5);
  transition: all 0.2s ease;
}
.rbac-perm-module-active {
  background: rgba(99, 102, 241, 0.15) !important;
  color: #6366f1 !important;
}

.rbac-module-checkbox {
  margin-left: 8px;
}
.rbac-module-checkbox :deep(.v-selection-control) {
  --v-selection-control-size: 20px;
}

.rbac-perm-panel-text :deep(.v-expansion-panel-text__wrapper) {
  padding: 0 20px 12px;
}

.rbac-perm-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.rbac-perm-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid transparent;
  transition: all 0.16s ease;
  cursor: default;
}
.rbac-perm-item:hover {
  background: rgba(var(--v-theme-on-surface), 0.03);
}
.rbac-perm-item-granted {
  background: rgba(99, 102, 241, 0.06);
  border-color: rgba(99, 102, 241, 0.15);
}

.rbac-perm-info {
  flex: 1;
  min-width: 0;
}

.rbac-perm-code {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 10px;
  padding: 1px 6px;
  border-radius: 4px;
  background: rgba(var(--v-theme-on-surface), 0.06);
  color: rgba(var(--v-theme-on-surface), 0.5);
  display: inline-block;
  margin-top: 2px;
}

@media (max-width: 600px) {
  .rbac-perm-grid {
    grid-template-columns: 1fr;
  }
}
</style>
