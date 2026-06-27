import { Controller } from "@hotwired/stimulus"

// Shows/hides trend score factor breakdown popover on hover.
export default class TrendBreakdownController extends Controller {
  static targets = ["popover"]

  show() {
    if (this.hasPopoverTarget) {
      this.popoverTarget.classList.remove("hidden")
    }
  }

  hide() {
    if (this.hasPopoverTarget) {
      this.popoverTarget.classList.add("hidden")
    }
  }
}
