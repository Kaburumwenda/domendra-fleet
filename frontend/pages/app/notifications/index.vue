<template>
  <div class="d-flex flex-column ga-4">
    <v-tabs v-model="tab" color="primary">
      <v-tab value="inbox"><v-icon class="me-2">mdi-bell-outline</v-icon>Inbox</v-tab>
      <v-tab value="templates"><v-icon class="me-2">mdi-email-edit-outline</v-icon>Templates</v-tab>
      <v-tab value="preferences"><v-icon class="me-2">mdi-tune</v-icon>Preferences</v-tab>
    </v-tabs>

    <v-window v-model="tab">
      <v-window-item value="inbox">
        <div class="d-flex align-center justify-space-between mb-3">
          <span class="text-body-2 text-medium-emphasis">{{ notifications.length }} notifications · {{ unread.length }} unread</span>
          <v-btn v-can="'notifications:update'" prepend-icon="mdi-check-all" variant="outlined" size="small" @click="markAllRead">Mark all read</v-btn>
        </div>
        <v-card elevation="0" border rounded="lg">
          <v-list lines="three">
            <v-list-item v-for="n in notifications" :key="n.id" :class="{ 'bg-primary-lighten-5': !n.is_read }">
              <template #prepend><v-icon :color="channelIcon(n.channel).color">{{ channelIcon(n.channel).icon }}</v-icon></template>
              <v-list-item-title class="font-weight-medium">{{ n.subject || n.event }}</v-list-item-title>
              <v-list-item-subtitle class="text-wrap">{{ n.body }}</v-list-item-subtitle>
              <template #append>
                <v-chip size="x-small" :color="n.status === 'failed' ? 'error' : n.status === 'sent' ? 'success' : 'grey'">{{ n.status }}</v-chip>
                <v-btn v-can="'notifications:update'" v-if="!n.is_read" icon="mdi-check" variant="text" size="small" @click="markRead(n)" />
              </template>
            </v-list-item>
            <v-list-item v-if="!notifications.length"><div class="text-center py-12 text-medium-emphasis"><v-icon size="48" class="mb-3">mdi-bell-off-outline</v-icon><p>No notifications.</p></div></v-list-item>
          </v-list>
        </v-card>
      </v-window-item>

      <v-window-item value="templates">
        <div class="d-flex justify-end mb-3"><v-btn v-can="'notifications:update'" color="primary" prepend-icon="mdi-plus" size="small" @click="openCreateTpl">Add Template</v-btn></div>
        <v-card elevation="0" border rounded="lg">
          <v-data-table :headers="tplHeaders" :items="templates" :loading="tplPending" density="compact" hover>
            <template #item.channel="{ value }"><v-chip size="small">{{ value }}</v-chip></template>
            <template #item.is_active="{ value }"><v-chip size="small" :color="value ? 'success' : 'grey'">{{ value ? 'Active' : 'Off' }}</v-chip></template>
            <template #item.actions="{ item }">
              <div class="d-flex ga-1">
                <v-btn v-can="'notifications:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEditTpl(item)" />
                <v-btn v-can="'notifications:update'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteTpl(item)" />
              </div>
            </template>
          </v-data-table>
        </v-card>
      </v-window-item>

      <v-window-item value="preferences">
        <v-card elevation="0" border rounded="lg" max-width="560" class="mx-auto">
          <AppModalHeader icon="mdi-tune">Notification Preferences</AppModalHeader>
          <v-card-text>
            <v-switch v-model="prefs.email_enabled" label="Email notifications" color="primary" />
            <v-switch v-model="prefs.sms_enabled" label="SMS notifications" color="primary" />
            <v-switch v-model="prefs.in_app_enabled" label="In-app notifications" color="primary" />
            <v-switch v-model="prefs.push_enabled" label="Push notifications" color="primary" />
          </v-card-text>
          <v-card-actions class="px-4 pb-4">
            <v-spacer />
            <v-btn color="primary" @click="savePrefs" :loading="savingPrefs">Save</v-btn>
          </v-card-actions>
        </v-card>
      </v-window-item>
    </v-window>

    <v-dialog v-model="tplDialog" max-width="560">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-email-edit-outline">{{ editingTpl ? 'Edit Template' : 'Add Template' }}</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="tplForm.name" label="Name" /></v-col>
            <v-col cols="6"><v-select v-model="tplForm.channel" :items="['email', 'sms', 'in_app', 'push']" label="Channel" /></v-col>
            <v-col cols="12"><v-text-field v-model="tplForm.event" label="Event (e.g. reminder_due)" /></v-col>
            <v-col cols="12"><v-text-field v-model="tplForm.subject" label="Subject" /></v-col>
            <v-col cols="12"><v-textarea v-model="tplForm.body" label="Body (use {{variable}} placeholders)" rows="4" /></v-col>
            <v-col cols="12"><v-checkbox v-model="tplForm.is_active" label="Active" density="compact" /></v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="tplDialog = false">Cancel</v-btn>
          <v-btn color="primary" @click="saveTpl" :loading="saving">{{ editingTpl ? 'Update' : 'Create' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api } = useNuxtApp()
const tab = ref('inbox')
const tplDialog = ref(false)
const editingTpl = ref(false)
const saving = ref(false)
const savingPrefs = ref(false)
const prefs = reactive<any>({ email_enabled: true, sms_enabled: true, in_app_enabled: true, push_enabled: true })
const tplForm = reactive<any>({ name: '', channel: 'email', event: '', subject: '', body: '', is_active: true })

const tplHeaders = [
  { title: 'Name', key: 'name', sortable: true },
  { title: 'Channel', key: 'channel', width: '120px' },
  { title: 'Event', key: 'event', width: '160px' },
  { title: 'Active', key: 'is_active', width: '100px' },
  { title: '', key: 'actions', width: '110px', sortable: false },
]

const { data: nData, refresh: refreshNotifs } = useAsyncData('notifications', () => $api('/notifications/'), { default: () => ({ results: [] }) })
const notifications = computed(() => nData.value?.results || [])
const unread = computed(() => notifications.value.filter((n: any) => !n.is_read))
const { data: tData, pending: tplPending, refresh: refreshTpls } = useAsyncData('notif-templates', () => $api('/notifications/templates/'), { default: () => ({ results: [] }) })
const templates = computed(() => tData.value?.results || [])

async function loadPrefs() { try { const d = await $api('/notifications/preferences/me/'); Object.assign(prefs, d) } catch (e) {} }
loadPrefs()

function channelIcon(ch: string) { return { email: { icon: 'mdi-email', color: 'primary' }, sms: { icon: 'mdi-message-text', color: 'info' }, in_app: { icon: 'mdi-bell', color: 'success' }, push: { icon: 'mdi-cellphone', color: 'warning' } }[ch] || { icon: 'mdi-bell', color: 'grey' } }

async function markAllRead() { await $api('/notifications/mark-all-read/', { method: 'POST' }); await refreshNotifs() }
async function markRead(n: any) { await $api(`/notifications/${n.id}/mark-read/`, { method: 'POST' }); await refreshNotifs() }

function openCreateTpl() { editingTpl.value = false; Object.assign(tplForm, { name: '', channel: 'email', event: '', subject: '', body: '', is_active: true }); tplDialog.value = true }
function openEditTpl(i: any) { editingTpl.value = true; Object.assign(tplForm, i); tplForm._id = i.id; tplDialog.value = true }
async function saveTpl() {
  saving.value = true
  try {
    if (editingTpl.value) await $api(`/notifications/templates/${tplForm._id}/`, { method: 'PATCH', body: tplForm })
    else await $api('/notifications/templates/', { method: 'POST', body: tplForm })
    tplDialog.value = false; await refreshTpls()
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteTpl(i: any) { if (!confirm(`Delete template ${i.name}?`)) return; await $api(`/notifications/templates/${i.id}/`, { method: 'DELETE' }); await refreshTpls() }
async function savePrefs() { savingPrefs.value = true; try { await $api('/notifications/preferences/me/', { method: 'PATCH', body: prefs }) } catch (e) { console.error(e) } finally { savingPrefs.value = false } }
</script>
