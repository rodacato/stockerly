import { Controller } from "@hotwired/stimulus"

// Makes a table row clickable — navigates to data-row-link-url-value on click
// Ignores clicks on buttons, links, and form elements within the row
export default class extends Controller {
  static values = { url: String }

  visit(event) {
    // Don't navigate if clicking on interactive elements
    const target = event.target.closest("a, button, input, form, [data-turbo-frame]")
    if (target) return

    if (this.urlValue) {
      window.Turbo.visit(this.urlValue)
    }
  }
}
