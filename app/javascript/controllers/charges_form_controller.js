import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    this.index = this.listTarget.querySelectorAll(".grid").length
  }

  add() {
    const clone = this.templateTarget.content.cloneNode(true)
    const html = clone.firstElementChild.outerHTML
      .replace(/__INDEX__/g, this.index)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.index++
  }

  remove(event) {
    const row = event.currentTarget.closest(".grid")
    if (!row) return
    const destroy = row.querySelector("input[name*='_destroy']")
    if (destroy) {
      destroy.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
