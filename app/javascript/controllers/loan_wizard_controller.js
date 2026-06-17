import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step", "nextBtn", "backBtn", "submitBtn", "counter", "currentStep",
    "stepper", "dotMobile", "amountField", "termField", "rateField",
    "productAutocomplete",
    "calculatorSummary", "calculatorEmpty", "displayAmount",
    "totalCharges", "netProceeds", "monthlyAmort", "chargesList"
  ]
  static values = { currentStep: { type: Number, default: 0 } }

  connect() {
    this.currentStepValue = this.stepFromURL()
    if (this.currentStepValue < 0) {
      const step = parseInt(this.element.dataset.currentStep, 10)
      this.currentStepValue = isNaN(step) ? 0 : Math.min(4, Math.max(0, step))
    }
    this.updateStepper()
    this.updateMobileDots()
    this.syncURL()
    this.showStep()
    this.recalculate()
  }

  next() {
    if (this.validateStep()) {
      if (this.currentStepValue < this.stepTargets.length - 1) {
        this.currentStepValue++
        this.showStep()
      }
    }
  }

  back() {
    if (this.currentStepValue > 0) {
      this.currentStepValue--
      this.showStep()
    }
  }

  showStep() {
    this.stepTargets.forEach((step, index) => {
      const isVisible = index === this.currentStepValue
      step.classList.toggle("hidden", !isVisible)
      step.querySelectorAll("input, select, textarea").forEach((el) => {
        if (el.type !== "hidden") {
          el.disabled = !isVisible
        }
      })
      if (isVisible) {
        step.classList.remove("animate-fade-in-up")
        void step.offsetWidth
        step.classList.add("animate-fade-in-up")
      }
    })

    if (this.hasBackBtnTarget) {
      this.backBtnTarget.classList.toggle("hidden", this.currentStepValue === 0)
    }
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.classList.toggle("hidden", this.currentStepValue === this.stepTargets.length - 1)
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.classList.toggle("hidden", this.currentStepValue !== this.stepTargets.length - 1)
    }

    this.updateStepper()
    this.updateMobileDots()
    this.updateCounter()
    this.syncURL()
    this.updateCurrentStepField()
  }

  updateStepper() {
    if (!this.hasStepperTarget) return
    const current = this.currentStepValue
    this.stepperTarget.querySelectorAll("[data-step-index]").forEach((el) => {
      const idx = parseInt(el.dataset.stepIndex, 10)
      const circle = el.querySelector("[data-step-circle]")
      const number = el.querySelector("[data-step-number]")
      const check = el.querySelector("[data-step-check]")
      const label = el.querySelector("[data-step-label]")
      const connectors = el.querySelectorAll("[data-step-connector]")

      if (circle) {
        if (idx < current) {
          circle.className = "relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-all duration-300 bg-primary border-primary text-white"
          if (number) number.classList.add("hidden")
          if (check) { check.classList.remove("hidden"); check.classList.add("text-white") }
        } else if (idx === current) {
          circle.className = "relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-all duration-300 border-primary text-primary"
          if (number) { number.classList.remove("hidden"); number.classList.add("text-primary") }
          if (check) check.classList.add("hidden")
        } else {
          circle.className = "relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold transition-all duration-300 border-border text-text-tertiary"
          if (number) { number.classList.remove("hidden"); number.classList.add("text-text-tertiary") }
          if (check) check.classList.add("hidden")
        }
      }
      if (label) {
        if (idx === current) {
          label.className = "mt-1.5 text-[11px] font-medium leading-tight text-center truncate max-w-[6rem] transition-colors duration-200 text-primary"
        } else if (idx < current) {
          label.className = "mt-1.5 text-[11px] font-medium leading-tight text-center truncate max-w-[6rem] transition-colors duration-200 text-text-tertiary"
        } else {
          label.className = "mt-1.5 text-[11px] font-medium leading-tight text-center truncate max-w-[6rem] transition-colors duration-200 text-text-tertiary/50"
        }
      }
      connectors.forEach((conn) => {
        conn.className = idx < current
          ? "flex-1 h-px bg-primary transition-colors duration-300"
          : "flex-1 h-px bg-border dark:bg-gray-700 transition-colors duration-300"
      })
    })
  }

  updateMobileDots() {
    if (!this.hasDotMobileTarget) return
    const current = this.currentStepValue
    this.dotMobileTargets.forEach((dot, idx) => {
      dot.className = idx <= current
        ? "flex-1 h-1.5 rounded-full transition-colors duration-300 bg-primary"
        : "flex-1 h-1.5 rounded-full transition-colors duration-300 bg-gray-200 dark:bg-gray-700"
    })
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `Step ${this.currentStepValue + 1} of ${this.stepTargets.length}`
    }
  }

  validateStep() {
    const currentStep = this.stepTargets[this.currentStepValue]
    const requiredFields = currentStep.querySelectorAll("[required]")
    let valid = true

    requiredFields.forEach((field) => {
      field.classList.remove("field-input-error")
      const wrapper = field.closest(".field-group, div")
      const existingError = wrapper?.querySelector(".field-error")
      if (existingError && currentStep.contains(existingError)) existingError.remove()

      let value
      let displayField = field

      if (field.dataset.autocompleteTarget === "hidden") {
        value = field.value
        displayField = wrapper?.querySelector("[data-autocomplete-target='input']") || field
      } else {
        value = field.value.trim()
      }

      if (!value) {
        displayField.classList.add("field-input-error")
        valid = false
        if (wrapper) {
          const msg = document.createElement("p")
          msg.className = "field-error"
          appendErrorIcon(msg)
          msg.appendChild(document.createTextNode(" This field is required"))
          wrapper.appendChild(msg)
        }
      }
    })

    if (!valid) {
      const firstInvalid = currentStep.querySelector(".field-input-error")
      firstInvalid?.focus()
    }
    return valid
  }

  onProductSelected(event) {
    const autocompleteEl = event.target
    const hiddenInput = autocompleteEl && autocompleteEl.querySelector('[data-loan-wizard-target="productAutocomplete"]')
    if (!hiddenInput) return

    const item = event.detail.item
    const rate = item.dataset.productRate
    if (rate && this.hasRateFieldTarget) {
      this.rateFieldTarget.value = rate
    }
    this._currentCharges = JSON.parse(item.dataset.productCharges || "[]")
    this._currentCalculation = item.dataset.productCalculation || "declining_balance"
    this.recalculate()
  }

  recalculate() {
    const amount = parseFloat(this.amountFieldTarget?.value || 0)
    const rate = parseFloat(this.rateFieldTarget?.value || 0)
    const term = parseFloat(this.termFieldTarget?.value || 0)
    const hasData = amount > 0 && !isNaN(amount)

    if (this.hasCalculatorSummaryTarget) {
      this.calculatorSummaryTarget.classList.toggle("hidden", !hasData)
    }
    if (this.hasCalculatorEmptyTarget) {
      this.calculatorEmptyTarget.classList.toggle("hidden", hasData)
    }
    if (!hasData) return

    this.displayAmountTarget.textContent = `PHP ${amount.toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`

    const charges = this._currentCharges || []
    let totalCharges = 0
    let chargesHtml = ""

    charges.forEach((charge) => {
      const computed = charge.charge_type === "percentage" ? amount * charge.value / 100.0 : charge.value
      totalCharges += computed
      chargesHtml +=
        `<div class="flex justify-between text-xs">
          <span class="text-text-tertiary">${charge.name}</span>
          <span class="text-text-secondary">PHP ${computed.toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
        </div>`
    })

    if (chargesHtml) {
      this.chargesListTarget.innerHTML = chargesHtml
    } else {
      this.chargesListTarget.innerHTML =
        `<div class="flex justify-between text-xs text-text-tertiary">
          <span>Charges & Fees</span>
          <span>None</span>
        </div>`
    }

    const netProceeds = Math.max(0, amount - totalCharges)
    this.totalChargesTarget.textContent = `PHP ${totalCharges.toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    this.netProceedsTarget.textContent = `PHP ${netProceeds.toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`

    const monthlyRate = rate / 100.0 / 12
    let monthlyAmort = 0
    if (monthlyRate > 0 && term > 0) {
      if (this._currentCalculation === "straight_line") {
        const monthlyPrincipal = netProceeds / term
        const monthlyInterest = netProceeds * monthlyRate
        monthlyAmort = monthlyPrincipal + monthlyInterest
      } else {
        const r = monthlyRate
        const n = term
        monthlyAmort = netProceeds * r * Math.pow(1 + r, n) / (Math.pow(1 + r, n) - 1)
      }
    }
    this.monthlyAmortTarget.textContent = `PHP ${(monthlyAmort || 0).toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
  }

  addCoMaker() {
    const container = document.getElementById("co-makers")
    const lastEntry = container.querySelector(".co-maker-entry:last-of-type")
    if (lastEntry) {
      const clone = lastEntry.cloneNode(true)
      clone.querySelectorAll("input, select").forEach((el) => { el.value = "" })
      container.appendChild(clone)
    }
  }

  toggleCollateralDetails() {
  }

  addIncome() {
    const container = document.getElementById("income-sources")
    const lastEntry = container.querySelector(".income-entry:last-of-type")
    if (lastEntry) {
      const clone = lastEntry.cloneNode(true)
      clone.querySelectorAll("input, select").forEach((el) => { el.value = "" })
      container.appendChild(clone)
    } else {
      container.insertAdjacentHTML("beforeend", this.incomeTemplate())
    }
  }

  incomeTemplate() {
    return '<div class="rounded-lg border border-border bg-surface-alt dark:border-gray-700 dark:bg-gray-800/50 p-4 income-entry">' +
      '<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">' +
        '<div class="field-group">' +
          '<label class="field-label">Source Type</label>' +
          '<select name="lending_loan_application[sources_of_income][][source_type]" required class="field-input">' +
            '<option value="">Select type</option>' +
            '<option value="Employment">Employment</option>' +
            '<option value="Self-Employed">Self-Employed</option>' +
            '<option value="Business">Business</option>' +
            '<option value="Remittances">Remittances</option>' +
            '<option value="Pension">Pension</option>' +
            '<option value="Investment">Investment</option>' +
            '<option value="Others">Others</option>' +
          '</select>' +
        '</div>' +
        '<div class="field-group">' +
          '<label class="field-label">Monthly Income (PHP)</label>' +
          '<input type="number" name="lending_loan_application[sources_of_income][][monthly_income]" value="" required min="0" step="0.01" placeholder="0.00" class="field-input">' +
        '</div>' +
      '</div>' +
    '</div>'
  }

  stepFromURL() {
    const names = ["loan_details", "sources_of_income", "co_makers", "collaterals", "repayment_schedule"]
    const name = new URL(window.location).searchParams.get("step")
    return name ? names.indexOf(name) : -1
  }

  syncURL() {
    const names = ["loan_details", "sources_of_income", "co_makers", "collaterals", "repayment_schedule"]
    const name = names[this.currentStepValue]
    const url = new URL(window.location)
    if (url.searchParams.get("step") !== name) {
      url.searchParams.set("step", name)
      history.replaceState({ step: this.currentStepValue }, "", url.toString())
    }
  }

  updateCurrentStepField() {
    if (this.hasCurrentStepTarget) {
      this.currentStepTarget.value = this.currentStepValue
    }
  }
}

function appendErrorIcon(msg) {
  const icon = document.createElementNS("http://www.w3.org/2000/svg", "svg")
  icon.setAttribute("viewBox", "0 0 24 24")
  icon.setAttribute("fill", "none")
  icon.setAttribute("stroke", "currentColor")
  icon.setAttribute("stroke-width", "1.5")
  icon.style.width = "1em"
  icon.style.height = "1em"
  icon.style.flexShrink = "0"
  const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
  path.setAttribute("stroke-linecap", "round")
  path.setAttribute("stroke-linejoin", "round")
  path.setAttribute("d", "M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z")
  icon.appendChild(path)
  msg.appendChild(icon)
}
