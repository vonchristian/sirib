import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "backdrop"]

  connect() {
    this.close()
  }

  toggle() {
    if (this.menuTarget.classList.contains("translate-x-0")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.remove("translate-x-full")
    this.menuTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("hidden")
    this.backdropTarget.classList.add("flex")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.menuTarget.classList.remove("translate-x-0")
    this.menuTarget.classList.add("translate-x-full")
    this.backdropTarget.classList.remove("flex")
    this.backdropTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  closeKeydown(e) {
    if (e.key === "Escape") this.close()
  }

  backdropClick() {
    this.close()
  }
}
