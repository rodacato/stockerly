import { Controller } from "@hotwired/stimulus"

// Displays a floating tooltip when hovering over SVG chart data points.
// Usage: data-controller="chart-tooltip" on a wrapper div containing an SVG and a tooltip div.
//
// Expects:
//   - target "svg": the <svg> element
//   - target "tooltip": a hidden <div> for displaying values
//   - <circle> elements inside the SVG with data-date and data-value attributes
export default class extends Controller {
  static targets = ["svg", "tooltip"]

  connect() {
    this._onMouseMove = this._handleMouseMove.bind(this)
    this._onMouseLeave = this._handleMouseLeave.bind(this)
    this.svgTarget.addEventListener("mousemove", this._onMouseMove)
    this.svgTarget.addEventListener("mouseleave", this._onMouseLeave)
  }

  disconnect() {
    this.svgTarget.removeEventListener("mousemove", this._onMouseMove)
    this.svgTarget.removeEventListener("mouseleave", this._onMouseLeave)
  }

  _handleMouseMove(event) {
    const svg = this.svgTarget
    const rect = svg.getBoundingClientRect()
    const circles = svg.querySelectorAll("circle[data-date]")
    if (circles.length === 0) return

    const mouseX = event.clientX - rect.left
    const scaleX = svg.viewBox.baseVal.width / rect.width

    const svgX = mouseX * scaleX
    let closest = circles[0]
    let minDist = Infinity

    circles.forEach((circle) => {
      const cx = parseFloat(circle.getAttribute("cx"))
      const dist = Math.abs(cx - svgX)
      if (dist < minDist) {
        minDist = dist
        closest = circle
      }
    })

    // Show highlight on closest point
    circles.forEach((c) => c.setAttribute("r", "0"))
    closest.setAttribute("r", "4")

    // Update tooltip content
    const tooltip = this.tooltipTarget
    tooltip.textContent = `${closest.dataset.date}: ${closest.dataset.value}`
    tooltip.classList.remove("hidden")

    // Position tooltip near cursor
    const tooltipWidth = tooltip.offsetWidth
    let left = mouseX - tooltipWidth / 2
    left = Math.max(0, Math.min(left, rect.width - tooltipWidth))
    tooltip.style.left = `${left}px`
  }

  _handleMouseLeave() {
    this.tooltipTarget.classList.add("hidden")
    this.svgTarget.querySelectorAll("circle[data-date]").forEach((c) => c.setAttribute("r", "0"))
  }
}
