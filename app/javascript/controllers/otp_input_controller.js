import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.submitOnComplete = this.element.dataset.otpAutoSubmit !== "false"
  }

  inputTargetConnected(element) {
    element.addEventListener("input", this._onInput.bind(this))
    element.addEventListener("paste", this._onPaste.bind(this))
  }

  _onInput(event) {
    const digits = event.target.value.replace(/\D/g, "")
    event.target.value = digits

    if (this.submitOnComplete && digits.length === 6) {
      this.element.requestSubmit()
    }
  }

  _onPaste(event) {
    event.preventDefault()
    const paste = (event.clipboardData || window.clipboardData).getData("text")
    const digits = paste.replace(/\D/g, "").slice(0, 6)
    event.target.value = digits

    if (this.submitOnComplete && digits.length === 6) {
      this.element.requestSubmit()
    }
  }
}
