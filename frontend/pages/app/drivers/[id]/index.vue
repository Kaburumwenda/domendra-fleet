<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="page-header-bar">
      <div class="d-flex align-center ga-2">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" @click="goBack" />
        <div class="driver-avatar-lg" :style="{ background: avatarColor }">
          <img v-if="driver?.photo" :src="resolveMediaUrl(driver.photo)" :alt="driver?.full_name" />
          <span v-else>{{ initials }}</span>
        </div>
        <div>
          <p class="text-h6 font-weight-bold page-header-title">{{ driver?.full_name || 'Driver' }}</p>
          <div class="d-flex align-center ga-2 mt-1">
            <v-chip v-if="dp" :color="employmentColor(dp.employment_status)" variant="tonal" size="small">{{ dp.employment_status_label || dp.employment_status }}</v-chip>
            <v-chip v-if="dp" :color="mvrColor(dp.mvr_status)" variant="flat" size="small">MVR: {{ dp.mvr_status_label || dp.mvr_status }}</v-chip>
            <span class="text-caption text-medium-emphasis">{{ driver?.email || driver?.phone || '' }}</span>
          </div>
        </div>
      </div>
      <div class="d-flex ga-2">
        <v-btn v-can="'drivers:update'" variant="text" prepend-icon="mdi-pencil-outline" @click="goEdit">Edit</v-btn>
        <v-btn v-can="'drivers:delete'" variant="text" color="error" prepend-icon="mdi-trash-can-outline" @click="deleteDriver">Delete</v-btn>
      </div>
    </div>

    <div v-if="pending" class="d-flex justify-center pa-10">
      <v-progress-circular indeterminate color="primary" />
    </div>

    <template v-else-if="driver">
      <!-- Tabs -->
      <div class="drivers-tabs-wrap">
        <div class="drivers-tabs">
          <button
            v-for="t in tabs"
            :key="t.value"
            type="button"
            class="drivers-tab"
            :class="{ 'drivers-tab--active': tab === t.value }"
            @click="tab = t.value"
          >
            <v-icon size="18" class="drivers-tab__icon">{{ t.icon }}</v-icon>
            <span class="drivers-tab__label">{{ t.label }}</span>
            <span v-if="t.count !== null" class="drivers-tab__count">{{ t.count }}</span>
          </button>
        </div>
      </div>

      <v-window v-model="tab" class="drivers-window">
        <!-- Profile -->
        <v-window-item value="profile">
          <v-row dense>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="lg" class="pa-5">
                <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">Personal Information</h3>
                <v-list density="compact">
                  <v-list-item title="Full Name" :subtitle="driver.full_name" />
                  <v-list-item title="Date of Birth" :subtitle="driver.date_of_birth || '—'" />
                  <v-list-item title="Employee ID" :subtitle="driver.employee_id || '—'" />
                  <v-list-item title="Department" :subtitle="driver.department || '—'" />
                  <v-list-item title="Phone" :subtitle="driver.phone || '—'" />
                  <v-list-item title="Email" :subtitle="driver.email || '—'" />
                  <v-list-item title="Address" :subtitle="fullAddress || '—'" />
                </v-list>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <v-card elevation="0" border rounded="lg" class="pa-5">
                <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">Emergency Contact</h3>
                <v-list density="compact">
                  <v-list-item title="Name" :subtitle="dp?.emergency_contact_name || '—'" />
                  <v-list-item title="Phone" :subtitle="dp?.emergency_contact_phone || '—'" />
                  <v-list-item title="Relationship" :subtitle="dp?.emergency_contact_relation || '—'" />
                  <v-list-item title="Blood Type" :subtitle="dp?.blood_type || '—'" />
                  <v-list-item title="Home Terminal" :subtitle="dp?.home_terminal || '—'" />
                </v-list>
              </v-card>
            </v-col>
          </v-row>

          <v-card elevation="0" border rounded="lg" class="pa-5 mt-4">
            <h3 class="text-subtitle-1 font-weight-bold mb-3" style="color: #1e293b">Notes</h3>
            <p v-if="driver.notes" class="text-body-2" style="color: #475569">{{ driver.notes }}</p>
            <p v-else class="text-body-2 text-medium-emphasis">No general notes.</p>
          </v-card>
        </v-window-item>

        <!-- License & Medical -->
        <v-window-item value="license">
          <v-card elevation="0" border rounded="lg" class="pa-5">
            <div class="d-flex align-center justify-space-between mb-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">License & Medical Card</h3>
              <v-btn v-can="'drivers:update'" size="small" variant="tonal" prepend-icon="mdi-pencil" @click="openProfileEdit">Edit</v-btn>
            </div>
            <v-row dense>
              <v-col cols="12" md="6">
                <v-list density="compact" class="info-list">
                  <v-list-item title="License Number" :subtitle="dp?.license_number || '—'" />
                  <v-list-item title="License Class" :subtitle="dp?.license_class_label || dp?.license_class || '—'" />
                  <v-list-item title="Issuing State" :subtitle="dp?.license_state || '—'" />
                  <v-list-item title="Expiry">
                    <template #subtitle>
                      <span :class="expiryClass(dp?.license_expiry)">{{ dp?.license_expiry || '—' }}</span>
                    </template>
                  </v-list-item>
                  <v-list-item title="Endorsements" :subtitle="formatEndorsements(dp?.license_endorsements)" />
                </v-list>
              </v-col>
              <v-col cols="12" md="6">
                <v-list density="compact" class="info-list">
                  <v-list-item title="Medical Card Number" :subtitle="dp?.medical_card_number || '—'" />
                  <v-list-item title="Medical Card Expiry">
                    <template #subtitle>
                      <span :class="expiryClass(dp?.medical_card_expiry)">{{ dp?.medical_card_expiry || '—' }}</span>
                    </template>
                  </v-list-item>
                  <v-list-item title="MVR Status" :subtitle="dp?.mvr_status_label || dp?.mvr_status || '—'" />
                  <v-list-item title="MVR Last Checked" :subtitle="dp?.mvr_last_checked || '—'" />
                  <v-list-item title="MVR Next Due" :subtitle="dp?.mvr_next_due || '—'" />
                  <v-list-item title="Hire Date" :subtitle="dp?.hire_date || '—'" />
                  <v-list-item title="Termination Date" :subtitle="dp?.termination_date || '—'" />
                </v-list>
              </v-col>
            </v-row>
          </v-card>
        </v-window-item>

        <!-- Violations -->
        <v-window-item value="violations">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Violations & Citations</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openViolationDialog()">Add Violation</v-btn>
            </div>
            <v-data-table :headers="violationHeaders" :items="dp?.violations || []" hover density="compact">
              <template #item.severity="{ value }">
                <v-chip :color="severityColor(value)" variant="flat" size="small">{{ value }}</v-chip>
              </template>
              <template #item.paid="{ value }">
                <v-icon :color="value ? 'success' : 'grey'" size="small">{{ value ? 'mdi-check' : 'mdi-close' }}</v-icon>
              </template>
              <template #item.actions="{ item }">
                <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteViolation(item)" />
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-shield-check</v-icon><p>No violations recorded.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- Drug Tests -->
        <v-window-item value="drug">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Drug & Alcohol Tests</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openDrugDialog()">Add Test</v-btn>
            </div>
            <v-data-table :headers="drugHeaders" :items="dp?.drug_tests || []" hover density="compact">
              <template #item.result="{ value }">
                <v-chip :color="drugResultColor(value)" variant="flat" size="small">{{ value }}</v-chip>
              </template>
              <template #item.actions="{ item }">
                <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteDrug(item)" />
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-flask-outline</v-icon><p>No drug tests recorded.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- Training -->
        <v-window-item value="training">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Training & Certifications</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openTrainingDialog()">Add Training</v-btn>
            </div>
            <v-data-table :headers="trainingHeaders" :items="dp?.trainings || []" hover density="compact">
              <template #item.status="{ value }">
                <v-chip :color="trainingStatusColor(value)" variant="tonal" size="small">{{ value }}</v-chip>
              </template>
              <template #item.score="{ value }">
                <span v-if="value !== null && value !== undefined">{{ value }}%</span>
                <span v-else class="text-medium-emphasis">—</span>
              </template>
              <template #item.actions="{ item }">
                <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteTraining(item)" />
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-school-outline</v-icon><p>No training records.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- HOS -->
        <v-window-item value="hos">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Hours of Service Logs</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openHosDialog()">Add HOS Entry</v-btn>
            </div>
            <v-data-table :headers="hosHeaders" :items="dp?.hos_logs || []" hover density="compact">
              <template #item.duty_status="{ value }">
                <v-chip :color="hosColor(value)" variant="tonal" size="small">{{ value }}</v-chip>
              </template>
              <template #item.actions="{ item }">
                <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteHos(item)" />
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-clock-outline</v-icon><p>No HOS logs recorded.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- Assignments -->
        <v-window-item value="assignments">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Vehicle Assignments</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openAssignmentDialog()">Assign Vehicle</v-btn>
            </div>
            <v-data-table :headers="assignmentHeaders" :items="dp?.assignments || []" hover density="compact">
              <template #item.is_active="{ value }">
                <v-chip :color="value ? 'success' : 'grey'" variant="flat" size="small">{{ value ? 'Active' : 'Released' }}</v-chip>
              </template>
              <template #item.actions="{ item }">
                <v-btn v-if="item.is_active" v-can="'drivers:update'" icon="mdi-link-off" variant="text" color="warning" size="small" @click="releaseAssignment(item)" />
                <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteAssignment(item)" />
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-car-connected</v-icon><p>No vehicle assignments.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- Hire Rates -->
        <v-window-item value="hire">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Hire Rate Plans</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openHireDialog()">Add Hire Rate</v-btn>
            </div>
            <v-data-table :headers="hireHeaders" :items="hireRates" hover density="compact" class="px-4 pb-4">
              <template #item.plan_name="{ item }">
                <div>
                  <p class="text-body-2 font-weight-medium">{{ item.customer_name || '—' }}</p>
                  <p class="text-caption text-medium-emphasis">{{ item.name || 'Default' }}</p>
                </div>
              </template>
              <template #item.rates="{ item }">
                <div class="d-flex flex-wrap ga-1">
                  <v-chip v-if="Number(item.hourly_rate) > 0" size="x-small" variant="tonal">Hr: {{ item.hourly_rate }}</v-chip>
                  <v-chip v-if="Number(item.daily_rate) > 0" size="x-small" variant="tonal">Day: {{ item.daily_rate }}</v-chip>
                  <v-chip v-if="Number(item.weekly_rate) > 0" size="x-small" variant="tonal">Wk: {{ item.weekly_rate }}</v-chip>
                  <v-chip v-if="Number(item.monthly_rate) > 0" size="x-small" variant="tonal">Mo: {{ item.monthly_rate }}</v-chip>
                  <v-chip v-if="Number(item.weekend_rate) > 0" size="x-small" variant="tonal">Wend: {{ item.weekend_rate }}</v-chip>
                </div>
              </template>
              <template #item.effective_rates="{ item }">
                <div class="d-flex flex-wrap ga-1">
                  <v-chip v-if="Number(item.hourly_effective_rate) > 0" size="x-small" variant="flat" color="success">Hr: {{ item.hourly_effective_rate }}</v-chip>
                  <v-chip v-if="Number(item.daily_effective_rate) > 0" size="x-small" variant="flat" color="success">Day: {{ item.daily_effective_rate }}</v-chip>
                  <v-chip v-if="Number(item.weekly_effective_rate) > 0" size="x-small" variant="flat" color="success">Wk: {{ item.weekly_effective_rate }}</v-chip>
                  <v-chip v-if="Number(item.monthly_effective_rate) > 0" size="x-small" variant="flat" color="success">Mo: {{ item.monthly_effective_rate }}</v-chip>
                  <v-chip v-if="Number(item.weekend_effective_rate) > 0" size="x-small" variant="flat" color="success">Wend: {{ item.weekend_effective_rate }}</v-chip>
                </div>
              </template>
              <template #item.status="{ value }">
                <v-chip :color="hireStatusColor(value)" variant="tonal" size="small">{{ value }}</v-chip>
              </template>
              <template #item.actions="{ item }">
                <div class="d-flex ga-1">
                  <v-btn icon="mdi-open-in-new" variant="text" size="small" title="Open plan" @click="navigateTo('/app/rentals/driver-hire-rates')" />
                  <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteHireRate(item)" />
                </div>
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-account-cash-outline</v-icon><p>No hire rate plans for this driver.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- Documents -->
        <v-window-item value="documents">
          <v-card elevation="0" border rounded="lg">
            <div class="d-flex align-center justify-space-between pa-4">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Documents</h3>
              <div class="d-flex align-center ga-2">
                <v-select v-model="docForm.document_type" :items="docTypes" item-title="label" item-value="value" label="Type" density="compact" variant="outlined" hide-details style="max-width: 180px" />
                <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openDocDialog">Add Document</v-btn>
              </div>
            </div>
            <div v-if="docDialog" class="pa-4 pt-0">
              <FileDropZone
                label="Upload Document (PDF, JPG, PNG)"
                icon="mdi-file-upload-outline"
                :file="docForm.file"
                accept=".pdf,.jpg,.jpeg,.png"
                @upload="onDocFile"
                @remove="removeDocFile"
              />
              <v-text-field v-model="docForm.title" label="Title" density="compact" variant="outlined" hide-details class="mt-3" />
              <div class="d-flex ga-2 mt-2">
                <v-text-field v-model="docForm.expiry_date" type="date" label="Expiry (optional)" density="compact" variant="outlined" hide-details />
              </div>
              <div class="d-flex justify-end ga-2 mt-3">
                <v-btn variant="text" size="small" @click="docDialog = false">Cancel</v-btn>
                <v-btn color="primary" size="small" :loading="saving" :disabled="!docForm.file" @click="uploadDoc">Upload</v-btn>
              </div>
            </div>
            <v-data-table :headers="docHeaders" :items="documents" hover density="compact" class="px-4">
              <template #item.title="{ item }">
                <div class="d-flex align-center ga-2">
                  <v-icon :icon="docIcon(item)" size="20" :color="docIconColor(item)" />
                  <span class="font-weight-medium" style="color: #1e293b">{{ item.title }}</span>
                </div>
              </template>
              <template #item.document_type="{ value }">
                <v-chip :color="docTypeColor(value)" variant="tonal" size="small">{{ value }}</v-chip>
              </template>
              <template #item.file_size="{ value }">
                <span class="text-caption">{{ formatSize(value) }}</span>
              </template>
              <template #item.expiry_date="{ value }">
                <span v-if="value" :class="expiryClass(value)">{{ value }}</span>
                <span v-else class="text-medium-emphasis">—</span>
              </template>
              <template #item.actions="{ item }">
                <div class="d-flex ga-1">
                  <v-btn :href="resolveMediaUrl(item.file)" target="_blank" icon="mdi-download" variant="text" size="small" title="Download" />
                  <v-btn v-can="'drivers:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteDoc(item)" />
                </div>
              </template>
              <template #no-data>
                <div class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-file-document-multiple-outline</v-icon><p>No documents uploaded.</p></div>
              </template>
            </v-data-table>
          </v-card>
        </v-window-item>

        <!-- Notes -->
        <v-window-item value="notes">
          <v-card elevation="0" border rounded="lg" class="pa-4">
            <div class="d-flex align-center justify-space-between mb-3">
              <h3 class="text-subtitle-1 font-weight-bold" style="color: #1e293b">Driver Notes & Log</h3>
              <v-btn v-can="'drivers:create'" size="small" color="primary" prepend-icon="mdi-plus" @click="openNoteDialog()">Add Note</v-btn>
            </div>
            <v-timeline v-if="dp?.notes_log?.length" density="compact" side="end">
              <v-timeline-item v-for="n in dp.notes_log" :key="n.id" :icon="noteIcon(n.category)" :dot-color="noteColor(n.category)" size="x-small">
                <div class="d-flex align-center justify-space-between">
                  <v-chip :color="noteColor(n.category)" variant="tonal" size="x-small">{{ n.category_label || n.category }}</v-chip>
                  <span class="text-caption text-medium-emphasis">{{ formatDate(n.created_at) }}</span>
                </div>
                <p class="text-body-2 mt-1" style="color: #475569">{{ n.body }}</p>
                <p v-if="n.author" class="text-caption text-medium-emphasis">— {{ n.author }}</p>
              </v-timeline-item>
            </v-timeline>
            <div v-else class="text-center py-8 text-medium-emphasis"><v-icon size="36" class="mb-2">mdi-note-text-outline</v-icon><p>No notes yet.</p></div>
          </v-card>
        </v-window-item>
      </v-window>
    </template>
  </div>

  <!-- Violation dialog -->
  <v-dialog v-model="violationDialog" max-width="560">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-shield-alert-outline">Add Violation</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12"><v-select v-model="vForm.violation_type" :items="violationTypes" item-title="label" item-value="value" label="Violation Type" /></v-col>
          <v-col cols="6"><v-select v-model="vForm.severity" :items="severityOptions" item-title="label" item-value="value" label="Severity" /></v-col>
          <v-col cols="6"><v-text-field v-model="vForm.date" type="date" label="Date" /></v-col>
          <v-col cols="6"><v-text-field v-model="vForm.state" label="State" /></v-col>
          <v-col cols="6"><v-text-field v-model="vForm.points" type="number" label="Points" /></v-col>
          <v-col cols="6"><v-text-field v-model="vForm.fine_amount" type="number" label="Fine Amount" /></v-col>
          <v-col cols="6"><v-checkbox v-model="vForm.paid" label="Paid" density="compact" /></v-col>
          <v-col cols="12"><v-textarea v-model="vForm.description" label="Description" rows="2" /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="violationDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveViolation">Save</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- Drug test dialog -->
  <v-dialog v-model="drugDialog" max-width="560">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-flask-outline">Add Drug Test</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12"><v-select v-model="dForm.test_type" :items="drugTestTypes" item-title="label" item-value="value" label="Test Type" /></v-col>
          <v-col cols="6"><v-text-field v-model="dForm.test_date" type="date" label="Test Date" /></v-col>
          <v-col cols="6"><v-select v-model="dForm.result" :items="drugResults" item-title="label" item-value="value" label="Result" /></v-col>
          <v-col cols="12"><v-text-field v-model="dForm.lab_name" label="Lab Name" /></v-col>
          <v-col cols="12"><v-text-field v-model="dForm.chain_of_custody" label="Chain of Custody #" /></v-col>
          <v-col cols="12"><v-textarea v-model="dForm.notes" label="Notes" rows="2" /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="drugDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveDrug">Save</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- Training dialog -->
  <v-dialog v-model="trainingDialog" max-width="560">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-school-outline">Add Training</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12"><v-text-field v-model="tForm.course_name" label="Course Name" /></v-col>
          <v-col cols="6"><v-text-field v-model="tForm.provider" label="Provider" /></v-col>
          <v-col cols="6"><v-select v-model="tForm.status" :items="trainingStatuses" item-title="label" item-value="value" label="Status" /></v-col>
          <v-col cols="6"><v-text-field v-model="tForm.completion_date" type="date" label="Completion Date" /></v-col>
          <v-col cols="6"><v-text-field v-model="tForm.expiry_date" type="date" label="Expiry Date" /></v-col>
          <v-col cols="4"><v-text-field v-model="tForm.score" type="number" label="Score %" /></v-col>
          <v-col cols="4"><v-text-field v-model="tForm.hours" type="number" label="Hours" /></v-col>
          <v-col cols="4"><v-text-field v-model="tForm.certificate_number" label="Cert #" /></v-col>
          <v-col cols="12"><v-textarea v-model="tForm.notes" label="Notes" rows="2" /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="trainingDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveTraining">Save</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- HOS dialog -->
  <v-dialog v-model="hosDialog" max-width="560">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-clock-outline">Add HOS Entry</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6"><v-text-field v-model="hForm.date" type="date" label="Date" /></v-col>
          <v-col cols="6"><v-select v-model="hForm.duty_status" :items="dutyStatuses" item-title="label" item-value="value" label="Duty Status" /></v-col>
          <v-col cols="6"><v-text-field v-model="hForm.hours" type="number" label="Hours" /></v-col>
          <v-col cols="6"><v-text-field v-model="hForm.driving_hours" type="number" label="Driving Hours" /></v-col>
          <v-col cols="6"><v-text-field v-model="hForm.on_duty_hours" type="number" label="On Duty Hours" /></v-col>
          <v-col cols="6"><v-text-field v-model="hForm.cycle_hours" type="number" label="Cycle Hours" /></v-col>
          <v-col cols="12"><v-text-field v-model="hForm.location" label="Location" /></v-col>
          <v-col cols="12"><v-text-field v-model="hForm.vehicle" label="Vehicle" /></v-col>
          <v-col cols="12"><v-textarea v-model="hForm.notes" label="Notes" rows="2" /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="hosDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveHos">Save</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- Assignment dialog -->
  <v-dialog v-model="assignmentDialog" max-width="500">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-car-connected">Assign Vehicle</AppModalHeader>
      <v-card-text>
        <v-select v-model="aForm.vehicle" :items="vehicles" item-title="label" item-value="id" label="Vehicle" class="mb-3" />
        <v-text-field v-model="aForm.notes" label="Notes" />
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="assignmentDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveAssignment">Assign</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- Note dialog -->
  <v-dialog v-model="noteDialog" max-width="500">
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-note-text-outline">Add Note</AppModalHeader>
      <v-card-text>
        <v-select v-model="nForm.category" :items="noteCategories" item-title="label" item-value="value" label="Category" class="mb-3" />
        <v-textarea v-model="nForm.body" label="Note" rows="3" />
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="noteDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveNote">Save</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- Hire rate dialog -->
  <v-dialog v-model="hireDialog" max-width="820" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-account-cash-outline">{{ hireEditing ? 'Edit Hire Rate Plan' : 'New Customer Hire Rate' }}</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="12" md="6"><v-text-field v-model="hireForm.name" label="Plan Name" /></v-col>
          <v-col cols="12" md="6"><v-select v-model="hireForm.default_rate_period" :items="hirePeriodOpts" item-title="label" item-value="value" label="Default Billing Period" /></v-col>
          <v-col cols="12" md="6"><v-select v-model="hireForm.status" :items="hireStatusOpts" item-title="label" item-value="value" label="Status" /></v-col>
          <v-col cols="12"><v-textarea v-model="hireForm.description" label="Notes" rows="2" /></v-col>
        </v-row>
        <p class="text-subtitle-2 font-weight-medium mt-3 mb-2" style="color: #475569">Base Rates</p>
        <v-row dense>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.hourly_rate" type="number" label="Hourly" density="compact" /></v-col>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.daily_rate" type="number" label="Daily" density="compact" /></v-col>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.weekly_rate" type="number" label="Weekly" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.monthly_rate" type="number" label="Monthly" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.weekend_rate" type="number" label="Weekend" density="compact" /></v-col>
        </v-row>
        <v-alert type="info" variant="tonal" density="compact" class="mt-3" v-if="hireHasAnyRate">
          <div class="d-flex flex-wrap ga-3">
            <div v-if="Number(hireForm.hourly_rate) > 0" class="d-flex align-center ga-1">
              <v-chip size="x-small" variant="flat" color="primary">Hourly</v-chip>
              <span class="text-caption">{{ hireEffRate('hourly') }}</span>
            </div>
            <div v-if="Number(hireForm.daily_rate) > 0" class="d-flex align-center ga-1">
              <v-chip size="x-small" variant="flat" color="primary">Daily</v-chip>
              <span class="text-caption">{{ hireEffRate('daily') }}</span>
            </div>
            <div v-if="Number(hireForm.weekly_rate) > 0" class="d-flex align-center ga-1">
              <v-chip size="x-small" variant="flat" color="primary">Weekly</v-chip>
              <span class="text-caption">{{ hireEffRate('weekly') }}</span>
            </div>
            <div v-if="Number(hireForm.monthly_rate) > 0" class="d-flex align-center ga-1">
              <v-chip size="x-small" variant="flat" color="primary">Monthly</v-chip>
              <span class="text-caption">{{ hireEffRate('monthly') }}</span>
            </div>
            <div v-if="Number(hireForm.weekend_rate) > 0" class="d-flex align-center ga-1">
              <v-chip size="x-small" variant="flat" color="primary">Weekend</v-chip>
              <span class="text-caption">{{ hireEffRate('weekend') }}</span>
            </div>
          </div>
          <p class="text-caption text-medium-emphasis mt-1">Effective = base × (1 − disc%) × (1 + markup%)</p>
        </v-alert>
        <p class="text-subtitle-2 font-weight-medium mt-3 mb-2" style="color: #475569">Discounts (%)</p>
        <v-row dense>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.hourly_discount_percent" type="number" label="Hr %" density="compact" /></v-col>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.daily_discount_percent" type="number" label="Day %" density="compact" /></v-col>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.weekly_discount_percent" type="number" label="Wk %" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.monthly_discount_percent" type="number" label="Mo %" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.weekend_discount_percent" type="number" label="Wend %" density="compact" /></v-col>
          <v-col cols="12" md="6"><v-text-field v-model="hireForm.discount_flat_amount" type="number" label="Flat Discount Amount" density="compact" /></v-col>
        </v-row>
        <p class="text-subtitle-2 font-weight-medium mt-3 mb-2" style="color: #475569">Markups (%)</p>
        <v-row dense>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.hourly_markup_percent" type="number" label="Hr %" density="compact" /></v-col>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.daily_markup_percent" type="number" label="Day %" density="compact" /></v-col>
          <v-col cols="6" md="2"><v-text-field v-model="hireForm.weekly_markup_percent" type="number" label="Wk %" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.monthly_markup_percent" type="number" label="Mo %" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.weekend_markup_percent" type="number" label="Wend %" density="compact" /></v-col>
          <v-col cols="12" md="6"><v-text-field v-model="hireForm.markup_flat_amount" type="number" label="Flat Markup Amount" density="compact" /></v-col>
        </v-row>
        <v-row dense class="mt-2">
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.security_deposit" type="number" label="Security Deposit" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.tax_percent" type="number" label="Tax %" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.valid_from" type="date" label="Valid From" density="compact" /></v-col>
          <v-col cols="6" md="3"><v-text-field v-model="hireForm.valid_to" type="date" label="Valid To" density="compact" /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="hireDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveHireRate">{{ hireEditing ? 'Update' : 'Create' }}</v-btn></v-card-actions>
    </v-card>
  </v-dialog>

  <!-- Driver profile edit dialog -->
  <v-dialog v-model="profileDialog" max-width="700" scrollable>
    <v-card rounded="xl">
      <AppModalHeader icon="mdi-account-edit-outline">Edit Driver Profile</AppModalHeader>
      <v-card-text>
        <v-row dense>
          <v-col cols="6"><v-text-field v-model="pForm.license_number" label="License Number" /></v-col>
          <v-col cols="6"><v-select v-model="pForm.license_class" :items="licenseClasses" item-title="label" item-value="value" label="License Class" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.license_state" label="License State" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.license_expiry" type="date" label="License Expiry" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.medical_card_number" label="Medical Card #" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.medical_card_expiry" type="date" label="Medical Card Expiry" /></v-col>
          <v-col cols="6"><v-select v-model="pForm.mvr_status" :items="mvrStatuses" item-title="label" item-value="value" label="MVR Status" /></v-col>
          <v-col cols="6"><v-select v-model="pForm.employment_status" :items="employmentStatuses" item-title="label" item-value="value" label="Employment Status" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.mvr_last_checked" type="date" label="MVR Last Checked" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.mvr_next_due" type="date" label="MVR Next Due" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.hire_date" type="date" label="Hire Date" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.termination_date" type="date" label="Termination Date" /></v-col>
          <v-col cols="6"><v-select v-model="pForm.license_endorsements" :items="endorsementOptions" item-title="label" item-value="value" label="Endorsements" multiple chips /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.home_terminal" label="Home Terminal" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.pay_rate" type="number" label="Pay Rate" /></v-col>
          <v-col cols="6"><v-select v-model="pForm.pay_type" :items="payTypes" label="Pay Type" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.emergency_contact_name" label="Emergency Contact" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.emergency_contact_phone" label="Emergency Phone" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.emergency_contact_relation" label="Relationship" /></v-col>
          <v-col cols="6"><v-text-field v-model="pForm.blood_type" label="Blood Type" /></v-col>
        </v-row>
      </v-card-text>
      <v-card-actions class="px-4 pb-4"><v-spacer /><v-btn variant="text" @click="profileDialog = false">Cancel</v-btn><v-btn color="primary" :loading="saving" @click="saveProfile">Save</v-btn></v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { $api } = useNuxtApp()
