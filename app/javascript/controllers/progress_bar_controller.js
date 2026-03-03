import { Controller } from "@hotwired/stimulus"

// Displays a thin progress bar at the top of the page during Turbo navigations.
// Attach to the app layout wrapper; the bar target is the visual indicator element.
export default class extends Controller {
  static targets = ["bar"]

  connect() {
    this.startHandler = this.start.bind(this)
    this.completeHandler = this.complete.bind(this)
    this.hideHandler = this.hide.bind(this)

    document.addEventListener("turbo:before-fetch-request", this.startHandler)
    document.addEventListener("turbo:before-fetch-response", this.completeHandler)
    document.addEventListener("turbo:load", this.hideHandler)
  }

  disconnect() {
    document.removeEventListener("turbo:before-fetch-request", this.startHandler)
    document.removeEventListener("turbo:before-fetch-response", this.completeHandler)
    document.removeEventListener("turbo:load", this.hideHandler)
  }

  start(event) {
    // Only trigger for full-page navigations, not Turbo Frame loads
    if (event.target instanceof HTMLFormElement || event.target.closest?.("turbo-frame")) return

    clearTimeout(this.hideTimeout)
    this.barTarget.style.width = "0%"
    this.barTarget.style.opacity = "1"

    // Use requestAnimationFrame to ensure the 0% width is rendered before animating
    requestAnimationFrame(() => {
      this.barTarget.style.width = "90%"
    })
  }

  complete() {
    this.barTarget.style.width = "100%"
  }

  hide() {
    this.barTarget.style.opacity = "0"
    this.hideTimeout = setTimeout(() => {
      this.barTarget.style.width = "0%"
    }, 200)
  }
}
