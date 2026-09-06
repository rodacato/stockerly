import { Controller } from "@hotwired/stimulus"

const KEY = "tradingview:acknowledged"

// Gates the opt-in chart behind a notice shown once (D66). The link is a plain
// turbo-frame link, so with the notice already acknowledged this controller
// does nothing and the browser follows it.
export default class extends Controller {
  static targets = ["notice", "link", "frame"]
  static values = { showLabel: String, hideLabel: String }

  // Declared on the frame in the markup, never wired from a lifecycle callback.
  // D66 condition 1 forbids this controller having one at all, and a spec reads
  // the source to enforce it — mounting from one is D2's defect, renamed.
  shown() {
    this.setShown(true)
  }

  // One button, two jobs: it fetches the embed the first time and hides or
  // shows what was already fetched after that.
  toggle(event) {
    if (!this.loaded) return this.open(event)

    event.preventDefault()
    this.setShown(this.frameTarget.hidden)
  }

  open(event) {
    if (this.#acknowledged) return

    event.preventDefault()
    this.noticeTarget.hidden = false
  }

  setShown(shown) {
    this.frameTarget.hidden = !shown
    this.linkTarget.textContent = shown ? this.hideLabelValue : this.showLabelValue
  }

  get loaded() {
    return this.frameTarget.childElementCount > 0
  }

  accept() {
    this.#acknowledge()
    this.noticeTarget.hidden = true
    this.linkTarget.click()
  }

  dismiss() {
    this.noticeTarget.hidden = true
  }

  // Storage throws in a private window and in a browser set to block site data.
  // Failing closed shows the notice again, which is the safe side for a notice.
  get #acknowledged() {
    try {
      return localStorage.getItem(KEY) === "1"
    } catch {
      return false
    }
  }

  #acknowledge() {
    try {
      localStorage.setItem(KEY, "1")
    } catch {
      // Nothing to do: the notice simply asks again next time.
    }
  }
}
