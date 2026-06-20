import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  add(event) {
    event.preventDefault()
    const content = this.element.dataset.fields
    const id = this.element.dataset.targetId
    const regexp = new RegExp(`new_${this.element.dataset.association || "accounting_entry_template_lines"}`, "g")
    const html = content.replace(regexp, id)
    const container = document.getElementById("template-lines")
    if (container) {
      container.insertAdjacentHTML("beforeend", html)
    }
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest(".nested-fields")
    if (wrapper) {
      const destroyInput = wrapper.querySelector("input[name*='_destroy']")
      if (destroyInput) {
        destroyInput.value = "1"
        wrapper.style.display = "none"
      }
    }
  }
}
