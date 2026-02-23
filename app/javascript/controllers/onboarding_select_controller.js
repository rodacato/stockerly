import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="onboarding-select"
// Manages stock selection toggling in onboarding step 2
export default class extends Controller {
  static values = { assetId: Number }
  static outlets = ["onboarding-form"]

  toggle() {
    const isSelected = this.element.dataset.selected === "true"

    if (isSelected) {
      this.deselect()
    } else {
      this.select()
    }

    this.onboardingFormOutlet.updateCount()
  }

  select() {
    this.element.dataset.selected = "true"
    this.element.classList.add("bg-primary/5", "border-primary/10")
    this.element.classList.remove("border-transparent")

    const btn = this.element.querySelector("[data-role='toggle-btn']")
    btn.classList.remove("border-2", "border-primary/20", "text-primary", "hover:bg-primary", "hover:text-white")
    btn.classList.add("bg-primary", "text-white", "shadow-md", "shadow-primary/20")
    btn.innerHTML = '<span class="material-symbols-outlined" style="font-variation-settings: \'FILL\' 1">check</span>'
  }

  deselect() {
    this.element.dataset.selected = "false"
    this.element.classList.remove("bg-primary/5", "border-primary/10")
    this.element.classList.add("border-transparent")

    const btn = this.element.querySelector("[data-role='toggle-btn']")
    btn.classList.add("border-2", "border-primary/20", "text-primary", "hover:bg-primary", "hover:text-white")
    btn.classList.remove("bg-primary", "text-white", "shadow-md", "shadow-primary/20")
    btn.innerHTML = '<span class="material-symbols-outlined">add</span>'
  }
}
