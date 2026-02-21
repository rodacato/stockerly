import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["panel", "badge", "item"]

  connect() {
    this.closeHandler = this.closeOnOutsideClick.bind(this)
    this.escapeHandler = this.closeOnEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
    document.removeEventListener("keydown", this.escapeHandler)
  }

  toggle(event) {
    event.stopPropagation()
    const isHidden = this.panelTarget.classList.contains("hidden")

    if (isHidden) {
      this.panelTarget.classList.remove("hidden")
      document.addEventListener("click", this.closeHandler)
      document.addEventListener("keydown", this.escapeHandler)
    } else {
      this.close()
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
    document.removeEventListener("click", this.closeHandler)
    document.removeEventListener("keydown", this.escapeHandler)
  }

  markAllAsRead() {
    this.itemTargets.forEach(item => {
      item.classList.remove("bg-primary/5", "dark:bg-primary/10", "hover:bg-primary/10", "dark:hover:bg-primary/20")
      item.classList.add("bg-white", "dark:bg-slate-900", "hover:bg-slate-50", "dark:hover:bg-slate-800")
    })
    if (this.hasBadgeTarget) {
      this.badgeTarget.classList.add("hidden")
    }
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
