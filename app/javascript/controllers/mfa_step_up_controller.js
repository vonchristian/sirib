import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "content", "error"]

  connect() {
    this.verifyUrl = this.element.dataset.verifyUrl || "/mfa/step_up_verify"
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"

    const input = this.contentTarget.querySelector("input")
    if (input) setTimeout(() => input.focus(), 100)
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  cancel() {
    this.close()
  }

  async verify(event) {
    event.preventDefault()

    const form = event.target
    const formData = new FormData(form)
    const submitButton = form.querySelector("[type=submit]")
    const errorEl = this.errorTarget

    errorEl.classList.add("hidden")
    errorEl.textContent = ""

    if (submitButton) submitButton.disabled = true

    try {
      const response = await fetch(this.verifyUrl, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content,
          "Accept": "application/json"
        },
        body: new URLSearchParams(formData)
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.dispatch("verified", { detail: { response: data } })
        this.close()
      } else {
        errorEl.textContent = data.error || "Invalid verification code."
        errorEl.classList.remove("hidden")

        const input = this.contentTarget.querySelector("input")
        if (input) {
          input.value = ""
          input.focus()
        }
      }
    } catch (err) {
      errorEl.textContent = "An error occurred. Please try again."
      errorEl.classList.remove("hidden")
    } finally {
      if (submitButton) submitButton.disabled = false
    }
  }

  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  keyboardClose(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
