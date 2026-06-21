import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "startDate", "endDate", "savePanel"]

  connect() {
    this.timeout = null
  }

  reset() {
    this.startDateTarget.value = new Date(new Date().setMonth(new Date().getMonth() - 1)).toISOString().split('T')[0]
    this.endDateTarget.value = new Date().toISOString().split('T')[0]

    const form = this.formTarget
    form.querySelectorAll('select').forEach(select => select.value = '')
    form.querySelectorAll('input[type="checkbox"]').forEach(cb => cb.checked = false)
    form.querySelectorAll('input[type="number"]').forEach(input => input.value = '')
    form.querySelector('input[name="reference_number"]').value = ''

    setTimeout(() => this.formTarget.requestSubmit(), 50)
  }

  toggleSavePanel() {
    this.savePanelTarget.classList.toggle('hidden')
  }

  saveFilter() {
    const form = this.formTarget
    const nameInput = this.savePanelTarget.querySelector('input[name="filter_name"]')
    const isShared = this.savePanelTarget.querySelector('input[name="is_shared"]').checked

    if (!nameInput.value.trim()) {
      nameInput.focus()
      return
    }

    const filterData = new FormData(form)
    const params = new URLSearchParams()
    params.set('name', nameInput.value.trim())
    params.set('is_shared', isShared.toString())

    filterData.forEach((value, key) => {
      if (value && key !== 'filter_name' && key !== 'is_shared') {
        params.set(key, value)
      }
    })

    fetch('/accounting/journal_entries/save_filter', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: params.toString()
    })
      .then(response => {
        if (response.ok) {
          window.location.reload()
        }
      })
  }

  submitDelayed() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 400)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}