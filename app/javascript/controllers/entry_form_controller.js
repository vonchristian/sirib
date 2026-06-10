import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "line", "debitTotal", "creditTotal", "difference"]

  connect() {
    this.counter = 0
    this.addLine()
    this.addLine()
    this.updateTotals()
  }

  get lineElements() {
    return this.linesTarget.querySelectorAll("[data-entry-form-target='line']")
  }

  formatMoney(n) {
    return "PHP " + n.toFixed(2)
  }

  addLine(event) {
    if (event) event.preventDefault()
    const index = this.counter++
    const tpl = document.getElementById("line_template")
    const row = tpl.content.cloneNode(true)

    row.querySelectorAll("[data-entry-form-name]").forEach(el => {
      const field = el.dataset.entryFormName
      el.name = `entry[amount_lines_attributes][${index}][${field}]`
      el.id = `entry_amount_lines_attributes_${index}_${field}`
      el.dataset.entryFormName = null
    })

    this.linesTarget.appendChild(row)
    this.updateTotals()
  }

  removeLine(event) {
    event.preventDefault()
    const row = event.currentTarget.closest("[data-entry-form-target='line']")
    if (this.lineElements.length > 1) {
      row.remove()
      this.updateTotals()
    }
  }

  updateTotals() {
    let debits = 0
    let credits = 0

    this.lineElements.forEach((row) => {
      const dir = row.querySelector("[data-entry-form-role='direction']")?.value
      const amt = parseFloat(row.querySelector("[data-entry-form-role='amount']")?.value || "0")
      if (isNaN(amt)) return
      if (dir === "debit") debits += amt
      else credits += amt
    })

    if (this.hasDebitTotalTarget) this.debitTotalTarget.textContent = this.formatMoney(debits)
    if (this.hasCreditTotalTarget) this.creditTotalTarget.textContent = this.formatMoney(credits)

    const diff = debits - credits
    if (this.hasDifferenceTarget) {
      this.differenceTarget.textContent = this.formatMoney(Math.abs(diff))
      this.differenceTarget.classList.toggle("text-danger", diff !== 0)
      this.differenceTarget.classList.toggle("text-positive", diff === 0)
    }
  }

  disableSubmit() {
    this.element.querySelector("input[type='submit']").disabled = true
  }
}
