import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  activate(event) {
    const tab = event.currentTarget
    const panelId = tab.dataset.tab

    this.tabTargets.forEach(t => {
      t.classList.remove("border-primary", "text-primary")
      t.classList.add("border-transparent", "text-text-tertiary", "hover:text-text-secondary")
    })

    tab.classList.remove("border-transparent", "text-text-tertiary", "hover:text-text-secondary")
    tab.classList.add("border-primary", "text-primary")

    this.panelTargets.forEach(p => p.classList.add("hidden"))
    const panel = this.element.querySelector(`#tab-${panelId}`)
    if (panel) panel.classList.remove("hidden")
  }
}