const { resolveMediaUrl } = useMediaUrl()
const route = useRoute()
const id = computed(() => route.params.id as string)

const tab = ref('profile')
const pending = ref(true)
const saving = ref(false)
const driver = ref<any>(null)
const dp = computed(() => driver.value?.driver_profile)
const vehicles = ref<any[]>([])
const hireRates = ref<any[]>([])
const customers = ref<any[]>([])

const tabs = computed(() => [
  { value: 'profile', label: 'Profile', icon: 'mdi-account-circle-outline', count: null },
  { value: 'license', label: 'License & Medical', icon: 'mdi-card-bulleted-outline', count: null },
  { value: 'violations', label: 'Violations', icon: 'mdi-shield-alert-outline', count: dp.value?.violations?.length ?? 0 },
  { value: 'drug', label: 'Drug Tests', icon: 'mdi-flask-outline', count: dp.value?.drug_tests?.length ?? 0 },
  { value: 'training', label: 'Training', icon: 'mdi-school-outline', count: dp.value?.trainings?.length ?? 0 },
  { value: 'hos', label: 'HOS Logs', icon: 'mdi-clock-outline', count: dp.value?.hos_logs?.length ?? 0 },
  { value: 'assignments', label: 'Assignments', icon: 'mdi-car-connected', count: dp.value?.assignments?.length ?? 0 },
  { value: 'hire', label: 'Hire Rates', icon: 'mdi-account-cash-outline', count: hireRates.value.length },
  { value: 'documents', label: 'Documents', icon: 'mdi-file-document-multiple-outline', count: documents.value.length },
  { value: 'notes', label: 'Notes', icon: 'mdi-note-text-outline', count: dp.value?.notes_log?.length ?? 0 },
])

