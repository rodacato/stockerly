import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { dismissAfter: { type: Number, default: 5000 } }

  connect() {
    this.element.classList.add("transition-all", "duration-300", "ease-out")
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"

    requestAnimationFrame(() => {
      this.element.style.transform = "translateX(0)"
      this.element.style.opacity = "1"
    })

    this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 300)
  }
}
