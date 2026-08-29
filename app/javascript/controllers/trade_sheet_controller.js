import { Controller } from "@hotwired/stimulus"

// The trade sheet's live parts (D11): the running total, and the FX rate for
// the date the movement actually happened rather than for today.
export default class TradeSheetController extends Controller {
  static targets = ["date", "currency", "shares", "price", "fee", "fxRate", "fxCard", "fxLabel", "fxNote", "total"]
  static values = { fxUrl: String, preferredCurrency: String, referenceCurrency: String }

  connect() {
    // Until a lookup lands, one reference unit is worth one reference unit.
    this.displayDivisor = 1
    this.refreshRate()
  }

  async refreshRate() {
    // The card shows whenever there is a rate to capture — the trade stores its
    // currency against the reference, not against what the user reads in.
    const currency = this.currencyTarget.value
    if (currency === this.referenceCurrencyValue) {
      this.fxCardTarget.hidden = true
      this.fxRateTarget.value = ""
      this.displayDivisor = 1
      this.recalculate()
      return
    }

    this.fxCardTarget.hidden = false
    this.fxLabelTarget.textContent = this.label(currency)

    const params = new URLSearchParams({ currency, date: this.dateTarget.value })
    try {
      const response = await fetch(`${this.fxUrlValue}?${params}`, { headers: { Accept: "application/json" } })
      const data = await response.json()
      this.applyRate(data)
    } catch {
      // A failed lookup must not block entry: the field stays editable and the
      // note says so, rather than leaving a silent empty box.
      this.fxNoteTarget.textContent = this.fxNoteTarget.dataset.manual
    }
    this.recalculate()
  }

  applyRate({ rate, date, display_divisor: divisor }) {
    this.displayDivisor = divisor || 1
    if (rate) {
      this.fxRateTarget.value = rate
      this.fxNoteTarget.textContent = this.fxNoteTarget.dataset.banxico.replace("%{date}", date)
    } else {
      this.fxRateTarget.value = ""
      this.fxNoteTarget.textContent = this.fxNoteTarget.dataset.manual
    }
  }

  recalculate() {
    const shares = parseFloat(this.sharesTarget.value)
    const price = parseFloat(this.priceTarget.value)
    if (!shares || !price) {
      this.totalTarget.textContent = "—"
      return
    }

    const fee = parseFloat(this.feeTarget.value) || 0
    // Stored against the reference, shown in the preferred currency: the
    // divisor is the preference's own rate on the same day.
    const fx = parseFloat(this.fxRateTarget.value) || 1
    const total = ((shares * price + fee) * fx) / (this.displayDivisor || 1)

    this.totalTarget.textContent = `${this.preferredCurrencyValue} ${total.toLocaleString("es-MX", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })}`
  }

  label(currency) {
    return this.fxLabelTarget.dataset.template
      .replace("%{base}", currency)
      .replace("%{target}", this.referenceCurrencyValue)
  }
}
