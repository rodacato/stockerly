import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["overlay", "modal", "input", "results", "assetResults", "group"]
  static values = { url: String }

  connect() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.keydownHandler)
    this.debounceTimer = null
    this.selectedIndex = -1
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydownHandler)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.modalTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
    this.selectedIndex = -1
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.modalTarget.classList.add("hidden")
    this.inputTarget.value = ""
    this.selectedIndex = -1
    if (this.hasAssetResultsTarget) {
      this.assetResultsTarget.innerHTML = '<p class="px-3 py-4 text-sm text-slate-400 text-center">Type to search stocks, crypto, indices...</p>'
    }
  }

  toggle() {
    const isHidden = this.modalTarget.classList.contains("hidden")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  fetch() {
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      if (this.hasAssetResultsTarget) {
        this.assetResultsTarget.innerHTML = '<p class="px-3 py-4 text-sm text-slate-400 text-center">Type to search stocks, crypto, indices...</p>'
      }
      this.selectedIndex = -1
      this.filterQuickActions(query)
      return
    }

    if (this.debounceTimer) clearTimeout(this.debounceTimer)

    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, 300)

    this.filterQuickActions(query)
  }

  async performSearch(query) {
    try {
      const url = this.urlValue || "/search"
      const response = await window.fetch(`${url}?q=${encodeURIComponent(query)}&format=modal`, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        if (this.hasAssetResultsTarget) {
          this.assetResultsTarget.innerHTML = html
          this.selectedIndex = -1
        }
      }
    } catch (_error) {
      // Silently fail — user can still use quick actions
    }
  }

  filterQuickActions(query) {
    const lowerQuery = query.toLowerCase()
    if (!this.hasGroupTarget) return

    this.groupTargets.forEach(group => {
      const links = group.querySelectorAll("a[data-quick-action]")
      links.forEach(link => {
        const text = link.textContent.toLowerCase()
        const match = !lowerQuery || text.includes(lowerQuery)
        link.classList.toggle("hidden", !match)
      })
    })
  }

  navigate(event) {
    const items = this.getNavigableItems()
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
      const selected = items[this.selectedIndex]
      if (selected && selected.href) {
        this.close()
        window.Turbo.visit(selected.href)
      }
    }
  }

  getNavigableItems() {
    if (!this.hasResultsTarget) return []
    return Array.from(this.resultsTarget.querySelectorAll("a:not(.hidden)"))
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("bg-primary/10")
        item.scrollIntoView({ block: "nearest" })
      } else {
        item.classList.remove("bg-primary/10")
      }
    })
  }

  handleKeydown(event) {
    // Cmd+K or Ctrl+K to toggle
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.toggle()
      return
    }

    // Only handle nav keys when modal is open
    if (this.modalTarget.classList.contains("hidden")) return

    if (event.key === "Escape") {
      this.close()
      return
    }

    if (["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) {
      this.navigate(event)
    }
  }
}
