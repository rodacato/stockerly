import { Controller } from "@hotwired/stimulus"
import { createChart, LineSeries } from "lightweight-charts"

// D2: our own series, never a third-party iframe. Colors read the resolved
// @theme tokens, so the chart follows the palette and the dark class for free.
//
// `series` is an array of { data: [{time, value}], token, width } — the
// Consolidado draws two (value and contributed), the asset detail one.
// `levels` are the ATR price lines (D96); the legend's checkbox adds and
// removes them, and the choice is remembered per browser.
// Colour separates the two kinds of level, the way the card separates them with
// a heading — it says which side of the ladder a line is on, never a forecast.
const LEVEL_STYLE = {
  entry: { token: "--color-positive", alpha: "8c" },
  exit: { token: "--color-negative", alpha: "8c" }
}
const ANCHOR_ALPHA = "59"
const STORAGE_KEY = "stockerly:chart-layers"

export default class ChartController extends Controller {
  static targets = ["canvas", "layerToggle"]
  static values = { series: Array, height: { type: Number, default: 220 }, levels: Array, anchors: Array }

  connect() {
    this.priceLines = []
    this.chart = createChart(this.container, {
      height: this.heightValue,
      layout: {
        attributionLogo: false,
        background: { color: "transparent" },
        textColor: this.token("--color-fg-subtle"),
        fontFamily: this.token("--font-sans")
      },
      grid: {
        horzLines: { color: this.token("--color-border-default") },
        vertLines: { visible: false }
      },
      rightPriceScale: { borderColor: this.token("--color-border-default") },
      timeScale: { borderColor: this.token("--color-border-default") }
    })

    this.seriesValue.forEach(({ data, token, width }) => {
      const series = this.chart.addSeries(LineSeries, {
        color: this.token(token || "--color-chart-1"),
        lineWidth: width || 2
      })
      series.setData(data)
      this.mainSeries ||= series
    })

    this.drawAnchors()
    this.restoreLayers()
    this.chart.timeScale().fitContent()
    this.resizeObserver = new ResizeObserver(([entry]) =>
      this.chart.applyOptions({ width: entry.contentRect.width })
    )
    this.resizeObserver.observe(this.container)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.chart?.remove()
    this.chart = null
    this.mainSeries = null
    this.priceLines = []
  }

  toggleLayer(event) {
    const { layer, checked } = { layer: event.target.dataset.layer, checked: event.target.checked }

    if (layer === "levels") checked ? this.drawLevels() : this.clearLevels()
    this.remember(layer, checked)
  }

  // A checkbox the server rendered checked is authoritative until this browser
  // has said otherwise, so only a stored `false` turns a layer off.
  restoreLayers() {
    const stored = this.storedLayers()

    this.layerToggleTargets.forEach((input) => {
      const layer = input.dataset.layer
      if (layer in stored) input.checked = stored[layer]
    })

    if (this.layerChecked("levels")) this.drawLevels()
  }

  // D98's colour rule: your cost takes whatever colour the price is not, so it
  // reads as a reference and never as a verdict about being up or down.
  drawAnchors() {
    if (!this.mainSeries) return

    this.anchorsValue.forEach(({ price, label }) =>
      this.mainSeries.createPriceLine({
        price,
        color: this.token("--color-fg-default") + ANCHOR_ALPHA,
        lineWidth: 1,
        axisLabelVisible: false,
        title: label
      })
    )
  }

  drawLevels() {
    if (!this.mainSeries || this.priceLines.length) return

    this.priceLines = this.levelsValue.map(({ price, kind, label }) => {
      const style = LEVEL_STYLE[kind] || LEVEL_STYLE.entry

      return this.mainSeries.createPriceLine({
        price,
        color: this.token(style.token) + style.alpha,
        lineWidth: 1,
        axisLabelVisible: true,
        title: label
      })
    })
  }

  clearLevels() {
    this.priceLines.forEach((line) => this.mainSeries?.removePriceLine(line))
    this.priceLines = []
  }

  layerChecked(layer) {
    const input = this.layerToggleTargets.find((target) => target.dataset.layer === layer)
    return input ? input.checked : false
  }

  // A private window, cleared site data or a browser that refuses storage all
  // land here; the server-rendered state is the answer in every one of them.
  storedLayers() {
    try {
      return JSON.parse(window.localStorage.getItem(STORAGE_KEY)) || {}
    } catch {
      return {}
    }
  }

  remember(layer, checked) {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...this.storedLayers(), [layer]: checked }))
    } catch {
      // storage is a convenience here, never the source of what is drawn
    }
  }

  get container() {
    return this.hasCanvasTarget ? this.canvasTarget : this.element
  }

  token(name) {
    return getComputedStyle(this.element).getPropertyValue(name).trim()
  }
}
