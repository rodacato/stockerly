import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "symbol", "name", "assetType", "exchange", "country", "sector"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.selectedIndex = -1
    this.clickOutsideHandler = this.clickOutside.bind(this)
    document.addEventListener("click", this.clickOutsideHandler)
  }

  disconnect() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    document.removeEventListener("click", this.clickOutsideHandler)
  }

  search() {
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.hideResults()
      return
    }

    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.performSearch(query), 300)
  }

  async performSearch(query) {
    try {
      this.showLoading()
      const response = await window.fetch(
        `${this.urlValue}?q=${encodeURIComponent(query)}`,
        { headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" } }
      )

      if (response.ok) {
        const results = await response.json()
        this.renderResults(results)
      } else {
        this.showError()
      }
    } catch (_error) {
      this.showError()
    }
  }

  renderResults(results) {
    if (results.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-slate-400 text-center">No results found</div>`
      this.showResults()
      return
    }

    const typeColors = {
      stock: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
      etf: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400",
      crypto: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
      index: "bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400"
    }

    this.resultsTarget.innerHTML = results.map((r, i) => `
      <button type="button"
        data-action="ticker-search#select"
        data-index="${i}"
        data-symbol="${this.escapeAttr(r.symbol)}"
        data-name="${this.escapeAttr(r.name)}"
        data-asset-type="${r.asset_type}"
        data-exchange="${this.escapeAttr(r.exchange || '')}"
        data-country="${this.escapeAttr(r.country || '')}"
        class="w-full flex items-center gap-3 px-4 py-2.5 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors text-left cursor-pointer">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <span class="font-semibold text-sm text-slate-900 dark:text-white">${this.escapeHtml(r.symbol)}</span>
            <span class="text-[10px] font-bold px-1.5 py-0.5 rounded ${typeColors[r.asset_type] || typeColors.stock}">${r.asset_type.toUpperCase()}</span>
          </div>
          <p class="text-xs text-slate-500 truncate">${this.escapeHtml(r.name)}</p>
        </div>
        <span class="text-xs text-slate-400 shrink-0">${this.escapeHtml(r.exchange || '')}</span>
      </button>
    `).join("")

    this.selectedIndex = -1
    this.showResults()
  }

  select(event) {
    const btn = event.currentTarget
    this.symbolTarget.value = btn.dataset.symbol
    this.nameTarget.value = btn.dataset.name
    this.assetTypeTarget.value = btn.dataset.assetType
    this.exchangeTarget.value = btn.dataset.exchange
    this.countryTarget.value = btn.dataset.country

    this.inputTarget.value = `${btn.dataset.symbol} — ${btn.dataset.name}`
    this.hideResults()
  }

  navigate(event) {
    const items = this.resultsTarget.querySelectorAll("button[data-action]")
    if (items.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
      this.highlightItem(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
      this.highlightItem(items)
    } else if (event.key === "Enter" && this.selectedIndex >= 0) {
      event.preventDefault()
      items[this.selectedIndex].click()
    } else if (event.key === "Escape") {
      this.hideResults()
    }
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      item.classList.toggle("bg-primary/10", index === this.selectedIndex)
    })
    if (this.selectedIndex >= 0) {
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
    this.selectedIndex = -1
  }

  showLoading() {
    this.resultsTarget.innerHTML = `
      <div class="px-4 py-3 text-sm text-slate-400 text-center">Searching...</div>`
    this.showResults()
  }

  showError() {
    this.resultsTarget.innerHTML = `
      <div class="px-4 py-3 text-sm text-red-400 text-center">Search unavailable. Fill fields manually.</div>`
    this.showResults()
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  escapeAttr(text) {
    return text.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}
