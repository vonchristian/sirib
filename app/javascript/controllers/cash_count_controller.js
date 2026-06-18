import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ["count", "subtotal", "total", "variance"];
  static values = {
    expectedTotal: Number,
    currency: String,
    sessionId: Number
  }

  connect() {
    this.calculateTotals();
  }

  calculateTotals() {
    let total = 0;

    this.countTargets.forEach((input, index) => {
      const count = parseInt(input.value) || 0;
      const amount = parseInt(input.dataset.amount) || 0;
      const subtotal = count * amount;

      if (this.subtotalTargets[index]) {
        this.subtotalTargets[index].textContent = this.formatCurrency(subtotal);
      }
      total += subtotal;
    });

    if (this.totalTarget) {
      this.totalTarget.textContent = this.formatCurrency(total);
    }

    const variance = total - this.expectedTotalValue;
    if (this.varianceTarget) {
      this.varianceTarget.textContent = this.formatCurrency(variance);

      this.varianceTarget.classList.remove("text-green-600", "text-red-600", "text-gray-500");
      if (variance > 0) {
        this.varianceTarget.classList.add("text-green-600");
      } else if (variance < 0) {
        this.varianceTarget.classList.add("text-red-600");
      } else {
        this.varianceTarget.classList.add("text-gray-500");
      }
    }
  }

  validateAndSubmit(event) {
    const total = this.getTotal();
    const variance = total - this.expectedTotalValue;

    if (Math.abs(variance) > 100) {
      event.preventDefault();
      alert(`Variance of ${this.formatCurrency(variance)} detected. Please verify your counts.`);
    }
  }

  getTotal() {
    let total = 0;

    this.countTargets.forEach((input) => {
      const count = parseInt(input.value) || 0;
      const amount = parseInt(input.dataset.amount) || 0;
      total += count * amount;
    });

    return total;
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-PH', {
      style: 'currency',
      currency: this.currencyValue
    }).format(amount / 100);
  }
}
