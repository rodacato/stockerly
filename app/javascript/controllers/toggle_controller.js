import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
// Optional persistence: add data-toggle-url-value and data-toggle-field-value
export default class ToggleController extends Controller {
  static targets = ["knob", "track"]
  static values = { url: String, field: String }

  toggle() {
    const isActive = this.trackTarget.classList.contains("bg-primary")
    this.render(!isActive)

    if (this.hasUrlValue && this.hasFieldValue) {
      // A rejected write must not stay flipped: the switch is the only place
      // the setting is visible, so leaving it on would report a state the
      // instance does not have. Same contract as `choice`.
      this.persist(!isActive).catch(() => this.render(isActive))
    }
  }

  // bg-bg-muted is what the server renders for the off state. Toggling a
  // different off-class (bg-slate-200) left both on the element, so a switch
  // turned off by hand did not match one rendered off.
  render(on) {
    this.trackTarget.classList.toggle("bg-primary", on)
    this.trackTarget.classList.toggle("bg-bg-muted", !on)
    this.knobTarget.classList.toggle("translate-x-5", on)
    this.knobTarget.classList.toggle("translate-x-0", !on)
  }

  async persist(enabled) {
    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ [this.fieldValue]: enabled })
    })

    if (!response.ok) throw new Error(response.status)
  }
}
