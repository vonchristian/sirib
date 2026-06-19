import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "messages", "input", "submitBtn", "emptyState", "suggestions", "suggestionList", "insights", "insightList", "floatingToggle", "closeBtn"]

  connect() {
    this.open = localStorage.getItem("ai_sidebar_open") !== "false"
    this.csrfToken = document.querySelector("[name='csrf-token']")?.content
    if (this.open) {
      this.sidebarTarget.style.width = "24rem"
      this.sidebarTarget.style.minWidth = "24rem"
      this.sidebarTarget.style.opacity = "1"
    } else {
      this.sidebarTarget.style.width = "0"
      this.sidebarTarget.style.minWidth = "0"
      this.sidebarTarget.style.opacity = "0"
    }
    requestAnimationFrame(() => { this.sidebarTarget.style.transition = "all 300ms" })
  }

  toggle() {
    this.open = !this.open
    localStorage.setItem("ai_sidebar_open", this.open.toString())
    if (this.open) {
      this.sidebarTarget.style.width = "24rem"
      this.sidebarTarget.style.minWidth = "24rem"
      this.sidebarTarget.style.opacity = "1"
    } else {
      this.sidebarTarget.style.width = "0"
      this.sidebarTarget.style.minWidth = "0"
      this.sidebarTarget.style.opacity = "0"
    }
  }

  openSidebar() {
    this.open = true
    localStorage.setItem("ai_sidebar_open", "true")
    this.sidebarTarget.style.width = "24rem"
    this.sidebarTarget.style.minWidth = "24rem"
    this.sidebarTarget.style.opacity = "1"
  }

  closeSidebar() {
    this.open = false
    localStorage.setItem("ai_sidebar_open", "false")
    this.sidebarTarget.style.width = "0"
    this.sidebarTarget.style.minWidth = "0"
    this.sidebarTarget.style.opacity = "0"
  }

  async send(event) {
    event.preventDefault()
    const message = this.inputTarget.value.trim()
    if (!message) return

    this._addMessage("user", message)
    this.inputTarget.value = ""
    this.submitBtnTarget.disabled = true

    try {
      const response = await this._fetchAI(message)
      this._handleResponse(response)
    } catch (error) {
      this._addMessage("ai", "Sorry, I encountered an error. Please try again.")
    } finally {
      this.submitBtnTarget.disabled = false
    }
  }

  async suggestAction(event) {
    const button = event.currentTarget
    const action = button.dataset.action
    const payload = JSON.parse(button.dataset.payload || "{}")

    this._addMessage("user", `Action: ${button.textContent.trim()}`)

    try {
      const response = await this._executeAction(action, payload)
      this._handleActionResponse(response)
    } catch (error) {
      this._addMessage("ai", "Failed to execute action. Please try again.")
    }
  }

  _addMessage(role, text) {
    this.emptyStateTarget.classList.add("hidden")

    const div = document.createElement("div")
    div.className = `flex gap-3 ${role === "user" ? "justify-end" : ""}`

    const bubble = document.createElement("div")
    bubble.className = role === "user"
      ? "rounded-lg bg-primary text-white px-3.5 py-2.5 text-sm max-w-[85%]"
      : "rounded-lg bg-surface-alt border border-border px-3.5 py-2.5 text-sm max-w-[85%]"

    bubble.textContent = text
    div.appendChild(bubble)
    this.messagesTarget.appendChild(div)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  _addSuggestion(label, action, payload = {}) {
    this.suggestionsTarget.classList.remove("hidden")

    const button = document.createElement("button")
    button.type = "button"
    button.dataset.action = action
    button.dataset.payload = JSON.stringify(payload)
    button.dataset.action = "click->ai-sidebar#suggestAction"
    button.className = "w-full text-left rounded-md border border-border bg-surface px-3 py-2 text-sm text-text-primary hover:bg-surface-alt transition-colors"
    button.textContent = label
    this.suggestionListTarget.appendChild(button)
  }

  _addInsight(type, text, severity = "low") {
    this.insightsTarget.classList.remove("hidden")

    const colors = {
      warning: "border-warning/30 bg-warning-50 text-warning",
      danger: "border-danger/30 bg-danger-50 text-danger",
      info: "border-primary/30 bg-primary-50 text-primary-700"
    }

    const div = document.createElement("div")
    div.className = `rounded-md border px-3 py-2 text-xs ${colors[type] || colors.info}`
    div.textContent = text
    this.insightListTarget.appendChild(div)
  }

  async _fetchAI(message) {
    const formData = new FormData()
    formData.append("message", message)

    const response = await fetch("/shell/ai_chat", {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
        "Accept": "application/json"
      },
      body: formData
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || "Request failed")
    }

    return response.json()
  }

  async _executeAction(action, payload) {
    const formData = new FormData()
    formData.append("action_type", action)
    formData.append("payload", JSON.stringify(payload))

    const response = await fetch("/shell/ai_suggested_action", {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfToken,
        "Accept": "application/json"
      },
      body: formData
    })

    if (!response.ok) throw new Error("Action execution failed")
    return response.json()
  }

  _handleResponse(response) {
    if (response.type === "error") {
      this._addMessage("ai", response.message || "An error occurred")
      return
    }

    this._addMessage("ai", response.message)

    if (response.suggestions?.length) {
      response.suggestions.forEach(s => {
        this._addSuggestion(s.label, s.action, s.payload)
      })
    }

    if (response.insights?.length) {
      response.insights.forEach(i => {
        this._addInsight(i.type, i.text, i.severity)
      })
    }
  }

  _handleActionResponse(response) {
    if (response.type === "confirmation") {
      if (confirm(response.message)) {
        this._executeAction(response.action, response.payload)
          .then(r => this._addMessage("ai", r.message || "Action executed"))
          .catch(e => this._addMessage("ai", "Action failed"))
      }
    } else if (response.type === "error") {
      this._addMessage("ai", response.error || "Action failed")
    } else {
      this._addMessage("ai", response.message || "Action completed")
    }
  }
}