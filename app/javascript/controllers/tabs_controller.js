import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab(0)
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("border-primary", i === index)
      tab.classList.toggle("text-primary", i === index)
      tab.classList.toggle("font-bold", i === index)
      tab.classList.toggle("border-transparent", i !== index)
      tab.classList.toggle("text-slate-400", i !== index)
      tab.classList.toggle("font-medium", i !== index)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
