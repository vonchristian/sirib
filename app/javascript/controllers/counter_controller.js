import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    start: { type: Number, default: 0 },
    end: { type: Number, default: 0 },
    duration: { type: Number, default: 800 },
    prefix: String,
    suffix: String,
    decimals: { type: Number, default: 0 },
    separator: { type: String, default: "," },
  }

  connect() {
    this._animate()
  }

  _animate() {
    const startTime = performance.now()
    const startVal = this.startValue
    const endVal = this.endValue
    const duration = this.durationValue
    const diff = endVal - startVal

    const tick = (now) => {
      const elapsed = now - startTime
      const progress = Math.min(elapsed / duration, 1)
      const eased = 1 - Math.pow(1 - progress, 3)
      const current = startVal + diff * eased
      this.element.textContent = this._format(current)

      if (progress < 1) {
        requestAnimationFrame(tick)
      } else {
        this.element.textContent = this._format(endVal)
        this.element.classList.add("text-primary")
      }
    }

    requestAnimationFrame(tick)
  }

  _format(value) {
    const rounded = value.toFixed(this.decimalsValue)
    const parts = rounded.split(".")
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, this.separatorValue)
    const num = parts.join(".")
    return `${this.prefixValue}${num}${this.suffixValue}`
  }
}
