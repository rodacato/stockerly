import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reveal"
// Toggles visibility of a content target when trigger is clicked
export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
