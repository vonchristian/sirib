import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchInput", "searchResults", "accountTable"]
  static values = { searchUrl: String, accountsUrl: String }

  connect() {
    this.searchTimeout = null
  }

  search(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()

    if (query.length < 2) {
      this.searchResultsTarget.classList.add("hidden")
      return
    }

    this.searchTimeout = setTimeout(() => {
      this._performSearch(query)
    }, 200)
  }

  _performSearch(query) {
    const url = `${this.searchUrlValue}?q=${encodeURIComponent(query)}`
    fetch(url, {
      headers: { "Accept": "text/html" }
    })
      .then(response => response.text())
      .then(html => {
        this.searchResultsTarget.innerHTML = html
        this.searchResultsTarget.classList.remove("hidden")
      })
  }

  handleSearchKeydown(event) {
    if (event.key === "Escape") {
      this.searchResultsTarget.classList.add("hidden")
      this.searchInputTarget.blur()
    }
  }

  navigateToAccount(event) {
    if (event.target.closest("a")) return
    const row = event.currentTarget
    const href = row.dataset.href
    if (href) {
      Turbo.visit(href)
    }
  }

  navigateOnEnter(event) {
    if (event.key === "Enter") {
      this.navigateToAccount(event)
    }
  }

  ignore(event) {
    event.stopPropagation()
  }

  filter(event) {
    const formData = new FormData()
    const selects = this.element.querySelectorAll("select[name], input[type='checkbox']")
    selects.forEach(el => {
      if (el.type === "checkbox") {
        if (el.checked) formData.append(el.name, el.value)
      } else {
        if (el.value) formData.append(el.name, el.value)
      }
    })

    const params = new URLSearchParams(formData).toString()
    const url = `${this.accountsUrlValue}?${params}`

    history.replaceState({}, "", `?${params}`)

    fetch(url, {
      headers: { "Accept": "text/html" }
    })
      .then(response => response.text())
      .then(html => {
        this.accountTableTarget.innerHTML = html
      })
  }

  clearFilters() {
    this.element.querySelectorAll("select[name]").forEach(el => el.value = "")
    this.element.querySelectorAll("input[type='checkbox']").forEach(el => el.checked = false)
    history.replaceState({}, "", this.accountsUrlValue)
    fetch(this.accountsUrlValue, {
      headers: { "Accept": "text/html" }
    })
      .then(response => response.text())
      .then(html => {
        this.accountTableTarget.innerHTML = html
      })
  }

  selectAccountFromSearch(event) {
    const accountId = event.currentTarget.dataset.accountId
    const url = `/accounting/accounts/${accountId}`
    this.searchResultsTarget.classList.add("hidden")
    this.searchInputTarget.value = ""
    Turbo.visit(url)
  }

  selectLedgerFromSearch(event) {
    const ledgerId = event.currentTarget.dataset.ledgerId
    this.searchResultsTarget.classList.add("hidden")
    this.searchInputTarget.value = ""
    const url = `${this.accountsUrlValue}?ledger_id=${ledgerId}`
    history.replaceState({}, "", `?ledger_id=${ledgerId}`)
    fetch(url, {
      headers: { "Accept": "text/html" }
    })
      .then(response => response.text())
      .then(html => {
        this.accountTableTarget.innerHTML = html
      })
  }
}
