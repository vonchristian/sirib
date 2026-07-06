import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundClose = this.close.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.element.classList.contains("landing-dd-open")

    this.element.parentElement.querySelectorAll(".landing-dd-open").forEach(g => {
      if (g !== this.element) g.classList.remove("landing-dd-open")
    })

    if (isOpen) {
      this.element.classList.remove("landing-dd-open")
      document.removeEventListener("click", this.boundClose)
    } else {
      this.element.classList.add("landing-dd-open")
      document.addEventListener("click", this.boundClose)
    }
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.element.classList.remove("landing-dd-open")
      document.removeEventListener("click", this.boundClose)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }
}
