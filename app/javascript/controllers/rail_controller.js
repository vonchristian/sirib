import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["workspacePanel", "contextTitle"]

  connect() {
    this.workspaceNames = {
      dashboard: "Dashboard",
      members: "Members",
      loans: "Loans & Payments",
      equity: "Share Capital",
      treasury: "Treasury",
      accounting: "Accounting",
      management: "Management",
      reports: "Reports",
      settings: "Settings"
    }
  }

  select(event) {
    const workspace = event.params.workspace
    const landing = event.params.landing
    this._switchTo(workspace)
    if (landing) {
      Turbo.visit(landing)
    }
  }

  _switchTo(workspace) {
    if (!workspace) return

    if (this.hasContextTitleTarget) {
      const name = this.workspaceNames[workspace] || workspace
      this.contextTitleTarget.textContent = name
    }

    this.workspacePanelTargets.forEach(panel => {
      const isMatch = panel.dataset.railWorkspace === workspace
      panel.classList.toggle("hidden", !isMatch)
    })
  }
}