import { Controller } from "@hotwired/stimulus"
import { createChart, LineSeries, createTextWatermark } from "lightweight-charts"

// D2: our own series, never a third-party iframe. Colors read the resolved
// @theme tokens, so the chart follows the palette and the dark class for free.
//
// `series` is an array of { data: [{time, value}], token, width } — the
// Consolidado draws two (value and contributed), the asset detail one.
// `levels` are the ATR price lines (D96) and a series carrying `layer` is one
// the legend adds and removes; both choices are remembered per browser.
//
// Colour separates the two kinds of level, the way the card separates them with
// a heading — it says which side of the ladder a line is on, never a forecast.
const LEVEL_STYLE = {
  entry: { token: "--color-positive", alpha: "8c" },
  exit: { token: "--color-negative", alpha: "8c" }
}
const ANCHOR_ALPHA = "59"
const STORAGE_KEY = "stockerly:chart-layers"
const RSI_PANE_HEIGHT = 64
// D105: the library formats the time axis itself, and without this it formats
// it in en-US — the one string on the screen no locale file could reach.
const LOCALE = "es-MX"
// D108, second pass: a second pane only reads as a different measurement if it
// is visibly a second pane. The library's default separator is #E0E3EB, which
// is invisible on our surface, so the two sat flush and looked like one canvas
// with a gap in it. The margins are the other half — without room under the
// price series and above the indicator, a separator alone still draws two
// things that touch. Applied only when there IS a second pane, so a range that
// draws no indicator keeps the price on the full height.
const PANE_MARGINS = { price: { top: 0.2, bottom: 0.16 }, indicator: { top: 0.2, bottom: 0.12 } }

export default class ChartController extends Controller {
  static targets = ["canvas", "layerToggle", "stat"]
  static values = { series: Array, height: { type: Number, default: 220 }, levels: Array, anchors: Array,
                    bars: Array }

  connect() {
    this.priceLines = []
    this.chart = createChart(this.container, {
      height: this.heightValue,
      layout: {
        attributionLogo: false,
        background: { color: "transparent" },
        textColor: this.token("--color-fg-subtle"),
        fontFamily: this.token("--font-sans"),
        panes: {
          separatorColor: this.token("--color-border-strong"),
          separatorHoverColor: this.token("--color-border-default")
        }
      },
      grid: {
        horzLines: { color: this.token("--color-border-default") },
        vertLines: { visible: false }
      },
      rightPriceScale: { borderColor: this.token("--color-border-default") },
      timeScale: { borderColor: this.token("--color-border-default") },
      localization: { locale: LOCALE }
    })

    this.layerSeries = {}
    this.seriesValue.filter((spec) => !spec.layer).forEach((spec) => this.addSeries(spec))

    this.drawAnchors()
    this.restoreLayers()
    this.separatePanes()
    this.trackCrosshair()
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
    this.layerSeries = {}
    this.barIndex = null
  }

  // D112: the strip reads the bar under the crosshair and falls back to the
  // latest when the pointer leaves — which is the third question D93 did not
  // consider, not a replacement for the one it answered. Touch needs no branch:
  // the library's default `trackingMode` holds the crosshair after the finger
  // lifts and drops it on the next tap, so a tap-and-read works as it stands.
  //
  // The index map is built from the series' own data rather than from what the
  // server sent, so the key is whatever shape the library normalised the time
  // into and the lookup cannot miss on a format it did not expect.
  trackCrosshair() {
    const bars = this.mainSeries?.data() || []
    if (!this.hasStatTarget || bars.length !== this.barsValue.length) return

    this.barIndex = new Map(bars.map((bar, index) => [ JSON.stringify(bar.time), index ]))
    this.chart.subscribeCrosshairMove(({ time }) =>
      this.showBar(this.barIndex.get(JSON.stringify(time)) ?? this.barsValue.length - 1)
    )
  }

  showBar(index) {
    if (index === this.shownBar) return

    this.shownBar = index
    this.statTargets.forEach((cell, position) => {
      cell.textContent = this.barsValue[index][position]
    })
  }

