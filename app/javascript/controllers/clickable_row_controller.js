import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundClick = this._onClick.bind(this)
    this.boundKeydown = this._onKeydown.bind(this)
    this.element.addEventListener("click", this.boundClick)
    this.element.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundClick)
    this.element.removeEventListener("keydown", this.boundKeydown)
  }

  _onClick(event) {
    const row = event.target.closest("[data-clickable-row-target='row']")
    if (!row) return
    if (event.target.closest("a, button, input, select, textarea")) return
    this._navigate(row)
  }

  _onKeydown(event) {
    if (event.key !== "Enter") return
    const row = event.target.closest("[data-clickable-row-target='row']")
    if (row) this._navigate(row)
  }

  _navigate(row) {
    const href = row.dataset.href
    if (!href) return
    window.location.href = href
  }
}
