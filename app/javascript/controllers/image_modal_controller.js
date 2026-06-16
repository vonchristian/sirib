import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "trigger"]

  connect() {
    this.boundClose = this.close.bind(this)
  }

  open(event) {
    const trigger = event.currentTarget
    const src = trigger.dataset.imageModalSrcValue || trigger.src
    this.imageTarget.src = src
    this.dialogTarget.showModal()
    this.dialogTarget.addEventListener("click", this.boundClose)
  }

  close(event) {
    if (event) {
      if (event.target !== this.dialogTarget && event.type !== "keydown") return
    }
    this.dialogTarget.close()
    this.dialogTarget.removeEventListener("click", this.boundClose)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
