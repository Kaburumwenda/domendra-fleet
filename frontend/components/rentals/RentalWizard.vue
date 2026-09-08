<template>
  <div class="rw-page">
    <!-- Sticky left sidebar with steps -->
    <aside class="rw-sidebar">
      <div class="rw-sidebar-header">
        <div class="rw-sidebar-icon">
          <v-icon size="24" color="white">mdi-car-key</v-icon>
        </div>
        <div>
          <h2 class="rw-sidebar-title">Rental Agreement</h2>
          <p class="rw-sidebar-sub">{{ props.editing ? 'Edit mode' : 'New agreement' }}</p>
        </div>
      </div>

      <div class="rw-sidebar-steps">
        <div
          v-for="(s, i) in steps"
          :key="i"
          class="rw-sidebar-step"
          :class="{ 'rw-sidebar-step--active': current === i, 'rw-sidebar-step--done': current > i }"
          @click="current = i"
        >
          <div class="rw-sidebar-step-circle">
            <v-icon v-if="current > i" size="16">mdi-check</v-icon>
            <span v-else>{{ i + 1 }}</span>
          </div>
          <div class="rw-sidebar-step-info">
            <div class="rw-sidebar-step-title">{{ s.title }}</div>
            <div class="rw-sidebar-step-sub">{{ s.subtitle }}</div>
          </div>
        </div>
      </div>

      <div class="rw-sidebar-footer">
        <v-btn variant="text" block size="small" prepend-icon="mdi-arrow-left" @click="goBack">
          Back to Agreements
        </v-btn>
      </div>
    </aside>

    <!-- Main content area -->
    <main class="rw-main">
      <!-- Top bar -->
      <div class="rw-topbar">
        <div class="rw-topbar-left">
          <h1 class="rw-topbar-title">{{ props.editing ? `Edit ${props.editing.agreement_no}` : 'New Rental Agreement' }}</h1>
          <p class="rw-topbar-desc">{{ props.editing ? 'Modify the rental agreement details below' : 'Complete the form below to create a new rental agreement' }}</p>
        </div>
        <div class="rw-topbar-right">
          <div class="rw-topbar-progress">
            <span class="rw-topbar-progress-label">Step {{ current + 1 }} of {{ steps.length }}</span>
            <div class="rw-topbar-progress-bar">
              <div class="rw-topbar-progress-fill" :style="{ width: ((current + 1) / steps.length * 100) + '%' }" />
            </div>
          </div>
        </div>
      </div>

      <!-- Step content -->
      <div class="rw-content">
        <v-window v-model="current">
          <!-- Step 1 Customer -->
          <v-window-item :value="0">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-account</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Customer</h3>
                <p class="rw-step-desc">Choose an existing customer or create a new one</p>
              </div>
            </div>
            <v-row dense>
              <v-col cols="12" class="mb-2">
                <v-autocomplete
                  v-model="form.customer"
                  :items="customerOptions"
                  item-title="label"
                  item-value="id"
                  label="Select existing customer *"
                  prepend-inner-icon="mdi-account-search-outline"
                  hide-details="auto"
                  clearable
                  @update:model-value="onCustomerSelected"
                />
              </v-col>
            </v-row>
            <v-alert v-if="selectedCustomer" type="info" variant="tonal" density="compact" class="mb-3">
              <strong>{{ selectedCustomer.full_name }}</strong> · {{ selectedCustomer.customer_type }} · ID: {{ selectedCustomer.id_number }} · {{ selectedCustomer.phone || 'no phone' }}
            </v-alert>
            <v-alert v-else type="warning" variant="tonal" density="compact" class="mb-3">
              No customer selected. Pick one from the dropdown above, or create one in the <a href="/app/rentals?tab=customers">Customers tab</a>.
            </v-alert>
            <div class="mb-3 text-caption text-medium-emphasis">{{ selectedCustomer ? 'Customer details (pre-filled from selected customer — edit if needed)' : 'New customer fields (used only if creating on the fly):' }}</div>
            <v-row dense>
              <v-col cols="6">
                <v-select v-model="newCustomer.customer_type" :items="[{title:'Local',value:'local'},{title:'Foreigner',value:'foreigner'}]" item-title="title" item-value="value" label="Customer Type" prepend-inner-icon="mdi-account-eye-outline" hide-details="auto" />
              </v-col>
              <v-col cols="6">
                <v-text-field v-model="newCustomer.full_name" label="Full Name" prepend-inner-icon="mdi-account" hide-details="auto" />
              </v-col>
              <v-col cols="6"><v-text-field v-model="newCustomer.phone" label="Phone" prepend-inner-icon="mdi-phone-outline" hide-details="auto" /></v-col>
              <v-col cols="6"><v-text-field v-model="newCustomer.email" label="Email" prepend-inner-icon="mdi-email-outline" hide-details="auto" /></v-col>
              <v-col cols="6"><v-text-field v-model="newCustomer.id_number" label="ID Number" prepend-inner-icon="mdi-identifier" hide-details="auto" /></v-col>
              <v-col cols="6"><v-text-field v-model="newCustomer.driving_license_no" label="Driving License No." prepend-inner-icon="mdi-card-bulleted-outline" hide-details="auto" /></v-col>
              <v-col cols="12">
                <v-text-field
                  ref="addressInputRef"
                  v-model="newCustomer.address"
                  label="Address"
                  prepend-inner-icon="mdi-map-marker-outline"
                  hide-details="auto"
                  autocomplete="off"
                  placeholder="Start typing an address…"
                >
                  <template #append-inner>
                    <v-progress-circular v-if="addressLoading" indeterminate size="16" width="2" color="primary" />
                  </template>
                </v-text-field>
              </v-col>
            </v-row>
          </v-window-item>

          <!-- Step 2 Vehicle & Rental Period -->
          <v-window-item :value="1">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-car</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Vehicle and Rental Period</h3>
                <p class="rw-step-desc">Select the vehicle, pickup/return dates and locations</p>
              </div>
            </div>
            <v-row dense>
              <v-col cols="12" md="6">
                <v-autocomplete
                  v-model="form.vehicle"
                  :items="vehicleOptions"
                  item-title="label"
                  item-value="id"
                  label="Vehicle *"
                  prepend-inner-icon="mdi-car-search"
                  hide-details="auto"
                  clearable
                  @update:model-value="previewRate"
                >
                  <template #item="{ item, props: itemProps }">
                    <v-list-item
                      v-bind="itemProps"
                      :disabled="item.raw.disabled"
                      :base-color="item.raw.disabled ? 'grey' : undefined"
                    >
                      <template #prepend>
                        <v-icon :color="item.raw.disabled ? 'grey' : 'primary'">
                          {{ item.raw.disabled ? 'mdi-car-off' : 'mdi-car' }}
                        </v-icon>
                      </template>
                      <template v-if="item.raw.disabled" #append>
                        <v-chip size="x-small" color="error" variant="tonal">On Rent</v-chip>
                      </template>
                      <template v-else-if="item.raw.rental_status === 'on_rent'" #append>
                        <v-chip size="x-small" color="info" variant="tonal">Current</v-chip>
                      </template>
                    </v-list-item>
                  </template>
                </v-autocomplete>
              </v-col>
              <v-col cols="12" md="6">
                <v-select v-model="form.rate_period" :items="ratePeriodOptions" item-title="label" item-value="value" label="Rate Period *" prepend-inner-icon="mdi-calendar-sync-outline" hide-details="auto" @update:model-value="onRatePeriodChange" />
              </v-col>
              <v-col cols="12">
                <div class="d-flex align-center gap-2 flex-wrap">
                  <span class="text-caption text-medium-emphasis me-1">Quick select:</span>
                  <v-chip
                    v-for="chip in durationChips"
                    :key="chip.value"
                    :color="selectedDuration === chip.value ? 'primary' : undefined"
                    :variant="selectedDuration === chip.value ? 'flat' : 'outlined'"
                    size="small"
                    label
                    @click="applyDuration(chip.value)"
                  >{{ chip.label }}</v-chip>
                </div>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="form.start_datetime" type="datetime-local" label="Pickup Date &amp; Time *" prepend-inner-icon="mdi-calendar-clock" hide-details="auto" @update:model-value="previewRate" />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="form.end_datetime" type="datetime-local" label="Return Date &amp; Time *" prepend-inner-icon="mdi-calendar-check" hide-details="auto" @update:model-value="previewRate" />
              </v-col>
              <v-col cols="6">
                <v-combobox
                  v-model="form.pickup_location"
                  :items="locationOptions"
                  item-title="name"
                  item-value="name"
                  label="Pickup Location *"
                  prepend-inner-icon="mdi-map-marker-plus-outline"
                  hide-details="auto"
                  clearable
                  chips
                  :return-object="false"
                  placeholder="Select or type a location"
                />
              </v-col>
              <v-col cols="6">
                <v-combobox
                  v-model="form.dropoff_location"
                  :items="locationOptions"
                  item-title="name"
                  item-value="name"
                  label="Drop-off Location *"
                  prepend-inner-icon="mdi-map-marker-minus-outline"
                  hide-details="auto"
                  clearable
                  chips
                  :return-object="false"
                  placeholder="Select or type a location"
                />
              </v-col>
              <v-col cols="6"><v-text-field v-model.number="form.start_mileage" type="number" label="Start Mileage (km) *" prepend-inner-icon="mdi-counter" hide-details="auto" /></v-col>
              <v-col cols="6">
                <v-select v-model="form.fuel_policy" :items="fuelPolicyOptions" item-title="label" item-value="value" label="Fuel Policy *" prepend-inner-icon="mdi-gas-station-outline" hide-details="auto" />
              </v-col>
              <!-- Fuel Level Gauges -->
              <v-col cols="12">
                <div class="fuel-gauge-section">
                  <!-- Start Fuel -->
                  <div class="fuel-gauge-block">
                    <div class="fuel-gauge-header">
                      <v-icon size="16" color="primary">mdi-gauge</v-icon>
                      <span>Start Fuel Level</span>
                      <v-chip size="x-small" variant="flat" :color="fuelChipColor('start_fuel_level')">{{ fuelName('start_fuel_level') }}</v-chip>
                    </div>
                    <div
                      ref="startFuelTrackRef"
                      class="fuel-gauge-track fuel-gauge-track--draggable"
                      @pointerdown="(e) => onFuelPointerDown(e, 'start_fuel_level')"
                    >
                      <div class="fuel-gauge-ticks">
                        <div v-for="t in fuelTicks" :key="t" class="fuel-gauge-tick" :class="{ 'fuel-gauge-tick--major': t % 25 === 0 }" :style="{ left: t + '%' }"></div>
                      </div>
                      <div class="fuel-gauge-fill" :style="{ width: fuelPercent('start_fuel_level') + '%', background: fuelFillColor('start_fuel_level') }"></div>
                      <div class="fuel-gauge-knob" :style="{ left: fuelPercent('start_fuel_level') + '%' }"></div>
                    </div>
                    <div class="fuel-gauge-labels">
                      <button v-for="level in fuelLevels" :key="level.value" class="fuel-gauge-btn" :class="{ 'fuel-gauge-btn--active': form.start_fuel_level === level.value }" @click="form.start_fuel_level = level.value">{{ level.label }}</button>
                    </div>
                    <div class="text-caption text-medium-emphasis mt-1">Drag the slider for exact level (5% steps) or tap a marker for quick select</div>
                  </div>
                </div>
              </v-col>
            </v-row>
          </v-window-item>

          <!-- Step 3 Pricing -->
          <v-window-item :value="2">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-cash-multiple</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Pricing and Add-ons</h3>
                <p class="rw-step-desc">Set rates, assign a driver, and configure add-on fees</p>
              </div>
            </div>
            <v-row dense>
              <v-col cols="12">
                <v-select
                  v-model="selectedPricingPlanId"
                  :items="applicablePricingPlans"
                  item-title="label"
                  item-value="id"
                  label="Pricing Plan (auto-fills fields below)"
                  prepend-inner-icon="mdi-cash-fast"
                  hint="Filtered by the selected vehicle's type or specific assignment"
                  persistent-hint
                  clearable
                  hide-details="auto"
                  :disabled="!form.vehicle"
                  @update:model-value="onPricingPlanSelected"
                >
                  <template #item="{ item, props }">
                    <v-list-item v-bind="props">
                      <template #prepend>
                        <v-icon :color="item.raw.vehicle_type_color || 'primary'">
                          {{ item.raw.vehicle_type_icon || 'mdi-tag-text-outline' }}
                        </v-icon>
                      </template>
                      <v-list-item-subtitle>
                        {{ item.raw.vehicle_type_name || 'Specific Vehicles' }} ·
                        Daily {{ item.raw.daily_rate }} · Weekly {{ item.raw.weekly_rate }}
                      </v-list-item-subtitle>
                    </v-list-item>
                  </template>
                </v-select>
              </v-col>
              <v-col v-if="!form.vehicle" cols="12">
                <v-alert type="info" density="compact" variant="tonal" class="text-caption">
                  Select a vehicle in Step 2 first to see applicable pricing plans.
                </v-alert>
              </v-col>

              <v-col cols="6" md="3"><v-text-field v-if="form.rate_period === 'daily'" v-model.number="form.daily_rate" type="number" :label="ratePeriodLabel + ' Rate'" :prefix="currencySymbol" prepend-inner-icon="mdi-cash" hide-details="auto" @update:model-value="previewRate" /></v-col>
              <v-col cols="6" md="3"><v-text-field v-if="form.rate_period === 'weekly'" v-model.number="form.weekly_rate" type="number" label="Weekly Rate" :prefix="currencySymbol" prepend-inner-icon="mdi-cash" hide-details="auto" @update:model-value="previewRate" /></v-col>
              <v-col cols="6" md="3"><v-text-field v-if="form.rate_period === 'monthly'" v-model.number="form.monthly_rate" type="number" label="Monthly Rate" :prefix="currencySymbol" prepend-inner-icon="mdi-cash" hide-details="auto" @update:model-value="previewRate" /></v-col>
              <v-col cols="6" md="3"><v-text-field v-if="form.rate_period === 'weekend'" v-model.number="form.weekend_rate" type="number" label="Weekend Rate" :prefix="currencySymbol" prepend-inner-icon="mdi-cash" hide-details="auto" @update:model-value="previewRate" /></v-col>

              <v-col cols="12" class="mt-3"><p class="rw-mini-title">Driver</p></v-col>
              <v-col cols="12" md="6">
                <v-select
                  v-model="form.driver"
                  :items="driverOptions"
                  item-title="label"
                  item-value="id"
                  label="Assigned Driver"
                  prepend-inner-icon="mdi-account-tie-hat-outline"
                  hint="Select an available driver (optional)"
                  persistent-hint
                  clearable
                  hide-details="auto"
                  @update:model-value="previewRate"
                />
              </v-col>
              <v-col v-if="form.driver" cols="6" md="3">
                <v-text-field
                  v-model.number="form.driver_daily_rate"
                  type="number"
                  label="Driver Daily Rate"
                  :prefix="currencySymbol"
                  prepend-inner-icon="mdi-cash"
                  hide-details="auto"
                  @update:model-value="previewRate"
                />
              </v-col>
              <v-col v-if="form.driver" cols="6" md="3">
                <v-text-field
                  :model-value="rentalDays"
                  label="Rental Days"
                  suffix="days"
                  prepend-inner-icon="mdi-calendar"
                  readonly
                  hide-details="auto"
                />
              </v-col>
              <v-col v-if="form.driver" cols="12">
                <v-alert type="info" density="compact" variant="tonal" class="text-caption">
                  Total driver cost: {{ currencySymbol }}{{ driverTotalCost.toFixed(2) }}
                  ({{ rentalDays }} day{{ rentalDays === 1 ? '' : 's' }} × {{ currencySymbol }}{{ Number(form.driver_daily_rate || 0).toFixed(2) }}/day)
                </v-alert>
              </v-col>
              <v-col v-if="form.driver && !form.driver_daily_rate" cols="12">
                <v-alert type="warning" density="compact" variant="tonal" class="text-caption">
                  Enter a daily rate for the driver to calculate the total cost.
                </v-alert>
              </v-col>

              <v-col cols="6" md="3"><v-text-field v-model.number="form.excess_mileage_rate" type="number" label="Excess Rate / hr" :prefix="currencySymbol" hide-details="auto" /></v-col>

              <v-col cols="12" class="mt-3"><v-textarea v-model="form.notes" label="Notes / Terms" rows="5" prepend-inner-icon="mdi-note-text-outline" hide-details="auto" /></v-col>
            </v-row>

            <div class="rw-total-preview">
              <div class="rw-total-preview-header">
                <v-icon size="16" color="primary">mdi-calculator-variant-outline</v-icon>
                <span>Cost Summary</span>
              </div>
              <div class="rw-total-row"><span>Base rental</span><span>{{ currencySymbol }}{{ totalPreview.base.toFixed(2) }}</span></div>
              <div v-if="form.driver" class="rw-total-row"><span>Driver ({{ rentalDays }} day{{ rentalDays === 1 ? '' : 's' }})</span><span>{{ currencySymbol }}{{ driverTotalCost.toFixed(2) }}</span></div>
              <div class="rw-total-row"><span>Add-ons</span><span>{{ currencySymbol }}{{ (totalPreview.addons - driverTotalCost).toFixed(2) }}</span></div>
              <div v-if="totalPreview.damages > 0" class="rw-total-row"><span>Damages</span><span>{{ currencySymbol }}{{ totalPreview.damages.toFixed(2) }}</span></div>
              <div v-if="totalPreview.charges > 0" class="rw-total-row"><span>Extra Charges</span><span>{{ currencySymbol }}{{ totalPreview.charges.toFixed(2) }}</span></div>
              <div class="rw-total-row"><span>Subtotal</span><span>{{ currencySymbol }}{{ totalPreview.subtotal.toFixed(2) }}</span></div>
              <div v-if="totalPreview.discount > 0" class="rw-total-row"><span>Discount (plan)</span><span>- {{ currencySymbol }}{{ totalPreview.discount.toFixed(2) }}</span></div>
              <div class="rw-total-row"><span>Taxes ({{ form.tax_percent || 0 }}%)</span><span>{{ currencySymbol }}{{ totalPreview.tax.toFixed(2) }}</span></div>
              <div class="rw-total-grand">
                <span>Total</span>
                <span>{{ currencySymbol }}{{ totalPreview.total.toFixed(2) }}</span>
              </div>
            </div>
          </v-window-item>

          <!-- Step 4 Damages & Additional Charges -->
          <v-window-item :value="3">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-car-wrench</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Additional Charges and Damages</h3>
                <p class="rw-step-desc">Log any pre-existing damage or extra charges</p>
              </div>
            </div>
            <v-row dense class="mb-2">
              <v-col cols="12"><p class="rw-mini-title">Additional Charges</p></v-col>
              <v-col cols="12">
                <div v-for="(c, i) in form.charges" :key="i" class="rw-line-row">
                  <v-select v-model="c.charge_type" :items="chargeTypeOptions" item-title="label" item-value="value" label="Type" density="compact" variant="outlined" hide-details class="rw-line-col-1" />
                  <v-text-field v-model="c.description" label="Description" density="compact" variant="outlined" hide-details class="rw-line-col-2" />
                  <v-text-field v-model.number="c.quantity" type="number" label="Qty" density="compact" variant="outlined" hide-details class="rw-line-col-3" />
                  <v-text-field v-model.number="c.unit_amount" type="number" label="Unit" density="compact" variant="outlined" hide-details class="rw-line-col-4" @update:model-value="c.total_amount = Number(c.quantity || 0) * Number(c.unit_amount || 0)" />
                  <v-text-field v-model.number="c.total_amount" type="number" label="Total" density="compact" variant="outlined" hide-details class="rw-line-col-5" readonly />
                  <v-btn icon="mdi-trash-can-outline" size="small" variant="text" color="error" @click="form.charges.splice(i, 1)" />
                </div>
                <v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" class="mt-2" @click="form.charges.push({ charge_type: 'other', description: '', quantity: 1, unit_amount: 0, total_amount: 0 })">Add Charge</v-btn>
              </v-col>
            </v-row>

            <v-row dense class="mt-3">
              <v-col cols="12"><p class="rw-mini-title">Damage Inspection (pre/post)</p></v-col>
              <v-col cols="12">
                <div v-for="(d, i) in form.damages" :key="i" class="rw-line-row">
                  <v-text-field v-model="d.location" label="Location" density="compact" variant="outlined" hide-details class="rw-line-col-2" />
                  <v-text-field v-model="d.description" label="Description" density="compact" variant="outlined" hide-details class="rw-line-col-2" />
                  <v-select v-model="d.severity" :items="['none','minor','moderate','severe']" label="Severity" density="compact" variant="outlined" hide-details class="rw-line-col-3" />
                  <v-text-field v-model.number="d.repair_cost" type="number" label="Repair Cost" density="compact" variant="outlined" hide-details class="rw-line-col-4" />
                  <v-btn icon="mdi-trash-can-outline" size="small" variant="text" color="error" @click="form.damages.splice(i, 1)" />
                </div>
                <v-btn size="small" variant="tonal" color="warning" prepend-icon="mdi-plus" class="mt-2" @click="form.damages.push({ location: '', description: '', severity: 'minor', repair_cost: 0 })">Add Damage</v-btn>
              </v-col>
            </v-row>
          </v-window-item>

          <!-- Step 5 Vehicle Extras Check -->
          <v-window-item :value="4">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-checkbox-marked-circle-outline</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Vehicle Extras Check</h3>
                <p class="rw-step-desc">Inspect and record the status of each vehicle extra at pickup</p>
              </div>
            </div>
            <v-alert type="info" variant="tonal" density="compact" class="mb-3">
              Tick off each item's status at pickup. All items default to <strong>Present</strong> — just change the ones that are missing or damaged. Add notes for any issues.
            </v-alert>
            <div class="d-flex ga-2 mb-3 flex-wrap align-center">
              <v-btn size="small" variant="tonal" color="success" prepend-icon="mdi-check-all" @click="form.vehicle_checks.forEach((vc:any) => vc.status = 'present')">Mark All Present</v-btn>
              <v-btn size="small" variant="tonal" color="warning" prepend-icon="mdi-alert-circle-outline" @click="form.vehicle_checks.forEach((vc:any) => vc.status = 'missing')">Mark All Missing</v-btn>
              <v-spacer />
              <v-btn size="small" variant="outlined" color="primary" prepend-icon="mdi-plus-circle-outline" @click="extrasDialog = true">Add Extra</v-btn>
            </div>
            <v-row dense>
              <v-col v-for="(vc, i) in form.vehicle_checks" :key="i" cols="12" md="6" lg="4">
                <v-card variant="outlined" class="pa-3" :class="{ 'border-success': vc.status === 'present', 'border-warning': vc.status === 'missing', 'border-error': vc.status === 'damaged' }">
                  <div class="d-flex align-center mb-2">
                    <v-icon
                      :color="checkStatusOptions.find((o:any) => o.value === vc.status)?.color || 'grey'"
                      size="18"
                      class="me-2"
                    >
                      {{ vc.status === 'present' ? 'mdi-check-circle' : vc.status === 'missing' ? 'mdi-alert-circle' : vc.status === 'damaged' ? 'mdi-car-broken' : 'mdi-minus-circle' }}
                    </v-icon>
                    <span class="text-body-2 font-weight-medium flex-grow-1">{{ vc.item_name }}</span>
                    <v-icon v-if="!defaultExtraKeys.has(vc.item_key)" size="18" color="error" class="ms-2 cursor-pointer" @click="removeExtra(i)" title="Remove">mdi-close-circle-outline</v-icon>
                  </div>
                  <v-select
                    v-model="vc.status"
                    :items="checkStatusOptions"
                    item-title="label"
                    item-value="value"
                    density="compact"
                    variant="outlined"
                    hide-details
                  />
                  <v-text-field
                    v-model="vc.notes"
                    label="Notes"
                    density="compact"
                    variant="outlined"
                    hide-details
                    class="mt-2"
                  />
                </v-card>
              </v-col>
            </v-row>

            <!-- Add Extra dialog -->
            <v-dialog v-model="extrasDialog" max-width="560">
              <v-card rounded="xl">
                <v-card-title class="d-flex align-center">
                  <v-icon class="me-2" color="primary">mdi-plus-circle-outline</v-icon>
                  <span class="text-h6">Add Vehicle Extra</span>
                  <v-spacer />
                  <v-btn icon="mdi-close" variant="text" size="small" @click="extrasDialog = false" />
                </v-card-title>
                <v-divider />
                <v-card-text class="pt-3">
                  <p class="text-caption text-medium-emphasis mb-3">Select from common vehicle extras, or add a custom one below.</p>
                  <v-chip-group v-if="availableAddons.length">
                    <v-chip
                      v-for="addon in availableAddons"
                      :key="addon.key"
                      size="small"
                      variant="outlined"
                      prepend-icon="mdi-plus"
                      @click="addExtra(addon)"
                    >{{ addon.label }}</v-chip>
                  </v-chip-group>
                  <v-alert v-else type="info" density="compact" variant="tonal" class="mb-3">
                    All known extras have already been added. You can still add a custom one below.
                  </v-alert>
                  <v-divider class="my-3" />
                  <p class="text-body-2 font-weight-medium mb-2">Custom extra</p>
                  <v-text-field
                    v-model="customExtraName"
                    label="Custom extra name"
                    prepend-inner-icon="mdi-tag-plus-outline"
                    placeholder="e.g. Bike Rack"
                    hide-details="auto"
                    density="compact"
                    variant="outlined"
                    @keyup.enter="addCustomExtra()"
                  />
                </v-card-text>
                <v-card-actions class="px-4 pb-4">
                  <v-spacer />
                  <v-btn variant="text" @click="extrasDialog = false">Cancel</v-btn>
                  <v-btn color="primary" variant="flat" prepend-icon="mdi-plus" :disabled="!customExtraName.trim()" @click="addCustomExtra(); extrasDialog = false">Add Custom</v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
          </v-window-item>

          <!-- Step 6 Vehicle Inspection -->
          <v-window-item :value="5">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-clipboard-check-outline</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Vehicle Inspection</h3>
                <p class="rw-step-desc">Check vehicle condition — lights, horn, battery, tires, cleaning and more</p>
              </div>
            </div>
            <v-alert type="info" variant="tonal" density="compact" class="mb-3">
              Inspect each item and mark its status. All items default to <strong>Pass</strong> — change any item to <strong>Fail</strong> or <strong>Warning</strong> as needed, and add notes for any issues found.
            </v-alert>

            <!-- Summary chips -->
            <div class="d-flex ga-2 mb-3 flex-wrap align-center">
              <v-chip size="small" variant="flat" color="success" prepend-icon="mdi-check-circle">
                {{ inspectionSummary.passed }} Passed
              </v-chip>
              <v-chip v-if="inspectionSummary.failed" size="small" variant="flat" color="error" prepend-icon="mdi-alert-circle">
                {{ inspectionSummary.failed }} Failed
              </v-chip>
              <v-chip v-if="inspectionSummary.warnings" size="small" variant="flat" color="warning" prepend-icon="mdi-alert">
                {{ inspectionSummary.warnings }} Warnings
              </v-chip>
              <v-chip size="small" variant="outlined" color="grey" prepend-icon="mdi-counter">
                {{ inspectionSummary.total }} Total
              </v-chip>
              <v-spacer />
              <v-btn size="small" variant="tonal" color="success" prepend-icon="mdi-check-all" @click="form.inspection_checks.forEach((ic:any) => ic.status = 'pass')">Mark All Pass</v-btn>
            </div>

            <v-row dense>
              <v-col v-for="(ic, i) in form.inspection_checks" :key="i" cols="12" md="6" lg="4">
                <v-card variant="outlined" class="pa-3" :class="{ 'border-success': ic.status === 'pass', 'border-error': ic.status === 'fail', 'border-warning': ic.status === 'warning' }">
                  <div class="d-flex align-center mb-2">
                    <v-icon
                      :color="inspectionStatusOptions.find((o:any) => o.value === ic.status)?.color || 'grey'"
                      size="18"
                      class="me-2"
                    >
                      {{ ic.status === 'pass' ? 'mdi-check-circle' : ic.status === 'fail' ? 'mdi-close-circle' : ic.status === 'warning' ? 'mdi-alert' : 'mdi-minus-circle' }}
                    </v-icon>
                    <v-icon
                      :color="inspectionStatusOptions.find((o:any) => o.value === ic.status)?.color || 'grey'"
                      size="16"
                      class="me-1"
                      style="opacity: 0.6"
                    >
                      {{ vehicleInspectionCatalog.find((c:any) => c.key === ic.item_key)?.icon || 'mdi-wrench' }}
                    </v-icon>
                    <span class="text-body-2 font-weight-medium flex-grow-1">{{ ic.item_name }}</span>
                    <!-- Battery serial number button -->
                    <v-btn
                      v-if="ic.item_key === 'battery' && form.vehicle"
                      size="x-small"
                      variant="tonal"
                      color="primary"
                      prepend-icon="mdi-barcode-scan"
                      :loading="batteryLoading"
                      @click="fetchVehicleBatteries"
                    >Check Serial</v-btn>
                    <!-- Tire serial number button -->
                    <v-btn
                      v-if="ic.item_key === 'tires' && form.vehicle"
                      size="x-small"
                      variant="tonal"
                      color="primary"
                      prepend-icon="mdi-barcode-scan"
                      :loading="tireLoading"
                      @click="fetchVehicleTires"
                    >Check Serial</v-btn>
                  </div>
                  <v-select
                    v-model="ic.status"
                    :items="inspectionStatusOptions"
                    item-title="label"
                    item-value="value"
                    density="compact"
                    variant="outlined"
                    hide-details
                  />
                  <v-text-field
                    v-model="ic.notes"
                    label="Notes"
                    density="compact"
                    variant="outlined"
                    hide-details
                    class="mt-2"
                    placeholder="e.g. Left headlight dim"
                  />
                  <!-- Battery serial number panel -->
                  <div v-if="ic.item_key === 'battery' && form.vehicle && vehicleBatteries.length" class="mt-3 pt-3" style="border-top: 1px solid rgba(var(--v-theme-on-surface), 0.12)">
                    <div class="text-caption font-weight-bold mb-2">Battery Serial Numbers</div>
                    <div v-for="bat in vehicleBatteries" :key="bat.id" class="d-flex align-center mb-2">
                      <v-icon size="16" class="me-2" color="primary">mdi-car-battery</v-icon>
                      <div class="flex-grow-1 me-2">
                        <div class="text-caption text-medium-emphasis">{{ bat.position || '—' }} • {{ bat.brand || 'Unknown' }} {{ bat.model || '' }}</div>
                        <v-text-field
                          v-model="batterySerialEdits[bat.id]"
                          density="compact"
                          variant="outlined"
                          hide-details
                          placeholder="Serial number"
                          class="mt-1"
                          :disabled="batterySaving"
                        />
                      </div>
                      <v-btn
                        size="x-small"
                        variant="text"
                        color="primary"
                        icon="mdi-content-save-outline"
                        :loading="batterySaving"
                        @click="updateBatterySerial(bat.id)"
                      />
                    </div>
                  </div>
                  <v-alert
                    v-else-if="ic.item_key === 'battery' && form.vehicle && !batteryLoading && vehicleBatteries.length === 0"
                    type="info"
                    variant="tonal"
                    density="compact"
                    class="mt-2 text-caption"
                  >No batteries found for this vehicle. Click "Check Serial" to refresh.</v-alert>
                  <!-- Tire serial number panel -->
                  <div v-if="ic.item_key === 'tires' && form.vehicle && vehicleTires.length" class="mt-3 pt-3" style="border-top: 1px solid rgba(var(--v-theme-on-surface), 0.12)">
                    <div class="text-caption font-weight-bold mb-2">Tire Serial Numbers</div>
                    <div v-for="tire in vehicleTires" :key="tire.id" class="d-flex align-center mb-2">
                      <v-icon size="16" class="me-2" color="primary">mdi-tire</v-icon>
                      <div class="flex-grow-1 me-2">
                        <div class="text-caption text-medium-emphasis">{{ tire.position || '—' }} • {{ tire.brand || 'Unknown' }} {{ tire.model || '' }} <span v-if="tire.size">({{ tire.size }})</span></div>
                        <v-text-field
                          v-model="tireSerialEdits[tire.id]"
                          density="compact"
                          variant="outlined"
                          hide-details
                          placeholder="Serial number"
                          class="mt-1"
                          :disabled="tireSaving"
                        />
                      </div>
                      <v-btn
                        size="x-small"
                        variant="text"
                        color="primary"
                        icon="mdi-content-save-outline"
                        :loading="tireSaving"
                        @click="updateTireSerial(tire.id)"
                      />
                    </div>
                  </div>
                  <v-alert
                    v-else-if="ic.item_key === 'tires' && form.vehicle && !tireLoading && vehicleTires.length === 0"
                    type="info"
                    variant="tonal"
                    density="compact"
                    class="mt-2 text-caption"
                  >No tires found for this vehicle. Click "Check Serial" to refresh.</v-alert>
                  <!-- Headlight failed-parts checkboxes -->
                  <div v-if="ic.item_key === 'headlights' && ic.status === 'fail'" class="mt-2">
                    <div class="text-caption font-weight-medium mb-1">Which headlights failed?</div>
                    <div class="d-flex flex-wrap ga-2">
                      <v-checkbox v-for="part in headlightParts" :key="part" v-model="ic.failed_parts" :value="part" density="compact" hide-details :label="part" />
                    </div>
                    <div v-if="!ic.failed_parts.length" class="text-caption text-medium-emphasis mt-1">Select "All" if all headlights failed, or pick specific ones.</div>
                  </div>
                  <!-- Indicator failed-parts checkboxes -->
                  <div v-if="ic.item_key === 'indicators' && ic.status === 'fail'" class="mt-2">
                    <div class="text-caption font-weight-medium mb-1">Which indicators failed?</div>
                    <div class="d-flex flex-wrap ga-2">
                      <v-checkbox v-for="part in indicatorParts" :key="part" v-model="ic.failed_parts" :value="part" density="compact" hide-details :label="part" />
                    </div>
                    <div v-if="!ic.failed_parts.length" class="text-caption text-medium-emphasis mt-1">Select "All" if all indicators failed, or pick specific ones.</div>
                  </div>
                </v-card>
              </v-col>
            </v-row>

            <!-- Inspection note -->
            <v-row dense class="mt-3">
              <v-col cols="12">
                <v-textarea
                  v-model="form.inspection_notes"
                  label="Additional inspection notes"
                  rows="2"
                  prepend-inner-icon="mdi-note-text-outline"
                  hide-details="auto"
                  placeholder="Any additional observations about the vehicle condition…"
                />
              </v-col>
            </v-row>
          </v-window-item>

          <!-- Step 7 Signatures -->
          <v-window-item :value="6">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-draw</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Digital Signatures</h3>
                <p class="rw-step-desc">Capture signatures from the renter and company representative</p>
              </div>
            </div>
            <v-alert type="info" variant="tonal" density="compact" class="mb-4">
              Sign below using your finger, mouse, or stylus. The signatures are captured as vector SVG and embedded in the printable agreement.
            </v-alert>
            <v-row dense>
              <v-col cols="12">
                <SignaturePad v-model="customerSignature" v-model:name="form.signatures[0].signatory_name" label="Renter (Customer) Signature" class="mb-4" />
              </v-col>
              <v-col cols="12">
                <SignaturePad v-model="companySignature" v-model:name="form.signatures[1].signatory_name" label="Company Representative Signature" class="mb-4" />
              </v-col>
            </v-row>
          </v-window-item>

          <!-- Step 8 Terms & Conditions -->
          <v-window-item :value="7">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-file-document-check-outline</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Terms &amp; Conditions</h3>
                <p class="rw-step-desc">Read and accept the rental agreement terms before signing</p>
              </div>
            </div>
            <div class="d-flex align-center justify-space-between mb-3 flex-wrap ga-2">
              <v-alert type="info" variant="tonal" density="compact" class="flex-grow-1">
                Please read all the terms and conditions below carefully. The Renter must accept these terms before the agreement can be created.
              </v-alert>
              <div class="d-flex ga-1">
                <v-btn
                  v-if="!termsEditMode"
                  size="small"
                  variant="tonal"
                  color="primary"
                  prepend-icon="mdi-pencil-outline"
                  @click="termsEditMode = true"
                >
                  Edit Terms
                </v-btn>
                <template v-else>
                  <v-btn
                    size="small"
                    variant="text"
                    color="grey-darken-1"
                    prepend-icon="mdi-undo"
                    @click="resetTerms()"
                  >
                    Reset
                  </v-btn>
                  <v-btn
                    size="small"
                    variant="tonal"
                    color="success"
                    prepend-icon="mdi-check"
                    @click="termsEditMode = false"
                  >
                    Done
                  </v-btn>
                </template>
              </div>
            </div>

            <!-- Terms content scroll box -->
            <v-card elevation="0" border rounded="lg" class="mb-4 rw-terms-box">
              <v-card-text class="pa-4">
                <!-- ===== Read mode ===== -->
                <template v-if="!termsEditMode">
                  <div class="rw-terms-paragraph" v-for="term in termsAndConditions" :key="term.id">
                    <div class="rw-terms-clause">
                      <span class="rw-terms-clause-num">{{ term.id }}.</span>
                      <span class="rw-terms-clause-title">{{ term.title }}</span>
                      <span class="rw-terms-clause-text">{{ term.text }}</span>
                    </div>
                  </div>
                </template>

                <!-- ===== Edit mode ===== -->
                <template v-else>
                  <div
                    v-for="(term, i) in termsAndConditions"
                    :key="'edit-' + i"
                    class="rw-terms-edit-row"
                  >
                    <div class="d-flex align-start ga-2 mb-2">
                      <span class="rw-terms-clause-num pt-3">{{ i + 1 }}.</span>
                      <v-text-field
                        v-model="term.title"
                        density="compact"
                        variant="outlined"
                        hide-details
                        label="Clause title"
                        class="flex-grow-1"
                      />
                      <v-btn
                        icon
                        size="small"
                        variant="text"
                        color="error"
                        @click="removeTermClause(i)"
                      >
                        <v-icon>mdi-delete-outline</v-icon>
                        <v-tooltip activator="parent" location="top">Remove clause</v-tooltip>
                      </v-btn>
                    </div>
                    <v-textarea
                      v-model="term.text"
                      density="compact"
                      variant="outlined"
                      hide-details
                      auto-grow
                      rows="2"
                      label="Clause text"
                      class="ms-7 mb-3"
                    />
                  </div>
                  <v-btn
                    size="small"
                    variant="tonal"
                    color="primary"
                    prepend-icon="mdi-plus"
                    class="mt-1"
                    @click="addTermClause()"
                  >
                    Add Clause
                  </v-btn>
                </template>
              </v-card-text>
            </v-card>

            <!-- Acceptance checkbox -->
            <v-checkbox
              v-model="termsAccepted"
              color="primary"
              density="compact"
              class="mb-2"
            >
              <template #label>
                <span class="text-body-2 font-weight-medium">
                  I have read, understood and accept the Terms and Conditions of this Rental Agreement.
                </span>
              </template>
            </v-checkbox>
            <v-alert v-if="!termsAccepted" type="warning" variant="tonal" density="compact" icon="mdi-alert-circle-outline">
              You must accept the terms and conditions to proceed to the Review step.
            </v-alert>
          </v-window-item>

          <!-- Step 9 Review -->
          <v-window-item :value="8">
            <div class="rw-step-header">
              <div class="rw-step-icon"><v-icon size="22" color="white">mdi-clipboard-check-outline</v-icon></div>
              <div>
                <h3 class="rw-step-heading">Review & Confirm</h3>
                <p class="rw-step-desc">Verify all details before creating the agreement</p>
              </div>
            </div>
            <v-alert type="info" variant="tonal" density="compact" class="mb-4">
              Please review all information below. Use the sidebar to go back and edit any step. When everything looks correct, click <strong>{{ props.editing ? 'Update Agreement' : 'Create Agreement' }}</strong> at the bottom.
            </v-alert>

            <!-- Customer -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-account</v-icon> Customer</p>
            <v-row dense class="mb-3">
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Name</label><div>{{ selectedCustomer?.full_name || newCustomer.full_name || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Type</label><div class="text-capitalize">{{ selectedCustomer?.customer_type || newCustomer.customer_type || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Phone</label><div>{{ selectedCustomer?.phone || newCustomer.phone || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Email</label><div>{{ selectedCustomer?.email || newCustomer.email || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>ID Number</label><div>{{ selectedCustomer?.id_number || newCustomer.id_number || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>License No</label><div>{{ selectedCustomer?.driving_license_no || newCustomer.driving_license_no || '—' }}</div></div></v-col>
            </v-row>

            <!-- Vehicle & Period -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-car</v-icon> Vehicle & Rental Period</p>
            <v-row dense class="mb-3">
              <v-col cols="6" md="4"><div class="rw-review-field"><label>Vehicle</label><div>{{ reviewVehicle?.display_name || reviewVehicle?.label || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>License Plate</label><div>{{ reviewVehicle?.license_plate || '—' }}</div></div></v-col>
              <v-col cols="6" md="2"><div class="rw-review-field"><label>Rate Period</label><div>{{ ratePeriodLabel }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Rental Duration</label><div>{{ rentalDays }} day{{ rentalDays === 1 ? '' : 's' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Start Date</label><div>{{ formatReviewDate(form.start_datetime) }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>End Date</label><div>{{ formatReviewDate(form.end_datetime) }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Pickup Location</label><div>{{ form.pickup_location || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Drop-off Location</label><div>{{ form.dropoff_location || '—' }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Start Mileage</label><div>{{ form.start_mileage ?? '—' }} km</div></div></v-col>
            </v-row>

            <!-- Pricing & Add-ons -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-cash-multiple</v-icon> Rates & Add-ons</p>
            <v-row dense class="mb-3">
              <v-col cols="6" md="3"><div class="rw-review-field"><label>{{ ratePeriodLabel }} Rate</label><div>{{ currencySymbol }}{{ activeRateValue.toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Insurance</label><div>{{ form.insurance_type || '—' }} · {{ currencySymbol }}{{ Number(form.insurance_premium || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="2"><div class="rw-review-field"><label>GPS</label><div>{{ currencySymbol }}{{ Number(form.gps_fee || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="2"><div class="rw-review-field"><label>Child Seat</label><div>{{ currencySymbol }}{{ Number(form.child_seat_fee || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="2"><div class="rw-review-field"><label>Add'l Driver</label><div>{{ currencySymbol }}{{ Number(form.additional_driver_fee || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="2"><div class="rw-review-field"><label>Delivery</label><div>{{ currencySymbol }}{{ Number(form.delivery_fee || 0).toFixed(2) }}</div></div></v-col>
              <v-col v-if="form.driver" cols="6" md="4"><div class="rw-review-field"><label>Driver</label><div>{{ reviewDriver?.label || '—' }} · {{ currencySymbol }}{{ Number(form.driver_daily_rate || 0).toFixed(2) }}/day ({{ currencySymbol }}{{ driverTotalCost.toFixed(2) }} total)</div></div></v-col>
            </v-row>

            <!-- Deposits & Mileage -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-shield-account-outline</v-icon> Deposits & Mileage</p>
            <v-row dense class="mb-3">
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Security Deposit</label><div>{{ currencySymbol }}{{ Number(form.security_deposit || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Damage Deposit</label><div>{{ currencySymbol }}{{ Number(form.damage_deposit || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Discount</label><div>{{ form.discount_percent || 0 }}% + {{ currencySymbol }}{{ Number(form.discount_amount || 0).toFixed(2) }}</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Tax Rate</label><div>{{ form.tax_percent || 0 }}%</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Free Mileage</label><div>{{ form.free_mileage || 0 }} km</div></div></v-col>
              <v-col cols="6" md="3"><div class="rw-review-field"><label>Excess / km</label><div>{{ currencySymbol }}{{ Number(form.excess_mileage_rate || 0).toFixed(2) }}</div></div></v-col>
            </v-row>

            <!-- Fuel -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-gas-station-outline</v-icon> Fuel</p>
            <v-row dense class="mb-3">
              <v-col cols="6" md="4"><div class="rw-review-field"><label>Policy</label><div class="text-capitalize">{{ fuelPolicyLabel }}</div></div></v-col>
              <v-col cols="6" md="4">
                <div class="rw-review-field">
                  <label>Start Fuel Level</label>
                  <div class="d-flex align-center ga-2">
                    <v-chip :color="fuelChipColor('start_fuel_level')" size="small" label>{{ fuelName('start_fuel_level') }}</v-chip>
                  </div>
                </div>
              </v-col>
            </v-row>
            <div class="rw-review-fuel-row mb-3">
              <div class="rw-review-fuel-block">
                <span class="rw-review-fuel-caption">Start gauge</span>
                <div class="rw-review-fuel-track">
                  <div class="rw-review-fuel-fill" :style="{ width: fuelPercent('start_fuel_level') + '%', background: fuelFillColor('start_fuel_level') }">
                    <span class="rw-review-fuel-pct">{{ fuelPercent('start_fuel_level') }}%</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Additional Charges -->
            <template v-if="form.charges.length">
              <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-receipt-text-outline</v-icon> Additional Charges</p>
              <v-table density="compact" class="mb-3 rw-review-table">
                <thead><tr><th>Type</th><th>Description</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead>
                <tbody>
                  <tr v-for="(c, i) in form.charges" :key="'rv-c-' + i">
                    <td class="text-capitalize">{{ chargeTypeOptions.find((o:any) => o.value === c.charge_type)?.label || c.charge_type }}</td>
                    <td>{{ c.description || '—' }}</td>
                    <td>{{ c.quantity || 1 }}</td>
                    <td>{{ currencySymbol }}{{ Number(c.unit_amount || 0).toFixed(2) }}</td>
                    <td><b>{{ currencySymbol }}{{ Number(c.total_amount || 0).toFixed(2) }}</b></td>
                  </tr>
                </tbody>
              </v-table>
            </template>

            <!-- Damages -->
            <template v-if="form.damages.length">
              <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-car-wrench</v-icon> Damages</p>
              <v-table density="compact" class="mb-3 rw-review-table">
                <thead><tr><th>Location</th><th>Description</th><th>Severity</th><th>Repair Cost</th></tr></thead>
                <tbody>
                  <tr v-for="(d, i) in form.damages" :key="'rv-d-' + i">
                    <td>{{ d.location || '—' }}</td>
                    <td>{{ d.description || '—' }}</td>
                    <td class="text-capitalize">{{ d.severity || 'none' }}</td>
                    <td>{{ currencySymbol }}{{ Number(d.repair_cost || 0).toFixed(2) }}</td>
                  </tr>
                </tbody>
              </v-table>
            </template>

            <!-- Vehicle Extras Check -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-checkbox-marked-circle-outline</v-icon> Vehicle Extras Check</p>
            <v-table density="compact" class="mb-3 rw-review-table">
              <thead><tr><th>Item</th><th>Status</th><th>Notes</th></tr></thead>
              <tbody>
                <tr v-for="(vc, i) in form.vehicle_checks" :key="'rv-vc-' + i">
                  <td>{{ vc.item_name || '—' }}</td>
                  <td>
                    <v-chip :color="checkStatusOptions.find((o:any) => o.value === vc.status)?.color || 'grey'" size="small" label class="text-capitalize">{{ checkStatusOptions.find((o:any) => o.value === vc.status)?.label || vc.status }}</v-chip>
                  </td>
                  <td>{{ vc.notes || '—' }}</td>
                </tr>
              </tbody>
            </v-table>

            <!-- Vehicle Inspection -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-clipboard-check-outline</v-icon> Vehicle Inspection</p>
            <div class="d-flex ga-2 mb-2 flex-wrap">
              <v-chip size="small" variant="flat" color="success">{{ inspectionSummary.passed }} Passed</v-chip>
              <v-chip v-if="inspectionSummary.failed" size="small" variant="flat" color="error">{{ inspectionSummary.failed }} Failed</v-chip>
              <v-chip v-if="inspectionSummary.warnings" size="small" variant="flat" color="warning">{{ inspectionSummary.warnings }} Warnings</v-chip>
            </div>
            <v-table density="compact" class="mb-3 rw-review-table">
              <thead><tr><th>Item</th><th>Status</th><th>Notes</th></tr></thead>
              <tbody>
                <tr v-for="(ic, i) in form.inspection_checks" :key="'rv-ic-' + i">
                  <td>{{ ic.item_name || '—' }}</td>
                  <td>
                    <v-chip :color="inspectionStatusOptions.find((o:any) => o.value === ic.status)?.color || 'grey'" size="small" label class="text-capitalize">{{ inspectionStatusOptions.find((o:any) => o.value === ic.status)?.label || ic.status }}</v-chip>
                  </td>
                  <td>
                    <template v-if="ic.failed_parts && ic.failed_parts.length">
                      <div class="mb-1"><v-chip v-for="fp in ic.failed_parts" :key="fp" size="x-small" color="error" variant="tonal" class="me-1 mb-1">{{ fp }}</v-chip></div>
                    </template>
                    {{ ic.notes || '—' }}
                  </td>
                </tr>
              </tbody>
            </v-table>
            <template v-if="form.inspection_notes">
              <div class="rw-review-notes mb-3">{{ form.inspection_notes }}</div>
            </template>

            <!-- Battery Serial Numbers -->
            <template v-if="vehicleBatteries.length">
              <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-car-battery</v-icon> Battery Serial Numbers</p>
              <v-table density="compact" class="mb-3 rw-review-table">
                <thead><tr><th>Position</th><th>Brand / Model</th><th>Serial Number</th><th>Status</th></tr></thead>
                <tbody>
                  <tr v-for="bat in vehicleBatteries" :key="'rv-bat-' + bat.id">
                    <td class="text-capitalize">{{ bat.position || '—' }}</td>
                    <td>{{ bat.brand || '—' }} {{ bat.model || '' }}</td>
                    <td><code>{{ bat.serial_number || '—' }}</code></td>
                    <td class="text-capitalize">{{ bat.status || '—' }}</td>
                  </tr>
                </tbody>
              </v-table>
            </template>

            <!-- Tire Serial Numbers -->
            <template v-if="vehicleTires.length">
              <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-tire</v-icon> Tire Serial Numbers</p>
              <v-table density="compact" class="mb-3 rw-review-table">
                <thead><tr><th>Position</th><th>Brand / Model</th><th>Size</th><th>Serial Number</th><th>Status</th></tr></thead>
                <tbody>
                  <tr v-for="tire in vehicleTires" :key="'rv-tire-' + tire.id">
                    <td class="text-capitalize">{{ tire.position || '—' }}</td>
                    <td>{{ tire.brand || '—' }} {{ tire.model || '' }}</td>
                    <td>{{ tire.size || '—' }}</td>
                    <td><code>{{ tire.serial_number || '—' }}</code></td>
                    <td class="text-capitalize">{{ tire.status || '—' }}</td>
                  </tr>
                </tbody>
              </v-table>
            </template>

            <!-- Cost Summary -->
            <div class="rw-total-preview">
              <div class="rw-total-preview-header">
                <v-icon size="16" color="primary">mdi-calculator-variant-outline</v-icon>
                <span>Cost Summary</span>
              </div>
              <div class="rw-total-row"><span>Base rental ({{ rentalDays }} day{{ rentalDays === 1 ? '' : 's' }})</span><span>{{ currencySymbol }}{{ totalPreview.base.toFixed(2) }}</span></div>
              <div v-if="form.driver" class="rw-total-row"><span>Driver ({{ rentalDays }} day{{ rentalDays === 1 ? '' : 's' }})</span><span>{{ currencySymbol }}{{ driverTotalCost.toFixed(2) }}</span></div>
              <div class="rw-total-row"><span>Add-ons</span><span>{{ currencySymbol }}{{ (totalPreview.addons - driverTotalCost).toFixed(2) }}</span></div>
              <div v-if="totalPreview.damages > 0" class="rw-total-row"><span>Damages</span><span>{{ currencySymbol }}{{ totalPreview.damages.toFixed(2) }}</span></div>
              <div v-if="totalPreview.charges > 0" class="rw-total-row"><span>Extra Charges</span><span>{{ currencySymbol }}{{ totalPreview.charges.toFixed(2) }}</span></div>
              <div class="rw-total-row"><span>Subtotal</span><span>{{ currencySymbol }}{{ totalPreview.subtotal.toFixed(2) }}</span></div>
              <div v-if="totalPreview.discount > 0" class="rw-total-row"><span>Discount</span><span>- {{ currencySymbol }}{{ totalPreview.discount.toFixed(2) }}</span></div>
              <div class="rw-total-row"><span>Taxes ({{ form.tax_percent || 0 }}%)</span><span>{{ currencySymbol }}{{ totalPreview.tax.toFixed(2) }}</span></div>
              <div class="rw-total-grand">
                <span>Total</span>
                <span>{{ currencySymbol }}{{ totalPreview.total.toFixed(2) }}</span>
              </div>
            </div>

            <!-- Signatures -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-draw</v-icon> Signatures</p>
            <v-row dense class="mb-3">
              <v-col cols="6">
                <div class="rw-review-sig-box">
                  <div class="rw-review-sig-label">Renter (Customer)</div>
                  <div v-if="customerSignature" class="rw-review-sig-image" v-html="customerSignature"></div>
                  <div v-else class="rw-review-sig-empty">Not signed</div>
                  <div class="rw-review-sig-meta">{{ form.signatures[0]?.signatory_name || '—' }}</div>
                </div>
              </v-col>
              <v-col cols="6">
                <div class="rw-review-sig-box">
                  <div class="rw-review-sig-label">Company Representative</div>
                  <div v-if="companySignature" class="rw-review-sig-image" v-html="companySignature"></div>
                  <div v-else class="rw-review-sig-empty">Not signed</div>
                  <div class="rw-review-sig-meta">{{ form.signatures[1]?.signatory_name || '—' }}</div>
                </div>
              </v-col>
            </v-row>

            <!-- Notes -->
            <template v-if="form.notes">
              <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-note-text-outline</v-icon> Notes / Terms</p>
              <div class="rw-review-notes mb-3">{{ form.notes }}</div>
            </template>

            <!-- Terms & Conditions Acceptance -->
            <p class="rw-review-section-title"><v-icon size="16" class="me-1" color="primary">mdi-file-document-check-outline</v-icon> Terms & Conditions</p>
            <div class="d-flex align-center ga-2 mb-3">
              <v-chip :color="termsAccepted ? 'success' : 'error'" size="small" variant="flat" prepend-icon="mdi-clipboard-check" density="compact">
                {{ termsAccepted ? 'Accepted by Renter' : 'Not yet accepted' }}
              </v-chip>
              <span class="text-body-2 text-medium-emphasis">{{ termsAndConditions.length }} clauses of the Sarei Car Hire Tours and Safaris Ltd rental agreement.</span>
            </div>
          </v-window-item>
        </v-window>
      </div>

      <!-- Sticky action bar -->
      <div class="rw-actions">
        <div class="rw-actions-left">
          <v-btn variant="text" :disabled="current === 0" prepend-icon="mdi-arrow-left" @click="current--">
            Back
          </v-btn>
          <div class="rw-actions-progress">
            <div class="rw-actions-progress-bar">
              <div class="rw-actions-progress-fill" :style="{ width: ((current + 1) / steps.length * 100) + '%' }" />
            </div>
            <span class="rw-actions-progress-text">{{ current + 1 }} / {{ steps.length }}</span>
          </div>
        </div>
        <div class="rw-actions-right">
          <v-btn variant="text" @click="goBack">Cancel</v-btn>
          <v-btn v-if="current < steps.length - 1" color="primary" prepend-icon="mdi-arrow-right" @click="next">Next</v-btn>
          <template v-else>
            <v-btn v-if="!props.editing" variant="tonal" color="grey-darken-1" prepend-icon="mdi-content-save-outline" :loading="savingDraft" :disabled="saving" @click="saveAsDraft">
              Save as Draft
            </v-btn>
            <v-select
              v-if="props.editing"
              v-model="editStatus"
              :items="statusOptions"
              density="compact"
              variant="outlined"
              label="Status"
              hide-details
              attach
              style="min-width: 160px; z-index: 9999;"
              :disabled="saving"
            />
            <v-btn color="success" size="large" prepend-icon="mdi-check-circle-outline" :loading="saving" :disabled="saving" @click="save">
              {{ props.editing ? 'Update Agreement' : 'Create Agreement' }}
            </v-btn>
          </template>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ editing?: any | null }>()
const emit = defineEmits<{ close: []; saved: [] }>()
const router = useRouter()

function goBack() {
  emit('close')
  router.push('/app/rentals')
}

const { $api, $swal } = useNuxtApp()
const { currencySymbol } = useCurrency()
const { attachAutocomplete } = useGoogleMaps()

// ── Battery serial number state ──
const vehicleBatteries = ref<any[]>([])
const batteryLoading = ref(false)
const batterySaving = ref(false)
const batterySerialEdits = ref<Record<number, string>>({})

/** Fetch batteries installed on the selected vehicle. */
async function fetchVehicleBatteries() {
  if (!form.vehicle) {
    vehicleBatteries.value = []
    return
  }
  batteryLoading.value = true
  try {
    const res = await $api('/batteries/', { query: { vehicle: form.vehicle, page_size: 50 } })
    const list = res?.results || res || []
    vehicleBatteries.value = list.filter((b: any) => b.status === 'Installed' || b.vehicle === form.vehicle)
    // Initialise edit buffer with current serial numbers
    batterySerialEdits.value = {}
    for (const b of vehicleBatteries.value) {
      batterySerialEdits.value[b.id] = b.serial_number || ''
    }
  } catch {
    vehicleBatteries.value = []
  } finally {
    batteryLoading.value = false
  }
}

/** Update a battery's serial number via PATCH. */
async function updateBatterySerial(batteryId: number) {
  const newSerial = batterySerialEdits.value[batteryId]
  if (newSerial === undefined || newSerial === null) return
  batterySaving.value = true
  try {
    await $api(`/batteries/${batteryId}/`, { method: 'PATCH', body: { serial_number: newSerial } })
    // Update local state
    const bat = vehicleBatteries.value.find((b) => b.id === batteryId)
    if (bat) bat.serial_number = newSerial
    $swal.fire({ icon: 'success', title: 'Serial number updated', toast: true, timer: 1200, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to update serial', text: e?.data?.serial_number?.[0] || e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
    // Revert edit buffer
    const bat = vehicleBatteries.value.find((b) => b.id === batteryId)
    if (bat) batterySerialEdits.value[batteryId] = bat.serial_number || ''
  } finally {
    batterySaving.value = false
  }
}

// ── Tire serial number state ──
const vehicleTires = ref<any[]>([])
const tireLoading = ref(false)
const tireSaving = ref(false)
const tireSerialEdits = ref<Record<number, string>>({})

/** Fetch tires mounted on the selected vehicle. */
async function fetchVehicleTires() {
  if (!form.vehicle) {
    vehicleTires.value = []
    return
  }
  tireLoading.value = true
  try {
    const res = await $api('/tires/', { query: { vehicle: form.vehicle, page_size: 50 } })
    const list = res?.results || res || []
    vehicleTires.value = list.filter((t: any) => t.status === 'mounted' || t.vehicle === form.vehicle)
    // Initialise edit buffer with current serial numbers
    tireSerialEdits.value = {}
    for (const t of vehicleTires.value) {
      tireSerialEdits.value[t.id] = t.serial_number || ''
    }
  } catch {
    vehicleTires.value = []
  } finally {
    tireLoading.value = false
  }
}

/** Update a tire's serial number via PATCH. */
async function updateTireSerial(tireId: number) {
  const newSerial = tireSerialEdits.value[tireId]
  if (newSerial === undefined || newSerial === null) return
  tireSaving.value = true
  try {
    await $api(`/tires/${tireId}/`, { method: 'PATCH', body: { serial_number: newSerial } })
    // Update local state
    const tire = vehicleTires.value.find((t) => t.id === tireId)
    if (tire) tire.serial_number = newSerial
    $swal.fire({ icon: 'success', title: 'Serial number updated', toast: true, timer: 1200, position: 'top-end' })
  } catch (e: any) {
    $swal.fire({ icon: 'error', title: 'Failed to update serial', text: e?.data?.serial_number?.[0] || e?.data?.detail || '', toast: true, timer: 2500, position: 'top-end' })
    // Revert edit buffer
    const tire = vehicleTires.value.find((t) => t.id === tireId)
    if (tire) tireSerialEdits.value[tireId] = tire.serial_number || ''
  } finally {
    tireSaving.value = false
  }
}

const current = ref(0)
const saving = ref(false)
const savingDraft = ref(false)
const termsAccepted = ref(false)
const editStatus = ref('active')
const statusOptions = [
  { title: 'Draft', value: 'draft' },
  { title: 'Active', value: 'active' },
  { title: 'Overdue', value: 'overdue' },
  { title: 'Completed', value: 'completed' },
  { title: 'Cancelled', value: 'cancelled' },
]
const addressInputRef = ref<any>(null)
const addressLoading = ref(false)
let addressAutocomplete: any = null

// Default vehicle extras/accessories shown in the pickup checklist
const vehicleExtrasCatalog = [
  { key: 'spare_wheel', label: 'Spare Wheel' },
  { key: 'wheel_spanner', label: 'Wheel Spanner / Lug Wrench' },
  { key: 'tools', label: 'Tools (general toolkit)' },
  { key: 'first_aid_kit', label: 'First Aid Kit' },
  { key: 'fire_extinguisher', label: 'Fire Extinguisher' },
  { key: 'floor_mats', label: 'Floor Mats' },
]
// Other known extras that can be added on demand
const vehicleExtrasAddons = [
  { key: 'jack', label: 'Jack' },
  { key: 'tape_cd_changer', label: 'Tape / CD Changer' },
  { key: 'warning_triangle', label: 'Warning Triangle' },
  { key: 'spare_keys', label: 'Spare Keys' },
  { key: 'radio', label: 'Radio / Stereo' },
  { key: 'headrests', label: 'Headrests' },
  { key: 'cargo_cover', label: 'Cargo Cover / Tonneau' },
  { key: 'wheel_caps', label: 'Wheel Caps / Hubcaps' },
  { key: 'reflective_jacket', label: 'Reflective Jacket' },
  { key: 'jumper_cables', label: 'Jumper Cables' },
  { key: 'torch', label: 'Torch / Flashlight' },
  { key: 'phone_charger', label: 'Phone Charger' },
  { key: 'navigation_gps', label: 'Navigation / GPS Unit' },
  { key: 'baby_seat', label: 'Baby / Child Seat' },
  { key: 'roof_rack', label: 'Roof Rack / Bars' },
  { key: 'tow_rope', label: 'Tow Rope' },
  { key: 'workshop_manual', label: 'Workshop / Owner Manual' },
  { key: 'spare_fuses', label: 'Spare Fuses' },
  { key: 'registration_docs', label: 'Registration / Logbook' },
  { key: 'insurance_docs', label: 'Insurance / Cover Note' },
  { key: 'license_disc', label: 'License Disc / Sticker' },
]
/** Keys of the six default extras — these can't be removed from the list. */
const defaultExtraKeys = new Set(vehicleExtrasCatalog.map((c) => c.key))
const checkStatusOptions = [
  { label: 'Present', value: 'present', color: 'success' },
  { label: 'Missing', value: 'missing', color: 'warning' },
  { label: 'Damaged', value: 'damaged', color: 'error' },
  { label: 'N/A', value: 'n_a', color: 'grey' },
]

// ── Vehicle Inspection items (headlights, brake lights, horns, etc.) ──
const vehicleInspectionCatalog = [
  { key: 'headlights', label: 'Headlights', icon: 'mdi-car-light-high' },
  { key: 'brake_lights', label: 'Brake Lights', icon: 'mdi-lightbulb-outline' },
  { key: 'indicators', label: 'Indicators / Turn Signals', icon: 'mdi-arrow-left-right-bold' },
  { key: 'horn', label: 'Horn', icon: 'mdi-bullhorn-outline' },
  { key: 'battery', label: 'Battery', icon: 'mdi-car-battery' },
  { key: 'tires', label: 'Tires (all 4 + spare)', icon: 'mdi-tire' },
  { key: 'cleaning', label: 'Vehicle Cleaning', icon: 'mdi-car-wash' },
  { key: 'wipers', label: 'Wiper Blades', icon: 'mdi-wiper-wash' },
  { key: 'mirrors', label: 'Mirrors', icon: 'mdi-car-mirrors' },
  { key: 'seatbelts', label: 'Seatbelts', icon: 'mdi-seatbelt' },
  { key: 'engine_oil', label: 'Engine Oil Level', icon: 'mdi-oil' },
  { key: 'coolant', label: 'Coolant Level', icon: 'mdi-water-thermometer' },
  { key: 'brake_fluid', label: 'Brake Fluid', icon: 'mdi-car-brake' },
  { key: 'ac_heater', label: 'AC / Heater', icon: 'mdi-air-conditioner' },
]

const steps = [
  { title: 'Customer', subtitle: 'Choose or add a customer' },
  { title: 'Vehicle', subtitle: 'Vehicle, rate & period' },
  { title: 'Pricing', subtitle: 'Rates, add-ons, discounts' },
  { title: 'Charges', subtitle: 'Damages & extra fees' },
  { title: 'Extras', subtitle: 'Vehicle extras check' },
  { title: 'Inspection', subtitle: 'Vehicle condition check' },
  { title: 'Signatures', subtitle: 'Digital signatures' },
  { title: 'Terms', subtitle: 'Terms & conditions' },
  { title: 'Review', subtitle: 'Review & confirm details' },
]

// — Terms & Conditions (editable) —
const defaultTermsAndConditions = [
  {
    id: 1,
    title: 'The Contract, Eligibility & Drivers',
    text: 'These Terms and Conditions form a binding contract (the “Agreement”) between Sarei Car Hire Tours and Safaris Ltd (“Sarei”, “we”, “us”) and the renter (“Renter”, “you”). By signing the Rental Agreement you confirm that you are at least 23 years of age, hold a valid driver’s licence (held for a minimum of 2 years) and accept all terms herein. Additional or replacement drivers must be named on the Agreement and must meet the same eligibility requirements. You must carry your original driver’s licence at all times while driving the Vehicle.',
  },
  {
    id: 2,
    title: 'Rental Period, Renewal & Return',
    text: 'The rental period begins on the pick-up date/time and ends on the return date/time specified in the Agreement. The Vehicle must be returned to the agreed drop-off location at or before the end of the rental period. Any extension must be requested and agreed in writing at least 24 hours before the original return time. Unauthorised late return will be charged at one full day’s rental for every 24-hour period or part thereof. The Vehicle must be returned in the same condition as when received, fair wear and tear excepted.',
  },
  {
    id: 3,
    title: 'Permitted & Prohibited Use',
    text: 'The Vehicle must not be used: (a) for any illegal purpose; (b) to carry passengers or goods for hire or reward; (c) in any race, rally, speed test or competition; (d) for driving instruction; (e) to push or tow any other vehicle or trailer; (f) to carry live animals (unless agreed in writing); (g) by any person under the influence of alcohol, drugs or any impairing substance; (h) on unsealed or off-road surfaces unless the Vehicle is expressly designated as a 4×4 for such use; (i) outside the territory or areas permitted under the Agreement.',
  },
  {
    id: 4,
    title: 'Charges, Deposits, Fuel, Mileage & Cleaning',
    text: 'The Renter shall pay all rental charges, deposits, surcharges and fees as specified in the Agreement. A security/damage deposit is payable at the commencement of the rental and is refundable within 14 business days of return, subject to deductions for damage, loss, outstanding charges or cleaning. The Vehicle must be returned with the same fuel level as at pick-up; otherwise a refuelling charge plus a service fee applies. If a mileage limit applies, kilometres in excess of the allowance are charged at the stated excess rate. A cleaning fee will apply if the Vehicle is returned in an excessively dirty condition.',
  },
  {
    id: 5,
    title: 'Cancellation & No-Show',
    text: 'If you cancel more than 72 hours before the scheduled pick-up, any advance rental payment is refundable less an administration fee. Cancellations within 72 hours are non-refundable. If you fail to collect the Vehicle at the scheduled time without prior notice (“no-show”), the full rental charge and one day’s rental as a no-show fee will apply and the reservation may be cancelled. Sarei reserves the right to charge a reasonable cancellation fee for administrative costs.',
  },
  {
    id: 6,
    title: 'Insurance, Excess & Excluded Loss',
    text: 'The Vehicle is covered by comprehensive motor insurance subject to the terms, limits and exclusions stated in the Agreement. The Renter is responsible for an excess amount per claim as specified. Insurance cover is void and the Renter shall be fully liable for all damage or loss if: (a) the Vehicle is used in breach of Clause 3; (b) the driver is unlicensed or under the influence; (c) the keys are not removed from the Vehicle or the Vehicle is left unlocked; (d) the incident is not reported as required under Clause 7; or (e) damage is caused to tyres, wheels, undercarriage, glass, interior trim or by overloading.',
  },
  {
    id: 7,
    title: 'Accident, Theft, Fire & Damage',
    text: 'In the event of any accident, theft, fire, vandalism or other damage to the Vehicle, the Renter must: (a) immediately notify Sarei by telephone; (b) report the incident to the police within 24 hours and obtain a case/reference number; (c) complete and sign Sarei’s incident report form; (d) not admit liability or make any settlement without Sarei’s written consent; (e) provide all reasonable assistance to Sarei and its insurers. Failure to comply may render the Renter fully liable for all loss and charges.',
  },
  {
    id: 8,
    title: 'Breakdown & Repairs',
    text: 'In the event of a breakdown or mechanical fault, the Renter must contact Sarei immediately. The Renter must not arrange or undertake any repair, replacement or servicing without Sarei’s prior written authorisation, except in an emergency where authorisation may be given retrospectively. Sarei will arrange recovery and repair at its discretion. The Renter is responsible for recovery costs caused by misuse, negligence or breach of the Agreement.',
  },
  {
    id: 9,
    title: 'Fines, Damage Assessment & Recovery',
    text: 'The Renter is liable for all traffic fines, toll charges, parking penalties and other statutory charges incurred during the rental period. Sarei may recover such amounts from the deposit or charge the Renter’s card on file, plus an administration fee per charge. Sarei reserves the right to assess damage upon return and charge the Renter accordingly. Damage assessment may be conducted by Sarei’s staff or an independent appraiser, and the Renter may request a copy of the assessment.',
  },
  {
    id: 10,
    title: 'Termination & Vehicle Recovery',
    text: 'Sarei may terminate this Agreement and repossess the Vehicle at any time, without notice, if: (a) the Renter breaches any term of the Agreement; (b) the Renter becomes insolvent or bankrupt; (c) the Vehicle is abandoned or left unattended for more than 24 hours; (d) Sarei reasonably believes the Vehicle is at risk. Upon termination, all rental charges and recovery costs become immediately due and payable. Sarei shall not be liable for any loss or damage to the Renter’s property arising from repossession.',
  },
  {
    id: 11,
    title: 'Personal Property, Data & Tracking',
    text: 'The Renter is responsible for all personal belongings left in the Vehicle; Sarei is not liable for loss or damage to such property. The Vehicle may be fitted with a GPS tracking device and/or telematics system. Sarei may collect, store and process location, driving behaviour and vehicle usage data for purposes including fleet management, safety, insurance and recovery. The Renter consents to such data processing and to data being shared with insurers and authorities where necessary.',
  },
  {
    id: 12,
    title: 'Liability, Force Majeure & Substitution',
    text: 'Sarei’s liability for any claim arising from this Agreement is limited to the rental charges paid, save for death or personal injury caused by Sarei’s negligence. Sarei shall not be liable for any indirect, consequential or special damages. Sarei may substitute the Vehicle with a comparable vehicle at any time due to mechanical issues, recall or other operational reasons. Sarei shall not be liable for failure to perform due to force majeure or events beyond its reasonable control.',
  },
  {
    id: 13,
    title: 'Cross-Border, Wilderness Parks & Special Charges',
    text: 'The Vehicle must not be taken outside the country of rental or into any restricted territory without Sarei’s prior written consent and appropriate cross-border authorisation. Additional insurance, fees and documentation may be required for cross-border travel. When travelling in or near national parks, game reserves or wilderness areas, the Renter must comply with all park rules, gate fees are the Renter’s responsibility, and the Vehicle must be locked and secured at all times. Sarei may charge additional fees for specialised equipment, cross-border letters or park-related services.',
  },
  {
    id: 14,
    title: 'Notices, Governing Law & Entire Agreement',
    text: 'All notices to Sarei must be sent to its registered address or by email/fax shown on the Agreement. This Agreement is governed by the laws of the jurisdiction in which the Vehicle is rented, and the parties submit to the exclusive jurisdiction of the courts of that jurisdiction. These Terms and Conditions, together with the Rental Agreement form, constitute the entire agreement between the parties and supersede all prior representations. No variation or waiver is valid unless signed by an authorised representative of Sarei.',
  },
]
const termsAndConditions = ref(JSON.parse(JSON.stringify(defaultTermsAndConditions)))
const termsEditMode = ref(false)

function addTermClause() {
  const nextId = termsAndConditions.value.length > 0
    ? Math.max(...termsAndConditions.value.map((t:any) => t.id)) + 1
    : 1
  termsAndConditions.value.push({ id: nextId, title: '', text: '' })
}

function removeTermClause(index: number) {
  termsAndConditions.value.splice(index, 1)
}

function resetTerms() {
  termsAndConditions.value = JSON.parse(JSON.stringify(defaultTermsAndConditions))
}

function renumberTerms() {
  termsAndConditions.value.forEach((t:any, i:number) => { t.id = i + 1 })
}

const customerSignature = ref('')
const companySignature = ref('')

/** Add-extras dialog state */
const extrasDialog = ref(false)
const filterExtrasDialog = ref(false)
const customExtraName = ref('')
/** Extras that aren't yet in the form.vehicle_checks list and can be added. */
const availableAddons = computed(() => {
  const usedKeys = new Set(form.vehicle_checks.map((vc:any) => vc.item_key))
  return vehicleExtrasAddons.filter((a) => !usedKeys.has(a.key))
})

const customerOptions = ref<any[]>([])
const vehicleOptions = ref<any[]>([])
const locationOptions = ref<any[]>([])
const pricingPlans = ref<any[]>([])
const selectedPricingPlanId = ref<any>(null)
const driverOptions = ref<any[]>([])

const defaultForm = () => ({
  customer: null as any,
  vehicle: null as any,
  status: 'draft',
  rate_period: 'daily',
  daily_rate: 0,
  weekly_rate: 0,
  monthly_rate: 0,
  weekend_rate: 0,
  pickup_location: '',
  dropoff_location: '',
  start_datetime: (() => { const d = new Date(); d.setSeconds(0, 0); return toLocalInput(d) })(),
  end_datetime: (() => { const d = new Date(); d.setSeconds(0, 0); d.setDate(d.getDate() + 1); return toLocalInput(d) })(),
  actual_return_datetime: null,
  insurance_type: 'CDW',
  insurance_premium: 0,
  gps_fee: 0,
  child_seat_fee: 0,
  additional_driver_fee: 0,
  delivery_fee: 0,
  driver: null as any,
  driver_daily_rate: 0,
  discount_percent: 0,
  discount_amount: 0,
  security_deposit: 0,
  damage_deposit: 0,
  free_mileage: 0,
  excess_mileage_rate: 0,
  start_mileage: null as any,
  end_mileage: null as any,
  fuel_policy: 'half_tank',
  start_fuel_level: 'half',
  end_fuel_level: '',
  tax_percent: 0,
  notes: 'The Renter agrees to return the vehicle in the same condition as received, on or before the agreed return date and time. Any late return will incur an additional day charge at the applicable daily rate. The Renter is responsible for any traffic violations, tolls, and damages occurring during the rental period. The vehicle must be returned with the agreed fuel level; otherwise, refuelling charges will apply. This agreement is governed by the terms and conditions issued at the time of rental.',
  charges: [] as any[],
  damages: [] as any[],
  vehicle_checks: vehicleExtrasCatalog.map((c) => ({
    item_key: c.key,
    item_name: c.label,
    status: 'present',
    stage: 'pickup',
    notes: '',
  })) as any[],
  inspection_checks: vehicleInspectionCatalog.map((c) => ({
    item_key: c.key,
    item_name: c.label,
    status: 'pass',
    notes: '',
    failed_parts: [] as string[],
  })) as any[],
  inspection_notes: '',
  signatures: [
    { party_type: 'customer', signatory_name: '', signature_data: '' },
    { party_type: 'company_rep', signatory_name: '', signature_data: '' },
  ],
})

const form = reactive<any>(defaultForm())

// Auto-fetch batteries and tires when the selected vehicle changes
watch(() => form.vehicle, () => {
  fetchVehicleBatteries()
  fetchVehicleTires()
})

const newCustomer = reactive<any>({
  customer_type: 'local', full_name: '', phone: '', email: '', id_number: '',
  driving_license_no: '', id_type: 'national_id', address: '', country: '',
  place_name: '', latitude: null as any, longitude: null as any,
})

const selectedCustomer = ref<any>(null)

const ratePeriodOptions = [
  { label: 'Daily', value: 'daily' },
  { label: 'Weekly', value: 'weekly' },
  { label: 'Monthly', value: 'monthly' },
  { label: 'Weekend', value: 'weekend' },
]
const ratePeriodLabel = computed(() => ratePeriodOptions.find((o) => o.value === form.rate_period)?.label || 'Daily')

/** Quick-select duration chips based on selected rate period. */
const durationChipsByPeriod: Record<string, number[]> = {
  daily: [1, 2, 3, 4, 5, 6],
  weekly: [1, 2, 3],
  monthly: [1, 2, 3, 6],
  weekend: [1],
}
const durationUnitByPeriod: Record<string, string> = {
  daily: 'd',
  weekly: 'w',
  monthly: 'm',
  weekend: 'd',
}

/** Current quick-select chips (derived from rate_period). */
const durationChips = computed(() => {
  const nums = durationChipsByPeriod[form.rate_period] || []
  const unit = durationUnitByPeriod[form.rate_period] || 'd'
  return nums.map((n) => ({ value: n, label: `${n}${unit}` }))
})
const selectedDuration = ref<number>(1)

/** Format a Date as 'YYYY-MM-DDTHH:mm' for datetime-local input. */
function toLocalInput(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** Get the base pickup date — current start_datetime if filled, else now. */
function basePickup(): Date {
  if (form.start_datetime) {
    const d = new Date(form.start_datetime)
    if (!isNaN(d.getTime())) return d
  }
  return new Date()
}

/** Apply a quick-select duration: n days/weeks/months from the pickup date.
 *  Pickup keeps its current time (or now if unset); Return = pickup + N
 *  units at the same clock time (e.g. 1d → 26/07 20:19 → 27/07 20:19). */
function applyDuration(n: number) {
  selectedDuration.value = n
  const start = basePickup()
  // Snap seconds/millis to 0 for a clean datetime-local value
  start.setSeconds(0, 0)
  const end = new Date(start)
  if (form.rate_period === 'weekly') end.setDate(end.getDate() + n * 7)
  else if (form.rate_period === 'monthly') end.setMonth(end.getMonth() + n)
  else if (form.rate_period === 'weekend') end.setDate(end.getDate() + 2)
  else end.setDate(end.getDate() + n)
  form.start_datetime = toLocalInput(start)
  form.end_datetime = toLocalInput(end)
  computePreview()
}

/** When the rate period changes — reset to the first duration and apply it. */
function onRatePeriodChange() {
  const nums = durationChipsByPeriod[form.rate_period] || []
  selectedDuration.value = nums[0] || 1
  applyDuration(selectedDuration.value)
}
const fuelPolicyOptions = [
  { label: 'Full to Full', value: 'full_full' },
  { label: 'Prepaid', value: 'prepaid' },
  { label: 'Half Tank', value: 'half_tank' },
]
const fuelLevels = [
  { value: 'empty', label: 'E', percent: 0, name: 'Empty' },
  { value: 'quarter', label: '¼', percent: 25, name: '¼ Tank' },
  { value: 'half', label: 'H', percent: 50, name: 'Half' },
  { value: 'three_quarter', label: '¾', percent: 75, name: '¾ Tank' },
  { value: 'full', label: 'F', percent: 100, name: 'Full' },
]
/** Tick marks every 5% (0–100); major ticks at 0/25/50/75/100 */
const fuelTicks = Array.from({ length: 21 }, (_, i) => i * 5)
/** Snap increment in percent for fine-grained fuel selection */
const FUEL_SNAP_PCT = 5

/** Resolve form[field] to a 0–100 number (handles named levels and "80%" strings) */
function fuelPercent(field: string): number {
  const val = form[field]
  if (val === undefined || val === null || val === '') return 0
  const named = fuelLevels.find((l) => l.value === val)
  if (named) return named.percent
  const num = Number(String(val).replace('%', ''))
  return isNaN(num) ? 0 : Math.max(0, Math.min(100, num))
}
function fuelName(field: string): string {
  const val = form[field]
  const named = fuelLevels.find((l) => l.value === val)
  if (named) return named.name
  const pct = fuelPercent(field)
  // Show exact percentage with nearest named reference
  const nearest = fuelLevels.reduce((best, l) =>
    Math.abs(l.percent - pct) < Math.abs(best.percent - pct) ? l : best,
  )
  return `${pct}% (near ${nearest.name})`
}
function fuelChipColor(field: string) {
  const p = fuelPercent(field)
  if (p <= 0) return 'error'
  if (p < 25) return 'warning'
  if (p < 50) return 'warning'
  if (p < 75) return 'info'
  if (p < 100) return 'info'
  return 'success'
}
function fuelFillColor(field: string) {
  const p = fuelPercent(field)
  if (p <= 0) return 'linear-gradient(90deg, #ef4444, #f87171)'
  if (p <= 25) return 'linear-gradient(90deg, #f59e0b, #fbbf24)'
  if (p <= 50) return 'linear-gradient(90deg, #eab308, #facc15)'
  if (p <= 75) return 'linear-gradient(90deg, #84cc16, #a3e635)'
  return 'linear-gradient(90deg, #22c55e, #4ade80)'
}

/* ---- Draggable fuel slider ---- */
const startFuelTrackRef = ref<HTMLElement | null>(null)
let _fuelDragField: string | null = null
let _fuelDragTrack: HTMLElement | null = null

/** Snap a 0-100 percentage to the nearest FUEL_SNAP_PCT increment and set form[field].
 *  Uses named level strings (empty/quarter/half/three_quarter/full) when the
 *  snapped value matches exactly; otherwise stores "<pct>%" for fine levels
 *  like 80% (between ¾ and full). */
function _snapAndSet(field: string, pct: number) {
  const snapped = Math.round(pct / FUEL_SNAP_PCT) * FUEL_SNAP_PCT
  const named = fuelLevels.find((l) => l.percent === snapped)
  form[field] = named ? named.value : `${snapped}%`
}

/** Pointer down on track — start dragging */
function onFuelPointerDown(e: PointerEvent, field: string) {
  _fuelDragField = field
  _fuelDragTrack = (e.currentTarget as HTMLElement)
  _updateFromPointer(e)
  window.addEventListener('pointermove', _onFuelPointerMove)
  window.addEventListener('pointerup', _onFuelPointerUp, { once: true })
}

function _updateFromPointer(e: PointerEvent) {
  if (!_fuelDragTrack) return
  const rect = _fuelDragTrack.getBoundingClientRect()
  const pct = Math.max(0, Math.min(100, ((e.clientX - rect.left) / rect.width) * 100))
  if (_fuelDragField) _snapAndSet(_fuelDragField, pct)
}

function _onFuelPointerMove(e: PointerEvent) {
  if (_fuelDragField) _updateFromPointer(e)
}

function _onFuelPointerUp() {
  _fuelDragField = null
  _fuelDragTrack = null
  window.removeEventListener('pointermove', _onFuelPointerMove)
}
const chargeTypeOptions = [
  { label: 'Base Rental', value: 'base_rental' },
  { label: 'Insurance', value: 'insurance' },
  { label: 'GPS', value: 'gps' },
  { label: 'Child Seat', value: 'child_seat' },
  { label: 'Additional Driver', value: 'additional_driver' },
  { label: 'Delivery', value: 'delivery' },
  { label: 'Late Return', value: 'late_return' },
  { label: 'Excess Mileage', value: 'excess_mileage' },
  { label: 'Fuel Refill', value: 'fuel_refill' },
  { label: 'Cleaning', value: 'cleaning' },
  { label: 'Damage', value: 'damage' },
  { label: 'Other', value: 'other' },
]

const totalPreview = reactive({ base: 0, addons: 0, damages: 0, charges: 0, subtotal: 0, discount: 0, tax: 0, total: 0 })

function computePreview() {
  const rateMap: Record<string, any> = {
    daily: Number(form.daily_rate || 0),
    weekly: Number(form.weekly_rate || 0),
    monthly: Number(form.monthly_rate || 0),
    weekend: Number(form.weekend_rate || 0),
  }
  let days = 1
  if (form.start_datetime && form.end_datetime) {
    const start = new Date(form.start_datetime).getTime()
    const end = new Date(form.end_datetime).getTime()
    const ms = Math.max(end - start, 24 * 3600 * 1000)
    // Round to the nearest day so that a 2-day quick-select (pickup 09:00 →
    // return 18:00 +2d, i.e. 2.375 days) counts as 2 days, not 3.
    days = Math.max(Math.round(ms / (24 * 3600 * 1000)), 1)
  }
  if (form.rate_period === 'weekend') days = 2
  let base = (rateMap[form.rate_period] || 0)
  if (form.rate_period === 'weekly') base = base * days / 7
  else if (form.rate_period === 'monthly') base = base * days / 30
  else base = base * days

  const addons = Number(form.insurance_premium || 0) + Number(form.gps_fee || 0) + Number(form.child_seat_fee || 0) + Number(form.additional_driver_fee || 0) + Number(form.delivery_fee || 0) + driverTotalCost.value
  const damagesTotal = form.damages.reduce((sum: number, d: any) => sum + Number(d.repair_cost || 0), 0)
  const chargesTotal = form.charges.reduce((sum: number, c: any) => sum + Number(c.total_amount || 0), 0)
  const subtotal = base + addons + damagesTotal + chargesTotal
  const pctDiscount = subtotal * Number(form.discount_percent || 0) / 100
  const discount = pctDiscount + Number(form.discount_amount || 0)
  const taxable = Math.max(subtotal - discount, 0)
  const tax = taxable * Number(form.tax_percent || 0) / 100

  totalPreview.base = base
  totalPreview.addons = addons
  totalPreview.damages = damagesTotal
  totalPreview.charges = chargesTotal
  totalPreview.subtotal = subtotal
  totalPreview.discount = discount
  totalPreview.tax = tax
  totalPreview.total = taxable + tax
}

function previewRate() { computePreview() }

/** Number of rental days (min 1), based on pickup/return datetimes.
 *  Uses Math.round so a 2-day quick-select (pickup 09:00 → return 18:00 +2d,
 *  i.e. 2.375 days) counts as 2 days, not 3. */
const rentalDays = computed(() => {
  if (!form.start_datetime || !form.end_datetime) return 1
  const start = new Date(form.start_datetime).getTime()
  const end = new Date(form.end_datetime).getTime()
  if (isNaN(start) || isNaN(end)) return 1
  const ms = Math.max(end - start, 24 * 3600 * 1000)
  return Math.max(Math.round(ms / (24 * 3600 * 1000)), 1)
})

/** Total driver cost = driver_daily_rate × rental days (only when a driver is selected). */
const driverTotalCost = computed(() => {
  if (!form.driver) return 0
  return Number(form.driver_daily_rate || 0) * rentalDays.value
})

/** Active rate value based on the selected rate period. */
const activeRateValue = computed(() => {
  const key = form.rate_period + '_rate'
  return Number(form[key] || 0)
})

/** Fuel policy display label. */
const fuelPolicyLabel = computed(() => fuelPolicyOptions.find((o) => o.value === form.fuel_policy)?.label || form.fuel_policy || '—')

// ── Inspection state ──
const inspectionStatusOptions = [
  { label: 'Pass', value: 'pass', color: 'success' },
  { label: 'Fail', value: 'fail', color: 'error' },
  { label: 'Warning', value: 'warning', color: 'warning' },
  { label: 'N/A', value: 'n_a', color: 'grey' },
]
const headlightParts = ['All', 'Left Headlight', 'Right Headlight', 'High Beam Left', 'High Beam Right', 'Low Beam Left', 'Low Beam Right']
const indicatorParts = ['All', 'Front Left', 'Front Right', 'Rear Left', 'Rear Right', 'Side Left', 'Side Right']
const inspectionSummary = computed(() => {
  const total = form.inspection_checks.length
  const passed = form.inspection_checks.filter((ic:any) => ic.status === 'pass').length
  const failed = form.inspection_checks.filter((ic:any) => ic.status === 'fail').length
  const warnings = form.inspection_checks.filter((ic:any) => ic.status === 'warning').length
  return { total, passed, failed, warnings }
})

/** Vehicle object for the review step. */
const reviewVehicle = computed(() => vehicleOptions.value.find((v:any) => v.id === form.vehicle) || null)

/** Driver object for the review step. */
const reviewDriver = computed(() => driverOptions.value.find((d:any) => d.id === form.driver) || null)

/** Format a datetime string for display in the review step. */
function formatReviewDate(d: any): string {
  if (!d) return '—'
  return String(d).slice(0, 16).replace('T', ' ')
}

/** Pricing plans applicable to the currently selected vehicle. */
const applicablePricingPlans = computed(() => {
  if (!form.vehicle) return []
  const veh = vehicleOptions.value.find((v:any) => v.id === form.vehicle)
  if (!veh) return []
  const vehTypeName = (veh.vehicle_type || '').toLowerCase()
  const vehId = veh.id
  return pricingPlans.value.filter((p:any) => {
    if (p.apply_to === 'vehicles') {
      // Plan assigns specific vehicles — check if selected vehicle is in the list
      return Array.isArray(p.vehicle_list) && p.vehicle_list.some((v:any) => v.id === vehId)
    }
    // Group plan — match by vehicle type name (case-insensitive)
    if (p.apply_to === 'group') {
      const planTypeName = (p.vehicle_type_name || '').toLowerCase()
      return planTypeName && planTypeName === vehTypeName
    }
    return false
  })
})

/** Auto-populate pricing fields from the selected plan, keeping them editable. */
function onPricingPlanSelected(planId: any) {
  if (!planId) {
    return
  }
  const plan = pricingPlans.value.find((p:any) => p.id === planId)
  if (!plan) return
  const fields = [
    'daily_rate','weekly_rate','weekend_rate','monthly_rate',
    'insurance_premium','gps_fee','child_seat_fee','additional_driver_fee','delivery_fee',
    'driver_fee','prep_fee','after_hours_fee','underage_fee','one_way_fee',
    'discount_percent','discount_amount',
    'security_deposit','damage_deposit','deposit_amount',
    'free_mileage','excess_mileage_rate','tax_percent',
    'custom_rate_label','custom_rate_value','custom_rate_days',
  ]
  for (const f of fields) {
    if (plan[f] !== undefined && plan[f] !== null) {
      form[f] = Number(plan[f])
    }
  }
  if (plan.custom_rate_label) form.custom_rate_label = plan.custom_rate_label
  if (plan.notes) form.notes = plan.notes
  computePreview()
}

/** Add a known extra from the addons list to the checklist. */
function addExtra(extra: { key: string; label: string }) {
  if (form.vehicle_checks.some((vc:any) => vc.item_key === extra.key)) return
  form.vehicle_checks.push({
    item_key: extra.key,
    item_name: extra.label,
    status: 'present',
    stage: 'pickup',
    notes: '',
  })
}

/** Add a custom (user-defined) extra to the checklist. */
function addCustomExtra() {
  const name = (customExtraName.value || '').trim()
  if (!name) return
  const key = 'custom_' + name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '')
  if (form.vehicle_checks.some((vc:any) => vc.item_key === key)) {
    $swal.fire({ icon: 'info', title: 'That extra is already in the list', toast: true, timer: 1500, position: 'top-end' })
    return
  }
  form.vehicle_checks.push({ item_key: key, item_name: name, status: 'present', stage: 'pickup', notes: '' })
  customExtraName.value = ''
}

/** Remove an added extra from the checklist (only non-default ones can be removed). */
function removeExtra(idx: number) {
  const vc = form.vehicle_checks[idx]
  if (!vc) return
  if (defaultExtraKeys.has(vc.item_key)) {
    $swal.fire({ icon: 'info', title: 'This is a default item and cannot be removed', toast: true, timer: 1800, position: 'top-end' })
    return
  }
  form.vehicle_checks.splice(idx, 1)
}

function onCustomerSelected(id: any) {
  if (id) {
    selectedCustomer.value = customerOptions.value.find((c) => c.id === id)
    if (selectedCustomer.value) {
      // Auto-populate the detail fields with the selected customer's data
      newCustomer.customer_type = selectedCustomer.value.customer_type || 'local'
      newCustomer.full_name = selectedCustomer.value.full_name || ''
      newCustomer.phone = selectedCustomer.value.phone || ''
      newCustomer.email = selectedCustomer.value.email || ''
      newCustomer.id_number = selectedCustomer.value.id_number || ''
      newCustomer.id_type = selectedCustomer.value.id_type || 'national_id'
      newCustomer.driving_license_no = selectedCustomer.value.driving_license_no || ''
      newCustomer.address = selectedCustomer.value.address || ''
      newCustomer.country = selectedCustomer.value.country || ''
      newCustomer.place_name = selectedCustomer.value.place_name || ''
      newCustomer.latitude = selectedCustomer.value.latitude || null
      newCustomer.longitude = selectedCustomer.value.longitude || null
      // Pre-fill the customer signature name
      if (selectedCustomer.value.full_name) {
        form.signatures[0].signatory_name = selectedCustomer.value.full_name
      }
    }
  } else {
    selectedCustomer.value = null
    // Clear the detail fields when no customer is selected
    Object.assign(newCustomer, {
      customer_type: 'local', full_name: '', phone: '', email: '', id_number: '',
      driving_license_no: '', id_type: 'national_id', address: '', country: '',
      place_name: '', latitude: null, longitude: null,
    })
  }
}

async function loadOptions() {
  try {
    const [customers, vehicles, locations, plans, drivers] = await Promise.all([
      $api('/rentals/customers/'),
      $api('/vehicles/vehicles/'),
      $api('/locations/'),
      $api('/rentals/pricing/?is_active=true'),
      $api('/contacts/?contact_type=driver&is_active=true'),
    ])
    const cList = customers?.results || customers || []
    const vList = vehicles?.results || vehicles || []
    const lList = locations?.results || locations || []
    customerOptions.value = cList.map((c:any) => ({ ...c, label: `${c.full_name} · ${c.customer_type}` }))
    const editingVehicleId = props.editing?.vehicle
    vehicleOptions.value = vList.map((v:any) => {
      const onRent = v.rental_status === 'on_rent'
      // Don't disable the vehicle that belongs to the agreement being edited
      const isThisEditingVehicle = editingVehicleId && v.id === editingVehicleId
      const disabled = onRent && !isThisEditingVehicle
      let label = `${v.display_name || `${v.year} ${v.make} ${v.model}`} · ${v.license_plate || ''}`
      if (onRent && !isThisEditingVehicle) {
        label += ` — Unavailable${v.rental_agreement_no ? ` (on rent: ${v.rental_agreement_no}` : ''}${v.rental_customer_name ? `, ${v.rental_customer_name}` : ''})`
      } else if (onRent && isThisEditingVehicle) {
        label += ` — Current rental`
      }
      return { ...v, label, disabled }
    })
    locationOptions.value = lList
    pricingPlans.value = (plans?.results || plans || []).map((p:any) => ({ ...p, label: p.name }))
    const dList = drivers?.results || drivers || []
    driverOptions.value = dList.map((d:any) => ({ ...d, label: d.full_name || `${d.first_name} ${d.last_name}` }))
  } catch (e) { /* silent */ }
}

function next() {
  // Validation per step
  if (current.value === 0 && !form.customer && !newCustomer.full_name) {
    $swal.fire({ icon: 'warning', title: 'Select a customer or fill new customer fields', toast: true, timer: 1800, position: 'top-end' })
    return
  }
  if (current.value === 1 && (!form.vehicle || !form.start_datetime || !form.end_datetime || !form.pickup_location || !form.dropoff_location || form.start_mileage === null || form.start_mileage === '' || !form.fuel_policy)) {
    $swal.fire({ icon: 'warning', title: 'Vehicle, dates, pickup/dropoff locations, start mileage and fuel policy are required', toast: true, timer: 2200, position: 'top-end' })
    return
  }
  if (current.value === 7 && !termsAccepted.value) {
    $swal.fire({ icon: 'warning', title: 'Please read and accept the Terms & Conditions to proceed', toast: true, timer: 2200, position: 'top-end' })
    return
  }
  current.value = Math.min(current.value + 1, steps.length - 1)
  computePreview()
}

async function save() {
  await doSave(props.editing ? editStatus.value : 'active')
}

async function saveAsDraft() {
  await doSave('draft')
}

async function doSave(targetStatus: string) {
  const isDraft = targetStatus === 'draft'

  if (!form.customer && newCustomer.full_name) {
    // create customer first
    try {
      const created = await $api('/rentals/customers/', { method: 'POST', body: newCustomer })
      form.customer = created.id
      selectedCustomer.value = created
      form.signatures[0].signatory_name = created.full_name
    } catch (e:any) {
      $swal.fire({ icon:'error', title:'Failed to create customer', text: e?.data?.detail || '', toast:true, timer:2500, position:'top-end' })
      return
    }
  }
  if (!isDraft && !form.customer) {
    $swal.fire({ icon:'warning', title:'Select a customer first', toast:true, timer:1800, position:'top-end' })
    current.value = 0
    return
  }
  if (!isDraft && !form.vehicle) {
    $swal.fire({ icon:'warning', title:'Select a vehicle', toast:true, timer:1800, position:'top-end' })
    current.value = 1
    return
  }

  // Prepare signatures list (drop blanks)
  const sigs = [
    { party_type: 'customer', signatory_name: form.signatures[0].signatory_name, signature_data: customerSignature.value || '' },
    { party_type: 'company_rep', signatory_name: form.signatures[1].signatory_name, signature_data: companySignature.value || '' },
  ].filter((s) => s.signature_data)

  const payload = { ...form }
  payload.status = targetStatus
  payload.signatures = sigs
  payload.vehicle_checks = form.vehicle_checks
  payload.inspection_checks = form.inspection_checks
  payload.inspection_notes = form.inspection_notes
  payload.terms_and_conditions = termsAndConditions.value.map((t:any, i:number) => ({
    id: i + 1,
    title: t.title || '',
    text: t.text || '',
  }))

  // Guard against double-submit: if already saving, bail out
  if (saving.value || savingDraft.value) return

  // Guard against double-submit: if already saving, bail out
  if (saving.value || savingDraft.value) return

  if (isDraft) { savingDraft.value = true } else { saving.value = true }
  try {
    if (props.editing) {
      await $api(`/rentals/agreements/${props.editing.id}/`, { method: 'PATCH', body: payload })
    } else {
      await $api('/rentals/agreements/', { method: 'POST', body: payload })
    }
    $swal.fire({ icon:'success', title: props.editing ? 'Agreement updated' : isDraft ? 'Draft saved' : 'Agreement activated', toast:true, timer:1500, position:'top-end' })
    emit('saved')
    router.push('/app/rentals')
  } catch (e:any) {
    $swal.fire({ icon:'error', title: 'Save failed', text: e?.data?.detail || e?.message || '', toast:true, timer:2500, position:'top-end' })
  } finally { saving.value = false; savingDraft.value = false }
}

onMounted(async () => {
  await loadOptions()
  computePreview()
  if (props.editing) {
    seedFromEditing()
    await nextTick()
  }

  // Attach Google Places autocomplete to the address input after the DOM is ready
  await nextTick()
  try {
    addressLoading.value = true
    const nativeInput = (addressInputRef.value as any)?.$el?.querySelector?.('input') as HTMLInputElement | null
    if (nativeInput) {
      addressAutocomplete = await attachAutocomplete(nativeInput, {
        types: ['geocode'],
        onPlace: (place: any) => {
          if (place?.formatted_address) {
            newCustomer.address = place.formatted_address
          }
          if (place?.name) {
            newCustomer.place_name = place.name
          } else if (place?.formatted_address) {
            newCustomer.place_name = place.formatted_address
          }
          if (place?.geometry?.location) {
            newCustomer.latitude = place.geometry.location.lat()
            newCustomer.longitude = place.geometry.location.lng()
          }
        },
      })
    }
  } catch (e) {
    // Google Maps not available — address still works as a manual text field
  } finally {
    addressLoading.value = false
  }
})

onBeforeUnmount(() => {
  if (addressAutocomplete && typeof addressAutocomplete.remove === 'function') {
    addressAutocomplete.remove()
  }
})

function seedFromEditing() {
  const a = props.editing
  editStatus.value = a.status || 'active'
  Object.assign(form, {
    customer: a.customer, vehicle: a.vehicle, status: a.status,
    rate_period: a.rate_period,
    daily_rate: a.daily_rate, weekly_rate: a.weekly_rate, monthly_rate: a.monthly_rate, weekend_rate: a.weekend_rate,
    pickup_location: a.pickup_location, dropoff_location: a.dropoff_location,
    start_datetime: (a.start_datetime || '').slice(0, 16),
    end_datetime: (a.end_datetime || '').slice(0, 16),
    actual_return_datetime: (a.actual_return_datetime || '').slice(0, 16) || null,
    insurance_type: a.insurance_type, insurance_premium: a.insurance_premium,
    gps_fee: a.gps_fee, child_seat_fee: a.child_seat_fee, additional_driver_fee: a.additional_driver_fee, delivery_fee: a.delivery_fee,
    discount_percent: a.discount_percent, discount_amount: a.discount_amount,
    security_deposit: a.security_deposit, damage_deposit: a.damage_deposit,
    free_mileage: a.free_mileage, excess_mileage_rate: a.excess_mileage_rate,
    start_mileage: a.start_mileage, end_mileage: a.end_mileage, fuel_policy: a.fuel_policy,
    start_fuel_level: a.start_fuel_level || 'full', end_fuel_level: a.end_fuel_level || '',
    tax_percent: a.tax_percent, notes: a.notes,
    charges: (a.charges || []).map((c:any) => ({ ...c })),
    damages: (a.damages || []).map((d:any) => ({ ...d })),
    vehicle_checks: (a.vehicle_checks || []).map((vc:any) => ({ ...vc })),
    inspection_checks: (a.inspection_checks || vehicleInspectionCatalog.map((c) => ({ item_key: c.key, item_name: c.label, status: 'pass', notes: '', failed_parts: [] }))).map((ic:any) => ({ failed_parts: [], ...ic })),
    inspection_notes: a.inspection_notes || '',
    signatures: [
      { party_type: 'customer', signatory_name: (a.signatures || []).find((s:any) => s.party_type === 'customer')?.signatory_name || '', signature_data: (a.signatures || []).find((s:any) => s.party_type === 'customer')?.signature_data || '' },
      { party_type: 'company_rep', signatory_name: (a.signatures || []).find((s:any) => s.party_type === 'company_rep')?.signatory_name || '', signature_data: (a.signatures || []).find((s:any) => s.party_type === 'company_rep')?.signature_data || '' },
    ],
  })
  customerSignature.value = form.signatures[0].signature_data
  companySignature.value = form.signatures[1].signature_data
  // Restore terms & conditions from the saved agreement
  if (a.terms_and_conditions && Array.isArray(a.terms_and_conditions) && a.terms_and_conditions.length > 0) {
    termsAndConditions.value = a.terms_and_conditions.map((t:any, i:number) => ({ id: t.id || i + 1, title: t.title || '', text: t.text || '' }))
  }
  onCustomerSelected(form.customer)
  computePreview()
}
</script>

<style scoped>
/* ============ Page Layout — sidebar + main ============ */
.rw-page {
  display: flex;
  min-height: 100vh;
  background: rgb(var(--v-theme-background));
}

/* ============ Sidebar ============ */
.rw-sidebar {
  width: 280px;
  flex-shrink: 0;
  background: rgb(var(--v-theme-surface));
  border-right: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  display: flex;
  flex-direction: column;
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  box-shadow: 2px 0 12px rgba(15, 23, 42, 0.05);
}

.rw-sidebar-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 24px 20px 20px;
  border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}

.rw-sidebar-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  background: linear-gradient(135deg, #4f46e5, #7c3aed);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 4px 14px rgba(99, 102, 241, 0.25);
}

.rw-sidebar-title {
  font-size: 18px;
  font-weight: 800;
  color: rgb(var(--v-theme-on-surface));
  margin: 0;
  line-height: 1.2;
}

.rw-sidebar-sub {
  font-size: 11px;
  color: rgb(var(--v-theme-on-surface));
  opacity: 0.5;
  margin: 2px 0 0;
}

.rw-sidebar-steps {
  flex: 1;
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.rw-sidebar-step {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 12px;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.rw-sidebar-step:hover {
  background: rgba(var(--v-theme-primary), 0.06);
}

.rw-sidebar-step--active {
  background: rgba(var(--v-theme-primary), 0.1);
}

.rw-sidebar-step--active .rw-sidebar-step-circle {
  background: rgb(var(--v-theme-primary));
  border-color: rgb(var(--v-theme-primary));
  color: rgb(var(--v-theme-on-primary));
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.3);
}

.rw-sidebar-step--active .rw-sidebar-step-title {
  color: rgb(var(--v-theme-primary));
}

.rw-sidebar-step--done .rw-sidebar-step-circle {
  background: #10b981;
  border-color: #10b981;
  color: #fff;
}

.rw-sidebar-step-circle {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: rgb(var(--v-theme-surface));
  border: 2px solid rgba(var(--v-theme-on-surface), 0.15);
  color: rgb(var(--v-theme-on-surface));
  opacity: 0.5;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 13px;
  transition: all 0.2s ease;
  flex-shrink: 0;
}

.rw-sidebar-step-info {
  flex: 1;
  min-width: 0;
}

.rw-sidebar-step-title {
  font-size: 13px;
  font-weight: 600;
  color: rgb(var(--v-theme-on-surface));
  opacity: 0.7;
  line-height: 1.3;
  transition: color 0.2s ease;
}

.rw-sidebar-step-sub {
  font-size: 11px;
  color: rgb(var(--v-theme-on-surface));
  opacity: 0.4;
  margin-top: 1px;
}

.rw-sidebar-footer {
  padding: 12px 16px 20px;
  border-top: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}

/* ============ Main content ============ */
.rw-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  height: 100vh;
  overflow-y: auto;
}

/* ============ Top bar ============ */
.rw-topbar {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 28px 36px 20px;
  background: rgb(var(--v-theme-surface));
  border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  flex-wrap: wrap;
}

.rw-topbar-left {
  flex: 1;
  min-width: 200px;
}

.rw-topbar-title {
  font-size: 24px;
  font-weight: 800;
  color: rgb(var(--v-theme-on-surface));
  margin: 0;
  line-height: 1.2;
}

.rw-topbar-desc {
  font-size: 13px;
  color: rgb(var(--v-theme-on-surface));
  opacity: 0.5;
  margin: 4px 0 0;
}

.rw-topbar-right {
  flex-shrink: 0;
}

.rw-topbar-progress {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.rw-topbar-progress-label {
  font-size: 11px;
  font-weight: 700;
  color: rgb(var(--v-theme-primary));
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.rw-topbar-progress-bar {
  width: 180px;
  height: 6px;
  background: rgba(var(--v-theme-primary), 0.12);
  border-radius: 4px;
  overflow: hidden;
}

.rw-topbar-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #6366f1, #818cf8);
  border-radius: 4px;
  transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

/* ============ Content area ============ */
.rw-content {
  flex: 1;
  padding: 32px 36px;
  overflow-y: auto;
}

/* ============ Step Header (inside content) ============ */
.rw-step-header {
  display: flex; align-items: center; gap: 14px;
  margin-bottom: 24px;
  padding-bottom: 20px;
  border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}
.rw-step-icon {
  width: 48px; height: 48px;
  border-radius: 14px;
  background: linear-gradient(135deg, #6366f1, #818cf8);
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 4px 14px rgba(99, 102, 241, 0.25);
}
.rw-step-heading {
  font-size: 20px; font-weight: 700;
  color: rgb(var(--v-theme-on-surface));
  margin: 0; line-height: 1.3;
}
.rw-step-desc {
  font-size: 13px; color: rgb(var(--v-theme-on-surface));
  opacity: 0.5; margin: 2px 0 0;
}

/* ============ Mini section titles ============ */
.rw-mini-title {
  font-size: 11px; font-weight: 700;
  color: rgb(var(--v-theme-primary));
  text-transform: uppercase; letter-spacing: 0.05em;
  display: flex; align-items: center; gap: 6px;
}
.rw-mini-title::before {
  content: '';
  width: 3px; height: 14px;
  background: rgb(var(--v-theme-primary));
  border-radius: 2px;
}

/* ============ Total Preview ============ */
.rw-total-preview {
  margin-top: 24px; padding: 20px 24px;
  border-radius: 16px;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.06), rgba(124, 58, 237, 0.04));
  border: 1px solid rgba(99, 102, 241, 0.15);
}
.rw-total-preview-header {
  display: flex; align-items: center; gap: 8px;
  font-size: 12px; font-weight: 700;
  color: rgb(var(--v-theme-primary));
  text-transform: uppercase; letter-spacing: 0.05em;
  margin-bottom: 14px;
  padding-bottom: 12px;
  border-bottom: 1px solid rgba(99, 102, 241, 0.15);
}
.rw-total-row {
  display: flex; justify-content: space-between;
  padding: 5px 0; font-size: 13px;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.7;
  border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.12);
}
.rw-total-grand {
  display: flex; justify-content: space-between;
  padding: 12px 0 0;
  font-size: 20px; font-weight: 800;
  color: rgb(var(--v-theme-primary));
  border-bottom: none;
}

/* ============ Line rows (charges/damages) ============ */
.rw-line-row {
  display: flex; align-items: flex-end; gap: 8px;
  margin-bottom: 10px; flex-wrap: wrap;
  padding: 12px; border-radius: 10px;
  background: rgba(var(--v-theme-on-surface), 0.03);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  transition: border-color 0.15s ease;
}
.rw-line-row:hover { border-color: rgba(var(--v-theme-primary), 0.2); }
.rw-line-col-1 { flex: 0 0 160px; }
.rw-line-col-2 { flex: 1 1 200px; }
.rw-line-col-3 { flex: 0 0 100px; }
.rw-line-col-4 { flex: 0 0 110px; }
.rw-line-col-5 { flex: 0 0 120px; }
@media (max-width: 700px) {
  .rw-line-col-1, .rw-line-col-3, .rw-line-col-4, .rw-line-col-5 { flex: 1 1 120px; }
}

/* ============ Action Bar (sticky bottom) ============ */
.rw-actions {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px 36px;
  background: rgb(var(--v-theme-surface));
  border-top: 1px solid rgba(var(--v-theme-on-surface), 0.08);
  box-shadow: 0 -4px 20px rgba(15, 23, 42, 0.06);
  gap: 12px;
  flex-wrap: wrap;
  position: sticky;
  bottom: 0;
  z-index: 10;
}
.rw-actions-left {
  display: flex; align-items: center; gap: 16px;
}
.rw-actions-right {
  display: flex; align-items: center; gap: 8px;
}
.rw-actions-progress {
  display: flex; align-items: center; gap: 8px;
}
.rw-actions-progress-bar {
  width: 100px; height: 5px;
  background: rgba(var(--v-theme-on-surface), 0.1);
  border-radius: 4px; overflow: hidden;
}
.rw-actions-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #6366f1, #818cf8);
  border-radius: 4px;
  transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}
.rw-actions-progress-text {
  font-size: 11px; font-weight: 600;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.5;
}

/* ============ Fuel Gauge ============ */
.fuel-gauge-section {
  display: flex;
  gap: 24px;
  flex-wrap: wrap;
  padding: 16px 18px;
  border-radius: 12px;
  background: rgba(var(--v-theme-on-surface), 0.03);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.08);
}
.fuel-gauge-block { flex: 1 1 280px; min-width: 260px; }
.fuel-gauge-header {
  display: flex; align-items: center; gap: 8px;
  margin-bottom: 10px;
  font-size: 0.8rem; font-weight: 700;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.7;
  text-transform: uppercase; letter-spacing: 0.03em;
}
.fuel-gauge-track {
  position: relative;
  height: 16px;
  background: rgba(var(--v-theme-on-surface), 0.08);
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  margin-bottom: 8px;
}
.fuel-gauge-track--draggable {
  cursor: pointer;
  overflow: visible;
  touch-action: none;
  height: 20px;
  margin-top: 14px;
  margin-bottom: 14px;
}
.fuel-gauge-track--draggable:hover .fuel-gauge-knob {
  transform: translate(-50%, -50%) scale(1.2);
}
.fuel-gauge-fill {
  height: 100%;
  border-radius: 8px;
  transition: width 0.2s cubic-bezier(0.4, 0, 0.2, 1), background 0.3s ease;
  pointer-events: none;
  z-index: 2;
}
.fuel-gauge-ticks {
  position: absolute; inset: 0;
  pointer-events: none; z-index: 3;
}
.fuel-gauge-tick {
  position: absolute; top: 0; bottom: 0;
  width: 1px;
  background: rgba(100, 116, 139, 0.3);
  transform: translateX(-50%);
}
.fuel-gauge-tick--major {
  width: 2px;
  background: rgba(71, 85, 105, 0.55);
}
.fuel-gauge-knob {
  position: absolute; top: 50%;
  width: 18px; height: 18px;
  border-radius: 50%;
  background: rgb(var(--v-theme-surface));
  border: 3px solid rgb(var(--v-theme-primary));
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.35);
  transform: translate(-50%, -50%);
  transition: transform 0.15s ease, left 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  pointer-events: none; z-index: 4;
}
.fuel-gauge-labels {
  display: flex; justify-content: space-between;
}
.fuel-gauge-btn {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 0.72rem; font-weight: 700;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.5;
  cursor: pointer;
  padding: 6px 0;
  border-radius: 8px;
  transition: all 0.15s ease;
}
.fuel-gauge-btn:hover {
  color: rgb(var(--v-theme-primary));
  background: rgba(var(--v-theme-primary), 0.12);
}
.fuel-gauge-btn--active {
  color: rgb(var(--v-theme-on-primary));
  background: rgb(var(--v-theme-primary));
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.3);
}
.fuel-gauge-btn--active:hover {
  color: rgb(var(--v-theme-on-primary));
  background: rgb(var(--v-theme-primary));
}

/* ============ Review Step ============ */
.rw-review-section-title {
  font-size: 12px; font-weight: 700;
  color: rgb(var(--v-theme-primary));
  text-transform: uppercase; letter-spacing: 0.05em;
  margin: 18px 0 8px;
  padding-left: 8px;
  border-left: 3px solid rgb(var(--v-theme-primary));
}
.rw-review-field label {
  display: block; font-size: 10px;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.05em; margin-bottom: 3px; font-weight: 600;
}
.rw-review-field > div {
  font-size: 13px; color: rgb(var(--v-theme-on-surface)); font-weight: 500;
  padding-bottom: 6px; border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.15);
}
.rw-review-table {
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  border-radius: 10px;
  overflow: hidden;
}
.rw-review-fuel-row {
  display: flex; gap: 24px; flex-wrap: wrap;
}
.rw-review-fuel-block { flex: 1 1 200px; min-width: 200px; }
.rw-review-fuel-caption {
  display: block; font-size: 10px; font-weight: 600;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.05em; margin-bottom: 4px;
}
.rw-review-fuel-track {
  position: relative; width: 100%; height: 28px;
  background: rgba(var(--v-theme-on-surface), 0.08);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.15);
  border-radius: 8px; overflow: hidden;
}
.rw-review-fuel-fill {
  position: relative; height: 100%;
  border-radius: 7px;
  transition: width 0.3s ease;
  min-width: 28px;
}
.rw-review-fuel-pct {
  position: absolute; top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  font-size: 11px; font-weight: 700;
  color: #ffffff;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
  white-space: nowrap;
}
.rw-review-sig-box {
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  border-radius: 10px; padding: 14px;
  min-height: 140px; position: relative;
  background: rgba(var(--v-theme-on-surface), 0.05);
}
.rw-review-sig-label {
  font-size: 10px; font-weight: 700;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.05em; margin-bottom: 8px;
}
.rw-review-sig-image :deep(svg) { width: 100%; height: 80px; }
.rw-review-sig-empty {
  text-align: center; padding-top: 24px;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.5; font-size: 12px;
}
.rw-review-sig-meta {
  margin-top: 8px; font-size: 11px;
  color: rgb(var(--v-theme-on-surface)); opacity: 0.6;
  border-top: 1px dashed rgba(var(--v-theme-on-surface), 0.15);
  padding-top: 6px;
}
.rw-review-notes {
  font-size: 12px; color: rgb(var(--v-theme-on-surface));
  padding: 12px; border-radius: 8px;
  background: rgba(var(--v-theme-on-surface), 0.05);
  border: 1px solid rgba(var(--v-theme-on-surface), 0.12);
  line-height: 1.5;
}

/* ============ Terms & Conditions ============ */
.rw-terms-box {
  max-height: 460px;
  overflow-y: auto;
}
.rw-terms-box .v-card__text,
.rw-terms-box .v-card-text {
  padding: 16px 20px;
}
.rw-terms-paragraph {
  margin-bottom: 0;
}
.rw-terms-clause {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  padding: 10px 0;
  border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.10);
  line-height: 1.6;
  font-size: 13px;
  color: rgb(var(--v-theme-on-surface));
}
.rw-terms-clause:last-child {
  border-bottom: none;
}
.rw-terms-clause-num {
  font-weight: 700;
  color: rgb(var(--v-theme-primary));
  min-width: 28px;
  flex: 0 0 28px;
}
.rw-terms-clause-title {
  font-weight: 600;
  margin-right: 8px;
}
.rw-terms-clause-text {
  flex: 1 1 100%;
  margin-top: 4px;
  margin-left: 28px;
  opacity: 0.85;
}
.rw-terms-edit-row {
  padding-bottom: 4px;
  margin-bottom: 4px;
  border-bottom: 1px dashed rgba(var(--v-theme-on-surface), 0.10);
}
.rw-terms-edit-row:last-of-type {
  border-bottom: none;
}

/* ============ Responsive ============ */
@media (max-width: 960px) {
  .rw-sidebar {
    width: 220px;
  }
  .rw-content {
    padding: 24px 20px;
  }
  .rw-topbar {
    padding: 20px 20px 16px;
  }
  .rw-actions {
    padding: 14px 20px;
  }
}

@media (max-width: 700px) {
  .rw-page {
    flex-direction: column;
  }
  .rw-sidebar {
    width: 100%;
    height: auto;
    position: relative;
    border-right: none;
    border-bottom: 1px solid rgba(var(--v-theme-on-surface), 0.08);
    box-shadow: none;
  }
  .rw-sidebar-steps {
    flex-direction: row;
    overflow-x: auto;
    padding: 12px 16px;
    gap: 8px;
  }
  .rw-sidebar-step {
    flex-shrink: 0;
    padding: 8px 10px;
  }
  .rw-sidebar-step-info {
    display: none;
  }
  .rw-sidebar-footer {
    border-top: none;
    padding: 0 16px 12px;
  }
  .rw-main {
    height: auto;
  }
  .rw-content {
    padding: 20px 16px;
  }
}
</style>
