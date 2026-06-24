import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["interestRate", "termMonths", "gracePeriod", "arrears", "partialPayoff"]

  connect() {
    this.scheduleSimulation()
  }

  scheduleSimulation() {
    clearTimeout(this._timeout)
    this._timeout = setTimeout(() => this.runSimulation(), 500)
  }

  async runSimulation() {
    const form = this.element
    const formData = new FormData(form)

    try {
      const response = await fetch(this.element.action.replace(/\/restructures(\/\d+)?$/, "/restructures/simulate"), {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      if (!response.ok) return

      const data = await response.json()
      this.renderSimulation(data)
    } catch (e) {
      // silently fail
    }
  }

  renderSimulation(data) {
    const panel = document.getElementById("simulation-content")
    if (!panel) return

    if (data.error) {
      panel.innerHTML = `<p class="text-sm text-danger italic">${data.error}</p>`
      return
    }

    const formatMoney = (cents) => {
      return "PHP " + (parseFloat(cents) || 0).toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    }

    const changeColor = data.payment_change < 0 ? "text-positive" : "text-danger"
    const impactColor = data.interest_impact < 0 ? "text-positive" : data.interest_impact > 0 ? "text-danger" : "text-text-primary"

    panel.innerHTML = `
      <div class="space-y-4">
        <div class="grid grid-cols-2 gap-3">
          <div class="rounded-lg border border-border bg-surface-alt p-3">
            <span class="text-xs text-text-tertiary">Old Monthly Payment</span>
            <p class="text-lg font-bold text-text-primary">${formatMoney(data.old_monthly_payment)}</p>
          </div>
          <div class="rounded-lg border border-border bg-surface-alt p-3">
            <span class="text-xs text-text-tertiary">New Monthly Payment</span>
            <p class="text-lg font-bold ${changeColor}">${formatMoney(data.new_monthly_payment)}</p>
          </div>
        </div>
        <div class="flex items-center justify-between rounded-lg bg-surface-alt px-3 py-2">
          <span class="text-xs text-text-tertiary">Difference</span>
          <span class="text-sm font-medium ${changeColor}">
            ${data.payment_change_pct}% (${formatMoney(Math.abs(data.payment_change))})
          </span>
        </div>
        <div class="flex items-center justify-between rounded-lg bg-surface-alt px-3 py-2">
          <span class="text-xs text-text-tertiary">Total Interest Impact</span>
          <span class="text-sm font-medium ${impactColor}">
            ${formatMoney(Math.abs(data.interest_impact))}
            ${data.interest_impact < 0 ? "saved" : data.interest_impact > 0 ? "increase" : "unchanged"}
          </span>
        </div>
        <div class="flex items-center justify-between rounded-lg bg-surface-alt px-3 py-2">
          <span class="text-xs text-text-tertiary">New Term</span>
          <span class="text-sm font-medium text-text-primary">${data.new_term_months} months</span>
        </div>
        <div class="flex items-center justify-between rounded-lg bg-surface-alt px-3 py-2">
          <span class="text-xs text-text-tertiary">New Interest Rate</span>
          <span class="text-sm font-medium text-text-primary">${data.new_interest_rate}%</span>
        </div>
      </div>
    `
  }
}