  addSeries(spec) {
    const series = this.chart.addSeries(
      LineSeries,
      {
        color: this.token(spec.token || "--color-chart-1"),
        lineWidth: spec.width || 2,
        priceLineVisible: !spec.layer,
        lastValueVisible: !spec.layer,
        ...(spec.scale && {
          autoscaleInfoProvider: () => ({ priceRange: { minValue: spec.scale.min, maxValue: spec.scale.max } })
        })
      },
      spec.pane || 0
    )
    series.setData(spec.data)
    if (spec.pane) this.decoratePane(series, spec)
    if (!spec.layer) this.mainSeries ||= series

    return series
  }

  // D108: a second pane is a different measurement, so it says which one and
  // holds a scale of its own. Autoscaled and unnamed it read as more price
  // chart, and every window filled the pane — which is the one thing an index
  // read against fixed thresholds must never do.
  decoratePane(series, spec) {
    this.chart.panes()[spec.pane]?.setHeight(RSI_PANE_HEIGHT)
    series.priceScale().applyOptions({ scaleMargins: PANE_MARGINS.indicator })

    ;(spec.guides || []).forEach((value) =>
      series.createPriceLine({
        price: value,
        color: this.token("--color-border-strong"),
        lineWidth: 1,
        lineStyle: 2,
        axisLabelVisible: true,
        title: ""
      })
    )

    if (spec.title) {
      createTextWatermark(this.chart.panes()[spec.pane], {
        horzAlign: "left",
        vertAlign: "top",
        lines: [ { text: spec.title, color: this.token("--color-fg-subtle"), fontSize: 11,
                   fontFamily: this.token("--font-mono") } ]
      })
    }
  }

  // A layer is added and removed rather than hidden: an RSI series left
  // invisible keeps its pane, and an empty pane is a gap with no explanation.
  showLayer(name) {
    if (this.layerSeries[name]) return

    this.layerSeries[name] = this.seriesValue
      .filter((spec) => spec.layer === name)
      .map((spec) => this.addSeries(spec))
  }

  hideLayer(name) {
    ;(this.layerSeries[name] || []).forEach((series) => this.chart.removeSeries(series))
    delete this.layerSeries[name]
  }

  // The price gives up room only while something is drawn under it, so turning
  // the indicator off puts the full height back rather than leaving a gap where
  // a pane used to be.
  separatePanes() {
    if (!this.mainSeries) return

    const stacked = this.chart.panes().length > 1
    this.mainSeries.priceScale().applyOptions({
      scaleMargins: stacked ? PANE_MARGINS.price : { top: 0.2, bottom: 0.1 }
    })
  }

  applyLayer(name, on) {
    if (name === "levels") return on ? this.drawLevels() : this.clearLevels()

    return on ? this.showLayer(name) : this.hideLayer(name)
  }

  toggleLayer(event) {
    const { layer, checked } = { layer: event.target.dataset.layer, checked: event.target.checked }

    this.applyLayer(layer, checked)
    this.separatePanes()
    this.remember(layer, checked)
  }

  // A checkbox the server rendered checked is authoritative until this browser
  // has said otherwise, so only a stored `false` turns a layer off.
  restoreLayers() {
    const stored = this.storedLayers()

    this.layerToggleTargets.forEach((input) => {
      const layer = input.dataset.layer
      if (layer in stored) input.checked = stored[layer]
      this.applyLayer(layer, input.checked)
    })
  }

  // D98's colour rule: your cost takes whatever colour the price is not, so it
  // reads as a reference and never as a verdict about being up or down.
  //
  // D104: the axis label is what makes the title render at all — the two are
  // one badge in this library, so hiding the number also hid the name.
  drawAnchors() {
    if (!this.mainSeries) return

    this.anchorsValue.forEach(({ price, label }) =>
      this.mainSeries.createPriceLine({
        price,
        color: this.token("--color-fg-default") + ANCHOR_ALPHA,
        lineWidth: 1,
        axisLabelVisible: true,
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
