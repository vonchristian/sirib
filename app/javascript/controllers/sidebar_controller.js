import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop", "userMenu"]

  connect() {
    this.open = false
    this._applyTheme()
  }

  _applyTheme() {
    const theme = localStorage.getItem("theme")
    if (theme === "dark" || (!theme && window.matchMedia("(prefers-color-scheme: dark)").matches)) {
      document.documentElement.classList.add("dark")
    }
  }

  toggle() {
    if (this.open) {
      this.close()
    } else {
      this.openSidebar()
    }
  }

  openSidebar() {
    this.open = true
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.open = false
    this.sidebarTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeKeydown(event) {
    if (event.code === "Escape") {
      if (this.open) this.close()
      this.userMenuTargets.forEach(m => m.classList.add("hidden"))
    }
  }

  toggleUserMenu(event) {
    const button = event.currentTarget
    const menu = button.parentElement.querySelector('[data-sidebar-target="userMenu"]')
    if (menu) menu.classList.toggle("hidden")
  }

  hideUserMenu(event) {
    this.userMenuTargets.forEach(menu => {
      if (menu.classList.contains("hidden")) return
      const container = menu.closest("[data-user-menu-container], [data-user-menu-container-mobile]")
      if (!container?.contains(event.target)) {
        menu.classList.add("hidden")
      }
    })
  }

  toggleDarkMode() {
    document.documentElement.classList.toggle("dark")
    const isDark = document.documentElement.classList.contains("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
  }
}
