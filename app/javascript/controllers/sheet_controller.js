import { Controller } from "@hotwired/stimulus"

// D11's drawer. The content is a real page loaded into a Turbo Frame; this only
// presents it. Because the URL really changed, the back button closes the sheet
// for free — a pure-JS drawer either hijacks history or drops you out of the app,
// which is the worst failure on a mobile browser.
export default class SheetController extends Controller {
  static targets = ["dialog", "frame"]

  connect() {
    this.onViewportChange = this.onViewportChange.bind(this)
    this.onPopState = this.onPopState.bind(this)
    window.addEventListener("popstate", this.onPopState)
  }

  disconnect() {
    window.removeEventListener("popstate", this.onPopState)
    this.untrackViewport()
  }

  // Back button: the sheet is a URL, so leaving it must close it.
  onPopState() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // Turbo loaded the route into the frame; present it.
  onFrameLoad() {
    if (this.dialogTarget.open) return

    this.dialogTarget.showModal()
    this.opened = true
    this.trackViewport()
  }

  close() {
    this.dialogTarget.close()
    // Keep the URL honest: the sheet's own entry goes away with it, so the
    // back button never returns to a sheet that is no longer open.
    if (this.opened) {
      this.opened = false
      window.history.back()
    }
  }

  // Closing must also unload the frame, or reopening shows the previous
  // movement's half-filled form.
  onClose() {
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
    this.untrackViewport()
  }

  // Backdrop click. A <dialog> reports clicks on the backdrop as clicks on
  // itself, so comparing the target is how you tell them apart. There is
  // deliberately no drag-to-dismiss: the grabber is an affordance, the X and
  // the backdrop are the real exits (D11).
  onDialogClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // The iOS keyboard shrinks the VISUAL viewport while the layout viewport
  // stays put, so a sheet anchored with bottom: 0 ends up underneath it —
  // submit button included. Following visualViewport is what keeps the sticky
  // footer where the thumb can reach it.
  trackViewport() {
    if (!window.visualViewport) return

    window.visualViewport.addEventListener("resize", this.onViewportChange)
    window.visualViewport.addEventListener("scroll", this.onViewportChange)
    this.onViewportChange()
  }

  untrackViewport() {
    if (!window.visualViewport) return

    window.visualViewport.removeEventListener("resize", this.onViewportChange)
    window.visualViewport.removeEventListener("scroll", this.onViewportChange)
    this.dialogTarget.style.removeProperty("--sheet-viewport-height")
  }

  onViewportChange() {
    const viewport = window.visualViewport
    this.dialogTarget.style.setProperty("--sheet-viewport-height", `${viewport.height}px`)
  }
}
