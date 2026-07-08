import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static values = {
    threshold: { type: Number, default: 0.1 },
    rootMargin: { type: String, default: "0px 0px -40px 0px" },
    stagger: { type: Number, default: 50 },
    animated: { type: Boolean, default: false },
  }

  connect() {
    if (this.animatedValue) return
    this.observer = new IntersectionObserver(
      (entries) => this._onIntersect(entries),
      { threshold: this.thresholdValue, rootMargin: this.rootMarginValue }
    )
    if (this.hasItemTarget) {
      this.itemTargets.forEach((el) => this.observer.observe(el))
    } else {
      this.observer.observe(this.element)
    }
  }

  disconnect() {
    this.observer?.disconnect()
  }

  _onIntersect(entries) {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue
      const target = entry.target
      this.observer.unobserve(target)

      const items = target.matches("[data-reveal-item]")
        ? [target]
        : [...target.querySelectorAll("[data-reveal-item]")]
      if (items.length === 0) {
        target.classList.add("animate-reveal")
      } else {
        items.forEach((el, i) => {
          const delay = Math.min(i * this.staggerValue, 400)
          el.style.animationDelay = `${delay}ms`
          el.classList.add("animate-reveal")
        })
      }
    }
  }
}
