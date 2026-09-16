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

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.classList.remove(...(active ? this.inactiveClasses : this.activeClasses))
      tab.classList.add(...(active ? this.activeClasses : this.inactiveClasses))
      tab.setAttribute("aria-selected", active)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
