import { Controller } from "@hotwired/stimulus"

// Submits the search form into its results frame once typing pauses, so the
// catalogue answers as you type without a request per keystroke.
export default class extends Controller {
  static targets = ["form", "input", "results"]
  static values = { delay: { type: Number, default: 300 } }

  queue() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.formTarget.requestSubmit(), this.delayValue)
  }

  clear() {
    clearTimeout(this.timer)
    if (this.hasInputTarget) this.inputTarget.value = ""
    if (this.hasResultsTarget) this.resultsTarget.innerHTML = ""
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
