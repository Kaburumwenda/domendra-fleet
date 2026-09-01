/**
 * `v-can` directive — declaratively hide/remove elements the current user
 * is not permitted to access.
 *
 * Usage:
 *   <v-btn v-can="'vehicles:delete'" @click="remove">Delete</v-btn>
 *   <v-btn v-can="['vehicles', 'delete']" @click="remove">Delete</v-btn>
 *   <v-btn v-can.canAny="['vehicles:delete', 'dispatch:assign']"> … </v-btn>
 *
 * The directive uses the reactive `useRbac()` state, so elements update
 * automatically when permissions are (re)loaded after login or role change.
 *
 * Two modifiers are supported:
 *  - `v-can` (default) — *all* listed codes must be granted (AND).
 *  - `v-can.canAny` — *any* listed code grants access (OR).
 *
 * When access is denied the element is removed from the DOM (via
 * `v-if`-style unmount on the comment placeholder) so it cannot be
 * triggered by keyboard or accidental focus. Use `v-can.show` to keep
 * the element mounted but visually hidden (display:none) if you need the
 * layout to remain stable.
 */
import type { Directive, DirectiveBinding } from 'vue'

function toCodes(value: unknown): string[] {
  if (Array.isArray(value)) {
    // ['vehicles', 'delete'] → 'vehicles:delete'
    if (value.length === 2 && typeof value[0] === 'string' && typeof value[1] === 'string' && !value[0].includes(':')) {
      return [`${value[0]}:${value[1]}`]
    }
    return (value as (string | undefined)[]).filter((v): v is string => typeof v === 'string')
  }
  if (typeof value === 'string') return [value]
  return []
}

export default defineNuxtPlugin((nuxtApp) => {
  const rbac = useRbac()

  function evaluate(binding: DirectiveBinding): boolean {
    const codes = toCodes(binding.value)
    if (codes.length === 0) return true
    const any = binding.modifiers.canAny
    if (any) return codes.some((c) => splitCan(c))
    return codes.every((c) => splitCan(c))
  }

  function splitCan(code: string): boolean {
    const idx = code.indexOf(':')
    if (idx === -1) return rbac.canCode(code)
    return rbac.can(code.slice(0, idx), code.slice(idx + 1))
  }

  const vCan: Directive = {
    mounted(el: HTMLElement, binding: DirectiveBinding) {
      if (!evaluate(binding) && !binding.modifiers.show) {
        // Remove from the DOM entirely (mirrors v-if behaviour)
        if (el.parentNode) el.parentNode.removeChild(el)
      }
    },
    updated(el: HTMLElement, binding: DirectiveBinding) {
      if (!evaluate(binding) && !binding.modifiers.show) {
        if (el.parentNode) el.parentNode.removeChild(el)
      }
    },
  }

  nuxtApp.vueApp.directive('can', vCan)
})
