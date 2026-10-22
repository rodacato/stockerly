import { Controller } from "@hotwired/stimulus"

// A citation in Velita's answer opens the folded reads and lands on its card,
// instead of jumping to an anchor hidden inside a closed <details> (D171).
export default class AssistantSourcesController extends Controller {
  static targets = ["fold"]

  reveal(event) {
    const card = this.element.querySelector(event.currentTarget.getAttribute("href"))
    if (!card || !this.hasFoldTarget) return

    event.preventDefault()
    this.foldTarget.open = true
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    card.scrollIntoView({ block: "nearest", behavior: reduce ? "auto" : "smooth" })
    card.focus({ preventScroll: true })
  }
}
