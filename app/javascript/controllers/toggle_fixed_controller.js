import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isFixed = this.element.value === "fixed"
    const input = this.amountTarget
    if (input) {
      input.disabled = !isFixed
      if (!isFixed) input.value = ""
    }
  }
}
