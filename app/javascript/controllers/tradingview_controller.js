import { Controller } from "@hotwired/stimulus"

// Lazy-loads TradingView Advanced Chart widget using IntersectionObserver.
// Usage: <div data-controller="tradingview" data-tradingview-symbol-value="NASDAQ:AAPL">
export default class extends Controller {
  static values = { symbol: String, theme: { type: String, default: "light" } }
  static targets = ["container"]

  connect() {
    this._observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this._loadWidget()
            this._observer.disconnect()
          }
        })
      },
      { threshold: 0.1 }
    )

    this._observer.observe(this.containerTarget)
  }

  disconnect() {
    this._observer?.disconnect()
  }

  _loadWidget() {
    const container = this.containerTarget
    container.innerHTML = ""

    const script = document.createElement("script")
    script.src = "https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js"
    script.async = true
    script.type = "text/javascript"
    script.textContent = JSON.stringify({
      autosize: true,
      symbol: this.symbolValue,
      interval: "D",
      timezone: "America/New_York",
      theme: this.themeValue,
      style: "1",
      locale: "en",
      hide_side_toolbar: false,
      allow_symbol_change: false,
      support_host: "https://www.tradingview.com"
    })

    container.appendChild(script)
  }
}
