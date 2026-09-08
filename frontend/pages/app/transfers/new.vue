<template>
  <div class="d-flex flex-column ga-4">
    <!-- Header -->
    <div class="transfer-hero-header">
      <div class="d-flex align-center ga-3">
        <v-btn icon="mdi-arrow-left" variant="text" size="small" color="white" @click="goBack" />
        <div class="transfer-hero-icon">
          <v-icon color="white" size="26">mdi-car-plus-outline</v-icon>
        </div>
        <div>
          <h2 class="text-h6 font-weight-bold mb-0 text-white">New Transfer Booking</h2>
          <p class="text-caption mb-0 text-white" style="opacity: 0.85">Create a premium point-to-point passenger transfer</p>
        </div>
      </div>
      <div class="d-flex align-center ga-2">
        <v-chip size="small" variant="flat" color="rgba(255,255,255,0.2)" class="text-white">
          <v-icon start size="14">mdi-calendar-clock</v-icon>
          Step {{ step }} of 4
        </v-chip>
      </div>
    </div>

    <v-card elevation="0" border rounded="xl" class="transfer-wizard-card">
      <v-stepper v-model="step" editable flat min-height="380" bg-color="transparent">
        <v-stepper-header class="transfer-stepper-header">
          <v-stepper-item value="1" title="Passenger" subtitle="Details and contact" icon="mdi-account-outline" />
          <v-divider />
          <v-stepper-item value="2" title="Route" subtitle="Pickup and drop-off" icon="mdi-map-marker-route" />
          <v-divider />
          <v-stepper-item value="3" title="Vehicle and Fare" subtitle="Class, assignment, pricing" icon="mdi-cash-clock" />
          <v-divider />
          <v-stepper-item value="4" title="Review" subtitle="Confirm and create" icon="mdi-clipboard-check-outline" />
        </v-stepper-header>

        <v-stepper-window v-model="step">
          <!-- Step 1: Passenger -->
          <v-stepper-window-item value="1">
            <div class="pa-2 pa-md-4">
              <!-- Passenger section -->
              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-account-circle-outline</v-icon>
                <span>Passenger Information</span>
              </div>
              <v-row dense>
                <v-col cols="12" md="6">
                  <v-text-field v-model="form.passenger_name" label="Passenger Name *" density="comfortable" variant="outlined" prepend-inner-icon="mdi-account" hide-details="auto" :rules="[v => !!v || 'Required']" />
                </v-col>
                <v-col cols="6" md="3">
                  <v-text-field v-model="form.passenger_phone" label="Phone" density="comfortable" variant="outlined" prepend-inner-icon="mdi-phone" hide-details />
                </v-col>
                <v-col cols="6" md="3">
                  <v-text-field v-model="form.passenger_email" label="Email" type="email" density="comfortable" variant="outlined" prepend-inner-icon="mdi-email" hide-details />
                </v-col>
              </v-row>

              <v-divider class="my-4" />

              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-account-group-outline</v-icon>
                <span>Trip Details</span>
              </div>
              <v-row dense>
                <v-col cols="6" md="3">
                  <v-text-field v-model.number="form.passenger_count" type="number" min="1" label="Passengers" density="comfortable" variant="outlined" prepend-inner-icon="mdi-account-multiple" hide-details />
                </v-col>
                <v-col cols="6" md="3">
                  <v-text-field v-model.number="form.luggage_count" type="number" min="0" label="Luggage Pieces" density="comfortable" variant="outlined" prepend-inner-icon="mdi-bag-suitcase" hide-details />
                </v-col>
                <v-col cols="6" md="3">
                  <v-select v-model="form.has_child_seat" :items="booleanOptions" label="Child Seat" item-title="label" item-value="value" density="comfortable" variant="outlined" prepend-inner-icon="mdi-car-child-seat" hide-details />
                </v-col>
                <v-col cols="6" md="3">
                  <v-select v-model="form.has_infant_seat" :items="booleanOptions" label="Infant Seat" item-title="label" item-value="value" density="comfortable" variant="outlined" prepend-inner-icon="mdi-baby-carriage" hide-details />
                </v-col>
                <v-col cols="12">
                  <v-textarea v-model="form.passenger_notes" label="Special Requests" placeholder="Accessibility needs, mobility assistance, preferred language, etc." rows="2" density="comfortable" variant="outlined" prepend-inner-icon="mdi-note-text" hide-details />
                </v-col>
              </v-row>
            </div>
          </v-stepper-window-item>

          <!-- Step 2: Route -->
          <v-stepper-window-item value="2">
            <div class="pa-2 pa-md-4">
              <!-- Trip type selector -->
              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-swap-horizontal</v-icon>
                <span>Trip Type</span>
              </div>
              <div class="trip-type-grid mb-4">
                <div
                  v-for="opt in tripTypeCards" :key="opt.value"
                  class="trip-type-card"
                  :class="{ 'trip-type-card-active': form.trip_type === opt.value }"
                  @click="form.trip_type = opt.value"
                >
                  <v-icon :icon="opt.icon" size="24" :color="form.trip_type === opt.value ? 'primary' : 'grey'" />
                  <span class="text-body-2 font-weight-medium mt-1">{{ opt.label }}</span>
                </div>
              </div>

              <!-- Pickup -->
              <div class="route-card route-card-pickup mb-3">
                <div class="route-card-header">
                  <div class="route-dot-large bg-success"></div>
                  <span class="text-subtitle-2 font-weight-bold text-white">Pickup Location</span>
                  <v-icon color="white" size="16" class="ml-auto">mdi-airplane-takeoff</v-icon>
                </div>
                <div class="pa-4">
                  <v-row dense>
                    <v-col cols="12" md="6">
                      <v-text-field v-model="form.pickup_name" label="Place Name * (e.g. JFK Airport T4)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-store-marker" hide-details="auto" :rules="[v => !!v || 'Required']" />
                    </v-col>
                    <v-col cols="12" md="6">
                      <v-text-field v-model="form.pickup_flight_no" label="Flight / Train No" density="comfortable" variant="outlined" prepend-inner-icon="mdi-airplane" placeholder="BAW178" hide-details hint="For meet-and-greet tracking" persistent-hint />
                    </v-col>
                    <v-col cols="12">
                      <v-text-field v-model="form.pickup_address" label="Pickup Address *" ref="pickupInput"
                        density="comfortable" variant="outlined" prepend-inner-icon="mdi-map-marker" autocomplete="off" hide-details="auto"
                        :rules="[v => !!v || 'Required']" append-inner-icon="mdi-crosshairs-gps" @click:append-inner="useCurrentLocation('pickup')" />
                    </v-col>
                    <v-col cols="6" md="4">
                      <v-text-field v-model="form.pickup_datetime" type="datetime-local" label="Pickup Date and Time *" density="comfortable" variant="outlined" prepend-inner-icon="mdi-clock-time-four" hide-details="auto" :rules="[v => !!v || 'Required']" />
                    </v-col>
                    <v-col cols="6" md="4">
                      <v-text-field v-model.number="form.estimated_duration_min" type="number" min="0" label="Est. Duration (min)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-timer-sand" hide-details />
                    </v-col>
                    <v-col cols="6" md="2">
                      <v-text-field v-model="form.pickup_lat" type="number" label="Lat" density="compact" variant="outlined" hide-details />
                    </v-col>
                    <v-col cols="6" md="2">
                      <v-text-field v-model="form.pickup_lng" type="number" label="Lng" density="compact" variant="outlined" hide-details />
                    </v-col>
                  </v-row>
                </div>
              </div>

              <!-- Intermediate stops -->
              <div v-if="form.stops.length > 0" class="mb-3">
                <div class="d-flex align-center ga-2 mb-2">
                  <v-icon size="18" color="info">mdi-circle-multiple-outline</v-icon>
                  <span class="text-subtitle-2 font-weight-medium">Intermediate Stops</span>
                </div>
                <transition-group name="stop-list" tag="div">
                  <div v-for="(stop, i) in form.stops" :key="i" class="stop-row mb-2">
                    <div class="stop-dot-info">
                      <v-icon size="12" color="info">mdi-circle-medium</v-icon>
                    </div>
                    <v-text-field v-model="stop.sequence" type="number" label="#" density="compact" variant="outlined" hide-details style="max-width: 60px" />
                    <v-text-field v-model="stop.place_name" label="Stop name" density="compact" variant="outlined" hide-details style="max-width: 180px" />
                    <v-text-field v-model="stop.address" label="Address" density="compact" variant="outlined" hide-details class="flex-1" />
                    <v-text-field v-model.number="stop.duration_min" type="number" label="Min" density="compact" variant="outlined" hide-details style="max-width: 70px" />
                    <v-btn icon="mdi-close" size="x-small" variant="text" color="error" @click="removeStop(i)" />
                  </div>
                </transition-group>
              </div>

              <v-btn size="small" variant="tonal" color="info" prepend-icon="mdi-plus-circle-outline" class="mb-4" @click="addStop">Add Intermediate Stop</v-btn>

              <!-- Drop-off -->
              <div class="route-card route-card-dropoff">
                <div class="route-card-header">
                  <div class="route-dot-large bg-error"></div>
                  <span class="text-subtitle-2 font-weight-bold text-white">Drop-off Location</span>
                  <v-icon color="white" size="16" class="ml-auto">mdi-flag-checkered</v-icon>
                </div>
                <div class="pa-4">
                  <v-row dense>
                    <v-col cols="12">
                      <v-text-field v-model="form.dropoff_name" label="Place Name * (e.g. Hilton Hotel)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-store-marker" hide-details="auto" :rules="[v => !!v || 'Required']" />
                    </v-col>
                    <v-col cols="12">
                      <v-text-field v-model="form.dropoff_address" label="Drop-off Address *" ref="dropoffInput"
                        density="comfortable" variant="outlined" prepend-inner-icon="mdi-map-marker" autocomplete="off" hide-details="auto"
                        :rules="[v => !!v || 'Required']" append-inner-icon="mdi-crosshairs-gps" @click:append-inner="useCurrentLocation('dropoff')" />
                    </v-col>
                    <v-col cols="6" md="4">
                      <v-text-field v-model="form.dropoff_datetime" type="datetime-local" label="Drop-off Date and Time" density="comfortable" variant="outlined" prepend-inner-icon="mdi-clock-time-four-outline" hide-details="auto" hint="Leave blank to auto-calc from duration" persistent-hint />
                    </v-col>
                    <v-col cols="6" md="4">
                      <v-text-field v-model="form.dropoff_lat" type="number" label="Lat" density="compact" variant="outlined" hide-details />
                    </v-col>
                    <v-col cols="6" md="4">
                      <v-text-field v-model="form.dropoff_lng" type="number" label="Lng" density="compact" variant="outlined" hide-details />
                    </v-col>
                    <v-col cols="12" md="4" v-if="form.trip_type === 'round_trip'">
                      <v-text-field v-model="form.return_datetime" type="datetime-local" label="Return Date and Time" density="compact" variant="outlined" prepend-inner-icon="mdi-airplane-landing" hide-details />
                    </v-col>
                  </v-row>
                </div>
              </div>
              <!-- Live Map Preview -->
              <div v-if="showMap" class="map-preview-container mt-4">
                <div class="d-flex align-center justify-space-between mb-2">
                  <div class="d-flex align-center ga-2">
                    <v-icon size="18" color="primary">mdi-map-outline</v-icon>
                    <span class="text-subtitle-2 font-weight-bold">Route Preview</span>
                  </div>
                  <v-btn size="x-small" variant="text" color="primary" prepend-icon="mdi-refresh" @click="buildMap">Re-render</v-btn>
                </div>
                <div ref="mapContainer" class="route-map"></div>
                <div v-if="routeDistance || routeDuration" class="d-flex ga-4 mt-2 flex-wrap">
                  <v-chip v-if="routeDistance" size="small" variant="tonal" color="primary">
                    <v-icon start size="14">mdi-map-marker-distance</v-icon>
                    Distance: {{ routeDistance }}
                  </v-chip>
                  <v-chip v-if="routeDuration" size="small" variant="tonal" color="info">
                    <v-icon start size="14">mdi-clock-outline</v-icon>
                    Duration: {{ routeDuration }}
                  </v-chip>
                  <v-chip v-if="routeFound" size="small" variant="tonal" color="success">
                    <v-icon start size="14">mdi-check-circle</v-icon>
                    Auto-filled
                  </v-chip>
                </div>
              </div>
            </div>
          </v-stepper-window-item>

          <!-- Step 3: Vehicle & Fare -->
          <v-stepper-window-item value="3">
            <div class="pa-2 pa-md-4">
              <!-- Service class visual selector -->
              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-car-elite</v-icon>
                <span>Service Class</span>
              </div>
              <div class="class-grid mb-4">
                <div
                  v-for="opt in serviceClassCards" :key="opt.value"
                  class="class-card"
                  :class="{ 'class-card-active': form.service_class === opt.value }"
                  @click="form.service_class = opt.value"
                >
                  <v-icon :icon="opt.icon" size="22" :color="form.service_class === opt.value ? '#fff' : 'primary'" />
                  <span class="text-body-2 font-weight-bold mt-1" :class="form.service_class === opt.value ? 'text-white' : 'text-slate-700'">{{ opt.label }}</span>
                  <span class="text-caption" :class="form.service_class === opt.value ? 'text-white' : 'text-medium-emphasis'" style="opacity: 0.8">{{ opt.desc }}</span>
                </div>
              </div>

              <v-divider class="mb-4" />

              <!-- Assignment -->
              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-car-key</v-icon>
                <span>Vehicle and Driver Assignment</span>
              </div>
              <v-row dense class="mb-2">
                <v-col cols="12" md="6">
                  <v-select v-model="form.vehicle" :items="availableVehicles" item-title="label" item-value="value" label="Vehicle" density="comfortable" variant="outlined" prepend-inner-icon="mdi-car" hide-details clearable placeholder="Select or leave unassigned">
                    <template #selection="{ item }">
                      <span class="font-weight-medium">{{ item.raw.label }}</span>
                      <span v-if="item.raw.license_plate" class="text-caption text-medium-emphasis ml-2">· {{ item.raw.license_plate }}</span>
                    </template>
                    <template #item="{ item, props }">
                      <v-list-item v-bind="props" :title="item.raw.label" :subtitle="item.raw.license_plate || 'No plate'" />
                    </template>
                  </v-select>
                </v-col>
                <v-col cols="12" md="6">
                  <v-select v-model="form.driver" :items="availableDrivers" item-title="label" item-value="value" label="Driver" density="comfortable" variant="outlined" prepend-inner-icon="mdi-account-tie" hide-details clearable placeholder="Select or leave unassigned" />
                </v-col>
              </v-row>

              <v-divider class="mb-4" />

              <!-- Fare breakdown -->
              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-cash-multiple</v-icon>
                <span>Fare Breakdown</span>
              </div>
              <v-row dense>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.base_fare" type="number" min="0" label="Base Fare *" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-tag" hide-details="auto" :rules="[v => (v !== '' && v != null && Number(v) > 0) || 'Required']" /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.distance_km" type="number" min="0" label="Distance (km)" density="comfortable" variant="outlined" prepend-inner-icon="mdi-map-marker-distance" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.tolls_amount" type="number" min="0" label="Tolls" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-boom-gate" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.parking_amount" type="number" min="0" label="Parking" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-parking" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.meet_greet_fee" type="number" min="0" label="Meet and Greet" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-handshake" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.waiting_fee" type="number" min="0" label="Waiting Fee" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-clock-alert" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.child_seat_fee" type="number" min="0" label="Child Seat Fee" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-car-child-seat" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.driver_tip" type="number" min="0" label="Driver Tip" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-hand-coin" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.tax_amount" type="number" min="0" label="Tax / VAT" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-receipt-text" hide-details /></v-col>
                <v-col cols="6" md="3"><v-text-field v-model.number="form.discount_amount" type="number" min="0" label="Discount" :prefix="currencySymbol" density="comfortable" variant="outlined" prepend-inner-icon="mdi-tag-minus" hide-details /></v-col>
              </v-row>

              <!-- Total highlight -->
              <div class="fare-total-panel mt-4">
                <div class="d-flex align-center ga-2">
                  <v-icon color="white" size="20">mdi-cash-check</v-icon>
                  <span class="text-white text-subtitle-2 font-weight-bold">Total Amount</span>
                </div>
                <span class="text-h5 font-weight-black text-white">{{ currencySymbol }}{{ computedTotal.toFixed(2) }}</span>
              </div>
            </div>
          </v-stepper-window-item>

          <!-- Step 4: Review -->
          <v-stepper-window-item value="4">
            <div class="pa-2 pa-md-4">
              <!-- Settings -->
              <div class="section-label mb-3">
                <v-icon size="18" color="primary">mdi-cog-outline</v-icon>
                <span>Booking Settings</span>
              </div>
              <v-row dense class="mb-4">
                <v-col cols="6">
                  <v-select v-model="form.status" :items="statusCreateOptions" item-title="title" item-value="value" label="Initial Status" density="comfortable" variant="outlined" prepend-inner-icon="mdi-flag" hide-details />
                </v-col>
                <v-col cols="6">
                  <v-select v-model="form.payment_method" :items="paymentMethodOptions" item-title="title" item-value="value" label="Payment Method" density="comfortable" variant="outlined" prepend-inner-icon="mdi-credit-card" hide-details clearable />
                </v-col>
                <v-col cols="12">
                  <v-textarea v-model="form.notes" label="Internal Notes (not shown to passenger)" rows="2" density="comfortable" variant="outlined" prepend-inner-icon="mdi-note-text" hide-details />
                </v-col>
              </v-row>

              <!-- Summary card -->
              <div class="review-summary-card">
                <div class="review-summary-header">
                  <v-icon color="white" size="20">mdi-clipboard-check-outline</v-icon>
                  <span class="text-subtitle-1 font-weight-bold text-white">Transfer Summary</span>
                </div>
                <div class="pa-5">
                  <!-- Route visualization -->
                  <div class="review-route">
                    <div class="d-flex align-start ga-3 mb-3">
                      <div class="route-dot-sm bg-success"></div>
                      <div class="flex-1">
                        <p class="text-caption text-medium-emphasis mb-0">FROM</p>
                        <p class="text-body-1 font-weight-bold mb-0">{{ form.pickup_name || '--' }}</p>
                        <p class="text-body-2 text-medium-emphasis mb-0">{{ form.pickup_address || '--' }}</p>
                      </div>
                      <div class="text-right">
                        <p class="text-caption text-medium-emphasis mb-0">Departure</p>
                        <p class="text-body-2 font-weight-bold text-primary mb-0">{{ pickFDate || '--' }}</p>
                        <v-chip v-if="form.pickup_flight_no" size="x-small" variant="tonal" color="info"><v-icon start size="10">mdi-airplane</v-icon>{{ form.pickup_flight_no }}</v-chip>
                      </div>
                    </div>
                    <div class="review-route-line"></div>
                    <div class="d-flex align-start ga-3">
                      <div class="route-dot-sm bg-error"></div>
                      <div class="flex-1">
                        <p class="text-caption text-medium-emphasis mb-0">TO</p>
                        <p class="text-body-1 font-weight-bold mb-0">{{ form.dropoff_name || '--' }}</p>
                        <p class="text-body-2 text-medium-emphasis mb-0">{{ form.dropoff_address || '--' }}</p>
                      </div>
                      <div class="text-right" v-if="form.estimated_duration_min">
                        <p class="text-caption text-medium-emphasis mb-0">Est. Duration</p>
                        <p class="text-body-2 font-weight-bold mb-0">{{ form.estimated_duration_min }} min</p>
                      </div>
                    </div>
                  </div>

                  <v-divider class="my-4" />

                  <!-- Info grid -->
                  <v-row dense>
                    <v-col cols="6" md="3">
                      <div class="review-info-item">
                        <v-icon size="16" color="primary">mdi-account-circle</v-icon>
                        <div>
                          <p class="text-caption text-medium-emphasis mb-0">Passenger</p>
                          <p class="text-body-2 font-weight-bold mb-0">{{ form.passenger_name || '--' }}</p>
                        </div>
                      </div>
                    </v-col>
                    <v-col cols="6" md="3">
                      <div class="review-info-item">
                        <v-icon size="16" color="primary">mdi-account-multiple</v-icon>
                        <div>
                          <p class="text-caption text-medium-emphasis mb-0">Passengers / Luggage</p>
                          <p class="text-body-2 font-weight-bold mb-0">{{ form.passenger_count }} / {{ form.luggage_count }}</p>
                        </div>
                      </div>
                    </v-col>
                    <v-col cols="6" md="3">
                      <div class="review-info-item">
                        <v-icon size="16" color="purple">mdi-car-elite</v-icon>
                        <div>
                          <p class="text-caption text-medium-emphasis mb-0">Service Class</p>
                          <p class="text-body-2 font-weight-bold mb-0">{{ classLabel(form.service_class) }}</p>
                        </div>
                      </div>
                    </v-col>
                    <v-col cols="6" md="3">
                      <div class="review-info-item">
                        <v-icon size="16" color="info">mdi-swap-horizontal</v-icon>
                        <div>
                          <p class="text-caption text-medium-emphasis mb-0">Trip Type</p>
                          <p class="text-body-2 font-weight-bold mb-0">{{ tripLabel(form.trip_type) }}</p>
                        </div>
                      </div>
                    </v-col>
                  </v-row>

                  <v-divider class="my-4" />

                  <!-- Fare summary -->
                  <div class="d-flex justify-space-between align-center flex-wrap ga-2">
                    <span class="text-body-1 font-weight-medium text-medium-emphasis">Estimated Distance</span>
                    <span class="text-body-1 font-weight-bold">{{ form.distance_km || 0 }} km</span>
                  </div>
                  <div class="d-flex justify-space-between align-center mt-2">
                    <span class="text-subtitle-1 font-weight-bold">Grand Total</span>
                    <span class="text-h5 font-weight-black text-primary">{{ currencySymbol }}{{ computedTotal.toFixed(2) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </v-stepper-window-item>
        </v-stepper-window>

        <v-divider />
        <div class="d-flex justify-space-between align-center pa-4">
          <v-btn variant="text" :disabled="step === '1'" prepend-icon="mdi-chevron-left" @click="step = String(Math.max(1, Number(step) - 1))">Back</v-btn>
          <div class="d-flex ga-2">
            <v-btn v-if="step !== '4'" color="primary" append-icon="mdi-chevron-right" @click="step = String(Number(step) + 1)">Continue</v-btn>
            <v-btn v-else color="primary" prepend-icon="mdi-check-circle" :loading="saving" :disabled="saving" @click="submit">Create Transfer</v-btn>
          </div>
        </div>
      </v-stepper>
    </v-card>
  </div>
</template>

<script setup lang="ts">
import { useTransferApi } from '~/composables/useTransferApi'

definePageMeta({ layout: 'default', permission: 'transfers:create' })

const { $swal } = useNuxtApp()
const { createTransfer } = useTransferApi()
const { currencySymbol } = useCurrency()
const gmaps = useGoogleMaps()

const step = ref('1')
const saving = ref(false)
const pickupInput = ref<any>(null)
const dropoffInput = ref<any>(null)
let pickupAutocomplete: any = null
let dropoffAutocomplete: any = null

// Map state
const mapContainer = ref<HTMLElement | null>(null)
let routeMap: any = null
let pickupMarker: any = null
let dropoffMarker: any = null
let directionsRenderer: any = null
const routeDistance = ref('')
const routeDuration = ref('')
const routeFound = ref(false)
const showMap = ref(false)

const availableVehicles = ref<any[]>([])
const availableDrivers = ref<any[]>([])

const booleanOptions = [
  { label: 'Yes', value: true },
  { label: 'No', value: false },
]

const statusCreateOptions = [
  { title: 'Draft', value: 'draft' },
  { title: 'Scheduled', value: 'scheduled' },
]

const paymentMethodOptions = [
  { title: 'Cash', value: 'cash' },
  { title: 'Card', value: 'card' },
  { title: 'PayPal', value: 'paypal' },
  { title: 'Bank Transfer', value: 'bank_transfer' },
]

const serviceClassCards = [
  { value: 'economy',  label: 'Economy',   icon: 'mdi-car-hatchback',    desc: 'Standard sedan' },
  { value: 'business',  label: 'Business',  icon: 'mdi-car-side',         desc: 'Executive sedan' },
  { value: 'premium',   label: 'Premium',    icon: 'mdi-car-convertible', desc: 'Luxury sedan' },
  { value: 'luxury',    label: 'Luxury',    icon: 'mdi-car-elite',       desc: 'Chauffeured' },
  { value: 'van',       label: 'Van',       icon: 'mdi-van-passenger',    desc: 'Group travel' },
  { value: 'executive', label: 'Executive', icon: 'mdi-car-limousine',    desc: 'VIP transport' },
]

const tripTypeCards = [
  { value: 'one_way',    label: 'One-Way',     icon: 'mdi-arrow-right' },
  { value: 'round_trip', label: 'Round Trip',  icon: 'mdi-swap-horizontal' },
  { value: 'hourly',     label: 'Hourly Hire', icon: 'mdi-clock-time-four' },
]

const defaultForm = () => ({
  passenger_name: '', passenger_email: '', passenger_phone: '',
  passenger_count: 1, luggage_count: 0, has_child_seat: false, has_infant_seat: false,
  passenger_notes: '',

  pickup_name: '', pickup_address: '', pickup_lat: undefined as any,
  pickup_lng: undefined as any, pickup_datetime: '', pickup_flight_no: '',
  dropoff_name: '', dropoff_address: '', dropoff_lat: undefined as any,
  dropoff_lng: undefined as any, dropoff_datetime: '',

  trip_type: 'one_way', service_class: 'business',

  vehicle: null as any, driver: null as any,

  base_fare: 0, distance_km: 0, estimated_duration_min: 0,
  tolls_amount: 0, parking_amount: 0, meet_greet_fee: 0,
  waiting_fee: 0, child_seat_fee: 0, driver_tip: 0,
  tax_amount: 0, discount_amount: 0, total_amount: 0,
  currency: 'USD', return_datetime: '',

  status: 'scheduled', payment_method: '', notes: '',
  amount_paid: 0, payment_reference: '', feedback: '',

  stops: [] as any[],
})

const form = reactive<any>(defaultForm())

const computedTotal = computed(() => {
  const t = (form.base_fare || 0) + (form.tolls_amount || 0) + (form.parking_amount || 0) +
    (form.meet_greet_fee || 0) + (form.waiting_fee || 0) + (form.child_seat_fee || 0) +
    (form.driver_tip || 0) + (form.tax_amount || 0) - (form.discount_amount || 0)
  return Math.max(0, Number(t.toFixed(2)))
})

const pickFDate = computed(() => {
  if (!form.pickup_datetime) return ''
  const d = new Date(form.pickup_datetime)
  return d.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
})

function addStop() {
  form.stops.push({ sequence: form.stops.length + 1, place_name: '', address: '', duration_min: 0 })
}
function removeStop(i: number) { form.stops.splice(i, 1) }

function classLabel(c: string) {
  const map: Record<string, string> = { economy: 'Economy', business: 'Business', premium: 'Premium', luxury: 'Luxury', van: 'Van', executive: 'Executive' }
  return map[c] || c
}
function tripLabel(t: string) {
  const map: Record<string, string> = { one_way: 'One-Way', round_trip: 'Round Trip', hourly: 'Hourly Hire' }
  return map[t] || t
}

let autocompleteInitialized = false

async function initAutocomplete() {
  if (autocompleteInitialized) return
  try {
    const google = await gmaps.ensureGoogle()

    // Pickup
    if (pickupInput.value) {
      const el = pickupInput.value.$el?.querySelector?.('input') || pickupInput.value.$el
      if (el instanceof HTMLInputElement) {
        pickupAutocomplete = new google.maps.places.Autocomplete(el, {
          types: ['geocode', 'establishment'],
          fields: ['address_components', 'formatted_address', 'geometry', 'name', 'place_id', 'types'],
        })
        pickupAutocomplete.addListener('place_changed', () => {
          const place = pickupAutocomplete.getPlace()
          if (place?.geometry) {
            form.pickup_lat = Number(place.geometry.location.lat().toFixed(6))
            form.pickup_lng = Number(place.geometry.location.lng().toFixed(6))
            form.pickup_address = place.formatted_address || form.pickup_address
            if (!form.pickup_name && place.name) form.pickup_name = place.name
            showMap.value = true
            nextTick(() => buildMap())
          }
        })
      }
    }

    // Dropoff
    if (dropoffInput.value) {
      const el = dropoffInput.value.$el?.querySelector?.('input') || dropoffInput.value.$el
      if (el instanceof HTMLInputElement) {
        dropoffAutocomplete = new google.maps.places.Autocomplete(el, {
          types: ['geocode', 'establishment'],
          fields: ['address_components', 'formatted_address', 'geometry', 'name', 'place_id', 'types'],
        })
        dropoffAutocomplete.addListener('place_changed', () => {
          const place = dropoffAutocomplete.getPlace()
          if (place?.geometry) {
            form.dropoff_lat = Number(place.geometry.location.lat().toFixed(6))
            form.dropoff_lng = Number(place.geometry.location.lng().toFixed(6))
            form.dropoff_address = place.formatted_address || form.dropoff_address
            if (!form.dropoff_name && place.name) form.dropoff_name = place.name
            showMap.value = true
            nextTick(() => buildMap())
          }
        })
      }
    }

    // Mark initialized only if at least one was bound
    if (pickupAutocomplete || dropoffAutocomplete) {
      autocompleteInitialized = true
    }
  } catch (e) {
    console.warn('Google Maps autocomplete unavailable, manual entry only', e)
  }
}

function ensureMapInstance(): boolean {
  if (!mapContainer.value) return false
  if (!routeMap && (form.pickup_lat || form.dropoff_lat)) {
    const centerLat = form.pickup_lat ?? form.dropoff_lat ?? 40.7128
    const centerLng = form.pickup_lng ?? form.dropoff_lng ?? -74.006
    routeMap = gmaps.createMap(mapContainer.value, { lat: centerLat, lng: centerLng }, 12)
  }
  return !!routeMap
}

async function buildMap() {
  try {
    const google = await gmaps.ensureGoogle()
    if (!ensureMapInstance()) return

    // Clear old markers
    if (pickupMarker) { pickupMarker.setMap(null); pickupMarker = null }
    if (dropoffMarker) { dropoffMarker.setMap(null); dropoffMarker = null }
    if (directionsRenderer) { directionsRenderer.setMap(null); directionsRenderer = null }

    const hasPickup = form.pickup_lat != null && form.pickup_lng != null
    const hasDropoff = form.dropoff_lat != null && form.dropoff_lng != null

    if (!hasPickup && !hasDropoff) return

    // Add pickup marker
    if (hasPickup) {
      pickupMarker = new google.maps.Marker({
        position: { lat: form.pickup_lat, lng: form.pickup_lng },
        map: routeMap,
        label: { text: 'A', color: '#fff', fontWeight: 'bold', fontSize: '11px' },
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 16,
          fillColor: '#16a34a',
          fillOpacity: 1,
          strokeColor: '#fff',
          strokeWeight: 2,
        },
      })
    }

    // Add dropoff marker
    if (hasDropoff) {
      dropoffMarker = new google.maps.Marker({
        position: { lat: form.dropoff_lat, lng: form.dropoff_lng },
        map: routeMap,
        label: { text: 'B', color: '#fff', fontWeight: 'bold', fontSize: '11px' },
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 16,
          fillColor: '#dc2626',
          fillOpacity: 1,
          strokeColor: '#fff',
          strokeWeight: 2,
        },
      })
    }

    // If both points exist, draw driving route + auto-fill distance/duration
    if (hasPickup && hasDropoff) {
      directionsRenderer = new google.maps.DirectionsRenderer({
        suppressMarkers: true,
        polylineOptions: { strokeColor: '#4f46e5', strokeWeight: 4, strokeOpacity: 0.85 },
      })
      directionsRenderer.setMap(routeMap)

      try {
        const result = await gmaps.getDirections(
          { lat: form.pickup_lat, lng: form.pickup_lng },
          { lat: form.dropoff_lat, lng: form.dropoff_lng },
        )
        directionsRenderer.setDirections(result)

        const leg = result.routes?.[0]?.legs?.[0]
        if (leg) {
          routeDistance.value = leg.distance?.text || ''
          routeDuration.value = leg.duration?.text || ''
          // Auto-fill numeric fields
          if (leg.distance?.value) form.distance_km = Number((leg.distance.value / 1000).toFixed(2))
          if (leg.duration?.value) form.estimated_duration_min = Math.round(leg.duration.value / 60)
          routeFound.value = true
        }
      } catch (e) {
        console.warn('Directions service failed, showing markers only', e)
      }

      // Fit bounds to both markers
      const bounds = new google.maps.LatLngBounds()
      if (hasPickup) bounds.extend({ lat: form.pickup_lat, lng: form.pickup_lng })
      if (hasDropoff) bounds.extend({ lat: form.dropoff_lat, lng: form.dropoff_lng })
      routeMap.fitBounds(bounds, 60)
    } else {
      // Single point: center on it
      const pt = hasPickup
        ? { lat: form.pickup_lat, lng: form.pickup_lng }
        : { lat: form.dropoff_lat, lng: form.dropoff_lng }
      routeMap.setCenter(pt)
      routeMap.setZoom(15)
    }
  } catch (e) {
    console.warn('Map build failed', e)
  }
}