// ---- Data ----
async function load() {
  pending.value = true
  try {
    driver.value = await $api(`/contacts/drivers/${id.value}/`)
  } catch (e) { console.error(e) } finally { pending.value = false }
}
onMounted(() => { load(); loadVehicles(); loadDocuments(); loadHireRates() })

async function loadHireRates() {
  try {
    const data = await $api(`/rentals/driver-hire-rates/?driver=${id.value}&page_size=1000`)
    hireRates.value = data?.results || data || []
  } catch { hireRates.value = [] }
}

async function loadCustomers() {
  try {
    const data = await $api('/rentals/customers/?page_size=1000')
    customers.value = data?.results || data || []
  } catch { customers.value = [] }
}

// ---- Hire Rates state ----
const hireHeaders = [
  { title: 'Plan', key: 'plan_name', sortable: true },
  { title: 'Base Rates', key: 'rates', sortable: false, width: '280px' },
  { title: 'Effective Rates', key: 'effective_rates', sortable: false, width: '280px' },
  { title: 'Period', key: 'default_rate_period', width: '100px', sortable: true },
  { title: 'Status', key: 'status', width: '110px', sortable: true },
  { title: 'Valid', key: 'valid_from', width: '140px', sortable: true },
  { title: '', key: 'actions', width: '90px', sortable: false },
]
const hireStatusOpts = [
  { label: 'Active', value: 'active' }, { label: 'Inactive', value: 'inactive' }, { label: 'Expired', value: 'expired' },
]
const hirePeriodOpts = [
  { label: 'Hourly', value: 'hourly' }, { label: 'Daily', value: 'daily' },
  { label: 'Weekly', value: 'weekly' }, { label: 'Monthly', value: 'monthly' }, { label: 'Weekend', value: 'weekend' },
]
function hireStatusColor(s: string) { return { active: 'success', inactive: 'default', expired: 'error' }[s] || 'default' }

