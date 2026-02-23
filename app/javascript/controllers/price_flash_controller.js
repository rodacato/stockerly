import { Controller } from "@hotwired/stimulus"

// Flashes green/red when an asset price changes via Turbo Stream replacement.
// Usage: data-controller="price-flash" data-price-flash-value="150.00"
export default class extends Controller {
  static values = { price: String }

  connect() {
    this.previousPrice = this.priceValue
    this.flashTimer = null
  }

  disconnect() {
    if (this.flashTimer) {
      clearTimeout(this.flashTimer)
      this.flashTimer = null
    }
  }

  priceValueChanged() {
    if (!this.previousPrice) {
      this.previousPrice = this.priceValue
      return
    }

    const oldPrice = parseFloat(this.previousPrice)
    const newPrice = parseFloat(this.priceValue)

    if (oldPrice === newPrice) return

    if (this.flashTimer) {
      clearTimeout(this.flashTimer)
      this.element.classList.remove("animate-flash-green", "animate-flash-red")
    }

    const flashClass = newPrice > oldPrice
      ? "animate-flash-green"
      : "animate-flash-red"

    this.element.classList.add(flashClass)

    this.flashTimer = setTimeout(() => {
      this.element.classList.remove(flashClass)
      this.flashTimer = null
    }, 1500)

    this.previousPrice = this.priceValue
  }
}
