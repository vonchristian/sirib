import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["input", "hidden", "results"]

  connect() {
    this.selected = null
  }

  search() {
    const query = this.inputTarget.value.trim()

    if (query.length < 1) {
      this.resultsTarget.innerHTML = ""
      this.resultsTarget.classList.add("hidden")
      return
    }

    this.selected = null
    this.hiddenTarget.value = ""

    fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, { credentials: "same-origin" })
      .then(r => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`)
        return r.text()
      })
      .then(html => {
        this.resultsTarget.innerHTML = html
        this.resultsTarget.classList.remove("hidden")
      })
      .catch(e => console.error("typeahead search failed:", e))
  }

  select(event) {
    const btn = event.currentTarget
    const id = btn.dataset.accountId
    const text = btn.textContent.trim()

    this.selected = id
    this.hiddenTarget.value = id
    this.inputTarget.value = text
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.classList.add("hidden")
  }

  hideResultsDelayed(event) {
    setTimeout(() => {
      this.resultsTarget.classList.add("hidden")
    }, 200)
  }

  showIfResults() {
    if (this.resultsTarget.children.length > 0) {
      this.resultsTarget.classList.remove("hidden")
    }
  }
}