async function useCurrentLocation(target: 'pickup' | 'dropoff') {
  try {
    const pos = await gmaps.getCurrentPosition()
    const lat = Number(pos.lat.toFixed(6))
    const lng = Number(pos.lng.toFixed(6))

    if (target === 'pickup') {
      form.pickup_lat = lat
      form.pickup_lng = lng
    } else {
      form.dropoff_lat = lat
      form.dropoff_lng = lng
    }

    // Reverse geocode to fill address
    const addr = await gmaps.reverseGeocode(lat, lng)
    if (addr) {
      if (target === 'pickup') {
        form.pickup_address = addr
        if (!form.pickup_name) form.pickup_name = 'Current Location'
      } else {
        form.dropoff_address = addr
        if (!form.dropoff_name) form.dropoff_name = 'Current Location'
      }
    }

    showMap.value = true
    nextTick(() => buildMap())
  } catch (e) {
    $swal.fire({ icon: 'error', title: 'Location Error', text: 'Could not get your current location.' })
  }
}

async function loadVehicles() {
  try {
    const { $api } = useNuxtApp()
    const data: any = await $api('/vehicles/vehicles/', { query: { page_size: 100 } })
    const items = data.results || data
    availableVehicles.value = items.map((v: any) => ({ label: v.display_name || `Vehicle #${v.id}`, value: v.id, license_plate: v.license_plate || '' }))
  } catch (e) {
    console.error('Failed to load vehicles:', e)
    availableVehicles.value = []
  }
}

