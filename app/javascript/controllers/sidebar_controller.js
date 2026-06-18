import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rail", "contextNav", "contextNavContent", "contextTitle", "backdrop", "mobileSidebar"]

  connect() {
    this._applyTheme()
    this._restoreMinimizedState()
    this._setContextTitle()
    this._showActiveSection()
  }

  _applyTheme() {
    const theme = localStorage.getItem("theme")
    if (theme === "dark" || (!theme && window.matchMedia("(prefers-color-scheme: dark)").matches)) {
      document.documentElement.classList.add("dark")
    }
  }

  _restoreMinimizedState() {
    const saved = localStorage.getItem("sidebar_minimized")
    if (saved === "true") {
      this.element.dataset.sidebarMinimizedValue = "true"
      this._applyMinimizedState(true)
    }
  }

  _setContextTitle() {
    const path = window.location.pathname
    let title = "Dashboard"
    let section = "members"

    if (path.startsWith("/deposits")) {
      title = "Deposits"
      section = "deposits"
    } else if (path.startsWith("/loans")) {
      title = "Loans"
      section = "loans"
    } else if (path.startsWith("/equity")) {
      title = "Equity"
      section = "equity"
    } else if (path.startsWith("/members") || path.startsWith("/applications")) {
      title = "Members"
      section = "members"
    } else if (path.startsWith("/treasury")) {
      title = "Treasury"
      section = "treasury"
    } else if (path.startsWith("/accounting")) {
      title = "Accounting"
      section = "accounting"
    } else if (path.includes("/reports") || path === "/dashboard/reports") {
      title = "Reports"
      section = "reports"
    } else if (path.startsWith("/management")) {
      title = "Management"
      section = "management"
    } else if (path === "/dashboard") {
      title = "Dashboard"
      section = "members"
    }

    if (this.hasContextTitleTarget) {
      this.contextTitleTarget.textContent = title
    }

    return section
  }

  _showActiveSection() {
    const activeSection = this._setContextTitle()
    const sections = this.element.querySelectorAll("[data-rail-section]")
    sections.forEach(section => {
      if (section.dataset.railSection === activeSection) {
        section.classList.remove("hidden")
      } else {
        section.classList.add("hidden")
      }
    })
  }

  _applyMinimizedState(isMinimized) {
    const minimizeIcon = this.element.querySelector("[data-sidebar-icon-minimize]")
    const maximizeIcon = this.element.querySelector("[data-sidebar-icon-maximize]")

    if (minimizeIcon && maximizeIcon) {
      minimizeIcon.classList.toggle("hidden", isMinimized)
      maximizeIcon.classList.toggle("hidden", !isMinimized)
    }

    const contextNav = this.element.querySelector("[data-sidebar-target='contextNav']")
    if (contextNav) {
      if (isMinimized) {
        contextNav.style.width = "0"
        contextNav.style.minWidth = "0"
        contextNav.style.opacity = "0"
      } else {
        contextNav.style.width = ""
        contextNav.style.minWidth = ""
        contextNav.style.opacity = "1"
      }
    }
  }

  minimize() {
    const isMinimized = this.element.dataset.sidebarMinimizedValue === "true"
    const newState = !isMinimized
    this.element.dataset.sidebarMinimizedValue = newState.toString()
    localStorage.setItem("sidebar_minimized", newState.toString())
    this._applyMinimizedState(newState)
  }

  selectRail(event) {
    const railId = event.currentTarget.dataset.railId
    if (!railId) return

    const routes = {
      deposits: "/deposits/savings",
      loans: "/loans/applications",
      equity: "/equity/capital",
      members: "/members",
      treasury: "/treasury/cash_sessions",
      accounting: "/accounting/entries",
      reports: "/dashboard/reports",
      management: "/management/dashboard"
    }

    const titles = {
      deposits: "Deposits",
      loans: "Loans",
      equity: "Equity",
      members: "Members",
      treasury: "Treasury",
      accounting: "Accounting",
      reports: "Reports",
      management: "Management"
    }

    const route = routes[railId]
    if (route) {
      Turbo.visit(route)
    }

    if (this.hasContextTitleTarget) {
      this.contextTitleTarget.textContent = titles[railId] || "Dashboard"
    }

    this._showSection(railId)
  }

  _showSection(sectionId) {
    const sections = this.element.querySelectorAll("[data-rail-section]")
    sections.forEach(section => {
      if (section.dataset.railSection === sectionId) {
        section.classList.remove("hidden")
      } else {
        section.classList.add("hidden")
      }
    })
  }

  toggleMobile() {
    const mobile = this.mobileSidebarTarget
    const backdrop = this.backdropTarget

    if (!mobile || !backdrop) return

    const isOpen = !mobile.classList.contains("-translate-x-full")

    if (isOpen) {
      this._closeMobile()
    } else {
      mobile.classList.remove("-translate-x-full")
      backdrop.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }
  }

  closeMobile() {
    const mobile = this.mobileSidebarTarget
    const backdrop = this.backdropTarget

    if (mobile) {
      mobile.classList.add("-translate-x-full")
    }
    if (backdrop) {
      backdrop.classList.add("hidden")
    }
    document.body.classList.remove("overflow-hidden")
  }

  toggleDarkMode() {
    document.documentElement.classList.toggle("dark")
    const isDark = document.documentElement.classList.contains("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
  }

  closeKeydown(event) {
    if (event.code === "Escape") {
      this.closeMobile()
    }
  }

  updateContextTitle(event) {
    if (this.hasContextTitleTarget) {
      this.contextTitleTarget.textContent = event.detail.title || "Dashboard"
    }
  }
}