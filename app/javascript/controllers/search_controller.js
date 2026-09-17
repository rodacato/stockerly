import { Controller } from "@hotwired/stimulus"

// Submits the search form into its results frame once typing pauses, so the
// catalogue answers as you type without a request per keystroke.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  queue() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
