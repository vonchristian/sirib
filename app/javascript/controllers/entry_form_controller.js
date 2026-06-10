import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "debitTotal", "creditTotal", "diffTotal", "errorMessage"]

  connect() {
    this.counter = 0
    this.addLine()
    this.addLine()
    this.updateTotals()
  }

  get lineElements() {
    return this.linesTarget.querySelectorAll("[data-entry-form-target='line']")
  }

  get optionsHTML() {
    return this.element.querySelector("#account-options")?.innerHTML || ""
  }

  formatMoney(n) {
    return n.toFixed(2)
  }

  addLine(event) {
    if (event) event.preventDefault()
    const index = this.counter++
    const tpl = document.getElementById("line_template")
    const row = tpl.content.cloneNode(true)

    const select = row.querySelector("[data-entry-form-role='account-select']")
    select.name = `entry[lines][${index}][account_id]`
    select.id = `entry_lines_${index}_account_id`
    select.innerHTML = "<option value=''>Select account...</option>" + this.optionsHTML

    const debit = row.querySelector("[data-entry-form-role='debit']")
    debit.name = `entry[lines][${index}][debit_amount]`
    debit.id = `entry_lines_${index}_debit_amount`

    const credit = row.querySelector("[data-entry-form-role='credit']")
    credit.name = `entry[lines][${index}][credit_amount]`
    credit.id = `entry_lines_${index}_credit_amount`

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
      const debitVal = parseFloat(row.querySelector("[data-entry-form-role='debit']")?.value || "0")
      const creditVal = parseFloat(row.querySelector("[data-entry-form-role='credit']")?.value || "0")
      if (!isNaN(debitVal)) debits += debitVal
      if (!isNaN(creditVal)) credits += creditVal
    })

    if (this.hasDebitTotalTarget) this.debitTotalTarget.textContent = this.formatMoney(debits)
    if (this.hasCreditTotalTarget) this.creditTotalTarget.textContent = this.formatMoney(credits)

    const diff = debits - credits
    if (this.hasDiffTotalTarget) {
      this.diffTotalTarget.textContent = this.formatMoney(Math.abs(diff))
      this.diffTotalTarget.classList.toggle("text-red-600", diff !== 0)
      this.diffTotalTarget.classList.toggle("text-green-600", diff === 0)
    }

    if (this.hasErrorMessageTarget) {
      if (diff !== 0) {
        this.errorMessageTarget.classList.remove("hidden")
      } else {
        this.errorMessageTarget.classList.add("hidden")
      }
    }
  }

  disableSubmit() {
    this.element.querySelector("input[type='submit']").disabled = true
  }
}
