import { Controller } from "@hotwired/stimulus"

// ADR-032: reports a catalogued client-side event (a link leaving the app).
// The server records it only while the owner's usage switch is on.
export default class extends Controller {
  static values = { url: String }

  record() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.urlValue, { method: "POST", headers: { "X-CSRF-Token": token }, keepalive: true })
  }
}
