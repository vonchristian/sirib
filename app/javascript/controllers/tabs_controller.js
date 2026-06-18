import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const hash = window.location.hash.replace("#", "")
    if (hash) this._show(hash)

    this._onHashChange = this._onHashChange.bind(this)
    window.addEventListener("hashchange", this._onHashChange)
  }

  disconnect() {
    window.removeEventListener("hashchange", this._onHashChange)
  }

  activate(event) {
    const panelId = event.currentTarget.dataset.tab
    if (panelId) {
      this._show(panelId)
      history.replaceState(null, "", `#${panelId}`)
    }
  }

  _show(panelId) {
    this.tabTargets.forEach(t => {
      t.classList.toggle("border-primary", t.dataset.tab === panelId)
      t.classList.toggle("border-transparent", t.dataset.tab !== panelId)
      t.classList.toggle("text-primary", t.dataset.tab === panelId)
      t.classList.toggle("text-text-tertiary", t.dataset.tab !== panelId)
      t.classList.toggle("hover:text-text-secondary", t.dataset.tab !== panelId)
    })

    this.panelTargets.forEach(p => {
      p.classList.toggle("hidden", p.id !== `tab-${panelId}`)
    })
  }

  _onHashChange() {
    const hash = window.location.hash.replace("#", "")
    if (hash) this._show(hash)
  }
}
