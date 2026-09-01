<template>
  <div class="vehicle-wizard" :class="{ 'vehicle-wizard--vertical': vertical }">
    <!-- LEFT RAIL (vertical only) -->
    <div v-if="vertical" class="wizard-rail">
      <div class="wizard-header pa-5">
        <div class="d-flex align-center ga-2 mb-1">
          <v-icon size="20" color="white">mdi-car</v-icon>
          <span class="text-h6 font-weight-bold text-white">{{ editing ? 'Edit Vehicle' : 'Add Vehicle' }}</span>
        </div>
        <p class="text-caption text-white opacity-80 mb-0">
          Step {{ currentStep + 1 }} of {{ steps.length }} · {{ steps[currentStep].title }}
        </p>
      </div>
      <div class="step-list pa-3">
        <div
          v-for="(step, i) in steps"
          :key="i"
          class="step-item"
          :class="{ active: currentStep === i, complete: currentStep > i }"
          @click="goToStep(i)"
        >
          <div class="step-icon">
            <v-icon v-if="currentStep > i" size="18">mdi-check</v-icon>
            <v-icon v-else size="18">{{ step.icon }}</v-icon>
          </div>
          <div class="step-text">
            <div class="step-title">{{ step.title }}</div>
            <div class="step-num">Step {{ i + 1 }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- RIGHT COLUMN (vertical) / single column (horizontal) -->
    <div class="wizard-main">
    <!-- Progress header (horizontal only) -->
    <div v-if="!vertical" class="wizard-header pa-5">
      <div class="d-flex align-center ga-2 mb-1">
        <v-icon size="20" color="white">mdi-car</v-icon>
        <span class="text-h6 font-weight-bold text-white">{{ editing ? 'Edit Vehicle' : 'Add Vehicle' }}</span>
      </div>
      <p class="text-caption text-white opacity-80 mb-0">
        Step {{ currentStep + 1 }} of {{ steps.length }} · {{ steps[currentStep].title }}
      </p>
    </div>

    <!-- Stepper (horizontal only) -->
    <v-stepper v-if="!vertical" v-model="currentStep" :items="steps" alt-labels hide-actions color="primary" bg-color="transparent" flat class="wizard-stepper">
      <template #item.0="{ props }"><div v-bind="props" /></template>
      <template #item.1="{ props }"><div v-bind="props" /></template>
      <template #item.2="{ props }"><div v-bind="props" /></template>
      <template #item.3="{ props }"><div v-bind="props" /></template>
      <template #item.4="{ props }"><div v-bind="props" /></template>
      <template #item.5="{ props }"><div v-bind="props" /></template>
      <template #item.6="{ props }"><div v-bind="props" /></template>
    </v-stepper>

    <v-divider v-if="!vertical" />

    <!-- Step content -->
    <div class="wizard-body pa-6">
      <v-window v-model="currentStep" class="step-window">
        <!-- 1. Details -->
        <v-window-item :value="0">
          <p class="step-title-lg">Vehicle Details</p>
          <p class="step-subtitle">Core identity and classification of the asset.</p>

          <div class="vehicle-image-upload d-flex align-center ga-4 mb-2">
            <div class="vehicle-image-preview" :style="imagePreviewStyle">
              <v-icon v-if="!imagePreview" size="40" color="text-medium-emphasis">mdi-camera-plus-outline</v-icon>
              <img v-else :src="imagePreview" alt="Vehicle preview" />
            </div>
            <div class="d-flex flex-column ga-2 flex-grow-1">
              <span class="text-body-2 font-weight-medium">Vehicle Photo</span>
              <span class="text-caption text-medium-emphasis">Upload a photo of the vehicle (JPG/PNG, up to 5MB).</span>
              <div class="d-flex ga-2">
                <v-btn size="small" variant="outlined" prepend-icon="mdi-upload" @click="pickImage">Upload Photo</v-btn>
                <v-btn v-if="imagePreview" size="small" variant="text" color="error" prepend-icon="mdi-trash-can-outline" @click="removeImage">Remove</v-btn>
              </div>
              <input ref="imageInput" type="file" accept="image/*" style="display:none" @change="onImageSelected" />
            </div>
          </div>

          <v-row dense>
            <v-col cols="12">
              <div class="d-flex align-center ga-2">
                <v-text-field
                  v-model="form.vin"
                  label="VIN *"
                  placeholder="17-char VIN or 8–14 char chassis number"
                  :maxlength="17"
                  density="comfortable"
                  :error-messages="errors.vin"
                  hint="Unique Vehicle Identification Number (US/EU) or chassis number (Japan)."
                  persistent-hint
                />
                <v-btn prepend-icon="mdi-magnify" variant="outlined" :loading="decoding" @click="decodeVin">Decode</v-btn>
              </div>
            </v-col>
            <v-col cols="6"><v-text-field v-model="form.license_plate" label="License Plate" density="comfortable" hint="Registered plate / tag number." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.year" label="Year" type="number" density="comfortable" hint="Model year of manufacture." persistent-hint /></v-col>
            <v-col cols="6">
              <v-combobox v-model="form.make" :items="makeOptions" label="Make" density="comfortable" clearable hint="Manufacturer (e.g. Toyota, Ford)." persistent-hint @update:model-value="onMakeChange" />
            </v-col>
            <v-col cols="6">
              <v-select
                v-model="form.body_type"
                :items="bodyTypeOptions"
                item-title="label"
                item-value="value"
                label="Body Type"
                density="comfortable"
                clearable
                :disabled="!form.make"
                hint="Vehicle body classification. Select a make first."
                persistent-hint
                @update:model-value="onBodyTypeChange"
              >
                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend>
                      <v-icon>{{ item.raw.icon }}</v-icon>
                    </template>
                  </v-list-item>
                </template>
                <template #selection="{ item }">
                  <v-icon size="18" class="mr-2">{{ item.raw.icon }}</v-icon>
                  <span>{{ item.raw.label }}</span>
                </template>
              </v-select>
            </v-col>
            <v-col cols="6">
              <v-select
                v-model="form.model"
                :items="modelOptions"
                label="Model"
                density="comfortable"
                clearable
                :disabled="!form.make || !form.body_type"
                hint="Specific model line for the make / body type."
                persistent-hint
              />
            </v-col>
            <v-col cols="6">
              <v-select
                v-model="form.vehicle_type"
                :items="vehicleTypeOptions"
                item-title="name"
                item-value="name"
                label="Vehicle Type *"
                density="comfortable"
                clearable
                :error-messages="errors.vehicle_type"
                hint="Fleet vehicle category (SUV, Mini-van, Truck, etc.)."
                persistent-hint
              >
                <template #item="{ props, item }">
                  <v-list-item v-bind="props">
                    <template #prepend>
                      <v-icon :color="item.raw.color">{{ item.raw.icon || 'mdi-car' }}</v-icon>
                    </template>
                  </v-list-item>
                </template>
                <template #selection="{ item }">
                  <v-icon size="18" class="mr-2" :color="item.raw.color">{{ item.raw.icon || 'mdi-car' }}</v-icon>
                  <span>{{ item.raw.name }}</span>
                </template>
              </v-select>
            </v-col>
            <v-col cols="6">
              <v-select v-model="form.status" :items="statuses" item-title="label" item-value="value" label="Status *" density="comfortable" :error-messages="errors.status" hint="Current operational state of the vehicle." persistent-hint />
            </v-col>
            <v-col cols="12">
              <v-select v-model="form.group" :items="groupOptions" item-title="name" item-value="id" label="Group *" density="comfortable" :error-messages="errors.group" hint="Fleet group / department this vehicle belongs to." persistent-hint />
            </v-col>
            <v-col cols="6">
              <v-select v-model="form.location" :items="locationOptions" item-title="name" item-value="name" label="Location / Yard *" density="comfortable" :error-messages="errors.location" hint="Where the vehicle is normally parked or dispatched." persistent-hint />
            </v-col>
            <v-col cols="6">
              <v-select v-model="form.assigned_driver" :items="driverOptions" :item-title="driverTitle" item-value="id" label="Assigned Driver" density="comfortable" clearable hint="Primary driver responsible for the vehicle." persistent-hint />
            </v-col>
          </v-row>
        </v-window-item>

        <!-- 2. Maintenance -->
        <v-window-item :value="1">
          <p class="step-title-lg">Maintenance Schedule</p>
          <p class="step-subtitle">Set up preventive maintenance reminders. These are created with the vehicle.</p>

          <div v-if="!reminders.length" class="text-center py-8 text-medium-emphasis">
            <v-icon size="40" class="mb-2">mdi-wrench-clock-outline</v-icon>
            <p class="text-body-2">No reminders added yet. Add a PM schedule to track recurring service.</p>
          </div>

          <div v-for="(r, i) in reminders" :key="i" class="reminder-row pa-3 mb-3 rounded-lg">
            <div class="d-flex align-center justify-space-between mb-2">
              <span class="text-body-2 font-weight-medium">Reminder #{{ i + 1 }}</span>
              <v-btn icon="mdi-trash-can-outline" variant="text" color="error" size="small" @click="reminders.splice(i, 1)" />
            </div>
            <v-row dense>
              <v-col cols="12"><v-text-field v-model="r.title" label="Title" placeholder="e.g. Oil Change" density="compact" hint="Name of the maintenance task." persistent-hint /></v-col>
              <v-col cols="6">
                <v-select v-model="r.trigger_type" :items="triggerTypes" item-title="label" item-value="value" label="Trigger" density="compact" hint="What activates the reminder." persistent-hint />
              </v-col>
              <v-col cols="6">
                <v-text-field v-model.number="r.trigger_interval" label="Interval" type="number" density="compact" :suffix="triggerSuffix(r.trigger_type)" hint="How often the reminder fires." persistent-hint />
              </v-col>
              <v-col cols="12">
                <v-select v-model="r.escalation_level" :items="escalationLevels" item-title="label" item-value="value" label="Escalation Level" density="compact" hint="Who gets notified when overdue." persistent-hint />
              </v-col>
            </v-row>
          </div>

          <v-btn variant="tonal" color="primary" prepend-icon="mdi-plus" size="small" @click="addReminder">Add Reminder</v-btn>
        </v-window-item>

        <!-- 3. Lifecycle -->
        <v-window-item :value="2">
          <p class="step-title-lg">Lifecycle</p>
          <p class="step-subtitle">Ownership and service lifecycle of the asset.</p>

          <p class="field-group-label">Ownership</p>
          <v-radio-group v-model="form.ownership" inline density="compact" hide-details class="mb-3">
            <v-radio label="Owned (Self)" value="self" />
            <v-radio label="Leased" value="lease" />
          </v-radio-group>

          <v-row v-if="form.ownership === 'lease'" dense class="mb-3">
            <v-col cols="12">
              <v-select v-model="form.lessor" :items="lessorOptions" item-title="display_name" item-value="id" label="Lessor" density="comfortable" :loading="loadingLessors" clearable hint="Company leasing the vehicle to you." persistent-hint />
            </v-col>
            <v-col cols="6"><v-text-field v-model="form.lease_start_date" label="Lease Start Date" type="date" density="comfortable" hint="Start of the lease contract." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.lease_end_date" label="Lease End Date" type="date" density="comfortable" hint="End of the lease contract." persistent-hint /></v-col>
          </v-row>

          <p class="field-group-label mt-4">Service Timeline</p>
          <v-row dense>
            <v-col cols="6"><v-text-field v-model="form.in_service_date" label="In Service Date" type="date" density="comfortable" hint="Date the vehicle entered active service." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.out_of_service_date" label="Out of Service Date" type="date" density="comfortable" hint="Date the vehicle was taken out of service." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.retired_date" label="Retired Date" type="date" density="comfortable" hint="Date the vehicle was permanently retired." persistent-hint /></v-col>
          </v-row>
        </v-window-item>

        <!-- 4. Financials -->
        <v-window-item :value="3">
          <p class="step-title-lg">Financials</p>
          <p v-if="form.ownership === 'lease'" class="step-subtitle">Lease cost details for this leased asset.</p>
          <p v-else class="step-subtitle">Acquisition cost, depreciation and recurring financials.</p>

          <v-row v-if="form.ownership === 'lease'" dense>
            <v-col cols="6"><v-text-field v-model="form.lease_monthly_rate" :label="`Lease Monthly Rate (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Recurring monthly lease payment." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.deposit" :label="`Deposit (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Security deposit paid to the lessor." persistent-hint /></v-col>
          </v-row>

          <v-row v-else dense>
            <v-col cols="6"><v-text-field v-model="form.purchase_price" :label="`Purchase Price (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Total acquisition cost of the vehicle." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.purchase_date" label="Purchase Date" type="date" density="comfortable" hint="Date the vehicle was purchased." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.salvage_value" :label="`Salvage Value (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Estimated end-of-life residual value." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.useful_life_years" label="Useful Life (years)" type="number" density="comfortable" hint="Expected service life for depreciation." persistent-hint /></v-col>
            <v-col cols="6">
              <v-select v-model="form.depreciation_method" :items="depreciationMethods" item-title="label" item-value="value" label="Depreciation Method" density="comfortable" hint="How depreciation is calculated." persistent-hint />
            </v-col>
            <v-col cols="6"><v-text-field v-model="form.residual_value" :label="`Residual Value (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Expected value at end of useful life." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.monthly_payment" :label="`Monthly Payment (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Financing installment, if applicable." persistent-hint /></v-col>
          </v-row>
        </v-window-item>

        <!-- 5. Insurance -->
        <v-window-item :value="4">
          <p class="step-title-lg">Insurance</p>
          <p class="step-subtitle">Coverage type, policy period and premium for this vehicle.</p>

          <v-row dense>
            <v-col cols="12">
              <v-select v-model="form.insurance_type" :items="insuranceTypes" item-title="label" item-value="value" label="Insurance Type" density="comfortable" hint="Type of insurance coverage." persistent-hint />
            </v-col>
            <v-col cols="6"><v-text-field v-model="form.insurance_start_date" label="Policy Start Date" type="date" density="comfortable" hint="Start of the insurance coverage." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.insurance_end_date" label="Policy End Date" type="date" density="comfortable" hint="Expiry of the insurance coverage." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.insurance_premium" :label="`Insurance Cost (${currencySymbol})`" placeholder="0.00" density="comfortable" hint="Annual premium paid for the policy." persistent-hint /></v-col>
          </v-row>
        </v-window-item>

        <!-- 6. Specifications -->
        <v-window-item :value="5">
          <p class="step-title-lg">Specifications</p>
          <p class="step-subtitle">Comprehensive technical, exterior and feature configuration of the asset.</p>

          <!-- Powertrain & Drivetrain -->
          <p class="spec-section-title mt-2 mb-3">Powertrain &amp; Drivetrain</p>
          <v-row dense class="mb-2">
            <v-col cols="6">
              <v-combobox v-model="form.fuel_type" :items="fuelTypeOptions" label="Fuel Type" density="comfortable" hint="Primary energy source of the vehicle." persistent-hint />
            </v-col>
            <v-col v-if="!isElectric" cols="6">
              <v-combobox v-model="form.engine_size" :items="engineSizeOptions" label="Engine Size" density="comfortable" placeholder="e.g. 2000cc" hint="Engine displacement in cubic centimetres." persistent-hint />
            </v-col>
            <v-col v-if="isMotorized" cols="6">
              <v-combobox v-model="form.motors" :items="motorOptions" label="Motors" density="comfortable" placeholder="e.g. Dual Motor" hint="Electric motor configuration / count." persistent-hint />
            </v-col>
            <v-col cols="6"><v-combobox v-model="form.transmission" :items="transmissionOptions" label="Transmission" density="comfortable" hint="Gearbox type of the vehicle." persistent-hint /></v-col>
            <v-col cols="6">
              <v-select v-model="form.drivetrain" :items="drivetrainOptions" item-title="label" item-value="value" label="Drivetrain" density="comfortable" clearable hint="Wheel configuration &amp; drive (e.g. 4x4)." persistent-hint />
            </v-col>
            <v-col cols="6">
              <div class="text-caption text-medium-emphasis mb-1">Steering</div>
              <div class="seg-toggle">
                <div
                  v-for="opt in steeringOptions"
                  :key="opt.value"
                  class="seg-toggle-item"
                  :class="{ active: form.steering === opt.value }"
                  @click="form.steering = opt.value"
                >
                  <v-icon size="16" class="me-1">{{ opt.icon }}</v-icon>
                  {{ opt.label }}
                </div>
              </div>
            </v-col>
          </v-row>

          <!-- Dimensions & Meters -->
          <p class="spec-section-title mt-5 mb-3">Dimensions &amp; Meters</p>
          <v-row dense class="mb-2">
            <v-col cols="6"><v-combobox v-model="form.trim" :items="trimOptions" label="Trim" density="comfortable" hint="Equipment / option level of the model." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model="form.weight_rating" label="Weight Rating (GVWR)" density="comfortable" hint="Gross Vehicle Weight Rating." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.gross_vehicle_weight" label="GVW (lbs)" type="number" density="comfortable" hint="Actual gross vehicle weight." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.tank_capacity" label="Tank Capacity (gal)" type="number" density="comfortable" hint="Fuel tank capacity in gallons." persistent-hint /></v-col>
            <v-col cols="6"><v-text-field v-model.number="form.current_mileage" label="Current Mileage" type="number" density="comfortable" hint="Odometer reading of the vehicle." persistent-hint /></v-col>
            <v-col cols="6">
              <v-select v-model="form.mileage_unit" :items="mileageUnits" item-title="label" item-value="value" label="Mileage Unit" density="comfortable" hint="Unit used for the odometer." persistent-hint />
            </v-col>
            <v-col cols="6"><v-text-field v-model.number="form.engine_hours" label="Engine Hours" type="number" density="comfortable" hint="Total engine running hours (for non-odometer assets)." persistent-hint /></v-col>
          </v-row>

          <!-- Exterior Color -->
          <p class="spec-section-title mt-5 mb-1">Exterior Color</p>
          <p class="text-body-2 text-medium-emphasis mb-3">Tap a swatch to pick the body color.</p>
          <div class="color-chip-row">
            <div
              v-for="c in exteriorColors"
              :key="c.name"
              class="color-chip"
              :class="{ active: form.color === c.name }"
              :title="c.label"
              @click="selectExteriorColor(c.name)"
            >
              <span
                class="color-chip-swatch"
                :style="{ background: c.swatch, border: c.border ? `1px solid ${c.border}` : '1px solid rgba(15,23,42,0.12)' }"
              >
                <v-icon v-if="c.name === 'other'" size="16" color="white">mdi-eyedropper-variant</v-icon>
              </span>
              <span class="color-chip-label">{{ c.label }}</span>
            </div>
          </div>
          <v-row v-if="form.color === 'other'" dense class="mt-3">
            <v-col cols="6">
              <div class="d-flex align-center ga-3">
                <input
                  type="color"
                  class="native-color-input"
                  :value="form.exterior_color_custom || '#6366f1'"
                  @input="form.exterior_color_custom = ($event.target as HTMLInputElement).value"
                />
                <v-text-field
                  v-model="form.exterior_color_custom"
                  label="Custom color (hex)"
                  density="comfortable"
                  hint="Pick a color or enter a hex code."
                  persistent-hint
                  style="max-width: 260px"
                  placeholder="#6366f1"
                />
              </div>
            </v-col>
          </v-row>

          <!-- Features & Options -->
          <p class="spec-section-title mt-6 mb-1">Features &amp; Options</p>
          <p class="text-body-2 text-medium-emphasis mb-4">Tap to toggle equipment included with the vehicle.</p>

          <div class="feature-group">
            <div class="feature-group-head">
              <v-icon size="18" class="me-2" color="primary">mdi-sofa-single-outline</v-icon>
              <span class="text-subtitle-2 font-weight-bold">Comfort &amp; Convenience</span>
              <v-chip size="x-small" variant="tonal" class="ms-2">{{ (form.comfort_convenience || []).length }}</v-chip>
            </div>
            <div class="feature-chip-wrap">
              <div
                v-for="f in comfortOptions"
                :key="f"
                class="feature-chip"
                :class="{ active: hasFeature('comfort_convenience', f) }"
                @click="toggleFeature('comfort_convenience', f)"
              >
                <v-icon size="14" class="me-1">{{ hasFeature('comfort_convenience', f) ? 'mdi-check-circle' : 'mdi-plus-circle-outline' }}</v-icon>
                {{ f }}
              </div>
            </div>
          </div>

          <div class="feature-group">
            <div class="feature-group-head">
              <v-icon size="18" class="me-2" color="primary">mdi-car-shift-pattern</v-icon>
              <span class="text-subtitle-2 font-weight-bold">Dress Up</span>
              <v-chip size="x-small" variant="tonal" class="ms-2">{{ (form.dress_up || []).length }}</v-chip>
            </div>
            <div class="feature-chip-wrap">
              <div
                v-for="f in dressUpOptions"
                :key="f"
                class="feature-chip"
                :class="{ active: hasFeature('dress_up', f) }"
                @click="toggleFeature('dress_up', f)"
              >
                <v-icon size="14" class="me-1">{{ hasFeature('dress_up', f) ? 'mdi-check-circle' : 'mdi-plus-circle-outline' }}</v-icon>
                {{ f }}
              </div>
            </div>
          </div>

          <div class="feature-group">
            <div class="feature-group-head">
              <v-icon size="18" class="me-2" color="primary">mdi-car-convertible</v-icon>
              <span class="text-subtitle-2 font-weight-bold">Exterior</span>
              <v-chip size="x-small" variant="tonal" class="ms-2">{{ (form.exterior_features || []).length }}</v-chip>
            </div>
            <div class="feature-chip-wrap">
              <div
                v-for="f in exteriorFeaturesOptions"
                :key="f"
                class="feature-chip"
                :class="{ active: hasFeature('exterior_features', f) }"
                @click="toggleFeature('exterior_features', f)"
              >
                <v-icon size="14" class="me-1">{{ hasFeature('exterior_features', f) ? 'mdi-check-circle' : 'mdi-plus-circle-outline' }}</v-icon>
                {{ f }}
              </div>
            </div>
          </div>

          <div class="feature-group">
            <div class="feature-group-head">
              <v-icon size="18" class="me-2" color="primary">mdi-shield-car-variant-outline</v-icon>
              <span class="text-subtitle-2 font-weight-bold">Safety</span>
              <v-chip size="x-small" variant="tonal" class="ms-2">{{ (form.safety_features || []).length }}</v-chip>
            </div>
            <div class="feature-chip-wrap">
              <div
                v-for="f in safetyOptions"
                :key="f"
                class="feature-chip"
                :class="{ active: hasFeature('safety_features', f) }"
                @click="toggleFeature('safety_features', f)"
              >
                <v-icon size="14" class="me-1">{{ hasFeature('safety_features', f) ? 'mdi-check-circle' : 'mdi-plus-circle-outline' }}</v-icon>
                {{ f }}
              </div>
            </div>
          </div>

          <!-- Power & Battery -->
          <p v-if="isMotorized" class="field-group-label mt-5 mb-1">Power &amp; Battery</p>
          <v-row v-if="isMotorized" dense>
            <v-col cols="4"><v-text-field v-model.number="form.battery_capacity_kwh" label="Battery (kWh)" type="number" density="comfortable" hint="Total battery capacity." persistent-hint /></v-col>
            <v-col cols="4"><v-text-field v-model.number="form.state_of_charge" label="SoC (%)" type="number" density="comfortable" hint="Current state of charge." persistent-hint /></v-col>
            <v-col cols="4"><v-text-field v-model.number="form.state_of_health" label="SoH (%)" type="number" density="comfortable" hint="Battery state of health." persistent-hint /></v-col>
          </v-row>
        </v-window-item>

        <!-- 7. Custom Fields -->
        <v-window-item :value="6">
          <p class="step-title-lg">Custom Fields</p>
          <p class="step-subtitle">Capture organization-specific attributes for this vehicle.</p>

          <div v-if="!customFieldDefs.length" class="text-center py-8 text-medium-emphasis">
            <v-icon size="40" class="mb-2">mdi-form-textbox</v-icon>
            <p class="text-body-2 mb-3">No custom fields defined yet. Create field definitions to use them here.</p>
            <v-btn variant="tonal" color="primary" size="small" prepend-icon="mdi-plus" @click="showFieldDefDialog = true">Create Custom Field</v-btn>
          </div>

          <v-row v-else dense>
            <v-col cols="12" v-for="field in customFieldDefs" :key="field.id">
              <component
                :is="fieldComponent(field.field_type)"
                v-model="customValues[field.id]"
                :label="field.display_label + (field.is_required ? ' *' : '')"
                :items="field.choices"
                density="comfortable"
                :hint="field.name ? `Custom field: ${field.name}` : ''"
                persistent-hint
              />
            </v-col>
          </v-row>

          <v-btn v-if="customFieldDefs.length" variant="text" size="small" prepend-icon="mdi-plus" class="mt-2" @click="showFieldDefDialog = true">Add another field definition</v-btn>
        </v-window-item>
      </v-window>
    </div>

    <v-divider />

    <!-- Footer actions -->
    <div class="d-flex align-center justify-space-between pa-4">
      <v-btn variant="text" :disabled="currentStep === 0" @click="currentStep--">
        <v-icon start>mdi-arrow-left</v-icon> Back
      </v-btn>
      <div class="d-flex ga-2">
        <v-btn variant="text" @click="$emit('cancel')">Cancel</v-btn>
        <v-btn v-if="currentStep < steps.length - 1" color="primary" @click="next">
          Next <v-icon end>mdi-arrow-right</v-icon>
        </v-btn>
        <v-btn v-else color="primary" prepend-icon="mdi-check" :loading="saving" @click="save">
          {{ editing ? 'Update Vehicle' : 'Create Vehicle' }}
        </v-btn>
      </div>
    </div>

    <!-- Custom field definition dialog -->
    <v-dialog v-model="showFieldDefDialog" max-width="500">
      <v-card rounded="xl">
        <AppModalHeader icon="mdi-form-textbox">New Custom Field</AppModalHeader>
        <v-card-text>
          <v-row dense>
            <v-col cols="12"><v-text-field v-model="newField.name" label="Field Name" density="comfortable" placeholder="e.g. acquisition_source" hint="Internal key (lowercase, no spaces)." persistent-hint /></v-col>
            <v-col cols="12"><v-text-field v-model="newField.label" label="Display Label" density="comfortable" placeholder="e.g. Acquisition Source" hint="Label shown to users on forms." persistent-hint /></v-col>
            <v-col cols="6">
              <v-select v-model="newField.field_type" :items="fieldTypes" item-title="label" item-value="value" label="Type" density="comfortable" hint="Data type of the field." persistent-hint />
            </v-col>
            <v-col cols="6" class="d-flex align-center">
              <v-switch v-model="newField.is_required" label="Required" density="compact" hide-details color="primary" />
            </v-col>
            <v-col v-if="newField.field_type === 'select'" cols="12">
              <v-text-field v-model="newField.choicesText" label="Choices (comma separated)" density="comfortable" placeholder="Option A, Option B" hint="Allowed values, separated by commas." persistent-hint />
            </v-col>
          </v-row>
        </v-card-text>
        <v-card-actions class="px-4 pb-4">
          <v-spacer />
          <v-btn variant="text" @click="showFieldDefDialog = false">Cancel</v-btn>
          <v-btn color="primary" :loading="savingField" @click="createCustomField">Create Field</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ vehicle?: any | null; vertical?: boolean }>()
const emit = defineEmits<{ saved: []; cancel: [] }>()

const { $api } = useNuxtApp()
const { currencySymbol, load: loadCurrency } = useCurrency()

const steps = [
  { title: 'Details', icon: 'mdi-car-information' },
  { title: 'Maintenance', icon: 'mdi-wrench' },
  { title: 'Lifecycle', icon: 'mdi-calendar-sync' },
  { title: 'Financials', icon: 'mdi-currency-usd' },
  { title: 'Insurance', icon: 'mdi-shield-car' },
  { title: 'Specifications', icon: 'mdi-car-cog' },
  { title: 'Custom Fields', icon: 'mdi-form-textbox' },
]

const currentStep = ref(0)
const saving = ref(false)
const decoding = ref(false)
const savingField = ref(false)
const showFieldDefDialog = ref(false)
const errors = reactive<any>({})

// Vehicle image upload
const imageInput = ref<HTMLInputElement | null>(null)
const imageFile = ref<File | null>(null)
const imageUrl = ref<string>('') // existing image URL from server (edit mode)
const imagePreview = computed(() => imageFile.value
  ? URL.createObjectURL(imageFile.value)
  : resolveMediaUrl(imageUrl.value))
const imagePreviewStyle = computed(() => imagePreview.value
  ? { backgroundImage: `url(${imagePreview.value})`, backgroundSize: 'cover', backgroundPosition: 'center' }
  : {})

function resolveMediaUrl(url: string): string {
  if (!url) return ''
  if (/^https?:\/\//i.test(url)) return url
  const base = (useRuntimeConfig().public.apiBase || '').replace(/\/api\/?$/, '')
  return `${base}/${url.replace(/^\/+/, '')}`
}

function pickImage() {
  imageInput.value?.click()
}

function onImageSelected(e: Event) {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) return
  imageFile.value = file
  // Reset the input so reselecting the same file fires change again
  target.value = ''
}

function removeImage() {
  imageFile.value = null
  imageUrl.value = ''
}

const editing = computed(() => !!props.vehicle)

const vehicleTypes = [
  { label: 'Vehicle', value: 'vehicle' },
  { label: 'Trailer', value: 'trailer' },
  { label: 'Equipment', value: 'equipment' },
  { label: 'Non-powered', value: 'non_powered' },
]
const fuelTypes = [
  { label: 'ICE', value: 'ICE' },
  { label: 'EV', value: 'EV' },
  { label: 'Hybrid', value: 'Hybrid' },
]
const statuses = [
  { label: 'Active', value: 'active' },
  { label: 'Out of Service', value: 'out_of_service' },
  { label: 'In Maintenance', value: 'in_maintenance' },
  { label: 'Retired', value: 'retired' },
]
const mileageUnits = [
  { label: 'Miles', value: 'miles' },
  { label: 'Kilometers', value: 'km' },
]
const depreciationMethods = [
  { label: 'Straight-Line', value: 'straight_line' },
  { label: 'Declining Balance', value: 'declining_balance' },
  { label: 'None', value: 'none' },
]
const triggerTypes = [
  { label: 'Time (Months)', value: 'time' },
  { label: 'Mileage', value: 'mileage' },
  { label: 'Engine Hours', value: 'engine_hours' },
]
const escalationLevels = [
  { label: 'None', value: 0 },
  { label: 'Email Driver', value: 1 },
  { label: 'SMS Manager', value: 2 },
  { label: 'Block Dispatch', value: 3 },
]
const fieldTypes = [
  { label: 'Text', value: 'text' },
  { label: 'Number', value: 'number' },
  { label: 'Date', value: 'date' },
  { label: 'Yes/No', value: 'boolean' },
  { label: 'Dropdown', value: 'select' },
]

const insuranceTypes = [
  { label: 'Comprehensive', value: 'comprehensive' },
  { label: 'Third-Party', value: 'third_party' },
  { label: 'Third-Party, Fire & Theft', value: 'third_party_fire_theft' },
  { label: 'Liability', value: 'liability' },
  { label: 'Collision', value: 'collision' },
  { label: 'Gap Insurance', value: 'gap' },
  { label: 'Commercial Fleet', value: 'commercial_fleet' },
]

const engineOptions = [
  'I3', 'I4', 'I5', 'I6', 'V6', 'V8', 'V10', 'V12',
  'Turbo I4', 'Twin-Turbo V6', 'Supercharged V8', 'Hemi V8',
  'Diesel I4', 'Diesel I6', 'Diesel V8', 'Diesel V10',
  'Electric Motor', 'Dual Electric Motor', 'Hybrid Synergy Drive',
  'Hydrogen Fuel Cell', 'Natural Gas', 'Propane',
]

const engineSizeOptions = [
  '660cc', '1000cc', '1200cc', '1300cc', '1400cc', '1500cc', '1600cc',
  '1800cc', '1900cc', '2000cc', '2200cc', '2400cc', '2500cc', '2700cc',
  '3000cc', '3200cc', '3500cc', '3700cc', '4000cc', '4200cc', '4500cc',
  '5000cc', '5200cc', '5500cc', '6000cc', '6200cc', '6400cc', '6800cc', '7000cc',
]

const fuelTypeOptions = [
  'Petrol', 'Diesel',
  'Hybrid (Petrol)', 'Hybrid (Diesel)',
  'Plug-in Hybrid (Petrol)', 'Plug-in Hybrid (Diesel)',
  'Mild Hybrid',
  'Electric', 'Fuel Cell (Hydrogen)',
  'LPG', 'CNG', 'LNG',
  'Ethanol (E85)', 'Flex Fuel', 'Biodiesel',
]

const motorOptions = [
  'Single Motor (FWD)', 'Single Motor (RWD)', 'Single Motor (AWD)',
  'Dual Motor (AWD)', 'Tri-Motor (AWD)', 'Quad-Motor (AWD)',
  'Single Motor', 'Dual Motor',
]
const trimOptions = [
  'Base', 'LX', 'DX', 'EX', 'EX-L', 'SX', 'SX Turbo', 'Sport', 'Sport Touring',
  'Limited', 'Limited Edition', 'SE', 'SEL', 'SEL Premium', 'GLS', 'S', 'LS',
  'LT', 'LTZ', 'XLT', 'Lariat', 'Platinum', 'King Ranch', 'SV', 'SL', 'SR', 'SR5',
  'TRD', 'TRD Off-Road', 'TRD Pro', 'R/T', 'SRT', 'SRT8', 'Hellcat', 'Trackhawk',
  'GT', 'GT-Line', 'GT Premium', 'EcoBoost', 'Titanium', 'Platinum Reserve',
  'Summit', 'Trailhawk', 'Rubicon', 'Sahara', 'Willys', 'Overland',
]

const transmissionOptions = [
  'Automatic', 'Manual', 'Semi-Automatic', 'Smoother', 'Inomat', 'Duonic',
  'Escot', 'Proshift', 'CVT', 'Dual-Clutch (DCT)', 'Automated Manual (AMT)',
  'Tiptronic', 'Sequential', 'Electric Single-Speed',
  '4-Speed Automatic', '5-Speed Manual', '6-Speed Automatic', '6-Speed Manual',
  '7-Speed DCT', '8-Speed Automatic', '9-Speed Automatic', '10-Speed Automatic',
]

const drivetrainOptions = [
  { label: '2WD', value: '2WD' },
  { label: '4WD', value: '4WD' },
  { label: '4x2', value: '4-2' },
  { label: '4x4', value: '4-4' },
  { label: '6x2', value: '6-2' },
  { label: '6x4', value: '6-4' },
  { label: '8x4', value: '8-4' },
]

const steeringOptions = [
  { label: 'Right Hand', value: 'right', icon: 'mdi-steering' },
  { label: 'Left Hand', value: 'left', icon: 'mdi-flip-horizontal' },
]

const exteriorColors = [
  { name: 'white',  label: 'White',  swatch: '#ffffff', border: '#cbd5e1' },
  { name: 'gray',   label: 'Gray',   swatch: '#9ca3af' },
  { name: 'black',  label: 'Black',  swatch: '#1f2937' },
  { name: 'gold',   label: 'Gold',   swatch: '#d4af37' },
  { name: 'pearl',  label: 'Pearl',  swatch: '#eae6da', border: '#cbd5e1' },
  { name: 'silver', label: 'Silver', swatch: '#c4c8cc' },
  { name: 'red',    label: 'Red',    swatch: '#dc2626' },
  { name: 'yellow', label: 'Yellow', swatch: '#f59e0b' },
  { name: 'green',  label: 'Green',  swatch: '#16a34a' },
  { name: 'blue',   label: 'Blue',   swatch: '#2563eb' },
  { name: 'purple', label: 'Purple', swatch: '#7c3aed' },
  { name: 'beige',  label: 'Beige',  swatch: '#e7d8b1' },
  { name: 'brown',  label: 'Brown',  swatch: '#78350f' },
  { name: 'other',  label: 'Other',  swatch: 'linear-gradient(135deg,#ef4444,#f59e0b,#10b981,#3b82f6,#a855f7)' },
]

const comfortOptions = [
  'Adaptive Cruise Control (ACC)', 'Cruise Control', 'Air Conditioner', 'Heater',
  'Climate Control (Dual Zone)', 'Power Steering', 'Power Windows', 'Power Door Locks',
  'Power Mirrors', 'Power Seats', 'Heated Seats', 'Ventilated Seats', 'Memory Seats',
  'Audio System', 'Navigation System', 'Bluetooth', 'Apple CarPlay', 'Android Auto',
  'Multi-function Steering Wheel', 'Auto-dimming Rearview Mirror', 'Keyless Entry',
  'Push Button Start', 'Remote Start', 'Rain-sensing Wipers', 'Auto Headlights',
  'Ambient Lighting', 'Cool Box', 'Electric Parking Brake', 'Auto Hold',
]
const dressUpOptions = [
  'Alloy Wheels', 'Chrome Grille', 'Grill Guard', 'Front Bumper Guard', 'Rear Bumper Guard',
  'Rear Spoiler', 'Side Steps', 'Body Kit', 'LED Daytime Running Lights', 'Fog Lights',
  'Chrome Mirror Covers', 'Wheel Arch Trim', 'Roof Rack', 'Chrome Door Handles',
  'Mud Flaps', 'Chrome Exhaust Tip', 'Decals / Striping', 'Hood Ornament',
]
const exteriorFeaturesOptions = [
  'Sun Roof', 'Double Sun Roof', 'Panoramic Sun Roof', 'Glass Roof', 'Moon Roof',
  'Roof Box', 'Roof Rails', 'Tinted Windows', 'Privacy Glass', 'Power Sliding Doors',
  'Power Liftgate / Tailgate', 'Towing Package', 'Winch', 'Bull Bar', 'Snorkel',
]
const safetyOptions = [
  'ABS', 'EBD (Electronic Brakeforce Distribution)', 'Brake Assist',
  'Front Airbags', 'Side Airbags', 'Curtain Airbags', 'Knee Airbags',
  'Side Camera', 'Back Camera', '360° Camera', 'Corner Sensors', 'Parking Sensors',
  'Lane Departure Warning', 'Lane Keep Assist', 'Blind Spot Monitoring',
  'Rear Cross Traffic Alert', 'Forward Collision Warning', 'Autonomous Emergency Braking',
  'Hill Start Assist', 'Hill Descent Control', 'Electronic Stability Control (ESC)',
  'Traction Control', 'Tire Pressure Monitoring (TPMS)', 'Immobilizer', 'Alarm System',
  'Dash Cam', 'Speed Limiter',
]

function selectExteriorColor(name: string) {
  form.color = name
  if (name !== 'other') form.exterior_color_custom = ''
}
function hasFeature(field: string, value: string) {
  return Array.isArray(form[field]) && form[field].includes(value)
}
function toggleFeature(field: string, value: string) {
  if (!Array.isArray(form[field])) form[field] = []
  const idx = form[field].indexOf(value)
  if (idx >= 0) form[field].splice(idx, 1)
  else form[field].push(value)
}

const tc = useTenantCatalog()
onMounted(() => { tc.load(); loadCurrency() })

const makeOptions = computed(() => tc.makeOptions())

const bodyTypeOptions = computed(() => {
  if (!form.make) return tc.allBodyTypes()
  return tc.bodyTypeOptionsForMake(form.make)
})

const isElectric = computed(() => {
  const f = (form.fuel_type || '').toString()
  return /electric/i.test(f) || /^ev$/i.test(f)
})
const isHybrid = computed(() => /hybrid/i.test((form.fuel_type || '').toString()))
const isMotorized = computed(() => isElectric.value || isHybrid.value)

const modelOptions = computed(() => {
  if (!form.make || !form.body_type) return []
  return tc.modelsForMakeBodyType(form.make, form.body_type)
})

function onMakeChange() {
  form.body_type = ''
  form.model = ''
}

function onBodyTypeChange() {
  form.model = ''
}

const form = reactive<any>(defaultForm())

const reminders = ref<any[]>([])
const customValues = reactive<any>({})
const customFieldDefs = ref<any[]>([])

const newField = reactive<any>({
  name: '', label: '', field_type: 'text', is_required: false, choicesText: '',
})

function defaultForm() {
  return {
    vin: '', license_plate: '', make: '', model: '', year: null, body_type: '',
    vehicle_type: '', fuel_type: 'Petrol', status: 'active',
    color: '', current_mileage: 0, mileage_unit: 'km', engine_hours: 0,
    group: null, location: '', assigned_driver: null,
    ownership: 'self', lessor: null, lease_start_date: '', lease_end_date: '',
    lease_monthly_rate: '', deposit: '',
    in_service_date: '', out_of_service_date: '', retired_date: '',
    purchase_price: '', purchase_date: '', salvage_value: '', useful_life_years: null,
    depreciation_method: 'straight_line', residual_value: '', monthly_payment: '',
    insurance_premium: '', insurance_type: '', insurance_start_date: '', insurance_end_date: '',
    engine: '', transmission: '', trim: '', weight_rating: '', gross_vehicle_weight: null, tank_capacity: null,
    engine_size: '', motors: '',
    steering: '', drivetrain: '',
    exterior_color_custom: '',
    comfort_convenience: [], dress_up: [], exterior_features: [], safety_features: [],
    battery_capacity_kwh: null, state_of_charge: null, state_of_health: null,
  }
}

// Options data
const { data: groupsData } = useAsyncData('wizard-groups', () =>
  $api('/vehicles/groups/'), { default: () => ({ results: [], count: 0 }) }
)
const groupOptions = computed(() => groupsData.value?.results || groupsData.value || [])

/** Active Vehicle Types (from the Vehicle Types tab). Falls back to the
 *  built-in static list if the API returns nothing (e.g. not seeded yet). */
const { data: vehicleTypesData } = useAsyncData('wizard-vehicle-types', () =>
  $api('/vehicles/vehicle-types/?is_active=true').catch(() => ({ results: [] })),
  { default: () => ({ results: [], count: 0 }) },
)
const vehicleTypeOptions = computed(() => {
  const list = vehicleTypesData.value?.results || vehicleTypesData.value || []
  if (list.length) return list
  return vehicleTypes.map((t) => ({ name: t.label, value: t.value, icon: 'mdi-car', color: '#6366f1' }))
})

const { data: locationsData } = useAsyncData('wizard-locations', () =>
  $api('/locations/'), { default: () => ({ results: [], count: 0 }) }
)
const locationOptions = computed(() => locationsData.value?.results || locationsData.value || [])

const { data: driversData } = useAsyncData('wizard-drivers', () =>
  $api('/contacts/?contact_type=driver'), { default: () => ({ results: [], count: 0 }) }
)
const driverOptions = computed(() => driversData.value?.results || driversData.value || [])

const { data: lessorsData, pending: loadingLessors } = useAsyncData('wizard-lessors', () =>
  $api('/lessors/'), { default: () => ({ results: [], count: 0 }) }
)
const lessorOptions = computed(() => lessorsData.value?.results || lessorsData.value || [])

const { data: customFieldsData, refresh: refreshCustomFields } = useAsyncData('wizard-custom-fields', () =>
  $api('/vehicles/custom-fields/'), { default: () => ({ results: [], count: 0 }) }
)
watchEffect(() => {
  customFieldDefs.value = customFieldsData.value?.results || customFieldsData.value || []
})

function driverTitle(item: any) {
  return item.full_name || item.company_name || `Contact #${item.id}`
}

// Lifecycle hooks
watchEffect(() => {
  if (props.vehicle) {
    populateFromVehicle(props.vehicle)
  }
})

function populateFromVehicle(v: any) {
  Object.assign(form, defaultForm(), {
    vin: v.vin || '', license_plate: v.license_plate || '', make: v.make || '', model: v.model || '',
    year: v.year, body_type: v.body_type || '',
    vehicle_type: v.vehicle_type || 'vehicle', fuel_type: v.fuel_type || 'Petrol',
    status: v.status || 'active', color: v.color || '', current_mileage: v.current_mileage || 0,
    mileage_unit: v.mileage_unit || 'km', engine_hours: v.engine_hours || 0,
    group: v.group || null, location: v.location || '', assigned_driver: v.assigned_driver || null,
    ownership: v.ownership || 'self', lessor: v.lessor || null,
    lease_start_date: v.lease_start_date || '', lease_end_date: v.lease_end_date || '',
    lease_monthly_rate: v.lease_monthly_rate || '', deposit: v.deposit || '',
    in_service_date: v.in_service_date || '', out_of_service_date: v.out_of_service_date || '',
    retired_date: v.retired_date || '',
    purchase_price: v.purchase_price || '', purchase_date: v.purchase_date || '',
    salvage_value: v.salvage_value || '', useful_life_years: v.useful_life_years,
    depreciation_method: v.depreciation_method || 'straight_line', residual_value: v.residual_value || '',
    monthly_payment: v.monthly_payment || '',
    insurance_premium: v.insurance_premium || '', insurance_type: v.insurance_type || '',
    insurance_start_date: v.insurance_start_date || '', insurance_end_date: v.insurance_end_date || '',
    engine: v.engine || '', engine_size: v.engine_size || '', motors: v.motors || '', transmission: v.transmission || '', trim: v.trim || '',
    steering: v.steering || '', drivetrain: v.drivetrain || '',
    exterior_color_custom: v.exterior_color_custom || '',
    comfort_convenience: Array.isArray(v.comfort_convenience) ? [...v.comfort_convenience] : [],
    dress_up: Array.isArray(v.dress_up) ? [...v.dress_up] : [],
    exterior_features: Array.isArray(v.exterior_features) ? [...v.exterior_features] : [],
    safety_features: Array.isArray(v.safety_features) ? [...v.safety_features] : [],
    weight_rating: v.weight_rating || '', gross_vehicle_weight: v.gross_vehicle_weight,
    tank_capacity: v.tank_capacity, battery_capacity_kwh: v.battery_capacity_kwh,
    state_of_charge: v.state_of_charge, state_of_health: v.state_of_health,
  })
  form._id = v.id
  imageUrl.value = v.image || ''
  imageFile.value = null
}

function triggerSuffix(type: string) {
  return { time: 'months', mileage: 'mi', engine_hours: 'hrs' }[type] || ''
}

function addReminder() {
  reminders.value.push({
    title: '', trigger_type: 'time', trigger_interval: 6, escalation_level: 0,
  })
}

function fieldComponent(type: string) {
  if (type === 'boolean') return 'v-switch'
  if (type === 'select') return 'v-select'
  if (type === 'number') return 'v-text-field'
  if (type === 'date') return 'v-text-field'
  return 'v-text-field'
}

function validateDetailsStep(): boolean {
  errors.vin = ''
  errors.status = ''
  errors.group = ''
  errors.location = ''
  errors.vehicle_type = ''
  let ok = true
  if (!form.vin) {
    errors.vin = 'VIN is required.'
    ok = false
  } else {
    const len = form.vin.trim().length
    if (len < 8 || len > 17) {
      errors.vin = 'VIN must be 8–17 characters (17 for US/EU, 8–14 for Japanese chassis numbers).'
      ok = false
    }
  }
  if (!form.status) { errors.status = 'Status is required.'; ok = false }
  if (!form.group) { errors.group = 'Group is required.'; ok = false }
  if (!form.location) { errors.location = 'Location / Yard is required.'; ok = false }
  if (!form.vehicle_type) { errors.vehicle_type = 'Vehicle type is required.'; ok = false }
  return ok
}

function next() {
  if (currentStep.value === 0 && !validateDetailsStep()) return
  currentStep.value = Math.min(currentStep.value + 1, steps.length - 1)
}

function goToStep(i: number) {
  if (i === currentStep.value) return
  if (i === 0 && !validateDetailsStep()) return
  if (i > currentStep.value && currentStep.value === 0 && !validateDetailsStep()) return
  currentStep.value = i
}

async function decodeVin() {
  if (!form.vin || form.vin.trim().length !== 17) {
    errors.vin = 'VIN decode requires a 17-character US/EU VIN. Japanese chassis numbers cannot be auto-decoded.'
    return
  }
  decoding.value = true
  try {
    const data = await $api('/vehicles/vin-decode/', { method: 'POST', body: { vin: form.vin } })
    if (data.make) form.make = data.make
    if (data.model) form.model = data.model
    if (data.year) form.year = parseInt(data.year)
    if (data.engine) form.engine = data.engine
    if (data.transmission) form.transmission = data.transmission
    if (data.weight_rating) form.weight_rating = data.weight_rating
  } catch (e) {
    console.error('VIN decode failed:', e)
  } finally {
    decoding.value = false
  }
}

async function createCustomField() {
  if (!newField.name) return
  savingField.value = true
  try {
    const payload: any = {
      name: newField.name,
      label: newField.label,
      field_type: newField.field_type,
      is_required: newField.is_required,
      choices: newField.field_type === 'select'
        ? newField.choicesText.split(',').map((c: string) => c.trim()).filter(Boolean)
        : [],
    }
    const created = await $api('/vehicles/custom-fields/', { method: 'POST', body: payload })
    await refreshCustomFields()
    Object.assign(newField, { name: '', label: '', field_type: 'text', is_required: false, choicesText: '' })
    showFieldDefDialog.value = false
  } catch (e) {
    console.error('Custom field create failed:', e)
  } finally {
    savingField.value = false
  }
}

async function save() {
  if (!validateDetailsStep()) {
    currentStep.value = 0
    return
  }
  saving.value = true
  try {
    const payload = buildVehiclePayload()
    const hasImage = !!imageFile.value
    let vehicleId: number

    if (editing.value) {
      const updated = hasImage
        ? await $api(`/vehicles/vehicles/${form._id}/`, { method: 'PATCH', body: toFormData(payload, imageFile.value!) })
        : await $api(`/vehicles/vehicles/${form._id}/`, { method: 'PATCH', body: payload })
      vehicleId = updated.id
      if (hasImage && updated.image) imageUrl.value = updated.image
    } else {
      const created = hasImage
        ? await $api('/vehicles/vehicles/', { method: 'POST', body: toFormData(payload, imageFile.value!) })
        : await $api('/vehicles/vehicles/', { method: 'POST', body: payload })
      vehicleId = created.id
      if (hasImage && created.image) imageUrl.value = created.image
    }
    imageFile.value = null

    // Create reminders (maintenance step) — skip on edit to avoid duplicates
    if (!editing.value) {
      for (const r of reminders.value) {
        if (!r.title) continue
        await $api('/reminders/', {
          method: 'POST',
          body: {
            vehicle: vehicleId,
            title: r.title,
            trigger_type: r.trigger_type,
            trigger_interval: r.trigger_interval,
            escalation_level: r.escalation_level,
            is_active: true,
          },
        })
      }
    }

    // Sync custom field values
    await syncCustomFieldValues(vehicleId)

    emit('saved')
  } catch (e: any) {
    console.error('Save error:', e?.data || e)
    if (e?.data) {
      errors.vin = e.data.vin?.[0] || ''
    }
  } finally {
    saving.value = false
  }
}

function toFormData(payload: any, file: File): FormData {
  const fd = new FormData()
  for (const [key, value] of Object.entries(payload)) {
    if (value === null || value === undefined) continue
    if (Array.isArray(value)) {
      fd.append(key, JSON.stringify(value))
    } else if (typeof value === 'object' && !(value instanceof File)) {
      fd.append(key, JSON.stringify(value))
    } else {
      fd.append(key, value as any)
    }
  }
  fd.append('image', file)
  return fd
}

function buildVehiclePayload() {
  const payload: any = { ...form }
  delete payload._id
  for (const f of ['engine', 'transmission', 'trim', 'fuel_type', 'engine_size', 'motors']) {
    const v = payload[f]
    payload[f] = typeof v === 'string' ? v : (v?.value || v?.label || '')
  }
  const featureArrays = ['comfort_convenience', 'dress_up', 'exterior_features', 'safety_features']
  for (const f of featureArrays) {
    payload[f] = Array.isArray(payload[f]) ? payload[f] : []
  }
  if (payload.color !== 'other') payload.exterior_color_custom = ''
  const decimalFields = ['purchase_price', 'salvage_value', 'residual_value', 'monthly_payment', 'lease_monthly_rate', 'insurance_premium', 'deposit']
  for (const f of decimalFields) {
    if (payload[f] === '' || payload[f] == null) {
      delete payload[f]
    } else {
      payload[f] = parseFloat(payload[f])
    }
  }
  if (payload.ownership !== 'lease') {
    payload.lessor = null
    delete payload.lease_start_date
    delete payload.lease_end_date
    delete payload.lease_monthly_rate
    delete payload.deposit
  } else if (!payload.lessor) {
    payload.lessor = null
  }
  // Clear empty date strings
  const dateFields = ['lease_start_date', 'lease_end_date', 'in_service_date', 'out_of_service_date', 'retired_date', 'purchase_date', 'insurance_start_date', 'insurance_end_date']
  for (const f of dateFields) {
    if (payload[f] === '') delete payload[f]
  }
  return payload
}

async function syncCustomFieldValues(vehicleId: number) {
  const existing = await $api(`/vehicles/custom-field-values/?vehicle=${vehicleId}`).catch(() => ({ results: [] }))
  const existingMap: Record<number, number> = {}
  for (const ev of (existing.results || existing || [])) {
    existingMap[ev.field] = ev.id
  }
  for (const field of customFieldDefs.value) {
    const rawValue = customValues[field.id]
    if (rawValue === undefined || rawValue === '' || rawValue === false) {
      if (field.is_required && !editing.value) continue
      if (existingMap[field.id]) {
        await $api(`/vehicles/custom-field-values/${existingMap[field.id]}/`, { method: 'DELETE' }).catch(() => {})
      }
      continue
    }
    const valueStr = typeof rawValue === 'boolean' ? String(rawValue) : String(rawValue)
    if (existingMap[field.id]) {
      await $api(`/vehicles/custom-field-values/${existingMap[field.id]}/`, {
        method: 'PATCH', body: { vehicle: vehicleId, field: field.id, value: valueStr },
      })
    } else {
      await $api('/vehicles/custom-field-values/', {
        method: 'POST', body: { vehicle: vehicleId, field: field.id, value: valueStr },
      })
    }
  }
}

// Load existing custom values when editing
watchEffect(async () => {
  if (!props.vehicle?.id) return
  const res = await $api(`/vehicles/custom-field-values/?vehicle=${props.vehicle.id}`).catch(() => ({ results: [] }))
  for (const ev of (res.results || res || [])) {
    customValues[ev.field] = ev.value
  }
})

defineExpose({ reset: () => { Object.assign(form, defaultForm()); reminders.value = []; currentStep.value = 0 } })
</script>

<style scoped>
.wizard-header {
  background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%);
}
.wizard-body {
  min-height: 320px;
}
.reminder-row {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}

/* Step headings */
.step-title-lg {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 4px;
  letter-spacing: -0.01em;
}
.step-subtitle {
  font-size: 14px;
  color: #64748b;
  margin-bottom: 22px;
}
.vehicle-image-upload {
  padding: 14px;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  background: #f8fafc;
}
.vehicle-image-preview {
  width: 120px;
  height: 90px;
  border-radius: 12px;
  border: 1px dashed #cbd5e1;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  flex-shrink: 0;
}
.vehicle-image-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.field-group-label {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #94a3b8;
  margin-bottom: 6px;
}

.vehicle-wizard--vertical {
  display: flex;
  min-height: 600px;
}

.wizard-rail {
  width: 280px;
  flex-shrink: 0;
  background: #f8fafc;
  border-right: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
}

.step-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.step-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  border-radius: 10px;
  cursor: pointer;
  transition: background 0.15s ease;
}

