import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab"]

  connect() {
    this.setActiveTab()
    this.boundFrameLoad = this._onFrameLoad.bind(this)
    document.addEventListener("turbo:frame-load", this.boundFrameLoad)
    document.addEventListener("turbo:render", this.boundFrameLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.boundFrameLoad)
    document.removeEventListener("turbo:render", this.boundFrameLoad)
  }

  setActiveTab() {
    const params = new URL(window.location).searchParams
    const activeTab = params.get("tab") || "overview"
    this._activate(activeTab)
  }

  _onFrameLoad(event) {
    if (event.target && event.target.id === "member-tab-content") {
      this.setActiveTab()
    } else if (!event.target) {
      this.setActiveTab()
    }
  }

  _activate(tabId) {
    this.tabTargets.forEach(t => {
      const isActive = t.dataset.tab === tabId
      t.classList.toggle("border-primary", isActive)
      t.classList.toggle("text-primary", isActive)
      t.classList.toggle("border-transparent", !isActive)
      t.classList.toggle("text-text-tertiary", !isActive)
    })
  }
}
