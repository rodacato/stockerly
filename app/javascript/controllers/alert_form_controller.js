import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert-form"
//
// Owns the create-alert form's chip selector + dynamic field set:
//   * Chips toggle the hidden condition field and the active style.
//   * Each "panel" target declares which conditions it applies to via
//     data-alert-form-conditions; we show/hide on chip change.
//   * The preview text recomposes from the ticker/threshold/window inputs.
export default class AlertFormController extends Controller {
  static targets = [
    "chip",
    "conditionInput",
    "direction",
    "panel",
    "ticker",
    "threshold",
    "thresholdLabel",
    "windowDays",
    "preview"
  ]

  // price_crosses_above and price_crosses_below share one chip; the direction
  // control picks between them, which is how the artboard draws it.
  static DIRECTIONAL = ["price_crosses_above", "price_crosses_below"]

  connect() {
    this.refreshPanels()
    this.refreshPreview()
  }

  selectChip(event) {
    const value = event.currentTarget.dataset.condition
    if (!value) return

    this.conditionInputTarget.value = value
    this.paintChips()
    this.refreshPanels()
    this.refreshPreview()
  }

  // The radios carry the enum value directly, so the hidden field is just
  // assigned. The chip stays lit because paintChips treats the pair as one.
  selectDirection(event) {
    this.conditionInputTarget.value = event.currentTarget.value
    this.paintChips()
    this.refreshPreview()
  }

  paintChips() {
    const value = this.conditionInputTarget.value
    this.chipTargets.forEach((chip) => {
      const active = chip.dataset.condition === value || this.sameFamily(chip.dataset.condition, value)
      chip.dataset.active = active ? "true" : "false"
      chip.classList.toggle("border-primary", active)
      chip.classList.toggle("bg-primary-muted", active)
      chip.classList.toggle("text-primary", active)
      chip.classList.toggle("font-semibold", active)
      chip.classList.toggle("border-border-default", !active)
      chip.classList.toggle("text-fg-default", !active)
    })
  }

  sameFamily(a, b) {
    const pair = this.constructor.DIRECTIONAL
    return pair.includes(a) && pair.includes(b)
  }

  refreshPanels() {
    const value = this.conditionInputTarget.value
    this.panelTargets.forEach((panel) => {
      const matches = (panel.dataset.alertFormConditions || "").split(/[ ,]+/).includes(value)
      panel.classList.toggle("hidden", !matches)
    })
    if (this.hasThresholdLabelTarget) {
      this.thresholdLabelTarget.textContent = this.thresholdLabelFor(value)
    }
  }

  refreshPreview() {
    if (!this.hasPreviewTarget) return

    const condition = this.conditionInputTarget.value
    const ticker = (this.tickerTarget.value || "ACTIVO").toUpperCase()
    const threshold = this.thresholdTarget.value || "—"
    const window = this.hasWindowDaysTarget ? (this.windowDaysTarget.value || "—") : "—"

    let text
    switch (condition) {
      case "price_crosses_above":
        text = `Te avisaremos cuando ${ticker} cruce ${threshold} al alza.`
        break
      case "price_crosses_below":
        text = `Te avisaremos cuando ${ticker} cruce ${threshold} a la baja.`
        break
      case "rsi_oversold":
        text = `Te avisaremos cuando el RSI(14) de ${ticker} baje de ${threshold}.`
        break
      case "rsi_overbought":
        text = `Te avisaremos cuando el RSI(14) de ${ticker} pase de ${threshold}.`
        break
      case "volume_spike":
        text = `Te avisaremos cuando ${ticker} registre volumen mayor a ${threshold}× su promedio.`
        break
      case "dividend_ex_date":
        text = `Te avisaremos ${window} día(s) antes del próximo ex-date de dividendo de ${ticker}.`
        break
      case "bmv_holiday":
        text = `Te avisaremos ${window} día(s) antes de cada festivo de la BMV.`
        break
      case "cete_auction":
        text = `Te avisaremos ${window} día(s) antes de la próxima subasta de CETES.`
        break
      default:
        text = `Te avisaremos cuando se cumpla la condición en ${ticker}.`
    }
    this.previewTarget.textContent = text
  }

  thresholdLabelFor(condition) {
    switch (condition) {
      case "rsi_oversold":
      case "rsi_overbought":
        return "Nivel RSI"
      case "volume_spike":
        return "Múltiplo del promedio"
      case "dividend_ex_date":
      case "bmv_holiday":
      case "cete_auction":
        return "Días antes del evento"
      default:
        return "Umbral de precio"
    }
  }
}