.step-item:hover {
  background: #eef2ff;
}

.step-item .step-icon {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  border: 2px solid #e2e8f0;
  color: #94a3b8;
  flex-shrink: 0;
  transition: all 0.15s ease;
}

.step-item.active .step-icon {
  background: #6366f1;
  border-color: #6366f1;
  color: #ffffff;
}

.step-item.complete .step-icon {
  background: #4f46e5;
  border-color: #4f46e5;
  color: #ffffff;
}

.step-item .step-title {
  font-size: 14px;
  font-weight: 600;
  color: #64748b;
  line-height: 1.2;
}

.step-item .step-num {
  font-size: 11px;
  color: #94a3b8;
}

.step-item.active .step-title {
  color: #4f46e5;
}

.wizard-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

/* Specifications — premium styling */
.spec-section-title {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #4f46e5;
  display: flex;
  align-items: center;
  gap: 8px;
}
.spec-section-title::before {
  content: '';
  width: 3px;
  height: 14px;
  background: linear-gradient(180deg, #6366f1, #4f46e5);
  border-radius: 2px;
}

/* Steering segmented toggle */
.seg-toggle {
  display: flex;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
}
.seg-toggle-item {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 9px 8px;
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  background: #ffffff;
  cursor: pointer;
  transition: all 0.15s ease;
  border-right: 1px solid #e2e8f0;
}
.seg-toggle-item:last-child { border-right: none; }
.seg-toggle-item:hover { background: #f8fafc; }
.seg-toggle-item.active {
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: #ffffff;
}

/* Exterior color chips */
.color-chip-row {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
}
.color-chip {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  cursor: pointer;
}
.color-chip-swatch {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.4);
  transition: transform 0.12s ease, box-shadow 0.12s ease;
}
.color-chip:hover .color-chip-swatch { transform: scale(1.08); }
.color-chip.active .color-chip-swatch {
  box-shadow: 0 0 0 3px #6366f1, inset 0 0 0 2px rgba(255, 255, 255, 0.4);
  transform: scale(1.08);
}
.color-chip-label {
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  text-transform: capitalize;
}
.color-chip.active .color-chip-label { color: #4f46e5; }

.native-color-input {
  width: 48px;
  height: 48px;
  padding: 0;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  background: transparent;
}

/* Feature toggle chips */
.feature-group {
  margin-top: 18px;
  padding: 16px;
  border: 1px solid #eef2f6;
  border-radius: 14px;
  background: linear-gradient(180deg, #ffffff, #fbfcfe);
}
.feature-group-head {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}
.feature-chip-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.feature-chip {
  display: inline-flex;
  align-items: center;
  padding: 7px 12px;
  font-size: 13px;
  font-weight: 500;
  color: #475569;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  cursor: pointer;
  transition: all 0.15s ease;
  user-select: none;
}
.feature-chip:hover {
  border-color: #c7d2fe;
  background: #f5f7ff;
}
.feature-chip.active {
  background: linear-gradient(135deg, #6366f1, #4f46e5);
  color: #ffffff;
  border-color: transparent;
  box-shadow: 0 4px 12px rgba(99, 102, 241, 0.25);
}
.feature-chip.active .v-icon { color: #ffffff; }
</style>
