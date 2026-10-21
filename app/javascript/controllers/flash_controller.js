import { Controller } from "@hotwired/stimulus"

export default class FlashController extends Controller {
  static values = { dismissAfter: { type: Number, default: 5000 } }

  connect() {
    this.raiseStack()
    this.element.classList.add("transition-all", "duration-300", "ease-out")
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"

    requestAnimationFrame(() => {
      this.element.style.transform = "translateX(0)"
      this.element.style.opacity = "1"
    })

    this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
  }

  // The top layer stacks in the order things were shown, so a toast arriving
  // over an open modal sheet has to re-show its stack to land above it.
  raiseStack() {
    const stack = this.element.closest("[popover]")
    if (!stack?.showPopover) return

    if (stack.matches(":popover-open")) stack.hidePopover()
    stack.showPopover()
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
