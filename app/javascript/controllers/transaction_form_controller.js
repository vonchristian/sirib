import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount", "description", "fromAccount", "toAccount", "submitBtn", "preview", "errors"]
  static values = {
    cashSessionId: Number,
    idempotencyKey: String
  }

  connect() {
    this._generateIdempotencyKey()
  }

  validate(event) {
    const amount = parseFloat(this.amountTarget.value)
    const description = this.descriptionTarget.value.trim()

    if (isNaN(amount) || amount <= 0) {
      this._showError("Amount must be greater than 0")
      return
    }

    if (!description) {
      this._showError("Description is required")
      return
    }

    this._clearErrors()
    this._updatePreview(amount, description)
  }

  async submit(event) {
    event.preventDefault()
    this.submitBtnTarget.disabled = true

    const form = event.currentTarget
    const formData = new FormData(form)
    formData.append("idempotency_key", this.idempotencyKeyValue)

    try {
      const response = await fetch(form.action, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        this._reset()
        this._generateIdempotencyKey()
      } else {
        const html = await response.text()
        if (response.headers.get("content-type")?.includes("turbo-stream")) {
          Turbo.renderStreamMessage(html)
        } else {
          this._showError("Transaction failed. Please try again.")
        }
      }
    } catch (error) {
      this._showError("Network error. Please check your connection.")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  async previewTransaction(event) {
    event.preventDefault()
    this._clearErrors()

    const form = event.currentTarget.closest("form")
    const formData = new FormData(form)

    try {
      const response = await fetch(form.action + "/preview", {
        method: "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      this._showError("Preview generation failed")
    }
  }

  _updatePreview(amount, description) {
    if (!this.hasPreviewTarget) return
    this.previewTarget.innerHTML = `
      <div class="rounded-md border border-border bg-surface-alt p-3 text-sm">
        <p class="font-medium text-text-primary">Transaction Preview</p>
        <p class="text-text-secondary mt-1">Amount: ₱${amount.toFixed(2)}</p>
        <p class="text-text-secondary">Description: ${this._escapeHtml(description)}</p>
      </div>
    `
  }

  _showError(message) {
    if (this.hasErrorsTarget) {
      this.errorsTarget.textContent = message
      this.errorsTarget.classList.remove("hidden")
    }
  }

  _clearErrors() {
    if (this.hasErrorsTarget) {
      this.errorsTarget.classList.add("hidden")
      this.errorsTarget.textContent = ""
    }
  }

  _reset() {
    if (this.hasAmountTarget) this.amountTarget.value = ""
    if (this.hasDescriptionTarget) this.descriptionTarget.value = ""
    if (this.hasPreviewTarget) this.previewTarget.innerHTML = ""
    if (this.hasFromAccountTarget) this.fromAccountTarget.selectedIndex = 0
    if (this.hasToAccountTarget) this.toAccountTarget.selectedIndex = 0
    this._clearErrors()
  }

  _generateIdempotencyKey() {
    this.idempotencyKeyValue = crypto.randomUUID()
  }

  _csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content
  }

  _escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
