import { Controller } from "@hotwired/stimulus"
import { createChart, LineSeries } from "lightweight-charts"

// D2: our own series, never a third-party iframe. Colors read the resolved
// @theme tokens, so the chart follows the palette and the dark class for free.
//
// `series` is an array of { data: [{time, value}], token, width } — the
// Consolidado draws two (value and contributed), the asset detail one.
export default class ChartController extends Controller {
  static values = { series: Array, height: { type: Number, default: 220 } }

  connect() {
    this.chart = createChart(this.element, {
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
      this.chart
        .addSeries(LineSeries, { color: this.token(token || "--color-chart-1"), lineWidth: width || 2 })
        .setData(data)
    })

    this.chart.timeScale().fitContent()
    this.resizeObserver = new ResizeObserver(([entry]) =>
      this.chart.applyOptions({ width: entry.contentRect.width })
    )
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.chart?.remove()
    this.chart = null
  }

  token(name) {
    return getComputedStyle(this.element).getPropertyValue(name).trim()
  }
}
