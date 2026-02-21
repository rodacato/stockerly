import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["overlay", "modal", "input", "results", "group"]

  connect() {
    this.keydownHandler = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.keydownHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.keydownHandler)
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.modalTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.modalTarget.classList.add("hidden")
    this.inputTarget.value = ""
  }

  toggle() {
    const isHidden = this.modalTarget.classList.contains("hidden")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    if (!this.hasGroupTarget) return

    this.groupTargets.forEach(group => {
      const links = group.querySelectorAll("a")
      let hasVisible = false

      links.forEach(link => {
        const text = link.textContent.toLowerCase()
        const match = !query || text.includes(query)
        link.classList.toggle("hidden", !match)
        if (match) hasVisible = true
      })

      group.classList.toggle("hidden", !hasVisible)
    })
  }

  handleKeydown(event) {
    // Cmd+K or Ctrl+K to toggle
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.toggle()
      return
    }

    // Escape to close
    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
