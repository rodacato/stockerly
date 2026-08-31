import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submitting"
//
// Turbo disables a submit button and swaps its label on its own, but only on
// forms it drives. A form that opts out of Turbo -- because its response renders
// rather than redirects -- has to say the same thing by hand, or a slow import
// looks like a button that did nothing.
export default class extends Controller {
  static values = { label: String }

  connect() {
    this.disable = this.disable.bind(this)
    this.element.addEventListener("submit", this.disable)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.disable)
  }

  disable() {
    const button = this.element.querySelector("input[type=submit], button[type=submit]")
    if (!button) return

    button.disabled = true
    button.classList.add("opacity-60", "cursor-progress")
    if (this.hasLabelValue) button.value = this.labelValue
  }
}
