import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "results", "selected"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.selected = false
    this.closeOnOutsideClick = this.close.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
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
    const thumb = item.dataset.autocompleteThumb

    this.hiddenTarget.value = id
    this.inputTarget.value = label
    this.selected = true
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""

    this.inputTarget.parentElement.classList.add("hidden")
    this.selectedTarget.classList.remove("hidden")
    this.selectedTarget.querySelector("[data-member-name]").textContent = label
    const img = this.selectedTarget.querySelector("img")
    const initial = this.selectedTarget.querySelector("[data-member-initial]")
    if (thumb) {
      img.classList.remove("hidden")
      initial.classList.add("hidden")
      img.src = thumb
    } else {
      img.classList.add("hidden")
      initial.classList.remove("hidden")
      initial.textContent = label.charAt(0).toUpperCase()
    }

    this.dispatch("selected", { detail: { id, label } })
  }

  clear() {
    this.hiddenTarget.value = ""
    this.inputTarget.value = ""
    this.selected = false
    this.selectedTarget.classList.add("hidden")
    this.inputTarget.parentElement.classList.remove("hidden")
    this.inputTarget.focus()
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
