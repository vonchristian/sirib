import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.contentTargets.forEach((el, i) => {
      const button = el.previousElementSibling
      if (i !== 0) {
        el.hidden = true
        if (button) button.setAttribute("aria-expanded", "false")
      } else {
        if (button) button.setAttribute("aria-expanded", "true")
      }
    })
  }

  toggle(event) {
    const header = event.currentTarget
    const content = header.nextElementSibling
    const icon = header.querySelector("[data-accordion-icon]")
    const isOpen = !content.hidden

    this.contentTargets.forEach((el) => {
      el.hidden = true
      const itemIcon = el.previousElementSibling?.querySelector("[data-accordion-icon]")
      if (itemIcon) itemIcon.style.transform = "rotate(0deg)"
      const btn = el.previousElementSibling
      if (btn) btn.setAttribute("aria-expanded", "false")
    })

    if (!isOpen) {
      content.hidden = false
      if (icon) icon.style.transform = "rotate(180deg)"
      header.setAttribute("aria-expanded", "true")
    }
  }
}