async function loadDrivers() {
  try {
    const { $api } = useNuxtApp()
    const data: any = await $api('/contacts/drivers/', { query: { page_size: 100 } })
    const items = data.results || data
    availableDrivers.value = items.map((d: any) => ({ label: d.full_name, value: d.id }))
  } catch (e) {
    console.error('Failed to load drivers:', e)
    availableDrivers.value = []
  }
}

async function submit() {
  if (saving.value) return
  saving.value = true
  try {
    if (!form.passenger_name) { $swal.fire({ icon: 'warning', title: 'Required', text: 'Passenger name is required.' }); return }
    if (!form.pickup_name || !form.dropoff_name) { $swal.fire({ icon: 'warning', title: 'Required', text: 'Pickup and drop-off names are required.' }); return }
    if (!form.pickup_datetime) { $swal.fire({ icon: 'warning', title: 'Required', text: 'Pickup date & time is required.' }); return }
    if (!form.base_fare || Number(form.base_fare) <= 0) { $swal.fire({ icon: 'warning', title: 'Required', text: 'Base fare is required and must be greater than 0.' }); return }

    form.total_amount = computedTotal.value
    const payload = { ...form }
    // Convert datetime-local strings to ISO 8601 and drop empty datetime fields
    const dateTimeFields = ['pickup_datetime', 'dropoff_datetime', 'return_datetime']
    for (const dt of dateTimeFields) {
      if (payload[dt]) {
        payload[dt] = new Date(payload[dt]).toISOString()
      } else {
        delete payload[dt]
      }
    }
    // Clean undefined/null numbers
    Object.keys(payload).forEach(k => {
      if (payload[k] === undefined) delete payload[k]
    })
    const created = await createTransfer(payload)
    $swal.fire({ icon: 'success', title: 'Created', text: `Transfer ${created.reference} created.`, timer: 2500, toast: true, position: 'top-end', showConfirmButton: false })
    navigateTo(`/app/transfers/${created.id}`)
  } catch (e: any) {
    console.error('Transfer create error:', e)
    let msg = 'Failed to create transfer.'
    if (e?.data) {
      if (typeof e.data === 'string') msg = e.data
      else if (e.data.detail) msg = e.data.detail
      else msg = JSON.stringify(e.data)
    }
    $swal.fire({ icon: 'error', title: 'Error', text: msg })
  } finally { saving.value = false }
}

