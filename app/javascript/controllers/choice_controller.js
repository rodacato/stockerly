import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="choice"
//
// A segmented control that persists the option you pick, with no submit
// button — the counterpart to `toggle` for a value rather than a boolean
// (D58). `toggle` sends {field: true|false} and cannot express a choice
// between N options, which is why this is a sibling and not a flag on it.
//
// The body is form-encoded and the param carries its full bracket name, so
// Rails parses `profile[preferred_currency]` into the nested params the
// endpoint already reads from the plain form on /profile.
export default class ChoiceController extends Controller {
  static targets = ["option"]
  static values = { url: String, param: String }

  select(event) {
    const value = event.currentTarget.dataset.choiceValue
    if (value === undefined || value === this.current) return

    const previous = this.current
    this.render(value)
    this.persist(value).catch(() => this.render(previous))
  }

  async persist(value) {
    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']")?.content,
        Accept: "application/json"
      },
      body: new URLSearchParams({ [this.paramValue]: value })
    })

    // A rejected value must not stay selected: the pill is the only place the
    // choice is visible, so leaving it on a value the server refused would
    // report a state the instance does not have.
    if (!response.ok) throw new Error(response.status)
  }

  render(value) {
    this.optionTargets.forEach((option) => {
      option.dataset.choiceActive = option.dataset.choiceValue === value ? "true" : "false"
    })
  }

  get current() {
    return this.optionTargets.find((option) => option.dataset.choiceActive === "true")
      ?.dataset.choiceValue
  }
}
