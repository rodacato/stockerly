import { Controller } from "@hotwired/stimulus"

const KEY = "tradingview:acknowledged"

// Gates the opt-in chart behind a notice shown once (D66). The link is a plain
// turbo-frame link, so with the notice already acknowledged this controller
// does nothing and the browser follows it.
export default class extends Controller {
  static targets = ["notice", "link"]

  open(event) {
    if (this.#acknowledged) return

    event.preventDefault()
    this.noticeTarget.hidden = false
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
