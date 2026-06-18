import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time", "date"]

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  tick() {
    const now = new Date()
    if (this.hasTimeTarget) {
      this.timeTarget.textContent = now.toLocaleTimeString("en-PH", { hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false })
    }
    if (this.hasDateTarget) {
      this.dateTarget.textContent = now.toLocaleDateString("en-PH", { weekday: "long", year: "numeric", month: "long", day: "numeric" })
    }
  }
}
