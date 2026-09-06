/**
 * Scroll-triggered reveal animation composable.
 *
 * Usage in <script setup>:
 *   const { register } = useScrollReveal()
 *   onMounted(() => register('.reveal'))
 *
 * Add class `reveal` to any element. Optional modifiers:
 *   data-reveal-delay="200"    — stagger in ms
 *   data-reveal-type="up"      — up | left | right | scale | fade (default: up)
 *
 * In template:
 *   <div class="reveal" data-reveal-type="up">...</div>
 *   <div class="reveal" data-reveal-delay="200">...</div>
 */
const observers: IntersectionObserver[] = []

export function useScrollReveal() {
  function register(selector = '.reveal') {
    if (!import.meta.client) return

    // Clean previous observers
    observers.forEach((o) => o.disconnect())
    observers.length = 0

    const els = document.querySelectorAll<HTMLElement>(selector)
    if (!els.length) return

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const el = entry.target as HTMLElement
            const delay = parseInt(el.dataset.revealDelay || '0')
            setTimeout(() => el.classList.add('reveal--in'), delay)
            observer.unobserve(el)
          }
        })
      },
      { threshold: 0.15, rootMargin: '0px 0px -60px 0px' },
    )

    els.forEach((el) => observer.observe(el))
    observers.push(observer)
  }

  return { register }
}
