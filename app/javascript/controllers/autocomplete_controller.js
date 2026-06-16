import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "results", "selected"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.selected = false
    this.closeOnClickOutside = this.close.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  search() {
    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) {
      this.resultsTarget.classList.add("hidden")
      this.resultsTarget.innerHTML = ""
      return
    }

    this.selected = false
    fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "text/html" }
    })
      .then(r => r.text())
      .then(html => {
        this.resultsTarget.innerHTML = html
        this.resultsTarget.classList.remove("hidden")
      })
      .catch(() => {})
  }

  select(event) {
    const item = event.currentTarget
    const id = item.dataset.autocompleteId
    const label = item.dataset.autocompleteLabel

    this.hiddenTarget.value = id
    this.inputTarget.value = label
    this.selected = true
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""

    this.dispatch("selected", { detail: { id, label, item } })
  }

  clear() {
    this.hiddenTarget.value = ""
    this.inputTarget.value = ""
    this.selected = false
  }

  close(event) {
    if (event && !this.element.contains(event.target)) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  keyboard(event) {
    const items = this.resultsTarget.querySelectorAll("[data-autocomplete-id]")
    if (items.length === 0) return

    let index = Array.from(items).findIndex(el => el.classList.contains("bg-primary-50"))

    if (event.key === "ArrowDown") {
      event.preventDefault()
      index = Math.min(index + 1, items.length - 1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      index = Math.max(index - 1, 0)
    } else if (event.key === "Enter") {
      event.preventDefault()
      if (index >= 0) items[index].click()
      return
    } else if (event.key === "Escape") {
      this.resultsTarget.classList.add("hidden")
      return
    }

    items.forEach((el, i) => {
      el.classList.toggle("bg-primary-50", i === index)
    })
  }
}
