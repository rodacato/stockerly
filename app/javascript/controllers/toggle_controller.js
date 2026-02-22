import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
// Optional persistence: add data-toggle-url-value and data-toggle-field-value
export default class extends Controller {
  static targets = ["knob", "track"]
  static values = { url: String, field: String }

  toggle() {
    const track = this.trackTarget
    const knob = this.knobTarget
    const isActive = track.classList.contains("bg-primary")

    track.classList.toggle("bg-primary", !isActive)
    track.classList.toggle("bg-slate-200", isActive)
    track.classList.toggle("dark:bg-slate-700", isActive)
    knob.classList.toggle("translate-x-5", !isActive)
    knob.classList.toggle("translate-x-0", isActive)

    if (this.hasUrlValue && this.hasFieldValue) {
      this.persist(!isActive)
    }
  }

  persist(enabled) {
    const csrfToken = document.querySelector("[name='csrf-token']")?.content
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({ [this.fieldValue]: enabled })
    })
  }
}
