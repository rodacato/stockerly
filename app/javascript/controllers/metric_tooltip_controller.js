import { Controller } from "@hotwired/stimulus"

// Manages educational metric tooltips on asset detail page.
// Opens a popover with definition and interpretation guidance.
export default class extends Controller {
  static targets = ["popover"]

  toggle(event) {
    event.stopPropagation()
    const isHidden = this.popoverTarget.classList.contains("hidden")

    // Close any other open tooltips first
    document.querySelectorAll("[data-metric-tooltip-target='popover']").forEach(el => {
      if (el !== this.popoverTarget) {
        el.classList.add("hidden")
        el.closest("[data-controller='metric-tooltip']")?.classList.remove("ring-2", "ring-primary/30")
      }
    })

    this.popoverTarget.classList.toggle("hidden")
    this.element.classList.toggle("ring-2", isHidden)
    this.element.classList.toggle("ring-primary/30", isHidden)
  }

  close(event) {
    event.stopPropagation()
    this.popoverTarget.classList.add("hidden")
    this.element.classList.remove("ring-2", "ring-primary/30")
  }

  connect() {
    this.outsideHandler = (event) => {
      if (!this.element.contains(event.target)) {
        this.popoverTarget.classList.add("hidden")
        this.element.classList.remove("ring-2", "ring-primary/30")
      }
    }
    document.addEventListener("click", this.outsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideHandler)
  }
}
