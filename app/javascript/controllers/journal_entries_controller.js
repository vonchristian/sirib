import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entriesList", "searchBox"]

  connect() {
  }

  showEntry(event) {
    const row = event.currentTarget
    const href = row.dataset.href

    if (href) {
      const entryId = row.dataset.entryId
      const detailFrame = document.getElementById('entry_detail')

      if (detailFrame) {
        detailFrame.src = `/accounting/journal_entries/${entryId}?format=turbo_stream`
      } else {
        Turbo.visit(href)
      }
    }
  }

  clearDetail() {
    const detailFrame = document.getElementById('entry_detail')
    if (detailFrame) {
      detailFrame.innerHTML = ''
    }
  }
}