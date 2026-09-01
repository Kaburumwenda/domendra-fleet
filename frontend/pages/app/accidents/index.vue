<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between flex-wrap ga-2">
      <div>
        <h1 class="text-h5 font-weight-bold" style="color: #1e293b">Accident Management</h1>
        <p class="text-caption text-medium-emphasis">Track, investigate and resolve vehicle accidents with insurance claims</p>
      </div>
      <v-btn v-can="'accidents:create'" color="primary" prepend-icon="mdi-plus" size="small" @click="openCreate">Report Accident</v-btn>
    </div>

    <!-- Stat Cards -->
    <v-row dense>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4">
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-caption text-medium-emphasis mb-1">Total Accidents</p>
              <p class="text-h4 font-weight-bold" style="color: #1e293b">{{ stats.total || 0 }}</p>
              <p class="text-caption text-success">{{ stats.last_30_days || 0 }} in last 30 days</p>
            </div>
            <v-icon size="40" color="primary" class="opacity-70">mdi-car-emergency</v-icon>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4">
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-caption text-medium-emphasis mb-1">Serious / Fatal</p>
              <p class="text-h4 font-weight-bold text-error">{{ (stats.serious || 0) + (stats.fatal || 0) }}</p>
              <p class="text-caption text-medium-emphasis">{{ stats.fatal || 0 }} fatal</p>
            </div>
            <v-icon size="40" color="error" class="opacity-70">mdi-alert-octagon</v-icon>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4">
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-caption text-medium-emphasis mb-1">Total Damage</p>
              <p class="text-h4 font-weight-bold text-warning">{{ currencySymbol }}{{ Number(stats.total_damage_cost || 0).toLocaleString(undefined, { maximumFractionDigits: 0 }) }}</p>
              <p class="text-caption text-medium-emphasis">Est. repair costs</p>
            </div>
            <v-icon size="40" color="warning" class="opacity-70">mdi-currency-usd</v-icon>
          </div>
        </v-card>
      </v-col>
      <v-col cols="6" md="3">
        <v-card elevation="0" border rounded="lg" class="pa-4">
          <div class="d-flex align-center justify-space-between">
            <div>
              <p class="text-caption text-medium-emphasis mb-1">Insurance Claims</p>
              <p class="text-h4 font-weight-bold" style="color: #1e293b">{{ stats.claims_filed || 0 }} filed</p>
              <p class="text-caption text-success">{{ stats.claims_settled || 0 }} settled</p>
            </div>
            <v-icon size="40" color="info" class="opacity-70">mdi-shield-account</v-icon>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Filter Bar -->
    <div class="d-flex align-center ga-3 flex-wrap">
      <span class="text-body-2 text-medium-emphasis text-nowrap">Filter by type:</span>
      <v-select v-model="filterSeverity" :items="severityOpts" item-title="label" item-value="value" density="compact" variant="outlined" hide-details style="max-width: 150px" clearable placeholder="Severity" />
      <v-select v-model="filterStatus" :items="statusOpts" item-title="label" item-value="value" density="compact" variant="outlined" hide-details style="max-width: 180px" clearable placeholder="Status" />
      <v-text-field v-model="search" prepend-inner-icon="mdi-magnify" placeholder="Search accidents..." density="compact" variant="outlined" hide-details style="max-width: 280px" clearable />
      <v-spacer />
      <v-btn variant="text" size="small" prepend-icon="mdi-refresh" @click="refresh">Refresh</v-btn>
    </div>

    <!-- Data Table -->
    <v-card elevation="0" border rounded="lg">
      <v-data-table :headers="headers" :items="filteredAccidents" :loading="pending" hover :items-per-page="15" :items-per-page-options="[10, 15, 25, 50]">
        <template #item.vehicle_name="{ item }">
          <div class="d-flex align-center ga-2">
            <v-icon size="small" color="primary">mdi-truck</v-icon>
            <div>
              <p class="text-body-2 font-weight-medium">{{ item.vehicle_name || '—' }}</p>
              <p class="text-caption text-medium-emphasis">{{ item.driver_name || item.client_name || 'Unassigned' }}</p>
            </div>
          </div>
        </template>
        <template #item.date="{ value }">
          <div>
            <p class="text-body-2">{{ new Date(value).toLocaleDateString() }}</p>
            <p class="text-caption text-medium-emphasis">{{ new Date(value).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }}</p>
          </div>
        </template>
        <template #item.severity="{ value }">
          <v-chip :color="severityColor(value)" variant="flat" size="small" class="text-capitalize">
            <v-icon size="x-small" start>{{ severityIcon(value) }}</v-icon>
            {{ value }}
          </v-chip>
        </template>
        <template #item.status="{ value }">
          <v-chip :color="statusColor(value)" variant="tonal" size="small" class="text-capitalize">{{ statusLabel(value) }}</v-chip>
        </template>
        <template #item.weather="{ value }">
          <div class="d-flex align-center ga-1">
            <v-icon size="small" color="info">{{ weatherIcon(value) }}</v-icon>
            <span class="text-capitalize text-body-2">{{ value }}</span>
          </div>
        </template>
        <template #item.estimated_damage_cost="{ value }">
          <span class="text-body-2 font-weight-medium text-warning">{{ currencySymbol }}{{ Number(value || 0).toLocaleString() }}</span>
        </template>
        <template #item.has_claim="{ item }">
          <v-chip v-if="item.insurance_claim" :color="claimStatusColor(item.insurance_claim.status)" variant="tonal" size="small" class="text-capitalize">{{ claimStatusLabel(item.insurance_claim.status) }}</v-chip>
          <v-icon v-else size="small" color="medium-emphasis">mdi-minus</v-icon>
        </template>
        <template #item.location="{ value }">
          <span class="text-body-2 text-medium-emphasis" style="max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; display: inline-block">{{ value || '—' }}</span>
        </template>
        <template #item.actions="{ item }">
          <div class="d-flex ga-1">
            <v-btn icon="mdi-eye-outline" variant="text" size="small" @click="openView(item)" />
            <v-btn v-can="'accidents:update'" icon="mdi-pencil-outline" variant="text" size="small" @click="openEdit(item)" />
            <v-btn v-can="'accidents:delete'" icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="deleteAccident(item)" />
          </div>
        </template>
        <template #no-data>
          <div class="text-center py-12 text-medium-emphasis">
            <v-icon size="48" class="mb-3">mdi-car-emergency</v-icon>
            <p>No accident reports yet.</p>
            <v-btn v-can="'accidents:create'" color="primary" variant="text" size="small" class="mt-2" @click="openCreate">Report First Accident</v-btn>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Add / Edit Accident Dialog -->
    <v-dialog v-model="dialogVisible" max-width="900" scrollable>
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-car-emergency">{{ editing ? 'Edit Accident Report' : 'Report New Accident' }}</AppModalHeader>
        <v-card-text class="pt-4">
          <v-row dense>
            <!-- Vehicle & Driver/Client -->
            <v-col cols="12" md="6"><v-select v-model="form.vehicle" :items="vehicleOptions" item-title="display_name" item-value="id" label="Vehicle *" density="comfortable" :error-messages="errors.vehicle" /></v-col>
            <v-col cols="12" md="6">
              <div class="d-flex align-center ga-2 mb-2">
                <v-btn-toggle v-model="form.person_type" mandatory density="compact" color="primary" variant="outlined" divided>
                  <v-btn value="driver" size="x-small" prepend-icon="mdi-steering">Driver</v-btn>
                  <v-btn value="client" size="x-small" prepend-icon="mdi-account-outline">Client</v-btn>
                </v-btn-toggle>
              </div>
              <v-select v-if="form.person_type === 'driver'" v-model="form.driver" :items="driverOptions" item-title="full_name" item-value="id" label="Driver" density="comfortable" clearable />
              <v-select v-else v-model="form.client" :items="clientOptions" item-title="full_name" item-value="id" label="Client" density="comfortable" clearable />
            </v-col>

            <!-- Date & Severity -->
            <v-col cols="12" md="6"><v-text-field v-model="form.date" type="datetime-local" label="Date & Time *" density="comfortable" :error-messages="errors.date" /></v-col>
            <v-col cols="6" md="3"><v-select v-model="form.severity" :items="severityOpts" item-title="label" item-value="value" label="Severity *" density="comfortable" /></v-col>
            <v-col cols="6" md="3"><v-select v-model="form.status" :items="statusOpts" item-title="label" item-value="value" label="Status" density="comfortable" /></v-col>

            <!-- Location with Google Places / Map / Live -->
            <v-col cols="12">
              <div class="d-flex align-center ga-2 mb-2">
                <v-btn-toggle v-model="addressMode" mandatory density="compact" color="primary" variant="outlined" divided>
                  <v-btn value="places" size="x-small" prepend-icon="mdi-magnify">Google Places</v-btn>
                  <v-btn value="map" size="x-small" prepend-icon="mdi-map-marker-radius">Pick on Map</v-btn>
                  <v-btn value="live" size="x-small" prepend-icon="mdi-crosshairs-gps">Live</v-btn>
                </v-btn-toggle>
              </div>

              <template v-if="addressMode === 'places'">
                <v-text-field
                  ref="placesInput"
                  v-model="placesQuery"
                  label="Search accident location (Google Places)"
                  placeholder="Start typing an address..."
                  density="comfortable"
                  prepend-inner-icon="mdi-magnify"
                  :loading="mapsLoading"
                  :error-messages="mapsError"
                  clearable
                  :hint="selectedPlaceName ? selectedPlaceName : 'Autocomplete will fill location, latitude & longitude'"
                  persistent-hint
                  @update:model-value="onPlacesQueryCleared"
                />
              </template>

              <template v-else-if="addressMode === 'map'">
                <v-text-field
                  v-model="form.location"
                  label="Accident Location"
                  density="comfortable"
                  prepend-inner-icon="mdi-map-marker"
                  readonly
                  :error-messages="errors.location"
                  :placeholder="form.location ? '' : 'Open the map to pick a location...'"
                  append-inner-icon="mdi-map-search"
                  @click:append-inner="openMapPicker"
                />
                <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-map-marker-radius" class="mt-2" @click="openMapPicker">
                  Open Map Picker
                </v-btn>
              </template>

              <template v-else-if="addressMode === 'live'">
                <v-text-field
                  v-model="form.location"
                  label="Accident Location"
                  density="comfortable"
                  prepend-inner-icon="mdi-map-marker"
                  readonly
                  placeholder="Use your current location..."
                  :error-messages="errors.location"
                />
                <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-crosshairs-gps" class="mt-2" :loading="locating" @click="useLiveLocation">
                  Use My Current Location
                </v-btn>
              </template>
            </v-col>
            <v-col cols="6" md="3"><v-text-field v-model.number="form.latitude" label="Latitude" type="number" density="comfortable" hide-details /></v-col>
            <v-col cols="6" md="3"><v-text-field v-model.number="form.longitude" label="Longitude" type="number" density="comfortable" hide-details /></v-col>

            <!-- Conditions -->
            <v-col cols="6" md="3"><v-select v-model="form.weather" :items="weatherOpts" item-title="label" item-value="value" label="Weather" density="comfortable" /></v-col>
            <v-col cols="6" md="3"><v-select v-model="form.road_condition" :items="roadOpts" item-title="label" item-value="value" label="Road Condition" density="comfortable" /></v-col>

            <!-- Police & Cost -->
            <v-col cols="12" md="6"><v-text-field v-model="form.police_report_number" label="Police Report #" density="comfortable" prepend-inner-icon="mdi-shield-account-outline" /></v-col>
            <v-col cols="12" md="6"><v-text-field v-model="form.estimated_damage_cost" :label="`Estimated Damage Cost (${currencySymbol})`" density="comfortable" type="number" prepend-inner-icon="mdi-currency-usd" /></v-col>

            <!-- Description -->
            <v-col cols="12"><v-textarea v-model="form.description" label="Accident Description *" rows="3" density="comfortable" :error-messages="errors.description" /></v-col>

            <!-- Root Cause -->
            <v-col cols="12"><v-textarea v-model="form.fault_tree_analysis" label="Fault Tree / Root Cause Analysis" rows="2" density="comfortable" hint="Document the root cause and contributing factors" persistent-hint /></v-col>
          </v-row>

          <!-- Photos Section -->
          <div class="mt-4">
            <div class="d-flex align-center justify-space-between mb-2">
              <span class="text-subtitle-2 font-weight-bold">Accident Photos</span>
              <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-camera-plus" @click="photoInput?.click()">Upload Images</v-btn>
              <input
                ref="photoInput"
                type="file"
                multiple
                accept="image/*"
                class="d-none"
                @change="onPhotosInputChange"
              />
            </div>
            <p class="text-caption text-medium-emphasis mb-2">Upload scene photos, vehicle damage close-ups, police sketches, or any related documentation.</p>
            <div v-if="newPhotoPreviews.length || existingPhotos.length" class="d-flex flex-wrap ga-2">
              <div v-for="(src, i) in newPhotoPreviews" :key="'new-' + i" class="position-relative" style="width: 120px; height: 120px">
                <img :src="src" alt="New photo" style="width: 100%; height: 100%; object-fit: cover; border-radius: 8px" />
                <v-btn icon="mdi-close" size="x-small" color="error" variant="flat" style="position: absolute; top: 4px; right: 4px" @click="removeNewPhoto(i)" />
                <v-chip size="x-small" variant="flat" color="primary" style="position: absolute; bottom: 4px; left: 4px">New</v-chip>
              </div>
              <div v-for="photo in existingPhotos" :key="'ex-' + photo.id" class="position-relative" style="width: 120px; height: 120px">
                <img :src="resolveMediaUrl(photo.image_url || photo.image)" alt="Accident photo" style="width: 100%; height: 100%; object-fit: cover; border-radius: 8px" />
                <v-btn icon="mdi-trash-can-outline" size="x-small" color="error" variant="flat" style="position: absolute; top: 4px; right: 4px" @click="removeExistingPhoto(photo)" />
              </div>
            </div>
            <div v-else class="text-center py-6 text-medium-emphasis" style="border: 2px dashed #e0e0e0; border-radius: 12px">
              <v-icon size="36" class="mb-1">mdi-image-multiple-outline</v-icon>
              <p class="text-caption">No photos uploaded. Click "Upload Images" to add accident scene photos.</p>
            </div>
          </div>

          <!-- Witnesses Section -->
          <div class="mt-4">
            <div class="d-flex align-center justify-space-between mb-2">
              <span class="text-subtitle-2 font-weight-bold">Witnesses ({{ form.witnesses.length }})</span>
              <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-account-plus" @click="addWitness">Add Witness</v-btn>
            </div>
            <v-card v-for="(w, i) in form.witnesses" :key="i" variant="outlined" class="mb-2 pa-3" rounded="lg">
              <div class="d-flex align-center ga-2">
                <v-text-field v-model="w.name" label="Name" density="compact" hide-details class="flex-grow-1" />
                <v-text-field v-model="w.contact_info" label="Contact" density="compact" hide-details class="flex-grow-1" />
                <v-btn icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="form.witnesses.splice(i, 1)" />
              </div>
              <v-textarea v-model="w.statement" label="Statement" rows="2" density="compact" hide-details class="mt-2" />
            </v-card>
            <div v-if="!form.witnesses.length" class="text-center py-4 text-medium-emphasis">
              <v-icon size="32" class="mb-1">mdi-account-question-outline</v-icon>
              <p class="text-caption">No witnesses recorded.</p>
            </div>
          </div>

          <!-- Insurance Claim Section -->
          <div class="mt-4">
            <div class="d-flex align-center justify-space-between mb-2">
              <span class="text-subtitle-2 font-weight-bold">Insurance Claim</span>
              <v-btn v-if="!form.insurance_claim" size="small" variant="tonal" color="info" prepend-icon="mdi-shield-plus" @click="form.insurance_claim = { claim_number: '', insurance_company: '', status: 'filed', claim_amount: 0, settled_amount: 0, filed_date: '', settled_date: '', notes: '' }">Create Claim</v-btn>
              <v-btn v-else size="small" variant="text" color="error" prepend-icon="mdi-shield-remove" @click="form.insurance_claim = null">Remove Claim</v-btn>
            </div>
            <v-card v-if="form.insurance_claim" variant="outlined" class="pa-3" rounded="lg">
              <v-row dense>
                <v-col cols="6" md="4"><v-text-field v-model="form.insurance_claim.claim_number" label="Claim #" density="compact" hide-details /></v-col>
                <v-col cols="6" md="4"><v-text-field v-model="form.insurance_claim.insurance_company" label="Insurance Company" density="compact" hide-details /></v-col>
                <v-col cols="12" md="4"><v-select v-model="form.insurance_claim.status" :items="claimStatusOpts" item-title="label" item-value="value" label="Claim Status" density="compact" hide-details /></v-col>
                <v-col cols="6" md="4"><v-text-field v-model="form.insurance_claim.claim_amount" :label="`Claim Amount (${currencySymbol})`" type="number" density="compact" hide-details /></v-col>
                <v-col cols="6" md="4"><v-text-field v-model="form.insurance_claim.settled_amount" :label="`Settled Amount (${currencySymbol})`" type="number" density="compact" hide-details /></v-col>
                <v-col cols="6" md="4"><v-text-field v-model="form.insurance_claim.filed_date" type="date" label="Filed Date" density="compact" hide-details /></v-col>
                <v-col cols="6" md="4"><v-text-field v-model="form.insurance_claim.settled_date" type="date" label="Settled Date" density="compact" hide-details /></v-col>
                <v-col cols="12"><v-textarea v-model="form.insurance_claim.notes" label="Claim Notes" rows="2" density="compact" hide-details /></v-col>
              </v-row>
            </v-card>
            <div v-else class="text-center py-4 text-medium-emphasis">
              <v-icon size="32" class="mb-1">mdi-shield-outline</v-icon>
              <p class="text-caption">No insurance claim filed for this accident.</p>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="dialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" :loading="saving" @click="save">{{ editing ? 'Update Report' : 'Submit Report' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- View Accident Detail Dialog -->
    <v-dialog v-model="viewDialogVisible" max-width="800" scrollable>
      <v-card rounded="xl" v-if="viewItem">
        <AppModalHeader icon="mdi-car-emergency">{{ viewItem.vehicle_name }} — {{ new Date(viewItem.date).toLocaleDateString() }}</AppModalHeader>
        <v-card-text class="pt-4">
          <!-- Summary Row -->
          <div class="d-flex flex-wrap ga-4 mb-4">
            <div class="flex-grow-1">
              <div class="text-caption text-medium-emphasis mb-1">Severity</div>
              <v-chip :color="severityColor(viewItem.severity)" variant="flat" size="small" class="text-capitalize">{{ viewItem.severity }}</v-chip>
            </div>
            <div class="flex-grow-1">
              <div class="text-caption text-medium-emphasis mb-1">Status</div>
              <v-chip :color="statusColor(viewItem.status)" variant="tonal" size="small" class="text-capitalize">{{ statusLabel(viewItem.status) }}</v-chip>
            </div>
            <div class="flex-grow-1">
              <div class="text-caption text-medium-emphasis mb-1">Driver</div>
              <div class="text-body-2">{{ viewItem.driver_name || 'Unassigned' }}</div>
            </div>
            <div class="flex-grow-1">
              <div class="text-caption text-medium-emphasis mb-1">Client</div>
              <div class="text-body-2">{{ viewItem.client_name || 'Unassigned' }}</div>
            </div>
            <div class="flex-grow-1">
              <div class="text-caption text-medium-emphasis mb-1">Date & Time</div>
              <div class="text-body-2">{{ new Date(viewItem.date).toLocaleString() }}</div>
            </div>
          </div>

          <v-divider class="mb-4" />

          <!-- Details Grid -->
          <div class="d-flex flex-column ga-3">
            <div>
              <div class="text-caption text-medium-emphasis mb-1">Location</div>
              <div class="text-body-2">{{ viewItem.location || '—' }}</div>
              <div v-if="viewItem.latitude && viewItem.longitude" class="text-caption text-medium-emphasis">{{ viewItem.latitude.toFixed(5) }}, {{ viewItem.longitude.toFixed(5) }}</div>
            </div>

            <div class="d-flex ga-6 flex-wrap">
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Weather</div>
                <div class="d-flex align-center ga-1">
                  <v-icon size="small" color="info">{{ weatherIcon(viewItem.weather) }}</v-icon>
                  <span class="text-body-2 text-capitalize">{{ viewItem.weather }}</span>
                </div>
              </div>
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Road Condition</div>
                <span class="text-body-2 text-capitalize">{{ roadLabel(viewItem.road_condition) }}</span>
              </div>
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Damage Cost</div>
                <span class="text-body-2 font-weight-medium text-warning">{{ currencySymbol }}{{ Number(viewItem.estimated_damage_cost || 0).toLocaleString() }}</span>
              </div>
              <div>
                <div class="text-caption text-medium-emphasis mb-1">Police Report</div>
                <span class="text-body-2">{{ viewItem.police_report_number || '—' }}</span>
              </div>
            </div>

            <div>
              <div class="text-caption text-medium-emphasis mb-1">Description</div>
              <div class="text-body-2">{{ viewItem.description || '—' }}</div>
            </div>

            <div v-if="viewItem.fault_tree_analysis">
              <div class="text-caption text-medium-emphasis mb-1">Fault Tree Analysis</div>
              <div class="text-body-2">{{ viewItem.fault_tree_analysis }}</div>
            </div>

            <v-divider />

            <!-- Accident Photos -->
            <div>
              <div class="text-caption text-medium-emphasis mb-2">Accident Photos ({{ viewItem.accident_photos?.length || 0 }})</div>
              <div v-if="viewItem.accident_photos?.length" class="d-flex flex-wrap ga-2">
                <a v-for="photo in viewItem.accident_photos" :key="photo.id" :href="resolveMediaUrl(photo.image_url || photo.image)" target="_blank" class="d-block">
                  <img :src="resolveMediaUrl(photo.image_url || photo.image)" alt="Accident photo" style="width: 140px; height: 140px; object-fit: cover; border-radius: 8px; border: 1px solid #e0e0e0" />
                </a>
              </div>
              <div v-else class="text-center py-3 text-medium-emphasis">
                <v-icon size="28" class="mb-1">mdi-image-off-outline</v-icon>
                <p class="text-caption">No photos uploaded for this accident.</p>
              </div>
            </div>

            <v-divider />

            <!-- Witnesses -->
            <div>
              <div class="text-caption text-medium-emphasis mb-2">Witnesses ({{ viewItem.witnesses?.length || 0 }})</div>
              <v-card v-for="w in (viewItem.witnesses || [])" :key="w.id" variant="outlined" class="mb-2 pa-3" rounded="lg">
                <div class="d-flex align-center ga-2 mb-1">
                  <v-icon size="small" color="primary">mdi-account</v-icon>
                  <span class="text-body-2 font-weight-medium">{{ w.name }}</span>
                  <span v-if="w.contact_info" class="text-caption text-medium-emphasis">— {{ w.contact_info }}</span>
                </div>
                <p class="text-body-2 text-medium-emphasis">{{ w.statement }}</p>
              </v-card>
              <div v-if="!viewItem.witnesses?.length" class="text-center py-3 text-medium-emphasis">
                <v-icon size="28" class="mb-1">mdi-account-question-outline</v-icon>
                <p class="text-caption">No witnesses recorded.</p>
              </div>
            </div>

            <v-divider />

            <!-- Insurance Claim -->
            <div v-if="viewItem.insurance_claim">
              <div class="text-caption text-medium-emphasis mb-2">Insurance Claim</div>
              <div class="d-flex flex-wrap ga-4">
                <div>
                  <div class="text-caption text-medium-emphasis mb-1">Claim #</div>
                  <span class="text-body-2">{{ viewItem.insurance_claim.claim_number || '—' }}</span>
                </div>
                <div>
                  <div class="text-caption text-medium-emphasis mb-1">Company</div>
                  <span class="text-body-2">{{ viewItem.insurance_claim.insurance_company || '—' }}</span>
                </div>
                <div>
                  <div class="text-caption text-medium-emphasis mb-1">Status</div>
                  <v-chip :color="claimStatusColor(viewItem.insurance_claim.status)" variant="tonal" size="small" class="text-capitalize">{{ claimStatusLabel(viewItem.insurance_claim.status) }}</v-chip>
                </div>
                <div>
                  <div class="text-caption text-medium-emphasis mb-1">Claim Amount</div>
                  <span class="text-body-2 font-weight-medium">{{ currencySymbol }}{{ Number(viewItem.insurance_claim.claim_amount || 0).toLocaleString() }}</span>
                </div>
                <div>
                  <div class="text-caption text-medium-emphasis mb-1">Settled Amount</div>
                  <span class="text-body-2 font-weight-medium text-success">{{ currencySymbol }}{{ Number(viewItem.insurance_claim.settled_amount || 0).toLocaleString() }}</span>
                </div>
              </div>
              <div v-if="viewItem.insurance_claim.notes" class="mt-2">
                <div class="text-caption text-medium-emphasis mb-1">Notes</div>
                <p class="text-body-2">{{ viewItem.insurance_claim.notes }}</p>
              </div>
            </div>
            <div v-else class="text-center py-3 text-medium-emphasis">
              <v-icon size="28" class="mb-1">mdi-shield-outline</v-icon>
              <p class="text-caption">No insurance claim filed.</p>
            </div>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="viewDialogVisible = false">Close</v-btn>
          <v-btn v-can="'accidents:update'" color="primary" variant="tonal" prepend-icon="mdi-pencil-outline" @click="openEditFromView">Edit</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Map Picker Dialog -->
    <v-dialog v-model="mapDialogVisible" max-width="720" scrollable>
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-map-marker-radius">Pick Accident Location on Map</AppModalHeader>
        <v-card-text class="pa-0">
          <div class="pa-3 d-flex align-center ga-2">
            <v-text-field
              v-model="mapSearch"
              label="Search address"
              density="compact"
              prepend-inner-icon="mdi-magnify"
              hide-details
              variant="outlined"
              clearable
              @keyup.enter="searchOnMap"
            />
            <v-btn color="primary" variant="tonal" prepend-icon="mdi-magnify" @click="searchOnMap">Search</v-btn>
          </div>
          <div ref="mapContainer" class="location-map" />
          <div v-if="pickedAddress" class="pa-3 text-body-2">
            <v-icon size="16" class="me-1" color="primary">mdi-map-marker</v-icon>
            {{ pickedAddress }}
            <span class="text-medium-emphasis ms-2">({{ pickedPos?.lat.toFixed(5) }}, {{ pickedPos?.lng.toFixed(5) }})</span>
          </div>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="mapDialogVisible = false">Cancel</v-btn>
          <v-btn color="primary" @click="confirmMapPick">Use This Location</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { resolveMediaUrl } = useMediaUrl()

const search = ref('')
const dialogVisible = ref(false)
const viewDialogVisible = ref(false)
const editing = ref(false)
const saving = ref(false)
const errors = reactive<any>({})
const filterSeverity = ref(null)
const filterStatus = ref(null)
const viewItem = ref<any>(null)

// ---- Photo upload state ----
const newPhotos = ref<File[]>([])
const newPhotoPreviews = ref<string[]>([])
const existingPhotos = ref<any[]>([])
const uploading = ref(false)
const photoInput = ref<HTMLInputElement | null>(null)

function onPhotosInputChange(e: Event) {
  const target = e.target as HTMLInputElement
  onPhotosSelected(target.files)
  target.value = ''
}

function onPhotosSelected(files: File[] | FileList | null) {
  if (!files) return
  const arr = Array.from(files)
  for (const f of arr) {
    newPhotos.value.push(f)
    newPhotoPreviews.value.push(URL.createObjectURL(f))
  }
}

function removeNewPhoto(i: number) {
  URL.revokeObjectURL(newPhotoPreviews.value[i])
  newPhotos.value.splice(i, 1)
  newPhotoPreviews.value.splice(i, 1)
}

async function removeExistingPhoto(photo: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Photo',
    text: 'Remove this accident photo?',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/accidents/photos/${photo.id}/`, { method: 'DELETE' })
  existingPhotos.value = existingPhotos.value.filter((p) => p.id !== photo.id)
  if (viewItem.value) {
    viewItem.value.accident_photos = (viewItem.value.accident_photos || []).filter((p: any) => p.id !== photo.id)
  }
}

async function uploadPhotos(accidentId: number) {
  for (const file of newPhotos.value) {
    const formData = new FormData()
    formData.append('accident', String(accidentId))
    formData.append('image', file)
    await $api('/accidents/photos/', { method: 'POST', body: formData })
  }
}

// ---- Google Places / Map / Live state ----
const addressMode = ref<'places' | 'map' | 'live'>('places')
const placesInput = ref<any>(null)
const placesQuery = ref('')
const selectedPlaceName = ref('')
const mapsLoading = ref(false)
const mapsError = ref('')
let autocomplete: any = null

const mapDialogVisible = ref(false)
const mapContainer = ref<HTMLElement | null>(null)
const mapSearch = ref('')
const pickedAddress = ref('')
const pickedPos = ref<{ lat: number; lng: number } | null>(null)
let mapInstance: any = null
let mapMarker: any = null

const locating = ref(false)

let gmaps: ReturnType<typeof useGoogleMaps> | null = null
function ensureMaps() {
  if (!gmaps) gmaps = useGoogleMaps()
  return gmaps
}

function getInputEl(): HTMLInputElement | null {
  const inst: any = placesInput.value
  if (!inst) return null
  const el: HTMLElement = inst.$el || inst.el || inst
  return (el.querySelector?.('input') as HTMLInputElement) || (el as HTMLInputElement)
}

async function attachAutocomplete() {
  mapsError.value = ''
  mapsLoading.value = true
  try {
    const maps = ensureMaps()
    await maps.ensureGoogle()
    await nextTick()
    const inputEl = getInputEl()
    if (!inputEl) { mapsLoading.value = false; return }
    if (autocomplete) {
      try { (window as any).google.maps.event.clearInstanceListeners(autocomplete) } catch {}
    }
    autocomplete = await maps.attachAutocomplete(inputEl, { onPlace: handlePlaceSelected })
  } catch (e: any) {
    mapsError.value = e?.message || 'Failed to load Google Places.'
  } finally {
    mapsLoading.value = false
  }
}

function handlePlaceSelected(place: any) {
  if (!place || !place.geometry) { selectedPlaceName.value = ''; return }
  const lat = place.geometry.location.lat()
  const lng = place.geometry.location.lng()
  form.latitude = lat
  form.longitude = lng
  form.location = place.formatted_address || place.name || ''
  selectedPlaceName.value = place.formatted_address || place.name || ''
}

function onPlacesQueryCleared(val: string) {
  if (!val) selectedPlaceName.value = ''
}

watch(dialogVisible, async (open) => {
  if (open && addressMode.value === 'places') {
    await nextTick()
    attachAutocomplete()
  }
})
watch(addressMode, async (mode) => {
  if (mode === 'places' && dialogVisible.value) {
    await nextTick()
    attachAutocomplete()
  }
})

// ---- Map Picker ----
async function openMapPicker() {
  pickedAddress.value = ''
  pickedPos.value = null
  mapSearch.value = form.location || ''
  mapDialogVisible.value = true
  await nextTick()
  const maps = ensureMaps()
  await maps.ensureGoogle()
  let center = { lat: form.latitude || 0, lng: form.longitude || 0 }
  if (!form.latitude && !form.longitude) {
    try { center = await maps.getCurrentPosition() } catch { center = { lat: 40.4171, lng: -3.7034 } }
  }
  if (!mapContainer.value) return
  mapInstance = maps.createMap(mapContainer.value, center, 15)
  const google = (window as any).google
  mapMarker = new google.maps.Marker({ position: center, map: mapInstance, draggable: true })
  mapMarker.addListener('dragend', () => updatePickedFromMarker())
  mapInstance.addListener('click', (e: any) => {
    const pos = { lat: e.latLng.lat(), lng: e.latLng.lng() }
    setMarkerPos(pos)
    updatePickedAddress(pos)
  })
  pickedPos.value = center
  if (form.location) pickedAddress.value = form.location
  else updatePickedAddress(center)
}

function setMarkerPos(pos: { lat: number; lng: number }) {
  if (!mapMarker) return
  mapMarker.setPosition(pos)
  pickedPos.value = pos
}

async function updatePickedFromMarker() {
  if (!mapMarker) return
  const p = mapMarker.getPosition()
  const pos = { lat: p.lat(), lng: p.lng() }
  pickedPos.value = pos
  updatePickedAddress(pos)
}

async function updatePickedAddress(pos: { lat: number; lng: number }) {
  const maps = ensureMaps()
  try { pickedAddress.value = await maps.reverseGeocode(pos.lat, pos.lng) } catch { pickedAddress.value = '' }
}

async function searchOnMap() {
  if (!mapSearch.value || !mapInstance) return
  const maps = ensureMaps()
  try {
    const res = await maps.geocodeAddress(mapSearch.value)
    if (!res) return
    const pos = { lat: res.lat, lng: res.lng }
    mapInstance.setCenter(pos)
    setMarkerPos(pos)
    pickedAddress.value = res.formatted
  } catch (e) { console.error(e) }
}

function confirmMapPick() {
  if (!pickedPos.value) return
  form.latitude = pickedPos.value.lat
  form.longitude = pickedPos.value.lng
  if (pickedAddress.value) form.location = pickedAddress.value
  mapDialogVisible.value = false
}

// ---- Live Location ----
async function useLiveLocation() {
  const maps = ensureMaps()
  locating.value = true
  try {
    const pos = await maps.getCurrentPosition()
    form.latitude = pos.lat
    form.longitude = pos.lng
    const addr = await maps.reverseGeocode(pos.lat, pos.lng)
    form.location = addr || `(${pos.lat.toFixed(5)}, ${pos.lng.toFixed(5)})`
  } catch (e: any) {
    mapsError.value = e?.message || 'Could not get your current location.'
  } finally {
    locating.value = false
  }
}

const severityOpts = [
  { label: 'Minor', value: 'minor' },
  { label: 'Moderate', value: 'moderate' },
  { label: 'Serious', value: 'serious' },
  { label: 'Fatal', value: 'fatal' },
]
const statusOpts = [
  { label: 'Reported', value: 'reported' },
  { label: 'Under Investigation', value: 'under_investigation' },
  { label: 'Resolved', value: 'resolved' },
  { label: 'Closed', value: 'closed' },
]
const weatherOpts = [
  { label: 'Clear', value: 'clear' },
  { label: 'Rain', value: 'rain' },
  { label: 'Snow', value: 'snow' },
  { label: 'Fog', value: 'fog' },
  { label: 'Storm', value: 'storm' },
]
const roadOpts = [
  { label: 'Dry', value: 'dry' },
  { label: 'Wet', value: 'wet' },
  { label: 'Icy', value: 'icy' },
  { label: 'Snow Covered', value: 'snow_covered' },
  { label: 'Construction', value: 'construction' },
]
const claimStatusOpts = [
  { label: 'Filed', value: 'filed' },
  { label: 'Under Review', value: 'under_review' },
  { label: 'Approved', value: 'approved' },
  { label: 'Denied', value: 'denied' },
  { label: 'Settled', value: 'settled' },
  { label: 'Litigation', value: 'litigation' },
]

const headers = [
  { title: 'Vehicle / Driver', key: 'vehicle_name', sortable: true, width: '200px' },
  { title: 'Date', key: 'date', sortable: true, width: '130px' },
  { title: 'Severity', key: 'severity', sortable: true, width: '110px' },
  { title: 'Status', key: 'status', sortable: true, width: '130px' },
  { title: 'Location', key: 'location', width: '200px' },
  { title: 'Weather', key: 'weather', sortable: true, width: '100px' },
  { title: 'Damage Cost', key: 'estimated_damage_cost', sortable: true, width: '130px' },
  { title: 'Claim', key: 'has_claim', sortable: false, width: '120px' },
  { title: '', key: 'actions', width: '120px', sortable: false },
]

function defaultForm() {
  return {
    id: null, vehicle: null, driver: null, client: null, person_type: 'driver',
    date: new Date().toISOString().slice(0, 16),
    severity: 'minor', status: 'reported',
    location: '', latitude: null, longitude: null,
    weather: 'clear', road_condition: 'dry',
    police_report_number: '', estimated_damage_cost: 0,
    description: '', fault_tree_analysis: '',
    witnesses: [] as any[],
    insurance_claim: null as any,
  }
}
const form = reactive<any>(defaultForm())

// ---- Data ----
const { data: vehicleData } = useAsyncData('acc-vehicles', () =>
  $api('/vehicles/vehicles/'), { default: () => ({ results: [] }) }
)
const vehicleOptions = computed(() => vehicleData.value?.results || [])

const { data: driverData } = useAsyncData('acc-drivers', () =>
  $api('/contacts/drivers/?page_size=1000'), { default: () => ({ results: [] }) }
)
const driverOptions = computed(() => driverData.value?.results || [])

const { data: clientData } = useAsyncData('acc-clients', () =>
  $api('/rentals/customers/?page_size=1000'), { default: () => ({ results: [] }) }
)
const clientOptions = computed(() => clientData.value?.results || [])

const { data: accData, pending, refresh } = useAsyncData('accidents', () =>
  $api('/accidents/reports/?page_size=1000'), { default: () => ({ results: [], count: 0 }) }
)
const accidents = computed(() => accData.value?.results || accData.value || [])

const { data: statsData, refresh: refreshStats } = useAsyncData('acc-stats', () =>
  $api('/accidents/reports/stats/'), { default: () => ({}) }
)
const stats = computed(() => statsData.value || {})

const filteredAccidents = computed(() => {
  let all = accidents.value
  if (filterSeverity.value) all = all.filter((a: any) => a.severity === filterSeverity.value)
  if (filterStatus.value) all = all.filter((a: any) => a.status === filterStatus.value)
  if (search.value) {
    const s = search.value.toLowerCase()
    all = all.filter((a: any) =>
      (a.location || '').toLowerCase().includes(s) ||
      (a.description || '').toLowerCase().includes(s) ||
      (a.police_report_number || '').toLowerCase().includes(s) ||
      (a.vehicle_name || '').toLowerCase().includes(s) ||
      (a.driver_name || '').toLowerCase().includes(s) ||
      (a.client_name || '').toLowerCase().includes(s)
    )
  }
  return all
})

// ---- Helpers ----
function severityColor(s: string) { return { minor: 'success', moderate: 'warning', serious: 'orange', fatal: 'error' }[s] || 'grey' }
function severityIcon(s: string) { return { minor: 'mdi-check-circle', moderate: 'mdi-alert', serious: 'mdi-alert-circle', fatal: 'mdi-alert-octagon' }[s] || 'mdi-help-circle' }
function statusColor(s: string) { return { reported: 'info', under_investigation: 'warning', resolved: 'success', closed: 'grey' }[s] || 'default' }
function statusLabel(s: string) { return { reported: 'Reported', under_investigation: 'Under Investigation', resolved: 'Resolved', closed: 'Closed' }[s] || s }
function weatherIcon(w: string) { return { clear: 'mdi-weather-sunny', rain: 'mdi-weather-rainy', snow: 'mdi-weather-snowy', fog: 'mdi-weather-fog', storm: 'mdi-weather-lightning' }[w] || 'mdi-weather' }
function roadLabel(r: string) { return { dry: 'Dry', wet: 'Wet', icy: 'Icy', snow_covered: 'Snow Covered', construction: 'Construction' }[r] || r }
function claimStatusColor(s: string) { return { filed: 'info', under_review: 'warning', approved: 'success', denied: 'error', settled: 'green-darken-2', litigation: 'purple' }[s] || 'grey' }
function claimStatusLabel(s: string) { return { filed: 'Filed', under_review: 'Under Review', approved: 'Approved', denied: 'Denied', settled: 'Settled', litigation: 'In Litigation' }[s] || s }

// ---- CRUD ----
function openCreate() {
  editing.value = false
  Object.assign(form, defaultForm())
  Object.keys(errors).forEach(k => delete errors[k])
  addressMode.value = 'places'
  placesQuery.value = ''
  selectedPlaceName.value = ''
  mapsError.value = ''
  newPhotos.value = []
  newPhotoPreviews.value = []
  existingPhotos.value = []
  dialogVisible.value = true
}

function openEdit(a: any) {
  editing.value = true
  Object.keys(errors).forEach(k => delete errors[k])
  Object.assign(form, defaultForm())
  form.id = a.id
  form.vehicle = a.vehicle
  form.driver = a.driver
  form.client = a.client
  form.person_type = a.client ? 'client' : 'driver'
  form.date = a.date ? new Date(a.date).toISOString().slice(0, 16) : new Date().toISOString().slice(0, 16)
  form.severity = a.severity
  form.status = a.status || 'reported'
  form.location = a.location || ''
  form.latitude = a.latitude
  form.longitude = a.longitude
  form.weather = a.weather
  form.road_condition = a.road_condition
  form.police_report_number = a.police_report_number || ''
  form.estimated_damage_cost = a.estimated_damage_cost || 0
  form.description = a.description || ''
  form.fault_tree_analysis = a.fault_tree_analysis || ''
  form.witnesses = (a.witnesses || []).map((w: any) => ({ id: w.id, name: w.name, contact_info: w.contact_info, statement: w.statement }))
  form.insurance_claim = a.insurance_claim ? { ...a.insurance_claim } : null
  existingPhotos.value = (a.accident_photos || []).map((p: any) => ({ ...p }))
  newPhotos.value = []
  newPhotoPreviews.value = []
  addressMode.value = (a.latitude && a.longitude) ? 'map' : 'places'
  placesQuery.value = a.location || ''
  selectedPlaceName.value = ''
  mapsError.value = ''
  dialogVisible.value = true
}

function openView(a: any) {
  viewItem.value = a
  viewDialogVisible.value = true
}

function openEditFromView() {
  viewDialogVisible.value = false
  if (viewItem.value) openEdit(viewItem.value)
}

function addWitness() {
  form.witnesses.push({ name: '', contact_info: '', statement: '' })
}

async function save() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.vehicle) errors.vehicle = 'Vehicle is required.'
  if (!form.date) errors.date = 'Date is required.'
  if (!form.location) errors.location = 'Location is required.'
  if (!form.description) errors.description = 'Description is required.'
  if (Object.keys(errors).length) return

  saving.value = true
  try {
    const body: any = {
      vehicle: form.vehicle,
      driver: form.person_type === 'driver' ? (form.driver || null) : null,
      client: form.person_type === 'client' ? (form.client || null) : null,
      date: new Date(form.date).toISOString(),
      severity: form.severity,
      status: form.status,
      location: form.location,
      latitude: form.latitude,
      longitude: form.longitude,
      weather: form.weather,
      road_condition: form.road_condition,
      police_report_number: form.police_report_number,
      estimated_damage_cost: parseFloat(form.estimated_damage_cost) || 0,
      description: form.description,
      fault_tree_analysis: form.fault_tree_analysis,
    }
    let accidentId = form.id
    if (editing.value) {
      // Update accident
      await $api(`/accidents/reports/${form.id}/`, { method: 'PATCH', body })
      // Sync witnesses
      await syncWitnesses(form.id, form.witnesses)
      // Sync insurance claim
      await syncClaim(form.id, form.insurance_claim)
    } else {
      // Create accident
      const created = await $api('/accidents/reports/', { method: 'POST', body })
      accidentId = created.id
      // Create witnesses
      await syncWitnesses(created.id, form.witnesses)
      // Create insurance claim
      await syncClaim(created.id, form.insurance_claim)
    }
    // Upload new photos
    if (newPhotos.value.length && accidentId) {
      uploading.value = true
      await uploadPhotos(accidentId)
    }
    dialogVisible.value = false
    await refresh()
    await refreshStats()
  } catch (e: any) {
    console.error('Accident save failed:', e?.data || e)
    const errs = e?.data || {}
    Object.keys(errs).forEach(k => { errors[k] = Array.isArray(errs[k]) ? errs[k][0] : errs[k] })
  } finally {
    saving.value = false
    uploading.value = false
  }
}

async function syncWitnesses(accidentId: number, witnesses: any[]) {
  for (const w of witnesses) {
    if (w.id) {
      // Existing witness — update
      await $api(`/accidents/witnesses/${w.id}/`, { method: 'PATCH', body: { name: w.name, contact_info: w.contact_info, statement: w.statement } })
    } else if (w.name) {
      // New witness — create
      await $api('/accidents/witnesses/', { method: 'POST', body: { accident: accidentId, name: w.name, contact_info: w.contact_info, statement: w.statement } })
    }
  }
}

async function syncClaim(accidentId: number, claim: any) {
  if (!claim || !claim.insurance_company && !claim.claim_number) return
  const claimBody: any = {
    accident: accidentId,
    claim_number: claim.claim_number || '',
    insurance_company: claim.insurance_company || '',
    status: claim.status || 'filed',
    claim_amount: parseFloat(claim.claim_amount) || 0,
    settled_amount: parseFloat(claim.settled_amount) || 0,
    filed_date: claim.filed_date || null,
    settled_date: claim.settled_date || null,
    notes: claim.notes || '',
  }
  if (claim.id) {
    await $api(`/accidents/claims/${claim.id}/`, { method: 'PATCH', body: claimBody })
  } else {
    await $api('/accidents/claims/', { method: 'POST', body: claimBody })
  }
}

async function deleteAccident(a: any) {
  const { isConfirmed } = await $swal.fire({
    title: 'Delete Accident Report',
    text: `Delete accident report for "${a.vehicle_name}" on ${new Date(a.date).toLocaleDateString()}?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Delete',
    cancelButtonText: 'Cancel',
  })
  if (!isConfirmed) return
  await $api(`/accidents/reports/${a.id}/`, { method: 'DELETE' })
  await refresh()
  await refreshStats()
}
</script>

<style scoped>
.location-map {
  width: 100%;
  height: 380px;
  background: #e2e8f0;
}
</style>
