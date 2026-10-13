import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
// Each consumer declares what active and inactive look like, so the strip
// keeps the shape its markup was drawn with.
export default class TabsController extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]

  connect() {
    this.showTab(0)
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(index)
  }

  navigate(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    const last = this.tabTargets.length - 1
    const next = { ArrowRight: (index + 1) % (last + 1),
                   ArrowLeft: (index + last) % (last + 1), Home: 0, End: last }[event.key]
    if (next === undefined) return
    event.preventDefault()
    this.showTab(next)
    this.tabTargets[next].focus()
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.classList.remove(...(active ? this.inactiveClasses : this.activeClasses))
      tab.classList.add(...(active ? this.activeClasses : this.inactiveClasses))
      tab.setAttribute("aria-selected", active)
      if (tab.getAttribute("role") === "tab") tab.tabIndex = active ? 0 : -1
    })
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