const hireDialog = ref(false)
const hireEditing = ref(false)
const defaultHireForm = () => ({
  id: null, name: '', description: '', default_rate_period: 'daily',
  hourly_rate: 0, daily_rate: 0, weekly_rate: 0, monthly_rate: 0, weekend_rate: 0,
  hourly_discount_percent: 0, daily_discount_percent: 0, weekly_discount_percent: 0, monthly_discount_percent: 0, weekend_discount_percent: 0,
  hourly_markup_percent: 0, daily_markup_percent: 0, weekly_markup_percent: 0, monthly_markup_percent: 0, weekend_markup_percent: 0,
  markup_flat_amount: 0, discount_flat_amount: 0,
  security_deposit: 0, tax_percent: 0,
  valid_from: '', valid_to: '', status: 'active', is_default: false,
})
const hireForm = reactive<any>(defaultHireForm())

// ---- Auto-calc helpers for hire form ----
const hireUserEdited = reactive({ weekly: false, monthly: false, weekend: false })
let hireSkipWatch = false

function hireRound2(n: number): number {
  return Math.round(n * 100) / 100
}

// Auto-fill weekly/monthly/weekend when daily changes
watch(() => Number(hireForm.daily_rate), (d) => {
  if (d > 0) {
    hireSkipWatch = true
    if (!hireUserEdited.weekly) hireForm.weekly_rate = hireRound2(d * 7)
    if (!hireUserEdited.monthly) hireForm.monthly_rate = hireRound2(d * 30)
    if (!hireUserEdited.weekend) hireForm.weekend_rate = hireRound2(d * 2)
    nextTick(() => { hireSkipWatch = false })
  }
})

