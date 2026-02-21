import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["knob", "track"]

  toggle() {
    const track = this.trackTarget
    const knob = this.knobTarget
    const isActive = track.classList.contains("bg-primary")

    track.classList.toggle("bg-primary", !isActive)
    track.classList.toggle("bg-slate-200", isActive)
    track.classList.toggle("dark:bg-slate-700", isActive)
    knob.classList.toggle("translate-x-5", !isActive)
    knob.classList.toggle("translate-x-0", isActive)
  }
}