function goBack() { navigateTo('/app/transfers') }

// Re-render map when step 2 becomes visible & init autocomplete (stepper may lazy-render step 2)
watch(step, (v) => {
  if (v === '2') {
    nextTick(() => {
      initAutocomplete()
      if (showMap.value) buildMap()
    })
  }
})

onMounted(async () => {
  await Promise.all([loadVehicles(), loadDrivers()])
  // Default currency from tenant
  try { form.currency = useCurrency().currency.value.code || 'USD' } catch {}
  await initAutocomplete()
})
</script>

<style scoped>
/* ===== Hero Header ===== */
.transfer-hero-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 18px 24px; border-radius: 16px;
  background: linear-gradient(135deg, #4f46e5, #6366f1, #7c3aed);
  box-shadow: 0 8px 24px rgba(79, 70, 229, 0.25);
}
.transfer-hero-icon {
  width: 48px; height: 48px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  background: rgba(255,255,255,0.18);
  backdrop-filter: blur(8px);
}

/* ===== Wizard Card ===== */
.transfer-wizard-card {
  overflow: hidden;
}
.transfer-stepper-header {
  background: linear-gradient(to bottom, #f8fafc, #ffffff);
  border-bottom: 1px solid #e2e8f0;
  padding: 8px 16px;
}

/* ===== Section Labels ===== */
.section-label {
  display: flex; align-items: center; gap: 8px;
  font-size: 14px; font-weight: 700; color: #1e293b;
  letter-spacing: -0.01em;
}
.section-label .v-icon {
  background: rgba(79, 70, 229, 0.1);
  border-radius: 8px; padding: 6px;
}

/* ===== Service Class Cards ===== */
.class-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(100%, 140px), 1fr));
  gap: 10px;
}
.class-card {
  display: flex; flex-direction: column; align-items: center; text-align: center;
  padding: 14px 8px 10px; border-radius: 12px; cursor: pointer;
  border: 2px solid #e2e8f0; background: #ffffff;
  transition: all 0.2s ease;
}
.class-card:hover {
  border-color: #c7d2fe; transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.12);
}
.class-card-active {
  background: linear-gradient(135deg, #4f46e5, #6366f1);
  border-color: transparent;
  box-shadow: 0 6px 16px rgba(79, 70, 229, 0.3);
}
.class-card-active .v-icon { color: #fff !important; }

/* ===== Trip Type Cards ===== */
.trip-type-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}
.trip-type-card {
  display: flex; flex-direction: column; align-items: center; text-align: center;
  padding: 12px 8px; border-radius: 12px; cursor: pointer;
  border: 2px solid #e2e8f0; background: #ffffff;
  transition: all 0.2s ease;
}
.trip-type-card:hover { border-color: #c7d2fe; }
.trip-type-card-active {
  border-color: primary; background: rgba(79, 70, 229, 0.06);
  box-shadow: 0 0 0 1px #4f46e5 inset;
}

/* ===== Route Cards ===== */
.route-card { border-radius: 14px; border: 1px solid #e2e8f0; overflow: hidden; }
.route-card-pickup { border-color: #bbf7d0; }
.route-card-dropoff { border-color: #fecaca; }
.route-card-header {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 16px; color: #fff;
}
.route-card-pickup .route-card-header { background: linear-gradient(135deg, #16a34a, #15803d); }
.route-card-dropoff .route-card-header { background: linear-gradient(135deg, #dc2626, #b91c1c); }
.route-dot-large {
  width: 12px; height: 12px; border-radius: 50%;
  border: 3px solid rgba(255,255,255,0.4);
  flex-shrink: 0;
}

/* ===== Stops ===== */
.stop-row {
  display: flex; align-items: center; gap: 8px;
  padding: 8px; border-radius: 10px;
  background: #f8fafc; border: 1px solid #e2e8f0;
}
.stop-dot-info {
  width: 28px; height: 28px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: rgba(59, 130, 246, 0.1);
  flex-shrink: 0;
}

/* ===== Fare Total Panel ===== */
.fare-total-panel {
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 20px; border-radius: 14px;
  background: linear-gradient(135deg, #4f46e5, #7c3aed);
  box-shadow: 0 8px 20px rgba(79, 70, 229, 0.3);
}

/* ===== Review Summary Card ===== */
.review-summary-card {
  border-radius: 16px; border: 1px solid #e2e8f0; overflow: hidden;
  box-shadow: 0 4px 16px rgba(0,0,0,0.06);
}
.review-summary-header {
  display: flex; align-items: center; gap: 10px;
  padding: 14px 20px;
  background: linear-gradient(135deg, #4f46e5, #6366f1, #7c3aed);
}

/* ===== Route Visualization ===== */
.review-route { position: relative; }
.review-route-line {
  position: absolute; left: 5px; top: 18px; bottom: 18px;
  width: 2px; background: linear-gradient(to bottom, #22c55e, #ef4444);
  margin-left: 0;
}
.route-dot-sm {
  width: 12px; height: 12px; border-radius: 50%;
  border: 3px solid #fff;
  box-shadow: 0 0 0 1px currentColor;
  flex-shrink: 0; margin-top: 4px; z-index: 1;
  position: relative;
}
.review-info-item {
  display: flex; align-items: flex-start; gap: 10px;
}
.review-info-item .v-icon { margin-top: 2px; }

/* ===== Transitions ===== */
.stop-list-enter-active, .stop-list-leave-active { transition: all 0.3s ease; }
.stop-list-enter-from, .stop-list-leave-to { opacity: 0; transform: translateX(-20px); }

/* ===== Map Preview ===== */
.map-preview-container {
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  padding: 12px;
  background: #f8fafc;
}
.route-map {
  width: 100%;
  height: 320px;
  border-radius: 10px;
  overflow: hidden;
  border: 1px solid #e2e8f0;
}
</style>
