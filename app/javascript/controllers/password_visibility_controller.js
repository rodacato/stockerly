import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="password-visibility"
// The icon set has no "visibility_off" twin, so the pressed state is carried
// by aria-pressed (and styled from it) rather than by swapping glyphs.
export default class PasswordVisibilityController extends Controller {
  static targets = ["input", "button"]

  toggle() {
    const reveal = this.inputTarget.type === "password"
    this.inputTarget.type = reveal ? "text" : "password"
    this.buttonTarget.setAttribute("aria-pressed", String(reveal))
  }
}
