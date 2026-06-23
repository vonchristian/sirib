import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entry", "sentinel", "end"]

  connect() {
    if (this.hasSentinelTarget) {
      this.observer = new IntersectionObserver(
        (entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              this.loadMore()
            }
          })
        },
        { rootMargin: "200px" }
      )
      this.observer.observe(this.sentinelTarget)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  loadMore() {
    if (this.loading) return
    this.loading = true

    const nextPage = this.sentinelTarget.dataset.nextPage
    const accountId = this.sentinelTarget.dataset.accountId
    const url = `/accounting/accounts/audit_entries?id=${accountId}&audit_page=${nextPage}`

    fetch(url)
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const newEntries = doc.querySelectorAll("[data-audit-timeline-target='entry']")
        const newSentinel = doc.querySelector("[data-audit-timeline-target='sentinel']")
        const endMarker = doc.querySelector("[data-audit-timeline-target='end']")

        newEntries.forEach(el => this.sentinelTarget.parentElement.insertBefore(el, this.sentinelTarget))

        if (newSentinel) {
          this.sentinelTarget.replaceWith(newSentinel)
        } else if (endMarker) {
          this.sentinelTarget.replaceWith(endMarker)
          this.sentinelTarget.remove()
        }
        this.loading = false
      })
      .catch(() => {
        this.loading = false
      })
  }
}