// When user manually edits weekly/monthly/weekend, mark as user-edited
watch(() => hireForm.weekly_rate, () => { if (!hireSkipWatch) hireUserEdited.weekly = true })
watch(() => hireForm.monthly_rate, () => { if (!hireSkipWatch) hireUserEdited.monthly = true })
watch(() => hireForm.weekend_rate, () => { if (!hireSkipWatch) hireUserEdited.weekend = true })

// Live effective rate preview
const hireHasAnyRate = computed(() =>
  Number(hireForm.hourly_rate) > 0 ||
  Number(hireForm.daily_rate) > 0 ||
  Number(hireForm.weekly_rate) > 0 ||
  Number(hireForm.monthly_rate) > 0 ||
  Number(hireForm.weekend_rate) > 0
)

function hireEffRate(period: string): string {
  const base = Number(hireForm[`${period}_rate`] || 0)
  if (base <= 0) return '0'
  const disc = Number(hireForm[`${period}_discount_percent`] || 0)
  const markup = Number(hireForm[`${period}_markup_percent`] || 0)
  const after = base * (1 - disc / 100) * (1 + markup / 100)
  return hireRound2(after).toFixed(2)
}

function openHireDialog(item?: any) {
  if (item) {
    hireEditing.value = true
    Object.assign(hireForm, defaultHireForm(), item)
  } else {
    hireEditing.value = false
    Object.assign(hireForm, defaultHireForm())
    hireForm.driver = Number(id.value)
  }
  hireUserEdited.weekly = false
  hireUserEdited.monthly = false
  hireUserEdited.weekend = false
  hireDialog.value = true
}

