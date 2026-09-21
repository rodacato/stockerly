import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
// Toggles visibility of a content target when trigger is clicked. The trigger
// announces the panel's state, and its chevron turns off the same attribute.
export default class RevealController extends Controller {
  static targets = ["content", "trigger"]

  toggle() {
    const hidden = this.contentTarget.classList.toggle("hidden")
    this.triggerTargets.forEach((trigger) => {
      trigger.setAttribute("aria-expanded", String(!hidden))
    })
  }
}
