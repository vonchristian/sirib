import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "toggle", "eye", "eyeOff"]

  connect() {
    this.visible = false
  }

  toggle() {
    this.visible = !this.visible
    this.inputTarget.type = this.visible ? "text" : "password"
    this.eyeTarget.classList.toggle("hidden", this.visible)
    this.eyeOffTarget.classList.toggle("hidden", !this.visible)
  }
}