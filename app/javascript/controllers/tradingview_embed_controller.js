import { Controller } from "@hotwired/stimulus"

const LOADER = "https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js"

// Builds the embed's script element rather than having the server print one.
// The config then travels as a Stimulus value — an attribute ERB escapes — so
// no view has to mark a database-derived string as safe.
//
// connect() is safe here in a way it would not be on the toggle: this element
// only exists inside the frame, and the frame is empty until the reader clicks.
// The mount is still the click, which is what D66 condition 1 protects.
export default class extends Controller {
  static values = { config: Object }

  connect() {
    if (this.#mounted) return

    const script = document.createElement("script")
    script.type = "text/javascript"
    script.src = LOADER
    script.async = true
    script.textContent = JSON.stringify(this.configValue)

    this.element.appendChild(script)
  }

  get #mounted() {
    return this.element.querySelector(`script[src="${LOADER}"]`) !== null
  }
}
