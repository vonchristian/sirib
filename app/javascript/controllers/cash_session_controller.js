import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    const row = event.currentTarget
    const detail = row.nextElementSibling
    if (detail && detail.id && detail.id.startsWith("voucher-detail-")) {
      detail.classList.toggle("hidden")
      row.classList.toggle("is-expanded")
    }
  }
}
