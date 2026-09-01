<template>
  <div>
    <!-- Mobile logo (shown on small screens where brand panel is hidden) -->
    <div class="d-flex align-center ga-2 mb-8 d-md-none login-anim" style="--li:0">
      <div class="auth-mobile-logo">
        <img src="/logo.png" alt="DomendraFleet" style="width: 100%; height: 100%; object-fit: contain; border-radius: 8px;" />
      </div>
      <span class="text-h6 font-weight-bold" style="color: rgb(var(--v-theme-on-surface))">DomendraFleet</span>
    </div>

    <div class="mb-8 login-anim" style="--li:1">
      <h2 class="auth-page-title">Welcome back</h2>
      <p class="auth-page-subtitle">Sign in to your fleet management dashboard</p>
    </div>

    <v-alert v-if="serverError" type="error" variant="tonal" density="comfortable" class="mb-5 rounded-lg">
      <template #prepend><v-icon>mdi-alert-circle-outline</v-icon></template>
      {{ serverError }}
    </v-alert>

    <form @submit.prevent="handleLogin" class="d-flex flex-column ga-5">
      <div class="login-anim" style="--li:2">
        <label class="auth-field-label">Email</label>
        <v-text-field
          v-model="email"
          type="email"
          placeholder="you@company.com"
          prepend-inner-icon="mdi-email-outline"
          variant="outlined"
          density="comfortable"
          color="primary"
          rounded="lg"
          hide-details="auto"
          :error-messages="errors.email"
          class="auth-input"
        />
      </div>

      <div class="login-anim" style="--li:3">
        <label class="auth-field-label">Password</label>
        <v-text-field
          v-model="password"
          :type="showPassword ? 'text' : 'password'"
          :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
          @click:append-inner="showPassword = !showPassword"
          placeholder="Enter your password"
          prepend-inner-icon="mdi-lock-outline"
          variant="outlined"
          density="comfortable"
          color="primary"
          rounded="lg"
          hide-details="auto"
          :error-messages="errors.password"
          class="auth-input"
        />
      </div>

      <v-btn
        type="submit"
        class="auth-submit-btn login-anim"
        style="--li:4"
        size="large"
        prepend-icon="mdi-login"
        :loading="loading"
        :disabled="loading"
        elevation="0"
        rounded="lg"
        block
      >
        Sign In
      </v-btn>
    </form>

    <div class="auth-divider mt-7 login-anim" style="--li:5">
      <span>or</span>
    </div>

    <v-btn
      class="auth-google-btn mt-5 login-anim"
      style="--li:6"
      variant="outlined"
      size="large"
      rounded="lg"
      block
      prepend-icon="mdi-google"
      disabled
    >
      Continue with Google
    </v-btn>

    <p class="text-center mt-6 auth-switch-link login-anim" style="--li:7">
      New to DomendraFleet?
      <NuxtLink to="/register">Create an account</NuxtLink>
    </p>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const auth = useAuthStore()
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const serverError = ref('')
const errors = reactive<Record<string, string>>({})

async function handleLogin() {
  errors.email = ''
  errors.password = ''
  serverError.value = ''

  if (!email.value) errors.email = 'Email is required'
  if (!password.value) errors.password = 'Password is required'
  if (Object.values(errors).some(v => v)) return

  loading.value = true
  try {
    // Clear any stale RBAC state from a previous session before logging in
    const rbac = useRbac()
    rbac.clearPermissions()
    await auth.login(email.value, password.value)
    await navigateTo(auth.isAdmin ? '/superadmin' : '/app')
  } catch (e: any) {
    serverError.value = e?.data?.detail || e?.data?.email?.[0] || 'Invalid credentials'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page-title {
  font-size: 26px;
  font-weight: 750;
  color: rgb(var(--v-theme-on-surface));
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.auth-page-subtitle {
  font-size: 15px;
  color: rgba(var(--v-theme-on-surface), 0.6);
  margin-top: 4px;
}

.auth-field-label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: rgba(var(--v-theme-on-surface), 0.7);
  margin-bottom: 8px;
}

.auth-input :deep(.v-field--variant-outlined .v-field__outline__start),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__notch),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__end) {
  border-color: rgba(var(--v-theme-on-surface), 0.2);
}

.auth-input :deep(.v-field--variant-outlined:hover .v-field__outline__start),
.auth-input :deep(.v-field--variant-outlined:hover .v-field__outline__notch),
.auth-input :deep(.v-field--variant-outlined:hover .v-field__outline__end) {
  border-color: #c7d2fe;
}

.auth-input :deep(.v-field--variant-outlined .v-field__outline__start),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__notch),
.auth-input :deep(.v-field--variant-outlined .v-field__outline__end),
.auth-input :deep(.v-field__input) {
  color: rgb(var(--v-theme-on-surface));
}

.auth-input :deep(.v-field--variant-outlined .v-field__input) {
  color: rgb(var(--v-theme-on-surface));
}

.auth-submit-btn {
  text-transform: none !important;
  font-weight: 600 !important;
  font-size: 15px !important;
  letter-spacing: 0.01em !important;
  height: 50px !important;
  background: linear-gradient(135deg, #6366f1, #4f46e5) !important;
  color: #fff !important;
  box-shadow: 0 4px 16px rgba(99, 102, 241, 0.3) !important;
  transition: transform 0.15s ease, box-shadow 0.15s ease !important;
}

.auth-submit-btn:hover:not(:disabled) {
  box-shadow: 0 8px 24px rgba(99, 102, 241, 0.4) !important;
  transform: translateY(-1px);
}

.auth-google-btn {
  text-transform: none !important;
  font-weight: 600 !important;
  font-size: 14px !important;
  height: 50px !important;
  color: rgba(var(--v-theme-on-surface), 0.7) !important;
  border-color: rgba(var(--v-theme-on-surface), 0.2) !important;
  background: rgb(var(--v-theme-surface)) !important;
}

.auth-divider {
  text-align: center;
  position: relative;
}

.auth-divider::before,
.auth-divider::after {
  content: '';
  position: absolute;
  top: 50%;
  width: 40%;
  height: 1px;
  background: rgba(var(--v-theme-on-surface), 0.12);
}

.auth-divider::before { left: 0; }
.auth-divider::after { right: 0; }

.auth-divider span {
  font-size: 12px;
  color: rgba(var(--v-theme-on-surface), 0.4);
  font-weight: 500;
  background: rgb(var(--v-theme-surface));
  padding: 0 12px;
  position: relative;
  z-index: 1;
}

.auth-switch-link {
  font-size: 14px;
  color: rgba(var(--v-theme-on-surface), 0.6);
}

.auth-switch-link a {
  color: #6366f1;
  font-weight: 600;
  text-decoration: none;
}

.auth-switch-link a:hover {
  text-decoration: underline;
}

.auth-mobile-logo {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: rgba(99, 102, 241, 0.08);
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ---- Staggered entrance ---- */
.login-anim {
  animation: login-fade-up 0.55s ease both;
  animation-delay: calc(var(--li, 0) * 80ms);
}
@keyframes login-fade-up {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}
@media (prefers-reduced-motion: reduce) {
  .login-anim { animation: none !important; }
}
</style>
