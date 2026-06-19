import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "tbody"]

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this._performSearch(), 250)
  }

  navigate(event) {
    const row = event.currentTarget.closest("[data-href]")
    if (row) {
      window.location.href = row.dataset.href
    }
  }

  _performSearch() {
    const query = this.inputTarget.value.trim()
    const url = new URL(window.location.href, window.location.origin)
    url.searchParams.set("q", query)

    fetch(url.toString(), {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
      .then(r => r.text())
      .then(html => {
        if (html) {
          Turbo.renderStreamMessage(html)
        }
      })
      .catch(() => {})
  }
}