async function saveHireRate() {
  if (!hireForm.name) { alert('Please enter a plan name.'); return }
  saving.value = true
  try {
    const body = { ...hireForm, driver: Number(id.value) }
    // Convert empty strings to null for date fields (DRF rejects '')
    if (!body.valid_from) body.valid_from = null
    if (!body.valid_to) body.valid_to = null
    if (hireEditing.value) {
      await $api(`/rentals/driver-hire-rates/${hireForm.id}/`, { method: 'PUT', body })
    } else {
      delete body.id
      await $api('/rentals/driver-hire-rates/', { method: 'POST', body })
    }
    hireDialog.value = false
    await loadHireRates()
  } catch (e: any) {
    console.error(e)
    alert('Failed to save hire rate. ' + JSON.stringify(e?.data || e?.message || e))
  } finally { saving.value = false }
}

async function deleteHireRate(item: any) {
  if (!confirm('Delete this hire rate plan?')) return
  try {
    await $api(`/rentals/driver-hire-rates/${item.id}/`, { method: 'DELETE' })
    await loadHireRates()
  } catch (e) { console.error(e); alert('Delete failed.') }
}

async function loadVehicles() {
  try {
    const data = await $api('/vehicles/vehicles/', { query: { page_size: 1000 } })
    const rows = data?.results || data || []
    vehicles.value = rows.map((v: any) => ({ id: v.id, label: v.unit_number ? `${v.unit_number} — ${v.vin || ''}` : (v.vin || `#${v.id}`) }))
  } catch {}
}

const initials = computed(() => {
  const d = driver.value
  return d ? ((d.first_name?.[0] || '') + (d.last_name?.[0] || '')).toUpperCase() : '?'
})
const avatarColor = computed(() => {
  const colors = ['#e0e7ff', '#dcfce7', '#fef9c3', '#fee2e2', '#f3e8ff', '#cffafe']
  const idx = (driver.value?.first_name?.charCodeAt(0) || 0) % colors.length
  return colors[idx]
})
const fullAddress = computed(() => {
  const d = driver.value
  if (!d) return ''
  return [d.address, d.city, d.state, d.zip_code, d.country].filter(Boolean).join(', ')
})

// ---- Options ----
const employmentStatuses = [
  { label: 'Active', value: 'active' }, { label: 'On Leave', value: 'on_leave' },
  { label: 'Suspended', value: 'suspended' }, { label: 'Terminated', value: 'terminated' },
  { label: 'Probation', value: 'probation' },
]
const mvrStatuses = [
  { label: 'Clean', value: 'clean' }, { label: 'Warning', value: 'warning' },
  { label: 'Suspended', value: 'suspended' }, { label: 'Expired', value: 'expired' },
]
const licenseClasses = [
  { label: 'Class A', value: 'A' }, { label: 'Class B', value: 'B' }, { label: 'Class C', value: 'C' },
  { label: 'CDL-A', value: 'CDL-A' }, { label: 'CDL-B', value: 'CDL-B' }, { label: 'Class M', value: 'M' },
]
const endorsementOptions = [
  { label: 'Hazmat (H)', value: 'hazmat' }, { label: 'Tanker (N)', value: 'tanker' },
  { label: 'Passenger (P)', value: 'passenger' }, { label: 'School Bus (S)', value: 'school_bus' },
  { label: 'Air Brake (L)', value: 'airbrake' }, { label: 'Tanker + Hazmat (X)', value: 'comb_tanker_hazmat' },
]
const payTypes = ['hourly', 'mileage', 'salary', 'percentage']
const violationTypes = [
  { label: 'Speeding', value: 'speeding' }, { label: 'Reckless Driving', value: 'reckless' },
  { label: 'DUI / DWI', value: 'dui' }, { label: 'Following Too Close', value: 'following' },
  { label: 'Improper Lane Change', value: 'lane' }, { label: 'Equipment Violation', value: 'equipment' },
  { label: 'Accident', value: 'accident' }, { label: 'Other', value: 'other' },
]
const severityOptions = [{ label: 'Minor', value: 'minor' }, { label: 'Major', value: 'major' }, { label: 'Critical', value: 'critical' }]
const drugTestTypes = [
  { label: 'Pre-Employment', value: 'pre_employment' }, { label: 'Random', value: 'random' },
  { label: 'Post-Accident', value: 'post_accident' }, { label: 'Reasonable Suspicion', value: 'reasonable_suspicion' },
  { label: 'Return to Duty', value: 'return_to_duty' }, { label: 'Follow-Up', value: 'follow_up' },
]
const drugResults = [
  { label: 'Negative', value: 'negative' }, { label: 'Positive', value: 'positive' },
  { label: 'Refused', value: 'refused' }, { label: 'Pending', value: 'pending' },
]
const trainingStatuses = [
  { label: 'Scheduled', value: 'scheduled' }, { label: 'In Progress', value: 'in_progress' },
  { label: 'Completed', value: 'completed' }, { label: 'Expired', value: 'expired' }, { label: 'Failed', value: 'failed' },
]
const dutyStatuses = [
  { label: 'Off Duty', value: 'off_duty' }, { label: 'Sleeper Berth', value: 'sleeper' },
  { label: 'Driving', value: 'driving' }, { label: 'On Duty (Not Driving)', value: 'on_duty' },
]
const noteCategories = [
  { label: 'General', value: 'general' }, { label: 'Performance', value: 'performance' },
  { label: 'Incident', value: 'incident' }, { label: 'Commendation', value: 'commendation' },
  { label: 'Warning', value: 'warning' }, { label: 'Other', value: 'other' },
]

