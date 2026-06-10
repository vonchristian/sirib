import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search"]

  connect() {
    this.timeout = null
  }

  submit() {
    this.element.requestSubmit()
  }

  submitDelayed() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 400)
  }

  visitRow(event) {
    const row = event.currentTarget
    const href = row.dataset.href
    if (href) {
      Turbo.visit(href)
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
