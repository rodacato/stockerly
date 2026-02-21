import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="selectable-card"
export default class extends Controller {
  static targets = ["card", "icon"]

  toggle(event) {
    const card = event.currentTarget
    const icon = card.querySelector("[data-selectable-card-target='icon']")
    const isSelected = card.dataset.selected === "true"

    if (isSelected) {
      card.dataset.selected = "false"
      card.classList.remove("border-primary", "ring-4", "ring-primary/5", "shadow-md")
      card.classList.add("border-slate-200", "dark:border-slate-800")
      if (icon) {
        icon.classList.add("hidden")
      }
    } else {
      card.dataset.selected = "true"
      card.classList.remove("border-slate-200", "dark:border-slate-800")
      card.classList.add("border-primary", "ring-4", "ring-primary/5", "shadow-md")
      if (icon) {
        icon.classList.remove("hidden")
      }
    }
  }
}
