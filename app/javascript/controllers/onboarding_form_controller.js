import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding-form"
// Manages the onboarding step 2 form: counter, validation, and submission
export default class extends Controller {
  static targets = ["counter", "counterIcon", "submitBtn", "hiddenInputs"]

  updateCount() {
    const selected = this.element.querySelectorAll("[data-selected='true']")
    const count = selected.length
    const minimum = 3

    // Update counter text
    this.counterTarget.textContent = `${count} of ${minimum} minimum selected`

    // Update counter icon
    if (count >= minimum) {
      this.counterIconTarget.textContent = "verified"
      this.counterIconTarget.classList.add("text-primary")
      this.counterIconTarget.classList.remove("text-slate-400")
    } else {
      this.counterIconTarget.textContent = "radio_button_unchecked"
      this.counterIconTarget.classList.remove("text-primary")
      this.counterIconTarget.classList.add("text-slate-400")
    }

    // Enable/disable submit button
    if (count >= minimum) {
      this.submitBtnTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.submitBtnTarget.removeAttribute("disabled")
    } else {
      this.submitBtnTarget.classList.add("opacity-50", "cursor-not-allowed")
      this.submitBtnTarget.setAttribute("disabled", "true")
    }
  }

  submit(event) {
    event.preventDefault()

    const selected = this.element.querySelectorAll("[data-selected='true']")
    if (selected.length < 3) return

    // Build hidden inputs for asset_ids
    this.hiddenInputsTarget.innerHTML = ""
    selected.forEach(el => {
      const assetId = el.dataset.onboardingSelectAssetIdValue
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "asset_ids[]"
      input.value = assetId
      this.hiddenInputsTarget.appendChild(input)
    })

    // Submit the form
    this.element.querySelector("form").submit()
  }
}
