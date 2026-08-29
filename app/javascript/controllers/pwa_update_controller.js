import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pwa-update"
//
// A deployed service worker installs but parks itself in "waiting" — see the
// SKIP_WAITING handler in app/views/pwa/service_worker.js.erb. This surfaces
// that, so the swap happens when the user says so and not under a live page.
export default class PwaUpdateController extends Controller {
  connect() {
    if (!("serviceWorker" in navigator)) return

    navigator.serviceWorker.ready.then((registration) => {
      if (registration.waiting) return this.reveal(registration.waiting)

      registration.addEventListener("updatefound", () => {
        const installing = registration.installing
        installing?.addEventListener("statechange", () => {
          // No controller means this is the first install, not an update.
          if (installing.state === "installed" && navigator.serviceWorker.controller) {
            this.reveal(installing)
          }
        })
      })
    })
  }

  apply() {
    navigator.serviceWorker.addEventListener(
      "controllerchange", () => globalThis.location.reload(), { once: true }
    )
    this.waitingWorker?.postMessage("SKIP_WAITING")
  }

  reveal(worker) {
    this.waitingWorker = worker
    this.element.hidden = false
  }
}
