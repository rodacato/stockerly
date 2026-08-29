import { Controller } from "@hotwired/stimulus"

// Flips every box to the same state. The button reads what the boxes are
// rather than tracking its own flag, so it stays right after individual clicks.
export default class CheckAllController extends Controller {
  static targets = ["box"]

  toggle() {
    const target = !this.boxTargets.every((box) => box.checked)
    this.boxTargets.forEach((box) => { box.checked = target })
  }
}
