import { Controller } from "@hotwired/stimulus"

export default class MobileMenuController extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }
}