// ---- Table headers ----
const violationHeaders = [
  { title: 'Type', key: 'violation_type_label', sortable: true },
  { title: 'Severity', key: 'severity', width: '100px' },
  { title: 'Date', key: 'date', width: '120px' },
  { title: 'State', key: 'state', width: '80px' },
  { title: 'Points', key: 'points', width: '80px' },
  { title: 'Fine', key: 'fine_amount', width: '100px' },
  { title: 'Paid', key: 'paid', width: '80px' },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const drugHeaders = [
  { title: 'Type', key: 'test_type_label', sortable: true },
  { title: 'Date', key: 'test_date', width: '120px' },
  { title: 'Result', key: 'result', width: '120px' },
  { title: 'Lab', key: 'lab_name' },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const trainingHeaders = [
  { title: 'Course', key: 'course_name', sortable: true },
  { title: 'Provider', key: 'provider' },
  { title: 'Status', key: 'status', width: '120px' },
  { title: 'Completed', key: 'completion_date', width: '120px' },
  { title: 'Expires', key: 'expiry_date', width: '120px' },
  { title: 'Score', key: 'score', width: '80px' },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const hosHeaders = [
  { title: 'Date', key: 'date', sortable: true },
  { title: 'Status', key: 'duty_status', width: '140px' },
  { title: 'Hours', key: 'hours', width: '80px' },
  { title: 'Driving', key: 'driving_hours', width: '90px' },
  { title: 'On Duty', key: 'on_duty_hours', width: '90px' },
  { title: 'Cycle', key: 'cycle_hours', width: '80px' },
  { title: 'Location', key: 'location' },
  { title: '', key: 'actions', width: '60px', sortable: false },
]
const assignmentHeaders = [
  { title: 'Vehicle', key: 'vehicle_label', sortable: true },
  { title: 'Assigned', key: 'assigned_at', width: '160px' },
  { title: 'Released', key: 'unassigned_at', width: '160px' },
  { title: 'Status', key: 'is_active', width: '100px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]
const docHeaders = [
  { title: 'Document', key: 'title', sortable: true },
  { title: 'Type', key: 'document_type', width: '120px' },
  { title: 'Size', key: 'file_size', width: '90px' },
  { title: 'Expiry', key: 'expiry_date', width: '120px' },
  { title: 'Uploaded', key: 'created_at', width: '140px' },
  { title: '', key: 'actions', width: '100px', sortable: false },
]

// ---- Color helpers ----
function employmentColor(s?: string) { return { active: 'success', on_leave: 'info', suspended: 'warning', terminated: 'grey', probation: 'amber' }[s || ''] || 'grey' }
function mvrColor(s?: string) { return { clean: 'success', warning: 'warning', suspended: 'error', expired: 'grey' }[s || ''] || 'grey' }
function severityColor(s: string) { return { minor: 'info', major: 'warning', critical: 'error' }[s] || 'grey' }
function drugResultColor(s: string) { return { negative: 'success', positive: 'error', refused: 'error', pending: 'warning' }[s] || 'grey' }
function trainingStatusColor(s: string) { return { scheduled: 'info', in_progress: 'warning', completed: 'success', expired: 'grey', failed: 'error' }[s] || 'grey' }
function hosColor(s: string) { return { off_duty: 'grey', sleeper: 'info', driving: 'success', on_duty: 'warning' }[s] || 'grey' }
function noteColor(c: string) { return { general: 'grey', performance: 'primary', incident: 'error', commendation: 'success', warning: 'warning', other: 'info' }[c] || 'grey' }
function noteIcon(c: string) { return { general: 'mdi-note-text', performance: 'mdi-chart-line', incident: 'mdi-alert', commendation: 'mdi-medal', warning: 'mdi-alert', other: 'mdi-information' }[c] || 'mdi-note-text' }
function expiryClass(dateStr?: string) {
  if (!dateStr) return ''
  const d = new Date(dateStr); const now = new Date()
  const days = (d.getTime() - now.getTime()) / 86400000
  if (days < 0) return 'text-error font-weight-medium'
  if (days < 30) return 'text-warning font-weight-medium'
  return ''
}
function formatEndorsements(list?: any) {
  if (!list || !list?.length) return '—'
  return (Array.isArray(list) ? list : []).map((e: string) => endorsementOptions.find(o => o.value === e)?.label || e).join(', ')
}
function formatDate(d: string) {
  return d ? new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : ''
}

// ---- Violations ----
const violationDialog = ref(false)
const defaultVForm = () => ({ violation_type: 'speeding', severity: 'minor', date: new Date().toISOString().slice(0, 10), state: '', points: 0, fine_amount: 0, paid: false, description: '', driver_profile: null })
const vForm = reactive<any>(defaultVForm())
function openViolationDialog() { Object.assign(vForm, defaultVForm()); vForm.driver_profile = dp.value?.id; violationDialog.value = true }
async function saveViolation() {
  saving.value = true
  try { await $api('/contacts/violations/', { method: 'POST', body: vForm }); violationDialog.value = false; await load() }
  catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteViolation(v: any) { if (!confirm('Delete this violation?')) return; await $api(`/contacts/violations/${v.id}/`, { method: 'DELETE' }); await load() }

// ---- Drug tests ----
const drugDialog = ref(false)
const defaultDForm = () => ({ test_type: 'pre_employment', test_date: new Date().toISOString().slice(0, 10), result: 'pending', lab_name: '', chain_of_custody: '', notes: '', driver_profile: null })
const dForm = reactive<any>(defaultDForm())
function openDrugDialog() { Object.assign(dForm, defaultDForm()); dForm.driver_profile = dp.value?.id; drugDialog.value = true }
async function saveDrug() {
  saving.value = true
  try { await $api('/contacts/drug-tests/', { method: 'POST', body: dForm }); drugDialog.value = false; await load() }
  catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteDrug(d: any) { if (!confirm('Delete this test?')) return; await $api(`/contacts/drug-tests/${d.id}/`, { method: 'DELETE' }); await load() }

// ---- Training ----
const trainingDialog = ref(false)
const defaultTForm = () => ({ course_name: '', provider: '', status: 'scheduled', completion_date: '', expiry_date: '', score: null, hours: 0, certificate_number: '', notes: '', driver_profile: null })
const tForm = reactive<any>(defaultTForm())
function openTrainingDialog() { Object.assign(tForm, defaultTForm()); tForm.driver_profile = dp.value?.id; trainingDialog.value = true }
async function saveTraining() {
  saving.value = true
  try { await $api('/contacts/trainings/', { method: 'POST', body: tForm }); trainingDialog.value = false; await load() }
  catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteTraining(t: any) { if (!confirm('Delete this training?')) return; await $api(`/contacts/trainings/${t.id}/`, { method: 'DELETE' }); await load() }

// ---- HOS ----
const hosDialog = ref(false)
const defaultHForm = () => ({ date: new Date().toISOString().slice(0, 10), duty_status: 'driving', hours: 0, driving_hours: 0, on_duty_hours: 0, cycle_hours: 0, location: '', vehicle: '', notes: '', driver_profile: null })
const hForm = reactive<any>(defaultHForm())
function openHosDialog() { Object.assign(hForm, defaultHForm()); hForm.driver_profile = dp.value?.id; hosDialog.value = true }
async function saveHos() {
  saving.value = true
  try { await $api('/contacts/hos/', { method: 'POST', body: hForm }); hosDialog.value = false; await load() }
  catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteHos(h: any) { if (!confirm('Delete this HOS entry?')) return; await $api(`/contacts/hos/${h.id}/`, { method: 'DELETE' }); await load() }

// ---- Assignments ----
const assignmentDialog = ref(false)
const defaultAForm = () => ({ vehicle: null, notes: '', driver_profile: null })
const aForm = reactive<any>(defaultAForm())
function openAssignmentDialog() { Object.assign(aForm, defaultAForm()); aForm.driver_profile = dp.value?.id; assignmentDialog.value = true }
async function saveAssignment() {
  saving.value = true
  try { await $api('/contacts/assignments/', { method: 'POST', body: aForm }); assignmentDialog.value = false; await load() }
  catch (e) { console.error(e) } finally { saving.value = false }
}
async function releaseAssignment(a: any) { await $api(`/contacts/assignments/${a.id}/release/`, { method: 'POST' }); await load() }
async function deleteAssignment(a: any) { if (!confirm('Delete this assignment?')) return; await $api(`/contacts/assignments/${a.id}/`, { method: 'DELETE' }); await load() }

// ---- Documents ----
const documents = ref<any[]>([])
const docDialog = ref(false)
const docTypes = [
  { label: 'Driving License', value: 'license' },
  { label: 'National ID', value: 'other' },
  { label: 'Medical Card', value: 'medical_card' },
  { label: 'Insurance', value: 'insurance' },
  { label: 'Other', value: 'other' },
]
const defaultDocForm = () => ({ document_type: 'license', title: '', file: null as File | null, expiry_date: '' })
const docForm = reactive<any>(defaultDocForm())

async function loadDocuments() {
  try {
    const data = await $api('/documents/', { query: { contact: id.value, page_size: 1000 } })
    documents.value = data?.results || data || []
  } catch (e) { console.error(e) }
}
function openDocDialog() { Object.assign(docForm, defaultDocForm()); docDialog.value = true }
function onDocFile(f: File) { docForm.file = f; if (!docForm.title) docForm.title = f.name.replace(/\.[^.]+$/, '') }
function removeDocFile() { docForm.file = null }
async function uploadDoc() {
  if (!docForm.file) return
  saving.value = true
  try {
    const fd = new FormData()
    fd.append('contact', String(id.value))
    fd.append('document_type', docForm.document_type || 'license')
    fd.append('title', docForm.title || docForm.file.name)
    fd.append('file', docForm.file)
    if (docForm.expiry_date) fd.append('expiry_date', docForm.expiry_date)
    await $api('/documents/', { method: 'POST', body: fd })
    docDialog.value = false
    await loadDocuments()
  } catch (e) { console.error(e) } finally { saving.value = false }
}
async function deleteDoc(d: any) { if (!confirm(`Delete document "${d.title}"?`)) return; await $api(`/documents/${d.id}/`, { method: 'DELETE' }); await loadDocuments() }
function docIcon(d: any) {
  const name = (d.file || d.title || '').toLowerCase()
  if (/\.(jpg|jpeg|png|gif|webp)$/.test(name)) return 'mdi-file-image-outline'
  if (/\.pdf$/.test(name)) return 'mdi-file-pdf-box-outline'
  return 'mdi-file-document-outline'
}
function docIconColor(d: any) {
  const name = (d.file || d.title || '').toLowerCase()
  if (/\.(jpg|jpeg|png|gif|webp)$/.test(name)) return 'info'
  if (/\.pdf$/.test(name)) return 'error'
  return 'primary'
}
function docTypeColor(t: string) { return { license: 'blue', medical_card: 'success', insurance: 'purple', other: 'grey' }[t] || 'grey' }
function formatSize(bytes?: number | null) {
  if (!bytes) return '—'
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

// ---- Notes ----
const noteDialog = ref(false)
const defaultNForm = () => ({ category: 'general', body: '', driver_profile: null })
const nForm = reactive<any>(defaultNForm())
function openNoteDialog() { Object.assign(nForm, defaultNForm()); nForm.driver_profile = dp.value?.id; noteDialog.value = true }
async function saveNote() {
  saving.value = true
  try { await $api('/contacts/notes/', { method: 'POST', body: nForm }); noteDialog.value = false; await load() }
  catch (e) { console.error(e) } finally { saving.value = false }
}

// ---- Profile edit ----
const profileDialog = ref(false)
const defaultPForm = () => ({ license_number: '', license_class: '', license_state: '', license_expiry: '', medical_card_number: '', medical_card_expiry: '', mvr_status: 'clean', employment_status: 'active', mvr_last_checked: '', mvr_next_due: '', hire_date: '', termination_date: '', license_endorsements: [], home_terminal: '', pay_rate: 0, pay_type: 'hourly', emergency_contact_name: '', emergency_contact_phone: '', emergency_contact_relation: '', blood_type: '', id: null })
const pForm = reactive<any>(defaultPForm())
function openProfileEdit() {
  Object.assign(pForm, defaultPForm())
  if (dp.value) {
    Object.keys(pForm).forEach(k => { if (dp.value[k] !== undefined && dp.value[k] !== null) pForm[k] = dp.value[k] })
    pForm.id = dp.value.id
    pForm.license_endorsements = dp.value.license_endorsements || []
  }
  profileDialog.value = true
}
async function saveProfile() {
  saving.value = true
  try {
    await $api(`/contacts/profiles/${pForm.id}/`, { method: 'PATCH', body: pForm })
    profileDialog.value = false; await load()
  } catch (e) { console.error(e) } finally { saving.value = false }
}

// ---- Navigation ----
function goBack() { navigateTo('/app/drivers') }
function goEdit() { navigateTo(`/app/drivers/${id.value}/edit`) }
async function deleteDriver() {
  if (!confirm(`Delete driver ${driver.value?.full_name}?`)) return
  await $api(`/contacts/drivers/${id.value}/`, { method: 'DELETE' }); navigateTo('/app/drivers')
}
</script>

<style scoped lang="scss">
.page-header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
}
.page-header-title {
  color: #0f172a;
  letter-spacing: -0.01em;
}
.driver-avatar-lg {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  flex-shrink: 0;
}
.driver-avatar-lg img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.driver-avatar-lg span {
  font-size: 18px;
  font-weight: 700;
  color: #4338ca;
}
.drivers-tabs-wrap {
  position: sticky;
  top: 0;
  z-index: 10;
  padding: 4px;
  background: rgb(255 255 255 / 80%);
  backdrop-filter: blur(8px);
  border-radius: 16px;
}
.drivers-tabs {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  box-shadow: inset 0 1px 2px rgb(15 23 42 / 4%);
  flex-wrap: wrap;
}
.drivers-tab {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 9px 16px;
  border: 0;
  background: transparent;
  border-radius: 10px;
  color: #64748b;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: color 0.25s ease, background 0.25s ease, box-shadow 0.25s ease, transform 0.18s ease;
}
.drivers-tab:hover { color: #334155; background: rgb(255 255 255 / 70%); }
.drivers-tab--active {
  color: #fff;
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  box-shadow: 0 6px 16px rgb(99 102 241 / 35%), inset 0 1px 0 rgb(255 255 255 / 20%);
  transform: translateY(-1px);
}
.drivers-tab--active:hover { color: #fff; background: linear-gradient(135deg, #6366f1, #4f46e5); }
.drivers-tab__count {
  min-width: 22px;
  padding: 1px 8px;
  border-radius: 999px;
  background: rgb(15 23 42 / 8%);
  font-size: 11px;
  font-weight: 700;
}
.drivers-tab--active .drivers-tab__count { background: rgb(255 255 255 / 25%); }
.drivers-window :deep(.v-window__container) { transition: none; }
.info-list :deep(.v-list-item) {
  padding-inline-start: 0;
}
</style>
